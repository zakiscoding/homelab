# MLflow experiment tracking

Central experiment tracking for GPU training runs (reaction/FER vision, future QLoRA). MLflow runs on the **iMac** in Docker; the **GPU PC** logs params, metrics, and checkpoints over Tailscale.

## URLs

| URL | Purpose |
|-----|---------|
| http://100.91.113.98:5001 | MLflow UI (experiments, runs, artifacts) |

> **Note:** macOS AirPlay uses port **5000** on the iMac host. MLflow is published on **5001**.

Same network rules as Grafana: **Tailscale / LAN only** unless you explicitly expose a port.

## Architecture

```text
  zak_pc (GPU)                         Mos-iMac (Docker)
  ─────────────                        ─────────────────
  train_reaction_gpu.py                mlflow (host :5001)
       │                                    │
       │  MLFLOW_TRACKING_URI               ├── Postgres DB "mlflow"
       └──────────────────────────────────► └── ./data/mlflow/ (artifacts)
```

- **Backend store:** Postgres database `mlflow` (separate from `homelab` app DB).
- **Artifacts:** Host path `homelab-services/data/mlflow/` (checkpoints, `metrics.json`, etc.).
- **Experiments:** Default `reaction-vision`; override with `MLFLOW_EXPERIMENT`.

## iMac deploy

On the iMac (`~/1tb-drive/homelab-services`):

```bash
bash scripts/migrate-mlflow.sh    # CREATE DATABASE mlflow if missing
docker-compose up -d mlflow
docker-compose ps mlflow
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5001/
```

`curl` should return `200`. Artifacts directory is created by `migrate-mlflow.sh`.

### Compose service

Defined in `homelab-services/docker-compose.yml`:

- Image: `ghcr.io/mlflow/mlflow:v2.19.0`
- Port: `5001:5000` (host 5001 → container 5000)
- `--serve-artifacts` so clients can download logged files from the UI

Uses existing `POSTGRES_USER` / `POSTGRES_PASSWORD` from `.env`.

## GPU client setup

On `zak_pc` (`homelab-gpu`):

```powershell
cd C:\Users\zakar\homelab-gpu
pip install -r requirements.txt   # includes mlflow>=2.19.0
```

In `.env` (see `.env.example`):

```env
MLFLOW_TRACKING_URI=http://100.91.113.98:5001
MLFLOW_EXPERIMENT=reaction-vision
MLFLOW_REGISTERED_MODEL=homelab-reaction-fer
MLFLOW_REGISTER_MODEL=1
```

Training scripts call `training/mlflow_util.log_training_run()` after a successful run. If the URI is unset or MLflow is unreachable, training still completes; logging is best-effort.

### Experiments vs Models (registry)

| MLflow UI tab | What you see |
|---------------|----------------|
| **Experiments** | One row per training run (metrics, params, file artifacts) |
| **Models** | **Registered** PyTorch models — only after `log_model` + `registered_model_name` |

Runs alone do **not** populate the Models tab. Registration is enabled by default (`MLFLOW_REGISTER_MODEL=1`).

### What gets logged

| Item | Source |
|------|--------|
| Params | epochs, arch, batch size, dataset path, aug flags, job id |
| Metrics | best val accuracy, final train/val loss |
| Artifacts | `best_model.pt`, `manifest.json`, `metrics.json` from checkpoint dir |
| **Registered model** | PyTorch module under Models → `homelab-reaction-fer` (or `MLFLOW_REGISTERED_MODEL`) |
| Tags | `job_id`, `host`, `dataset` |

Run name defaults to the homelab job UUID when present.

### Register models for runs already in MLflow

```powershell
cd C:\Users\zakar\homelab-gpu
$env:PYTHONUTF8 = "1"
$env:MLFLOW_TRACKING_URI = "http://100.91.113.98:5001"
# Best checkpoint only (recommended):
python scripts\register_mlflow_models.py --best-only
# Or one job:
python scripts\register_mlflow_models.py --job-id 8117bfe1-85ea-4074-a967-5ebeedd40698
```

## Operator workflow

1. Start a reaction train job (web UI, API, or local script on GPU).
2. Open MLflow → experiment **reaction-vision** → compare runs by `metrics.best_val_acc`.
3. Note the winning `run_id` / homelab `job_id`; deploy that checkpoint to reaction serve (see [GPU-TRAIN.md](GPU-TRAIN.md)).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| UI unreachable on `:5001` | `docker-compose up -d mlflow`; check `docker-compose logs mlflow` |
| `database "mlflow" does not exist` | Run `bash scripts/migrate-mlflow.sh` |
| GPU prints `[mlflow] skip (...)` | Check Tailscale, URI, firewall; verify `curl http://100.91.113.98:5001` from GPU |
| `:5000` returns Apple AirTunes 403 | Expected on macOS — use **5001** |
| Artifacts missing in UI | Ensure `--serve-artifacts` in compose; artifacts live under `data/mlflow/` |
| **Models tab empty** | Runs != registry; run `register_mlflow_models.py` or train with `MLFLOW_REGISTER_MODEL=1` |

## Related

- [GPU-TRAIN.md](GPU-TRAIN.md) — FER / reaction training
- [OBSERVABILITY.md](OBSERVABILITY.md) — Grafana + Prometheus (Homelab Stack dashboard links to MLflow)
