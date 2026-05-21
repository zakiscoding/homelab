# Inventory

Hardware and logical resources. Update when we add, rename, or retire anything.

## Physical hardware

| Name | Role | Model / specs | Location | Notes |
|------|------|---------------|----------|-------|
| GPU PC (`zak_pc`) | AI inference | RTX 5070 | Homelab | Windows user **`zakar`** |
| iMac (`Mos-iMac`) | API / database | Apple iMac | Homelab | macOS user **`momo`**; repo on 1TB |
| Laptop (controller) | Ops / docs | Windows | Desk | User **`cashh`**; git + SSH to GPU |

## Hypervisor / hosts

| Hostname | Type | OS / hypervisor | CPU / RAM / disk | IP | Notes |
|----------|------|-----------------|------------------|-----|-------|
| gpu-node (`zak_pc`) | Bare metal | **Windows**, login **`zakar`** | RTX 5070, driver 596.x | **10.0.0.156**, **100.88.71.33** (Tailscale) | Ollama :11434; `OllamaServe` at startup |
| imac-node (`Mos-iMac`) | Bare metal | **macOS**, login **`momo`** | iMac | _TBD_ Tailscale IP_ | `/Volumes/1tb drive/homelab`; iMac→GPU OK |
| controller (laptop) | Laptop | **Windows**, login **`cashh`** | — | N/A | `C:\Users\cashh\homelab`; Tailscale curl to GPU |

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
