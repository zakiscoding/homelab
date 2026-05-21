# 1TB drive layout

Canonical paths on the iMac external volume **`/Volumes/1tb drive`**.

## Top level

```text
/Volumes/1tb drive/
├── README.md                 ← this index (not in homelab git)
├── homelab/                  ← git: documentation
├── homelab-services/         ← git: iMac Docker stack
├── homelab-gpu/              ← git: GPU training (mirror; also on zak_pc)
├── homelab-runtime/          ← Colima + docker CLI (not git)
│   ├── colima/               ← COLIMA_HOME
│   └── docker-config/        ← DOCKER_CONFIG
├── Personal/                 ← school, resumes, misc (not homelab)
│   ├── School/
│   ├── Resumes/
│   ├── Screenshots/
│   └── Projects/
├── Desktop/                  ← macOS (unchanged)
└── Documents/                ← macOS (unchanged)
```

## Homelab repos (git)

| Directory | Remote | Never put here |
|-----------|--------|----------------|
| `homelab/` | `zakiscoding/homelab` | Docker compose, `.env`, service code |
| `homelab-services/` | `zakiscoding/homelab-services` | Long markdown runbooks (use `homelab/docs`) |
| `homelab-gpu/` | `zakiscoding/homelab-gpu` | Checkpoints, datasets, Ollama models |

## Runtime (not git)

| Directory | Env var | Purpose |
|-----------|---------|---------|
| `homelab-runtime/colima/` | `COLIMA_HOME` | Colima VM disk, Docker socket |
| `homelab-runtime/docker-config/` | `DOCKER_CONFIG` | Compose plugin path |

Service **data** (Postgres, Redis, etc.) stays in `homelab-services/data/`.

## Symlinks on iMac

| Link | Target |
|------|--------|
| `~/1tb-drive` | `/Volumes/1tb drive` |
| `~/homelab` | `/Volumes/1tb drive/homelab` |

Use `~/1tb-drive/homelab-services` when Colima bind mounts dislike spaces in the volume name.

## GPU PC paths (not on this drive)

| Path | Repo |
|------|------|
| `C:\Users\zakar\homelab-gpu` | Training code |
| Local disk | Ollama models, checkpoints, datasets |

## Controller laptop

| Path | Repo |
|------|------|
| `C:\Users\cashh\homelab` | Docs clone |
| `C:\Users\cashh\homelab-services` | Optional services clone |

## Adding new homelab files

1. **Documentation** → edit under `homelab/docs/`, commit in `homelab` repo.
2. **iMac services** → edit `homelab-services/`, commit there.
3. **GPU training** → edit `homelab-gpu/` on `zak_pc` (or mirror on 1TB), commit there.
4. **Do not** add loose homelab files at the volume root — use the folders above.

Log structural changes in [SETUP-LOG](SETUP-LOG.md).
