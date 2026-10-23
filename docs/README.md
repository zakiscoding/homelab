# Docs index

Every document in this repo, grouped by topic. Start with [ARCHITECTURE.md](ARCHITECTURE.md).
Back to the [repo README](../README.md).

## Overview

| Doc | What it covers |
|-----|----------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Topology, chat, job lifecycle, routing and monitoring diagrams; node/port table; design principles |
| [REPOS.md](REPOS.md) | The five repos, where each runs, clone commands |
| [SERVICES.md](SERVICES.md) | Every running service with URL and config path |
| [../share/HOMELAB-COMPLETE-OVERVIEW.md](../share/HOMELAB-COMPLETE-OVERVIEW.md) | Standalone overview to send to others |

## Hardware, network, access

| Doc | What it covers |
|-----|----------------|
| [INVENTORY.md](INVENTORY.md) | Hosts, containers, k3s, cloud, storage |
| [NETWORK.md](NETWORK.md) | Tailscale addresses, firewall and exposure |
| [DRIVE-LAYOUT.md](DRIVE-LAYOUT.md) | Folder map of the iMac 1 TB drive |
| [ACCESS.md](ACCESS.md) | Where credentials live (never the values) |
| [deploy/public-internet.md](deploy/public-internet.md) | Optional public HTTPS through Caddy |

## Nodes

| Doc | Node |
|-----|------|
| [nodes/imac-node.md](nodes/imac-node.md) | iMac control plane runbook |
| [nodes/imac-checklist.md](nodes/imac-checklist.md) | iMac responsibilities, done vs planned |
| [nodes/gpu-node.md](nodes/gpu-node.md) | GPU PC, Windows boot: Ollama, training, worker |
| [nodes/GPU-NODE-CHECKLIST.md](nodes/GPU-NODE-CHECKLIST.md) | GPU PC, Windows boot: install checklist and ports |
| [nodes/gpu-node-ubuntu.md](nodes/gpu-node-ubuntu.md) | GPU PC, Ubuntu boot: CUDA, vLLM, k3s, DCGM, Modal |
| [nodes/controller.md](nodes/controller.md) | Laptop controller: SSH aliases, tests, deploys |

## Services

| Doc | Service |
|-----|---------|
| [services/imac-stack.md](services/imac-stack.md) | Docker Compose stack on the iMac |
| [services/web-ui.md](services/web-ui.md) | homelab-web (chat, RAG, reactions) |
| [services/rag.md](services/rag.md) | RAG ingest, embed and query |
| [services/vision-reactions.md](services/vision-reactions.md) | Reaction CNN on the GPU PC |
| [OBSERVABILITY.md](OBSERVABILITY.md) | Prometheus, Pushgateway, Grafana, DCGM |
| [MLFLOW.md](MLFLOW.md) | Experiment tracking on the iMac |

## Jobs and ML

| Doc | Topic |
|-----|-------|
| [EXECUTION-MODEL.md](EXECUTION-MODEL.md) | Postgres as source of truth, workers, leases |
| [GPU-TRAIN.md](GPU-TRAIN.md) | Default GPU-only training on the RTX 5070 |
| [CNN-FINETUNE.md](CNN-FINETUNE.md) | ResNet18 image classifier fine-tuning |
| [DISTRIBUTED-TRAIN.md](DISTRIBUTED-TRAIN.md) | iMac coordinator + GPU executor |
| [REACTION-VISION.md](REACTION-VISION.md) | Facial-expression model research and design |

## Build phases

| Doc | Phase |
|-----|-------|
| [PHASE-0A.md](PHASE-0A.md) | Job control plane |
| [PHASE-0B.md](PHASE-0B.md) | Leases, retry, `/system/status` |
| [PHASE-1.md](PHASE-1.md) | Inference pipeline (`/chat`) |
| [PHASE-2.md](PHASE-2.md) | RAG |
| [PHASE-3.md](PHASE-3.md) | QLoRA training |
| [PHASE-3-LORA-SERVE.md](PHASE-3-LORA-SERVE.md) | Serve LoRA adapters in Ollama |
| [PHASE-4.md](PHASE-4.md) | Redis job wake |
| [PHASE-5.md](PHASE-5.md) | Observability |
| [PHASE-6.md](PHASE-6.md) | Distributed training + MLflow |

Phase docs describe the system as it was built; later changes (vLLM backend, router, Ubuntu boot)
are in [ARCHITECTURE.md](ARCHITECTURE.md) and the [setup log](SETUP-LOG.md).

## Operations

| Doc | Topic |
|-----|-------|
| [SETUP-LOG.md](SETUP-LOG.md) | Dated change log, newest first |
| [TESTING.md](TESTING.md) | End-to-end checks over Tailscale |
| [BACKUPS.md](BACKUPS.md) | Postgres dumps, checkpoints |
| [GIT.md](GIT.md) | Git workflow for this repo |
