# Inventory

Hardware and logical resources. Update when we add, rename, or retire anything.

## Physical hardware

| Name | Role | Model / specs | Location | Notes |
|------|------|---------------|----------|-------|
| GPU PC (`zak_pc`) | AI inference | RTX 5070 | Homelab | Windows user **`zakar`** |
| iMac (`Mos-iMac`) | API / database | Apple iMac, **M1**, macOS 15.7 | Homelab | user **`momo`**; Colima + stack |
| Laptop (controller) | Ops / docs | Windows | Desk | User **`cashh`**; git + SSH to GPU |

## Hypervisor / hosts

| Hostname | Type | OS / hypervisor | CPU / RAM / disk | IP | Notes |
|----------|------|-----------------|------------------|-----|-------|
| gpu-node (`zak_pc`) | Bare metal | **Windows**, login **`zakar`** | RTX 5070, driver 596.x | **10.0.0.156**, **100.88.71.33** (Tailscale) | Ollama :11434; `OllamaServe` at startup |
| imac-node (`Mos-iMac`) | Bare metal | **macOS** 15.7.3, **Apple M1**, **`momo`** | iMac | **100.91.113.98** (Tailscale) | Colima on 1TB; stack **running** — [SERVICES](SERVICES.md) |
| controller (laptop) | Laptop | **Windows**, login **`cashh`** | — | N/A | `C:\Users\cashh\homelab`; Tailscale to GPU |

## Virtual machines

| VM name | Host | vCPU | RAM | Disk | IP | Purpose |
|---------|------|------|-----|------|-----|---------|
| | | | | | | |

## Containers (iMac — `homelab-services`)

| Name | Host | Image / stack | Ports | Purpose |
|------|------|---------------|-------|---------|
| api | Mos-iMac | build `./api` | 8000 (internal) | FastAPI → GPU |
| postgres | Mos-iMac | postgres:16-alpine | internal | Chat logs |
| redis | Mos-iMac | redis:7-alpine | internal | Counters / queue |
| caddy | Mos-iMac | caddy:2-alpine | 80, 443 | Reverse proxy |
| qdrant | Mos-iMac | qdrant/qdrant | 6333 | Vectors / RAG |
| prometheus | Mos-iMac | prom/prometheus | 9090 | Metrics |
| grafana | Mos-iMac | grafana/grafana | 3000 | Dashboards |

## Storage

| Pool / share | Backend | Size | Mount / export | Used for |
|--------------|---------|------|----------------|----------|
| 1TB drive | External/USB | ~1 TB | `/Volumes/1tb drive` | `homelab/`, `homelab-services/`, `homelab-gpu/`, `homelab-runtime/`, `Personal/` — [DRIVE-LAYOUT](DRIVE-LAYOUT.md) |

## Domains & DNS (internal)

| FQDN | Points to | Service |
|------|-----------|---------|
| | | |
