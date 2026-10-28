# Market data and GPU experiment

Integration notes live in the private repo [zakiscoding/market-data-gpu-systems](https://github.com/zakiscoding/market-data-gpu-systems). This page is the pointer from the homelab docs hub.

Weeks 1 through 6 were run on 27 October 2026 from the Windows boot of `zak_pc`. The write-up is `docs/results.md` in [zakiscoding/market-data-gpu-systems](https://github.com/zakiscoding/market-data-gpu-systems).

The million-event capture is eight EduFS files. The guest remount matched all of them. BTCUSDT January–March 2024 is the model window: logistic regression and a 32-unit MLP both land at test ROC AUC 0.524, so the network does not beat the linear baseline. On that checkpoint the CPU forward is faster than the RTX 5070 at every measured batch. MLflow run `57a218a5bedc4d9599835b7929ca70e3` is on the iMac.

The file system in use is [linux-file-system-extension](https://github.com/zakiscoding/linux-file-system-extension). The capture format and replay engines are [limit-order](https://github.com/zakiscoding/limit-order). Training and CUDA timings stay on one named boot of the RTX 5070. MLflow remains the iMac service already documented in [MLFLOW.md](MLFLOW.md).

EduFS files stop at 4,243,456 bytes and the volume has no journal. Those limits are part of the experiment, not bugs to remove in order to hit a round number.
