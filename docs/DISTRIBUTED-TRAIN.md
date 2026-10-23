# Distributed training — iMac coordinator + GPU executor

**Postgres remains the single source of truth.** The iMac does **not** run CUDA training; it **plans batches** (shard indices). The GPU runs **optimized training** (AMP, gradient accumulation, batched shards).

## Why split Mac vs GPU?

| Node | Role | Why |
|------|------|-----|
| **iMac (M1)** | `train_prep` job — shuffle/split indices into `shard_count` shards in Postgres | Cheap CPU + always-on; no VRAM contention with Ollama |
| **GPU (RTX 5070)** | `train` job — load images, forward/backward, save `best_model.pt` | CUDA + 12 GB VRAM |

This is **not** PyTorch multi-node DDP where the iMac runs backward passes alongside the GPU. The M1 would be ~50–100× slower on conv layers and would add network sync overhead. Instead:

| What people often mean | What the homelab does |
|------------------------|------------------------|
| “Train on GPU + CPU together” | iMac **CPU** only shuffles/splits **index lists** into Postgres shards (~seconds) |
| PyTorch `DistributedDataParallel` | **GPU only** runs forward/backward/AMP; shards control epoch order and memory churn |
| Faster training | Same peak speed as GPU-only; benefit is **job queue**, **resumability**, and not blocking the laptop |

True cross-device DDP (CUDA + Apple MPS) is possible in theory but **not recommended** for this homelab — use GPU-only `train_reaction_gpu.py` for max accuracy/speed, or distributed mode for **orchestration**.

Aligned with [EXECUTION-MODEL.md](EXECUTION-MODEL.md).

## Flow

```text
POST /jobs { distributed: true, train_mode: cnn, shard_count: 8, ... }
  → Postgres: train job (pending) + train_prep job (pending)
  → iMac imac-worker claims train_prep
      → writes train_plans + train_shards (index JSON) in Postgres
      → train_prep succeeded
  → GPU worker claims train (only when plan.ready_at set)
      → GET /internal/worker/train/{id}/plan
      → epoch loop: for each shard → DataLoader(Subset) → AMP + grad_accum
      → checkpoints/{job_id}/best_model.pt
```

## Optimization (GPU)

| Setting | Default | Effect |
|---------|---------|--------|
| `use_amp` | `true` | Mixed precision on CUDA (faster, less VRAM) |
| `grad_accum_steps` | `4` | Effective batch = `batch_size × grad_accum` |
| `batch_size` | `32` | Per micro-batch |
| `shard_count` | `8` | iMac splits training indices across 8 shards per epoch |
| `num_workers` | `2` | DataLoader prefetch (GPU env `CNN_NUM_WORKERS`) |

## Deploy (once)

**iMac:**

```bash
ssh imac-ts
source ~/1tb-drive/homelab-services/scripts/docker-1tb-env.sh
cd ~/1tb-drive/homelab-services
git pull
./scripts/migrate-distributed-train.sh
docker compose up -d --build api imac-worker
```

**GPU:**

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
# API_BASE_URL must reach FastAPI (Tailscale). If /jobs 404 on :80, expose api:8000 or use LAN port map.
.\scripts\start-gpu-worker.ps1
```

## Start distributed reaction/CNN train (laptop)

```powershell
cd C:\Users\cashh\homelab-gpu
.\scripts\submit-distributed-train.ps1 -Dataset cifar10 -ShardCount 8 -Epochs 5 -GradAccum 4 -Wait
```

**FER2013 / reactions** (FER+ labels, ResNet34, strong aug):

```powershell
cd C:\Users\cashh\homelab-gpu
.\scripts\submit-distributed-reaction.ps1 -ShardCount 8 -Epochs 60 -Wait
```

Requires on **GPU PC**: `fer2013.csv` + `fer2013new.csv` (`fetch_fer2013_csv.py`, `fetch_ferplus.py`). Plan uses `val_ratio: 0` so validation stays on the official **PublicTest** split (not a random 10% holdout).

Manual body fields: `dataset: fer2013`, `labels: ferplus`, `architecture: resnet34`, `accurate_aug: true`, `class_weights: true`, `label_smoothing: 0.1`, `val_ratio: 0`.

Manual body:

```powershell
$body = @{
  train_mode = "cnn"
  dataset = "cifar10"
  model_version = "reaction-dist-v1"
  distributed = $true
  shard_count = 8
  epochs = 5
  batch_size = 32
  grad_accum_steps = 4
  use_amp = $true
} | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98:3080/api/homelab/jobs" -Method Post `
  -Headers @{ "x-api-key" = $key; "Content-Type" = "application/json" } -Body $body
```

## Verify plan in Postgres

```bash
docker compose exec postgres psql -U app -d homelab -c \
  "SELECT train_job_id, shard_count, ready_at FROM train_plans ORDER BY created_at DESC LIMIT 3;"
```

## Research link

Reaction model goals: [REACTION-VISION.md](REACTION-VISION.md) (Barsoum FER+, ResNet). Distributed training here only changes **how batches are scheduled**; the CNN+FER objective is unchanged.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Train stays `pending` | `train_prep` not done — check imac-worker logs |
| GPU `404` on plan | Plan not ready; wait for train_prep |
| GPU cannot reach API | Set `API_BASE_URL` to reachable FastAPI (not only web :3080 for internal routes) |
| OOM | Lower `batch_size` or `grad_accum`; `stop-ollama.ps1` |

## API note

Internal route `GET /internal/worker/train/{job_id}/plan` requires **direct FastAPI** access from GPU (`WORKER_API_KEY`). The web BFF does not proxy internal worker routes.
