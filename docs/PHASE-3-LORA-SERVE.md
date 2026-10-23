# Phase 3b — Serve LoRA in Ollama

**Prerequisite:** [Phase 3](PHASE-3.md) train job `succeeded` with `checkpoints/{job_id}/adapter/`.

## Goal

Use your fine-tuned adapter in **Chat** (web UI or `POST /chat`) by publishing it as an Ollama model on `zak_pc`.

```text
train succeeded → merge adapter (fp16) → ollama create homelab-{version}
→ Chat model = homelab-smoke-lora-v1
```

## Important constraints

| Topic | Detail |
|-------|--------|
| **Base model match** | Ollama `FROM` must match the HF base you trained on ([configs/ollama_bases.yaml](https://github.com/zakiscoding/homelab-gpu/blob/main/configs/ollama_bases.yaml)) |
| **QLoRA** | 4-bit train weights are merged to fp16 before import (Ollama prefers non-quantized adapters) |
| **SmolLM smoke** | Default smoke uses `SmolLM2-360M` — no Ollama tag; publish merges then `FROM` merged directory |
| **Llama 3.2** | For chat-compatible LoRA, train with `base_model: meta-llama/Llama-3.2-3B-Instruct` and `ollama pull llama3.2:3b` first |
| **VRAM** | Merge needs GPU RAM — `stop-ollama.ps1` runs automatically during merge |
| **Ollama + train** | Do not train while Ollama is serving large models — same as Phase 3 |

## Publish (GPU PC)

```powershell
ssh zak-ts
cd C:\Users\zakar\homelab-gpu
git pull
.\.venv\Scripts\pip install pyyaml
# Replace with your succeeded job UUID:
.\scripts\publish-lora-to-ollama.ps1 -JobId "YOUR-JOB-UUID"
# Optional custom tag:
.\scripts\publish-lora-to-ollama.ps1 -JobId "YOUR-JOB-UUID" -OllamaName "homelab-smoke-lora-v1"
```

Verify:

```powershell
ollama list
curl.exe http://127.0.0.1:11434/api/tags
```

Artifacts added under the job dir:

```text
checkpoints/{job_id}/
├── merged/              # fp16 merged weights (after publish)
├── ollama_publish/Modelfile
└── published_ollama.json  # { "ollama_model": "homelab-..." }
```

## Sync adapter to iMac ML-STORE (optional)

Archive only — inference still runs on GPU Ollama:

```powershell
.\scripts\sync-adapter-to-imac.ps1 -JobId "YOUR-JOB-UUID" -ModelVersion "smoke-lora-v1"
```

## Chat with your LoRA

**Web UI:** open Chat → model dropdown lists Ollama tags; pick `homelab-*` (default prefers newest `homelab-` tag).

**API:**

```powershell
$key = "YOUR_API_KEY"
$h = @{ "x-api-key" = $key; "Content-Type" = "application/json" }
$body = @{ prompt = "Hello"; model = "homelab-smoke-lora-v1" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98:3080/api/homelab/chat" -Method Post -Headers $h -Body $body
```

**List models:**

```powershell
Invoke-RestMethod -Uri "http://100.91.113.98/models" -Headers @{ "x-api-key" = $key }
```

## Auto-publish after train (optional)

On GPU `.env`:

```env
AUTO_PUBLISH_OLLAMA=true
```

Worker runs publish after each successful QLoRA job (can take several minutes for merge + `ollama create`).

## Train for Llama 3.2 (recommended for Ollama chat)

```powershell
$body = @{
  dataset_version = "smoke"
  model_version   = "my-lora-v1"
  base_model      = "meta-llama/Llama-3.2-3B-Instruct"
} | ConvertTo-Json -Compress
# POST /jobs ...
```

Set `TRAIN_BASE_MODEL=meta-llama/Llama-3.2-3B-Instruct` on GPU for default. Requires HF access to Meta weights if gated.

## Deploy API + web (after pull)

```bash
ssh imac-ts
source ~/1tb-drive/homelab-services/scripts/docker-1tb-env.sh
cd ~/1tb-drive/homelab-services && git pull && docker compose up -d --build api web
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ollama create` fails | Check `published_ollama.json` / stderr; ensure base model matches training |
| Chat still generic | Model field must be exact `ollama list` name (e.g. `homelab-smoke-lora-v1:latest`) |
| Merge OOM | `stop-ollama.ps1`; use smaller base (1B) or fewer `TRAIN_MAX_STEPS` |
| No `homelab-*` in UI | Publish on GPU; redeploy API; `GET /models` |

## Next

- Larger dataset under `homelab-data/datasets/{version}/train.jsonl`
- [Phase 4](PHASE-4.md) Redis wake (already on)
- Scheduled backups [BACKUPS.md](BACKUPS.md)
