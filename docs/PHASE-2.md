# Phase 2 — RAG pipeline

**Status:** Deploy in progress (2026-05-21)  
**Prerequisite:** [Phase 1](PHASE-1.md).

## Goal

Ingest text → chunk → embed (iMac worker) → Qdrant → `/rag/query` with citations.

```text
POST /rag/ingest → ingest job → chunks in Postgres
                 → embed job  → vectors in Qdrant (coll_v1_minilm_l6)
POST /rag/query  → retrieve → Ollama → answer + citations
```

## What ships

| Component | Location |
|-----------|----------|
| Schema | `postgres/005_phase2_rag.sql` |
| RAG API | `api/rag_routes.py`, `rag_engine.py`, `rag_store.py` |
| iMac worker | `worker/poll_imac.py` (Docker service `imac-worker`) |
| Collection alias | Postgres `collection_aliases` name=`active` |
| Cache | Redis `rag:{collection_version}:{query_hash}` |
| Failure: no context | `answer: null`, `reason: "no_context"` |

## Deploy (iMac)

```bash
ssh imac-ts
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
source /Volumes/1tb\ drive/homelab-services/scripts/docker-1tb-env.sh
cd /Volumes/1tb\ drive/homelab-services
git pull
chmod +x scripts/migrate-phase2.sh
POSTGRES_USER=app ./scripts/migrate-phase2.sh
docker-compose up -d --build api imac-worker
```

First embed run downloads MiniLM (~90MB) inside `imac-worker`.

## Smoke test (laptop)

```powershell
$key = "YOUR_API_KEY"
$h = @{ "x-api-key" = $key; "Content-Type" = "application/json" }

# Ingest
$ing = @{ text = "The homelab GPU is zak_pc with an RTX 5070. The iMac runs Postgres and Qdrant."; source_id = "smoke-1" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98/rag/ingest" -Method Post -Headers $h -Body $ing

# Wait ~30–60s for imac-worker (ingest + embed), then:
$q = @{ query = "What GPU does the homelab use?"; model = "llama3.2:latest" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "http://100.91.113.98/rag/query" -Method Post -Headers $h -Body $q
```

## API

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/rag/ingest` | Queue ingest (+ optional embed) jobs |
| POST | `/rag/query` | RAG answer with citations |
| GET | `/rag/status` | Active collection alias |
| POST | `/internal/worker/jobs/claim-imac` | iMac worker claim |

## Failure modes (v1)

| Case | Behavior |
|------|----------|
| No chunks above score threshold | `no_context`, job succeeded |
| Qdrant down | 503 `qdrant_error` |
| Embed model / collection change | New `collection_version` + manual alias update (v2 automates) |
| Stale cache | Purged on embed job success |

Spec detail: [services/rag.md](services/rag.md).

## Next: Phase 3

Real QLoRA training via GPU worker, artifact publish to ML-STORE, `experiments` linkage.
