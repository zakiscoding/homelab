# HOMELAB

**Documentation only** — hardware, network, services, setup logs. No Docker code here.

**Share with someone else (one file):** [share/HOMELAB-COMPLETE-OVERVIEW.md](share/HOMELAB-COMPLETE-OVERVIEW.md) — full standalone overview, no other docs required.

## Who is what

| Node | Machine | Windows user | Hostname | Role |
|------|---------|--------------|----------|------|
| **Controller** | Laptop | **`cashh`** | — | Docs, `git`, `curl` tests, SSH to GPU |
| **GPU node** | Desktop PC | **`zakar`** | `zak_pc` | Ollama + RTX 5070 |
| **GPU node (Ubuntu boot)** | same Desktop PC | Linux **`zak`** | `zak-gpu-node` | CUDA / k3s / vLLM / GPU monitoring — [gpu-node-ubuntu.md](docs/nodes/gpu-node-ubuntu.md) |
| **App / DB** | iMac | **`momo`** | `Mos-iMac` | API stack in `homelab-services/` |

`cashh` = laptop only; `zakar` = GPU PC on Windows. The GPU PC **dual-boots**: Windows (`zak_pc`,
Ollama) **or** Ubuntu (`zak-gpu-node`), never both at once.

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

**GitHub:** [homelab](https://github.com/zakiscoding/homelab) (docs) · [homelab-services](https://github.com/zakiscoding/homelab-services) (iMac) · [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) (GPU) · [homelab-web](https://github.com/zakiscoding/homelab-web) (UI) — all **private** · [gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab) (Ubuntu GPU node: CUDA, MPI/NCCL, serving, k3s) — [docs/REPOS.md](docs/REPOS.md)

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
| [**Phase 3b**](docs/PHASE-3-LORA-SERVE.md) | Publish LoRA → Ollama (`homelab-*` models in chat) |
| [**CNN fine-tune**](docs/CNN-FINETUNE.md) | ResNet18 image classifier (CIFAR-10 or custom folders) |
| [**GPU-only train**](docs/GPU-TRAIN.md) | **Default** — AMP + grad accum on RTX 5070 (`run-cnn-local.ps1`) |
| [**Reaction vision**](docs/REACTION-VISION.md) | FER / expressions — Barsoum FER+, ResNet |
| [Execution model](docs/EXECUTION-MODEL.md) | Postgres SSOT, GPU worker, SSH aliases |
| [GPU node runbook](docs/nodes/gpu-node.md) | Ollama on Windows |
| [GPU node checklist](docs/nodes/GPU-NODE-CHECKLIST.md) | Install ✅, ports, ML-only rule |
| [**GPU node — Ubuntu**](docs/nodes/gpu-node-ubuntu.md) | `zak-gpu-node`: CUDA 13.2, k3s, vLLM, DCGM/Grafana, Modal burst |
| [Git workflow](docs/GIT.md) | Clone, pull, push — GitHub `zakiscoding/homelab` |
| [Repositories](docs/REPOS.md) | Five repos: docs, services, gpu, web, gpu-systems-lab |
| [**Phase 6**](docs/PHASE-6.md) | Distributed train + MLflow |
| [**Web UI**](docs/services/web-ui.md) | Chat, RAG, reactions — `:3081` on iMac |
| [**Vision / reactions**](docs/services/vision-reactions.md) | FER CNN on GPU `:8100` |
| [Backups](docs/BACKUPS.md) | Postgres dumps, checkpoints, restic |
| [1TB layout](docs/DRIVE-LAYOUT.md) | iMac volume folder map |
| [Testing](docs/TESTING.md) | Tailscale curl checklist |
| [1TB drive layout](docs/DRIVE-LAYOUT.md) | Folder structure on external volume |
| [iMac checklist](docs/nodes/imac-checklist.md) | M1 services role — done vs planned |
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
| iMac — API/DB (Colima) | **Done** | Stack + web UI `:3080`; `100.91.113.98` |
| Web UI (homelab-web) | **Done** | Chat, RAG, overview over Tailscale |
| GPU Ollama (persistent) | **Done** | `HomelabOllamaServe` on `zak_pc` |
| Docs on 1TB drive | Done | `/Volumes/1tb drive/homelab` |
| Services on 1TB drive | Done | `/Volumes/1tb drive/homelab-services` |
| GitHub repos | **Done** | Four private repos: `homelab`, `homelab-services`, `homelab-gpu`, `homelab-web` |
| Monitoring | Running | Prometheus :9090, Grafana :3000 on iMac |
| Tailscale E2E tests | **Done** | GPU + iMac health; web UI chat/RAG from laptop |
| GPU training prep | **Done** | `homelab-gpu` cloned, Python, torch, data dirs |
| QLoRA smoke train | **Done** | Phase 3 — `training/lora_quickstart/train.py` via GPU worker |
| Backups | Documented | [BACKUPS.md](docs/BACKUPS.md) + `backup-postgres.sh` on iMac (schedule **Next**) |
| LoRA → Ollama inference | **Ready** | `publish-lora-to-ollama.ps1` — see [PHASE-3-LORA-SERVE.md](docs/PHASE-3-LORA-SERVE.md) |
| GPU node — Ubuntu boot | **Done** | `zak-gpu-node` `100.121.51.35`; CUDA 13.2, Docker, Open MPI — [gpu-node-ubuntu.md](docs/nodes/gpu-node-ubuntu.md) |
| GPU monitoring (DCGM) | **Running** | Grafana `100.121.51.35:3000/d/gpu-node`, Prometheus `:9090` (Ubuntu boot) |
| k3s GPU scheduling | **Running** | single node, NVIDIA device plugin, GPU admission policy |
| vLLM serving | **Done** | Qwen2.5-1.5B: 4.4k tok/s on RTX 5070 (on demand, localhost) |
| Cloud GPU burst (Modal) | **Done** | H100 / 2x H100; **$10** usage limit |
| Ubuntu node hardening | **Done** | `harden_node.sh`: LAN blocked for 22/6443/10250 (verified), sudo cleanup; reboot pending for Nsight counters |
| Chat on vLLM (dual-boot aware) | **Done** | `LLM_BACKEND=auto`: vLLM on Ubuntu, Ollama on Windows |
| Unified Grafana | **Done** | GPU node dashboard + datasource in the iMac Grafana |
| Router → job queue | **Done** | `route` jobs claimed by the router worker; local RTX or Modal |
| Postgres migrations | **Done** | DB was at 003; 004–007 applied 2026-10-23 (`scripts/migrate-all.sh`) |
