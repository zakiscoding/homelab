# Web UI (homelab-web)

Next.js app for chat, RAG, and platform overview. Repo: **`homelab-web`** (laptop clone `C:\Users\cashh\homelab-web`).

## Hosting

| Phase | Host | URL |
|-------|------|-----|
| Dev | Laptop `cashh` | http://localhost:3000 |
| Prod | iMac Docker `:3080` | http://100.91.113.98:3080 |

Do **not** run the UI on the GPU PC. Grafana already uses iMac **`:3000`** — web uses **`:3080`** to avoid a port clash.

The UI calls the iMac API through a Next.js **BFF** (`/api/homelab/*`) so `HOMELAB_API_KEY` stays server-side.

## Setup (laptop)

```powershell
cd C:\Users\cashh\homelab-web
copy .env.local.example .env.local
# HOMELAB_API_KEY = API_KEY from iMac homelab-services/.env
npm run dev
```

## iMac deploy

Clone beside `homelab-services` on the 1TB drive, then build the `web` service:

```bash
cd ~/1tb-drive/homelab-services
./scripts/ensure-homelab-web.sh
source ./scripts/docker-1tb-env.sh
docker-compose up -d --build web
```

Open http://100.91.113.98:3080

## Surfaces

- Overview — `/health`, `/health/gpu`, `/system/status`
- Chat — plain Ollama (`POST /chat`)
- RAG — ingest → wait for worker → query

See [homelab-web README](https://github.com/zakiscoding/homelab-web) or `homelab-web/README.md` locally.
