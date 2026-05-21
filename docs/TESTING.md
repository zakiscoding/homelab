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
$body = @{ message = "Hello" } | ConvertTo-Json -Compress
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

Log results in [SETUP-LOG.md](SETUP-LOG.md).
