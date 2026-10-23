# Phased Infrastructure Plan — Hybrid AI Lab

**Scope:** Living plan for the hybrid AI lab on the **Ubuntu boot** of the dual-boot GPU PC. Execution follows phase gates below; existing `homelab*` Windows/iMac software paths stay untouched unless the user asks. New Ubuntu work lives under `~/projects` on the external disk.

**Stack:** Local Ubuntu GPU boot (`zak-gpu-node`) first → Docker after local PyTorch smoke → Modal parity after Docker → NCCL/DDP only on Modal multi-GPU.

**Related repos (context only):** `homelab` (docs — this tree), `homelab-gpu` (Windows training), `homelab-services` (iMac API/stack), `homelab-web` (UI). Existing docs describe a Windows GPU path (`zak_pc` / Tailscale `zakar`). **Authoritative identity:** physical Ubuntu OS-name `zak-gpu-node` and Windows `zakar` / `zak_pc` are the **same dual-boot PC** (one RTX 5070) — Ubuntu on external `/dev/sda`, Windows on internal NVMe. This plan covers the **Ubuntu-native** CUDA/Docker/Modal track on that machine. The Cursor cloud Tailscale name is `cursor-cloud` @ `100.124.163.68` (see Phase 0B); Ubuntu Tailscale is `zak-gpu-node` @ `100.121.51.35`.

**Naming note:** Repo-root [`PHASE-0A.md`](../PHASE-0A.md) / [`PHASE-0B.md`](../PHASE-0B.md) are the **Windows/iMac job control plane**. The Phase 0A/0B below are the **Ubuntu hybrid track** only.

---

## Hard invariants (every phase)

| Invariant | Rule |
|-----------|------|
| **Windows NVMe** | Never modify, format, repartition, or write to the 2TB Windows internal NVMe. **Before work:** verify Windows partitions are **unmounted** (they have auto-mounted before — do not assume). If mounted, unmount before continuing; do not browse or write. Ubuntu work stays on the dedicated external drive (`/dev/sda`). |
| **Workspace** | Default work root: `~/projects`. Anything outside requires explicit user approval. Existing `homelab*` repos stay untouched unless asked. |
| **Privilege / system** | Ask before `sudo`, Docker/NVIDIA Container Toolkit install, networking/firewall/Tailscale changes, or system package updates. |
| **Modal vs buy** | Prefer Modal for multi-GPU / burst cost; do not assume a second GPU PC. **Modal is not set up** — do not install or configure until the user explicitly asks. |
| **CUDA Toolkit** | Do **not** install the full CUDA Toolkit unless custom CUDA/C++ kernels are needed. Prefer PyTorch-provided CUDA wheels. |

### Approval legend

Items marked **[APPROVAL]** need a clear yes from the user before any agent or operator executes them.

---

## Inventory (authoritative baseline)

### Local dual-boot PC — one machine, two OS boots

| Item | Value |
|------|--------|
| Hardware | One PC, NVIDIA RTX 5070 12GB VRAM |
| Ubuntu boot | OS hostname `zak-gpu-node`; Ubuntu 24.04.5 LTS on dedicated 750GB external (`/dev/sda`) |
| Windows boot | Homelab name `zak_pc`; Tailscale `zakar` (`100.88.71.33` when online); Windows on internal 2TB NVMe — **do not touch** |
| Ubuntu driver (when booted) | 595.99.02 (CUDA driver support 13.2) |
| Ubuntu Tailscale | `zak-gpu-node` @ `100.121.51.35` |
| Not this machine | Cursor cloud VM advertising Tailscale `cursor-cloud` @ `100.124.163.68` (no GPU) |

### Cloud — Modal (later)

| Item | Role |
|------|------|
| Modal | Expensive jobs, multi-GPU, DDP/NCCL experiments — **not installed / not configured** in this stack yet |

---

## Phase 0 — Split: local safety first, Tailscale later

Local RTX 5070 / PyTorch work **must not wait** on Tailscale naming or remote SSH cleanup. Phase 0 is two tracks:

| Track | Name | Blocks Phase 1? | When |
|-------|------|-----------------|------|
| **0A** | Local safety baseline | **Yes** — required before Phase 1 | Now |
| **0B** | Tailscale identity / remote path | **No** — defer | Before remote SSH / control-plane work |

### Clarification (identity map)

- **Same physical PC:** Ubuntu OS-name `zak-gpu-node` ↔ Windows `zak_pc` / Tailscale `zakar` — dual-boot, one RTX 5070.
- Ubuntu Tailscale: `zak-gpu-node` @ `100.121.51.35`. Cursor cloud VM: `cursor-cloud` @ `100.124.163.68` (no GPU) — not the remote path to the GPU PC.
- Windows Tailscale path remains `zakar` @ `100.88.71.33` when that OS is booted.

---

### Phase 0A — Local safety baseline

**Goal:** Confirm this is the real Ubuntu GPU boot and the Windows disk is safe before any Phase 1 install.

### Work

- [x] Confirm OS hostname is Ubuntu `zak-gpu-node` (not Cursor VM).
- [x] Confirm Ubuntu root is on `/dev/sda` (external); home/workspace on that disk.
- [x] **Verify** Windows NVMe partitions are **unmounted** before work (do not assume — they have auto-mounted once).
- [x] Confirm `nvidia-smi` healthy (driver present; do not “fix” blindly).
- [x] Confirm `~/projects` as default workspace; existing `homelab*` repos untouched.

### Exit criteria (0A)

- [x] `/` on `/dev/sda*`; Windows NVMe unmounted at start of work.
- [x] `nvidia-smi` shows RTX 5070 + working driver.
- [x] Ready to begin Phase 1 immediately (0B not required).

---

### Phase 0B — Tailscale identity cleanup (deferred)

**Goal:** Finish remote-access identity before SSH / Magentic / control-plane work. **Does not block Phase 1.**

### Work

- [x] Cursor VM renamed to Tailscale `cursor-cloud` (frees `zak-gpu-node` for Ubuntu boot).
- [x] Install Tailscale on Ubuntu boot and join as `zak-gpu-node` (`100.121.51.35`; distinct from `cursor-cloud` @ `100.124.163.68`).
- [ ] Inventory / document Tailscale machines for operators (names, IPs, OS boot) — see [infra-inventory.md](infra-inventory.md).
- [ ] Document SSH / Magentic / Cursor remote target only after identity is unambiguous.
- [ ] Remote path to the real GPU node (correct OS boot) verified by the user.

### Exit criteria (0B)

- [x] No two machines claim `zak-gpu-node` on Tailscale.
- [ ] Remote path to the real GPU node is explicit and user-verified.
- [ ] Done **before** relying on Tailscale for SSH/control-plane automation.

### Requires approval (0B)

- **[APPROVAL]** Tailscale rename / remove / ACL or firewall changes.
- **[APPROVAL]** Any SSH daemon / networking changes on the GPU box.
- **[APPROVAL]** Work outside `~/projects`.

---

## Phase 1 — Local PyTorch baseline (CUDA wheel, no Toolkit)

**Goal:** Verified local GPU stack for development inside `~/projects`, without Docker yet.

**Windows NVMe:** At session start, verify Windows partitions are unmounted; confirm Ubuntu root/home on `/dev/sda`.

### Prerequisites

- Phase **0A** exit criteria met (not 0B).
- Driver already present per inventory (595.99.02); validate with `nvidia-smi`.

### Work

- [x] Install a **PyTorch-provided CUDA wheel** compatible with the NVIDIA driver (Blackwell / `sm_120` needs CUDA **12.8+** wheel, e.g. `cu128`); **do not** install the full CUDA Toolkit unless custom CUDA/C++ kernels are needed. The driver is already working; PyTorch ships the CUDA runtime it needs. **Done:** `torch==2.11.0+cu128` / `torchvision==0.26.0+cu128` in `~/projects/pytorch-cuda-smoke`.
- [x] Create `~/projects/<name>` layout — `~/projects/pytorch-cuda-smoke`.
- [x] Python venv + pinned `torch` / `torchvision` from the official PyTorch wheel index (not system packages).
- [x] Smoke tests: tensor on CUDA, matmul, tiny train step, VRAM note; `sm_120` present — **PASS** (`scripts/smoke_cuda.py`).
- [x] Capture versions in project README (`nvidia-smi`, `torch.__version__`, `torch.version.cuda`).

### Deliverables

- Working venv under `~/projects/pytorch-cuda-smoke` with `requirements.txt` (**host-local on the GPU box** — see [pytorch-cuda-smoke.md](pytorch-cuda-smoke.md)).
- One-command smoke: `python scripts/smoke_cuda.py`.

### Exit criteria

- [x] `nvidia-smi` healthy; smoke script passes on RTX 5070.
- [x] Pins documented; no system-wide Python pollution; no full CUDA Toolkit (`nvcc` still absent).
- [x] Windows NVMe verified unmounted; no unapproved `sudo`/updates.

### Requires approval

- **[APPROVAL]** `sudo` apt/driver/**full CUDA Toolkit** installs or upgrades (not needed for standard PyTorch wheels).
- **[APPROVAL]** System-wide Python or package changes outside the project venv.
- **[APPROVAL]** System updates.

---

## Phase 2 — Docker + NVIDIA Container Toolkit

**Goal:** Reproducible GPU containers on the local Ubuntu node for the same workloads as Phase 1.

**Windows NVMe:** Container data/volumes stay on Ubuntu disk paths under home or approved project dirs.

### Prerequisites

- Phase 1 smoke green.
- Disk space check on Ubuntu external drive.

### Work

- [ ] **[APPROVAL]** Install Docker Engine (or confirm existing) + NVIDIA Container Toolkit.
- [ ] **[APPROVAL]** User in `docker` group / socket permissions as preferred by user.
- [ ] Base image choice aligned with Phase 1 PyTorch/CUDA pin.
- [ ] `docker run --gpus all` smoke (same checks as Phase 1).
- [ ] Project Dockerfile + compose (optional) pattern for local GPU jobs.
- [ ] Document volume mounts: code from `~/projects`, caches on Ubuntu disk only.

### Deliverables

- Documented install steps (executed only after approval).
- Sample GPU Dockerfile + run script in a scaffold project.
- Pass/fail container smoke checklist.

### Exit criteria

- [ ] Container sees the RTX 5070 and runs the smoke test.
- [ ] Host and container pins are consistent enough for day-to-day work.
- [ ] No Windows disk mounts in compose/volume configs.

### Requires approval

- **[APPROVAL]** Docker Engine / NVIDIA Container Toolkit install.
- **[APPROVAL]** `sudo`, group membership, daemon config.
- **[APPROVAL]** Firewall or exposing container ports beyond localhost.
- **[APPROVAL]** System updates pulled as part of install.

---

## Phase 3 — Project scaffolding conventions

**Goal:** Every AI-infra experiment is portfolio-ready and runnable locally (venv and/or Docker) with clear docs.

### Prerequisites

- Phase 1 done; Phase 2 recommended but not strictly required for scaffolding templates.

### Recommended layout (`~/projects/<name>/`)

```text
README.md           # goal, hardware assumptions, quickstart
requirements.txt    # or pyproject.toml — pinned
scripts/            # smoke, train, eval entrypoints
src/                # library code
configs/            # YAML/JSON hyperparameters
docker/ or Dockerfile
modal/              # Modal app entry (Phase 4+)
.gitignore          # venv, data, checkpoints, .env
```

### Conventions checklist

- [ ] Git repo per project (or monorepo policy — decide once).
- [ ] README: hardware (12GB local vs Modal), install, run local, run Modal, expected artifacts.
- [ ] Scripts: no hardcoded Windows paths; Ubuntu + Modal only for this track.
- [ ] Secrets via `.env` (gitignored); never commit keys.
- [ ] Large weights/datasets gitignored; document where they live on Ubuntu disk.
- [ ] One “definition of done” smoke per project.

### Deliverables

- A reusable template project under `~/projects/_template` (or documented cookiecutter steps).
- Short CONTRIBUTING-style note: how to add a new experiment.

### Exit criteria

- [ ] New project can be cloned/copied and reach smoke in documented steps.
- [ ] Conventions written and used by at least one real project stub.

### Requires approval

- **[APPROVAL]** Creating repos outside `~/projects` or pushing to org/remotes if that needs credentials/policy.
- **[APPROVAL]** Any change to existing `homelab*` repos (out of scope unless user asks).

---

## Phase 4 — Modal parity

**Goal:** Same training/inference workloads run on Modal with minimal drift from local scripts.

**Status:** **Not started.** Modal is **not set up** in this homelab. Do not add install instructions as completed work.

### Prerequisites

- Phase 3 template exists.
- Modal account / token available to the user (agent must not invent secrets).
- Explicit user request to begin Modal work.

### Work

- [ ] Modal project layout (`modal/` or `app.py`) wrapping the same `src/` entrypoints.
- [ ] Image build: match Phase 1/2 CUDA/PyTorch pins as closely as Modal images allow; document deltas.
- [ ] Volumes / secrets for datasets and checkpoints.
- [ ] Cost guardrails: GPU type, timeout, concurrency defaults in README.
- [ ] Parity checklist: local smoke ↔ Modal single-GPU smoke (same script flags).

### Requires approval

- **[APPROVAL]** Modal billing / creating paid GPU runs.
- **[APPROVAL]** Uploading datasets or model weights to Modal volumes.
- **[APPROVAL]** Networking changes if Modal webhooks/tunnels are involved.

---

## Phase 5 — PyTorch DDP / NCCL on Modal

**Goal:** Multi-GPU distributed experiments on Modal (not on the single local 12GB card).

### Prerequisites

- Phase 4 single-GPU Modal path solid.
- Workload that benefits from ≥2 GPUs (synthetic allreduce OK for first milestone).

### Work

- [ ] Minimal DDP script: process group init, NCCL backend, allreduce sanity, timed train step.
- [ ] Modal multi-GPU resource config (GPU count/type) documented.
- [ ] Failure modes checklist: NCCL timeouts, mismatched CUDA, uneven batches.
- [ ] Optional: scale a real small model once synthetic test passes.
- [ ] Explicit note: local node remains single-GPU validation; DDP proof is Modal-first.

### Requires approval

- **[APPROVAL]** Multi-GPU Modal runs (cost).
- **[APPROVAL]** Longer training jobs / higher quotas.

---

## Phase 6 — Portfolio project sequencing

**Goal:** Ship a short sequence of portfolio-quality AI-infra projects using this stack.

### Suggested sequence (adjust after open decisions)

| Order | Project theme | Proves |
|-------|---------------|--------|
| 1 | CUDA/PyTorch + Docker smoke portfolio repo | Local reproducibility |
| 2 | Train-small + Modal single-GPU parity | Hybrid workflow |
| 3 | DDP/NCCL Modal lab report | Distributed infra literacy |
| 4 | Optional: tie-in to homelab control plane / MLflow later | System design (only if desired) |

### Requires approval

- **[APPROVAL]** Making repos public / publishing benchmarks.
- **[APPROVAL]** Integrating with existing `homelab-services` / Windows Ollama path.
- **[APPROVAL]** Any work outside `~/projects`.

---

## Cross-phase checklist (operators / agents)

Before any change on the dual-boot GPU PC:

- [ ] Am I on the **real** Ubuntu boot (`zak-gpu-node` OS hostname), not Cursor Tailscale `cursor-cloud` @ `100.124.163.68`?
- [ ] Am I under `~/projects` (or explicitly approved path) on the Ubuntu external disk?
- [ ] Did I **verify** Windows NVMe partitions are **unmounted** this session?
- [ ] Does this need **[APPROVAL]** (sudo / Docker / network / updates / full CUDA Toolkit)?
- [ ] Could this write to the Windows NVMe? If yes → **stop**.

---

## Open decisions / questions for the user

These shape Phase 1+; **0A is enough to start Phase 1**.

1. **Join Ubuntu boot to Tailscale as `zak-gpu-node`** — **Done** (`100.121.51.35`). Remaining 0B: document remote SSH target when needed. (Windows boot still uses Tailscale `zakar` when that OS is up.)
2. **Preferred PyTorch pin** — **Decided default:** PyTorch-provided CUDA wheel with `sm_120` (e.g. `cu128`+); no full CUDA Toolkit. Override only if you want a specific version.
3. **First portfolio project** — Smoke + Docker template, small fine-tune, inference server, or DDP lab first?
4. **Docker timing** — Install Docker in Phase 2 immediately after Phase 1 smoke, or defer until a project needs containers? (**Default:** after local PyTorch smoke; still needs **[APPROVAL]**.)
5. **Windows vs Ubuntu software coexistence** — Keep Ollama/`homelab-gpu` on the Windows boot as-is (Ubuntu work only on external disk), or plan a later migration of workloads onto Ubuntu?
6. **Git hosting** — New repos under `~/projects` only (**default**), or extend private `zakiscoding/homelab-*` docs? (This folder is the docs landing place in `homelab`.)
7. **Modal packaging** — Prefer Modal Functions + custom image, or Modal + Docker image build from the same Dockerfile as local? (Defer until Phase 4; **no Modal until explicitly asked**.)

---

## Phase dependency graph

```text
Phase 0A (local safety) ─────────────────────────────┐
                                                      ▼
                                              Phase 1 (local PyTorch wheel)
                                                      ├── Phase 2 (Docker / NVIDIA CTK) [APPROVAL]
                                                      └── Phase 3 (scaffolding)
                                                              └── Phase 4 (Modal parity) [explicit ask]
                                                                      └── Phase 5 (DDP/NCCL on Modal)
                                                                              └── Phase 6 (portfolio)

Phase 0B (Tailscale / remote path) ──► before SSH / control-plane only (does not block Phase 1)
```

**Document status:** Plan + execution tracker. **Phase 0A complete; Phase 1 smoke green** on `zak-gpu-node` (`~/projects/pytorch-cuda-smoke`). Phase 0B deferred (remote SSH). Docker / MPI / NCCL / Modal not started.
