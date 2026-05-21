# Git workflow

**Remote:** `https://github.com/zakiscoding/homelab` (private)

## One-time: publish repo from iMac

`gh` must be logged in as **zakiscoding**:

```bash
gh auth login
cd "/Volumes/1tb drive/homelab"
gh repo create homelab --private --source=. --remote=origin --push
```

If you already created an empty private repo on GitHub:

```bash
git push -u origin main
```

## Clone

**iMac** (already on 1TB drive):

```bash
cd "/Volumes/1tb drive/homelab"
git pull
```

**Windows controller (laptop, user `cashh`):**

```powershell
git clone https://github.com/zakiscoding/homelab.git C:\Users\cashh\homelab
cd C:\Users\cashh\homelab
# Services stack is NOT in this repo — see homelab-services on 1TB drive
# cd "/Volumes/1tb drive/homelab-services"
# copy .env.example .env
```

**GPU PC (user `zakar`, optional second clone):**

```powershell
git clone https://github.com/zakiscoding/homelab.git C:\Users\zakar\homelab
# or sync existing: C:\Users\zakar\HOMELAB
```

Same private repo on both Windows machines — **`cashh`** laptop is the usual place to edit and push; **`zakar`** GPU box is for running Ollama, not required to host the repo.

## Daily workflow

**Rule:** Every documentation change must end with **`git push`** so iMac, laptop (`cashh`), and GPU (`zakar`) stay aligned. Other nodes run `git pull` before work.

```bash
git pull
# ... edit docs or compose ...
git add .
git status   # confirm no secrets
git commit -m "Describe what changed"
git push origin main
```

### After push — on other nodes

| Node | Command |
|------|---------|
| iMac (`momo`) | `cd "/Volumes/1tb drive/homelab" && git pull` |
| Laptop (`cashh`) | `cd C:\Users\cashh\homelab && git pull` |
| GPU (`zakar`, if cloned) | `cd C:\Users\zakar\HOMELAB && git pull` |

### Cursor / agents

When editing homelab docs: **`git pull` first**, then edit, then **`git commit` + `git push`** in the same session. Do not leave commits only on disk.

**GPU PC (`zak_pc`) one-off commit** (if git identity not configured):

```powershell
git -c user.name="zakiscoding" -c user.email="zakiscoding@users.noreply.github.com" commit -m "Your message"
git push origin main
```

## Never commit

- `compose/.env` (use `.env.example` as template)
- Keys, tokens, `secrets/`
