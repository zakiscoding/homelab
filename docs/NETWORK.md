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
| Web UI | No (default) | — | Tailscale `100.91.113.98:3081` or `:80` |
| Caddy HTTPS | Yes (optional) | WAN 80, 443 → iMac | Only when `DOMAIN` set — [public-internet.md](deploy/public-internet.md) |
| GPU Ollama | **No** | — | Tailscale `100.88.71.33:11434` only |
| GPU vLLM, Grafana, Prometheus (Ubuntu boot) | **No** | — | Tailscale `100.121.51.35` only; API key on vLLM |
| SSH / k3s API / kubelet (Ubuntu boot) | **No** | — | ufw blocks 22/6443/10250 on LAN; tailnet only |
| Grafana, Qdrant, Redis, raw API | **No** | — | Tailscale / LAN only |

## VPN / remote access

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| Tailscale | GPU Windows `100.88.71.33`, GPU Ubuntu `100.121.51.35`, iMac `100.91.113.98`, laptop `100.73.132.95` | Tailscale account (Tailscale SSH check mode on the Ubuntu boot) | GPU Ollama `:11434`; GPU vLLM `:8000`; iMac web `:3081` / `:80`; Grafana `:3000` |

## Wi‑Fi

| SSID | VLAN | Security | Notes |
|------|------|----------|-------|
| | | | |
