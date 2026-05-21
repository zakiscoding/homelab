# End-to-end tests

Run after changes or from a new machine on Tailscale.

## From controller laptop (`cashh`)

```powershell
# GPU Ollama
curl.exe http://100.88.71.33:11434/api/tags

# iMac stack
curl.exe http://100.91.113.98/health
curl.exe http://100.91.113.98:9090/-/healthy
curl.exe http://100.91.113.98:6333/

# Chat (replace KEY from iMac homelab-services/.env)
$key = "YOUR_API_KEY"
$body = @{ prompt = "Hello" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98/chat" -Method Post -Headers @{ "x-api-key" = $key } -Body $body -ContentType "application/json"
```

## From GPU PC (`zakar`)

Same URLs; localhost Ollama:

```powershell
curl.exe http://127.0.0.1:11434/api/tags
curl.exe http://100.91.113.98/health
cd C:\Users\zakar\homelab-gpu
.\scripts\verify-gpu.ps1
```

## Expected (2026-05-21)

| Check | Expected |
|-------|----------|
| GPU tags | JSON with `llama3.2:latest` |
| iMac health | 200 OK |
| iMac /chat | JSON with GPU-backed reply |
| verify-gpu | `cuda True`, RTX 5070 |

## Phase 0A — train jobs (after deploy)

See [PHASE-0A.md](PHASE-0A.md). SSH: `imac-ts`, `zak-ts`.

```powershell
$key = "YOUR_API_KEY"   # iMac homelab-services/.env
$job = Invoke-RestMethod -Uri "http://100.91.113.98/jobs" -Method Post -Headers @{ "x-api-key" = $key }
$job.id
Invoke-RestMethod -Uri "http://100.91.113.98/jobs/$($job.id)" -Headers @{ "x-api-key" = $key }
```

| Check | Expected |
|-------|----------|
| POST /jobs | `status: pending`, `type: train` |
| GPU worker running | becomes `running` then `succeeded` |
| Gate (kill -9) | reset-stale + retry → one `published.json` under `checkpoints\{job_id}\` |

Log results in [SETUP-LOG.md](SETUP-LOG.md).
