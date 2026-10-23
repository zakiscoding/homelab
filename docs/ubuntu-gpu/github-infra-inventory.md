# GitHub / checkout infrastructure inventory

**Scope:** Read-only inventory of what the four private `zakiscoding/homelab*` repos document vs the Ubuntu hybrid track.  
**Not in scope:** Modal install/config, live node login as completed work.  
**As of:** 2026-10-23.  
**Related:** [infra-inventory.md](infra-inventory.md) · [phased-infrastructure-plan.md](phased-infrastructure-plan.md) · [ubuntu-gpu README](README.md)

---

## 1. Repos and how they relate

Four **private** GitHub repos form one three-node homelab. Docs say: do **not** put Docker/services inside `homelab`.

| Repo | Default branch | Role | Runs on |
|------|----------------|------|---------|
| [zakiscoding/homelab](https://github.com/zakiscoding/homelab) | `main` | **Docs only** — architecture, phases, runbooks, inventory; **Ubuntu track:** [`docs/ubuntu-gpu/`](README.md) | All nodes (read) |
| [zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services) | `main` | Docker Compose stack, FastAPI, workers, DB migrations | **iMac** (`Mos-iMac` / `momo`) via **Colima** |
| [zakiscoding/homelab-gpu](https://github.com/zakiscoding/homelab-gpu) | `main` | Training scripts, GPU worker, Ollama helpers, notebooks | **Dual-boot PC, Windows boot** (`zak_pc` / Tailscale `zakar`; same hardware as Ubuntu `zak-gpu-node`) |
| [zakiscoding/homelab-web](https://github.com/zakiscoding/homelab-web) | `master` | Next.js UI (chat, RAG, status) + BFF proxy | Dev: laptop; prod: iMac Docker `:3080`/`:3081` |

```text
  Laptop (cashh) — controller: git, curl, SSH, web dev
           │ Tailscale
     ┌─────┴─────┐
     ▼           ▼
  Dual-boot PC   iMac (momo)
  (one RTX 5070) Mos-iMac
  Windows boot:  Colima + homelab-services
    zak_pc/zakar + homelab-web
    Ollama/homelab-gpu
    :11434 / :8100
  Ubuntu boot:
    OS name + Tailscale zak-gpu-node
    @ 100.121.51.35
    external /dev/sda; ~/projects
                 :3081 / :8000 / Postgres SSOT
```

**Execution model (documented):** Postgres on iMac is SSOT for jobs; GPU worker polls/claims; iMac worker handles RAG ingest/embed. See [`docs/EXECUTION-MODEL.md`](../EXECUTION-MODEL.md).

**Related repos (not part of the four-pack):**

| Repo | Note |
|------|------|
| [zakiscoding/Audio_CNN](https://github.com/zakiscoding/Audio_CNN) | Owner repo with real `import modal` / `modal.App` (prior art only). **Not** wired into homelab. Modal is **not set up** for this stack. |

---

## 2. Local GPU / Docker / CUDA / PyTorch / deploy tooling

### Documented as present (Windows GPU path — `zak_pc`)

| Item | Status in docs |
|------|----------------|
| NVIDIA RTX 5070 (12 GB) | Done |
| Driver / CUDA | Checklist: driver 596.x, **CUDA 13.2 via driver**; overview also mentions PyTorch CUDA 12.8 wheel |
| Python 3.12 + `.venv` | Done (`homelab-gpu`) |
| Ollama native Windows `:11434` | Done; Tailscale `100.88.71.33` |
| Reaction vision CNN `:8100` | Documented |
| GPU job worker | Phase 0A+ (job control plane) |

### Ubuntu GPU path (this folder)

| Item | Status |
|------|--------|
| Dual-boot identity | Documented here — Ubuntu `zak-gpu-node` ≡ Windows `zakar`/`zak_pc` |
| Driver 595.99.02 + PyTorch `2.11.0+cu128` | Phase 1 **PASS** on host `~/projects/pytorch-cuda-smoke` |
| Full CUDA Toolkit | **Not** installed (wheel policy) |
| Docker + NVIDIA Container Toolkit | **Not** installed |
| Modal | **Not** set up |

### Docker / NVIDIA Container Toolkit

| Where | What |
|-------|------|
| **iMac** | **Colima** + compose — **CPU/app stack only**. No NVIDIA GPU on iMac. |
| **GPU PC (Windows)** | Ollama **does not** use Docker. Docker Desktop + WSL2 marked optional later. |
| **GPU PC (Ubuntu)** | Docker / NVIDIA CTK **not installed** — Phase 2 after approval. |

---

## 3. Modal · Tailscale · dual-boot

### Modal

| Location | Finding |
|----------|---------|
| `homelab`, `homelab-gpu`, `homelab-services`, `homelab-web` | **Not set up.** Do not treat Modal as done work. |
| `Audio_CNN` | Prior art only; separate project. |
| Hybrid plan | Modal is a **later** phase for burst/multi-GPU — planning only until the user asks. |

### Tailscale

| Node | Tailscale IPv4 | Notes |
|------|----------------|-------|
| GPU Windows `zakar` | `100.88.71.33` | Ollama `:11434`, vision `:8100` when Windows booted |
| GPU Ubuntu `zak-gpu-node` | `100.121.51.35` | Ubuntu CUDA track |
| iMac `mos-imac` | `100.91.113.98` | Web `:3081`, API `:8000`, Grafana, etc. |
| Laptop `hp-laptop` | `100.73.132.95` | Controller |
| Cursor VM `cursor-cloud` | `100.124.163.68` | **No GPU** — not the dual-boot PC |

### Dual-boot

| Claim | In GitHub docs? |
|-------|-----------------|
| GPU software path documented as **Windows** (`zak_pc`) | **Yes** — [`nodes/gpu-node.md`](../nodes/gpu-node.md), SETUP-LOG |
| Dual-boot: Ubuntu `zak-gpu-node` ≡ Windows `zakar`/`zak_pc`; never touch Windows NVMe from Ubuntu | **Yes** — this folder ([README](README.md), [phased plan](phased-infrastructure-plan.md)) |

---

## 4. Gaps vs hybrid AI lab goals

| Goal | Four-repo (Windows/iMac) status | Ubuntu track status |
|------|----------------------------------|---------------------|
| Local CUDA / PyTorch | Windows path documented | Ubuntu Phase 1 smoke **PASS** (host-local project) |
| Docker + NVIDIA | iMac Colima only; Windows Docker optional | Not installed — Phase 2 + **[APPROVAL]** |
| Modal later | Not in homelab* | Plan only — **not set up** |
| DDP / multi-GPU | Job shards on one GPU, not NCCL | Modal-first later |
| Identity | Windows `zak_pc` / `zakar` | Dual-boot + Tailscale map documented here |

---

## 5. Recommended source of truth

| Need | Prefer | Why |
|------|--------|-----|
| Architecture, Windows/iMac phases, Tailscale service map | **`zakiscoding/homelab`** root docs (`ARCHITECTURE`, `INVENTORY`, `NETWORK`, `PHASE-*`) | Docs SSOT |
| Ubuntu hybrid track, dual-boot safety, Phase 1 smoke | **`docs/ubuntu-gpu/`** (this folder) | Ubuntu + Modal-later track |
| Compose, API, migrations, iMac ops | **`zakiscoding/homelab-services`** | Runtime code |
| Training / GPU worker / Ollama (Windows) | **`zakiscoding/homelab-gpu`** | Windows GPU code SSOT |
| UI | **`zakiscoding/homelab-web`** | Sibling of services |
| Modal patterns (when authorized) | Study **`Audio_CNN`** as reference only; do not install until asked | Only real Modal SDK usage under the owner |

**Practical rule:** Treat GitHub `homelab*` root docs as SSOT for the **Windows boot software + iMac Colima** platform. Treat **`docs/ubuntu-gpu/`** as SSOT for the **Ubuntu boot of that same dual-boot PC**. Never conflate either with Cursor Tailscale `cursor-cloud` @ `100.124.163.68`.
