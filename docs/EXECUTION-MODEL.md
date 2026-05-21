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

## Phase 0B additions

```text
claim → lease_expires_at = now + 15m
failed(transient) → pending + scheduled_at backoff (if attempts remain)
lease expired → auto-requeue via expire_stale_leases() or reset-stale
/chat → infer job (priority 10) + Ollama; 503 gpu_busy if train running (unless flag set)
GET /system/status → queue + workers + flags + GPU + Qdrant
```

Runbook: [PHASE-0B.md](PHASE-0B.md).

## Phase 2 — RAG workers

| Actor | Job types | Execution |
|-------|-----------|-----------|
| **iMac worker** (`imac-worker` container) | `ingest`, `embed` | Poll `POST /internal/worker/jobs/claim-imac` |
| **FastAPI** | `rag_query` | Inline in `POST /rag/query` (like `infer` on `/chat`) |

Runbook: [PHASE-2.md](PHASE-2.md) · [services/rag.md](services/rag.md).

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
