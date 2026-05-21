# HOMELAB

**Documentation only** — hardware, network, services, setup logs. No Docker code here.

**Share with someone else (one file):** [share/HOMELAB-COMPLETE-OVERVIEW.md](share/HOMELAB-COMPLETE-OVERVIEW.md) — full standalone overview, no other docs required.

## Who is what

| Node | Machine | Windows user | Hostname | Role |
|------|---------|--------------|----------|------|
| **Controller** | Laptop | **`cashh`** | — | Docs, `git`, `curl` tests, SSH to GPU |
| **GPU node** | Desktop PC | **`zakar`** | `zak_pc` | Ollama + RTX 5070 |
| **App / DB** | iMac | **`momo`** | `Mos-iMac` | API stack in `homelab-services/` |

Both homelab Windows boxes run **Windows** (PowerShell). `cashh` = laptop only; `zakar` = GPU PC only.

## Paths on the 1TB drive

See **[docs/DRIVE-LAYOUT.md](docs/DRIVE-LAYOUT.md)** for the full tree.

| Folder | Purpose |
|--------|---------|
| **`homelab/`** | This repo — docs only |
| **`homelab-services/`** | Docker stack, API, databases, `data/` |
| **`homelab-gpu/`** | GPU training code (mirror) |
| **`homelab-runtime/`** | Colima + Docker CLI config |
| **`Personal/`** | School, resumes, projects (not homelab) |

| Machine | Docs | Services |
|---------|------|----------|
| **iMac** | `homelab/` | `homelab-services/` |
| **Controller (`cashh`)** | `C:\Users\cashh\homelab` (git clone) | Copy or clone `homelab-services` |
| **GPU PC (`zakar`)** | Optional clone of `homelab` | — |

**GitHub:** [homelab](https://github.com/zakiscoding/homelab) (docs) · [homelab-services](https://github.com/zakiscoding/homelab-services) (iMac) · [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) (GPU training) — all **private** — [docs/REPOS.md](docs/REPOS.md)

## Quick links

| Doc | Purpose |
|-----|---------|
| [Setup log](docs/SETUP-LOG.md) | Chronological record of what we did and when |
| [Inventory](docs/INVENTORY.md) | Hosts, VMs, containers, hardware |
| [Network](docs/NETWORK.md) | VLANs, subnets, DNS, firewall, VPN |
| [Services](docs/SERVICES.md) | Running apps and how to reach/manage services |
| [Secrets & access](docs/ACCESS.md) | Where credentials live (not the secrets themselves) |
| [Architecture](docs/ARCHITECTURE.md) | Three-node layout (GPU / iMac / controller) |
| [GPU node runbook](docs/nodes/gpu-node.md) | Ollama on Windows |
| [GPU node checklist](docs/nodes/GPU-NODE-CHECKLIST.md) | Install ✅, ports, ML-only rule |
| [Git workflow](docs/GIT.md) | Clone, pull, push — GitHub `zakiscoding/homelab` |
| [Repositories](docs/REPOS.md) | `homelab` + `homelab-services` + `homelab-gpu` |
| [Backups](docs/BACKUPS.md) | Postgres dumps, checkpoints, restic |
| [1TB layout](docs/DRIVE-LAYOUT.md) | iMac volume folder map |
| [Testing](docs/TESTING.md) | Tailscale curl checklist |
| [1TB drive layout](docs/DRIVE-LAYOUT.md) | Folder structure on external volume |
| [iMac stack](docs/services/imac-stack.md) | Docker — `homelab-services` repo |

## How we use this repo

1. **`git pull`** — GitHub is canonical for docs.
2. **Before a change** — skim [SETUP-LOG](docs/SETUP-LOG.md).
3. **During setup** — log commands and paths; service config lives in **`homelab-services/`**.
4. **After it works** — update inventory/services, then **`git commit` + `git push`**.

Runtime compose and API code: **`homelab-services/`** — document from `docs/services/` and the setup log.

## Status

| Area | Status | Notes |
|------|--------|-------|
| Documentation scaffold | Done | 2026-05-21 |
| Architecture (3 nodes) | Documented | GPU + iMac live |
| GPU node — Ollama | **Done** | RTX 5070; `100.88.71.33:11434` |
| iMac — API/DB (Colima) | **Done** | All 7 containers up; `100.91.113.98` |
| Docs on 1TB drive | Done | `/Volumes/1tb drive/homelab` |
| Services on 1TB drive | Done | `/Volumes/1tb drive/homelab-services` |
| GitHub repos | **Done** | `homelab` + `homelab-services` + `homelab-gpu` (all private) |
| Monitoring | Running | Prometheus :9090, Grafana :3000 on iMac |
| Tailscale E2E tests | **Done** | GPU + iMac health from `zak_pc` |
| GPU training prep | **Done** | `homelab-gpu` cloned, Python, torch, data dirs |
| Backups | Documented | [BACKUPS.md](docs/BACKUPS.md) + `backup-postgres.sh` on iMac |
| First LoRA run | **Next** | Add dataset + `train.py` in `homelab-gpu/training/` |
