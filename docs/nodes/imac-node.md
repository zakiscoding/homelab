# iMac node — API & database (Phase 2)

**Host:** `Mos-iMac` · **User:** `momo` · **OS:** macOS  
**Repo (all homelab files):** `/Volumes/1tb drive/homelab`

HTTP API, database, and supporting services. GPU node serves Ollama; iMac proxies and persists.

## Verified (2026-05-21)

```bash
curl http://100.88.71.33:11434/api/tags          # OK — llama3.2:latest
curl http://100.88.71.33:11434/api/generate ...  # OK — response "Hello!"
```

Use `curl` on macOS (not `curl.exe`).

## Planned workloads

| Service | Notes |
|---------|-------|
| API gateway / backend | FastAPI under `homelab/compose/` (TBD) |
| Database | Postgres + Redis in Docker |
| Reverse proxy (optional) | Caddy/Nginx later |

## Before starting Docker

- [x] GPU node checklist — [gpu-node.md](gpu-node.md)
- [x] iMac → GPU over Tailscale
- [ ] iMac Tailscale IP in [INVENTORY](../INVENTORY.md)
- [ ] Docker Desktop installed on iMac
- [ ] `sw_vers` and iMac model/year in inventory (for embedding offload decision)

## Setup

_Add compose stack under `/Volumes/1tb drive/homelab/compose/` — log steps in [SETUP-LOG](../SETUP-LOG.md)._
