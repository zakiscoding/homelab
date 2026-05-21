# Observability

Homelab monitoring: **Prometheus** scrapes metrics; **Grafana** dashboards; **`GET /system/status`** for humans/agents.

Postgres `jobs` and worker heartbeats drive operational signals — not log files alone.

## Endpoints

| URL | Auth | Purpose |
|-----|------|---------|
| http://100.91.113.98/metrics | None (LAN/Tailscale) | Prometheus scrape (API) |
| http://100.91.113.98:9090 | None | Prometheus UI |
| http://100.91.113.98:9091 | None | Pushgateway (GPU metrics) |
| http://100.91.113.98:3000 | Grafana login | Dashboards |
| http://100.91.113.98/system/status | `x-api-key` | JSON situational summary |

## Metric families

| Metric | Source | Meaning |
|--------|--------|---------|
| `homelab_http_requests_total` | API middleware | Request count by route/status |
| `homelab_http_request_duration_seconds` | API middleware | Latency histogram |
| `homelab_jobs_pending` / `_running` | Postgres (on scrape) | Queue depth by `type` |
| `homelab_jobs_failed_24h` | Postgres | Failure rate signal |
| `homelab_worker_last_seen_age_seconds` | `worker_heartbeats` | Stale worker detection |
| `homelab_redis_requests_total` | Redis | Cumulative `/chat` counter |
| `homelab_job_notify_*` | Redis | Phase 4 wake queue health |
| `homelab_gpu_*` | GPU → Pushgateway | Utilization, VRAM, temperature |

Qdrant exposes its own metrics at `:6333/metrics` (scraped as job `qdrant`).

## Health rules (operator)

| Signal | Warning | Action |
|--------|---------|--------|
| `homelab_worker_last_seen_age_seconds` > 120 | Worker offline | Restart GPU/imac worker or check Tailscale |
| `homelab_jobs_pending{type="train"}` > 0 for 30m + no running | Stuck queue | `reset-stale`, run detached worker |
| `sum(homelab_jobs_failed_24h)` rising | Pipeline errors | `GET /system/status` → `recent_failures` |
| GPU util 0% while train `running` | Train hung / CPU-only | SSH GPU, check `worker-last.log` |
| Qdrant scrape down | RAG broken | `docker-compose restart qdrant` |
| `training_paused` flag true | Ops halt | Clear in `system_settings` when healthy |

Tie Grafana alerts to these later; v1 uses dashboard thresholds.

## GPU metrics (Windows)

On `zak-ts`:

```powershell
cd C:\Users\zakar\homelab-gpu
.\scripts\push-gpu-metrics.ps1
.\scripts\register-gpu-metrics-task.ps1   # every 30s
```

Requires `PUSHGATEWAY_URL=http://100.91.113.98:9091` (default).

## Deploy

See [PHASE-5.md](PHASE-5.md).
