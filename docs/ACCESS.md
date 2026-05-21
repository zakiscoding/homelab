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
| | | | 22 | |

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
