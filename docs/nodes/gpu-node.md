# GPU node — AI inference & training (Windows)

| | |
|--|--|
| **Machine** | Desktop GPU PC (**dual-boot** — same hardware as Ubuntu `zak-gpu-node`) |
| **Hostname** | `zak_pc` |
| **Windows login** | **`zakar`** (`PS C:\Users\zakar>`) |
| **Tailscale (Windows boot)** | `zakar` @ `100.88.71.33` |
| **Controller laptop** | **`cashh`** — runs `curl` / `ssh zakar@...` from elsewhere |

**Ubuntu boot of this same PC** (external disk, OS+Tailscale `zak-gpu-node` @ `100.121.51.35`, PyTorch CUDA track): **[docs/ubuntu-gpu/](../ubuntu-gpu/)**. From Ubuntu, never modify the Windows NVMe; verify it is unmounted before work. Cursor Tailscale `cursor-cloud` @ `100.124.163.68` is a different machine (no GPU).

Physical GPU PC **Windows boot**. Two roles on that OS:

| Role | Stack | Versioned in |
|------|-------|--------------|
| **Inference** | NVIDIA driver + **Ollama** | This doc + [homelab SETUP-LOG](../SETUP-LOG.md) |
| **Training** | Python / PyTorch / fine-tune tooling | **[homelab-gpu](https://github.com/zakiscoding/homelab-gpu)** (scripts & configs only) |

Docker Desktop is optional for non-Ollama containers. **Checkpoints and datasets stay on GPU local disk** — not GitHub.

LAN API target: `http://<GPU_NODE_IP>:11434`

**Status:** Inference **complete**. Training **ready to start** — `homelab-gpu` cloned, Python + PyTorch, `C:\Users\zakar\homelab-data\`. Add dataset + `train.py` for first LoRA run.

| Path | Purpose |
|------|---------|
| `C:\Users\zakar\homelab-gpu` | Training repo (git) |
| `C:\Users\zakar\homelab-data\checkpoints` | Model outputs (not git) |
| `C:\Users\zakar\homelab-data\datasets` | JSONL / datasets (not git) |
| `homelab-gpu/notebooks/` | JupyterLab fine-tuning — `.\scripts\start-jupyter.ps1` |

See [REPOS.md](../REPOS.md) for how this node fits with [homelab-services](https://github.com/zakiscoding/homelab-services) on the iMac.

**Checklist (install / ports / what not to run):** [GPU-NODE-CHECKLIST.md](GPU-NODE-CHECKLIST.md)

---

## 0. Prerequisites (on the GPU node)

Run in **PowerShell on the GPU PC** (locally or over SSH from the laptop — both show `PS C:\...>`).

```powershell
hostname
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
nvidia-smi
ipconfig
```

| Check | Expected | If it fails |
|-------|----------|-------------|
| OS | Windows 10/11 | — |
| `nvidia-smi` | GPU name, driver (e.g. RTX 5070, no errors) | Install/update [NVIDIA Game Ready / Studio driver](https://www.nvidia.com/drivers) |
| `ipconfig` | IPv4 on LAN (e.g. `192.168.x.x`) | Record in [INVENTORY](../INVENTORY.md) |

**Recorded (2026-05-21):** `nvidia-smi` — NVIDIA GeForce RTX 5070, driver 596.36, CUDA 13.2. Ollama process present (`ollama.exe`).

Do **not** use Linux-only commands on this node (`cat /etc/os-release`, `apt`, `systemctl`).

---

## 1. Ollama (main inference runtime)

### Install (if missing)

Download from [https://ollama.com/download](https://ollama.com/download) (Windows installer), or:

```powershell
# winget, if available
winget install Ollama.Ollama
```

### Pull and test a model

```powershell
ollama run llama3.2
```

First pull can take a while. `Ctrl+C` exits the chat; the service keeps running.

### Local test

```powershell
curl.exe http://127.0.0.1:11434/api/tags
```

If that fails (`Could not connect`), Ollama is not running or not listening — see **Troubleshooting** below.

---

## 2. Listen on the LAN (`OLLAMA_HOST`)

By default Ollama may only bind to `127.0.0.1`. For the laptop / iMac to call it:

**System environment variable (persistent, recommended):**

1. **Settings → System → About → Advanced system settings → Environment Variables**
2. Under **System variables** → **New**
   - Name: `OLLAMA_HOST`
   - Value: `0.0.0.0:11434`
3. Restart Ollama (tray icon → Quit, then start again) or reboot.

Or one-liner (admin PowerShell):

```powershell
[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
```

Then restart the Ollama app / sign out and back in.

**Quick test (current session only):**

```powershell
$env:OLLAMA_HOST = "0.0.0.0:11434"
# restart Ollama from tray after setting Machine var; session var alone may not affect the service
```

---

## 3. Windows Firewall

Allow inbound **11434** from the local network (adjust profile as needed):

```powershell
New-NetFirewallRule -DisplayName "Ollama LAN" -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private
```

If the network is marked **Public**, use `-Profile Private,Public` deliberately (less secure) or set the adapter to Private in **Settings → Network**.

---

## 4. Verify from the controller laptop (`cashh`)

```powershell
curl.exe http://10.0.0.156:11434/api/tags
curl.exe http://100.88.71.33:11434/api/tags
```

JSON with models = homelab GPU node is reachable. IPs in [INVENTORY](../INVENTORY.md).

**Generate (PowerShell — avoid `curl -d` JSON escaping issues):**

```powershell
$body = @{ model = "llama3.2:latest"; prompt = "Say hello in one sentence."; stream = $false } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.88.71.33:11434/api/generate" -Method Post -Body $body -ContentType "application/json"
```

---

## 5. Remote admin (optional) — OpenSSH Server

Lets the laptop `ssh` into the GPU PC for PowerShell remotely.

**On the GPU node** (Admin PowerShell):

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

Firewall rule is usually added automatically. From laptop:

```powershell
ssh <windows-user>@<GPU_NODE_IP>
```

---

## 6. Docker Desktop (optional, later)

Only needed if you run **non-Ollama** GPU containers. Ollama on Windows does not require Docker.

Rough path when needed:

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Enable **WSL 2** backend and GPU support in Docker settings
3. Use Linux containers with `--gpus all` inside WSL2

Skip until you have a specific container workload.

---

## Verification checklist

- [x] `nvidia-smi` on GPU node (RTX 5070)
- [x] GPU node IPs in [INVENTORY](../INVENTORY.md) — `10.0.0.156`, `100.88.71.33`
- [x] `curl.exe http://127.0.0.1:11434/api/tags` on GPU node
- [x] `OLLAMA_HOST=0.0.0.0:11434` set (Machine) + `ollama serve`
- [x] Firewall rule for 11434
- [x] Remote curl via Tailscale (`100.88.71.33`) from controller (`cashh`)
- [x] Scheduled task **`OllamaServe`** (AtStartup)
- [x] `homelab-gpu` cloned; Python 3.12 + venv + PyTorch CUDA
- [x] `C:\Users\zakar\homelab-data\{checkpoints,datasets}`
- [ ] First LoRA training run
- [ ] OpenSSH (optional)

---

## RTX 5070 (12 GB VRAM)

| Workload | Rule |
|----------|------|
| Ollama inference | Small quantized models (e.g. `llama3.2:latest` ~2 GB) |
| Training | **QLoRA / 4-bit only** — not full fine-tune of large models |
| Ollama + train | **Do not run together** — `.\scripts\stop-ollama.ps1` before training |
| Concurrent trains | **Max 1** (job claim SQL on iMac) |

PyTorch: `cuda True`; may warn on sm_120 until newer wheel — see [SETUP-LOG](../SETUP-LOG.md).

## Phase 0A GPU worker

| Item | Value |
|------|-------|
| Repo path | `C:\Users\zakar\homelab-gpu` |
| Worker | `.\scripts\start-gpu-worker.ps1` (polls iMac API) |
| Artifacts | `homelab-data\checkpoints\{job_id}\` |
| Docs | [PHASE-0A.md](../PHASE-0A.md) |

SSH from laptop: `ssh zak-ts`.

## Ops notes

| Item | Value |
|------|-------|
| Ollama port | `11434` |
| API | `http://<GPU_IP>:11434/api/...` |
| OS | Windows — use PowerShell, not `apt` / `systemd` |

**Security:** Do not port-forward `11434` to the internet without authentication.

---

## Homelab persistent Ollama (recommended)

The iMac UI and API need Ollama on **`0.0.0.0:11434`** over Tailscale. Use the scheduled task in **homelab-gpu**:

| Script | When |
|--------|------|
| `scripts/install-ollama-serve-task.ps1` | **Once**, Admin PowerShell — creates `HomelabOllamaServe` + firewall |
| `scripts/serve-ollama.bat` | Wrapper: `OLLAMA_HOST=0.0.0.0:11434` + `ollama serve` |
| `scripts/start-ollama.ps1` | Quick start or `schtasks /Run /TN HomelabOllamaServe` |

```powershell
cd C:\Users\zakar\homelab-gpu
git pull
.\scripts\install-ollama-serve-task.ps1   # Admin, first time
# After reboot or if chat hangs:
schtasks /Run /TN HomelabOllamaServe
```

Verify from **laptop** (`cashh`):

```powershell
curl.exe http://100.88.71.33:11434/api/tags
```

Expect JSON including `llama3.2:latest`. If this fails, chat in the web UI stays on **Thinking…**.

---

## Remote-only setup (SSH — no monitor / no tray)

Use this when you only have PowerShell over SSH (e.g. OpenSSH), not the physical PC. Prefer **HomelabOllamaServe** above when possible.

### 1. Find Ollama and fix `netstat`

```powershell
where.exe ollama
# common path if where fails:
Test-Path "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
```

Check the port (note the space in `netstat -an`):

```powershell
netstat -an | findstr 11434
```

### 2. Restart the API (process up but port closed)

Your terminal showed **ollama running** with **no listener on 11434** — restart the server from CLI:

```powershell
Stop-Process -Name ollama* -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

$ollama = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
if (-not (Test-Path $ollama)) { $ollama = (Get-Command ollama -ErrorAction Stop).Source }

# LAN bind (current session + permanent)
$env:OLLAMA_HOST = "0.0.0.0:11434"
[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")

Start-Process -FilePath $ollama -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 8

netstat -an | findstr 11434
curl.exe http://127.0.0.1:11434/api/tags
```

Machine env may need **Administrator** PowerShell. If it fails, session `$env:OLLAMA_HOST` still applies to the `serve` process started in that command.

### 3. Test from your laptop (not on the GPU box)

Same LAN:

```powershell
curl.exe http://10.0.0.156:11434/api/tags
```

Over **Tailscale** (works even when you are not home):

```powershell
curl.exe http://100.88.71.33:11434/api/tags
```

### 4. Keep Ollama up after you disconnect SSH

`Start-Process` usually keeps running after SSH closes, but if it stops, create a scheduled task (run once on GPU node):

```powershell
$ollama = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
$action = New-ScheduledTaskAction -Execute $ollama -Argument "serve"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "OllamaServe" -Action $action -Trigger $trigger -RunLevel Highest -Force
Start-ScheduledTask -TaskName "OllamaServe"
```

Someone with admin rights on the PC may be required. Until then, `Start-Process ... serve` after each reboot is enough.

### 5. When you are back at the PC

Confirm the tray app is not fighting the CLI server (quit tray Ollama if you use `ollama serve` only).

---

## Troubleshooting

### `curl` to `127.0.0.1:11434` fails

```powershell
Get-Process ollama* -ErrorAction SilentlyContinue
netstat -an | findstr 11434
```

| What you see | Fix |
|--------------|-----|
| No `ollama` process | Start **Ollama** from Start menu; wait for tray icon |
| Process exists, no port 11434 | Quit Ollama (tray → Quit), start again; reboot if stuck |
| Port listening, curl still fails | Check URL; try `Invoke-RestMethod http://127.0.0.1:11434/api/tags` |

Restart from PowerShell (if `ollama` is on PATH):

```powershell
ollama serve
```

(Usually the GUI app manages the service — prefer tray restart.)

### Firewall rule exists but LAN curl fails

1. Fix **localhost** first (`127.0.0.1:11434`).
2. Then set `OLLAMA_HOST=0.0.0.0:11434` and restart Ollama.
3. Use the right IP: **10.0.0.156** on home Wi‑Fi, **100.88.71.33** over Tailscale.

### Documented IPs (this node)

| Interface | IPv4 | Use |
|-----------|------|-----|
| Wi‑Fi | `10.0.0.156` | Same LAN as laptop/iMac |
| Tailscale | `100.88.71.33` | Remote controller / iMac if on Tailscale |
