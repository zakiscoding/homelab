# Homelab infrastructure inventory (live probe)

**As of:** 2026-10-23 (probe from Cursor coordinator VM)  
**Collector:** Cursor cloud VM — Tailscale name **`cursor-cloud`** @ `100.124.163.68` (not the real GPU box; formerly misnamed `zak-gpu-node`)

For the Ubuntu GPU host’s own capture (hardware, Phase 0A/1), prefer [infra-from-zak-gpu-node.md](infra-from-zak-gpu-node.md). This page is the Tailscale/reachability snapshot from the cloud VM.

---

## Critical: identity map

| Identity | What it actually is |
|----------|---------------------|
| Tailscale **`cursor-cloud`** `100.124.163.68` | **Cursor cloud VM** (Ubuntu 24.04, **no NVIDIA device**, no `nvidia-smi`). Renamed off `zak-gpu-node` — **not** the dual-boot PC. |
| Physical dual-boot PC (one RTX 5070) | **Same machine**, two OS boots: |
| → Ubuntu OS hostname **`zak-gpu-node`** | Ubuntu on external `/dev/sda`. Tailscale: **`zak-gpu-node`** @ `100.121.51.35`. Detail: [infra-from-zak-gpu-node.md](infra-from-zak-gpu-node.md). |
| → Windows **`zak_pc` / Tailscale `zakar`** `100.88.71.33` | Windows on internal NVMe + Ollama per [nodes/gpu-node.md](../nodes/gpu-node.md) — offline when Ubuntu is the active boot. |

Do **not** SSH/curl Tailscale `cursor-cloud` / `100.124.163.68` expecting CUDA — that is the Cursor VM. When Windows is booted, the GPU path is `zakar@100.88.71.33`. When Ubuntu is booted, use `zak-gpu-node` @ `100.121.51.35` (or local console).

---

## Tailscale peers (probe snapshot)

| Advertised name | IP | OS | Online (at probe) | Role |
|-----------------|----|----|-------------------|------|
| **cursor-cloud** | 100.124.163.68 | linux | yes | Cursor VM (no GPU) |
| **zak-gpu-node** | 100.121.51.35 | linux | yes (after join) | Dual-boot PC **Ubuntu** boot |
| **hp-laptop** | 100.73.132.95 | windows | yes | Controller laptop; docs user **`cashh`** |
| **mos-imac** | 100.91.113.98 | macOS | yes | App/DB plane; docs user **`momo`**, host `Mos-iMac` |
| **zakar** | 100.88.71.33 | windows | offline while Ubuntu booted | Dual-boot PC **Windows** boot (`zak_pc`); same hardware as Ubuntu `zak-gpu-node` |

---

## Reachability & services (live probe from Cursor VM)

### hp-laptop — online, no SSH inventory

- Ping OK.
- Open among probed: **135**, **445**, **7680**. No SSH (22), no RDP (3389) among probed ports.
- Docs expect git/docs at `C:\Users\cashh\homelab`.

### mos-imac — online, SSH keys required

- Ping OK. Open: **22** (SSH), **5000** (AirPlay — **not** MLflow), **5900** (VNC).
- SSH from the Cursor VM failed without deploy keys (`Permission denied (publickey)` for probed users).
- Homelab compose ports **not listening** over Tailscale at probe time: 80, 3000, 3080, 3081, 5001, 6333, 6379, 8000, 9090, 9091 → Colima/`homelab-services` stack appeared **stopped or not published**.

### zakar (Windows boot) — offline when Ubuntu is active

- Expected while Ubuntu is booted. Same physical PC as Ubuntu `zak-gpu-node` (RTX 5070).
- Windows software path: Ollama `:11434`, vision `:8100`, `C:\Users\zakar\homelab-gpu`, data under `C:\Users\zakar\homelab-data\`.

---

## What exists where

### Dual-boot GPU PC — Windows boot `zak_pc` / Tailscale `zakar` — `100.88.71.33`

Same hardware as Ubuntu OS-name `zak-gpu-node` below (one RTX 5070).

| Item | Detail |
|------|--------|
| Role | Inference (Ollama) + training (`homelab-gpu`) when Windows is booted |
| GPU | RTX 5070 12GB (shared hardware) |
| Disk | Windows on internal NVMe — **never modify from Ubuntu** |
| Key ports | Ollama `11434`, vision/reactions `8100`, optional Jupyter `8888` |
| Paths | `C:\Users\zakar\homelab-gpu`, `C:\Users\zakar\homelab-data\{checkpoints,datasets}` |
| LAN | Also documented as `10.0.0.156` |

### Dual-boot GPU PC — Ubuntu boot `zak-gpu-node` — `100.121.51.35`

| Item | Detail |
|------|--------|
| GPU | RTX 5070 12GB, driver **595.99.02**, CUDA driver **13.2** |
| Disk | Ubuntu on external `/dev/sda`; Windows NVMe — **verify unmounted** before work |
| Phase 1 | `~/projects/pytorch-cuda-smoke`, `torch==2.11.0+cu128` **PASS** |
| Not installed | Docker, full CUDA Toolkit, Modal |

### iMac — `Mos-iMac` / Tailscale `mos-imac` — `100.91.113.98`

| Item | Detail |
|------|--------|
| Role | API / DB / UI / observability (Colima + Docker Compose) |
| User | `momo` |
| Stack | `homelab-services`: api, postgres, redis, qdrant, web (`homelab-web`), caddy, grafana, prometheus, pushgateway, mlflow, imac-worker |
| Live at probe | Stack ports closed; only SSH/AirPlay/VNC seen |

### Laptop — Tailscale `hp-laptop` — `100.73.132.95`

| Item | Detail |
|------|--------|
| Role | Ops / docs / git; docs user **`cashh`** |
| Path | `C:\Users\cashh\homelab` |

### Cursor coordinator VM

| Item | Detail |
|------|--------|
| Tailscale | `cursor-cloud` @ `100.124.163.68` |
| GPU | **None** |
| Docker | CLI not installed on that VM at probe |

### Not found / not claimed

- Ansible / Kubernetes control plane on these nodes.
- Modal runtime on nodes (Modal is plan/cloud-side later; **not set up**).

---

## Secrets

Document **names/locations only** in [ACCESS.md](../ACCESS.md). Never commit passwords, API keys, or sudo credentials. This inventory stores **no secret values**.

---

## Blockers (at probe)

1. **SSH keys** on the Cursor VM may be missing → deep peer inventory limited.
2. **`zakar` offline** while Ubuntu is booted → cannot verify Windows Ollama/CUDA until that OS is up.
3. **iMac stack** may be stopped → cannot scrape `/system/status`, Grafana, etc. until Colima is up.
4. **Phase 0B** — remote SSH path to Ubuntu `zak-gpu-node` still needs operator verification before automation.

**Unblock options (need user):** deploy key for `momo@mos-imac` and/or Ubuntu GPU SSH; boot Windows when Windows-path verification is needed; start Colima on iMac. Any Tailscale ACL / SSH daemon change needs **[APPROVAL]**.
