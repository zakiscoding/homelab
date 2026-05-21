# Git repositories

How homelab code and docs are split across GitHub. **Do not put Docker/services inside `homelab`.**

## Overview

| Repo | GitHub | Runs on | Contents |
|------|--------|---------|----------|
| **homelab** | [zakiscoding/homelab](https://github.com/zakiscoding/homelab) | All nodes (read) | Markdown docs, setup log, runbooks |
| **homelab-services** | [zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services) | **iMac** (`Mos-iMac`) | Docker Compose (via **Colima**), FastAPI, Caddy, DB stack |
| **homelab-gpu** | _planned_ | **GPU PC** (`zak_pc`) | Training scripts, configs (not inference models) |

## Paths on the 1TB drive (iMac)

| Folder | Git repo |
|--------|----------|
| `/Volumes/1tb drive/homelab` | `homelab` |
| `/Volumes/1tb drive/homelab-services` | `homelab-services` |

GPU PC keeps large artifacts **local** (Ollama models, checkpoints, datasets) — documented in `homelab`, not committed.

## Node → repo map

```text
                    homelab (docs)
                   /      |      \
                  /       |       \
         controller    iMac      GPU PC
         git pull     clone      git pull docs only
         homelab      both       (homelab-gpu later for training code)
                        |
                 homelab-services
                 docker compose up
```

| Node | User | Clone `homelab` | Clone `homelab-services` |
|------|------|-----------------|--------------------------|
| Laptop (controller) | `cashh` | Yes — edit & push docs | Optional — deploy/debug |
| iMac | `momo` | Yes — `git pull` for docs | Yes — **canonical** working copy on 1TB |
| GPU PC | `zakar` | Optional — runbooks | No — inference is Ollama native |

## GPU PC: inference + training

| Workload | Where it runs | Versioned in |
|----------|---------------|--------------|
| **Inference** | Ollama on GPU (`:11434`) | Documented in `homelab/docs/nodes/gpu-node.md` |
| **Training** | Python/PyTorch on GPU | Future **`homelab-gpu`** repo (scripts + configs only) |
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
# on iMac: docker compose up -d --build
```

Log major changes in [SETUP-LOG](SETUP-LOG.md).

### Secrets

| File | Repo | Committed? |
|------|------|------------|
| `homelab-services/.env` | homelab-services | **Never** |
| `homelab-services/.env.example` | homelab-services | Yes (placeholders) |

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
```

See also [GIT.md](GIT.md) (docs repo) and [services/imac-stack.md](services/imac-stack.md).
