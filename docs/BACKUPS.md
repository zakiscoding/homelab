# Backups

Homelab data that must survive disk failure or accidental deletes.

## What to back up

| Data | Location | Tool | Frequency |
|------|----------|------|-----------|
| Postgres (chat logs) | iMac `homelab-services/data/postgres` | `pg_dump` | Daily |
| Qdrant vectors | `homelab-services/data/qdrant` | Volume snapshot or `restic` | Weekly |
| Grafana dashboards | `homelab-services/data/grafana` | `restic` | Weekly |
| GPU checkpoints | `D:\homelab-data\checkpoints` (GPU PC) | External drive / cloud | After each train |
| 1TB drive docs | `homelab/`, `homelab-services/` git | GitHub (already) | Every push |

## iMac — Postgres dump (manual)

On iMac (`momo`), with stack running:

```bash
cd "/Volumes/1tb drive/homelab-services"
source ./scripts/docker-1tb-env.sh
mkdir -p backups
docker-compose exec -T postgres pg_dump -U "${POSTGRES_USER:-homelab}" "${POSTGRES_DB:-homelab}" \
  > "backups/homelab-$(date +%Y%m%d).sql"
```

Copy `backups/*.sql` to external storage or cloud. **Do not commit** dumps to git.

## iMac — automated script

In `homelab-services` repo: `scripts/backup-postgres.sh` (run via cron or launchd).

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ./scripts/docker-1tb-env.sh
mkdir -p backups
FILE="backups/homelab-$(date +%Y%m%d-%H%M).sql"
docker-compose exec -T postgres pg_dump -U "${POSTGRES_USER:-homelab}" "${POSTGRES_DB:-homelab}" > "$FILE"
find backups -name 'homelab-*.sql' -mtime +14 -delete
echo "Wrote $FILE"
```

## GPU PC — checkpoints

Checkpoints live under `CHECKPOINT_DIR` (default `D:\homelab-data\checkpoints`). Copy to USB or cloud after training; they are too large for GitHub.

## Restic (optional, all nodes)

Install [restic](https://restic.net/) on iMac; backup `homelab-services/data/` and `backups/` to S3/B2/another machine. Document bucket name in [ACCESS.md](ACCESS.md), not in git.

## Restore smoke test

Quarterly: restore latest `pg_dump` to a test DB container and confirm row counts.

Log backup runs in [SETUP-LOG.md](SETUP-LOG.md).
