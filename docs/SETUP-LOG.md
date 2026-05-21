# Setup log

Chronological record of homelab setup work. Newest entries at the top.

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

**Open:**

- [ ] Grafana `data/grafana` permissions (`chown 472:472` on iMac)
- [ ] Log iMac Tailscale IP; test from laptop `cashh`

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
