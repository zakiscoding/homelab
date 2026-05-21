# iMac node — API & database (Phase 2)

**Host:** `Mos-iMac` · **User:** `momo` · **OS:** macOS  
**Docs repo:** `/Volumes/1tb drive/homelab`  
**Services stack:** `/Volumes/1tb drive/homelab-services` ← Docker runs here, not in `homelab/`

HTTP API, database, and supporting services. GPU node serves Ollama; iMac proxies and persists.

## Verified (2026-05-21)

```bash
curl http://100.88.71.33:11434/api/tags          # OK — llama3.2:latest
curl http://100.88.71.33:11434/api/generate ...  # OK — response "Hello!"
```

Use `curl` on macOS (not `curl.exe`).

## Services (on 1TB drive)

| Service | Port | Config |
|---------|------|--------|
| Caddy | 80 / 443 | `homelab-services/caddy/` |
| FastAPI | via Caddy | `homelab-services/api/` |
| PostgreSQL | internal | `homelab-services/data/postgres` |
| Redis | internal | `homelab-services/data/redis` |
| Qdrant | 6333 | `homelab-services/data/qdrant` |
| Prometheus | 9090 | `homelab-services/prometheus/` |
| Grafana | 3000 | `homelab-services/data/grafana` |

Full runbook: [services/imac-stack.md](../services/imac-stack.md)

## Prerequisites

- [x] GPU node Ollama — [gpu-node.md](gpu-node.md)
- [x] iMac → GPU over Tailscale
- [ ] **Docker Desktop** on iMac ([install](#docker-desktop))
- [ ] Copy `homelab-services/.env.example` → `.env`
- [ ] `docker compose up -d --build` from `homelab-services/`
- [ ] iMac Tailscale IP in [INVENTORY](../INVENTORY.md)
- [ ] `sw_vers` + model in inventory

## Docker Desktop

1. Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/).
2. Install to **Applications** (app binary stays there; **data** goes under `homelab-services/data/` via compose bind mounts).
3. Open Docker Desktop once; wait until “Engine running”.
4. Verify: `docker compose version`

**Disk:** Keep the 1TB volume mounted; compose uses `/Volumes/1tb drive/homelab-services`.

## Start stack

```bash
cd "/Volumes/1tb drive/homelab-services"
cp .env.example .env   # edit GPU_URL, passwords, API_KEY
mkdir -p data/{postgres,redis,qdrant,prometheus,grafana,caddy,caddy-config}
docker compose up -d --build
curl http://localhost/health
```

## Test from controller (Tailscale)

```powershell
curl.exe http://<IMAC_TAILSCALE_IP>/health
curl.exe -X POST http://<IMAC_TAILSCALE_IP>/chat `
  -H "Content-Type: application/json" `
  -H "x-api-key: YOUR_KEY" `
  -d "{\"prompt\":\"Say hello in one sentence.\"}"
```

Log results in [SETUP-LOG](../SETUP-LOG.md).
