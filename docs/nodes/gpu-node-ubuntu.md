# GPU node — Ubuntu boot (`zak-gpu-node`)

The same desktop as [gpu-node.md](gpu-node.md) (RTX 5070), **dual-booted into Ubuntu** from an
external drive for CUDA/HPC/AI-infra work. Code and results live in
**[gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab)**.

> **One OS at a time.** When the PC is on Ubuntu, the Windows side (`zak_pc`, Tailscale `zakar`
> 100.88.71.33) is **offline**: no Ollama `:11434`, no Windows GPU worker, no vision API `:8100`.
> Homelab chat keeps working: the iMac API (`LLM_BACKEND=auto`) switches to vLLM on this boot.
> Boot back into Windows for the rest.

| | |
|--|--|
| **Hostname** | `zak-gpu-node` |
| **Tailscale** | **100.121.51.35** (MagicDNS `zak-gpu-node`) |
| **Login** | **`zak`** (in `sudo`, `docker`) |
| **SSH from laptop** | `ssh gpu-ts` (alias → `zak@zak-gpu-node`). Uses **Tailscale SSH** in check mode: re-approve in the browser every ~12 h |
| **OS / disk** | Ubuntu 24.04.5 on the **external 698 GB HGST drive** (`/dev/sda2`). The internal 2 TB Windows NVMe is **not mounted** |
| **GPU** | RTX 5070 12 GB, sm_120 (Blackwell), driver **595.99.02** (CUDA ≤ 13.2) |
| **CPU / RAM** | 28 threads, 31 GiB |

## Software

| Component | Version / location | Notes |
|-----------|--------------------|-------|
| CUDA toolkit | 13.2 (`/usr/local/cuda`) | toolkit only, driver unchanged |
| LLVM / Clang | 21 | CUDA → LLVM IR for sm_120 |
| PyTorch | 2.11.0+cu128 in `~/gpu-systems-lab/.venv` | 67.7 TFLOPS BF16 |
| vLLM | 0.32 (Docker, `serving/compose.yml`; venv `~/venvs/vllm` for benchmarks) | always-on on the tailnet **:8000/v1**, API key; homelab chat backend |
| Docker + NVIDIA Container Toolkit | Docker 29 | `docker run --gpus all` |
| Open MPI | 4.1.6 (apt) + `~/opt/openmpi-4.1.6-het` (source, heterogeneous) | the source build pairs with the iMac for 2-machine MPI |
| **k3s** | v1.36.5 (systemd `k3s`) | single node, NVIDIA device plugin v0.19.3, GPU admission policy |
| **Observability** | dcgm-exporter 4.6.1, Prometheus 3.5, Grafana 12.1, node-exporter | Docker compose `~/gpu-systems-lab/observability` |

## Services and ports

| Service | Address | Access |
|---------|---------|--------|
| Grafana (GPU dashboard) | http://100.121.51.35:3000/d/gpu-node | tailnet only; anonymous view, admin password in node `.env` |
| Prometheus | http://100.121.51.35:9090 | tailnet only |
| dcgm-exporter | 127.0.0.1:9400 | node only |
| k3s API | :6443 | TLS client cert (kubeconfig `~/.kube/config`, mode 600) |
| kubelet | :10250 | TLS client cert |
| vLLM | http://100.121.51.35:8000/v1 | tailnet only, API key (LAN refused); ~5 GB VRAM resident |
| SSH | :22 | Tailscale SSH on the tailnet |

**Hardening (done):** `gpu-systems-lab/scripts/harden_node.sh` blocks 22/6443/10250 on the LAN
interfaces (Wi-Fi `wlp5s0` 10.0.0.21 + Ethernet) with ufw, enables Nsight Compute counters after a
reboot and removes the setup-time passwordless sudo rule. LAN blocking is verified; the reboot for
Nsight counters is pending.

## Common operations

```bash
ssh gpu-ts                                          # from the laptop
nvidia-smi
cd ~/gpu-systems-lab/observability && docker compose ps      # monitoring stack
kubectl get nodes; kubectl -n gpu-jobs get jobs     # k3s GPU queue
python3 ~/gpu-systems-lab/scheduling/submit.py --help         # submit a GPU job
```

From the laptop, `python -m router route --job <name>` (in gpu-systems-lab) decides whether a job
runs here or on a Modal cloud GPU.

## Cloud burst: Modal

GPU jobs that don't fit 12 GB, or that need multiple GPUs, run on **Modal** (workspace
`zakiscoding`). The usage limit is set to **$10**. The client lives on the laptop in
`~\.venvs\gpu-lab`. Measured: H100 = 10x this card (677.8 TFLOPS BF16), 2x H100 NCCL all-reduce 329 GB/s.

## Uninstall / revert

| What | How |
|------|-----|
| k3s | `/usr/local/bin/k3s-uninstall.sh` |
| Monitoring stack | `cd ~/gpu-systems-lab/observability && docker compose down -v` |
| Firewall rules | `sudo ufw disable` |
| Profiling flag | `sudo rm /etc/modprobe.d/nvidia-profiling.conf && sudo update-initramfs -u` |
| vLLM | `rm -rf ~/venvs/vllm` |

Results and runbooks: [gpu-systems-lab docs/RESULTS.md](https://github.com/zakiscoding/gpu-systems-lab/blob/main/docs/RESULTS.md).
