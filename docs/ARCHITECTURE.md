# Architecture

Three-node homelab split by role. GPU node first; iMac and API layer connected after.

```text
         [ Laptop — Windows, user cashh (controller) ]
              git / curl.exe / SSH ─────────────────────┐
                                |                        |
                    +-----------+-----------+            |
                    |                       |            |
      [ GPU PC — Windows, user zakar ]   [ iMac — momo ] |
      zak_pc · Ollama · RTX 5070         homelab-services │
      inference + training (Phase 1)     (Phase 2)        │
```

## Node roles

| Node | Windows/macOS user | Role | Primary workloads | Phase |
|------|-------------------|------|-------------------|-------|
| **GPU PC** | **`zakar`** (`zak_pc`) | Inference + **training** | Ollama; future `homelab-gpu` for train code | **1 — inference done** |
| **iMac** | **`momo`** (`Mos-iMac`) | App / data plane | [`homelab-services`](https://github.com/zakiscoding/homelab-services) | 2 — in progress |
| **Laptop** | **`cashh`** | Controller | SSH to GPU, `git pull`/`push`, remote tests | Ongoing |

## Traffic flow (target)

1. **Controller** hits GPU node at `http://<GPU_IP>:11434` for model inference (Ollama API).
2. **Now:** clients hit **iMac** `homelab-services` (Caddy → FastAPI) → GPU Ollama; Postgres/Redis on iMac.

**Paths (iMac 1TB):** docs → `homelab/` · runtime → `homelab-services/`

**Git:** [REPOS.md](REPOS.md) — `homelab` (docs) + `homelab-services` (iMac stack) + planned `homelab-gpu` (training scripts).

## Principles

- Get **GPU node** verified (`nvidia-smi`, Ollama, LAN `OLLAMA_HOST`) before wiring the iMac.
- Do not expose Ollama to the internet without auth; LAN-only or behind reverse proxy on iMac later.
- Record IPs and command output in [SETUP-LOG](SETUP-LOG.md) as each step completes.

## Runbooks

| Node | Doc |
|------|-----|
| GPU PC | [nodes/gpu-node.md](nodes/gpu-node.md) |
| iMac | [nodes/imac-node.md](nodes/imac-node.md) · [services/imac-stack.md](services/imac-stack.md) |
| Repos | [REPOS.md](REPOS.md) |
| Controller | [nodes/controller.md](nodes/controller.md) |
