# Architecture

Three-node homelab split by role. GPU node first; iMac and API layer connected after.

```text
                    [ Laptop — Windows controller ]
                           SSH / curl.exe / docs (no apt/nvidia setup here)
                                |
                    +-----------+-----------+
                    |                       |
            [ GPU PC — Windows ]      [ iMac node ]
            AI inference              API, database,
            Ollama (+ GPU drivers)    supporting services
            (Phase 1 — now)           (Phase 2 — later)
```

## Node roles

| Node | Role | Primary workloads | Phase |
|------|------|-------------------|-------|
| **GPU PC** | Inference | **Windows**, Ollama, NVIDIA driver; Docker optional | **1 — in progress** |
| **iMac** | App / data plane | HTTP API, database, related services | 2 — planned |
| **Laptop** | Controller | SSH, testing (`curl` to Ollama), docs in this repo | Ongoing |

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
