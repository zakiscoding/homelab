# Architecture

Three-node homelab split by role. GPU node first; iMac and API layer connected after.

```text
         [ Laptop — Windows, user cashh (controller) ]
              git / browser / SSH ───────────────────────┐
                                |                        |
                    +-----------+-----------+            |
                    |                       |            |
      [ Dual-boot GPU PC ]             [ iMac — momo ]   |
      Windows: zakar / zak_pc          homelab-services  │
        Ollama :11434 · homelab-gpu    homelab-web       │
      Ubuntu: zak-gpu-node             Caddy → web       │
        ~/projects (CUDA track)                          │
```

## Node roles

| Node | User / OS | Role | Primary workloads | Phase |
|------|-----------|------|-------------------|-------|
| **GPU PC (Windows boot)** | **`zakar`** (`zak_pc` / Tailscale `zakar`) | Inference + **training** | Ollama; `homelab-gpu` | **1 — inference done** |
| **GPU PC (Ubuntu boot)** | OS+Tailscale **`zak-gpu-node`** | Ubuntu CUDA / hybrid lab | PyTorch wheels under `~/projects` — [ubuntu-gpu](ubuntu-gpu/) | Phase 1 smoke **PASS**; Docker/Modal later |
| **iMac** | **`momo`** (`Mos-iMac`) | App / data plane | [`homelab-services`](https://github.com/zakiscoding/homelab-services) | **2 — done** (Colima) |
| **Laptop** | **`cashh`** | Controller | Docs, web dev, `ssh imac-ts` / `ssh zak-ts` | Ongoing |
| **Cursor VM** | Tailscale `cursor-cloud` | Cloud agent host | **No GPU** — not the dual-boot PC | — |

## Traffic flow

1. **Browser** → iMac **homelab-web** (`:3080` or Caddy `:80`) — chat, RAG, status.
2. **Web BFF** → iMac **FastAPI** (internal `:8000`, `x-api-key` server-side) → GPU **Ollama** `:11434`.
3. **Training** → GPU worker polls iMac; artifacts on `zak_pc` disk ([homelab-gpu](https://github.com/zakiscoding/homelab-gpu)).

**Paths (iMac 1TB):** `homelab/` · `homelab-services/` · `homelab-web/` (sibling clone)

**Git:** [REPOS.md](REPOS.md) — four repos: docs, services, gpu, web.

## Principles

- Get **GPU node** verified (`nvidia-smi`, Ollama, LAN `OLLAMA_HOST`) before wiring the iMac.
- Do not expose Ollama to the internet without auth; LAN-only or behind reverse proxy on iMac later.
- Record IPs and command output in [SETUP-LOG](SETUP-LOG.md) as each step completes.

## Runbooks

| Node | Doc |
|------|-----|
| GPU PC (Windows) | [nodes/gpu-node.md](nodes/gpu-node.md) |
| GPU PC (Ubuntu / hybrid) | [ubuntu-gpu/](ubuntu-gpu/) |
| iMac | [nodes/imac-node.md](nodes/imac-node.md) · [services/imac-stack.md](services/imac-stack.md) |
| Repos | [REPOS.md](REPOS.md) |
| Controller | [nodes/controller.md](nodes/controller.md) |
| Web UI | [services/web-ui.md](services/web-ui.md) |
