# Compose stacks

Docker Compose files for the **iMac** services node live here.

Planned layout:

```text
compose/
  docker-compose.yml   # api, postgres, redis
  .env.example         # copy to .env (gitignored)
  api/
    Dockerfile
    main.py
```

Run from iMac:

```bash
cd "/Volumes/1tb drive/homelab/compose"
cp .env.example .env   # edit GPU_URL, passwords
docker compose up -d --build
```
