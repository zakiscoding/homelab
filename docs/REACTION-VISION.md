# Reaction vision — research basis and homelab design

**Goal:** Computer vision that reads **your facial reactions** (expressions) from a webcam and returns an interpretable label + confidence — not LLM chat.

This document ties the homelab plan to published work so design choices have explicit reasoning.

---

## 1. Problem (what “understand my reactions” means)

In affective computing, a **facial reaction** is usually treated as a **visible expression** mapped to an emotion category or to **valence / arousal** (how positive/negative and how intense). The homelab MVP follows the **discrete emotion** path because it matches your existing **CNN classifier** stack ([CNN-FINETUNE.md](CNN-FINETUNE.md)) and fits RTX 5070 training.

**Reasoning chain (inference):**

```text
webcam frame → face region → CNN logits → emotion label + confidence → (optional) log / UI
```

That pipeline is standard in facial expression recognition (FER) literature; the papers below justify each step.

---

## 2. Primary references (read these first)

### A. Dataset and labels — FER2013

**Goodfellow, I., et al.** “Challenges in Representation Learning: A report on three machine learning contests.” *ICML 2013 Workshop on Representation Learning*, 2013.

- Introduces the **FER2013** benchmark: ~35k train / ~3.5k test faces, 48×48 grayscale, **7 emotion classes** (anger, disgust, fear, happiness, sadness, surprise, neutral).
- **Why we cite it:** Defines the task and label set the homelab will use first; widely reproduced on Kaggle/Hugging Face.
- **Limitation (from follow-on work):** Noisy single rater labels, many posed/studio faces — motivates FER+ below.

### B. Better labels on the same images — FER+

**Barsoum, E., Zhang, C., Ferrer, C. C., & Zhang, Z.** “Training Deep Networks for Facial Expression Recognition with Crowd-Sourced Label Distribution.” *arXiv:1608.01041*, 2016. ([PDF](https://arxiv.org/abs/1608.01041))

- Relabels FER2013 with **crowd consensus** and **label distributions** (not one hot noisy tag).
- Reports strong CNN baselines on FER2013/FER+; shows **majority vote** and **distribution-based loss** improve over raw FER2013 tags.
- **Why we cite it (core reasoning paper):**
  - Justifies **7–8 emotion categories** for “reactions.”
  - Justifies treating low confidence as **ambiguous** (paper’s whole point: expressions are uncertain).
  - Recommends **deep CNNs** on face crops — aligns with ResNet fine-tune on GPU.

**Homelab mapping:** Train on FER2013 or FER+; at inference, show **softmax confidence** and only assert a reaction when confidence exceeds a threshold (distribution thinking from FER+).

### C. Architecture — transfer learning with ResNet

**He, K., Zhang, X., Ren, S., & Sun, J.** “Deep Residual Learning for Image Recognition.” *Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition (CVPR)*, 2016. ([PDF](https://arxiv.org/abs/1512.03385))

- **ResNet** residual blocks enable training deeper CNNs; **ResNet-18** is a standard efficient backbone.
- **Why we cite it:** Homelab CNN jobs use **ImageNet-pretrained ResNet18** + replaced final layer ([`homelab-gpu/training/cnn_quickstart/train.py`](https://github.com/zakiscoding/homelab-gpu)). FER papers (including FER+) use similar **transfer learning**: low-level face features transfer from general vision pretraining.

### D. Faces “in the wild” (phase 2 dataset)

**Mollahosseini, A., Hasani, B., & Salaman, D. M.** “AffectNet: A Database for Facial Expression, Valence, and Arousal Computing in the Wild.” *IEEE Transactions on Affective Computing*, 2019 (early arXiv 2017). ([IEEE](https://ieeexplore.ieee.org/document/8013713))

- Large-scale **in-the-wild** faces with expression + **valence/arousal**.
- **Why we cite it:** Explains why webcam/home lighting differs from FER2013; motivates **fine-tuning on your own reaction folders** later (`datasets/me-reactions/train/...`).

### E. Psychological grounding (optional, for “reaction” vocabulary)

**Ekman, P., & Friesen, W. V.** *Facial Action Coding System (FACS)*. Consulting Psychologists Press, 1978.

- Not a ML paper — defines **action units** underlying expressions.
- **Why we mention it:** Clarifies that “reactions” are **brief, observable face movements**, not mind-reading; sets realistic expectations for CNN output.

---

## 3. Design decisions → paper reasoning

| Homelab choice | Reasoning from literature |
|----------------|----------------------------|
| **Face crop → CNN** | Standard FER pipeline (FER2013 challenge, FER+, AffectNet all use aligned/cropped faces). |
| **7 emotion labels** | FER2013 / FER+ taxonomy; Barsoum et al. show crowd labels improve over raw tags. |
| **ResNet18 + fine-tune** | Deep CNN + transfer learning per FER+ and ResNet; fits 12 GB VRAM. |
| **Confidence threshold** | FER+ label distributions → high-entropy predictions = “uncertain / neutral” rather than wrong certainty. |
| **Custom `me-reactions` dataset later** | AffectNet: domain shift between lab dataset and **your** webcam; personal fine-tune is standard mitigation. |
| **Distributed batching (iMac + GPU)** | iMac plans shard indices in Postgres; GPU executes AMP training per [DISTRIBUTED-TRAIN.md](DISTRIBUTED-TRAIN.md) — coordinator/executor, not cross-device DDP. |
| **Not using LLM for vision** | These papers are **discriminative vision**; language models are separate (homelab chat/RAG). |

---

## 4. Proposed homelab architecture

```text
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│ Webcam      │────►│ Face detect      │────►│ ResNet18 (FER fine-   │
│ (browser or │     │ (OpenCV Haar or  │     │ tuned) → 7 classes  │
│  GPU local) │     │  MediaPipe)      │     │ + softmax confidence│
└─────────────┘     └──────────────────┘     └──────────┬──────────┘
                                                        │
                        ┌───────────────────────────────▼──────────────┐
                        │ homelab-web /reactions  or  GPU script       │
                        │ "happy (0.82)" / "uncertain" if max < τ       │
                        └──────────────────────────────────────────────┘
```

**Training (GPU worker, existing job plane):**

```json
{
  "train_mode": "cnn",
  "dataset": "fer2013",
  "model_version": "reaction-resnet18-v1",
  "architecture": "resnet18",
  "epochs": 15
}
```

**Inference reasoning (pseudo):**

1. If **no face** detected → `reason: no_face` (not an emotion).
2. If **max softmax < τ** (e.g. 0.45) → `reason: ambiguous_expression` (FER+ uncertainty).
3. Else → `label = argmax`, `confidence = max prob`, `reason: fer_classifier`.

---

## 5. Datasets for this project

| Stage | Dataset | Paper | Homelab path |
|-------|---------|-------|--------------|
| **1 — Baseline** | FER2013 | Goodfellow et al. 2013 | `homelab-data/datasets/fer2013/` (download script TBD) |
| **2 — Better labels** | FER+ | Barsoum et al. 2016 | Same images, relabel file from [Microsoft FER+ repo](https://github.com/Microsoft/FERPlus) |
| **3 — Personal** | Your webcam captures | AffectNet motivates in-the-wild | `datasets/me-reactions/train/{happy,neutral,surprise,...}/` |

Start with **FER2013** for a working baseline; move to **FER+** labels when you want accuracy closer to published benchmarks.

---

## 6. Benchmarks to compare against (sanity checks)

From **Barsoum et al. (FER+)** (order-of-magnitude, not exact hardware match):

- Strong CNN on FER2013/FER+ often reaches **~85%+** on held-out test with good labels and augmentation.
- If homelab val accuracy is **&lt; 60%**, check: grayscale vs RGB pipeline, class imbalance, or train/val leak.

Track **`metrics.json`** per job ([CNN-FINETUNE.md](CNN-FINETUNE.md)) and compare epoch-over-epoch.

---

## 7. Limitations (from the literature — be honest in the UI)

| Limitation | Source |
|------------|--------|
| Expressions ≠ inner emotion | Ekman/FACS; FER papers measure **visible face**, not intent. |
| Culture / individual difference | AffectNet, FER+ discuss label noise and subjective affect. |
| Posed vs spontaneous | FER2013 skews posed; webcam is closer to “wild” (AffectNet motivation). |
| Single camera, lighting | No 3D face model in MVP — occlusion and shadows hurt CNNs. |

UI copy should say **“detected expression”**, not **“you feel X.”**

---

## 8. Implementation checklist (homelab)

- [x] CNN train path (`train_mode: cnn`, ResNet18) — [CNN-FINETUNE.md](CNN-FINETUNE.md)
- [x] FER2013 loader + `download-fer2013.ps1` + `train_reaction_gpu.py` — [GPU-TRAIN.md](GPU-TRAIN.md)
- [ ] Optional FER+ label CSV merge (Barsoum et al. methodology)
- [x] `infer_reaction_webcam.py` — webcam + face crop + `best_model.pt`
- [x] API `POST /vision/reaction` (image base64) on iMac → `GPU_VISION_URL` on zak_pc
- [x] Web UI `/reactions` with live camera + confidence bar
- [ ] Fine-tune on **`me-reactions`** for your face/lighting

---

## 9. BibTeX (for notes / README)

```bibtex
@inproceedings{goodfellow2013challenges,
  title={Challenges in Representation Learning: A report on three machine learning contests},
  author={Goodfellow, Ian and others},
  booktitle={ICML Workshop on Representation Learning},
  year={2013}
}

@article{barsoum2016training,
  title={Training Deep Networks for Facial Expression Recognition with Crowd-Sourced Label Distribution},
  author={Barsoum, Emad and Zhang, Cha and Ferrer, Cristian Canton and Zhang, Zhengyou},
  journal={arXiv preprint arXiv:1608.01041},
  year={2016}
}

@inproceedings{he2016deep,
  title={Deep Residual Learning for Image Recognition},
  author={He, Kaiming and Zhang, Xiangyu and Ren, Shaoqing and Sun, Jian},
  booktitle={CVPR},
  year={2016}
}

@article{mollahosseini2017affectnet,
  title={AffectNet: A Database for Facial Expression, Valence, and Arousal Computing in the Wild},
  author={Mollahosseini, Ali and Hasani, Behzad and Salaman, Mohammad H},
  journal={IEEE Transactions on Affective Computing},
  year={2019}
}
```

---

## 10. Next step

1. Download **FER2013** on `zak_pc` and run a **reaction** train job (`model_version: reaction-resnet18-v1`).
2. Implement webcam inference with **confidence threshold** per FER+ reasoning.
3. Collect **50–200 frames per expression** of yourself → fine-tune for “my reactions” (AffectNet-style domain adaptation).

Related: [CNN-FINETUNE.md](CNN-FINETUNE.md) · [EXECUTION-MODEL.md](EXECUTION-MODEL.md) · [gpu-node.md](nodes/gpu-node.md)
