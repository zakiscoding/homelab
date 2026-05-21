# Services

What runs in the lab and how to operate it. One row per service; link to config in this repo when it exists.

## Core infrastructure

| Service | Runs on | URL / access | Config in repo | Backup |
|---------|---------|--------------|----------------|--------|
| Reverse proxy | | | | |
| DNS / ad-blocking | | | | |
| Certificate authority / TLS | | | | |
| Monitoring | | | | |
| Backups | | | | |

## Applications

| Service | Runs on | URL / access | Config in repo | Notes |
|---------|---------|--------------|----------------|-------|
| Ollama | gpu-node | `http://10.0.0.156:11434` (LAN), `http://100.88.71.33:11434` (Tailscale) | [gpu-node.md](nodes/gpu-node.md) | Model: `llama3.2:latest` |

## Per-service detail (optional)

Create `docs/services/<name>.md` when a service needs more than a table row (install steps, env vars, upgrade path).

### Example: `docs/services/example.md`

- **Purpose:**
- **Install method:** (Docker / compose / apt / Helm)
- **Data paths:**
- **Environment variables:** (names only; values in vault — see [ACCESS](ACCESS.md))
- **Upgrade:**
- **Troubleshooting:**
