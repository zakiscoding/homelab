# Setup log

Chronological record of homelab setup work. Newest entries at the top.

---

## 2026-05-21 — Phase 2 RAG pipeline

**Goal:** Ingest → chunk → embed → Qdrant → `/rag/query` with iMac worker.

**Repos:** homelab-services (`005_phase2_rag.sql`, `rag_*`, `imac-worker` service), homelab [PHASE-2.md](PHASE-2.md), [services/rag.md](services/rag.md).

---

## 2026-05-21 — Phase 1 inference (chat_logs.job_id)

**Goal:** Complete inference pipeline traceability; optional GPU worker scheduled task.

**Repos:** homelab-services `004_phase1.sql`, homelab-gpu `register-gpu-worker-task.ps1`, [PHASE-1.md](PHASE-1.md).

**Smoke:** `/chat` → `phase1-ok`, infer job `4674dc51-...` succeeded, `chat_logs.job_id` migrated.

---

## 2026-05-21 — Phase 0B leases, retry, system status

**Goal:** Auto-recover stuck train jobs; observability; infer jobs on `/chat`; ML-STORE layout.

**Repos:** homelab-services (`003_phase0b.sql`, expanded `jobs.py`, API v0.3), homelab-gpu (heartbeat + 0B reset-stale), homelab docs [PHASE-0B.md](PHASE-0B.md).

**Deploy:** iMac `migrate-phase0b.sh` + `setup-ml-store.sh` + `start-stack.sh` (Colima); re-ran `002` after stack recreate; GPU `git pull` `1d099fe`. Heartbeat fix `a435577`.

**Smoke:** `/system/status` OK (GPU + Qdrant); train job `2f77e255-...` succeeded; worker `zak_pc` in heartbeats.

---

## 2026-05-21 — Phase 0A job control plane (code + docs)

**Goal:** Postgres-backed `train` jobs; GPU MVW worker; execution gate (crash-safe, idempotent artifacts).

**Repos:**

| Repo | Changes |
|------|---------|
| **homelab-services** | `postgres/002_jobs.sql`, `api/jobs.py`, job routes, `WORKER_API_KEY`, `scripts/migrate-jobs.sh` |
| **homelab-gpu** | `worker/poll_jobs.py`, `worker/run_train.py`, `scripts/start-gpu-worker.ps1`, `httpx` dep |
| **homelab** (this) | [PHASE-0A.md](PHASE-0A.md), [EXECUTION-MODEL.md](EXECUTION-MODEL.md) |

**SSH:** laptop uses `imac-ts` (momo), `zak-ts` (zakar) — see [nodes/controller.md](nodes/controller.md).

**Deploy (2026-05-21 via SSH `imac-ts` / `zak-ts`):**

1. iMac: `git pull` → `WORKER_API_KEY` appended to `.env` → migrate with `psql -U app` → `docker-compose up -d --build api` — `/health` OK
2. GPU: `git pull` → `.env` with matching `WORKER_API_KEY` → `pip install httpx` → worker claimed job → **succeeded**
3. FastAPI fix: `response_model=None` on claim route (pushed `07bc359`)

**Smoke test:** `POST /jobs` from laptop → job `355e220f-...` → `status=succeeded`, `locked_by=zak_pc`.

**Gate test (passed):** job `3d6a966b-9a19-4437-b37c-5931831b614b` — `taskkill` on GPU mid-train → job stayed `running` → `POST /internal/worker/jobs/reset-stale` → `pending` → worker finished → `succeeded`; one `published.json` under `checkpoints\{job_id}\`. See [PHASE-0A.md](PHASE-0A.md#gate-test-from-laptop).

**Ops notes:** API needed `docker-compose up -d --force-recreate api` after adding `WORKER_API_KEY` to `.env`. GPU worker must load `.env` (`run-worker-once.ps1` / `start-gpu-worker-bg.ps1`); raw `python -m worker.poll_jobs` without env returns 401 / no claim.

**RTX 5070:** 0A uses CPU stub train (no VRAM); real QLoRA requires `stop-ollama.ps1` first.

**Next (0B):** auto-retry, leases, `/system/status`, iMac embed worker, ML-STORE.

---

## 2026-05-21 — iMac service checklist doc

**Goal:** Single-page checklist for Mos-iMac role (services vs GPU).

**Done:**

- [nodes/imac-checklist.md](nodes/imac-checklist.md) — install, containers, per-service responsibilities, ports, “should NOT run”
- Updated [imac-node.md](nodes/imac-node.md) — links checklist, M1 + ports

---

## 2026-05-21 — Jupyter notebooks in `homelab-gpu`

**Goal:** Interactive fine-tuning on GPU PC (better than one-shot scripts for experiments).

**Done:**

- `notebooks/01_gpu_and_paths.ipynb` — CUDA + path check
- `scripts/start-jupyter.ps1` — JupyterLab `:8888`
- `requirements.txt` — `jupyterlab`, `ipykernel`, `python-dotenv`
- [notebooks/README.md](https://github.com/zakiscoding/homelab-gpu/blob/main/notebooks/README.md) — local + Tailscale access

**Next:** Copy to `02_lora_experiment.ipynb` when dataset is ready.

---

## 2026-05-21 — Homelab open items closed (GPU PC session)

**Goal:** Finish remaining setup-log tasks: Tailscale tests, `homelab-gpu` on `zak_pc`, training prep, backups doc.

**Done:**

| Task | Result |
|------|--------|
| Tailscale from GPU/controller path | OK — GPU `:11434`, iMac `/health`, Prometheus, Qdrant |
| Clone `homelab-gpu` | `C:\Users\zakar\homelab-gpu` |
| Python 3.12 + venv + PyTorch (cu124) | `cuda True` RTX 5070 (sm_120 warning — upgrade PyTorch when newer wheel supports 5070) |
| Data dirs | `C:\Users\zakar\homelab-data\{checkpoints,datasets}` (no `D:` on this PC) |
| Training scaffold | `scripts/*.ps1`, `training/lora-quickstart/`, `configs/paths.example.yaml` |
| Backups | [BACKUPS.md](BACKUPS.md) + `homelab-services/scripts/backup-postgres.sh` |
| Clone `homelab-services` on GPU (reference) | `C:\Users\zakar\homelab-services` |

**Still manual / next:**

- [ ] Run `backup-postgres.sh` on iMac + schedule (cron/launchd)
- [ ] Test iMac `/chat` from **`cashh`** laptop with `x-api-key` (need key from iMac `.env`)
- [ ] Add first `train.py` + dataset in `homelab-gpu/training/lora-quickstart/`
- [ ] iMac: `git pull` in `homelab`, `homelab-services`, `homelab-gpu` on 1TB

**Pushed:** `homelab`, `homelab-gpu`, `homelab-services` (see commits).

---

## 2026-05-21 — 1TB drive folder structure cleanup

**Goal:** Separate homelab repos, runtime, and personal files; clear volume root.

**Done:**

- **`homelab-runtime/`** — moved `colima/`, `docker-config/` from volume root
- **`Personal/`** — `School/`, `Resumes/`, `Screenshots/`, `Projects/` (MLOps, GitHub, redis-clone, etc.)
- Volume root **`README.md`** + [DRIVE-LAYOUT.md](DRIVE-LAYOUT.md)
- Updated `homelab-services/scripts/*` for new `COLIMA_HOME` paths
- Removed stray `curl.exe`, empty `docker-data/`

**Left in place:** `Desktop/`, `Documents/` (macOS folders)

---

## 2026-05-21 — Colima recovered after folder move

**Problem:** VM broke after move; `colima start` timed out (~10 min).

**Fix:** `colima delete -f` then `colima start --cpu 4 --memory 6 --disk 40 ...` — ~3 min. Restart API if Caddy shows 502.

**Verified:** All 7 containers up; `/health` and `/chat` → GPU OK.

---

## 2026-05-21 — `homelab-gpu` private repo created

**Goal:** Version training code on GPU PC; confirm all homelab GitHub repos are private.

**Done:**

- Verified **homelab-services** → `visibility: PRIVATE`
- Created **[zakiscoding/homelab-gpu](https://github.com/zakiscoding/homelab-gpu)** (private)
- Scaffold: `configs/`, `training/`, `scripts/`, `.gitignore`, `.env.example`
- GPU clone path: `C:\Users\zakar\homelab-gpu`
- Updated [REPOS.md](REPOS.md), [gpu-node.md](nodes/gpu-node.md)

**Next:**

- [x] Clone `homelab-gpu` on `zak_pc` — `C:\Users\zakar\homelab-gpu`
- [x] `CHECKPOINT_DIR` / `DATASET_DIR` — `C:\Users\zakar\homelab-data\`
- [ ] First training run — see `training/lora-quickstart/`

---

## 2026-05-21 — Colima on 1TB + stack running on iMac

**Goal:** Docker on iMac without Desktop; all data on 1TB; full services up.

**Done:**

- **Colima** — `COLIMA_HOME=/Volumes/1tb drive/colima`, `brew install colima docker docker-compose`
- Images pulled; `docker-compose up` from `~/1tb-drive/homelab-services` (symlink for mount quirks)
- **Working:** API, Caddy :80, Postgres, Redis, Qdrant :6333, Prometheus :9090
- **`curl http://localhost/health`** → OK
- **`POST /chat`** → GPU response (e.g. `"Hello, I'm here!"`)
- Scripts: `homelab-services/scripts/setup-1tb.sh`, `start-stack.sh`, `docker-1tb-env.sh`
- Compose fix: directory mounts + Caddy `reverse-proxy` command (Colima file-bind issue)

**Also done (later same day):**

- Grafana + Prometheus up (`user: "0"` for Colima virtiofs volumes)
- iMac Tailscale IP: **100.91.113.98**
- Full service check: health, `/chat`, Qdrant, Prometheus, Grafana — all OK
- Pushed to GitHub: `homelab` + `homelab-services`

**Open:**

- [x] Test URLs over Tailscale (from `zak_pc` 2026-05-21)
- [x] `homelab-gpu` repo + scaffold on GPU PC
- [ ] `/chat` from **`cashh`** with API key (user test)

---

## 2026-05-21 — GitHub repo `homelab-services` + repo plan in docs

**Goal:** Private GitHub repo for iMac stack; document multi-repo layout (incl. future GPU training).

**Done:**

- GitHub: **[zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services)** (private)
- Local path: `/Volumes/1tb drive/homelab-services`
- Docs: [REPOS.md](REPOS.md) — `homelab` / `homelab-services` / planned `homelab-gpu`
- Updated [ARCHITECTURE.md](ARCHITECTURE.md), [GIT.md](GIT.md), [imac-stack.md](services/imac-stack.md)

**Next:**

- [ ] `git pull` on iMac in both folders after clone/push
- [ ] Docker Desktop + `docker compose up` on iMac
- [ ] Create `homelab-gpu` when training scripts exist

---

## 2026-05-21 — Services split: `homelab-services/` on 1TB drive

**Goal:** Keep `homelab/` docs-only; run Docker stack in a separate folder on the 1TB drive.

**Done:**

- Created **`/Volumes/1tb drive/homelab-services`** with:
  - FastAPI (`api/`) — `/chat`, `/health`, `/health/gpu`, Postgres chat logs
  - PostgreSQL, Redis, Qdrant, Caddy, Prometheus, Grafana
  - Persistent data under `homelab-services/data/` (bind mounts)
- Removed `homelab/compose/` (no services in docs repo)
- Docs: [services/imac-stack.md](services/imac-stack.md), updated [imac-node.md](nodes/imac-node.md), [SERVICES.md](SERVICES.md)

**Next:**

- [ ] Install Docker Desktop on iMac
- [ ] `cp .env.example .env` in `homelab-services/`
- [ ] `docker compose up -d --build`
- [ ] Test `curl http://localhost/health` and `/chat` with API key
- [x] GitHub repo `homelab-services` (see entry above)

---

## 2026-05-21 — Doc changes must be pushed (GitHub sync)

**Rule:** Every homelab doc edit → `git commit` + `git push` so iMac / `cashh` / `zakar` can `git pull`.

**Other nodes:**

```bash
# iMac
cd "/Volumes/1tb drive/homelab" && git pull

# laptop cashh
cd C:\Users\cashh\homelab && git pull
```

---

## 2026-05-21 — Node identities (Windows users)

| Node | Login | Hostname |
|------|-------|----------|
| Controller laptop | **`cashh`** | — |
| GPU PC | **`zakar`** | `zak_pc` |
| iMac | **`momo`** | `Mos-iMac` |

Docs updated so `cashh` is never confused with the GPU machine.

---

## 2026-05-21 — Repo on 1TB drive + iMac → GPU verified

**Goal:** Keep all homelab files on the iMac’s 1TB volume; confirm inference path from iMac.

**Done:**

- Copied repo to **`/Volumes/1tb drive/homelab`** (canonical root).
- iMac (`Mos-iMac`, user `momo`): `curl http://100.88.71.33:11434/api/generate` → `"response":"Hello!"`.
- Tailscale + SSH from controller to both nodes (already working).

**Repo paths:**

| Host | Path |
|------|------|
| iMac | `/Volumes/1tb drive/homelab` |
| Old copy | `~/homelab` — use 1TB path instead |

**Next:** Run stack from `homelab-services/`; log iMac Tailscale IP in inventory.

---

## 2026-05-21 — Git repo → GitHub `zakiscoding/homelab` (private)

**Goal:** Private GitHub repo; sync docs/compose across iMac and controller.

**Done:**

- `git init` in `/Volumes/1tb drive/homelab`
- 2 commits on `main`; pushed to **https://github.com/zakiscoding/homelab** (`isPrivate: true`)
- `gh` authenticated as **zakiscoding**
- Remote: `https://github.com/zakiscoding/homelab.git`
- Latest commit: `6857852` (local = remote)

**Clone on controller:** see [GIT.md](GIT.md)

---

## 2026-05-21 — GPU node Ollama live (LAN + Tailscale)

**Goal:** Ollama API reachable remotely without sitting at the GPU PC.

**Done:**

- Remote restart: `Stop-Process ollama*` → `Start-Process ollama.exe serve` with `OLLAMA_HOST=0.0.0.0:11434` (Machine + session).
- `netstat`: `0.0.0.0:11434` LISTENING.
- Local: `curl.exe http://127.0.0.1:11434/api/tags` OK.
- Remote (controller user `cashh`, Tailscale): `curl.exe http://100.88.71.33:11434/api/tags` OK.

**Models on GPU node:**

| Model | Size | Notes |
|-------|------|-------|
| `llama3.2:latest` | ~2 GB | Q4_K_M, 3.2B params |

**Endpoints:**

| From | URL |
|------|-----|
| GPU node itself | `http://127.0.0.1:11434` |
| Home LAN | `http://10.0.0.156:11434` |
| Tailscale | `http://100.88.71.33:11434` |

**Also done (terminal on `zak_pc`):**

- `Invoke-RestMethod` generate test → response `Hello!`, `done: True`
- Scheduled task **`OllamaServe`** registered (AtStartup, `ollama serve`)

**Next:** iMac phase 2 (API/DB); after reboot confirm port 11434 still listening.

---

## 2026-05-21 — GPU node is Windows (not Ubuntu)

**Goal:** Correct homelab docs and path for a Windows GPU server.

**Clarification:**

- GPU PC runs **Windows**, not Ubuntu. SSH into it is still **PowerShell**, not bash.
- `cat /etc/os-release` fails on Windows — that was expected on the GPU node.
- AI stack: **Ollama native on Windows** + NVIDIA driver; skip Linux `apt` / `systemctl` / NVIDIA Container Toolkit unless we add Docker Desktop later.

**Verified on GPU node:**

```text
nvidia-smi: NVIDIA GeForce RTX 5070, Driver 596.36, CUDA 13.2
Ollama: ollama.exe running (seen in nvidia-smi process list)
```

**2026-05-21 session (terminal):**

```text
ipconfig:
  Wi-Fi IPv4:  10.0.0.156  (LAN — use for homelab on same network)
  Tailscale:   100.88.71.33 (remote access from other Tailscale devices)

curl.exe http://127.0.0.1:11434/api/tags → FAILED (connection refused)
New-NetFirewallRule "Ollama LAN" :11434 Private → OK
```

`Get-Process ollama*` shows a process (~7 GB) but **`netstat -an | findstr 11434` empty** and `curl` to 127.0.0.1 fails — API not listening (typo `netstat-an` also gave no output). Remote fix: `Stop-Process` + `ollama serve` via `Start-Process` — see gpu-node.md § Remote-only.

**Next:**

1. Start/restart Ollama; confirm `netstat -an | findstr 11434` shows LISTENING
2. `curl.exe http://127.0.0.1:11434/api/tags` must work locally first
3. Set `OLLAMA_HOST=0.0.0.0:11434` (Machine) + restart Ollama
4. `curl.exe http://10.0.0.156:11434/api/tags` from laptop (or `100.88.71.33` over Tailscale)

**Docs updated:** [nodes/gpu-node.md](nodes/gpu-node.md) rewritten for Windows.

---

## 2026-05-21 — Three-node plan + GPU node Phase 1

**Goal:** GPU PC runs AI models; iMac later for API/DB; laptop as controller. Document plan and start GPU verification before installs.

**Architecture:**

- **GPU node** — Windows, Ollama, NVIDIA driver (Docker optional)
- **iMac** — API, database (phase 2)
- **Laptop** — SSH, testing, this repo

**Done:**

- Documented layout in [ARCHITECTURE.md](ARCHITECTURE.md)
- GPU runbook: [nodes/gpu-node.md](nodes/gpu-node.md)
- Placeholders: [nodes/imac-node.md](nodes/imac-node.md), [nodes/controller.md](nodes/controller.md)

**Superseded:** Linux verify steps — GPU node confirmed **Windows**. See entry above.

---

## 2026-05-21 — Documentation scaffold

**Goal:** Start a repo that documents everything we do for the homelab.

**Done:**

- Created `HOMELAB` documentation structure (`README.md`, `docs/*`).
- Defined workflow: log changes here, keep inventory/network/services in sync.

**Next (fill in as we go):**

- [x] Document physical hardware and hypervisor choice (see ARCHITECTURE + INVENTORY)
- [ ] Document LAN/VLAN design
- [x] GPU node: Windows + `nvidia-smi`
- [x] GPU node: Ollama LAN + firewall + Tailscale test
- [ ] GPU node: Docker (only if needed)

**Commands / artifacts:**

```text
# Repo root (iMac): /Volumes/1tb drive/homelab
# Controller: sync or git clone from iMac 1TB drive
```

**Notes:**

- Add a dated section for each setup session, even small fixes.

---

## Template (copy for new entries)

```markdown
## YYYY-MM-DD — Short title

**Goal:**

**Done:**

**Commands / artifacts:**

```bash
# paste commands or paths to configs in this repo
```

**Rollback / gotchas:**

**Next:**
```
