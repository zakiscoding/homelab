# Access & secrets

Where authentication lives — **never** commit passwords, API keys, or private keys to this repo.

## Secret storage

| Secret type | Stored in | Recovery |
|-------------|-----------|----------|
| Router admin | | |
| Hypervisor | | |
| SSH keys | | |
| TLS private keys | | |
| App API tokens | | |

## SSH

| Host | User | Key location | Port | Notes |
|------|------|--------------|------|-------|
| GPU PC (`zak_pc`) | **`zakar`** | _TBD_ | 22 | From laptop **`cashh`**: `ssh zakar@100.88.71.33` |
| iMac (`Mos-iMac`) | **`momo`** | _TBD_ | 22 | |
| Controller | **`cashh`** | — | — | Laptop; initiates SSH |

## Admin UIs

| System | URL | Account notes |
|--------|-----|---------------|
| | | |

## Backup encryption

| What | Key / passphrase location |
|------|---------------------------|
| | |

## `.gitignore` reminder

If we add env files or keys locally, keep them ignored:

```gitignore
.env
.env.*
*.pem
*.key
secrets/
```
