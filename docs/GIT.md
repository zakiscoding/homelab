# Git workflow

**Remote:** `https://github.com/zakiscoding/homelab` (private)

## Clone

**iMac** (already on 1TB drive):

```bash
cd "/Volumes/1tb drive/homelab"
git pull
```

**Windows controller:**

```powershell
git clone https://github.com/zakiscoding/homelab.git C:\Users\cashh\homelab
cd C:\Users\cashh\homelab
copy compose\.env.example compose\.env
# edit compose\.env with real secrets (never commit .env)
```

## Daily workflow

```bash
git pull
# ... edit docs or compose ...
git add .
git commit -m "Describe what changed"
git push
```

## Never commit

- `compose/.env` (use `.env.example` as template)
- Keys, tokens, `secrets/`
