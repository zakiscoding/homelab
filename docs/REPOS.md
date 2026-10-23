# Git repositories

How homelab code and docs are split across GitHub. **Do not put Docker/services inside `homelab`.**

## Overview

| Repo | GitHub | Runs on | Contents |
|------|--------|---------|----------|
| **homelab** | [zakiscoding/homelab](https://github.com/zakiscoding/homelab) | All nodes (read) | Markdown docs, setup log, runbooks |
| **homelab-services** | [zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services) | **iMac** (`Mos-iMac`) | Docker Compose (via **Colima**), FastAPI, Caddy, DB stack |
| **homelab-gpu** | [zakiscoding/homelab-gpu](https://github.com/zakiscoding/homelab-gpu) | **GPU PC on Windows** (`zak_pc`) | Ollama helpers, QLoRA training, GPU job worker, reaction CNN serve `:8100`, metrics push |
| **homelab-web** | [zakiscoding/homelab-web](https://github.com/zakiscoding/homelab-web) | **Laptop** (dev), **iMac** `:3081` (prod) | Next.js UI — chat, RAG, status |
| **gpu-systems-lab** | [zakiscoding/gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab) | **GPU PC on Ubuntu** (`zak-gpu-node`), **Modal**, laptop | CUDA kernels, MPI/NCCL, FSDP, vLLM serving, k3s scheduling, DCGM monitoring, job router — [gpu-node-ubuntu.md](nodes/gpu-node-ubuntu.md) |

## Paths on the 1TB drive (iMac)

Full tree: [DRIVE-LAYOUT.md](DRIVE-LAYOUT.md)

| Folder | Git repo |
|--------|----------|
| `homelab/` | `homelab` |
| `homelab-services/` | `homelab-services` |
| `homelab-gpu/` | `homelab-gpu` |
| `homelab-web/` | `homelab-web` |
| `homelab-runtime/` | _(not git — Colima)_ |
| `Personal/` | _(not git — school/resumes)_ |

**GPU PC (Windows):** clone `homelab-gpu` to `C:\Users\zakar\homelab-gpu` (canonical on GPU machine).

**GPU PC (Ubuntu boot):** `gpu-systems-lab` at `~/gpu-systems-lab` on `zak-gpu-node`; the
canonical working copy is on the laptop (`OneDrive\Desktop\gpu-systems-lab`), synced to the node.

GPU PC keeps large artifacts **local** (Ollama models, checkpoints, datasets) — documented in `homelab`, not committed.

## Node → repo map

```text
                    homelab (docs)
                   /      |      \
                  /       |       \
         controller    iMac      GPU PC
         git pull     clone      git pull docs only
         homelab      both       homelab-gpu (training)
                        |
                 homelab-services
                 docker compose up
```

| Node | User | Clone `homelab` | Clone `homelab-services` |
|------|------|-----------------|--------------------------|
| Laptop (controller) | `cashh` | Yes — edit & push docs | `homelab-web` dev; SSH deploy to iMac; `gpu-systems-lab` (router worker, Modal client) |
| iMac | `momo` | Yes — `git pull` for docs | Yes — **canonical** working copy on 1TB |
| GPU PC (Windows) | `zakar` | Optional — runbooks | Yes — **`homelab-gpu`** (training code) |
| GPU PC (Ubuntu) | `zak` | — | **`gpu-systems-lab`** at `~/gpu-systems-lab` |

## GPU PC: inference + training

| Workload | Where it runs | Versioned in |
|----------|---------------|--------------|
| **Inference** | vLLM on Ubuntu (`:8000/v1`) or Ollama on Windows (`:11434`) | `gpu-systems-lab/serving/`; [nodes/gpu-node.md](nodes/gpu-node.md) |
| **Training** | Python/PyTorch on GPU | **`homelab-gpu`** — `C:\Users\zakar\homelab-gpu` on `zak_pc`; routed jobs via `gpu-systems-lab/router` |
| **API gateway** | iMac `homelab-services` | This repo |

Before long training jobs: free VRAM (stop idle Ollama models). Checkpoints stay on GPU disk, not GitHub.

## Workflows

### Documentation change

```bash
cd "/Volumes/1tb drive/homelab"
git pull && edit docs/ && git commit -m "..." && git push
```

### iMac stack change

```bash
cd "/Volumes/1tb drive/homelab-services"
git pull && edit && git commit -m "..." && git push
source ./scripts/docker-1tb-env.sh
docker-compose up -d --build
```

### Web UI deploy (iMac)

```bash
cd ~/1tb-drive/homelab-services
git pull
./scripts/ensure-homelab-web.sh
./scripts/render-caddyfile.sh
docker-compose up -d --build web caddy
```

See [services/web-ui.md](services/web-ui.md).

Log major changes in [SETUP-LOG](SETUP-LOG.md).

### Secrets

| File | Repo | Committed? |
|------|------|------------|
| `homelab-services/.env` | homelab-services | **Never** |
| `homelab-services/.env.example` | homelab-services | Yes (placeholders) |
| `homelab-web/.env.local` | homelab-web | **Never** |
| `homelab-web/.env.local.example` | homelab-web | Yes |

## Clone commands

**iMac — services (first time):**

```bash
cd "/Volumes/1tb drive"
git clone https://github.com/zakiscoding/homelab-services.git
cp homelab-services/.env.example homelab-services/.env
```

**Laptop (`cashh`):**

```powershell
git clone https://github.com/zakiscoding/homelab.git C:\Users\cashh\homelab
git clone https://github.com/zakiscoding/homelab-services.git C:\Users\cashh\homelab-services
git clone https://github.com/zakiscoding/homelab-web.git C:\Users\cashh\homelab-web
```

See [services/web-ui.md](services/web-ui.md).

See also [GIT.md](GIT.md) (docs repo) and [services/imac-stack.md](services/imac-stack.md).
