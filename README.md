<div align="center">

# homelab

**A self-hosted AI platform across three home machines plus cloud GPUs, joined by Tailscale. This repo is its documentation hub.**

[![CI](https://github.com/zakiscoding/homelab/actions/workflows/ci.yml/badge.svg)](https://github.com/zakiscoding/homelab/actions/workflows/ci.yml) ![nodes](https://img.shields.io/badge/nodes-3%20%2B%20cloud-2f81f7?style=flat-square) ![GPU](https://img.shields.io/badge/GPU-RTX%205070%2012%20GB-76b900?style=flat-square&logo=nvidia&logoColor=white) ![burst](https://img.shields.io/badge/burst-Modal%20H100-7c3aed?style=flat-square) ![network](https://img.shields.io/badge/network-Tailscale-242424?style=flat-square&logo=tailscale&logoColor=white) ![repos](https://img.shields.io/badge/repos-7%20public-2da44e?style=flat-square&logo=github&logoColor=white)

**homelab (docs hub)** · [homelab-services](https://github.com/zakiscoding/homelab-services) · [homelab-web](https://github.com/zakiscoding/homelab-web) · [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) · [gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab) · [gophergrid](https://github.com/zakiscoding/gophergrid) · [low-latency-trading-engine](https://github.com/zakiscoding/low-latency-trading-engine)

</div>

---

## What's inside

- **Architecture** with diagrams of the whole platform: topology, chat path, job lifecycle, job routing, monitoring — [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Node runbooks** for the iMac, the dual-boot GPU PC (Windows and Ubuntu) and the controller laptop
- **Service docs**: web UI, iMac stack, RAG, vision/reactions, observability, MLflow
- **Phase docs** (0A to 6) describing how each capability was built and tested
- **[Setup log](docs/SETUP-LOG.md)**: dated record of every change
- **Public edge on Cloudflare**: an OpenAI-compatible API for the home GPU with per-client keys, a strict rate limit and a hosted fallback, reached through a tunnel with no open ports, plus a public [results page](https://gpu-systems-lab-results.vllm-gateway.workers.dev), read-only [homelab dashboards](https://grafana-proxy.vllm-gateway.workers.dev) and a [paper-trading site](https://paper-trading.vllm-gateway.workers.dev) — [docs/deploy/public-internet.md](docs/deploy/public-internet.md)
- **[What's hosted where](#whats-hosted-where)**: every service, the machine it runs on, and how it's reached
- No code and no secrets. Code lives in the other repos; credentials stay in `.env` files on each machine.

## Architecture

```mermaid
flowchart LR
  subgraph TAILNET["Tailscale tailnet"]
    LAPTOP["Laptop, controller only<br/>browser, git, SSH, deploys<br/>hosts no services"]
    subgraph IMAC["iMac, control plane · 100.91.113.98"]
      WEB["Web UI :3081<br/>Caddy :80"]
      API["FastAPI :8000"]
      DATA[("Postgres jobs · Redis<br/>Qdrant :6333")]
      MON["Prometheus · Grafana<br/>Alertmanager · Tempo · MLflow"]
      GGI["GopherGrid leader<br/>Postgres · etcd"]
      LLE["Trading engine (native)<br/>QuestDB tick store"]
    end
    subgraph GPUPC["GPU PC, RTX 5070 · one OS at a time"]
      WIN["Windows · 100.88.71.33 · WSL2<br/>vLLM :8000, DCGM, Prometheus, Grafana<br/>GopherGrid scheduler-2 + workers<br/>Ray head, cloudflared"]
      UBU["Ubuntu · 100.121.51.35<br/>vLLM, k3s (offline while on Windows)"]
    end
  end
  MODAL["Modal cloud<br/>H100 burst"]
  CF["Cloudflare Workers<br/>LLM gateway · results site<br/>dashboards · paper trading"]
  CLIENT["Public users<br/>and API clients"]

  LAPTOP -->|"HTTP"| WEB
  WEB --> API
  API --> DATA
  API -->|"chat, primary"| UBU
  API -.->|"chat, fallback"| WIN
  GGI -->|"gRPC jobs"| WIN
  LAPTOP -->|"SSH"| WIN
  LAPTOP -->|"modal run"| MODAL
  MON -.->|"scrape"| API
  MON -.->|"scrape, federate"| WIN
  CLIENT --> CF
  CF -->|"tunnel: gateway"| WIN
  CF -->|"tunnel: trading data"| LLE
  CF -->|"tunnel: read-only dashboards"| MON
```

Full diagrams and explanations: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**.

## What's hosted where

Checked on 2026-11-14. The laptop is the controller only: it builds, tests and deploys, and runs no services.

### Public (Cloudflare Workers)

| URL | What it is | Backend |
|-----|------------|---------|
| [vllm-gateway.vllm-gateway.workers.dev](https://vllm-gateway.vllm-gateway.workers.dev/health) | OpenAI-compatible LLM API: per-client keys, 60 requests/min per client, Workers AI fallback | vLLM on the GPU PC, through a tunnel |
| [gpu-systems-lab-results.vllm-gateway.workers.dev](https://gpu-systems-lab-results.vllm-gateway.workers.dev) | Benchmark results and charts | Static |
| [grafana-proxy.vllm-gateway.workers.dev](https://grafana-proxy.vllm-gateway.workers.dev) | Read-only homelab dashboards | iMac Grafana, through a tunnel |
| [paper-trading.vllm-gateway.workers.dev](https://paper-trading.vllm-gateway.workers.dev) | Live market view (no login), paper trading after GitHub/Google sign-in, admin behind Cloudflare Access. Paper only, no real orders | Trading engine on the iMac, through a tunnel |

### iMac (`mos-imac`, 100.91.113.98)

| Group | Services |
|-------|----------|
| Homelab core (Colima) | `web`, `caddy`, `api`, `imac-worker`, `postgres`, `redis`, `qdrant`, `mlflow` |
| Monitoring (Colima) | `prometheus`, `grafana`, `alertmanager`, `blackbox`, `pushgateway`, `otel-collector`, `tempo` |
| GopherGrid (Colima) | `scheduler-1` (leader), `postgres`, `etcd` |
| Trading engine | `crypto_engine`, `paper_exchange`, `recorder`, `telemetry` run natively under launchd; `questdb` tick store in Colima |
| Ray | Worker node |
| Edge | `homelab-cloudflared` tunnel for the public dashboards and the trading site |

### GPU PC (`zakar`, Windows boot, 100.88.71.33)

| Group | Services (Docker in WSL2 Ubuntu) |
|-------|----------------------------------|
| AI serving | `vllm-chat`: Qwen2.5-1.5B, the backend for the gateway and the web UI |
| Monitoring | `obs-prometheus`, `obs-grafana`, `obs-dcgm-exporter`, `obs-node-exporter` |
| GopherGrid | `scheduler-2` (follower), `gpu-worker` (RTX 5070), `cpu-worker` |
| Ray | `ray-head` with its dashboard on `:8265` |
| Edge | `cloudflared` tunnel for the LLM gateway |

Windows Tailscale publishes vLLM `:8000`, Grafana `:3000`, Prometheus `:9090` and the GopherGrid ports to the tailnet only (`tailscale serve`).

### Not running

| What | Why |
|------|-----|
| GPU PC Ubuntu boot (`zak-gpu-node`): vLLM, k3s, DCGM | The PC is booted into Windows |
| Ollama on the GPU PC | Replaced by vLLM in WSL2 as the chat backend |
| Slurm controller | Being moved off the laptop |

## Start here

1. **[Architecture](docs/ARCHITECTURE.md)**: the five diagrams, node and port table, design principles.
2. **[Repositories](docs/REPOS.md)**: which repo runs where and how they are cloned.
3. **[Services](docs/SERVICES.md)**: every running service, URL and config path.
4. **The node you are working on**: [iMac](docs/nodes/imac-node.md) · [GPU PC, Windows](docs/nodes/gpu-node.md) · [GPU PC, Ubuntu](docs/nodes/gpu-node-ubuntu.md) · [Laptop](docs/nodes/controller.md)
5. **[Setup log](docs/SETUP-LOG.md)**: skim the latest entries before changing anything.

Sharing with someone outside the project? Send the standalone **[share/HOMELAB-COMPLETE-OVERVIEW.md](share/HOMELAB-COMPLETE-OVERVIEW.md)**.

## Repo map

| Repo | Role | Runs on |
|------|------|---------|
| **homelab** (this repo) | Docs hub: architecture, nodes, services, setup log, runbooks | Read everywhere |
| [homelab-services](https://github.com/zakiscoding/homelab-services) | iMac stack: FastAPI, Postgres job queue, Redis, Qdrant RAG, Caddy, Prometheus/Grafana, MLflow, iMac worker | iMac (Colima) |
| [homelab-web](https://github.com/zakiscoding/homelab-web) | Next.js 16 / React 19 / Tailwind 4 UI: chat, RAG, reactions, status; BFF keeps the API key server-side | iMac `:3081` (prod), laptop (dev) |
| [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) | Windows GPU PC: Ollama, QLoRA training, GPU job worker, reaction CNN `:8100`, metrics push | GPU PC on Windows |
| [gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab) | Ubuntu GPU node + Modal: CUDA kernels, MPI/NCCL, FSDP, vLLM, k3s, DCGM observability, job router, Cloudflare gateway | GPU PC (Ubuntu, or WSL2 on Windows), Modal, Cloudflare |
| [gophergrid](https://github.com/zakiscoding/gophergrid) | Distributed compute scheduler in Go: gRPC heartbeats, leases, etcd leader election, GPU-aware placement, exactly-once results | iMac (Postgres, etcd, scheduler-1), GPU PC (scheduler-2, a CPU worker and the RTX 5070 worker) — [homelab deployment](https://github.com/zakiscoding/gophergrid/blob/main/docs/homelab.md) |
| [low-latency-trading-engine](https://github.com/zakiscoding/low-latency-trading-engine) | Low-latency C++20 trading engine on live market data: feed handler, order book, matching engine, paper exchange, tick store, public web UI. Paper trading only | iMac (live stack, QuestDB), Cloudflare (site); clean latency runs planned on the GPU PC's Ubuntu boot |

All seven repos are public, with secret scanning, push protection and Dependabot alerts on. Details: [docs/REPOS.md](docs/REPOS.md).

## Machines

| Node | Hostname | Tailscale IP | OS | User | Runbook |
|------|----------|--------------|----|------|---------|
| Laptop (controller only, hosts nothing) | `hp-laptop` | 100.73.132.95 | Windows | `cashh` | [controller.md](docs/nodes/controller.md) |
| iMac (control plane) | `Mos-iMac` | 100.91.113.98 | macOS 15.7, Apple M1 | `momo` | [imac-node.md](docs/nodes/imac-node.md) |
| GPU PC, Windows boot | `zak_pc` | 100.88.71.33 | Windows | `zakar` | [gpu-node.md](docs/nodes/gpu-node.md) |
| GPU PC, Ubuntu boot | `zak-gpu-node` | 100.121.51.35 | Ubuntu 24.04 (external HDD) | `zak` | [gpu-node-ubuntu.md](docs/nodes/gpu-node-ubuntu.md) |
| Cloud | Modal `zakiscoding` | — | gVisor containers | — | [gpu-node-ubuntu.md](docs/nodes/gpu-node-ubuntu.md#cloud-burst-modal) |

The GPU PC (RTX 5070 12 GB, i7-14700F) runs **Windows or Ubuntu, never both**. `cashh` is the
laptop; `zakar` is the GPU PC on Windows.

## Status

| Area | Status | Notes |
|------|--------|-------|
| iMac stack (Colima) | **Running** | API, Postgres, Redis, Qdrant, Caddy, MLflow on `100.91.113.98` |
| Web UI (homelab-web) | **Running** | Chat, RAG, reactions, status at `:3081` (and `:80` via Caddy). Restored 2026-11-14 after a Colima networking fix ([the 10-connect limit](https://github.com/zakiscoding/homelab-services/pull/4)) |
| Chat backend | **Running** | `LLM_BACKEND=auto`: vLLM on the Ubuntu boot, Ollama on the Windows boot |
| GPU PC, Windows: Ollama | **Off** | Replaced by vLLM in WSL2 as the Windows-boot chat backend |
| GPU PC, Ubuntu boot | **Done** | `zak-gpu-node`, CUDA 13.2, Docker, Open MPI — [gpu-node-ubuntu.md](docs/nodes/gpu-node-ubuntu.md) |
| vLLM serving | **Running** | Always-on, tailnet `:8000/v1`, API key; Qwen2.5-1.5B 4.4k tok/s on RTX 5070 |
| Job queue | **Done** | Postgres SSOT, leases with renew, retry backoff, Redis wake |
| Router worker | **Done** | Routed jobs → local RTX 5070 or Modal; decision stored in `experiments` |
| Cloud GPU burst (Modal) | **Done** | H100 / 2x H100 / L4; **$10** usage limit |
| k3s GPU scheduling | **Running** | Single node, NVIDIA device plugin, GPU admission policy |
| Monitoring | **Running** | iMac Prometheus `:9090` + Grafana `:3000`; GPU node DCGM dashboard as a second datasource |
| Cloudflare LLM gateway | **Running** | Public OpenAI-compatible API on Workers: per-client keys, 60 requests/min per client (Durable Object), Workers AI fallback when the GPU is unreachable. Reaches vLLM through a tunnel with no open ports — [details](https://github.com/zakiscoding/gpu-systems-lab/blob/main/docs/CLOUDFLARE.md) |
| GPU PC, Windows: WSL2 | **Running** | vLLM, Prometheus, Grafana, DCGM and `cloudflared` in Ubuntu on WSL2, kept up by the `WSL Keep Alive` task. Ports bind to localhost and Windows Tailscale publishes them to the tailnet, so the iMac can reach this vLLM. The iMac's Prometheus scrapes it |
| Results site | **Live** | [gpu-systems-lab-results.vllm-gateway.workers.dev](https://gpu-systems-lab-results.vllm-gateway.workers.dev): benchmark results and charts, built from gpu-systems-lab. Latest: FP16 vs AWQ vs FP8 vLLM serving on the RTX 5070, run as GopherGrid jobs: FP8 works on Blackwell and gives 1.36–1.45x FP16 throughput; 4-bit AWQ halves single-request token latency; speculative decoding (n-gram or a 0.5B draft) made the 1.5B model slower |
| Public dashboards | **Live** | [grafana-proxy.vllm-gateway.workers.dev](https://grafana-proxy.vllm-gateway.workers.dev): read-only homelab dashboards |
| Paper-trading site | **Live** | [paper-trading.vllm-gateway.workers.dev](https://paper-trading.vllm-gateway.workers.dev): live data from the trading engine on the iMac; paper only. The native stack starts at iMac login, so a reboot needs a login to bring it back |
| Ray | **Running** | Head on the GPU PC (WSL2), worker on the iMac |
| Slurm | **Paused** | Controller is being moved off the laptop |
| R2 results storage | **Waiting** | Upload script ready; R2 isn't enabled on the account |
| Ubuntu node hardening | **Done** | LAN blocked for 22/6443/10250 (verified); reboot pending for Nsight counters |
| Postgres migrations | **Done** | 004–007 applied 2026-10-23 (`scripts/migrate-all.sh`) |
| GPU training env (Windows) | **Done** | `homelab-gpu` cloned, Python, PyTorch, data dirs |
| QLoRA training | **Done** | Smoke train via the GPU worker (Phase 3) |
| LoRA → Ollama | **Ready** | `publish-lora-to-ollama.ps1` — [PHASE-3-LORA-SERVE.md](docs/PHASE-3-LORA-SERVE.md) |
| Tailscale end-to-end tests | **Done** | GPU + iMac health; web UI chat/RAG from the laptop |
| GitHub repos | **Done** | All seven public, with secret scanning, push protection and Dependabot alerts (see Repo map) |
| 1 TB drive layout | **Done** | Docs and services under `/Volumes/1tb drive` on the iMac |
| GopherGrid on the homelab | **Running** | Schedulers on the iMac and the GPU PC (moved off the laptop on 2026-11-14), both workers on the GPU PC. Real `llm` jobs on the live vLLM: 300 jobs × 8 prompts at 5,792 completion tok/s; with the GPU worker SIGKILLed mid-run, 600/600 jobs recorded exactly one result. A `benchmark` job ran gpu-systems-lab's matmul at 63.6 TFLOPS fp16 next to vLLM — [measurements](https://github.com/zakiscoding/gophergrid/blob/main/docs/homelab.md#measured-on-the-homelab) |
| CI | **Running** | GitHub Actions in all six repos: tests, lint, builds, config checks; GPU and live-host tests run on the homelab, not in CI |
| Backups | **Partial** | `backup-postgres.sh` on the iMac; schedule is next — [BACKUPS.md](docs/BACKUPS.md) |

## Docs

| Topic | Docs |
|-------|------|
| Overview | [Architecture](docs/ARCHITECTURE.md) · [Repositories](docs/REPOS.md) · [Docs index](docs/README.md) · [Shareable overview](share/HOMELAB-COMPLETE-OVERVIEW.md) |
| Inventory and network | [Inventory](docs/INVENTORY.md) · [Network](docs/NETWORK.md) · [1 TB drive layout](docs/DRIVE-LAYOUT.md) · [Secrets and access](docs/ACCESS.md) (where credentials live, not the values) |
| Nodes | [iMac](docs/nodes/imac-node.md) · [iMac checklist](docs/nodes/imac-checklist.md) · [GPU PC, Windows](docs/nodes/gpu-node.md) · [GPU checklist](docs/nodes/GPU-NODE-CHECKLIST.md) · [GPU PC, Ubuntu](docs/nodes/gpu-node-ubuntu.md) · [Laptop](docs/nodes/controller.md) |
| Services | [Services](docs/SERVICES.md) · [iMac stack](docs/services/imac-stack.md) · [Web UI](docs/services/web-ui.md) · [RAG](docs/services/rag.md) · [Vision / reactions](docs/services/vision-reactions.md) |
| Jobs and ML | [Execution model](docs/EXECUTION-MODEL.md) · [GPU training](docs/GPU-TRAIN.md) · [CNN fine-tune](docs/CNN-FINETUNE.md) · [Distributed train](docs/DISTRIBUTED-TRAIN.md) · [Reaction vision](docs/REACTION-VISION.md) · [MLflow](docs/MLFLOW.md) · [Market data](docs/MARKET-DATA-GPU.md) |
| Operations | [Observability](docs/OBSERVABILITY.md) · [Testing](docs/TESTING.md) · [Backups](docs/BACKUPS.md) · [Public internet (optional)](docs/deploy/public-internet.md) · [Git workflow](docs/GIT.md) · [Setup log](docs/SETUP-LOG.md) |
| Build phases | [0A](docs/PHASE-0A.md) · [0B](docs/PHASE-0B.md) · [1](docs/PHASE-1.md) · [2](docs/PHASE-2.md) · [3](docs/PHASE-3.md) · [3b](docs/PHASE-3-LORA-SERVE.md) · [4](docs/PHASE-4.md) · [5](docs/PHASE-5.md) · [6](docs/PHASE-6.md) |

## How we use this repo

1. `git pull` — GitHub is canonical for docs.
2. Before a change, skim the latest [setup log](docs/SETUP-LOG.md) entries.
3. During setup, note commands and paths; service config lives in the code repos, not here.
4. After it works, add a dated setup-log entry, update inventory/services, then commit and push.

On the iMac the docs live at `/Volumes/1tb drive/homelab`, next to `homelab-services/` and
`homelab-web/` ([DRIVE-LAYOUT.md](docs/DRIVE-LAYOUT.md)). On the laptop: `C:\Users\cashh\homelab`.

## Related repos

- [homelab-services](https://github.com/zakiscoding/homelab-services) — iMac control plane
- [homelab-web](https://github.com/zakiscoding/homelab-web) — web UI
- [homelab-gpu](https://github.com/zakiscoding/homelab-gpu) — GPU PC, Windows boot
- [gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab) — GPU PC, Ubuntu boot, Modal, router
- [gophergrid](https://github.com/zakiscoding/gophergrid) — distributed job scheduler (Go, gRPC, etcd)
- [low-latency-trading-engine](https://github.com/zakiscoding/low-latency-trading-engine) — low-latency C++ trading engine with paper trading and a public web UI
