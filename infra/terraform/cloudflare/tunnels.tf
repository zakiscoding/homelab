# Cloudflare Tunnels. cloudflared runs as a container on each node with a run token
# (TUNNEL_TOKEN in a mode-600 .env on that node). Terraform never reads or outputs that token.

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  for_each = var.tunnels

  account_id = var.account_id
  name       = each.key
  config_src = each.value.config_src

  lifecycle {
    # Replacing a tunnel would invalidate the run token on the node and drop the gateway.
    prevent_destroy = true
    # Write-only on the API: absent after import, and not needed for remotely managed tunnels.
    ignore_changes = [tunnel_secret]
  }
}

import {
  for_each = { for name, t in var.tunnels : name => t.id if t.id != null }
  to       = cloudflare_zero_trust_tunnel_cloudflared.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  for_each = var.tunnels

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[each.key].id

  config = {
    ingress = [
      for rule in each.value.ingress : {
        hostname = rule.hostname
        path     = rule.path
        service  = rule.service
      }
    ]
  }
}

import {
  for_each = { for name, t in var.tunnels : name => t.id if t.id != null }
  to       = cloudflare_zero_trust_tunnel_cloudflared_config.this[each.key]
  id       = "${var.account_id}/${each.value}"
}
