# Resources are split by service: tunnels.tf, vpc_services.tf, workers.tf, r2.tf, access.tf.

locals {
  worker_hosts = {
    for name in keys(var.workers) : name => "${name}.${var.workers_dev_subdomain}.workers.dev"
  }
}
