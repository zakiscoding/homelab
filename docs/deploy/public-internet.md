# Public internet access (optional)

**Default homelab access is Tailscale only** — see [services/web-ui.md](../services/web-ui.md) (`http://100.91.113.98:3080`). Use this guide only if you want a **public domain** on your own router (no Cloudflare Tunnel / ngrok).

Expose the **web UI** from the **iMac** using **Caddy** on ports **80/443**. Only your router, domain DNS, and the homelab stack.

## What is exposed

| WAN port | → iMac | Service |
|----------|--------|---------|
| 80, 443 | Caddy | **homelab-web** only (login via Caddy basic auth) |
| — | **not** forwarded | API :8000, Grafana :3000, Prometheus, Qdrant, Redis |

The FastAPI stays on the Docker network. The browser talks to Next.js; Next.js proxies to `api:8000` with your API key on the server.

## Prerequisites

1. A **domain** you control (A record → your home **public IP**).
2. Router **port forward**: WAN **80** and **443** → iMac LAN IP (same host running Colima).
3. iMac stack up with `homelab-web` cloned beside `homelab-services`.

## iMac setup

```bash
cd ~/1tb-drive/homelab-services
git pull
./scripts/ensure-homelab-web.sh

# First time only — creates .env with random secrets (or copy from laptop)
./scripts/bootstrap-env.sh
# Or: scp from laptop — see below

# Edit .env — use a hostname YOU own (not the docs placeholder):
# DOMAIN=ml.example.com
# ACME_EMAIL=you@example.com
# WEB_AUTH_USER=admin
# WEB_AUTH_HASH='$2a$14$...'    ← single quotes! bcrypt hash contains $

./scripts/render-caddyfile.sh
source ./scripts/docker-1tb-env.sh
docker-compose up -d --build caddy web
```

Open **https://YOUR-DOMAIN** (the exact value of `DOMAIN` in `.env`). Use the basic-auth user/password you configured.

Run `./scripts/check-public-tls.sh` on the iMac to verify DNS and the certificate before using Chrome.

TLS certificates are issued automatically by **Let's Encrypt** via Caddy (outbound HTTPS only — no tunnel vendor).

## LAN / Tailscale without a domain

Leave `DOMAIN` unset in `.env`. Run `./scripts/render-caddyfile.sh` — Caddy serves **http://:80 → web** (and **http://100.91.113.98:3080** for direct UI).

## Security checklist

- [ ] Do **not** port-forward 3000, 6333, 6379, 9090, 9091, or 8000.
- [ ] Strong `WEB_AUTH_*` and `API_KEY` in `.env`.
- [ ] Keep Grafana/Prometheus Tailscale-only.
- [ ] Re-run `render-caddyfile.sh` after changing `DOMAIN` or auth.

## Troubleshooting

### Chrome: “unusual and incorrect credentials” + HSTS

Almost always one of these:

1. **You opened `ml.yourdomain.com` literally** — that string in the docs is a **placeholder**, not a real site. Use the domain you bought (e.g. `ml.mydomain.net`). If you already visited the placeholder, clear HSTS: Chrome → `chrome://net-internals/#hsts` → Delete domain security policies → `ml.yourdomain.com`.
2. **DNS does not point to your home** — `dig +short A YOUR-DOMAIN` must show your current public IP.
3. **Port 443 is not reaching Caddy** — router forward WAN 443 → iMac; run `docker-compose logs caddy` on the iMac for ACME errors.
4. **Broken `WEB_AUTH_HASH` in `.env`** — bcrypt hashes contain `$`; wrap the hash in **single quotes** or re-run `render-caddyfile.sh` after pulling the latest script.

### Other issues

| Issue | Fix |
|-------|-----|
| Certificate pending | Confirm A record → public IP; ports 80/443 reach iMac; `docker-compose logs caddy` |
| 401 on site | Use `WEB_AUTH_USER` + plaintext password (not the hash) in browser |
| Blank / 502 | `docker-compose logs web caddy`; rebuild `web` |
| API errors in UI | `API_KEY` in `.env` must match; `HOMELAB_API_KEY` uses same value in compose |

Log deploys in [SETUP-LOG](../SETUP-LOG.md).
