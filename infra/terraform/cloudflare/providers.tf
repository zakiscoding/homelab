# Authenticates with the CLOUDFLARE_API_TOKEN environment variable. Never put the token in
# a .tf or .tfvars file. Scopes needed are listed in infra/README.md.
provider "cloudflare" {}
