# Phase 1 — Inference pipeline

**Status:** Deployed (2026-05-21)  
**Prerequisite:** [Phase 0](PHASE-0A.md) complete (0A + 0B).

## Goal

End-to-end LLM inference through the iMac API with traceable jobs:

```text
Client → POST /chat (x-api-key) → infer job in Postgres → Ollama on GPU → response + job_id
```

## What ships

| Item | Where | Notes |
|------|--------|--------|
| Ollama on GPU | `zak_pc` :11434 | Already live |
| API gateway | iMac Caddy → FastAPI | `/chat`, `/health`, `/health/gpu` |
| Infer jobs | `jobs` type=`infer` | Created + completed inline in `/chat` handler |
| `gpu_busy` guard | `create_infer_job()` | 503 if train running (unless `allow_infer_during_train`) |
| Chat traceability | `chat_logs.job_id` | Migration `004_phase1.sql` |
| GPU train worker (ops) | `register-gpu-worker-task.ps1` | Optional scheduled task at logon |

## API

| Method | Path | Auth |
|--------|------|------|
| POST | `/chat` | `x-api-key` — body `{ "prompt": "...", "model": "llama3.2:latest" }` |
| GET | `/health` | none |
| GET | `/health/gpu` | none |
| GET | `/system/status` | `x-api-key` |

Response includes `job_id`, `duration_ms`, `model`, `response`.

## Deploy (iMac)

```bash
ssh imac-ts
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
source /Volumes/1tb\ drive/homelab-services/scripts/docker-1tb-env.sh
cd /Volumes/1tb\ drive/homelab-services
git pull
chmod +x scripts/migrate-phase1.sh
POSTGRES_USER=app ./scripts/migrate-phase1.sh
docker-compose up -d --build --force-recreate api
```

## Deploy (GPU — optional always-on worker)

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
# Run once as Administrator:
.\scripts\register-gpu-worker-task.ps1
```

## Smoke test (laptop)

```powershell
$key = "YOUR_API_KEY"
$body = @{ prompt = "Say hello in one sentence."; model = "llama3.2:latest" } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "http://100.91.113.98/chat" -Method Post `
    -Headers @{ "x-api-key" = $key; "Content-Type" = "application/json" } -Body $body
$r.job_id
$r.response
Invoke-RestMethod -Uri "http://100.91.113.98/jobs/$($r.job_id)" -Headers @{ "x-api-key" = $key }
```

Expect infer job `status=succeeded`.

## Phase 1 done when

- [x] `/chat` returns a real Ollama response over Tailscale
- [x] Each `/chat` creates an `infer` job that reaches `succeeded` or `failed`
- [x] `chat_logs` stores `job_id` for correlation
- [ ] GPU scheduled worker registered on `zak_pc` (operator choice)

## Next: Phase 2 — RAG

Ingest → chunk → embed (iMac worker) → Qdrant → `/rag/query`. See roadmap in homelab plan; spec TBD in `docs/services/rag.md`.
