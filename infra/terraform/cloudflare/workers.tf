# The Worker scripts (code, bindings, secrets, Durable Object migrations) are deployed by
# wrangler from gpu-systems-lab, after their unit tests. Terraform does not upload code; it owns
# the routing around each script: its workers.dev URL, preview URLs, custom domains and DNS.

resource "cloudflare_workers_script_subdomain" "this" {
  for_each = var.workers

  account_id       = var.account_id
  script_name      = each.key
  enabled          = each.value.workers_dev
  previews_enabled = each.value.previews_enabled
}

import {
  for_each = var.workers
  to       = cloudflare_workers_script_subdomain.this[each.key]
  id       = "${var.account_id}/${each.key}"
}

resource "cloudflare_workers_custom_domain" "this" {
  for_each = var.worker_custom_domains

  account_id = var.account_id
  zone_id    = var.zone_id
  hostname   = each.key
  service    = each.value.service
}

import {
  for_each = { for host, d in var.worker_custom_domains : host => d.import_id if d.import_id != null }
  to       = cloudflare_workers_custom_domain.this[each.key]
  id       = "${var.account_id}/${each.value}"
}

resource "cloudflare_dns_record" "this" {
  for_each = var.dns_records

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = each.value.ttl
  comment = each.value.comment
}

import {
  for_each = { for k, r in var.dns_records : k => r.import_id if r.import_id != null }
  to       = cloudflare_dns_record.this[each.key]
  id       = "${var.zone_id}/${each.value}"
}
