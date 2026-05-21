# Services

What runs in the lab and how to operate it. One row per service; link to config in this repo when it exists.

## Core infrastructure (iMac — `homelab-services/`)

| Service | Runs on | URL / access | Config path (1TB) | Backup |
|---------|---------|--------------|-------------------|--------|
| Caddy | imac-node | `http://<imac>:80` | `homelab-services/caddy/` | — |
| Prometheus | imac-node | `http://<imac>:9090` | `homelab-services/prometheus/` | `data/prometheus` |
| Grafana | imac-node | `http://<imac>:3000` | `homelab-services/data/grafana` | same |
| Backups | — | — | — | TBD `pg_dump` → external |

## Applications

| Service | Runs on | URL / access | Config path (1TB) | Notes |
|---------|---------|--------------|-------------------|-------|
| Ollama | gpu-node | `http://10.0.0.156:11434`, `http://100.88.71.33:11434` | [gpu-node.md](nodes/gpu-node.md) | `llama3.2:latest` |
| Homelab API | imac-node | `http://<imac>/chat` (via Caddy) | `homelab-services/api/` | Proxies to GPU |
| PostgreSQL | imac-node | internal | `homelab-services/data/postgres` | Chat logs |
| Redis | imac-node | internal | `homelab-services/data/redis` | Request counters |
| Qdrant | imac-node | `http://<imac>:6333` | `homelab-services/data/qdrant` | RAG (optional) |

Stack doc: [services/imac-stack.md](services/imac-stack.md)

## Per-service detail (optional)

Create `docs/services/<name>.md` when a service needs more than a table row (install steps, env vars, upgrade path).

### Example: `docs/services/example.md`

- **Purpose:**
- **Install method:** (Docker / compose / apt / Helm)
- **Data paths:**
- **Environment variables:** (names only; values in vault — see [ACCESS](ACCESS.md))
- **Upgrade:**
- **Troubleshooting:**
