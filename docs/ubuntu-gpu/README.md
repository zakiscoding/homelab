# Ubuntu GPU track (hybrid AI lab)

Docs for the **Ubuntu boot** of the dual-boot RTX 5070 PC, plus the phased hybrid plan (local PyTorch → Docker later → Modal later).

This track is **separate** from the existing Windows GPU runbooks under [`docs/nodes/gpu-node.md`](../nodes/gpu-node.md) and the job-control **Phase 0A/0B** docs at the repo root (`docs/PHASE-0A.md`, `docs/PHASE-0B.md`). Those cover the Windows/`homelab-services` control plane. **Here**, Phase 0A/0B means local safety vs Tailscale identity for Ubuntu CUDA work.

## Critical identity map

| Identity | What it is |
|----------|------------|
| Ubuntu OS hostname **`zak-gpu-node`** | Ubuntu boot of the dual-boot PC (external `/dev/sda`) |
| Windows **`zak_pc`** / Tailscale **`zakar`** `100.88.71.33` | **Same physical PC**, Windows boot (internal NVMe) — Ollama / `homelab-gpu` path |
| Tailscale **`cursor-cloud`** `100.124.163.68` | Cursor cloud VM — **no GPU**; not the dual-boot PC |
| Ubuntu Tailscale **`zak-gpu-node`** `100.121.51.35` | Ubuntu boot on the tailnet |

**One RTX 5070.** Never modify the Windows NVMe from Ubuntu. Before work: **verify** Windows partitions are **unmounted** (they have auto-mounted before).

## Documents in this folder

| Doc | Purpose |
|-----|---------|
| [phased-infrastructure-plan.md](phased-infrastructure-plan.md) | Living hybrid plan: 0A/0B → PyTorch → Docker → Modal → DDP |
| [infra-from-zak-gpu-node.md](infra-from-zak-gpu-node.md) | Host inventory from the Ubuntu boot |
| [infra-inventory.md](infra-inventory.md) | Live Tailscale / reachability probe (coordinator VM) |
| [github-infra-inventory.md](github-infra-inventory.md) | What the four `homelab*` repos already document vs gaps |
| [pytorch-cuda-smoke.md](pytorch-cuda-smoke.md) | Phase 1 smoke: host path + minimal mirror notes |

## Status (2026-10-23)

| Item | Status |
|------|--------|
| Phase **0A** (local safety) | **Complete** |
| Phase **1** (`torch==2.11.0+cu128` smoke) | **PASS** on host `~/projects/pytorch-cuda-smoke` |
| Phase **0B** (remote SSH path docs) | Deferred — Tailscale joined; SSH target not fully operator-verified |
| Docker / NVIDIA Container Toolkit | **Not installed** — needs approval after Phase 1 |
| Modal | **Not set up** — do not install until explicitly asked |
| Full CUDA Toolkit (`nvcc`) | **Not installed** (by design; use PyTorch wheels) |

## Related Windows / iMac docs

- [GPU node (Windows)](../nodes/gpu-node.md) · [INVENTORY](../INVENTORY.md) · [NETWORK](../NETWORK.md) · [ARCHITECTURE](../ARCHITECTURE.md)
