# Phase 4 — Redis job notify (optional wake-up)

**Status:** Code shipped (2026-05-21) — deploy API + workers  
**Prerequisite:** [Phase 3](PHASE-3.md) gate passed.

## Goal

Workers wake faster when jobs become claimable, without making Redis the job queue.

| Layer | Role |
|-------|------|
| **Postgres `jobs`** | Source of truth (status, lease, retry) |
| **Redis lists** | Wake signals only (`LPUSH` on create/requeue, `BLPOP` in workers) |

```text
POST /jobs → INSERT Postgres pending → LPUSH homelab:jobs:wake:{train|imac}
GPU/iMac worker → BLPOP (timeout = poll interval) → POST .../claim → run → update Postgres
```

## Redis queues

| Queue | Worker | Job types |
|-------|--------|-----------|
| `homelab:jobs:wake:train` | GPU `poll_jobs.py` | `train` |
| `homelab:jobs:wake:imac` | `imac-worker` | `ingest`, `embed` |

`infer` / `rag_query` are inline in the API — no Redis wake.

## Env vars

| Var | Where | Default | Purpose |
|-----|-------|---------|---------|
| `JOB_NOTIFY_ENABLED` | API, workers | `true` | Set `false` to fall back to poll-only |
| `REDIS_URL` | API, imac-worker | `redis://redis:6379/0` | Notify + RAG cache |
| `REDIS_URL` | GPU `.env` | `redis://100.91.113.98:6379/0` | Reach iMac Redis over Tailscale |
| `WORKER_POLL_SEC` | workers | `10` | BLPOP timeout when idle |

## Deploy (iMac)

```bash
ssh imac-ts
source /Volumes/1tb\ drive/homelab-services/scripts/docker-1tb-env.sh
cd /Volumes/1tb\ drive/homelab-services
git pull
docker-compose up -d --build --force-recreate api imac-worker
# Redis now publishes 6379 for GPU wake (LAN/Tailscale)
```

## Deploy (GPU)

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
.\.venv\Scripts\pip install redis
# Add to .env:
#   REDIS_URL=redis://100.91.113.98:6379/0
#   JOB_NOTIFY_ENABLED=true
.\scripts\register-gpu-worker-task.ps1   # or run-worker-detached.ps1 for one shot
```

## Verify

```powershell
$key = "YOUR_API_KEY"
$h = @{ "x-api-key" = $key }
(Invoke-RestMethod http://100.91.113.98/system/status -Headers $h).job_notify
# enabled: true, queues may show depth after POST /jobs

$body = @{ dataset_version = "smoke"; model_version = "phase4-test" } | ConvertTo-Json -Compress
Invoke-RestMethod http://100.91.113.98/jobs -Method Post -Headers ($h + @{"Content-Type"="application/json"}) -Body $body
# GPU worker should claim within ~1s if notify + worker running (vs up to WORKER_POLL_SEC without)
```

Disable notify (poll-only mode): `JOB_NOTIFY_ENABLED=false` on API and workers.

## Phase 4 done when

- [ ] `GET /system/status` shows `job_notify.enabled: true`
- [ ] Creating a `train` job pushes to `homelab:jobs:wake:train`
- [ ] GPU worker claims without waiting full poll interval (worker log shows `notify=true`)
- [ ] Postgres still authoritative (worker always uses `claim` API)

## Next

[Phase 5](PHASE-5.md) ops / Grafana, or Ollama adapter load for trained models.
