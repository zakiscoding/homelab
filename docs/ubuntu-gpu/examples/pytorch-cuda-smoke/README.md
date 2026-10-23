# pytorch-cuda-smoke (minimal mirror)

**Docs-only mirror** of the Phase 1 smoke layout. The authoritative working tree is on the Ubuntu GPU box at `~/projects/pytorch-cuda-smoke` — see [../../pytorch-cuda-smoke.md](../../pytorch-cuda-smoke.md).

Verified pin (2026-10-23 on `zak-gpu-node`): `torch==2.11.0+cu128` / `torchvision==0.26.0+cu128` — **PASS**.

## Quickstart (on Ubuntu GPU boot only)

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -U pip
pip install -r requirements.txt --index-url https://download.pytorch.org/whl/cu128
python scripts/smoke_cuda.py
```

Do not run this expecting a GPU on the Cursor cloud VM (`cursor-cloud`).
