---
description: HITL gate — choose product-docs destination (skip / docs MD / docs repo / Confluence), then write dual-audience docs
---

# /update-docs

Run skill `update-docs`:

1. Write `.cursor/docs-gate.pending`
2. Stop and ask HITL via skill `hitl-choice` (prefer `AskQuestion` buttons). Preset **Docs update destination**:
   - `skip` — no docs this run
   - `docs_md` — Markdown under `docs/` in the current repo
   - `docs_repo` — separate documentation repository (path/URL next)
   - `confluence` — Confluence page (space/parent or URL next)
3. On a non-skip choice, run **style resolution** first (especially for `docs_repo` / `confluence`): match existing house docs, or a human custom style for user and/or engineer audiences; kit dual-audience default only as fallback. Then draft per `skills/update-docs/references/writing-guide.md`, polish with `english-humanizer` without fighting house voice, and publish
4. Clear `.cursor/docs-gate.pending` when done or skipped
