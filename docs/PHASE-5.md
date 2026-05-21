# Phase 5 — Ops / observability

**Status:** Deployed (2026-05-21) — iMac stack + GPU metrics push  
**Prerequisite:** [Phase 4](PHASE-4.md).

## Goal

See platform health in Grafana: API traffic, job queues, workers, Qdrant, and **RTX 5070** GPU stats.

```text
API /metrics ← Prometheus ← Grafana dashboard
GPU nvidia-smi → Pushgateway :9091 → Prometheus
Qdrant :6333/metrics → Prometheus
```

`GET /system/status` remains the human/agent summary; metrics are for trends and alerts.

## Stack changes

| Component | Change |
|-----------|--------|
| **API** | `GET /metrics` (Prometheus), HTTP + job gauges |
| **Prometheus** | Config mounted; scrapes `api`, `qdrant`, `pushgateway` |
| **Pushgateway** | New service `:9091` |
| **Grafana** | Provisioned Prometheus datasource + **Homelab ML Platform** dashboard |
| **GPU** | `push-gpu-metrics.ps1` + optional scheduled task |

## Deploy (iMac)

```bash
ssh imac-ts
source /Volumes/1tb\ drive/homelab-services/scripts/docker-1tb-env.sh
cd /Volumes/1tb\ drive/homelab-services
git pull
docker-compose up -d --build --force-recreate api prometheus pushgateway grafana
```

## Deploy (GPU metrics)

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\push-gpu-metrics.ps1
.\scripts\register-gpu-metrics-task.ps1
```

## Verify

```powershell
# Prometheus targets UP
curl.exe http://100.91.113.98:9090/api/v1/targets

# API metrics
curl.exe http://100.91.113.98/metrics | findstr homelab_jobs

# Grafana — login, open folder Homelab → Homelab ML Platform
# http://100.91.113.98:3000
```

| Check | Expected |
|-------|----------|
| Target `homelab-api` | `health: up` |
| Target `qdrant` | `health: up` |
| Target `pushgateway` | `health: up` |
| Dashboard GPU panels | Data after `push-gpu-metrics.ps1` |
| `homelab_jobs_pending` | Matches `/system/status` queue |

## Env vars

| Var | Where | Default |
|-----|-------|---------|
| `METRICS_REFRESH_SEC` | API | `15` — Postgres gauge refresh cadence |
| `PUSHGATEWAY_URL` | GPU scripts | `http://100.91.113.98:9091` |
| `GRAFANA_USER` / `GRAFANA_PASSWORD` | iMac `.env` | `admin` / change-me |

## Phase 5 done when

- [ ] Prometheus scrapes API, Qdrant, Pushgateway (all up)
- [ ] Grafana dashboard shows job queues + API rate
- [ ] GPU utilization/VRAM visible after metrics task runs
- [ ] [OBSERVABILITY.md](OBSERVABILITY.md) health rules understood

## Next

Load trained adapters into Ollama for inference, ML-STORE sync automation, or Grafana alerting rules.
