# R2 buckets for data (raw benchmark results). R2 isn't enabled on the account yet, so the map
# is empty in terraform.tfvars.example's live section.

resource "cloudflare_r2_bucket" "this" {
  for_each = var.r2_buckets

  account_id   = var.account_id
  name         = each.key
  location     = each.value.location
  jurisdiction = each.value.jurisdiction

  lifecycle {
    prevent_destroy = true
  }
}

import {
  for_each = { for name, b in var.r2_buckets : name => b if b.import }
  to       = cloudflare_r2_bucket.this[each.key]
  id       = "${var.account_id}/${each.key}/${each.value.jurisdiction}"
}
