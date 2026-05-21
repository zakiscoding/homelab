# iMac services stack

**Code & compose:** `/Volumes/1tb drive/homelab-services`  
**Not in this repo** — `homelab` is documentation only.

## Layout on 1TB drive

```text
/Volumes/1tb drive/
├── homelab/              ← docs (this git repo)
└── homelab-services/     ← Docker stack, API, data/
    ├── docker-compose.yml
    ├── .env              ← local secrets (gitignored in services repo)
    ├── api/
    ├── data/             ← postgres, redis, qdrant, grafana, ...
    ├── caddy/
    └── prometheus/
```

## Install & run

See [homelab-services/README.md](../../../homelab-services/README.md) on the iMac (path above).

Summary:

```bash
cd "/Volumes/1tb drive/homelab-services"
cp .env.example .env
mkdir -p data/{postgres,redis,qdrant,prometheus,grafana,caddy,caddy-config}
docker compose up -d --build
```

## Environment variables (names only)

| Variable | Used by |
|----------|---------|
| `GPU_URL` | API → Ollama on GPU node |
| `POSTGRES_*` | Postgres container |
| `API_KEY` | FastAPI `x-api-key` header |
| `GRAFANA_*` | Grafana admin login |

Values live in `homelab-services/.env` only.

## Upgrade / troubleshooting

- **Rebuild API:** `docker compose up -d --build api`
- **Logs:** `docker compose logs -f api`
- **GPU unreachable:** from iMac, `curl $GPU_URL/api/tags`
- Log changes in [SETUP-LOG](../SETUP-LOG.md)
