# Inventory

Hardware and logical resources. Update when we add, rename, or retire anything.

## Physical hardware

| Name | Role | Model / specs | Location | Notes |
|------|------|---------------|----------|-------|
| GPU PC | AI inference node | NVIDIA GPU (model TBD) | Homelab | Phase 1 |
| iMac | API / database node | Apple iMac (`Mos-iMac`) | Homelab | Phase 2; repo on 1TB drive |
| Laptop | Controller | Windows (user `cashh` tested Tailscale) | Desk | SSH/docs; reach GPU via `100.88.71.33:11434` |

## Hypervisor / hosts

| Hostname | Type | OS / hypervisor | CPU / RAM / disk | IP | Notes |
|----------|------|-----------------|------------------|-----|-------|
| gpu-node (`zak_pc`) | Bare metal | **Windows** (10/11) | RTX 5070, driver 596.x | **10.0.0.156** (Wi‑Fi), **100.88.71.33** (Tailscale) | Ollama :11434; task `OllamaServe` at startup |
| imac-node (`Mos-iMac`) | Bare metal | **macOS** (user `momo`) | iMac | _TBD_ Tailscale IP_ | Repo: `/Volumes/1tb drive/homelab`; iMac→GPU Ollama OK |
| controller | Laptop | Windows 10/11 | Laptop | N/A | Sync docs from `homelab` on 1TB drive |

## Virtual machines

| VM name | Host | vCPU | RAM | Disk | IP | Purpose |
|---------|------|------|-----|------|-----|---------|
| | | | | | | |

## Containers / LXC

| Name | Host | Image / stack | IP / ports | Purpose |
|------|------|---------------|------------|---------|
| | | | | |

## Storage

| Pool / share | Backend | Size | Mount / export | Used for |
|--------------|---------|------|----------------|----------|
| | | | | |

## Domains & DNS (internal)

| FQDN | Points to | Service |
|------|-----------|---------|
| | | |
