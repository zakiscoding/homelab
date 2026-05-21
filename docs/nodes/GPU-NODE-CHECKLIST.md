# GPU node checklist (`zak_pc`)

**Purpose:** AI inference and model training only.  
**Machine:** Windows desktop · user **`zakar`** · hostname **`zak_pc`**  
**Should NOT run here:** PostgreSQL, Redis, Grafana, Qdrant, or the main API server — the GPU spends resources on ML. Those run on the **iMac** ([homelab-services](https://github.com/zakiscoding/homelab-services)).

---

## Install

| Item | Status | Notes |
|------|--------|-------|
| NVIDIA drivers | ✅ Done | RTX 5070, driver 596.x — `nvidia-smi` |
| CUDA | ✅ Driver CUDA | CUDA **13.2** via driver; PyTorch uses bundled CUDA in wheel |
| Python | ✅ Done | 3.12 — `winget install Python.Python.3.12` |
| Virtual environments | ✅ Done | `C:\Users\zakar\homelab-gpu\.venv` |
| Jupyter | ✅ Done | JupyterLab — `.\scripts\start-jupyter.ps1` |
| Ollama | ✅ Done | `ollama serve`, `OLLAMA_HOST=0.0.0.0:11434`, task `OllamaServe` |
| Tailscale | ✅ Done | `100.88.71.33` — remote access from laptop / iMac |

---

## Run here — inference

Serve models:

```powershell
# Usually automatic via Ollama app / scheduled task
ollama serve
```

**Examples to pull and run (Ollama):**

| Family | Example tag |
|--------|-------------|
| Llama | `llama3.2`, `llama3.1` |
| Qwen | `qwen2.5` |
| DeepSeek | `deepseek-r1` (if available in library) |
| Mistral | `mistral`, `mixtral` |

```powershell
ollama pull llama3.2
ollama run llama3.2
```

**Test API:**

```powershell
curl.exe http://127.0.0.1:11434/api/tags
curl.exe http://100.88.71.33:11434/api/tags   # Tailscale
```

---

## Run here — training

| Workload | Status | Tooling |
|----------|--------|---------|
| LoRA | 🔲 Ready to run | PEFT / notebook |
| QLoRA | 🔲 Ready to run | bitsandbytes + PEFT (add to `requirements.txt`) |
| Fine-tuning | 🔲 First job pending | Jupyter `notebooks/` |
| Dataset processing | 🔲 Add pipelines | `datasets/` dir or notebooks |

**Before training:** free VRAM:

```powershell
cd C:\Users\zakar\homelab-gpu
.\scripts\stop-ollama.ps1
.\scripts\verify-gpu.ps1
```

---

## Folder layout

**Git repo** (`homelab-gpu` — scripts & notebooks only):

```text
C:\Users\zakar\homelab-gpu\
├── notebooks/          ✅ 01_gpu_and_paths.ipynb, add 02_lora_experiment.ipynb
├── scripts/            ✅ stop-ollama, setup-venv, verify-gpu, start-jupyter
├── training/           ✅ lora-quickstart/
├── configs/            ✅ paths.example.yaml
└── requirements.txt    ✅ torch, jupyter, peft, …
```

**Large files (not in git)** — on local disk:

```text
C:\Users\zakar\homelab-data\
├── datasets/           ← training JSONL / raw data
├── checkpoints/        ← LoRA adapters, training outputs
└── models/             ← optional: exported GGUF / merged weights (optional)
```

> Your checklist showed `datasets/` and `checkpoints/` inside `homelab-gpu/` — we keep them **outside** the repo so `git push` never accidentally includes terabytes. Same roles, paths above.

**Ollama models** (inference weights) live in Ollama’s own store (~`%USERPROFILE%\.ollama`), not in `homelab-gpu`.

---

## Store (local disk only)

| What | Where |
|------|--------|
| Datasets | `C:\Users\zakar\homelab-data\datasets` |
| Training outputs | `C:\Users\zakar\homelab-data\checkpoints` |
| Checkpoints | same |
| Model adapters | `checkpoints\<project>\` |
| Exported / merged models (optional) | `C:\Users\zakar\homelab-data\models` |

---

## Expose (LAN / Tailscale only)

| Port | Service | URL (Tailscale) |
|------|---------|-----------------|
| **11434** | Ollama | `http://100.88.71.33:11434` |
| **8888** | Jupyter (optional) | `http://100.88.71.33:8888` when `JUPYTER_LISTEN=0.0.0.0` |

**LAN IP:** `10.0.0.156` — same ports.

**Do not** port-forward these to the public internet without auth.

Firewall: Ollama **11434** (Private) rule added on Windows.

---

## Should NOT run on GPU node

| Service | Runs on instead |
|---------|-----------------|
| ❌ PostgreSQL | iMac `homelab-services` |
| ❌ Redis | iMac |
| ❌ Grafana | iMac |
| ❌ Qdrant | iMac |
| ❌ Main API server (FastAPI/Caddy) | iMac |

The GPU node only **answers** HTTP from the iMac API when Ollama is called — it does not host the app stack.

---

## Quick verification (all ✅ = install complete)

```powershell
nvidia-smi
python --version
cd C:\Users\zakar\homelab-gpu
.\scripts\verify-gpu.ps1
curl.exe http://127.0.0.1:11434/api/tags
```

---

## Related docs

- [gpu-node.md](gpu-node.md) — full runbook  
- [homelab-gpu README](https://github.com/zakiscoding/homelab-gpu)  
- [Shareable overview](../../share/HOMELAB-COMPLETE-OVERVIEW.md)
