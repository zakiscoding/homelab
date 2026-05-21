# Phase 0B — Leases, retry, observability

**Status:** Deploy in progress (2026-05-21)  
**Prerequisite:** [Phase 0A](PHASE-0A.md) gate passed.

## What ships

| Feature | Where |
|---------|--------|
| Lease + auto-requeue | `jobs.lease_expires_at`, `expire_stale_leases()` |
| Retry/backoff | `attempt`, `max_attempts`, `scheduled_at`, `error_class` |
| Priority queue | `priority` (infer=10, train=50) |
| `infer` job type | `/chat` creates short-lived infer job |
| Worker heartbeats | `worker_heartbeats` + `POST /internal/worker/heartbeat` |
| System flags | `system_settings` (`training_paused`, `allow_infer_during_train`) |
| Experiments table | `experiments` (for Phase 1+ manifest linking) |
| `/system/status` | Queue depth, workers, GPU reachability, Qdrant |
| ML-STORE tree | `scripts/setup-ml-store.sh` on iMac 1TB |
| GPU worker 0B | Heartbeat, 0B `reset-stale` response, transient `failed` |

## Migrate (iMac)

```bash
ssh imac-ts
cd ~/1tb-drive/homelab-services
git pull
chmod +x scripts/migrate-phase0b.sh scripts/setup-ml-store.sh
POSTGRES_USER=app ./scripts/migrate-phase0b.sh
./scripts/setup-ml-store.sh
docker-compose up -d --build --force-recreate api
```

## Deploy GPU worker

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\run-worker-once.ps1   # smoke
# daemon: .\scripts\start-gpu-worker.ps1 or .\scripts\start-gpu-worker-bg.ps1
```

## API (new / changed)

| Method | Path | Notes |
|--------|------|--------|
| GET | `/system/status` | `x-api-key` — jobs, workers, flags, GPU, Qdrant |
| POST | `/internal/worker/heartbeat` | Worker liveness |
| POST | `/internal/worker/jobs/reset-stale` | Returns `lease_expired_requeued`, `forced_reset` |
| POST | `/internal/worker/jobs/{id}/failed` | Body: `error_message`, `error_class`, optional `retry` |
| POST | `/chat` | Creates `infer` job when DB available; `job_id` in response |

## Smoke test (laptop)

```powershell
$key = "YOUR_API_KEY"
Invoke-RestMethod -Uri "http://100.91.113.98/system/status" -Headers @{ "x-api-key" = $key }

$job = Invoke-RestMethod -Uri "http://100.91.113.98/jobs" -Method Post -Headers @{ "x-api-key" = $key }
# Start GPU worker; poll until succeeded
```

## Lease behavior

- Train jobs get **15 min** lease on claim.
- Worker crash without callback: next `reset-stale` or `expire_stale_leases()` requeues with backoff (30s / 120s / 600s) until `max_attempts` (default 3).
- `forced_reset` still resets all `running` train jobs on worker startup (operator escape hatch).

## Deferred (Phase 1+)

iMac embed/RAG worker, Redis queue, MLflow ingest, real QLoRA training, artifact sync to ML-STORE.

See [EXECUTION-MODEL.md](EXECUTION-MODEL.md).
