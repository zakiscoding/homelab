# Offline tests: a mocked provider, so no API token or network is needed.
#   terraform init -backend=false && terraform test

mock_provider "cloudflare" {}

# Mock providers cannot import, so imported resources get fixed values instead. This still
# exercises every import block (for_each filters and ID strings) during plan.
override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared.this
  values = { id = "11111111-1111-1111-1111-111111111111" }
}

override_resource {
  target = cloudflare_zero_trust_tunnel_cloudflared_config.this
}

override_resource {
  target = cloudflare_connectivity_directory_service.this
  values = { id = "svc-mock" }
}

override_resource {
  target = cloudflare_workers_script_subdomain.this
}

variables {
  account_id = "00000000000000000000000000000000"
  tunnels = {
    "gpu-pc"   = { id = "11111111-1111-1111-1111-111111111111" }
    "mos-imac" = { id = "22222222-2222-2222-2222-222222222222" }
  }
  vpc_services = {
    "vllm"         = { id = "svc-vllm", tunnel = "gpu-pc", hostname = "vllm", http_port = 8000 }
    "grafana-imac" = { id = "svc-grafana-imac", tunnel = "mos-imac", hostname = "grafana", http_port = 3000 }
    "grafana"      = { id = "svc-grafana", tunnel = "gpu-pc", hostname = "grafana", http_port = 3000 }
  }
  workers = {
    "vllm-gateway"            = {}
    "gpu-systems-lab-results" = {}
    "grafana-proxy"           = { previews_enabled = false }
  }
}

run "live_inventory" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_cloudflared.this) == 2 && length(cloudflare_connectivity_directory_service.this) == 3
    error_message = "Expected 2 tunnels and 3 VPC services."
  }

  assert {
    condition     = alltrue([for c in cloudflare_zero_trust_tunnel_cloudflared_config.this : c.config.ingress[0].service == "http_status:404" && length(c.config.ingress) == 1])
    error_message = "With no published hostnames, each tunnel's only ingress rule is the 404 catch-all."
  }

  assert {
    condition     = cloudflare_workers_script_subdomain.this["grafana-proxy"].previews_enabled == false
    error_message = "grafana-proxy must keep version preview URLs off."
  }

  assert {
    condition     = output.worker_urls["grafana-proxy"] == "https://grafana-proxy.vllm-gateway.workers.dev"
    error_message = "Worker URL is built from the workers.dev subdomain."
  }

  assert {
    condition     = length(cloudflare_r2_bucket.this) == 0 && length(cloudflare_zero_trust_access_application.this) == 0 && length(cloudflare_dns_record.this) == 0
    error_message = "R2, Access and DNS are off by default, matching the account today."
  }
}

run "access_and_r2_when_enabled" {
  command = plan

  variables {
    r2_buckets  = { "gpu-systems-lab-results" = {} }
    access_apps = { "grafana-proxy" = { allowed_emails = ["owner@example.com"] } }
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.this["grafana-proxy"].domain == "grafana-proxy.vllm-gateway.workers.dev"
    error_message = "The Access app protects the Worker's workers.dev host."
  }

  assert {
    condition     = cloudflare_r2_bucket.this["gpu-systems-lab-results"].jurisdiction == "default"
    error_message = "Bucket uses the default jurisdiction."
  }
}

run "rejects_bad_account_id" {
  command = plan

  variables {
    account_id = "not-an-account"
  }

  expect_failures = [var.account_id]
}

run "rejects_tunnel_without_catch_all" {
  command = plan

  variables {
    tunnels = {
      "gpu-pc" = { ingress = [{ hostname = "x.example.com", service = "http://vllm:8000" }] }
    }
    vpc_services = {}
  }

  expect_failures = [var.tunnels]
}

run "custom_domain_needs_zone" {
  command = plan

  variables {
    worker_custom_domains = { "llm.example.com" = { service = "vllm-gateway" } }
  }

  expect_failures = [var.worker_custom_domains]
}
