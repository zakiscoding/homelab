# Homelab — Complete Overview (Shareable Document)

**Document purpose:** Standalone description of the homelab for collaborators, reviewers, or future you.  
**No access required** to other files in the repository — everything essential is here.  
**Last updated:** May 27, 2026 (Phase 6, vision/reactions, MLflow, web UI :3081)  
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
| **Web UI** | Chat, RAG, reactions, status at `http://100.91.113.98:3081` (or `:80` via Caddy) |
| **Chat inference** | Browser → iMac web → API → GPU Ollama → response |
| **RAG** | Ingest text → iMac worker embeds → Qdrant → query with citations |
| **Reactions** | Webcam/upload → API `/vision/reaction` → GPU CNN serve `:8100` |
| **Jobs** | Postgres SSOT; GPU + iMac workers; Redis wake on job create |
| **Training** | QLoRA on GPU (smoke train done; artifacts under `homelab-data/checkpoints/`); optional **distributed** shard plans (Phase 6) |
| **MLflow** | Experiment UI on iMac `:5001` |
| **Monitoring** | Prometheus + Grafana (“Homelab Stack” + GPU node dashboards) |
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
        │  • Ollama :11434      │◄── HTTP ─────│  • Web UI :3081 / Caddy :80│
        │  • Reaction CNN :8100 │◄── vision ───│  • FastAPI :8000          │
        │  • RTX 5070 12GB      │   inference  │  • Postgres, Redis, Qdrant│
        │  • homelab-gpu        │              │  • MLflow :5001           │
        │  • GPU train worker   │── poll jobs ─│  • imac-worker (RAG/prep) │
        │  • Jupyter :8888      │              │  • Prometheus, Grafana    │
        └─────────────────────┘              └───────────────────────────┘
```

### Request flow (chat via web UI)

1. User opens **http://100.91.113.98:3081** (or `http://100.91.113.98/` via Caddy).
2. **homelab-web** (Next.js) proxies `/api/homelab/chat` to **FastAPI** with `x-api-key` on the server (key never in the browser).
3. FastAPI calls **Ollama** on the GPU (`http://100.88.71.33:11434`).
4. Response returns to the UI; chat may be logged in **Postgres**.

### Request flow (RAG)

1. User ingests text in the **RAG** tab → API creates ingest + embed jobs.
2. **imac-worker** chunks, embeds via GPU/Ollama path, stores vectors in **Qdrant**.
3. User queries → API searches Qdrant → LLM answer with citations.

### Request flow (reactions / vision)

1. User opens **/reactions** in homelab-web → captures frame or uploads image.
2. Next.js BFF calls **`POST /vision/reaction`** on the iMac API.
3. FastAPI forwards to **GPU reaction serve** (`:8100`).
4. Label + confidence return to the UI (FER-style classes).

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
| iMac | (DHCP) | Web `3081`, Caddy `80`, API `8000`, Grafana `3000`, MLflow `5001` |
| Home gateway | `10.0.0.1` | Typical |

### Tailscale (primary remote access)

| Node | Tailscale IPv4 | Key services |
|------|----------------|--------------|
| GPU PC | `100.88.71.33` | Ollama `:11434`, reaction serve `:8100` |
| iMac | `100.91.113.98` | Web UI `:3081`, Caddy `:80`, API `:8000`, Grafana `:3000`, MLflow `:5001` |
| Laptop | `100.73.132.95` | Controller |

### Security posture

- GitHub repos are **private**.
- **Do not** port-forward Ollama (`11434`) or internal API (`8000`) to the internet.
- Web UI uses server-side API proxy; direct API calls still need `x-api-key`.
- Optional public HTTPS: domain + router `80/443` → iMac Caddy only (see homelab `docs/deploy/public-internet.md`).
- GPU firewall: **Ollama LAN** rule; Ollama bound via `OLLAMA_HOST=0.0.0.0:11434`.

---

## 5. GitHub repositories (four-repo model)

| Repository | GitHub | Runs on | Contains |
|------------|--------|---------|----------|
| **homelab** | [zakiscoding/homelab](https://github.com/zakiscoding/homelab) | All nodes (docs) | Markdown, architecture, phases, setup log |
| **homelab-services** | [zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services) | **iMac** | Docker Compose, FastAPI, Caddy, workers, DB migrations |
| **homelab-gpu** | [zakiscoding/homelab-gpu](https://github.com/zakiscoding/homelab-gpu) | **GPU PC** | Training scripts, GPU worker, Ollama helpers, notebooks |
| **homelab-web** | [zakiscoding/homelab-web](https://github.com/zakiscoding/homelab-web) | **Laptop dev**, **iMac prod** | Next.js UI — chat, RAG, status |

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
| **web** | Next.js UI (homelab-web) | **3081** |
| **caddy** | Reverse proxy → `web:3000` | **80**, 443 |
| **api** | FastAPI — chat, RAG, vision, jobs, metrics | **8000** |
| **imac-worker** | RAG ingest/embed + train_prep | internal |
| **mlflow** | Experiment tracking UI | **5001** |
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
| Vision | `GET /vision/status`, `POST /vision/reaction` | `x-api-key` |
| Jobs | `POST /jobs`, `GET /jobs/{id}` | `x-api-key` |
| Models | `GET /models` (Ollama tags on GPU) | `x-api-key` |
| Workers | `/internal/worker/*` | `X-Worker-Key` |
| Metrics | `GET /metrics` | LAN/Tailscale |
| System | `GET /system/status` | `x-api-key` |

The **web UI** calls these through `/api/homelab/*` on the Next.js server (browser never holds the API key).

### 7.4 Web UI (homelab-web)

| Item | Detail |
|------|--------|
| Repo | [github.com/zakiscoding/homelab-web](https://github.com/zakiscoding/homelab-web) |
| Production URL | http://100.91.113.98:3081 or http://100.91.113.98/ |
| Pages | `/` overview, `/chat`, `/rag`, `/reactions` |
| Chat UX | GPU health banner; 2-minute client timeout; clearer 502 when Ollama is down |
| Dev | `npm run dev` on laptop → `http://localhost:3000` |
| Deploy | `ensure-homelab-web.sh` then `docker-compose up -d --build web caddy` on iMac |

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
| **Web UI** | homelab-web on `:3081` | Done (May 2026) |
| **6** | Distributed train plans, MLflow, vision/reactions API | Done (May 2026) |

**Not in MVP yet (optional):** served LoRA adapter in Ollama, public domain HTTPS, full user auth in UI, GPU reaction-serve install scripts in homelab-gpu repo.

---

## 11. Status snapshot

| Area | Status | Notes |
|------|--------|-------|
| Documentation scaffold | Done | 2026-05-21 |
| Architecture (3 nodes) | Documented | GPU + iMac live |
| GPU node — Ollama | Done | RTX 5070; `100.88.71.33:11434` |
| iMac — API/DB (Colima) | Done | Stack + web UI `:3080`; `100.91.113.98` |
| Web UI (homelab-web) | Done | Chat, RAG, overview over Tailscale |
| GPU Ollama (persistent) | Done | `HomelabOllamaServe` on `zak_pc` |
| Docs on 1TB drive | Done | `/Volumes/1tb drive/homelab` |
| Services on 1TB drive | Done | `/Volumes/1tb drive/homelab-services` |
| GitHub repos | Done | Four private: homelab, homelab-services, homelab-gpu, homelab-web |
| Monitoring | Running | Prometheus `:9090`, Grafana `:3000` on iMac |
| Tailscale E2E tests | Done | GPU + iMac health; UI chat/RAG from laptop |
| GPU training prep | Done | homelab-gpu cloned, Python, torch, data dirs |
| QLoRA smoke train | Done | Phase 3 via GPU worker (`lora_quickstart/train.py`) |
| Backups | Documented | `BACKUPS.md` + `backup-postgres.sh` (cron **Next**) |
| LoRA → Ollama inference | **Ready** | `homelab-gpu/scripts/publish-lora-to-ollama.ps1` → Chat model `homelab-*` |
| CNN image fine-tune | **Ready** | CIFAR-10 or FER2013 — [CNN-FINETUNE.md](../docs/CNN-FINETUNE.md) |
| Reaction vision (FER) | **Live in web UI** | `/reactions` on `:3081` (web UI; `:3080` may be stale on iMac) — [GPU-TRAIN.md](../docs/GPU-TRAIN.md) |

- [x] Five-repo layout on GitHub (homelab, services, gpu, web + gpu-systems-lab)  
- [x] GPU: Ollama, Tailscale, `HomelabOllamaServe`, training env, QLoRA smoke  
- [x] iMac: full compose stack + web UI + RAG worker  
- [x] Tailscale E2E: UI, chat, RAG, reactions, Grafana  
- [x] Job plane + Redis wake + observability  
- [x] Vision proxy + reactions page; MLflow `:5001`  
- [x] Phase 6 distributed train schema + train_prep worker  
- [x] GPU PC Ubuntu boot (`zak-gpu-node`): CUDA 13.2, k3s GPU scheduling, DCGM monitoring, hardening  
- [x] Chat on vLLM with Ollama fallback (`LLM_BACKEND=auto`); unified Grafana  
- [x] Router worker: routed jobs → local RTX 5070 or Modal H100s  

Canonical copy also lives in [README.md](../README.md#status) in the homelab repo.

### Sensible next steps

- [ ] Scheduled Postgres backups on iMac (`backup-postgres.sh`)  
- [ ] Publish latest train job: `publish-lora-to-ollama.ps1 -JobId <uuid>` on GPU  
- [ ] Optional: sync adapter archive to iMac ML-STORE  
- [ ] Redeploy web + API on iMac after BFF/error-handling fixes (if not yet pulled)  
- [ ] Optional: public domain + HTTPS (homelab deploy doc)  
- [ ] After GPU reboot: confirm `schtasks /Run /TN HomelabOllamaServe`  

---

## 12. Quick reference — URLs (Tailscale)

| Service | URL |
|---------|-----|
| **Web UI (primary)** | http://100.91.113.98:3081 |
| **Reactions UI** | http://100.91.113.98:3081/reactions |
| **Web UI (Caddy)** | http://100.91.113.98/ |
| GPU Ollama health | http://100.88.71.33:11434/api/tags |
| GPU reaction health | http://100.88.71.33:8100/health |
| iMac API health (ops) | http://100.91.113.98:8000/health |
| MLflow | http://100.91.113.98:5001 |
| Grafana | http://100.91.113.98:3000 |
| MLflow | http://100.91.113.98:5001 |
| Prometheus | http://100.91.113.98:9090 |
| Pushgateway | http://100.91.113.98:9091 |
| Qdrant | http://100.91.113.98:6333 |
| Jupyter (GPU, if started) | http://100.88.71.33:8888 |

---

## 13. Troubleshooting (common)

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `:3081` connection refused | `web` container down on iMac | `docker-compose up -d web` (+ `source docker-1tb-env.sh`) |
| Reactions “vision down” | GPU reaction serve not on `:8100` | Start serve on zak_pc; check `GPU_VISION_URL` in `.env` |
| Webcam blocked on Tailscale | HTTP lacks secure context | Use **Upload photo** or SSH tunnel to `https://localhost:3081` |
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
| **MLflow** | Experiment tracking server on iMac |
| **train_prep** | iMac job that builds shard plan before GPU train |
| **Reaction serve** | GPU FastAPI/CNN on port 8100 for `/vision/reaction` |

---

## 15. Contact and repository access

- GitHub user: **zakiscoding**  
- Private repo access must be granted by the owner.  
- This document contains **no** passwords, API keys, or tokens.

After joining the project: clone **homelab**, read `docs/SETUP-LOG.md` for build history, `docs/services/web-ui.md` for the browser UI, and `docs/services/vision-reactions.md` for the reactions pipeline.

---

*End of shareable overview.*
