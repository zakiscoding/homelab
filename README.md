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
- **Infrastructure as code** in [infra/](infra/README.md): Terraform for the Cloudflare edge (tunnels, Workers VPC services, workers.dev settings; existing resources imported, state in R2) and Ansible roles for the Linux nodes, tested twice against throwaway containers. Not yet planned or run against the real account and nodes
- No secrets. Application code lives in the other repos; credentials stay in `.env` files on each machine.

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
| Edge | `homelab-cloudflared` tunnel for the public dashboards and the trading site |

### GPU PC (`zakar`, Windows boot, 100.88.71.33)

| Group | Services (Docker in WSL2 Ubuntu) |
|-------|----------------------------------|
| AI serving | `vllm-chat`: Qwen2.5-1.5B, the backend for the gateway and the web UI |
| Monitoring | `obs-prometheus`, `obs-grafana`, `obs-dcgm-exporter`, `obs-node-exporter` |
| GopherGrid | `scheduler-2` (follower), `gpu-worker` (RTX 5070), `cpu-worker` |
| Scheduling | `slurmctld` + `slurmd` (native systemd in WSL2, GPU as a gres), `gg-nightly.timer` (nightly GopherGrid regression benchmark) |
| Edge | `cloudflared` tunnel for the LLM gateway |

Windows Tailscale publishes vLLM `:8000`, Grafana `:3000`, Prometheus `:9090` and the GopherGrid ports to the tailnet only (`tailscale serve`).

### Not running

| What | Why |
|------|-----|
| GPU PC Ubuntu boot (`zak-gpu-node`): vLLM, k3s, DCGM | The PC is booted into Windows |
| Ollama on the GPU PC | Replaced by vLLM in WSL2 as the chat backend |
| Ray cluster (head on the GPU PC, worker on the iMac) | Stopped after its benchmark; start it again from gpu-systems-lab `serving/ray/` |

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
| Chat backend | **Running** | `LLM_BACKEND=auto`: vLLM on whichever boot is up (in WSL2 on the Windows boot). The iMac API was mostly on the Ollama fallback until the [Colima 10-connect fix](https://github.com/zakiscoding/homelab-services/pull/4) on 2026-11-14 |
| GPU PC, Windows: Ollama | **Off** | Replaced by vLLM in WSL2 as the Windows-boot chat backend |
| GPU PC, Ubuntu boot | **Done** | `zak-gpu-node`, CUDA 13.2, Docker, Open MPI — [gpu-node-ubuntu.md](docs/nodes/gpu-node-ubuntu.md) |
| vLLM serving | **Running** | Always-on, tailnet `:8000/v1`, API key; Qwen2.5-1.5B 4.4k tok/s on RTX 5070 |
| Job queue | **Done** | Postgres SSOT, leases with renew, retry backoff, Redis wake |
| Router worker | **Done** | Routed jobs → local RTX 5070 or Modal; decision stored in `experiments` |
| Cloud GPU burst (Modal) | **Done** | H100 / 2x H100 / L4; **$10** usage limit |
| k3s GPU scheduling | **Running** | Single node, NVIDIA device plugin, GPU admission policy |
| Monitoring | **Running** | iMac Prometheus `:9090` + Grafana `:3000`; GPU node DCGM dashboard as a second datasource |
| Tracing, SLOs, alerting | **Running** | OpenTelemetry traces gateway → iMac API → vLLM in Tempo; 5 SLOs with burn-rate alerts; Alertmanager → ntfy. Found the iMac's Colima egress problem on day one — [homelab-services#4](https://github.com/zakiscoding/homelab-services/pull/4), [gpu-systems-lab#10](https://github.com/zakiscoding/gpu-systems-lab/pull/10), [postmortem](docs/postmortems/2026-11-04-wsl-down.md) |
| NVIDIA serving stack | **Measured** | Triton + TensorRT-LLM vs vLLM on the RTX 5070, same client and KV cache: TRT-LLM +10% at 256 in flight, vLLM 12–21% faster at 1–64 — [gpu-systems-lab#8](https://github.com/zakiscoding/gpu-systems-lab/pull/8) |
| GpuJob operator (Go) | **Tested** | controller-runtime CRD → GPU Jobs; 31 envtest/unit cases; queueing shown on kind with a fake GPU. GPU Operator + 4-way time-slicing prepared for k3s — [gpu-systems-lab#9](https://github.com/zakiscoding/gpu-systems-lab/pull/9) |
| Helm + Argo CD | **Tested** | Chart for the iMac stack, 32 unit tests, Argo CD sync and selfHeal on k3d (reverts in 2–5 s) — [homelab-services#3](https://github.com/zakiscoding/homelab-services/pull/3) |
| Infrastructure as code | **Validated** | Terraform for the Cloudflare edge (imports, R2 state), Ansible roles idempotent on test containers; no plan against the real account yet — [homelab#4](https://github.com/zakiscoding/homelab/pull/4) |
| Cloudflare LLM gateway | **Running** | Public OpenAI-compatible API on Workers: per-client keys, 60 requests/min per client (Durable Object), Workers AI fallback when the GPU is unreachable. Reaches vLLM through a tunnel with no open ports — [details](https://github.com/zakiscoding/gpu-systems-lab/blob/main/docs/CLOUDFLARE.md) |
| GPU PC, Windows: WSL2 | **Running** | vLLM, Prometheus, Grafana, DCGM and `cloudflared` in Ubuntu on WSL2, kept up by the `WSL Keep Alive` task. Ports bind to localhost and Windows Tailscale publishes them to the tailnet, so the iMac can reach this vLLM. The iMac's Prometheus scrapes it |
| Results site | **Live** | [gpu-systems-lab-results.vllm-gateway.workers.dev](https://gpu-systems-lab-results.vllm-gateway.workers.dev): benchmark results and charts, built from gpu-systems-lab. Latest: FP16 vs AWQ vs FP8 vLLM serving on the RTX 5070, run as GopherGrid jobs: FP8 works on Blackwell and gives 1.36–1.45x FP16 throughput; 4-bit AWQ halves single-request token latency; speculative decoding (n-gram or a 0.5B draft) made the 1.5B model slower |
| Public dashboards | **Live** | [grafana-proxy.vllm-gateway.workers.dev](https://grafana-proxy.vllm-gateway.workers.dev): read-only homelab dashboards |
| Paper-trading site | **Live** | [paper-trading.vllm-gateway.workers.dev](https://paper-trading.vllm-gateway.workers.dev): live data from the trading engine on the iMac; paper only. The native stack starts at iMac login, so a reboot needs a login to bring it back |
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
| Slurm | **Running** | Slurm 25.11 on the GPU PC (controller + node in WSL, GPU as a gres on `/dev/dxg`) running gpu-systems-lab's FSDP/NCCL jobs; a job survived controller and slurmd restarts — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/12) |
| JAX/XLA | **Done** (TPU run pending) | GPT benchmark ported to JAX with logit/grad parity tests: JAX + cuDNN attention 68.9 ms/step vs 73.5 for the best PyTorch setup on the RTX 5070; Colab/Kaggle TPU notebook ready — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/14) |
| GKE (Terraform) | **Done, torn down** | GopherGrid on GKE with KEDA + cluster autoscaler: exactly-once through a scheduler-leader kill; node autoscaling 17.2 → 23.6 jobs/s; project deleted after (<$0.25) — [PR](https://github.com/zakiscoding/gophergrid/pull/2) |
| DeepSpeed ZeRO | **Done** | ZeRO 1/2/3 vs DDP/FSDP2 on Modal 2x H100: ZeRO-1/2 within 5% of FSDP2 at 1.34B; optimizer-step bound at 5.64B — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/13). Megatron-LM not attempted |
| nccl-tests | **Done** | 2x H100: all-reduce 344 GB/s busbw (72% of the 478 GB/s NVLink limit), 13x slower without P2P; no IB/RDMA at home — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/11) |
| Triton kernel | **Done** | Fused bias+GELU in Triton: 559 GB/s, ties torch.compile, 14% faster than the hand-written CUDA kernel — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/16) |
| Custom PyTorch op | **Done** | C++/CUDA RMSNorm via `torch.library` (fake + autograd, passes `opcheck`, `fullgraph=True`): 562 GB/s, level with TorchInductor — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/17) |
| GEMM step by step | **Done** | Naive 0.5 → vectorized 18.4 TFLOPS (82% of cuBLAS FP32); WMMA 43.4 vs cuBLAS/CUTLASS 66.5 FP16 — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/19) |
| Roofline | **Done** | Every measured workload against the 5070's measured roofs, charted on the results site — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/18) |
| Ray | **Done** (cluster stopped) | Ray Serve LLM vs plain vLLM (same engine): −3.6% to −25% throughput, +43 ms TTFT, bursty tokens; Ray cluster GPU PC head (tailnet-joined container) + native iMac worker: 24 ms task RTT, ~10 MB/s; cross-node DDP to macOS failed at gloo rendezvous (documented) — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/20) |
| Engine comparison | **Done** | vLLM vs SGLang vs TensorRT-LLM, FlashAttention vs FlashInfer, 512→256 tokens on Qwen2.5-1.5B: SGLang peaks highest (5,243 tok/s), but under TTFT p95 ≤ 1 s / TPOT p95 ≤ 30 ms vLLM gives 3,048 tok/s vs TensorRT-LLM 2,518 and SGLang 1,516; one agreed 47-min `vllm-chat` window — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/21) |
| Nightly regression tracking | **Running** | systemd timer on the GPU PC submits a matmul `benchmark` job through GopherGrid each night; >5% below the 7-run median sets a Grafana flag and a Prometheus alert. A noisy-neighbour test was flagged at 0.47–0.49x; no self-hosted runner, `vllm-chat` never stopped — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/22) |
| Measurement rigor | **Done** | `benchstat.py`: warm-up, 10 separate runs, 95% CI and recorded GPU clocks. CUDA kernels re-measured: CV ≤ 0.5%; warp-shuffle reduction is 1.8% faster than CUB (not tied), fusion 1.98x — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/23) |
| Load balancer | **Done** | HAProxy in front of vLLM replicas: a replica kill fails 0.23% of requests with L7 retries vs 5.8% without; +1.1 ms p50 — [PR](https://github.com/zakiscoding/gpu-systems-lab/pull/15) |
| Postgres HA lab | **Done** | Streaming replication + failover on a copy of the job-queue DB: RTO 6–8 s, 0 acknowledged commits lost; sync partition stalls writes; commit p99 traced with bpftrace/iostat/strace/perf to flush stalls on the USB-backed Colima disk — [PR](https://github.com/zakiscoding/homelab-services/pull/6) |
| Upstream contribution | **Draft PR** | vLLM `bench throughput` spurious `--random-range-ratio` warning, e2e-validated — [vllm-project/vllm#67658](https://github.com/vllm-project/vllm/pull/67658) |
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
| Operations | [Infrastructure as code](infra/README.md) · [Observability](docs/OBSERVABILITY.md) · [Testing](docs/TESTING.md) · [Backups](docs/BACKUPS.md) · [Public internet (optional)](docs/deploy/public-internet.md) · [Git workflow](docs/GIT.md) · [Setup log](docs/SETUP-LOG.md) |
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
