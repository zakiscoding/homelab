# Homelab — Complete Overview (Shareable Document)

**Document purpose:** Standalone description of the homelab for collaborators, reviewers, or future you.  
**No access required** to other files in the repository — everything essential is here.  
**Last updated:** May 21, 2026  
**Owner / GitHub:** [zakiscoding](https://github.com/zakiscoding) (private repositories)

---

## 1. Executive summary

This homelab is a **three-machine AI stack** built at home:

1. A **Windows GPU desktop** runs **large language model inference** (Ollama) and will run **fine-tuning / training** experiments.
2. An **Apple iMac** runs the **application layer**: HTTP API, databases, reverse proxy, monitoring, and vector search — all in Docker via Colima.
3. A **Windows laptop** is the **controller**: documentation, Git, remote testing, and SSH into the other machines.

Machines connect over the **local network** and **Tailscale** (mesh VPN) so services can be reached securely from outside the house without exposing ports to the public internet.

**What works today:**

- Chat-style inference: client → iMac API → GPU (Ollama) → response stored in Postgres on iMac.
- Direct access to Ollama on the GPU for testing and development.
- Monitoring (Prometheus + Grafana) on the iMac.
- GPU training environment prepared (Python, PyTorch, Jupyter notebooks) — first fine-tune run pending dataset + training notebook.

**What is intentionally not in public Git:** model weights, datasets, API keys, database passwords, and checkpoint files.

---

## 2. High-level architecture

```text
                         ┌─────────────────────────────────────┐
                         │  Controller laptop (Windows)        │
                         │  User: cashh                        │
                         │  Role: git, docs, SSH, curl tests   │
                         └──────────────┬──────────────────────┘
                                        │ Tailscale / LAN
                    ┌───────────────────┴───────────────────┐
                    │                                       │
         ┌──────────▼──────────┐               ┌───────────▼──────────┐
         │  GPU PC (Windows)   │               │  iMac (macOS)        │
         │  Host: zak_pc       │               │  Host: Mos-iMac      │
         │  User: zakar        │               │  User: momo           │
         │                     │               │                      │
         │  • Ollama :11434    │◄── HTTP ──────│  • Caddy :80         │
         │  • RTX 5070 12GB    │   (inference) │  • FastAPI /chat     │
         │  • Training / Jupyter│              │  • Postgres, Redis   │
         │  • homelab-gpu repo │               │  • Qdrant, Prom, Graf│
         └─────────────────────┘               └──────────────────────┘
```

### Request flow (typical chat)

1. Client sends `POST /chat` to the **iMac** with header `x-api-key`.
2. **Caddy** reverse-proxies to the **FastAPI** container.
3. FastAPI calls **Ollama** on the GPU PC (`OLLAMA_HOST` / Tailscale IP).
4. Response returns to the client; conversation may be logged in **PostgreSQL** on the iMac.

### Design principles

| Principle | Rationale |
|-----------|-----------|
| **GPU does heavy ML** | Keeps VRAM for models; iMac (M1) is not used for large inference |
| **iMac owns state** | Databases, API keys, metrics, and orchestration live with the app stack |
| **Docs separate from code** | `homelab` repo is markdown only; Docker lives in `homelab-services` |
| **Private GitHub** | Topology and hostnames stay private; no secrets in repos |
| **Tailscale for remote ops** | Laptop can test GPU and iMac without port-forwarding on home router |

---

## 3. Hardware and identities

| Machine | Hostname | OS | Primary user | Hardware notes |
|---------|----------|-----|--------------|----------------|
| **GPU desktop** | `zak_pc` | Windows 10/11 | `zakar` | NVIDIA GeForce **RTX 5070**, 12 GB VRAM |
| **iMac** | `Mos-iMac` | macOS 15.7 | `momo` | **Apple M1** |
| **Laptop** | — | Windows | `cashh` | Controller only (no homelab services required) |

**Important:** Both Windows machines use PowerShell. The GPU PC is **`zakar`**; the laptop is **`cashh`**. They are not the same computer.

---

## 4. Network and access

### Local network (example)

| Node | LAN IPv4 | Notes |
|------|----------|-------|
| GPU PC | `10.0.0.156` | Wi‑Fi; Ollama port 11434 |
| iMac | (DHCP on LAN) | Caddy port 80 |
| Home gateway | `10.0.0.1` | Typical |

### Tailscale (remote access)

| Node | Tailscale IPv4 | Use |
|------|----------------|-----|
| GPU PC | `100.88.71.33` | Ollama API, optional Jupyter |
| iMac | `100.91.113.98` | Full app stack |

Tailscale gives each device a stable IP on a private mesh. Team members with Tailscale installed can reach services as if on the same VPN.

### Security posture

- Repositories on GitHub are **private**.
- **Do not** port-forward Ollama (11434) or Jupyter (8888) to the open internet without authentication.
- API access to `/chat` requires **`x-api-key`** (value stored only in iMac `.env`, not in git).
- Firewall on Windows GPU allows Ollama on **Private** profile for LAN/Tailscale.

---

## 5. GitHub repositories (three-repo model)

| Repository | URL | Runs on | Contains |
|------------|-----|---------|----------|
| **homelab** | github.com/zakiscoding/homelab | All nodes (read/write docs) | Markdown documentation, setup logs, architecture |
| **homelab-services** | github.com/zakiscoding/homelab-services | **iMac** (canonical) | Docker Compose, FastAPI, Caddy, data volumes |
| **homelab-gpu** | github.com/zakiscoding/homelab-gpu | **GPU PC** (canonical) | Training scripts, Jupyter notebooks, configs |

### Local paths (canonical copies)

| Machine | homelab (docs) | homelab-services | homelab-gpu |
|---------|----------------|------------------|-------------|
| **iMac** | `/Volumes/1tb drive/homelab` | `/Volumes/1tb drive/homelab-services` | `/Volumes/1tb drive/homelab-gpu` (optional mirror) |
| **Laptop** | `C:\Users\cashh\homelab` | `C:\Users\cashh\homelab-services` (optional) | — |
| **GPU PC** | `C:\Users\zakar\HOMELAB` (optional) | — | `C:\Users\zakar\homelab-gpu` |

**Workflow:** GitHub is the source of truth. Before editing: `git pull`. After editing: `git commit` + `git push`.

---

## 6. GPU node (`zak_pc`) — inference and training

### 6.1 Inference — Ollama

| Item | Detail |
|------|--------|
| Software | [Ollama](https://ollama.com) native on Windows |
| Port | `11434` |
| Bind address | `0.0.0.0` (LAN + Tailscale) via env `OLLAMA_HOST=0.0.0.0:11434` |
| Model in use (example) | `llama3.2:latest` (~2 GB, Q4_K_M quantization) |
| Startup | Windows scheduled task `OllamaServe` + manual `ollama serve` |

**Test inference:**

```http
GET http://100.88.71.33:11434/api/tags
GET http://100.88.71.33:11434/api/generate
```

### 6.2 Training — prepared, first run pending

| Item | Path or tool |
|------|----------------|
| Repo | `C:\Users\zakar\homelab-gpu` |
| Python | 3.12, virtualenv `.venv` |
| Libraries | PyTorch (CUDA), transformers, PEFT, accelerate, datasets |
| Notebooks | `notebooks/01_gpu_and_paths.ipynb` — environment check |
| Jupyter | `scripts/start-jupyter.ps1` → default `http://127.0.0.1:8888` |
| Datasets (local) | `C:\Users\zakar\homelab-data\datasets` |
| Checkpoints (local) | `C:\Users\zakar\homelab-data\checkpoints` |

**Before training:** run `scripts/stop-ollama.ps1` to free GPU memory.

**VRAM note:** 12 GB fits **LoRA / QLoRA** on small models; full fine-tune of large models is usually not feasible. RTX 5070 is very new; PyTorch may show a compatibility warning but reports `cuda available` in tests.

**Not yet done:** actual fine-tune job with a real dataset and saved adapter.

---

## 7. iMac node (`Mos-iMac`) — application stack

### 7.1 Docker runtime

| Item | Detail |
|------|--------|
| Runtime | **Colima** (not Docker Desktop) |
| Colima data | `/Volumes/1tb drive/homelab-runtime/colima` |
| Compose project | `/Volumes/1tb drive/homelab-services` |
| Symlink workaround | `~/1tb-drive/homelab-services` if paths with spaces break mounts |

Helper scripts: `setup-1tb.sh`, `start-stack.sh`, `docker-1tb-env.sh`.

### 7.2 Running containers (seven services)

| Container | Purpose | External port (via Tailscale) |
|-----------|---------|--------------------------------|
| **api** | FastAPI — `/health`, `/chat`, GPU proxy | via Caddy |
| **caddy** | Reverse proxy, TLS-ready | **80** |
| **postgres** | Chat / app persistence | internal |
| **redis** | Counters / cache | internal |
| **qdrant** | Vector DB for RAG | **6333** |
| **prometheus** | Metrics | **9090** |
| **grafana** | Dashboards | **3000** |

### 7.3 API behavior (summary)

| Endpoint | Method | Auth | Behavior |
|----------|--------|------|----------|
| `/health` | GET | None | Liveness check |
| `/chat` | POST | `x-api-key` | Forwards prompt to GPU Ollama; may log to Postgres |

**Test from any Tailscale device:**

```http
GET  http://100.91.113.98/health
GET  http://100.91.113.98:9090/-/healthy
GET  http://100.91.113.98:6333/
POST http://100.91.113.98/chat
     Header: x-api-key: <from iMac .env only>
     Body: JSON with user message
```

---

## 8. Controller laptop (`cashh`)

| Responsibility | Detail |
|----------------|--------|
| Documentation | Edit `homelab` repo, push to GitHub |
| Remote testing | `curl` / browser to Tailscale IPs |
| SSH | `ssh zakar@100.88.71.33` for GPU PowerShell |
| Optional | Clone `homelab-services` for debugging |

The laptop does **not** need to run Ollama or Docker for the homelab to function.

---

## 9. 1TB external drive layout (iMac)

The iMac uses a **1 TB external volume** as the main workspace:

```text
/Volumes/1tb drive/
├── homelab/              ← documentation (git)
├── homelab-services/     ← Docker stack (git)
├── homelab-gpu/          ← training code mirror (git, optional)
├── homelab-runtime/      ← Colima + Docker config (not git)
│   ├── colima/
│   └── docker-config/
└── Personal/             ← non-homelab files
```

Service **data** (Postgres files, Grafana, etc.) lives under `homelab-services/data/`.

---

## 10. What is complete vs. what is next

### Complete

- [x] Three-node architecture deployed and documented  
- [x] GPU: drivers, Ollama, LAN/Tailscale, scheduled task  
- [x] iMac: Colima, full Docker stack, `/health` and `/chat` to GPU  
- [x] Three private GitHub repositories  
- [x] Tailscale connectivity tested (GPU + iMac)  
- [x] GPU: Python, PyTorch, Jupyter, notebook scaffold  
- [x] Backup procedure documented + Postgres backup script in `homelab-services`  

### Next steps (operational)

- [ ] Run scheduled Postgres backups on iMac (`scripts/backup-postgres.sh`)  
- [ ] Full test of `/chat` from laptop with production API key  
- [ ] First LoRA fine-tune: dataset + `02_lora_experiment.ipynb` on GPU  
- [ ] Optional: export fine-tuned model to GGUF and load in Ollama  
- [ ] Confirm Ollama still starts correctly after GPU PC reboot  

---

## 11. Quick reference — URLs (Tailscale)

| Service | URL |
|---------|-----|
| GPU Ollama | http://100.88.71.33:11434 |
| iMac health | http://100.91.113.98/health |
| iMac chat API | http://100.91.113.98/chat |
| Grafana | http://100.91.113.98:3000 |
| Prometheus | http://100.91.113.98:9090 |
| Qdrant | http://100.91.113.98:6333 |
| Jupyter (GPU, if started) | http://100.88.71.33:8888 |

---

## 12. Glossary

| Term | Meaning |
|------|---------|
| **Ollama** | Local LLM runtime; serves models over HTTP on port 11434 |
| **Colima** | Lightweight Docker VM for macOS |
| **LoRA / QLoRA** | Parameter-efficient fine-tuning; fits consumer GPUs |
| **Tailscale** | Mesh VPN; private IPs for home machines |
| **PEFT** | Hugging Face library for adapter-based training |
| **Caddy** | Reverse proxy in front of the FastAPI app |
| **Qdrant** | Vector database for embeddings / RAG |

---

## 13. Contact and repository access

- GitHub organization / user: **zakiscoding**  
- Access to private repos must be granted by the owner.  
- This document does **not** contain passwords, API keys, or tokens.

For internal technical runbooks after joining the project, clone **homelab** and read `docs/SETUP-LOG.md` for chronological build history.

---

*End of shareable overview.*
