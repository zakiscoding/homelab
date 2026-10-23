# Network

Design and runtime network layout. Keep in sync with the router, switches, and firewall.

## Overview

```text
[ Internet ]
     |
[ Router / firewall ]  — model: ___________
     |
[ Switch(es) ]
   /    \
[ Host ] [ Wi‑Fi / IoT VLAN ]
```

## Addressing

| VLAN / zone | Subnet | Gateway | DHCP range | Purpose |
|-------------|--------|---------|------------|---------|
| Management | | | | Hosts, iDRAC, Proxmox UI |
| Servers | | | | VMs, Docker |
| Clients | | | | PCs, phones |
| IoT | | | | Untrusted devices |
| Guest | | | | Optional |

## DNS

| Resolver | Where | Notes |
|----------|-------|-------|
| | | e.g. Pi-hole, AdGuard, router |

Internal records: see [Inventory — Domains](INVENTORY.md#domains--dns-internal).

## Firewall & exposure

| Rule / service | WAN exposed? | Port forward / reverse proxy | Notes |
|----------------|--------------|------------------------------|-------|
| Web UI | No (default) | — | Tailscale `100.91.113.98:3080` or `:80` |
| Caddy HTTPS | Yes (optional) | WAN 80, 443 → iMac | Only when `DOMAIN` set — [public-internet.md](deploy/public-internet.md) |
| GPU Ollama | **No** | — | Tailscale `100.88.71.33:11434` only |
| Grafana, Qdrant, Redis, raw API | **No** | — | Tailscale / LAN only |

## VPN / remote access

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| Tailscale | See table below | Tailscale account | Primary remote access |

| Advertised name | IPv4 | Node |
|-----------------|------|------|
| `zakar` | `100.88.71.33` | Dual-boot PC **Windows** boot (`zak_pc`) — Ollama `:11434` when online |
| `zak-gpu-node` | `100.121.51.35` | Dual-boot PC **Ubuntu** boot — CUDA/`~/projects` track |
| `mos-imac` | `100.91.113.98` | iMac — web `:3080`/`:3081` / `:80`; Grafana `:3000` |
| `hp-laptop` | `100.73.132.95` | Controller laptop (`cashh`) |
| `cursor-cloud` | `100.124.163.68` | Cursor cloud VM — **no GPU** |

Ubuntu dual-boot identity and live probe notes: [ubuntu-gpu/infra-inventory.md](ubuntu-gpu/infra-inventory.md).

## Wi‑Fi

| SSID | VLAN | Security | Notes |
|------|------|----------|-------|
| | | | |
