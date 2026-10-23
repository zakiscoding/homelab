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
| http://100.91.113.98:5001 | None (LAN/Tailscale) | MLflow experiment tracking |
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
| `homelab_host_*` | GPU → Pushgateway | Host CPU %, RAM MiB |
| `homelab_reaction_serve_up` / `homelab_ollama_up` | GPU → Pushgateway | Service health on zak_pc |
| `homelab_vision_*` | API vision proxy | Reaction `/vision` request rate & latency |

Dashboard **Homelab Stack** (`homelab-stack.json`) adds GPU PC CPU/RAM, vision latency, and quick links to MLflow and `/reactions`.

See [MLFLOW.md](MLFLOW.md) for experiment tracking on `:5001` (macOS reserves `:5000` for AirPlay).

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

## GPU metrics (Ubuntu boot — DCGM)

When the GPU PC runs Ubuntu (`zak-gpu-node`), it has its own stack
([gpu-systems-lab/observability](https://github.com/zakiscoding/gpu-systems-lab/tree/main/observability)):
**dcgm-exporter → Prometheus → Grafana**, plus node-exporter. Docker Compose; ports bound to the
tailnet.

| URL | Purpose |
|-----|---------|
| http://100.121.51.35:3000/d/gpu-node | Grafana GPU dashboard (21 panels, anonymous view) |
| http://100.121.51.35:9090 | Prometheus (5 s scrape, 15-day retention) |

DCGM works on this GeForce card, including the profiling fields (SM active, occupancy, tensor-pipe,
DRAM activity, PCIe bytes). There are no NVLink, ECC or MIG metrics, and memory temperature reads 0.
Measured under load: GPU 0 → 100%, power 2 → 229 W, 36 → 63 °C, SM clock 180 → 2,820 MHz.

**One pane (done 2026-10-23):** the iMac Grafana (`:3000`) has `100.121.51.35:9090` as a second
datasource, **"GPU node (zak-gpu-node)"** (uid `gpu-node-prom`), and the GPU dashboard
**"GPU node (RTX 5070, zak-gpu-node)"** sits in the Homelab folder next to the platform dashboards.
Provisioned from `homelab-services/grafana/`. It shows no data while the PC runs Windows.

## Deploy

See [PHASE-5.md](PHASE-5.md).
