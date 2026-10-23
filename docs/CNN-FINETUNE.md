# CNN fine-tuning (image classification)

Train a **convolutional neural network** on the GPU PC through the same Postgres job worker as LoRA. Output: `checkpoints/{job_id}/best_model.pt` + `metrics.json`.

**Not for chat/Ollama** — this is vision (images → class labels). Use LoRA ([PHASE-3.md](PHASE-3.md)) for language models.

**Facial reactions / emotions:** See [REACTION-VISION.md](REACTION-VISION.md) — research basis (FER2013, FER+ / Barsoum et al., ResNet transfer learning).

## Recommended datasets

| Dataset | Size | Classes | Best for | How you get it |
|---------|------|---------|----------|----------------|
| **CIFAR-10** (default) | 60k images, 32×32 | 10 | First CNN run, fast smoke | **Auto-download** — set `"dataset": "cifar10"` |
| **Fashion-MNIST** | 70k, 28×28 grayscale | 10 | Simpler than CIFAR | Add to `train.py` later or convert to folder layout |
| **Cats vs Dogs** | ~25k images | 2 | Classic beginner project | [Kaggle](https://www.kaggle.com/datasets/saladerobots/cats-vs-dogs) → extract under `datasets/cats-vs-dogs/train/{cat,dog}/` |
| **Food-101** | 101k images | 101 | Realistic food recognition | [Kaggle Food-101](https://www.kaggle.com/datasets/kmader/food41) or official Food-101 — use **subset** on 12 GB |
| **PlantVillage** | ~54k leaves | 38 | Plant disease | [Kaggle PlantVillage](https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset) |
| **FER2013** | ~35k faces, 48×48 | 7 emotions | **Your reaction AI** | Kaggle/HF — see [REACTION-VISION.md](REACTION-VISION.md) |
| **Your own photos** | Any | Your labels | Personal reactions (webcam) | `datasets/me-reactions/train/{happy,neutral,...}/` |

### Custom folder layout (any dataset)

On GPU PC (`zakar`):

```text
C:\Users\zakar\homelab-data\datasets\my-project\
├── train\
│   ├── class_a\
│   │   ├── img001.jpg
│   │   └── ...
│   └── class_b\
│       └── ...
└── val\          (optional — 10% holdout auto-split if missing)
    ├── class_a\
    └── class_b\
```

Job payload: `"dataset": "folder", "dataset_version": "my-project"`.

## Quick start — CIFAR-10 (no manual download)

**Recommended:** GPU-only optimized train on `zak_pc` — [GPU-TRAIN.md](GPU-TRAIN.md).

```powershell
# on zak_pc
.\scripts\run-cnn-local.ps1 -Epochs 10
```

### Via iMac job queue (optional)

### 1. GPU worker ready

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
# .env: TRAIN_MODE can stay qlora; job payload overrides with train_mode=cnn
.\scripts\start-gpu-worker.ps1
# or ensure HomelabGpuWorker scheduled task is running
```

### 2. Submit job (laptop)

```powershell
$key = "YOUR_API_KEY"   # from homelab-services .env
$h = @{ "x-api-key" = $key; "Content-Type" = "application/json" }
$body = @{
  train_mode      = "cnn"
  dataset         = "cifar10"
  dataset_version = "cifar10"
  model_version   = "cifar-resnet18-v1"
  architecture    = "resnet18"
  epochs          = 5
  batch_size      = 32
} | ConvertTo-Json -Compress

$job = Invoke-RestMethod -Uri "http://100.91.113.98:3081/api/homelab/jobs" -Method Post -Headers $h -Body $body
$job.id
```

### 3. Poll until succeeded

```powershell
Invoke-RestMethod -Uri "http://100.91.113.98:3081/api/homelab/jobs/$($job.id)" -Headers @{ "x-api-key" = $key }
```

### 4. Artifacts on GPU

```text
C:\Users\zakar\homelab-data\checkpoints\{job_id}\
├── best_model.pt    # ResNet18 weights + class names
├── metrics.json     # per-epoch train/val accuracy
├── manifest.json
└── published.json
```

## RTX 5070 notes

| Rule | Why |
|------|-----|
| Stop Ollama before train | CNN uses CUDA; training script calls `stop-ollama.ps1` |
| Start with **CIFAR-10** or small folder | 12 GB VRAM — avoid full ImageNet without subset |
| **ResNet18** default | Good accuracy/speed tradeoff |
| Max **1** train job | Same Postgres gate as LoRA |

## API job body

| Field | Example | Meaning |
|-------|---------|---------|
| `train_mode` | `"cnn"` | Required for CNN (overrides GPU `TRAIN_MODE`) |
| `dataset` | `"cifar10"` or `"folder"` | Built-in vs custom folders |
| `dataset_version` | `"my-project"` | Subfolder under `homelab-data/datasets/` for folder mode |
| `model_version` | `"cifar-resnet18-v1"` | Label for experiments table |
| `architecture` | `"resnet18"` | Also `resnet34` |
| `epochs` | `5` | Training epochs |
| `batch_size` | `32` | Lower if OOM |
| `learning_rate` | `0.001` | Adam LR |

## Deploy API change (once)

After pulling `homelab-services` with extended `POST /jobs` body:

```bash
ssh imac-ts
source ~/1tb-drive/homelab-services/scripts/docker-1tb-env.sh
cd ~/1tb-drive/homelab-services && git pull
docker compose up -d --build api
```

## Local debug (GPU only, no job queue)

```powershell
cd C:\Users\zakar\homelab-gpu
$env:TRAIN_MODE = "cnn"
.\.venv\Scripts\python.exe -c "
from worker.run_train import run_train
import json
m = run_train('local-cnn-test', {'train_mode':'cnn','dataset':'cifar10','epochs':2})
print(json.dumps(m, indent=2))
"
```

## Next after training

- Export ONNX for deployment (optional script TBD)
- Jupyter: plot `metrics.json` in `notebooks/`
- Larger dataset: Cats vs Dogs or Food-101 subset with folder layout

## See also

- [PHASE-3.md](PHASE-3.md) — LoRA / language models  
- [gpu-node.md](nodes/gpu-node.md) — VRAM and Ollama  
- [EXECUTION-MODEL.md](EXECUTION-MODEL.md) — job worker flow
