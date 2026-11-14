# infra: the homelab as code

[homelab](../README.md) / `infra/` · [Architecture](../docs/ARCHITECTURE.md) · [Inventory](../docs/INVENTORY.md) · [Cloudflare edge](../docs/deploy/public-internet.md)

Two pieces, both checked into this public repo with no secrets in them:

| Piece | What it describes | State |
|---|---|---|
| [`terraform/cloudflare/`](terraform/cloudflare) | The Cloudflare edge: tunnels, tunnel ingress, Workers VPC services, each Worker's workers.dev settings, plus optional custom domains, DNS, R2 and Access | Validated, linted and tested offline. **Not yet planned against the real account**: that needs an API token only the owner can create |
| [`ansible/`](ansible) | Node setup for the Linux machines: base packages, Tailscale, Docker, NVIDIA container toolkit, node_exporter, k3s, WSL2 settings, plus a small macOS playbook for the iMac | Linted (production profile) and run twice against throwaway Ubuntu 24.04 containers. **Not yet run against a real node** |

Measured results are in [Results](#results). What only the owner can do is in [What's left](#whats-left).

```text
infra/
├── terraform/cloudflare/
│   ├── versions.tf            Terraform >= 1.10, cloudflare provider 5.29.0 (pinned), S3 backend
│   ├── tunnels.tf             gpu-pc and mos-imac tunnels + ingress rules (catch-all 404 only)
│   ├── vpc_services.tf        Workers VPC services: vllm, grafana-imac, grafana
│   ├── workers.tf             workers.dev / preview URL settings, custom domains, DNS
│   ├── r2.tf  access.tf       R2 buckets and Access apps (empty today)
│   ├── terraform.tfvars.example   live inventory with the IDs blanked out
│   ├── backend.hcl.example        R2 state backend
│   ├── backend_override.tf.example  local state before R2 exists
│   └── tests/plan.tftest.hcl  offline tests with a mocked provider
└── ansible/
    ├── inventory/hosts.yml    real nodes by Tailscale address; inventory/test.yml for containers
    ├── group_vars/            per-group switches (gpu_enabled, k3s_enabled, tailscale_service_enabled ...)
    ├── roles/                 common, tailscale, docker, nvidia_container_toolkit, node_exporter, k3s, wsl
    ├── site.yml  gpu-node.yml  wsl.yml  imac.yml
    └── tests/                 controller + systemd target images, idempotency.sh
```

## Terraform: the Cloudflare edge

### What it owns, and what it leaves to wrangler

The Workers' **code** (scripts, bindings, secrets, Durable Object migrations) stays deployed by
`wrangler deploy` from [gpu-systems-lab](https://github.com/zakiscoding/gpu-systems-lab), after
each Worker's unit tests. Two tools uploading the same script would fight over every deploy.
Terraform owns what surrounds the scripts:

| Resource | Terraform type | Live today (found read-only with wrangler, 2026-11-13) |
|---|---|---|
| Tunnels | `cloudflare_zero_trust_tunnel_cloudflared` | `gpu-pc` (cloudflared in WSL2 on the GPU PC), `mos-imac` (cloudflared on the iMac); both healthy |
| Tunnel ingress | `cloudflare_zero_trust_tunnel_cloudflared_config` | No published hostnames; modelled as the 404 catch-all only (see [limits](#limits)) |
| Workers VPC services | `cloudflare_connectivity_directory_service` | `vllm` → `vllm:8000` on gpu-pc, `grafana-imac` → `grafana:3000` on mos-imac, `grafana` → `grafana:3000` on gpu-pc (no longer bound by any Worker) |
| workers.dev settings | `cloudflare_workers_script_subdomain` | `vllm-gateway`, `grafana-proxy` (preview URLs off), `gpu-systems-lab-results`, all on `*.vllm-gateway.workers.dev` |
| Custom domains, DNS | `cloudflare_workers_custom_domain`, `cloudflare_dns_record` | None: the account has no domain |
| R2 buckets | `cloudflare_r2_bucket` | None: R2 isn't enabled (`wrangler r2 bucket list` returns error 10042) |
| Access apps + policies | `cloudflare_zero_trust_access_application`, `_policy` | None: `grafana-proxy` serves public read-only dashboards by choice |
| KV, D1, Queues | — | None exist (`wrangler kv namespace list`, `d1 list`, `queues list` are empty) |

The empty rows are maps that default to `{}`. Turning one on is a tfvars change, for example
`access_apps = { "grafana-proxy" = { allowed_emails = ["you@example.com"] } }`, and the offline
tests cover that path.

### Adopting the existing resources (import, not recreate)

Every resource has an `import {}` block whose ID is built from tfvars, so the first plan reads the
live objects into state instead of creating new ones. Tunnels and R2 buckets also have
`prevent_destroy`, so a mismatch that would force replacement stops the plan instead of cutting
the gateway off.

```bash
cd infra/terraform/cloudflare
cp terraform.tfvars.example terraform.tfvars      # gitignored
npx wrangler whoami                                # account_id
npx wrangler tunnel list                           # tunnel IDs
npx wrangler vpc service list                      # VPC service IDs
# fill those into terraform.tfvars
```

### State: R2, and the chicken-and-egg

State never goes in the repo (`*.tfstate*`, `.terraform/`, `*.tfvars`, `backend.hcl` are
gitignored). It lives in an R2 bucket through Terraform's S3 backend, with S3-native locking
(`use_lockfile`, a `.tflock` object written with a conditional PUT).

The state bucket can't be created by the configuration whose state it holds, so it is made once,
by hand, and never listed in `r2_buckets`:

1. Enable R2 in the dashboard (it may ask for a payment method; the free tier covers this).
2. `npx wrangler r2 bucket create homelab-tfstate`
3. Create an R2 API token scoped to that one bucket with Object Read & Write. Keep the key pair in
   your shell or password manager, never in a file in the repo:

   ```bash
   export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...
   cp backend.hcl.example backend.hcl                # set <ACCOUNT_ID> in the endpoint
   terraform init -backend-config=backend.hcl
   ```

Until R2 is enabled, keep state on local disk outside the repo:
`cp backend_override.tf.example backend_override.tf` (gitignored) and `terraform init`. Later,
delete the override and run `terraform init -migrate-state -backend-config=backend.hcl`.

### Running it

Terraform isn't installed on the laptop; the pinned containers are used instead.

```bash
cd infra/terraform/cloudflare
TF="docker run --rm -it -v $PWD:/w -w /w -e CLOUDFLARE_API_TOKEN -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY hashicorp/terraform:1.17.2"
$TF fmt -check -recursive
$TF init -backend=false && $TF validate && $TF test        # offline, no token
docker run --rm -v $PWD:/data -w /data ghcr.io/terraform-linters/tflint:v0.66.0 --init
docker run --rm -v $PWD:/data -w /data ghcr.io/terraform-linters/tflint:v0.66.0
# with a token and a backend:
$TF init -backend-config=backend.hcl
$TF plan                                                    # expect only imports
```

The API token needs, on this account only: **Cloudflare Tunnel: Edit**, **Connectivity Directory
(Workers VPC): Edit**, **Workers Scripts: Edit**, and later **Workers R2 Storage: Edit**,
**Access: Apps and Policies: Edit** and **Zone DNS: Edit** when those maps are used. Read-only
variants are enough for a first plan.

## Ansible: node setup

### What runs where

| Playbook | Hosts | Roles | How it connects |
|---|---|---|---|
| `gpu-node.yml` | `zak-gpu-node` (Ubuntu boot, 100.121.51.35) | common, tailscale (`--ssh`), docker, nvidia_container_toolkit, k3s | SSH as `zak` over the tailnet (Tailscale SSH) |
| `wsl.yml` | `zak-pc-wsl` (Ubuntu in WSL2, Windows boot) | wsl, common, tailscale (installed, service off), docker, nvidia_container_toolkit | `ansible_connection: local`, run inside the distro |
| `imac.yml` | `mos-imac` (100.91.113.98) | Homebrew formulae, Colima status check | SSH as `momo` |
| `site.yml` | all of the above | imports the three | offline hosts are reported unreachable |

Choices that follow the docs rather than a generic setup:

- **One OS at a time.** The GPU PC is either `zak-gpu-node` or `zak_pc`; `site.yml` copes with
  one of them being unreachable.
- **WSL is driven from inside.** `ssh zak-ts` lands in `cmd.exe`, which Ansible can't use, so
  `wsl.yml` runs in the distro against itself. The `wsl` role sets `systemd=true` in
  `/etc/wsl.conf` and `vmIdleTimeout=-1` in the Windows user's `.wslconfig` through `/mnt/c`. The
  `WSL Keep Alive` scheduled task is Windows-side and stays a manual step
  ([gpu-systems-lab cloudflare/README](https://github.com/zakiscoding/gpu-systems-lab/blob/main/cloudflare/README.md#wsl2-on-the-windows-boot)).
- **Tailscale is off inside WSL.** Windows' own Tailscale forwards WSL's ports with
  `tailscale serve`, and a second node from WSL joined the wrong tailnet before.
- **Tailscale auth key** comes from `TS_AUTHKEY` in the environment (or a vault file outside the
  repo), is only used when the node isn't logged in, and the task is `no_log`.
- **node_exporter** is off on both GPU hosts, because the `obs-node-exporter` container in
  gpu-systems-lab already covers them. The role binds to `127.0.0.1:9100` by default (never
  `0.0.0.0`) and is turned on in the container test.
- **k3s** is pinned to `v1.36.5+k3s1` (the version on the node), sets `tls-san` to the tailnet IP
  and name, and makes `nvidia` the default containerd runtime on GPU hosts. The NVIDIA device
  plugin and the GPU admission policy stay in
  [gpu-systems-lab `scheduling/`](https://github.com/zakiscoding/gpu-systems-lab).
- **The NVIDIA driver isn't managed.** The Ubuntu boot runs 595.99.02 and WSL uses the Windows
  driver; the role only adds the container toolkit and registers the `nvidia` runtime in
  `/etc/docker/daemon.json`, keeping any other settings there.
- **Unattended upgrades** are limited to security origins and never reboot.

### macOS

`imac.yml` is deliberately small. On the iMac, Ansible can install Homebrew formulae and read
state, but the parts that matter are not good Ansible targets: Colima's VM lives on an external
drive (`COLIMA_HOME` on `/Volumes/1tb drive`) that has to be mounted first, the stack is started
by `homelab-services/scripts/start-stack.sh` with its own config sync scripts, and macOS
permissions prompts (Full Disk Access, login items) need someone at the screen. The playbook
installs `colima`, `docker` and `docker-compose` and reports whether Colima is running.

### Running it

```bash
cd infra/ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook gpu-node.yml --check --diff          # dry run first, always
ansible-playbook gpu-node.yml
# in the WSL distro, from a clone of this repo:
ansible-playbook -l zak-pc-wsl wsl.yml --check --diff --ask-become-pass
```

Ansible isn't installed on the Windows laptop either; [tests/Containerfile.controller](ansible/tests/Containerfile.controller)
builds a controller image with pinned `ansible-core 2.21.5`, `ansible-lint 26.10.1`,
`community.general 14.0.1` and `community.docker 5.4.0`.

### Testing against a throwaway container

```bash
cd infra/ansible
docker build -t homelab-iac/ansible-controller:test -f tests/Containerfile.controller .
docker build -t homelab-iac/ubuntu-systemd:24.04  -f tests/Containerfile.target .
for n in iac-test-ubuntu iac-test-wsl; do
  docker run -d --name $n --hostname $n --privileged --cgroupns=host \
    --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:rw homelab-iac/ubuntu-systemd:24.04
done
RUN="docker run --rm -v $PWD:/work -v /var/run/docker.sock:/var/run/docker.sock homelab-iac/ansible-controller:test"
$RUN bash tests/idempotency.sh gpu-node.yml iac-test-ubuntu
$RUN bash tests/idempotency.sh wsl.yml iac-test-wsl
docker rm -f iac-test-ubuntu iac-test-wsl
```

`inventory/test.yml` puts the containers in the real `gpu_ubuntu` and `wsl` groups, so they get
the real group_vars, and overrides only `gpu_enabled: false` and `k3s_enabled: false` (no GPU, and
k3s inside a container says little about the node). The script fails unless the second run
reports `changed=0`.

## Results

Measured on 2026-11-13 on the Windows laptop, in Docker Desktop (Linux containers). Times are wall
clock and include container start-up, which costs about 12 s per command there.

**Terraform** (`hashicorp/terraform:1.17.2`, provider `cloudflare/cloudflare 5.29.0`, `tflint v0.66.0`):

| Check | Result | Time |
|---|---|---|
| `terraform fmt -check -recursive` | clean | 4 s |
| `terraform init -backend=false` | provider 5.29.0 installed; lockfile has hashes for linux_amd64, linux_arm64, windows_amd64, darwin_arm64 | — |
| `terraform validate` | `Success! The configuration is valid.` | 50 s |
| `terraform test` (mocked provider) | `5 passed, 0 failed`: live inventory plans with every import block evaluated; R2 + Access turned on; bad account ID, a tunnel with no catch-all rule, and a custom domain with no zone are all rejected | 36 s |
| `tflint` (terraform ruleset, `preset = "all"`) | 0 issues (the one earlier finding, no `main.tf`, was fixed) | 6 s |

**Ansible** (`ansible-core 2.21.5`, `ansible-lint 26.10.1`):

| Check | Result | Time |
|---|---|---|
| `ansible-lint` (production profile) | `Passed: 0 failure(s), 0 warning(s) in 47 files`. The first pass found 6 (apt-cache refresh tasks that should have been handlers, a debug task, a missing file mode, a lowercase play name); all fixed rather than skipped, except one `noqa` on the `.wslconfig` task, because `/mnt/c` ignores chmod | 385 s |
| `ansible-playbook --syntax-check` | `site.yml`, `gpu-node.yml`, `wsl.yml`, `imac.yml` against the real inventory, and the first two against the test inventory: all pass | 107 s for all six |

Idempotency, each against a fresh `ubuntu:24.04` systemd container:

| Playbook → container | Run 1 | Run 2 |
|---|---|---|
| `gpu-node.yml` → `iac-test-ubuntu` | `ok=20 changed=16 failed=0 skipped=13`, 581 s | `ok=18 changed=0 failed=0 skipped=14`, 337 s |
| `wsl.yml` → `iac-test-wsl` | `ok=14 changed=10 failed=0 skipped=14`, 515 s | `ok=13 changed=0 failed=0 skipped=14`, 365 s |

The first attempt failed on its first repository task (`python3-debian` missing, which
`deb822_repository` needs), so it's now in the base packages. After the second run, inside
`iac-test-ubuntu`: `docker`, `tailscaled` and `node_exporter` were active, Docker was 29.9.3,
Tailscale 1.104.7 (not logged in), node_exporter on `127.0.0.1:9100` served 724 `node_*` series,
and the timezone was `America/Toronto` (a test value; real nodes keep theirs). In `iac-test-wsl`,
`/etc/wsl.conf` had `systemd = true`, Docker was active and `tailscaled` was disabled and stopped,
as on the real distro. `unattended-upgrades` is enabled but shows inactive: on Ubuntu the apt
timers do the upgrading, and the service only runs at shutdown.

Runs are slow because the Docker API connection opens a new exec for every module, and run 1
downloads Docker, Tailscale and node_exporter.

## Limits

- **No real plan yet.** Validation, lint and tests run without credentials. Whether the import
  produces zero diff is unknown until the owner runs `terraform plan` with a token.
- **Tunnel ingress is inferred, not read.** The OAuth login wrangler uses has no scope for reading
  a tunnel's configuration, so the ingress (404 catch-all only) comes from the docs ("no public
  hostnames", "keep the catch-all at 404"). If the live config differs, the first plan shows it as
  an update; adjust `tunnels.<name>.ingress` to match before applying.
- **Preview URL flags are partly inferred.** `grafana-proxy` sets `preview_urls = false` in its
  wrangler.jsonc; the other two use wrangler's default, modelled here as enabled.
- **`config_src` is assumed `cloudflare`** (remotely managed) for both tunnels. `gpu-pc` was made
  in the dashboard as a remotely managed tunnel; `mos-imac`'s origin isn't recorded.
- **Workers VPC is in beta**, and so is its Terraform resource; field names may change.
- **The account-wide workers.dev subdomain** (`vllm-gateway`) has no resource in provider 5.29.0,
  so it is an input, not managed.
- **Ansible on real nodes is untested.** The container runs skip the GPU tasks (toolkit, Docker's
  nvidia runtime, k3s) and Tailscale login. The WSL test runs in a plain container, not WSL, so
  the `.wslconfig` task is skipped there. `imac.yml` is linted and syntax-checked only.
- **Ubuntu 26.04 in WSL.** The WSL distro is 26.04; Docker's, NVIDIA's and Tailscale's apt
  repositories are keyed on the release codename, and only 24.04 was tested.

## What's left

| Task | Who | Notes |
|---|---|---|
| Create a scoped Cloudflare API token | Owner | Scopes above; this account only. Never commit it: `export CLOUDFLARE_API_TOKEN=...` |
| Fill `terraform.tfvars` from `wrangler whoami / tunnel list / vpc service list` | Owner | Already filled in the laptop's gitignored copy |
| Pick a state location | Owner | Local override now, or enable R2 and create `homelab-tfstate` with wrangler |
| `terraform plan`: confirm only imports and zero changes | Owner | Fix any ingress or preview-URL drift in tfvars, then `apply` to record the imports |
| Retire the unused `grafana` VPC service on gpu-pc | Owner | Drop it from tfvars after the import, then apply |
| `ansible-playbook gpu-node.yml --check --diff` on the Ubuntu boot | Owner | Next time the PC is on Ubuntu |
| `wsl.yml --check --diff` inside WSL | Owner | Needs a clone of this repo and Ansible in the distro |
| Wire the offline checks into CI | Whoever owns `.github/workflows` | `terraform fmt/validate/test`, tflint, ansible-lint |
