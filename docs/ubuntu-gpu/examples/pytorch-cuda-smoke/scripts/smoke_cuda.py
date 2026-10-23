#!/usr/bin/env python3
"""Minimal CUDA smoke for RTX 5070 / sm_120 (Phase 1 mirror)."""

from __future__ import annotations

import sys


def main() -> int:
    import torch
    import torch.nn as nn

    print(f"torch={torch.__version__} cuda={torch.version.cuda}")
    if not torch.cuda.is_available():
        print("FAIL: torch.cuda.is_available() is False")
        return 1

    device = torch.device("cuda:0")
    name = torch.cuda.get_device_name(0)
    major, minor = torch.cuda.get_device_capability(0)
    arch_list = torch.cuda.get_arch_list()
    print(f"device={name} capability={major}.{minor}")
    print(f"arch_list={arch_list}")

    if "sm_120" not in arch_list and f"sm_{major}{minor}" not in arch_list:
        print("WARN: expected sm_120 (Blackwell) not listed; continuing anyway")

    a = torch.randn(2048, 2048, device=device, dtype=torch.float32)
    b = torch.randn(2048, 2048, device=device, dtype=torch.float32)
    c = a @ b
    torch.cuda.synchronize()
    print(f"matmul_fp32 ok mean={c.mean().item():.6f}")

    a16 = a.half()
    b16 = b.half()
    c16 = a16 @ b16
    torch.cuda.synchronize()
    print(f"matmul_fp16 ok mean={c16.float().mean().item():.6f}")

    model = nn.Linear(128, 64).to(device)
    x = torch.randn(32, 128, device=device)
    y = model(x).sum()
    y.backward()
    torch.cuda.synchronize()
    print("train_step ok")

    free, total = torch.cuda.mem_get_info(0)
    print(f"vram_free_gib={free / (1024**3):.2f} total_gib={total / (1024**3):.2f}")
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
