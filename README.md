# HOMELAB

**Documentation only** — hardware, network, services, setup logs. No Docker code here.

## Who is what

| Node | Machine | Windows user | Hostname | Role |
|------|---------|--------------|----------|------|
| **Controller** | Laptop | **`cashh`** | — | Docs, `git`, `curl` tests, SSH to GPU |
| **GPU node** | Desktop PC | **`zakar`** | `zak_pc` | Ollama + RTX 5070 |
| **App / DB** | iMac | **`momo`** | `Mos-iMac` | API stack in `homelab-services/` |

Both homelab Windows boxes run **Windows** (PowerShell). `cashh` = laptop only; `zakar` = GPU PC only.

## Paths on the 1TB drive

| Folder | Purpose |
|--------|---------|
| **`/Volumes/1tb drive/homelab`** | This repo — docs only |
| **`/Volumes/1tb drive/homelab-services`** | Docker stack, API, databases, `data/` |

| Machine | Docs | Services |
|---------|------|----------|
| **iMac** | `homelab/` | `homelab-services/` |
| **Controller (`cashh`)** | `C:\Users\cashh\homelab` (git clone) | Copy or clone `homelab-services` |
| **GPU PC (`zakar`)** | Optional clone of `homelab` | — |

**GitHub:** [homelab](https://github.com/zakiscoding/homelab) (docs) · [homelab-services](https://github.com/zakiscoding/homelab-services) (iMac stack) — [docs/REPOS.md](docs/REPOS.md)

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
| [Git workflow](docs/GIT.md) | Clone, pull, push — GitHub `zakiscoding/homelab` |
| [Repositories](docs/REPOS.md) | `homelab` + `homelab-services` + planned `homelab-gpu` |
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
| GitHub repos | **Done** | `homelab` + `homelab-services` (private) |
| Monitoring | Running | Prometheus :9090, Grafana :3000 on iMac |
| Backups | TBD | `pg_dump` / Restic not configured |
