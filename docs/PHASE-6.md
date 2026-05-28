# Phase 6 — Distributed training + MLflow

**Goal:** iMac coordinates shard plans in Postgres; GPU executes `train` jobs only after `train_prep` completes. Optional MLflow tracking on the iMac stack.

## Components

| Piece | Repo | Role |
|-------|------|------|
| `train_plans` / `train_shards` tables | homelab-services | Postgres SSOT for shard indices |
| `train_prep` job type | homelab-services API + imac-worker | iMac builds plan before GPU claims train |
| `POST /jobs` with `distributed: true` | homelab-services API | Creates train + train_prep jobs |
| MLflow server | homelab-services compose `:5001` | Experiment tracking UI |
| GPU worker | homelab-gpu | Claims train when `train_plans.ready_at` is set |

## Deploy (iMac)

```bash
cd ~/1tb-drive/homelab-services
git pull
source ./scripts/docker-1tb-env.sh
./scripts/migrate-distributed-train.sh
./scripts/migrate-mlflow.sh
docker-compose up -d --build api imac-worker mlflow
```

## Create a distributed train job

```bash
curl -s -X POST http://100.91.113.98:8000/jobs \
  -H "x-api-key: $API_KEY" \
  -H "content-type: application/json" \
  -d '{
    "type": "train",
    "payload": {
      "distributed": true,
      "dataset": "cifar10",
      "shard_count": 8,
      "train_mode": "qlora"
    }
  }'
```

Flow:

1. API inserts `train` job (pending) and `train_prep` job.
2. **imac-worker** runs `train_prep` → writes `train_plans` + shards → sets `ready_at`.
3. **GPU worker** can claim the `train` job (lease + execute).

## MLflow

| URL | Notes |
|-----|-------|
| http://100.91.113.98:5001 | UI (Tailscale) |
| Backend DB | `mlflow` database on same Postgres instance |

Artifacts: `homelab-services/data/mlflow/`

## Status

- [x] Schema `006_distributed_train.sql`
- [x] `train_plan.py` + imac-worker `run_train_prep.py`
- [x] API `distributed` flag on train job create
- [x] MLflow compose service + `007_mlflow.sql`
- [ ] End-to-end distributed QLoRA on real dataset (GPU train path uses shards)
- [ ] Log runs to MLflow from GPU worker

See [SETUP-LOG.md](SETUP-LOG.md) for deploy notes.
