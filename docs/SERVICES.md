# Services

What runs in the lab and how to operate it. One row per service; link to config in this repo when it exists.

## Core infrastructure (iMac — `homelab-services/`)

| Service | Runs on | URL / access | Config path (1TB) | Backup |
|---------|---------|--------------|-------------------|--------|
| Caddy | imac-node | `http://100.91.113.98/` (Tailscale) | `homelab-services` compose | `:80` → **homelab-web** |
| **Web UI** | imac-node | `http://100.91.113.98:3081` | [homelab-web](https://github.com/zakiscoding/homelab-web) | Chat, RAG, reactions — [web-ui.md](services/web-ui.md) |
| Reaction vision API | imac-node | `/vision/*` on API `:8000` | `homelab-services/api/vision_routes.py` | Proxies GPU `:8100` |
| Prometheus | imac-node | `http://100.91.113.98:9090` | `homelab-services/prometheus/config` | Scrapes API, Qdrant, Pushgateway |
| Pushgateway | imac-node | `http://100.91.113.98:9091` | ephemeral | GPU metrics push target |
| Grafana | imac-node | `http://100.91.113.98:3000` | `homelab-services/grafana/` | Dashboards: Homelab ML Platform, Homelab Stack, GPU node |
| MLflow | imac-node | `http://100.91.113.98:5001` | `homelab-services/data/mlflow` | Training experiments — [MLFLOW.md](MLFLOW.md) |
| API `/metrics` | imac-node | `http://100.91.113.98/metrics` | `homelab-services/api/metrics.py` | Phase [5](PHASE-5.md) |
| Backups | imac-node | — | `homelab-services/scripts/backup-postgres.sh` | Manual `pg_dump`; schedule pending — [BACKUPS.md](BACKUPS.md) |

## Applications

| Service | Runs on | URL / access | Config path (1TB) | Notes |
|---------|---------|--------------|-------------------|-------|
| **LLM backend** (chat + RAG) | iMac API → GPU PC | `LLM_BACKEND=auto` in `homelab-services/.env` | `homelab-services/api/llm.py` | vLLM when the PC runs Ubuntu, else Ollama (re-checked every 30 s) |
| vLLM (Ubuntu boot) | zak-gpu-node | `http://100.121.51.35:8000/v1` (API key) | `gpu-systems-lab/serving/compose.yml` | `qwen2.5-1.5b-instruct`; chat ~0.3–0.5 s |
| Ollama (Windows boot) | gpu-node | `http://100.88.71.33:11434` | [gpu-node.md](nodes/gpu-node.md) | `llama3.2:latest`; task `HomelabOllamaServe` |
| Homelab API | imac-node | internal `:8000`; `/health` via Caddy only for ops | `homelab-services/api/` | `x-api-key`; UI uses BFF proxy |
| GPU train worker | gpu-node | Polls iMac internal worker API | `homelab-gpu/worker/` | `WORKER_API_KEY`; Phase [0A](PHASE-0A.md); skips routed jobs |
| **Router worker** | laptop (controller) | `python -m router.homelab_worker` | `gpu-systems-lab/router/` | claims `route` jobs only; runs on local RTX or Modal; decision → `experiments` |
| PostgreSQL | imac-node | internal | `homelab-services/data/postgres` | Job queue (single source of truth), chat logs, RAG metadata |
| Redis | imac-node | internal | `homelab-services/data/redis` | Request counters, job wake queues |
| Qdrant | imac-node | `http://100.91.113.98:6333` | `homelab-services/data/qdrant` | v1.18 — RAG |

Stack doc: [services/imac-stack.md](services/imac-stack.md)

## GPU node — Ubuntu boot (`zak-gpu-node`, `gpu-systems-lab`)

Only up while the PC is booted into Ubuntu (the Windows services above are down then).

| Service | Runs on | URL / access | Config | Notes |
|---------|---------|--------------|--------|-------|
| Grafana (GPU) | zak-gpu-node | `http://100.121.51.35:3000/d/gpu-node` | `gpu-systems-lab/observability/` | tailnet only; anonymous view |
| Prometheus (GPU) | zak-gpu-node | `http://100.121.51.35:9090` | `gpu-systems-lab/observability/prometheus/` | alerts: GPU temp > 85 °C, VRAM > 95%, XID, exporter down |
| dcgm-exporter | zak-gpu-node | `127.0.0.1:9400/metrics` | `observability/dcgm/counters.csv` | SM active, tensor pipe, power, temp, PCIe |
| k3s + GPU queue | zak-gpu-node | `kubectl` (kubeconfig on node) | `gpu-systems-lab/scheduling/` | `submit.py`; admission policy enforces GPU limits |
| vLLM | zak-gpu-node | `http://100.121.51.35:8000/v1` (OpenAI API, API key) | `gpu-systems-lab/serving/compose.yml` | always-on Docker; homelab chat backend (see Applications) |
| Job router | laptop | `python -m router route/run` | `gpu-systems-lab/router/` | local RTX vs Modal by VRAM, deadline, cost |

## Per-service detail (optional)

| Doc | Service |
|-----|---------|
| [services/web-ui.md](services/web-ui.md) | homelab-web |
| [services/imac-stack.md](services/imac-stack.md) | Docker stack |
| [services/rag.md](services/rag.md) | RAG pipeline |
| [services/vision-reactions.md](services/vision-reactions.md) | FER / reactions |
| [PHASE-6.md](PHASE-6.md) | Distributed train + MLflow |

Create `docs/services/<name>.md` when a service needs more than a table row.

### Example: `docs/services/example.md`

- **Purpose:**
- **Install method:** (Docker / compose / apt / Helm)
- **Data paths:**
- **Environment variables:** (names only; values in vault — see [ACCESS](ACCESS.md))
- **Upgrade:**
- **Troubleshooting:**
