# Controller — Windows laptop (`cashh`)

| | |
|--|--|
| **Machine** | Laptop (not the GPU desktop) |
| **OS** | Windows |
| **Login** | **`cashh`** |
| **Repo (git clone)** | `C:\Users\cashh\homelab` |
| **Role** | Docs, `git pull`/`push`, `curl` tests, SSH into GPU PC |

Do not confuse with the **GPU PC** — that machine logs in as **`zakar`** (`zak_pc`). See [gpu-node.md](gpu-node.md).

## Homelab nodes

| Node | User / host | SSH alias (laptop `~/.ssh/config`) |
|------|-------------|--------------------------------------|
| **GPU PC** | **`zakar`** @ `zak_pc` | `ssh zak-ts` → `100.88.71.33` |
| **iMac** | **`momo`** @ `Mos-iMac` | `ssh imac-ts` |
| **This laptop** | **`cashh`** | Local PowerShell + `C:\Users\cashh\homelab` |

Legacy: `ssh zakar@10.0.0.156` on LAN. Phase 0A deploy: [PHASE-0A.md](../PHASE-0A.md).

## Git (GitHub first)

```powershell
cd C:\Users\cashh\homelab
git pull
# edit docs...
git add -A
git commit -m "Describe change"
git push
```

See [GIT.md](../GIT.md). GitHub: **zakiscoding/homelab** (private).

## Test GPU Ollama from this laptop

Use the **GPU node IP** — not `127.0.0.1` (that would be laptop-local only).

```powershell
# Tailscale (works away from home)
curl.exe http://100.88.71.33:11434/api/tags

# Home LAN
curl.exe http://10.0.0.156:11434/api/tags
```

**Generate (PowerShell):**

```powershell
$body = @{ model = "llama3.2:latest"; prompt = "Say hello in one sentence."; stream = $false } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.88.71.33:11434/api/generate" -Method Post -Body $body -ContentType "application/json"
```

## SSH to GPU PC (`zakar`)

```powershell
ssh zakar@10.0.0.156
# or over Tailscale:
ssh zakar@100.88.71.33
```

Prompt will be `PS C:\Users\zakar>` on the **GPU** machine.

## Remote-only on GPU

If you are SSH’d into **`zakar`**@`zak_pc`, you are on the GPU node — not the controller. GPU fixes: [gpu-node.md § Remote-only](gpu-node.md#remote-only-setup-ssh--no-monitor--no-tray).

## Cursor on the GPU PC?

If you open this repo under `C:\Users\zakar\HOMELAB` on **`zak_pc`**, that is still the same GitHub repo — just the GPU workstation copy. Prefer **`cashh`** laptop for day-to-day `git push` if that is your main controller.
