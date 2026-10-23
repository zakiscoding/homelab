# Inventory

Hardware and logical resources. Update when we add, rename, or retire anything.

## Physical hardware

| Name | Role | Model / specs | Location | Notes |
|------|------|---------------|----------|-------|
| GPU PC (dual-boot) | AI inference + Ubuntu CUDA lab | RTX 5070 12GB | Homelab | **Same machine:** Windows `zak_pc`/`zakar` **or** Ubuntu `zak-gpu-node` — [ubuntu-gpu](ubuntu-gpu/) |
| iMac (`Mos-iMac`) | API / database | Apple iMac, **M1**, macOS 15.7 | Homelab | user **`momo`**; Colima + stack |
| Laptop (controller) | Ops / docs | Windows | Desk | User **`cashh`**; git + SSH to GPU |

## Hypervisor / hosts

| Hostname | Type | OS / hypervisor | CPU / RAM / disk | IP | Notes |
|----------|------|-----------------|------------------|-----|-------|
| gpu-node Windows (`zak_pc` / Tailscale `zakar`) | Bare metal | **Windows**, login **`zakar`** | RTX 5070, driver 596.x (Windows boot) | **10.0.0.156**, **100.88.71.33** (Tailscale) | Ollama :11434; `homelab-gpu`; data `C:\Users\zakar\homelab-data\`; offline when Ubuntu is booted |
| gpu-node Ubuntu (`zak-gpu-node`) | Bare metal | **Ubuntu** 24.04.5 on external `/dev/sda` | Same RTX 5070, driver 595.99.02 | **100.121.51.35** (Tailscale) | `~/projects/pytorch-cuda-smoke` Phase 1 **PASS**; never write Windows NVMe — [ubuntu-gpu](ubuntu-gpu/) |
| imac-node (`Mos-iMac`) | Bare metal | **macOS** 15.7.3, **Apple M1**, **`momo`** | iMac | **100.91.113.98** (Tailscale) | Colima on 1TB; stack **running** — [SERVICES](SERVICES.md) |
| controller (laptop) | Laptop | **Windows**, login **`cashh`** | — | **100.73.132.95** (Tailscale `hp-laptop`) | `C:\Users\cashh\homelab` |
| cursor-cloud | Cloud VM | Ubuntu (Cursor) | **No GPU** | **100.124.163.68** (Tailscale) | Not the dual-boot PC |

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
| web | Mos-iMac | homelab-services-web | **3080** | Next.js UI |
| caddy | Mos-iMac | caddy:2-alpine | 80, 443 | → web:3000 |
| qdrant | Mos-iMac | qdrant/qdrant | 6333 | Vectors / RAG |
| imac-worker | Mos-iMac | build worker | — | RAG ingest/embed |
| prometheus | Mos-iMac | prom/prometheus | 9090 | Metrics |
| grafana | Mos-iMac | grafana/grafana | 3000 | Dashboards |

## Storage

| Pool / share | Backend | Size | Mount / export | Used for |
|--------------|---------|------|----------------|----------|
| 1TB drive | External/USB | ~1 TB | `/Volumes/1tb drive` | `homelab/`, `homelab-services/`, `homelab-web/`, `homelab-gpu/`, `homelab-runtime/`, `Personal/` — [DRIVE-LAYOUT](DRIVE-LAYOUT.md) |

## Domains & DNS (internal)

| FQDN | Points to | Service |
|------|-----------|---------|
| | | |
