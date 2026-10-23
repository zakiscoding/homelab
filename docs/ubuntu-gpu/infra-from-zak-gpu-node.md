# Infra inventory — physical Ubuntu boot `zak-gpu-node`

**Source:** self-hosted worker on the user’s Ubuntu GPU machine.  
**Captured / updated:** 2026-10-23.

This is the **Ubuntu boot** of the dual-boot RTX 5070 PC. **Same physical machine** as Windows `zak_pc` / Tailscale `zakar` (different OS/software only). It is **not** the Cursor cloud VM (`cursor-cloud` @ `100.124.163.68`, no GPU) — see Phase 0 in the [phased plan](phased-infrastructure-plan.md).

---

## Host facts

| Item | Value |
|------|--------|
| OS hostname | `zak-gpu-node` (Ubuntu boot) |
| Same PC as | Windows `zak_pc` / Tailscale `zakar` (dual-boot) |
| OS | Ubuntu 24.04.5 LTS (Noble), kernel `7.0.0-38-generic` |
| CPU | Intel Core i7-14700F (28 threads reported) |
| RAM | 31 GiB |
| GPU | NVIDIA GeForce RTX 5070, **12227 MiB** VRAM |
| Driver | `595.99.02` (driver reports CUDA **13.2**) |
| Ubuntu root | `/dev/sda2` ~686G usable (`/` on ~750GB external disk) |
| Windows disk | `/dev/nvme0n1` ~1.8T NTFS (`Windows` / `SYSTEM`) — **verify unmounted** each session; never write (Windows boot of this same PC) |
| Ubuntu Tailscale | `zak-gpu-node` @ `100.121.51.35` |

GPU process list at initial capture: display stack only (Xorg, GNOME, Firefox, Cursor) — no training/inference jobs.

---

## Workspace inventory

### `~/homelab`

- Exists; at capture contained **only** an empty git repo (`.git`, branch `master`, **no commits**, **no remotes**, no tracked files).
- No README, compose, Dockerfiles, k8s, ansible, Modal, CUDA, or PyTorch files in that empty tree.
- Canonical docs for this track live in **this repo** under [`docs/ubuntu-gpu/`](README.md).

### `~/projects`

| Path | Status |
|------|--------|
| `~/projects/pytorch-cuda-smoke` | **Present on the GPU box only** — Phase 1 smoke **PASS** (`torch==2.11.0+cu128`). Not mirrored as a separate public GitHub repo. See [pytorch-cuda-smoke.md](pytorch-cuda-smoke.md). |

### Tools (system)

| Tool | Status |
|------|--------|
| `docker` | **Not installed** |
| Full CUDA Toolkit (`nvcc`) | **Not installed** (by design) |
| Modal CLI | **Not installed** — Modal not set up |
| PyTorch | In project venv only (`~/projects/pytorch-cuda-smoke`), not system-wide |
| Tailscale | **Joined** as `zak-gpu-node` @ `100.121.51.35` |

---

## Phase 0A safety check (2026-10-23)

| Check | Result |
|-------|--------|
| Hostname | `zak-gpu-node` |
| Ubuntu root | `/dev/sda2` ext4 `/` |
| Windows NVMe | `/dev/nvme0n1` present; **verified unmounted** (no ntfs/Windows mounts) |
| `nvidia-smi` | RTX 5070, driver 595.99.02, ~12GB VRAM, healthy |

---

## Phase 1 local PyTorch (2026-10-23)

| Item | Value |
|------|--------|
| Project | `~/projects/pytorch-cuda-smoke` (on `/dev/sda2`) |
| Wheel | `torch==2.11.0+cu128`, `torchvision==0.26.0+cu128` (PyTorch ships CUDA 12.8 runtime) |
| Smoke | `scripts/smoke_cuda.py` → **PASS** (matmul FP32/FP16 + tiny train step; `sm_120` in arch list) |
| Toolkit | Full CUDA Toolkit **not** installed (`nvcc` absent) |
| Docker / Modal / NCCL | Not touched |

---

## Gaps vs hybrid lab goals

Aligned with [phased-infrastructure-plan.md](phased-infrastructure-plan.md):

| Goal | Status on this host |
|------|---------------------|
| Local CUDA / driver | **Driver OK** + **Phase 1 PyTorch smoke PASS** (`torch 2.11.0+cu128`, `sm_120`). No system CUDA Toolkit/`nvcc` (by design). |
| `~/projects` workspace | **Present** — `~/projects/pytorch-cuda-smoke` |
| Docker + NVIDIA Container Toolkit | **Not installed** → Phase 2 after local smoke; needs **[APPROVAL]** |
| Modal parity | **No Modal** on this host; wait for explicit ask |
| DDP / multi-GPU | Local is **single GPU 12GB**; DDP remains Modal-first (Phase 5) — not started |
| Homelab docs | This folder in `zakiscoding/homelab`; empty local `~/homelab` tree unchanged |
| Tailscale identity | **Joined** as `zak-gpu-node` @ `100.121.51.35` (distinct from Cursor VM `cursor-cloud` @ `100.124.163.68`). Phase **0B** remote-path docs deferred. |

---

## Blockers / needs approval (not done)

1. **Phase 2 Docker / NVIDIA CTK** — **[APPROVAL]** required; only after local smoke (now green).
2. **Modal** — wait for explicit user ask.
3. **Phase 0B** — document SSH/remote path when needed; Tailscale already joined.
4. **Windows NVMe** — **verify unmounted before each work session** (has auto-mounted once); never write/modify.

---

## Tailscale (Ubuntu boot)

| Item | Value |
|------|--------|
| Status | Joined / running (auth complete) |
| Hostname | `zak-gpu-node` |
| IPv4 | `100.121.51.35` |
| MagicDNS | `zak-gpu-node.tail31c8eb.ts.net` |
| Collision check | **OK** — peer `cursor-cloud` is separately listed @ `100.124.163.68` (not this node) |
| Other peers (at check) | `hp-laptop`, `mos-imac` online; Windows `zakar` @ `100.88.71.33` offline (expected while Ubuntu is booted) |

---

## Operator note

**Verify** Windows NVMe unmounted each session. Docker, system CUDA Toolkit, upgrades, MPI/NCCL, and Modal not touched. Prefer PyTorch CUDA wheels; no full Toolkit by default.
