# Workers VPC services (beta). Each one lets a Worker reach exactly one host:port on the far
# side of a tunnel, with no public hostname. The Worker binds it by ID in wrangler.jsonc,
# so the IDs are outputs.

resource "cloudflare_connectivity_directory_service" "this" {
  for_each = var.vpc_services

  account_id = var.account_id
  name       = each.key
  type       = "http"
  http_port  = each.value.http_port

  host = {
    hostname = each.value.hostname
    resolver_network = {
      tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.this[each.value.tunnel].id
    }
  }
}

import {
  for_each = { for name, s in var.vpc_services : name => s.id if s.id != null }
  to       = cloudflare_connectivity_directory_service.this[each.key]
  id       = "${var.account_id}/${each.value}"
}
