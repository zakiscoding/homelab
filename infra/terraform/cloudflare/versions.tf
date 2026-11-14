terraform {
  # 1.10+ for S3-native state locking (use_lockfile), which works on R2.
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.29.0"
    }
  }

  # Partial configuration: the bucket, key and R2 endpoint come from a gitignored
  # backend.hcl (see backend.hcl.example), and the R2 access key from the environment.
  # Before R2 is enabled, use backend_override.tf.example to keep state on local disk
  # outside the repo.
  backend "s3" {}
}
