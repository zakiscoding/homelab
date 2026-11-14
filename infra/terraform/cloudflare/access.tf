# Cloudflare Access in front of a Worker's workers.dev URL: one reusable allow policy per app.
# Not in use today (grafana-proxy serves public, read-only dashboards); kept so that putting a
# login back in front of it is a tfvars change.

resource "cloudflare_zero_trust_access_policy" "allow_emails" {
  for_each = var.access_apps

  account_id       = var.account_id
  name             = "${each.key}: allow listed emails"
  decision         = "allow"
  session_duration = each.value.session_duration

  include = [for email in each.value.allowed_emails : { email = { email = email } }]
}

import {
  for_each = { for name, a in var.access_apps : name => a.policy_id if a.policy_id != null }
  to       = cloudflare_zero_trust_access_policy.allow_emails[each.key]
  id       = "${var.account_id}/${each.value}"
}

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = var.access_apps

  account_id       = var.account_id
  name             = each.key
  type             = "self_hosted"
  domain           = local.worker_hosts[each.key]
  session_duration = each.value.session_duration

  # The Worker validates the Cf-Access-Jwt-Assertion header against this app's AUD.
  policies = [{
    id         = cloudflare_zero_trust_access_policy.allow_emails[each.key].id
    precedence = 1
  }]
}

import {
  for_each = { for name, a in var.access_apps : name => a.app_id if a.app_id != null }
  to       = cloudflare_zero_trust_access_application.this[each.key]
  id       = "accounts/${var.account_id}/${each.value}"
}
