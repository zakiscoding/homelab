# HOMELAB

Living documentation for this homelab: hardware, network, services, and every setup step we take.

## Who is what

| Node | Machine | Windows user | Hostname | Role |
|------|---------|--------------|----------|------|
| **Controller** | Laptop | **`cashh`** | — | Docs, `git`, `curl` tests, SSH to GPU |
| **GPU node** | Desktop PC | **`zakar`** | `zak_pc` | Ollama + RTX 5070 |
| **App / DB** | iMac | **`momo`** | `Mos-iMac` | API, compose, repo on 1TB drive |

Both homelab Windows boxes run **Windows** (PowerShell). `cashh` = laptop only; `zakar` = GPU PC only.

## Repo location (canonical)

| Machine | Path |
|---------|------|
| **iMac** | `/Volumes/1tb drive/homelab` |
| **Controller (laptop `cashh`)** | `C:\Users\cashh\homelab` (git clone) |
| **GPU PC (`zakar`)** | `C:\Users\zakar\HOMELAB` or clone `homelab` — same GitHub repo |

Config, compose stacks, and scripts live under this tree — not in `~/homelab`.

**GitHub:** [github.com/zakiscoding/homelab](https://github.com/zakiscoding/homelab) (private) — see [docs/GIT.md](docs/GIT.md) to push/clone.

## Quick links

| Doc | Purpose |
|-----|---------|
| [Setup log](docs/SETUP-LOG.md) | Chronological record of what we did and when |
| [Inventory](docs/INVENTORY.md) | Hosts, VMs, containers, hardware |
| [Network](docs/NETWORK.md) | VLANs, subnets, DNS, firewall, VPN |
| [Services](docs/SERVICES.md) | Running apps and how to reach/manage them |
| [Secrets & access](docs/ACCESS.md) | Where credentials live (not the secrets themselves) |
| [Architecture](docs/ARCHITECTURE.md) | Three-node layout (GPU / iMac / controller) |
| [GPU node runbook](docs/nodes/gpu-node.md) | Docker, NVIDIA toolkit, Ollama |
| [Git workflow](docs/GIT.md) | Clone, pull, push — GitHub `zakiscoding/homelab` |

## How we use this repo

1. **`git pull`** — GitHub is canonical; other nodes depend on it.
2. **Before a change** — skim [SETUP-LOG](docs/SETUP-LOG.md) so we do not repeat mistakes.
3. **During setup** — note commands, versions, and config paths in the log (or a service section).
4. **After it works** — update inventory, network, and services, then **`git commit` + `git push`** so every node can `git pull` and see the latest.

Config files, compose stacks, and scripts can live in this repo as we add them; link them from the relevant doc sections.

## Status

| Area | Status | Notes |
|------|--------|-------|
| Documentation scaffold | Done | 2026-05-21 |
| Architecture (3 nodes) | Documented | GPU first, iMac phase 2 |
| GPU node — OS/GPU verify | **Done** | Windows; RTX 5070, `nvidia-smi` OK |
| GPU node — Ollama LAN | **Done** | `OLLAMA_HOST`, firewall, Tailscale + LAN curl OK |
| GPU node — Docker | Optional | Skip unless needed for other containers |
| iMac — API/DB | In progress | iMac → GPU Ollama verified; Docker stack TBD |
| Repo on 1TB drive | Done | `/Volumes/1tb drive/homelab` |
| Core network | Partial | Fill IPs in inventory |
| Storage | — | |
| Monitoring / backups | — | |
