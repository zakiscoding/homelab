# Phase 3 — QLoRA training + experiments

**Status:** Code shipped (2026-05-21) — deploy API + GPU worker  
**Prerequisite:** [Phase 2](PHASE-2.md).

## Goal

Real GPU training through the job worker (not stub), with experiment records and adapter artifacts.

```text
POST /jobs { dataset_version?, model_version? }
  → GPU worker claims → stop Ollama → QLoRA train → checkpoints/{job_id}/
  → POST .../experiment → Postgres experiments
  → optional scp adapter → iMac ML-STORE
```

## RTX 5070 rules

| Rule | Detail |
|------|--------|
| VRAM | 12 GB — **QLoRA 4-bit only** on small bases (default SmolLM2-360M) |
| Ollama | **Must stop** before train (`scripts/stop-ollama.ps1` runs automatically) |
| Concurrency | Max **1** train job `running` (unchanged) |
| Gate / debug | `TRAIN_MODE=stub` in GPU `.env` |

## GPU setup

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\setup-venv.ps1
.\.venv\Scripts\pip install -r requirements.txt
# .env: TRAIN_MODE=qlora, WORKER_API_KEY, API_BASE_URL
.\scripts\register-gpu-worker-task.ps1   # optional always-on
```

Default smoke dataset: `training/lora-quickstart/data/smoke_train.jsonl`  
Custom data: `C:\Users\zakar\homelab-data\datasets\{version}\train.jsonl`

## API

| Method | Path | Body |
|--------|------|------|
| POST | `/jobs` | optional `{ "dataset_version", "model_version", "base_model" }` |
| POST | `/internal/worker/jobs/{id}/experiment` | worker registers manifest |

## Create train job (laptop)

```powershell
$key = "YOUR_API_KEY"
$h = @{ "x-api-key" = $key; "Content-Type" = "application/json" }
$body = @{ dataset_version = "smoke"; model_version = "smoke-lora-v1" } | ConvertTo-Json -Compress
$job = Invoke-RestMethod -Uri "http://100.91.113.98/jobs" -Method Post -Headers $h -Body $body
# Start GPU worker; poll job until succeeded (first QLoRA run may take several minutes + HF download)
```

## Sync adapter to iMac ML-STORE

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
.\scripts\sync-adapter-to-imac.ps1 -JobId "<job-uuid>" -ModelVersion "smoke-lora-v1"
```

Target: `/Volumes/1tb drive/ML-STORE/models/adapters/{model_version}/`

## Env vars (GPU `.env`)

| Var | Default | Purpose |
|-----|---------|---------|
| `TRAIN_MODE` | `qlora` | `stub` for Phase 0A-style tests |
| `TRAIN_MAX_STEPS` | `30` | Short smoke train |
| `TRAIN_BASE_MODEL` | `HuggingFaceTB/SmolLM2-360M-Instruct` | Small base for 12GB |
| `TRAIN_USE_4BIT` | `true` | QLoRA; falls back if bitsandbytes missing |
| `WORKER_TRAIN_TIMEOUT_SEC` | `1800` | HTTP client timeout during train |

## Deploy (iMac API)

```bash
ssh imac-ts
source /Volumes/1tb\ drive/homelab-services/scripts/docker-1tb-env.sh
cd /Volumes/1tb\ drive/homelab-services
git pull && docker-compose up -d --build --force-recreate api
```

## Artifacts per job

```text
checkpoints/{job_id}/
├── adapter/           # PEFT weights
├── manifest.json      # reproducibility bundle
├── published.json     # idempotent marker
└── trainer_out/       # HF Trainer checkpoints (ephemeral)
```

## Next

Phase 5 ops (Grafana GPU metrics), Phase 4 optional Redis notify, Ollama adapter load for inference.
