# HOMELAB

**Documentation only** — hardware, network, services, setup logs. No Docker code here.

**Share with someone else (one file):** [share/HOMELAB-COMPLETE-OVERVIEW.md](share/HOMELAB-COMPLETE-OVERVIEW.md) — full standalone overview, no other docs required.

## Who is what

| Node | Machine | User / OS | Hostname / Tailscale | Role |
|------|---------|-----------|----------------------|------|
| **Controller** | Laptop | Windows **`cashh`** | Tailscale `hp-laptop` | Docs, `git`, `curl` tests, SSH |
| **GPU node (dual-boot)** | Desktop PC (one RTX 5070) | Windows **`zakar`** **or** Ubuntu | Windows: `zak_pc` / Tailscale `zakar` `100.88.71.33` · Ubuntu: OS+Tailscale `zak-gpu-node` `100.121.51.35` | Windows: Ollama + `homelab-gpu` · Ubuntu: CUDA/`~/projects` track — [docs/ubuntu-gpu/](docs/ubuntu-gpu/) |
| **App / DB** | iMac | macOS **`momo`** | `Mos-iMac` / `mos-imac` | API stack in `homelab-services/` |
| **Cursor cloud VM** | Cloud | — | Tailscale `cursor-cloud` `100.124.163.68` | **No GPU** — not the dual-boot PC |

Windows boxes (`cashh`, `zakar`) use **PowerShell**. Ubuntu boot of the GPU PC is a separate OS on the same machine (external disk); never touch the Windows NVMe from Ubuntu.

## Paths on the 1TB drive

See **[docs/DRIVE-LAYOUT.md](docs/DRIVE-LAYOUT.md)** for the full tree.

| Folder | Purpose |
|--------|---------|
| **`homelab/`** | This repo — docs only |
| **`homelab-services/`** | Docker stack, API, databases, `data/` |
| **`homelab-gpu/`** | GPU training code (mirror) |
| **`homelab-web/`** | Next.js UI (mirror; prod on iMac `:3081`) |
| **`homelab-runtime/`** | Colima + Docker CLI config |
| **`Personal/`** | School, resumes, projects (not homelab) |

| Machine | Docs | Services |
|---------|------|----------|
| **iMac** | `homelab/` | `homelab-services/` |
| **Controller (`cashh`)** | `C:\Users\cashh\homelab` (git clone) | `homelab-web`, `homelab-services` clones |
| **GPU PC (`zakar`)** | Optional clone of `homelab` | — |

**GitHub:** [homelab](https://github.com/zakiscoding/homelab) (docs) · [homelab-services](https://github.com/zakiscoding/homelab-services) (iMac) · [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) (GPU) · [homelab-web](https://github.com/zakiscoding/homelab-web) (UI) — all **private** — [docs/REPOS.md](docs/REPOS.md)

## Quick links

| Doc | Purpose |
|-----|---------|
| [Setup log](docs/SETUP-LOG.md) | Chronological record of what we did and when |
| [Inventory](docs/INVENTORY.md) | Hosts, VMs, containers, hardware |
| [Network](docs/NETWORK.md) | VLANs, subnets, DNS, firewall, VPN |
| [Services](docs/SERVICES.md) | Running apps and how to reach/manage services |
| [Secrets & access](docs/ACCESS.md) | Where credentials live (not the secrets themselves) |
| [Architecture](docs/ARCHITECTURE.md) | Three-node layout (GPU / iMac / controller) |
| [**Phase 0A**](docs/PHASE-0A.md) | Job control plane — deploy + gate test |
| [**Phase 0B**](docs/PHASE-0B.md) | Leases, retry, `/system/status`, ML-STORE |
| [**Phase 1**](docs/PHASE-1.md) | Inference pipeline — `/chat` + infer jobs |
| [**Phase 2**](docs/PHASE-2.md) | RAG — ingest, embed, `/rag/query` |
| [**Phase 3**](docs/PHASE-3.md) | QLoRA training + experiments + ML-STORE sync |
| [Execution model](docs/EXECUTION-MODEL.md) | Postgres SSOT, GPU worker, SSH aliases |
| [GPU node runbook](docs/nodes/gpu-node.md) | Ollama on Windows |
| [GPU node checklist](docs/nodes/GPU-NODE-CHECKLIST.md) | Install ✅, ports, ML-only rule |
| [Git workflow](docs/GIT.md) | Clone, pull, push — GitHub `zakiscoding/homelab` |
| [Repositories](docs/REPOS.md) | Four repos: docs, services, gpu, web |
| [**Phase 6**](docs/PHASE-6.md) | Distributed train + MLflow |
| [**Web UI**](docs/services/web-ui.md) | Chat, RAG, reactions — `:3081` on iMac |
| [**Vision / reactions**](docs/services/vision-reactions.md) | FER CNN on GPU `:8100` |
| [Backups](docs/BACKUPS.md) | Postgres dumps, checkpoints, restic |
| [1TB layout](docs/DRIVE-LAYOUT.md) | iMac volume folder map |
| [Testing](docs/TESTING.md) | Tailscale curl checklist |
| [1TB drive layout](docs/DRIVE-LAYOUT.md) | Folder structure on external volume |
| [iMac checklist](docs/nodes/imac-checklist.md) | M1 services role — done vs planned |
| [iMac stack](docs/services/imac-stack.md) | Docker — `homelab-services` repo |
| [**Ubuntu GPU / hybrid AI lab**](docs/ubuntu-gpu/) | Dual-boot Ubuntu track: Phase 0A/0B, PyTorch smoke, inventories |

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
| iMac — API/DB (Colima) | **Done** | Stack + web UI `:3080`; `100.91.113.98` |
| Web UI (homelab-web) | **Done** | Chat, RAG, overview over Tailscale |
| GPU Ollama (persistent) | **Done** | `HomelabOllamaServe` on `zak_pc` |
| Docs on 1TB drive | Done | `/Volumes/1tb drive/homelab` |
| Services on 1TB drive | Done | `/Volumes/1tb drive/homelab-services` |
| GitHub repos | **Done** | `homelab` + `homelab-services` + `homelab-gpu` (all private) |
| Monitoring | Running | Prometheus :9090, Grafana :3000 on iMac |
| Tailscale E2E tests | **Done** | GPU + iMac health from `zak_pc` |
| GPU training prep | **Done** | `homelab-gpu` cloned, Python, torch, data dirs |
| Backups | Documented | [BACKUPS.md](docs/BACKUPS.md) + `backup-postgres.sh` on iMac |
| First LoRA run | **Next** | Add dataset + `train.py` in `homelab-gpu/training/` |
| Ubuntu GPU track | **Phase 1 PASS** | Dual-boot docs + `torch==2.11.0+cu128` smoke on host — [docs/ubuntu-gpu/](docs/ubuntu-gpu/) |
| Modal | **Not set up** | Later phase only; do not install until asked |
