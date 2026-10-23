# Services

What runs in the lab and how to operate it. One row per service; link to config in this repo when it exists.

## Core infrastructure (iMac — `homelab-services/`)

| Service | Runs on | URL / access | Config path (1TB) | Backup |
|---------|---------|--------------|-------------------|--------|
| Caddy | imac-node | `http://100.91.113.98/` (Tailscale) | `homelab-services` compose | `:80` → **homelab-web** |
| **Web UI** | imac-node | `http://100.91.113.98:3080` | [homelab-web](https://github.com/zakiscoding/homelab-web) | Chat, RAG, status — [web-ui.md](services/web-ui.md) |
| Prometheus | imac-node | `http://100.91.113.98:9090` | `homelab-services/prometheus/config` | Scrapes API, Qdrant, Pushgateway |
| Pushgateway | imac-node | `http://100.91.113.98:9091` | ephemeral | GPU metrics push target |
| Grafana | imac-node | `http://100.91.113.98:3000` | `homelab-services/grafana/` | Dashboards: Homelab Stack |
| MLflow | imac-node | `http://100.91.113.98:5001` | `homelab-services/data/mlflow` | Training experiments — [MLFLOW.md](MLFLOW.md) |
| API `/metrics` | imac-node | `http://100.91.113.98/metrics` | `homelab-services/api/metrics.py` | Phase [5](PHASE-5.md) |
| Backups | — | — | — | TBD `pg_dump` → external |

## Applications

| Service | Runs on | URL / access | Config path (1TB) | Notes |
|---------|---------|--------------|-------------------|-------|
| Ollama | gpu-node | `http://100.88.71.33:11434` | [gpu-node.md](nodes/gpu-node.md) | `llama3.2:latest`; task `HomelabOllamaServe` |
| Homelab API | imac-node | internal `:8000`; `/health` via Caddy only for ops | `homelab-services/api/` | `x-api-key`; UI uses BFF proxy |
| GPU train worker | gpu-node | Polls iMac internal worker API | `homelab-gpu/worker/` | `WORKER_API_KEY`; Phase [0A](PHASE-0A.md) |
| PostgreSQL | imac-node | internal | `homelab-services/data/postgres` | Chat logs |
| Redis | imac-node | internal | `homelab-services/data/redis` | Request counters |
| Qdrant | imac-node | `http://100.91.113.98:6333` | `homelab-services/data/qdrant` | v1.18 — RAG |

Stack doc: [services/imac-stack.md](services/imac-stack.md)

## Per-service detail (optional)

| Doc | Service |
|-----|---------|
| [services/web-ui.md](services/web-ui.md) | homelab-web |
| [services/imac-stack.md](services/imac-stack.md) | Docker stack |
| [services/rag.md](services/rag.md) | RAG pipeline |

Create `docs/services/<name>.md` when a service needs more than a table row.

### Example: `docs/services/example.md`

- **Purpose:**
- **Install method:** (Docker / compose / apt / Helm)
- **Data paths:**
- **Environment variables:** (names only; values in vault — see [ACCESS](ACCESS.md))
- **Upgrade:**
- **Troubleshooting:**
