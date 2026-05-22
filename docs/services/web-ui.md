# Web UI (homelab-web)

Next.js app for **chat**, **RAG**, and **platform overview**. Repo: [zakiscoding/homelab-web](https://github.com/zakiscoding/homelab-web).

## Traffic flow

```text
Browser (Tailscale)
    │
    ├─ http://100.91.113.98:3080  ──► homelab-web (Docker)
    └─ http://100.91.113.98/      ──► Caddy :80 ──► homelab-web
              │
              │  /api/homelab/*  (Next.js BFF, server-side API key)
              ▼
         iMac FastAPI :8000 (internal)
              │
              │  Tailscale
              ▼
         GPU Ollama :11434
```

The browser **never** holds `API_KEY`. Grafana stays on **`:3000`**; the web UI uses **`:3080`** so ports do not clash.

## URLs (Tailscale)

| URL | What |
|-----|------|
| http://100.91.113.98:3080 | Web UI (direct) |
| http://100.91.113.98/ | Same UI via Caddy |
| http://100.91.113.98:3000 | Grafana (not the ML UI) |
| http://100.88.71.33:11434/api/tags | GPU Ollama health |

**No domain required** — Tailscale or home LAN only. Optional public HTTPS: [deploy/public-internet.md](../deploy/public-internet.md).

## Pages

| Path | API |
|------|-----|
| `/` | `/health`, `/health/gpu`, `/system/status` |
| `/chat` | `POST /chat` → Ollama |
| `/rag` | `POST /rag/ingest`, `POST /rag/query`, `GET /rag/status` |

## iMac deploy (production)

`homelab-web` must sit **beside** `homelab-services` on the 1TB drive:

```text
/Volumes/1tb drive/
  homelab-services/
  homelab-web/          ← build context ../homelab-web
```

```bash
cd ~/1tb-drive/homelab-services
git pull
./scripts/ensure-homelab-web.sh    # clone if missing
source ./scripts/docker-1tb-env.sh

# First-time secrets (iMac only):
./scripts/bootstrap-env.sh         # or keep existing .env

./scripts/render-caddyfile.sh      # LAN: Caddy :80 → web
docker-compose up -d --build web caddy
```

Verify:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3080/
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/
```

Both should return **200**.

## Laptop dev

```powershell
git clone https://github.com/zakiscoding/homelab-web.git C:\Users\cashh\homelab-web
cd C:\Users\cashh\homelab-web
copy .env.local.example .env.local
```

Set in `.env.local`:

```env
HOMELAB_API_URL=http://100.91.113.98
HOMELAB_API_KEY=<API_KEY from iMac homelab-services/.env>
```

```powershell
npm install
npm run dev
```

Open http://localhost:3000

Generate laptop `.env` for services (optional):

```powershell
cd C:\Users\cashh\homelab-services
.\scripts\bootstrap-env.ps1   # also writes homelab-web\.env.local
```

## GPU prerequisite (chat / RAG)

Chat hangs on **Thinking…** when Ollama is down. On **`zak_pc`**:

```powershell
# Quick check from laptop
curl.exe http://100.88.71.33:11434/api/tags

# On GPU — persistent serve (recommended)
schtasks /Run /TN HomelabOllamaServe

# Or first-time setup (Admin PowerShell on GPU)
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\install-ollama-serve-task.ps1
```

Scripts: `serve-ollama.bat`, `start-ollama.ps1`, `install-ollama-serve-task.ps1` — see [gpu-node.md](../nodes/gpu-node.md).

## iMac scripts

| Script | Purpose |
|--------|---------|
| `ensure-homelab-web.sh` | Clone `homelab-web` beside services |
| `bootstrap-env.sh` / `.ps1` | Create `.env` + `homelab-web/.env.local` |
| `render-caddyfile.sh` | `data/caddy/Caddyfile` (LAN or public HTTPS) |
| `sync-caddy-config.sh` | Inject Caddyfile when `DOMAIN` set (Colima) |
| `start-stack.sh` | Full stack + render caddy |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `:3080` connection refused | `docker-compose up -d web` on iMac; `source docker-1tb-env.sh` |
| Chat **Thinking…** forever | `curl.exe http://100.88.71.33:11434/api/tags`; start Ollama on GPU |
| Chat **502** | GPU Ollama unreachable from iMac; check `GPU_URL` in `.env` |
| `/` 404, `/health` works | Old Caddy → API; `git pull`, rebuild `web` + `caddy` |
| API errors in UI | `HOMELAB_API_KEY` in web container must match iMac `API_KEY`; recreate `web` |
| Caddy mount error | Colima quirk — use compose `reverse-proxy` command (see `docker-compose.yml`) |

## Secrets

| File | Machine | Committed? |
|------|---------|------------|
| `homelab-services/.env` | iMac | **Never** |
| `homelab-web/.env.local` | Laptop dev | **Never** |

See [REPOS.md](../REPOS.md), [imac-stack.md](imac-stack.md), [homelab-web README](https://github.com/zakiscoding/homelab-web).
