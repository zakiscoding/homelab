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
| | | | |

## VPN / remote access

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| Tailscale | GPU node `100.88.71.33` | Tailscale account | Ollama `http://100.88.71.33:11434` verified 2026-05-21 |

## Wi‑Fi

| SSID | VLAN | Security | Notes |
|------|------|----------|-------|
| | | | |
