# iMac services stack

| | |
|--|--|
| **Repo** | [github.com/zakiscoding/homelab-services](https://github.com/zakiscoding/homelab-services) |
| **Path** | `/Volumes/1tb drive/homelab-services` |
| **Docker** | Colima — `homelab-runtime/colima/` on 1TB drive |
| **Docs** | [homelab](https://github.com/zakiscoding/homelab) (this file) |

## Why Colima

Lightweight Docker VM on macOS; all VM disk and compose data stay on the **1TB drive**. No Docker Desktop required.

## Quick start

```bash
brew install colima docker docker-compose
cd "/Volumes/1tb drive/homelab-services"
./scripts/setup-1tb.sh      # .env, data dirs, start Colima
./scripts/start-stack.sh    # pull + docker-compose up
curl http://localhost/health
```

Use `~/1tb-drive/homelab-services` if Colima has trouble with spaces in `/Volumes/1tb drive` (symlink created by scripts).

## Commands

| Task | Command |
|------|---------|
| Start | `./scripts/start-stack.sh` |
| Status | `docker-compose ps` |
| Logs | `docker-compose logs -f api` |
| Stop containers | `docker-compose down` |
| Stop Colima VM | `colima stop` |
| Rebuild API | `docker-compose up -d --build api` |
| Web UI | `./scripts/ensure-homelab-web.sh` then `docker-compose up -d --build web` → `:3080` |

Source env before manual docker commands:

```bash
source ./scripts/docker-1tb-env.sh
```

## Environment variables

See `homelab-services/.env.example`. Copy to `.env` on the iMac only.

## Colima + 1TB paths

| Variable / path | Location |
|-----------------|----------|
| `COLIMA_HOME` | `/Volumes/1tb drive/homelab-runtime/colima` |
| `DOCKER_CONFIG` | `/Volumes/1tb drive/homelab-runtime/docker-config` |
| Compose project | `/Volumes/1tb drive/homelab-services` |
| Service data | `homelab-services/data/*` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `docker compose` not found | Use `docker-compose` or fix `docker-config/config.json` cliPluginsExtraDirs |
| Bind mount “is a directory” | Run compose from `~/1tb-drive/homelab-services`; use directory mounts (not single files) |
| Grafana permission denied | `sudo chown -R 472:472 data/grafana` |
| `/chat` 401 | Set `x-api-key` from `.env` |
| `/chat` 502 | From iMac: `curl $GPU_URL/api/tags` |

Log changes in [SETUP-LOG](../SETUP-LOG.md).
