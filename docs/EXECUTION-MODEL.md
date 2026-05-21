# Execution model

**Postgres is the single source of truth for system state transitions.**  
**Workers are stateless executors.** Job state lives only in Postgres on the iMac.

## Planes

| Plane | Where | Role |
|-------|-------|------|
| Control | iMac Postgres `jobs` | State machine |
| Orchestration | iMac FastAPI | Create jobs, worker callbacks |
| Execution | GPU `zak_pc` | MVW poll loop (`homelab-gpu/worker/`) |
| Controller | Laptop `cashh` | Docs, tests, SSH |

## Phase 0A flow

```text
POST /jobs (laptop) → Postgres pending
GPU worker → POST /internal/worker/jobs/claim → running
GPU run_train(job_id) → checkpoints/{job_id}/
GPU → POST .../succeeded → Postgres succeeded
```

Recovery after **kill -9:** worker startup calls `POST .../reset-stale` (running → pending), then claims again. Same `job_id` must not duplicate `published.json`.

## Who updates jobs

| Actor | Updates status |
|-------|----------------|
| FastAPI `jobs.py` | Via worker internal routes only for GPU |
| GPU `poll_jobs.py` | claim / succeeded / failed through API |
| Human | Avoid raw SQL; use API or reset-stale |

## Concurrency (0A)

- Max **1** `train` job in `running` (enforced in `claim_train_job` SQL)
- RTX 5070 12 GB: do not run Ollama + real training together ([gpu-node.md](nodes/gpu-node.md))

## SSH

| Alias | Node |
|-------|------|
| `imac-ts` | iMac stack + Postgres |
| `zak-ts` | GPU worker |

Full runbook: [PHASE-0A.md](PHASE-0A.md).
