# iMac node — API & database

**Host:** `Mos-iMac` · **User:** `momo` · **OS:** macOS 15.7 · **CPU:** Apple M1  
**Docs:** `/Volumes/1tb drive/homelab`  
**Stack:** `/Volumes/1tb drive/homelab-services`  
**Docker:** [Colima](https://github.com/abiosoft/colima) — VM at `homelab-runtime/colima/`

Application platform and data services. GPU node runs Ollama; iMac proxies and persists.

**Quick checklist:** [imac-checklist.md](imac-checklist.md) — responsibilities, ports, done vs planned.

## Role summary

| Do on iMac | Do on GPU PC |
|------------|----------------|
| FastAPI, Caddy, Postgres, Redis, Qdrant | Ollama inference |
| Prometheus, Grafana | Model training (`homelab-gpu`) |
| Auth, routing, storage (growing) | CUDA / large models |

## 1TB paths

| Path | Purpose |
|------|---------|
| `homelab/` | This documentation repo |
| `homelab-services/` | Docker compose + API code |
| `homelab-runtime/` | Colima + `docker-config` |
| `~/1tb-drive` | Symlink to volume (Colima mounts) |

## Network

| Interface | IP |
|-----------|-----|
| Tailscale | **100.91.113.98** |
| GPU Ollama (via Tailscale) | `http://100.88.71.33:11434` |

## Exposed ports

| Port | Service |
|------|---------|
| 80 | Caddy → FastAPI |
| 3000 | Grafana |
| 6333 | Qdrant |
| 9090 | Prometheus |

## Install (one-time)

```bash
brew install colima docker docker-compose
"/Volumes/1tb drive/homelab-services/scripts/setup-1tb.sh"
```

## Daily operations

```bash
source ~/1tb-drive/homelab-services/scripts/docker-1tb-env.sh
colima start    # if VM not running
cd ~/1tb-drive/homelab-services && docker-compose up -d
curl http://localhost/health
```

Full runbook: [services/imac-stack.md](../services/imac-stack.md)

## Test from controller (`cashh`)

```powershell
curl.exe http://100.91.113.98/health
curl.exe -X POST http://100.91.113.98/chat `
  -H "Content-Type: application/json" `
  -H "x-api-key: YOUR_KEY" `
  -d "{\"prompt\":\"Say hello.\"}"
```

API key: `homelab-services/.env` on the iMac (not in git).
