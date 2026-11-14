variable "account_id" {
  description = "Cloudflare account ID. Not a secret, but kept out of the repo: set it in terraform.tfvars."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32-character hex Cloudflare account ID."
  }
}

variable "workers_dev_subdomain" {
  description = "The account's workers.dev subdomain (<name>.workers.dev). Used only to build URLs and the Access domain."
  type        = string
  default     = "vllm-gateway"
}

# ---------------------------------------------------------------------------
# Cloudflare Tunnels
# ---------------------------------------------------------------------------

variable "tunnels" {
  description = <<-EOT
    Remotely managed Cloudflare Tunnels, keyed by tunnel name. `id` is the existing tunnel's
    UUID (from `wrangler tunnel list`) and is only used to import it; leave it null to create
    a new tunnel. `ingress` is the tunnel's published-application rules, evaluated in order;
    the last rule must be a catch-all. The homelab publishes no hostnames: Workers reach the
    origins through Workers VPC services instead, so the default is only the 404 catch-all.
  EOT
  type = map(object({
    id         = optional(string)
    config_src = optional(string, "cloudflare")
    ingress = optional(list(object({
      hostname = optional(string)
      path     = optional(string)
      service  = string
    })), [{ service = "http_status:404" }])
  }))

  validation {
    condition = alltrue([
      for t in values(var.tunnels) : t.ingress[length(t.ingress) - 1].hostname == null && t.ingress[length(t.ingress) - 1].path == null
    ])
    error_message = "The last ingress rule of every tunnel must be a catch-all (no hostname or path)."
  }
}

# ---------------------------------------------------------------------------
# Workers VPC services (Connectivity directory)
# ---------------------------------------------------------------------------

variable "vpc_services" {
  description = <<-EOT
    Workers VPC services: one private HTTP origin behind a tunnel, bound to a Worker with a
    `vpc_services` entry in its wrangler.jsonc. `tunnel` is a key of var.tunnels. `id` is the
    existing service's ID (from `wrangler vpc service list`), used only to import it.
  EOT
  type = map(object({
    id        = optional(string)
    tunnel    = string
    hostname  = string
    http_port = number
  }))
}

# ---------------------------------------------------------------------------
# Workers: the scripts are deployed by wrangler; Terraform owns what surrounds them.
# ---------------------------------------------------------------------------

variable "workers" {
  description = <<-EOT
    Workers deployed by wrangler from gpu-systems-lab. Terraform manages only their workers.dev
    setting (enabled, and whether version preview URLs are on). Keep these in sync with
    `workers_dev` / `preview_urls` in each wrangler.jsonc, because wrangler sets the same flags
    on every deploy.
  EOT
  type = map(object({
    workers_dev      = optional(bool, true)
    previews_enabled = optional(bool, true)
  }))
}

variable "zone_id" {
  description = "Zone ID of a custom domain on this account. Null today: the homelab has no domain and everything is on workers.dev."
  type        = string
  default     = null
}

variable "worker_custom_domains" {
  description = "Custom domains for Workers, keyed by hostname, value = Worker name. Needs zone_id. `import_id` adopts an existing one."
  type = map(object({
    service   = string
    import_id = optional(string)
  }))
  default = {}

  validation {
    condition     = length(var.worker_custom_domains) == 0 || var.zone_id != null
    error_message = "worker_custom_domains needs zone_id."
  }
}

variable "dns_records" {
  description = "DNS records in zone_id, keyed by a stable label. Empty today (no zone). `import_id` adopts an existing record."
  type = map(object({
    name      = string
    type      = string
    content   = string
    proxied   = optional(bool, true)
    ttl       = optional(number, 1)
    comment   = optional(string)
    import_id = optional(string)
  }))
  default = {}

  validation {
    condition     = length(var.dns_records) == 0 || var.zone_id != null
    error_message = "dns_records needs zone_id."
  }
}

# ---------------------------------------------------------------------------
# R2
# ---------------------------------------------------------------------------

variable "r2_buckets" {
  description = <<-EOT
    R2 buckets this config owns, keyed by bucket name. Empty until R2 is enabled on the
    account (a dashboard step). The Terraform state bucket is deliberately NOT listed here:
    it is created once with wrangler so that this config never manages its own backend.
  EOT
  type = map(object({
    location     = optional(string)
    jurisdiction = optional(string, "default")
    import       = optional(bool, false)
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Zero Trust Access
# ---------------------------------------------------------------------------

variable "access_apps" {
  description = <<-EOT
    Cloudflare Access self-hosted applications in front of Workers, keyed by Worker name, each
    with one allow-by-email policy. Empty today: grafana-proxy serves read-only public
    dashboards by choice and has no Access app. `app_id` / `policy_id` adopt existing ones.
  EOT
  type = map(object({
    allowed_emails   = list(string)
    session_duration = optional(string, "24h")
    app_id           = optional(string)
    policy_id        = optional(string)
  }))
  default = {}
}
