---
description: HITL gate — choose product-docs destination (skip / docs MD / docs repo / Confluence), then write dual-audience docs
---

# /csp-update-docs

Run skill `update-docs`:

1. Resolve the plan path, then write `.cursor/gates/docs-gate/<slug>` (line 1 = plan path) via `pg_write_gate docs-gate`.
2. Stop and ask HITL via skill `hitl-choice` (AskQuestion required; text only after failed/missing tool). Preset **Docs update destination**:
   - `skip` — no docs this run
   - `docs_md` — Markdown under `docs/` in the current repo
   - `docs_repo` — separate documentation repository (path/URL next)
   - `confluence` — Confluence page (space/parent or URL next)
3. On a non-skip choice, run **style resolution** first (especially for `docs_repo` / `confluence`): match existing house docs, or a human custom style for user and/or engineer audiences; kit dual-audience default only as fallback. Then draft per `skills/update-docs/references/writing-guide.md`, polish with `english-humanizer` without fighting house voice, and publish
4. Clear this plan's `.cursor/gates/docs-gate/<slug>` when done or skipped. Do not delete another slug's docs-gate without HITL `force-clear`.
