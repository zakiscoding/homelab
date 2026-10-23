# iMac (Mos-iMac) — quick checklist

**Purpose:** Application platform and data services.  
**Not for:** Large LLM inference, heavy training, or CUDA workloads — use the **GPU PC** (`zak_pc`). The **Apple M1** is for services.

**Tailscale:** `100.91.113.98` · **Stack:** [homelab-services](https://github.com/zakiscoding/homelab-services)

---

## Install (host)

| Item | Status | Notes |
|------|--------|-------|
| Docker (via **Colima**) | [x] | `homelab-runtime/colima/` on 1TB |
| Colima | [x] | `brew install colima docker docker-compose` |
| Tailscale | [x] | SSH + API from controller |
| Git clones on 1TB | [x] | `homelab/`, `homelab-services/`, `homelab-gpu/` (mirror) |

---

## Run containers

| Container | Status | Role |
|-----------|--------|------|
| **API** (FastAPI) | [x] | Gateway to Ollama |
| **Web UI** (`homelab-web`) | [x] | `:3081`, Caddy `:80` |
| **Caddy** | [x] | `:80` → `web:3000` |
| **PostgreSQL** | [x] | Persistent data |
| **Redis** | [x] | Cache / counters |
| **Qdrant** | [x] | Vector DB (RAG-ready) |
| **Prometheus** | [x] | Metrics |
| **Grafana** | [x] | Dashboards |

Start: `homelab-services/scripts/start-stack.sh`

---

## API — FastAPI

**Responsibilities:**

| Responsibility | Status | Today |
|----------------|--------|-------|
| Authentication | [~] | `x-api-key` on `/chat`, `/stats` — not full user auth |
| Request validation | [x] | Pydantic models on `/chat` |
| Logging | [~] | Chat rows in Postgres — no structured app log yet |
| Calling the LLM | [x] | `api/llm.py`, `LLM_BACKEND=auto`: vLLM (Ubuntu boot) else Ollama via `GPU_URL` |
| Returning responses | [x] | JSON to client |

Endpoints: `/health`, `/health/gpu`, `/chat`, `/rag/*`, `/jobs`, `/system/status` — UI at [web-ui.md](../services/web-ui.md)

---

## Reverse proxy — Caddy

| Responsibility | Status | Today |
|----------------|--------|-------|
| Routing | [x] | `:80` → `web:3000` (UI); API internal only |
| HTTPS | [ ] | Optional — [public-internet.md](../deploy/public-internet.md) |
| Rate limiting | [ ] | Not configured |
| Public endpoint management | [~] | Tailscale/LAN; no WAN by default |

---

## Database — PostgreSQL

**Should store:**

| Data | Status | Today |
|------|--------|-------|
| Users | [ ] | Schema TBD |
| Chats | [x] | `chat_logs` table |
| Settings | [ ] | Schema TBD |
| Logs | [~] | Chat logs only |
| Metadata | [ ] | Schema TBD |

---

## Cache — Redis

**Should store:**

| Data | Status | Today |
|------|--------|-------|
| Session data | [ ] | Not wired |
| Queues | [ ] | Not wired (future async jobs) |
| Temporary cache | [~] | `homelab:requests:total` counter only |

---

## Vector search — Qdrant

**Should store:**

| Data | Status | Today |
|------|--------|-------|
| Embeddings | [ ] | Service up; API not integrated |
| Documents | [ ] | Ingest pipeline TBD |
| Knowledge base vectors | [ ] | RAG flow TBD |

Port **6333** exposed for when RAG is built.

---

## Monitoring

| Tool | Status | Port |
|------|--------|------|
| Prometheus | [x] | 9090 |
| Grafana | [x] | 3000 |

**Should track:**

| Metric | Status |
|--------|--------|
| API requests | [~] | Redis counter; no Prometheus scrape of API yet |
| Database health | [~] | Compose healthcheck on Postgres |
| GPU metrics | [ ] | Add exporter on `zak_pc` + scrape config |
| Service uptime | [~] | Manual `docker-compose ps`; Grafana defaults |

---

## Exposed ports (iMac)

| Port | Service |
|------|---------|
| **80** | Caddy → API |
| **3000** | Grafana |
| **6333** | Qdrant |
| **9090** | Prometheus |

API is **internal** on 8000 — browser uses **web UI** on `:3081` / Caddy `:80` (BFF proxy).

---

## Should NOT run on iMac

| Workload | Where instead |
|----------|----------------|
| Large LLM inference | GPU PC — Ollama `:11434` |
| Heavy model training | GPU PC — [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) |
| Large CUDA workloads | GPU PC (RTX 5070) |

---

## Related docs

- [imac-node.md](imac-node.md) — install & commands
- [imac-stack.md](../services/imac-stack.md) — compose runbook
- [gpu-node.md](gpu-node.md) — inference + training node
- [DRIVE-LAYOUT.md](../DRIVE-LAYOUT.md) — 1TB paths

Legend: **[x]** done · **[~]** partial · **[ ]** planned
