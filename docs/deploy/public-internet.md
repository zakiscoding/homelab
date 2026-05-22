# Public internet access (your nodes only)

Expose the **web UI** from the **iMac** using **Caddy** on ports **80/443**. No Cloudflare Tunnel, ngrok, or other hosted proxy — only your router, domain DNS, and the homelab stack.

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

# Password for the public site (save the hash output)
./scripts/hash-web-password.sh 'choose-a-strong-password'

# Edit .env — add:
# DOMAIN=ml.yourdomain.com
# ACME_EMAIL=you@yourdomain.com
# WEB_AUTH_USER=admin
# WEB_AUTH_HASH=<paste hash from hash-web-password.sh>

./scripts/render-caddyfile.sh
source ./scripts/docker-1tb-env.sh
docker-compose up -d --build caddy web
```

Open **https://ml.yourdomain.com** from any network. Use the basic-auth user/password you configured.

TLS certificates are issued automatically by **Let's Encrypt** via Caddy (outbound HTTPS only — no tunnel vendor).

## LAN / Tailscale without a domain

Leave `DOMAIN` unset in `.env`. Run `./scripts/render-caddyfile.sh` — Caddy serves **http://:80 → web** (and **http://100.91.113.98:3080** for direct UI).

## Security checklist

- [ ] Do **not** port-forward 3000, 6333, 6379, 9090, 9091, or 8000.
- [ ] Strong `WEB_AUTH_*` and `API_KEY` in `.env`.
- [ ] Keep Grafana/Prometheus Tailscale-only.
- [ ] Re-run `render-caddyfile.sh` after changing `DOMAIN` or auth.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Certificate pending | Confirm A record points to current public IP; ports 80/443 reach iMac |
| 401 on site | Use `WEB_AUTH_USER` + plaintext password (not the hash) in browser |
| Blank / 502 | `docker-compose logs web caddy`; rebuild `web` |
| API errors in UI | `API_KEY` in `.env` must match; `HOMELAB_API_KEY` uses same value in compose |

Log deploys in [SETUP-LOG](../SETUP-LOG.md).
