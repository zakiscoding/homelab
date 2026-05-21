# Phase 0A — Job control plane (execution gate)

**Status:** Deployed on iMac + GPU (2026-05-21); gate test in progress  
**Goal:** Prove jobs survive worker crash without duplicate artifacts.  
**Hardware:** RTX 5070 12 GB — train uses stub in 0A; stop Ollama before real QLoRA (Phase 3).

## What shipped

| Component | Repo | Path |
|-----------|------|------|
| `jobs` table | homelab-services | `postgres/002_jobs.sql` |
| Job API | homelab-services | `api/jobs.py`, `api/main.py` |
| Migration script | homelab-services | `scripts/migrate-jobs.sh` |
| GPU MVW worker | homelab-gpu | `worker/poll_jobs.py`, `worker/run_train.py` |
| Start worker | homelab-gpu | `scripts/start-gpu-worker.ps1` |

**Principle:** Postgres on iMac is the only source of truth for job state. GPU worker is stateless; it calls the iMac API (not Postgres directly).

## SSH hosts (controller `cashh`)

| Alias | Node | User |
|-------|------|------|
| `imac-ts` | Mos-iMac | `momo` |
| `zak-ts` | zak_pc | `zakar` |

Config: `~/.ssh/config` on laptop.

## API endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/jobs` | `x-api-key` | Create `train` job (`pending`) |
| GET | `/jobs/{id}` | `x-api-key` | Poll status |
| POST | `/internal/worker/jobs/claim` | `X-Worker-Key` + `X-Worker-Id` | GPU claims one job (204 = none) |
| POST | `/internal/worker/jobs/{id}/succeeded` | `X-Worker-Key` | Mark done |
| POST | `/internal/worker/jobs/{id}/failed` | `X-Worker-Key` | Mark failed |
| POST | `/internal/worker/jobs/reset-stale` | `X-Worker-Key` | `running` → `pending` after kill -9 |

## Environment variables

**iMac** (`homelab-services/.env`):

```bash
WORKER_API_KEY=<long-random-different-from-API_KEY>
```

**GPU** (`homelab-gpu/.env`):

```bash
API_BASE_URL=http://100.91.113.98
WORKER_API_KEY=<same as iMac>
CHECKPOINT_DIR=C:\Users\zakar\homelab-data\checkpoints
```

## Deploy on iMac (`momo`)

```bash
ssh imac-ts
cd ~/1tb-drive/homelab-services   # or "/Volumes/1tb drive/homelab-services"
git pull
# Add WORKER_API_KEY to .env if missing
chmod +x scripts/migrate-jobs.sh
# Postgres user on this homelab is `app` (see .env POSTGRES_USER)
POSTGRES_USER=app ./scripts/migrate-jobs.sh
docker-compose up -d --build api
curl http://localhost/health
```

If Colima is stopped: `colima start` then `docker-compose up -d` (see [imac-stack.md](services/imac-stack.md)).

## Deploy on GPU (`zakar`)

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\setup-venv.ps1   # if needed
.\.venv\Scripts\pip install httpx
# Copy .env.example → .env; WORKER_API_KEY must match iMac homelab-services/.env
.\scripts\start-gpu-worker.ps1
# One cycle (debug): .\scripts\run-worker-once.ps1
```

## Gate test (from laptop)

```powershell
# 1. Create job (use API_KEY from iMac .env)
$key = "YOUR_API_KEY"
$job = Invoke-RestMethod -Uri "http://100.91.113.98/jobs" -Method Post -Headers @{ "x-api-key" = $key }
$job.id

# 2. Watch status
Invoke-RestMethod -Uri "http://100.91.113.98/jobs/$($job.id)" -Headers @{ "x-api-key" = $key }

# 3. Kill worker mid-run on GPU (Task Manager or Stop-Process), then restart worker
# 4. If stuck running: worker calls reset-stale on startup, or:
$wk = "YOUR_WORKER_API_KEY"
Invoke-RestMethod -Uri "http://100.91.113.98/internal/worker/jobs/reset-stale" -Method Post -Headers @{ "X-Worker-Key" = $wk }

# 5. Assert one published.json under checkpoints\{job_id}\ on GPU
```

## Idempotency (0A)

- Artifacts only under `CHECKPOINT_DIR/{job_id}/`
- `published.json` written once per job_id; re-run does not create a second publish file
- Max **1** `train` job `running` at a time (SQL + claim query)

## RTX 5070 rules

- **0A stub** does not use CUDA (safe with Ollama up for other tests)
- **Real LoRA (Phase 3):** run `scripts/stop-ollama.ps1` first; QLoRA 4-bit only; see [nodes/gpu-node.md](nodes/gpu-node.md)

## Deferred (Phase 0B+)

Auto-retry/backoff, leases, iMac ingest/embed worker, `/system/status`, ML-STORE, RAG pipeline, Redis queue.

See [EXECUTION-MODEL.md](EXECUTION-MODEL.md) and [SETUP-LOG.md](SETUP-LOG.md).
