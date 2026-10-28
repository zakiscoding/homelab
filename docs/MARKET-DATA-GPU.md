# Market data and GPU experiment

Integration notes live in the private repo [zakiscoding/market-data-gpu-systems](https://github.com/zakiscoding/market-data-gpu-systems). This page is the pointer from the homelab docs hub.

Week 1, recorded 28 October 2026 on the Windows boot of `zak_pc`, put a 4,096-event `LOBREPV1` capture through EduFS. The offline checker passed, a QEMU remount read the same bytes twice, and the C++ and Python books emitted the same fingerprints. The raw result is `results/week-1.json` in that repo.

The file system in use is [linux-file-system-extension](https://github.com/zakiscoding/linux-file-system-extension). The capture format and replay engines are [limit-order](https://github.com/zakiscoding/limit-order). Training and CUDA timings stay on one named boot of the RTX 5070. MLflow remains the iMac service already documented in [MLFLOW.md](MLFLOW.md).

EduFS files stop at 4,243,456 bytes and the volume has no journal. Those limits are part of the experiment, not bugs to remove in order to hit a round number.
