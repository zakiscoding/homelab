# Homelab — Complete Overview (Shareable Document)

**Document purpose:** Standalone description of the homelab for collaborators, reviewers, or future you.  
**No access required** to other files in the repository — everything essential is here.  
**Last updated:** May 22, 2026  
**Owner / GitHub:** [zakiscoding](https://github.com/zakiscoding) (private repositories)

---

## 1. Executive summary

This homelab is a **three-machine AI platform** built at home:

1. A **Windows GPU desktop** (`zak_pc`) runs **LLM inference** (Ollama), **fine-tuning** (PyTorch / QLoRA), and a **GPU job worker** that polls the iMac.
2. An **Apple iMac** (`Mos-iMac`) runs the **application layer**: Next.js web UI, FastAPI, Postgres (job control plane), Redis, Qdrant (RAG), reverse proxy, and monitoring — all in Docker via Colima on a 1 TB external drive.
3. A **Windows laptop** (`cashh`) is the **controller**: documentation, Git, browser access to the UI, `curl` tests, and SSH (`imac-ts`, `zak-ts`).

Machines connect over **home LAN** and **Tailscale**. **Default access is Tailscale only** — no public internet exposure unless you optionally add a domain and port-forward (documented separately).

**What works today (MVP):**

| Capability | How |
|------------|-----|
| **Web UI** | Chat, RAG ingest/query, platform status at `http://100.91.113.98:3080` |
| **Chat inference** | Browser → iMac web → API → GPU Ollama → response |
| **RAG** | Ingest text → iMac worker embeds → Qdrant → query with citations |
| **Jobs** | Postgres SSOT; GPU + iMac workers; Redis wake on job create |
| **Training** | QLoRA smoke train on GPU; artifacts under `homelab-data/checkpoints/` |
| **Monitoring** | Prometheus + Grafana (“Homelab ML Platform” dashboard) |
| **GPU metrics** | Pushgateway from GPU PC every minute |

**What is intentionally not in public Git:** model weights, datasets, API keys, database passwords, checkpoints, and `.env` files.

---

## 2. High-level architecture

```text
                    ┌──────────────────────────────────────┐
                    │  Controller laptop (Windows)         │
                    │  User: cashh                         │
                    │  Browser, git, SSH (imac-ts / zak-ts)│
                    └──────────────────┬───────────────────┘
                                       │ Tailscale / LAN
                   ┌───────────────────┴────────────────────┐
                   │                                        │
        ┌──────────▼──────────┐              ┌─────────────▼─────────────┐
        │  GPU PC (Windows)   │              │  iMac (macOS, M1)         │
        │  zak_pc · zakar       │              │  Mos-iMac · momo            │
        │                       │              │                           │
        │  • Ollama :11434      │◄── HTTP ─────│  • Web UI :3080 / Caddy :80 │
        │  • RTX 5070 12GB      │   inference  │  • FastAPI (internal :8000)│
        │  • homelab-gpu        │              │  • Postgres, Redis, Qdrant│
        │  • GPU train worker   │── poll jobs ─│  • imac-worker (RAG)      │
        │  • Jupyter :8888      │              │  • Prometheus, Grafana    │
        └─────────────────────┘              └───────────────────────────┘
```

### Request flow (chat via web UI)

1. User opens **http://100.91.113.98:3080** (or `http://100.91.113.98/` via Caddy).
2. **homelab-web** (Next.js) proxies `/api/homelab/chat` to **FastAPI** with `x-api-key` on the server (key never in the browser).
3. FastAPI calls **Ollama** on the GPU (`http://100.88.71.33:11434`).
4. Response returns to the UI; chat may be logged in **Postgres**.

### Request flow (RAG)

1. User ingests text in the **RAG** tab → API creates ingest + embed jobs.
2. **imac-worker** chunks, embeds via GPU/Ollama path, stores vectors in **Qdrant**.
3. User queries → API searches Qdrant → LLM answer with citations.

### Design principles

| Principle | Rationale |
|-----------|-----------|
| **GPU does heavy ML** | VRAM for Ollama + training; iMac M1 runs services only |
| **iMac owns state** | Postgres job plane, RAG, metrics, API keys |
| **Four Git repos** | Docs, iMac stack, GPU training code, web UI — see §5 |
| **Private GitHub** | No secrets in git |
| **Tailscale default** | Remote ops without WAN port-forward |
| **Web BFF** | API key stays on iMac in the Next.js server layer |

---

## 3. Hardware and identities

| Machine | Hostname | OS | Primary user | Hardware notes |
|---------|----------|-----|--------------|----------------|
| **GPU desktop** | `zak_pc` | Windows | `zakar` | NVIDIA GeForce **RTX 5070**, 12 GB VRAM |
| **iMac** | `Mos-iMac` | macOS 15.7 | `momo` | **Apple M1** |
| **Laptop** | — | Windows | `cashh` | Controller — no homelab services required |

**Important:** GPU PC is **`zakar`**; laptop is **`cashh`**. They are different machines.

---

## 4. Network and access

### Local network (example)

| Node | LAN IPv4 | Notes |
|------|----------|-------|
| GPU PC | `10.0.0.156` | Ollama `11434`, Jupyter `8888` |
| iMac | (DHCP) | Web `3080`, Caddy `80`, Grafana `3000` |
| Home gateway | `10.0.0.1` | Typical |

### Tailscale (primary remote access)

| Node | Tailscale IPv4 | Key services |
|------|----------------|--------------|
| GPU PC | `100.88.71.33` | Ollama `:11434` |
| iMac | `100.91.113.98` | Web UI `:3080`, Caddy `:80`, Grafana `:3000` |
| Laptop | `100.73.132.95` | Controller |

### Security posture

- GitHub repos are **private**.
- **Do not** port-forward Ollama (`11434`) or internal API (`8000`) to the internet.
- Web UI uses server-side API proxy; direct API calls still need `x-api-key`.
- Optional public HTTPS: domain + router `80/443` → iMac Caddy only (see homelab `docs/deploy/public-internet.md`).
- GPU firewall: **Ollama LAN** rule; Ollama bound via `OLLAMA_HOST=0.0.0.0:11434`.

---

## 5. GitHub repositories (four-repo model)

| Repository | Runs on | Contains |
|------------|---------|----------|
| **homelab** | All nodes (docs) | Markdown, architecture, phases, setup log |
| **homelab-services** | **iMac** | Docker Compose, FastAPI, Caddy, workers, DB migrations |
| **homelab-gpu** | **GPU PC** | Training scripts, GPU worker, Ollama helpers, notebooks |
| **homelab-web** | **Laptop dev**, **iMac prod** | Next.js UI — chat, RAG, status |

### Local paths (canonical copies)

| Machine | homelab | homelab-services | homelab-gpu | homelab-web |
|---------|---------|------------------|-------------|-------------|
| **iMac** | `…/homelab` | `…/homelab-services` | `…/homelab-gpu` (mirror) | `…/homelab-web` (sibling) |
| **Laptop** | `C:\Users\cashh\homelab` | optional clone | — | `C:\Users\cashh\homelab-web` |
| **GPU PC** | optional | — | `C:\Users\zakar\homelab-gpu` | — |

**Workflow:** `git pull` → edit → `git commit` → `git push`. Secrets only in `.env` / `.env.local` (never committed).

---

## 6. GPU node (`zak_pc`) — inference and training

**Rule:** GPU runs **ML and the train worker only** — not Postgres, Redis, Grafana, Qdrant, or the main API.

### 6.1 Inference — Ollama

| Item | Detail |
|------|--------|
| Software | [Ollama](https://ollama.com) on Windows |
| Port | `11434` on `0.0.0.0` (`OLLAMA_HOST=0.0.0.0:11434`) |
| Model (example) | `llama3.2:latest` |
| **Persistent start** | Scheduled task **`HomelabOllamaServe`** → `homelab-gpu/scripts/serve-ollama.bat` |
| Quick recovery | `schtasks /Run /TN HomelabOllamaServe` |

**Health check (from laptop):**

```text
GET http://100.88.71.33:11434/api/tags
```

If this fails, the web UI chat stays on “Thinking…”.

**Scripts (homelab-gpu):**

| Script | Purpose |
|--------|---------|
| `install-ollama-serve-task.ps1` | One-time Admin setup — task + firewall |
| `start-ollama.ps1` | Quick start / run task |
| `stop-ollama.ps1` | Free VRAM before training |

### 6.2 Training and GPU worker

| Item | Path or tool |
|------|----------------|
| Repo | `C:\Users\zakar\homelab-gpu` |
| Python | 3.12, `.venv`, PyTorch (CUDA 12.8 for RTX 5070) |
| Training | `training/lora_quickstart/train.py` — QLoRA smoke **succeeded** |
| Worker | Polls iMac `POST /internal/worker/jobs/claim` for `train` jobs |
| Data (local) | `C:\Users\zakar\homelab-data\` — datasets, checkpoints |
| Jupyter | `scripts/start-jupyter.ps1` → `:8888` |
| Metrics | `scripts/push-gpu-metrics.ps1` → iMac Pushgateway `:9091` |

**Before long training:** `stop-ollama.ps1` to free VRAM.

---

## 7. iMac node (`Mos-iMac`) — application stack

### 7.1 Docker runtime

| Item | Detail |
|------|--------|
| Runtime | **Colima** on 1 TB drive |
| Colima | `/Volumes/1tb drive/homelab-runtime/colima` |
| Compose | `/Volumes/1tb drive/homelab-services` |
| Symlink | `~/1tb-drive/homelab-services` (paths with spaces) |

**Always before docker commands:** `source ./scripts/docker-1tb-env.sh`

Key scripts: `setup-1tb.sh`, `start-stack.sh`, `ensure-homelab-web.sh`, `render-caddyfile.sh`, `bootstrap-env.sh`.

### 7.2 Running containers

| Container | Purpose | Tailscale port |
|-----------|---------|----------------|
| **web** | Next.js UI (homelab-web) | **3080** |
| **caddy** | Reverse proxy → `web:3000` | **80**, 443 |
| **api** | FastAPI — chat, RAG, jobs, metrics | internal 8000 |
| **imac-worker** | RAG ingest + embed | internal |
| **postgres** | Jobs, chat logs, RAG metadata | internal |
| **redis** | Counters, job wake queues | **6379** (GPU worker) |
| **qdrant** | Vector search | **6333** |
| **prometheus** | Metrics scrape | **9090** |
| **grafana** | Dashboards | **3000** |
| **pushgateway** | GPU metric push | **9091** |

### 7.3 API surface (summary)

| Area | Endpoints | Auth |
|------|-----------|------|
| Health | `/health`, `/health/gpu` | None / LAN |
| Chat | `POST /chat` | `x-api-key` |
| RAG | `POST /rag/ingest`, `POST /rag/query`, `GET /rag/status` | `x-api-key` |
| Jobs | `POST /jobs`, `GET /jobs/{id}` | `x-api-key` |
| Workers | `/internal/worker/*` | `X-Worker-Key` |
| Metrics | `GET /metrics` | LAN/Tailscale |
| System | `GET /system/status` | `x-api-key` |

The **web UI** calls these through `/api/homelab/*` on the Next.js server (browser never holds the API key).

### 7.4 Web UI (homelab-web)

| Item | Detail |
|------|--------|
| Repo | github.com/zakiscoding/homelab-web |
| Production URL | http://100.91.113.98:3080 or http://100.91.113.98/ |
| Pages | `/` overview, `/chat`, `/rag` |
| Dev | `npm run dev` on laptop → `http://localhost:3000` |
| Deploy | `docker-compose up -d --build web caddy` on iMac |

---

## 8. Controller laptop (`cashh`)

| Responsibility | Detail |
|----------------|--------|
| Documentation | Edit **homelab**, push to GitHub |
| Web dev | **homelab-web** locally |
| Browser | Production UI on iMac Tailscale IP |
| SSH | `ssh imac-ts` (iMac), `ssh zak-ts` (GPU) — `~/.ssh/config` |
| Testing | `curl.exe`, PowerShell `Invoke-RestMethod` |

The laptop does **not** need Docker or Ollama for the homelab to run.

**Deploy UI to iMac (example):**

```bash
ssh imac-ts
cd ~/1tb-drive/homelab-services && git pull
./scripts/ensure-homelab-web.sh
source ./scripts/docker-1tb-env.sh
./scripts/render-caddyfile.sh
docker-compose up -d --build web caddy
```

---

## 9. 1TB external drive layout (iMac)

```text
/Volumes/1tb drive/
├── homelab/              ← documentation (git)
├── homelab-services/     ← Docker stack (git)
├── homelab-web/          ← Next.js UI (git, sibling of services)
├── homelab-gpu/          ← training mirror (git, optional)
├── homelab-runtime/      ← Colima (not git)
└── Personal/             ← non-homelab
```

Persistent service data: `homelab-services/data/` (Postgres, Grafana, Qdrant, etc.).

---

## 10. Platform phases (what was built)

| Phase | Theme | Status |
|-------|--------|--------|
| **0A** | Job control plane, GPU worker, leases | Done |
| **0B** | Retry, stale jobs, `/system/status`, ML-STORE paths | Done |
| **1** | `/chat` inference + infer jobs | Done |
| **2** | RAG — ingest, embed, Qdrant, `/rag/query` | Done |
| **3** | QLoRA training smoke on GPU | Done |
| **4** | Redis job wake (LPUSH / BLPOP) | Done |
| **5** | Prometheus, Pushgateway, Grafana dashboards | Done |
| **Web UI** | homelab-web on `:3080` | Done (May 2026) |

**Not in MVP yet (optional):** served LoRA adapter in Ollama, MLflow, public domain HTTPS, full user auth in UI.

---

## 11. What is complete vs. what is next

### Complete

- [x] Four-repo layout on GitHub (private)  
- [x] GPU: Ollama, Tailscale, `HomelabOllamaServe`, training env, QLoRA smoke  
- [x] iMac: full compose stack + web UI + RAG worker  
- [x] Tailscale E2E: UI, chat, RAG, Grafana  
- [x] Job plane + Redis wake + observability  

### Sensible next steps

- [ ] Scheduled Postgres backups on iMac (`backup-postgres.sh`)  
- [ ] Sync LoRA adapter to ML-STORE / load in Ollama for inference  
- [ ] Optional: public domain + HTTPS (homelab deploy doc)  
- [ ] After GPU reboot: confirm `schtasks /Run /TN HomelabOllamaServe`  

---

## 12. Quick reference — URLs (Tailscale)

| Service | URL |
|---------|-----|
| **Web UI (primary)** | http://100.91.113.98:3080 |
| **Web UI (Caddy)** | http://100.91.113.98/ |
| GPU Ollama health | http://100.88.71.33:11434/api/tags |
| iMac API health (ops) | http://100.91.113.98/health |
| Grafana | http://100.91.113.98:3000 |
| Prometheus | http://100.91.113.98:9090 |
| Pushgateway | http://100.91.113.98:9091 |
| Qdrant | http://100.91.113.98:6333 |
| Jupyter (GPU, if started) | http://100.88.71.33:8888 |

---

## 13. Troubleshooting (common)

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `:3080` connection refused | `web` container down on iMac | `docker-compose up -d web` (+ `source docker-1tb-env.sh`) |
| Chat “Thinking…” forever | GPU Ollama not running | `curl` GPU tags; `schtasks /Run /TN HomelabOllamaServe` on GPU |
| Chat 502 | iMac cannot reach GPU `:11434` | Check `GPU_URL` in `.env`, firewall, Ollama bind |
| RAG query empty | Embed not finished | Wait 30–90s after ingest; check `imac-worker` logs |
| `docker ps` empty on iMac | Wrong Docker context | `source scripts/docker-1tb-env.sh` |

---

## 14. Glossary

| Term | Meaning |
|------|---------|
| **Ollama** | Local LLM server on GPU, port 11434 |
| **homelab-web** | Next.js UI; BFF hides API key |
| **Colima** | Docker VM on macOS (iMac) |
| **LoRA / QLoRA** | Efficient fine-tuning on consumer GPUs |
| **Tailscale** | Mesh VPN for home machines |
| **imac-worker** | Container that runs RAG ingest/embed jobs |
| **BFF** | Backend-for-frontend — Next.js `/api/homelab` proxy |
| **Caddy** | Reverse proxy; LAN mode forwards `:80` → web UI |
| **Qdrant** | Vector DB for RAG |
| **Pushgateway** | Prometheus target for GPU-pushed metrics |

---

## 15. Contact and repository access

- GitHub user: **zakiscoding**  
- Private repo access must be granted by the owner.  
- This document contains **no** passwords, API keys, or tokens.

After joining the project: clone **homelab**, read `docs/SETUP-LOG.md` for build history, and `docs/services/web-ui.md` for the browser UI.

---

*End of shareable overview.*
