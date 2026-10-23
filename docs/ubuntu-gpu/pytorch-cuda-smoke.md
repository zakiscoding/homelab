# Phase 1 — `pytorch-cuda-smoke`

## Where the real project lives

The working smoke project is **host-local on the Ubuntu GPU box**, not a separate GitHub repository:

```text
/home/zak/projects/pytorch-cuda-smoke
```

| Artifact (on GPU box) | Role |
|-----------------------|------|
| `README.md` | Versions (`nvidia-smi`, `torch.__version__`, `torch.version.cuda`) |
| `requirements.txt` | Pinned wheels |
| `.venv/` | Local venv (not committed) |
| `scripts/smoke_cuda.py` | CUDA matmul + tiny train step |
| `.gitignore` | venv, caches, `.env` |

**This `homelab` docs repo does not contain that checkout.** A minimal recreate recipe is below (and under [`examples/pytorch-cuda-smoke/`](examples/pytorch-cuda-smoke/)) so operators can rebuild if the host tree is missing. Prefer copying from the GPU box when available.

---

## Result (2026-10-23)

| Item | Value |
|------|--------|
| Host | Ubuntu `zak-gpu-node` (RTX 5070) |
| Pin | `torch==2.11.0+cu128`, `torchvision==0.26.0+cu128` |
| Arch | `sm_120` present |
| Smoke | **PASS** — matmul FP32/FP16 + `nn.Linear` train step |
| Toolkit | Full CUDA Toolkit **not** installed (`nvcc` absent) |
| Docker / Modal | Not used |

Policy: install a **PyTorch-provided CUDA wheel** compatible with the driver; do **not** install the full CUDA Toolkit unless custom CUDA/C++ kernels are needed.

---

## Recreate on `zak-gpu-node` (Ubuntu external disk only)

**Before starting:** verify Windows NVMe partitions are **unmounted**; confirm `/` is on `/dev/sda*`.

```bash
mkdir -p ~/projects/pytorch-cuda-smoke
cd ~/projects/pytorch-cuda-smoke
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install torch==2.11.0+cu128 torchvision==0.26.0+cu128 \
  --index-url https://download.pytorch.org/whl/cu128
# copy or recreate scripts/smoke_cuda.py from examples/pytorch-cuda-smoke/
python scripts/smoke_cuda.py
```

Expected: script exits 0 and prints CUDA device name, `sm_120` (or arch list containing it), and PASS for matmul / train step.

---

## Safety

- Work only under `~/projects` on the Ubuntu disk.
- No `sudo`, no Docker, no Modal, no system CUDA Toolkit for this smoke.
- Never write to the Windows NVMe.
