# RAG service

Phase 2 homelab RAG — engineered behavior, not ad-hoc scripts.

## Stack

| Piece | Role |
|-------|------|
| Postgres `rag_documents` / `rag_chunks` | Canonical text + chunk registry |
| `collection_aliases` | SSOT for active Qdrant collection (`active` → `coll_v1_minilm_l6`) |
| Qdrant | Vector search (cosine, 384-d MiniLM) |
| `imac-worker` | Executes `ingest` + `embed` jobs |
| FastAPI | `/rag/ingest`, `/rag/query` (sync executor for query) |
| Redis | Query result cache keyed by `collection_version` + query hash |
| LLM (GPU PC) | Generation only: vLLM on the Ubuntu boot, Ollama on the Windows boot (`LLM_BACKEND=auto`) |

## Ingest flow

1. `POST /rag/ingest` with `{ "text", "source_id?", "auto_embed": true }`
2. API inserts `rag_documents` (dedupe by `content_sha256`)
3. API creates `ingest` job (`payload.document_id`)
4. If new doc, API creates `embed` job
5. iMac worker claims `ingest` → chunks (400 chars, 50 overlap) → `rag_chunks`
6. iMac worker claims `embed` → FastEmbed → Qdrant upsert by `chunk_id`
7. On embed success, Redis keys `rag:{version}:*` purged

## Query flow

1. `POST /rag/query` with `{ "query", "model?", "top_k?" }`
2. Check Redis cache
3. Create `rag_query` job (observability)
4. Load `collection_aliases.active`
5. Embed query + Qdrant search
6. Filter hits with `score < 0.35` → `no_context`
7. Build prompt with top chunks → LLM backend (vLLM or Ollama, via `api/llm.py`)
8. Return `answer`, `citations[]`, `job_id`

## Chunk schema (v1)

| Field | Value |
|-------|--------|
| `chunk_id` | UUID (Qdrant point id) |
| `document_id` | Parent doc |
| `chunk_index` | 0..n |
| `collection_version` | e.g. `v1_minilm_l6` |
| `embedded_at` | NULL until embed job |

## Failure modes

| Failure | Detection | Behavior |
|---------|-----------|----------|
| Embedding model change | Config ≠ collection metadata | Operator creates new `collection_version`, re-embed, update alias |
| Qdrant down | `/readyz` fail | 503; no cache write |
| Stale cache | Embed success hook | Delete `rag:{version}:*` |
| Empty retrieval | score < threshold | 200, `reason: no_context` |
| Ollama fail after retrieval | HTTP 5xx | `rag_query` job failed, 502 |

## Governance (Phase 2 v1)

- Ingest writes only via API (`rag_documents`)
- GPU node does not write Qdrant or `rag_*` tables
- Workers update job status only through internal API routes

Full rules: `DATA-GOVERNANCE.md` (Phase 3 doc).
