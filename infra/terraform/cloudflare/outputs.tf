output "worker_urls" {
  description = "workers.dev URL of each Worker that has it enabled."
  value       = { for name, w in var.workers : name => "https://${local.worker_hosts[name]}" if w.workers_dev }
}

output "tunnel_ids" {
  description = "Tunnel IDs by name. The run token is not an output: fetch it in the dashboard."
  value       = { for name, t in cloudflare_zero_trust_tunnel_cloudflared.this : name => t.id }
}

output "vpc_service_ids" {
  description = "Workers VPC service IDs, for `vpc_services[].service_id` in wrangler.jsonc."
  value       = { for name, s in cloudflare_connectivity_directory_service.this : name => s.id }
}

output "r2_buckets" {
  description = "R2 buckets managed here."
  value       = keys(cloudflare_r2_bucket.this)
}

output "access_audiences" {
  description = "Access application AUD tags, for ACCESS_AUD in a Worker's wrangler.jsonc."
  value       = { for name, a in cloudflare_zero_trust_access_application.this : name => a.aud }
}
