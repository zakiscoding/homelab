# iMac node — API & database (Phase 2)

**Host:** `Mos-iMac` · **User:** `momo` · **OS:** macOS  
**Docs repo:** `/Volumes/1tb drive/homelab`  
**Services repo:** `/Volumes/1tb drive/homelab-services`  
**Docker:** [Colima](https://github.com/abiosoft/colima) (not Docker Desktop) — VM disk on 1TB drive

HTTP API, database, and supporting services. GPU node serves Ollama; iMac proxies and persists.

## 1TB drive layout

| Path | Purpose |
|------|---------|
| `homelab/` | Documentation (git: `zakiscoding/homelab`) |
| `homelab-services/` | Compose stack (git: `zakiscoding/homelab-services`) |
| `colima/` | Colima VM + Docker engine data |
| `docker-config/` | Docker CLI config (compose plugin path) |
| `~/1tb-drive` | Symlink → `/Volumes/1tb drive` (for Colima bind mounts) |

## Verified

- iMac → GPU Ollama over Tailscale (`100.88.71.33:11434`)
- Stack via Colima: `curl http://localhost/health`, `POST /chat` → GPU

## Services

| Service | Port | Notes |
|---------|------|-------|
| Caddy | 80 | Reverse proxy → API |
| FastAPI | internal 8000 | `x-api-key` required for `/chat` |
| PostgreSQL | internal | `data/postgres` |
| Redis | internal | `data/redis` |
| Qdrant | 6333 | `data/qdrant` |
| Prometheus | 9090 | `prometheus/config/` |
| Grafana | 3000 | `data/grafana` (user `472` perms) |

Runbook: [services/imac-stack.md](../services/imac-stack.md)

## Colima install (one-time)

```bash
brew install colima docker docker-compose
"/Volumes/1tb drive/homelab-services/scripts/setup-1tb.sh"
```

## Start / stop stack

```bash
"/Volumes/1tb drive/homelab-services/scripts/start-stack.sh"
```

Or manually:

```bash
export COLIMA_HOME="/Volumes/1tb drive/colima"
colima start --cpu 4 --memory 6 --disk 80 --mount-type virtiofs --mount "/Volumes/1tb drive:w"
cd ~/1tb-drive/homelab-services
docker-compose up -d
```

```bash
colima stop   # stops all containers when VM stops
```

## Prerequisites checklist

- [x] GPU Ollama — [gpu-node.md](gpu-node.md)
- [x] Colima + images pulled
- [x] `.env` in `homelab-services/`
- [x] iMac Tailscale IP **100.91.113.98** — [INVENTORY](../INVENTORY.md)
- [x] macOS 15.7 documented in inventory

## Test from controller

```powershell
curl.exe http://<IMAC_TAILSCALE_IP>/health
curl.exe -X POST http://<IMAC_TAILSCALE_IP>/chat `
  -H "Content-Type: application/json" `
  -H "x-api-key: YOUR_KEY" `
  -d "{\"prompt\":\"Say hello.\"}"
```

API key is in `homelab-services/.env` on the iMac (not in git).
