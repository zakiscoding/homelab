# Architecture

Three-node homelab split by role. GPU node first; iMac and API layer connected after.

```text
         [ Laptop — Windows, user cashh (controller) ]
              git / curl.exe / SSH ─────────────────────┐
                                |                        |
                    +-----------+-----------+            |
                    |                       |            |
      [ GPU PC — Windows, user zakar ]   [ iMac — momo ] |
      zak_pc · Ollama · RTX 5070         API / compose   |
      (Phase 1 — done)                   (Phase 2)       │
```

## Node roles

| Node | Windows/macOS user | Role | Primary workloads | Phase |
|------|-------------------|------|-------------------|-------|
| **GPU PC** | **`zakar`** (`zak_pc`) | Inference | Ollama, NVIDIA driver | **1 — done** |
| **iMac** | **`momo`** (`Mos-iMac`) | App / data plane | API, database, `compose/` | 2 — in progress |
| **Laptop** | **`cashh`** | Controller | SSH to GPU, `git pull`/`push`, remote tests | Ongoing |

## Traffic flow (target)

1. **Controller** hits GPU node at `http://<GPU_IP>:11434` for model inference (Ollama API).
2. **Later:** clients or the iMac API call the GPU node or a gateway on the iMac for orchestration + persistence.

## Principles

- Get **GPU node** verified (`nvidia-smi`, Ollama, LAN `OLLAMA_HOST`) before wiring the iMac.
- Do not expose Ollama to the internet without auth; LAN-only or behind reverse proxy on iMac later.
- Record IPs and command output in [SETUP-LOG](SETUP-LOG.md) as each step completes.

## Runbooks

| Node | Doc |
|------|-----|
| GPU PC | [nodes/gpu-node.md](nodes/gpu-node.md) |
| iMac | [nodes/imac-node.md](nodes/imac-node.md) (placeholder) |
| Controller | [nodes/controller.md](nodes/controller.md) |
