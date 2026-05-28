# Vision / Reactions (FER CNN on GPU)

Facial expression classification via a small CNN on the **GPU PC**, proxied through the iMac API and exposed in **homelab-web** at `/reactions`.

## Traffic flow

```text
Browser /reactions
    │
    │  POST /api/homelab/vision/reaction  (BFF, x-api-key server-side)
    ▼
iMac FastAPI  /vision/reaction
    │
    │  Tailscale
    ▼
GPU reaction serve  :8100  /infer/reaction
```

## URLs (Tailscale)

| URL | What |
|-----|------|
| http://100.91.113.98:3081/reactions | Web UI — webcam or upload |
| http://100.91.113.98:8000/vision/status | API health (needs `x-api-key`) |
| http://100.88.71.33:8100/health | GPU reaction service (direct) |

## iMac configuration

In `homelab-services/.env`:

```bash
GPU_VISION_URL=http://100.88.71.33:8100
REACTION_SERVE_KEY=   # optional; must match GPU serve if set
```

Redeploy API after changes:

```bash
source ./scripts/docker-1tb-env.sh
docker-compose up -d --build api
```

## GPU PC (zak_pc)

Reaction inference runs **only on the GPU** — not in Docker on the iMac.

1. Clone/update **homelab-gpu** on `C:\Users\zakar\homelab-gpu`.
2. Start the reaction serve process (port **8100**):

```powershell
cd C:\Users\zakar\homelab-gpu
.\scripts\start-reaction-serve-bg.ps1
```

3. Verify from laptop:

```powershell
curl.exe http://100.88.71.33:8100/health
```

If the web UI shows “vision down”, Ollama may still work — start reaction serve separately.

## Webcam over Tailscale

Browsers block `getUserMedia` on plain HTTP. Over Tailscale use **Upload photo**, or tunnel HTTPS to localhost:

```bash
ssh -L 3081:127.0.0.1:3081 imac-ts
# open https://localhost:3081/reactions
```

## Metrics

Prometheus gauges (Phase 5+):

- `homelab_vision_requests_total`
- `homelab_vision_request_duration_seconds`
- `homelab_reaction_serve_up` (from GPU push script when configured)

See Grafana dashboard **Homelab Stack** (`grafana/dashboards/homelab-stack.json`).

## Related

- [web-ui.md](web-ui.md) — deploy homelab-web on `:3081`
- [PHASE-5.md](../PHASE-5.md) — observability
- GPU training repo: [homelab-gpu](https://github.com/zakiscoding/homelab-gpu)
