# GPU-only training (recommended)

**Default for CNN / reaction vision on the homelab.** All optimized training runs on **`zak_pc` (RTX 5070)**. The iMac keeps Postgres, API, and web UI — it does not run CUDA.

## Why GPU-only

| | GPU-only | iMac + GPU “distributed” |
|--|----------|---------------------------|
| Speed | Fastest — no shard/API overhead | Same GPU work + extra steps |
| VRAM | Full 12 GB for train | Same |
| Optimizations | AMP, grad accumulation, batch size | Same on GPU |
| Dependencies | `homelab-gpu` + `.venv` only | Needs Postgres + `train_prep` |

Use the **job queue** (`POST /jobs`) later for experiment tracking — still GPU execution, `distributed: false`.

## One-time setup (GPU PC)

```powershell
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\setup-venv.ps1
.\.venv\Scripts\pip install -r requirements.txt
# CHECKPOINT_DIR / DATASET_DIR in .env or defaults:
#   C:\Users\zakar\homelab-data\checkpoints
#   C:\Users\zakar\homelab-data\datasets
```

## Run training (optimized defaults)

```powershell
.\scripts\run-cnn-local.ps1 -Dataset cifar10 -Epochs 10 -BatchSize 32 -GradAccum 4
# or directly:
.\.venv\Scripts\python.exe .\scripts\train_cifar_gpu_min.py
# env: CNN_EPOCHS, CNN_BATCH_SIZE, CNN_GRAD_ACCUM
```

| Flag | Default | Meaning |
|------|---------|---------|
| `-Dataset` | `cifar10` | Auto-download CIFAR-10 |
| `-Epochs` | `10` | Training epochs |
| `-BatchSize` | `32` | Micro-batch (raise if VRAM allows) |
| `-GradAccum` | `4` | Effective batch ≈ 128 |
| `-ModelVersion` | `gpu-cnn-v1` | Label in manifest |

Script runs **`stop-ollama.ps1`** first, then trains with **AMP** on CUDA.

## CPU + GPU together (zak_pc i7-14700F)

The **GPU** runs the model; the **CPU** keeps it fed so the RTX 5070 is not waiting on disk/decode/augment:

| Mechanism | Role |
|-----------|------|
| **DataLoader `num_workers`** | ~10 parallel workers decode FER pixels / apply aug while GPU trains |
| **`prefetch_factor` + `persistent_workers`** | Batches ready before the GPU asks |
| **`pin_memory` + `non_blocking`** | Faster host→GPU copies |
| **`cudnn.benchmark` + TF32** | Faster convolutions on fixed 224×224 inputs |
| **1 thread per worker** (`OMP_NUM_THREADS=1`) | Avoids 10×28-thread CPU fights |

On the GPU PC before training:

```powershell
. .\scripts\set-cpu-train-env.ps1   # sets CNN_NUM_WORKERS, thread caps
.\scripts\run-reaction-train-accurate.ps1
```

Override: `$env:CNN_NUM_WORKERS = "6"` if RAM is tight (~2 GB per worker with heavy aug).

The **iMac M1** does not run CNN backward passes; in distributed mode it only builds shard index lists in Postgres ([DISTRIBUTED-TRAIN.md](DISTRIBUTED-TRAIN.md)).

## Outputs

```text
C:\Users\zakar\homelab-data\checkpoints\{job-id}\
├── best_model.pt
├── metrics.json
├── manifest.json
└── published.json
```

## Facial expression / reactions (FER2013)

```powershell
.\scripts\download-fer2013.ps1          # needs Kaggle CLI or manual fer2013.csv
.\scripts\run-reaction-train.ps1 -Dataset fer2013 -Epochs 15 -BatchSize 64
```

Uses `train_reaction_gpu.py` — ResNet18, AMP, 7 FER classes. Expect **~60–85%** val accuracy depending on labels and epochs ([REACTION-VISION.md](REACTION-VISION.md)).

## Personal webcam captures

```powershell
.\scripts\capture-reactions.ps1       # saves to datasets\me-reactions\train\{class}\
.\scripts\run-reaction-train.ps1 -Dataset reactions -Epochs 20
```

## Web GUI (homelab-web)

1. On GPU PC, keep inference running:

```powershell
.\scripts\start-reaction-serve-bg.ps1
# listens on http://0.0.0.0:8100 — checkpoint from REACTION_CHECKPOINT env
```

2. iMac `.env`: `GPU_VISION_URL=http://100.88.71.33:8100`

3. Open **http://100.91.113.98:3081/reactions** — live webcam + expression bars (use `:3081`; `:3080` may serve a stale build on iMac).

## Webcam inference (local script)

```powershell
.\scripts\run-reaction-infer.ps1 -CheckpointDir "C:\Users\zakar\homelab-data\checkpoints\<job-id>"
```

Not Ollama — loads `best_model.pt` + Haar face crop. Threshold default **0.45** (ambiguous below).

## After training

- **LoRA / chat:** `publish-lora-to-ollama.ps1` (LLM adapters only).
- **CNN / reactions:** `run-reaction-infer.ps1` or future homelab-web `/reactions` page.

For research context, see [REACTION-VISION.md](REACTION-VISION.md).

## Later: job queue (same GPU code)

When iMac Postgres is healthy:

```powershell
$body = @{
  train_mode = "cnn"
  dataset = "cifar10"
  distributed = $false
  epochs = 10
  batch_size = 32
  grad_accum_steps = 4
  use_amp = $true
} | ConvertTo-Json -Compress
# POST http://100.91.113.98:3080/api/homelab/jobs
# GPU worker: .\scripts\start-gpu-worker.ps1
```

## See also

- [CNN-FINETUNE.md](CNN-FINETUNE.md)
- [DISTRIBUTED-TRAIN.md](DISTRIBUTED-TRAIN.md) — optional orchestration, not default
- [nodes/gpu-node.md](nodes/gpu-node.md)
