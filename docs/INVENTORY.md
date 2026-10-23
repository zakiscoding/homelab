# Inventory

Hardware and logical resources. Update when we add, rename, or retire anything.

## Physical hardware

| Name | Role | Model / specs | Location | Notes |
|------|------|---------------|----------|-------|
| GPU PC (`zak_pc` / `zak-gpu-node`) | AI inference, training, HPC | RTX 5070 12 GB, 28 threads, 31 GiB | Homelab | Dual boot: Windows **`zakar`** (internal 2 TB NVMe) or Ubuntu **`zak`** (external 698 GB HDD) |
| iMac (`Mos-iMac`) | API / database | Apple iMac, **M1**, macOS 15.7 | Homelab | user **`momo`**; Colima + stack |
| Laptop (controller) | Ops / docs | Windows | Desk | User **`cashh`**; git + SSH to GPU |

## Hypervisor / hosts

| Hostname | Type | OS / hypervisor | CPU / RAM / disk | IP | Notes |
|----------|------|-----------------|------------------|-----|-------|
| gpu-node (`zak_pc`) | Bare metal | **Windows**, login **`zakar`** | RTX 5070, driver 596.x | **10.0.0.156**, **100.88.71.33** (Tailscale) | Ollama :11434; `homelab-gpu`; data `C:\Users\zakar\homelab-data\` |
| gpu-node Ubuntu (`zak-gpu-node`) | Bare metal (same PC) | **Ubuntu 24.04.5**, login **`zak`** | RTX 5070, driver 595.99.02, CUDA 13.2 | 10.0.0.21 (Wi-Fi), **100.121.51.35** (Tailscale) | Docker, k3s, vLLM, DCGM/Grafana — [gpu-node-ubuntu](nodes/gpu-node-ubuntu.md) |
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
| web | Mos-iMac | homelab-services-web | **3080** | Next.js UI |
| caddy | Mos-iMac | caddy:2-alpine | 80, 443 | → web:3000 |
| qdrant | Mos-iMac | qdrant/qdrant | 6333 | Vectors / RAG |
| imac-worker | Mos-iMac | build worker | — | RAG ingest/embed |
| prometheus | Mos-iMac | prom/prometheus | 9090 | Metrics |
| grafana | Mos-iMac | grafana/grafana | 3000 | Dashboards |

## Containers & cluster (GPU node, Ubuntu — `gpu-systems-lab`)

| Name | Host | Image / stack | Ports | Purpose |
|------|------|---------------|-------|---------|
| obs-dcgm-exporter | zak-gpu-node | nvcr.io/nvidia/k8s/dcgm-exporter:4.6.1-4.8.4 | 127.0.0.1:9400 | GPU metrics |
| obs-prometheus | zak-gpu-node | prom/prometheus:v3.5.0 | 100.121.51.35:9090 | GPU node metrics, 15-day retention |
| obs-grafana | zak-gpu-node | grafana/grafana:12.1.1 | 100.121.51.35:3000 | GPU dashboard `gpu-node` |
| obs-node-exporter | zak-gpu-node | prom/node-exporter:v1.9.1 | internal | CPU / RAM / disk |
| k3s | zak-gpu-node | k3s v1.36.5 (systemd) | 6443, 10250 | single-node Kubernetes |
| nvidia-device-plugin | k3s `kube-system` | nvcr.io/nvidia/k8s-device-plugin:v0.19.3 | — | advertises `nvidia.com/gpu: 1` |

## Cloud

| Provider | Account | Used for | Limits |
|----------|---------|----------|--------|
| Modal | workspace `zakiscoding` | H100 / 2x H100 / L4 bursts: benchmarks, NCCL, FSDP, vLLM | usage limit **$10**; volume `gpu-lab-hf-cache` (model weights) |

## Storage

| Pool / share | Backend | Size | Mount / export | Used for |
|--------------|---------|------|----------------|----------|
| 1TB drive | External/USB | ~1 TB | `/Volumes/1tb drive` | `homelab/`, `homelab-services/`, `homelab-web/`, `homelab-gpu/`, `homelab-runtime/`, `Personal/` — [DRIVE-LAYOUT](DRIVE-LAYOUT.md) |

## Domains & DNS (internal)

| FQDN | Points to | Service |
|------|-----------|---------|
| | | |
