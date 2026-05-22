# End-to-end tests

Run after changes or from a new machine on Tailscale.

## From controller laptop (`cashh`)

```powershell
# GPU Ollama (required for chat)
curl.exe http://100.88.71.33:11434/api/tags

# Web UI
curl.exe -s -o NUL -w "%{http_code}" http://100.91.113.98:3080/
curl.exe -s -o NUL -w "%{http_code}" http://100.91.113.98/

# iMac stack (ops)
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

## Web UI chat (via BFF)

```powershell
$key = "YOUR_API_KEY"   # iMac homelab-services/.env
$h = @{ "x-api-key" = $key; "Content-Type" = "application/json" }
$body = @{ prompt = "say hi"; model = "llama3.2:latest" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98:3080/api/homelab/chat" -Method Post -Headers $h -Body $body
```

## Expected

| Check | Expected |
|-------|----------|
| GPU tags | JSON with `llama3.2:latest` |
| Web UI `:3080` / `/` | HTTP 200 |
| Web chat | JSON with `response`, `duration_ms` |
| iMac `/health` | 200 OK (direct API; optional) |
| verify-gpu | `cuda True`, RTX 5070 |

## Phase 2 — RAG

```powershell
$key = "YOUR_API_KEY"
$h = @{ "x-api-key" = $key; "Content-Type" = "application/json" }
$ing = @{ text = "The GPU node is zak_pc with RTX 5070."; source_id = "test1" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98/rag/ingest" -Method Post -Headers $h -Body $ing
# Wait for imac-worker (~60s), then:
$q = @{ query = "What GPU is in the homelab?"; model = "llama3.2:latest" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98/rag/query" -Method Post -Headers $h -Body $q
```

## Phase 1 — /chat inference

```powershell
$key = "YOUR_API_KEY"
$body = @{ prompt = "Hello"; model = "llama3.2:latest" } | ConvertTo-Json -Compress
$r = Invoke-RestMethod -Uri "http://100.91.113.98/chat" -Method Post `
  -Headers @{ "x-api-key" = $key; "Content-Type" = "application/json" } -Body $body
$r | Select-Object job_id, duration_ms, model
Invoke-RestMethod -Uri "http://100.91.113.98/jobs/$($r.job_id)" -Headers @{ "x-api-key" = $key }
```

## Phase 0B — system status

```powershell
$key = "YOUR_API_KEY"
Invoke-RestMethod -Uri "http://100.91.113.98/system/status" -Headers @{ "x-api-key" = $key }
```

Expect `workers.zak_pc`, `gpu.reachable`, `rag.qdrant_ready`.

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

## Phase 4 — Redis job notify

See [PHASE-4.md](PHASE-4.md). After deploy + GPU `REDIS_URL`:

```powershell
$key = "YOUR_API_KEY"
$h = @{ "x-api-key" = $key }
(Invoke-RestMethod http://100.91.113.98/system/status -Headers $h).job_notify
```

| Check | Expected |
|-------|----------|
| `job_notify.enabled` | `true` |
| POST `/jobs` (train) | `homelab:jobs:wake:train` depth increases |
| GPU worker log | `notify=true`; claims soon after job create |

## Phase 5 — Observability

See [PHASE-5.md](PHASE-5.md).

```powershell
curl.exe http://100.91.113.98/metrics | findstr homelab_jobs
curl.exe http://100.91.113.98:9090/-/healthy
```

| Check | Expected |
|-------|----------|
| `/metrics` | `homelab_jobs_pending`, `homelab_http_requests_total` |
| Prometheus targets | `homelab-api`, `qdrant`, `pushgateway` up |
| Grafana :3000 | Dashboard **Homelab ML Platform** has data |
| GPU push | `homelab_gpu_utilization_percent` after `push-gpu-metrics.ps1` |
