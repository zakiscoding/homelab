# Controller — Windows laptop

**OS:** Windows  
**Repo:** Sync from iMac — **`/Volumes/1tb drive/homelab`** (canonical).  
On Windows, copy that folder via USB/network share, or use git once initialized.  
**Role:** Docs, remote tests, SSH to GPU PC and iMac.

## Homelab nodes

| Node | OS | How you manage it |
|------|-----|-------------------|
| **GPU PC** | **Windows** | PowerShell on box, or `ssh` if OpenSSH Server enabled |
| **iMac** | TBD (macOS likely) | SSH / Screen Sharing later |
| **This laptop** | Windows | Local PowerShell + this repo |

The GPU node is **not Linux**. Over SSH you still get **PowerShell** (`PS C:\...>`), not `user@host:~$`.

## Commands on the GPU node (Windows)

Run on the GPU PC (local or SSH):

```powershell
nvidia-smi
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
ipconfig
curl.exe http://127.0.0.1:11434/api/tags
```

Do **not** expect `cat /etc/os-release` or `apt` to work on the GPU node.

## Test GPU node Ollama from this laptop

```powershell
curl.exe http://<GPU_NODE_IP>:11434/api/tags
```

`127.0.0.1` on the laptop only hits **local** Ollama on the laptop — use the GPU PC’s LAN IP for the homelab node.

## Remote-only workflow

You may only have the **GPU node SSH terminal** (not at the desk, not on the laptop). Run all fix/start commands **in that SSH session** — see [gpu-node.md § Remote-only](gpu-node.md#remote-only-setup-ssh--no-monitor--no-tray).

From the laptop (optional), test over Tailscale if you are away from home:

```powershell
curl.exe http://100.88.71.33:11434/api/tags
```

## SSH to Windows GPU node (optional)

```powershell
ssh <windows-user>@<gpu-node-ip>
```

Then run PowerShell commands as above. See [gpu-node.md](gpu-node.md) § OpenSSH.

## Same GPU on two machines?

If both the laptop and GPU PC have an RTX 5070, they are separate boxes — always use **IP address** to tell them apart in tests and docs.
