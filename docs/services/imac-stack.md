# iMac services stack

| | |
|--|--|
| **Repo** | [github.com/zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services) |
| **Path** | `/Volumes/1tb drive/homelab-services` |
| **Docker** | Colima — `homelab-runtime/colima/` on 1TB drive |
| **Web UI** | [homelab-web](https://github.com/zakiscoding/homelab-web) — sibling `../homelab-web` |
| **Docs** | [homelab](https://github.com/zakiscoding/homelab) (this file) |

## Why Colima

Lightweight Docker VM on macOS; all VM disk and compose data stay on the **1TB drive**. No Docker Desktop required.

## Quick start

```bash
brew install colima docker docker-compose
cd "/Volumes/1tb drive/homelab-services"
./scripts/setup-1tb.sh      # .env, data dirs, start Colima
./scripts/render-caddyfile.sh
./scripts/start-stack.sh    # pull + docker-compose up
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3081/   # expect 200
```

Use `~/1tb-drive/homelab-services` if Colima has trouble with spaces in `/Volumes/1tb drive` (symlink created by scripts).

**Always** before manual docker commands:

```bash
source ./scripts/docker-1tb-env.sh
```

## Compose services

| Service | Host port | Purpose |
|---------|-----------|---------|
| **web** | **3081** | Next.js UI ([web-ui.md](web-ui.md)) |
| **caddy** | 80, 443 | Reverse proxy → `web:3000` (LAN mode) |
| **api** | internal 8000 | FastAPI → vLLM or Ollama (`LLM_BACKEND=auto`) |
| **postgres** | internal | Jobs, chat, RAG metadata |
| **redis** | 6379 | Counters, job wake |
| **qdrant** | 6333 | Vectors |
| **imac-worker** | — | RAG ingest / embed |
| **prometheus** | 9090 | Metrics |
| **grafana** | 3000 | Dashboards |
| **pushgateway** | 9091 | GPU push metrics |

## Commands

| Task | Command |
|------|---------|
| Start stack | `./scripts/start-stack.sh` |
| Status | `docker-compose ps` |
| Logs (API) | `docker-compose logs -f api` |
| Logs (web) | `docker-compose logs -f web` |
| Stop containers | `docker-compose down` |
| Stop Colima VM | `colima stop` |
| Rebuild API | `docker-compose up -d --build api` |
| Deploy / rebuild web | `./scripts/ensure-homelab-web.sh` then `docker-compose up -d --build web caddy` |
| Create `.env` | `./scripts/bootstrap-env.sh` |
| Caddy config (LAN) | `./scripts/render-caddyfile.sh` |
| Public HTTPS (optional) | Set `DOMAIN` in `.env`, then `./scripts/sync-caddy-config.sh` — [public-internet.md](../deploy/public-internet.md) |

## Environment variables

See `homelab-services/.env.example`. Copy to `.env` on the iMac only — never commit.

| Variable | Used by |
|----------|---------|
| `API_KEY` | API + web container (`HOMELAB_API_KEY`) |
| `LLM_BACKEND` | `auto`: vLLM if reachable, else Ollama; re-checked every 30 s |
| `GPU_URL` | API → Ollama fallback (default `http://100.88.71.33:11434`) |
| `WORKER_API_KEY` | GPU + iMac workers |
| `DOMAIN` | Optional public HTTPS only |

## Colima + 1TB paths

| Variable / path | Location |
|-----------------|----------|
| `COLIMA_HOME` | `/Volumes/1tb drive/homelab-runtime/colima` |
| `DOCKER_CONFIG` | `/Volumes/1tb drive/homelab-runtime/docker-config` |
| Compose project | `/Volumes/1tb drive/homelab-services` |
| Service data | `homelab-services/data/*` |
| `homelab-web` clone | `/Volumes/1tb drive/homelab-web` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `docker compose` not found | Use `docker-compose` or fix `docker-config/config.json` |
| `docker ps` empty | Run `source ./scripts/docker-1tb-env.sh` (Colima context) |
| Bind mount “is a directory” | Compose from `~/1tb-drive/`; sync scripts for Prometheus/Grafana |
| Grafana permission denied | `sudo chown -R 472:472 data/grafana` |
| Web `:3081` refused | `docker-compose up -d web` |
| `/chat` 401 | `x-api-key` / `HOMELAB_API_KEY` mismatch |
| `/chat` 502 or UI “Thinking…” | GPU Ollama down — `curl http://100.88.71.33:11434/api/tags`; [gpu-node.md](../nodes/gpu-node.md) |
| Caddy file mount error | Use compose `reverse-proxy` command; optional `sync-caddy-config.sh` for `DOMAIN` |

Log changes in [SETUP-LOG](../SETUP-LOG.md).
