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
3. On a non-skip choice, draft dual-audience docs per `skills/update-docs/references/writing-guide.md`, polish with `english-humanizer`, and publish to the chosen destination
4. Clear `.cursor/docs-gate.pending` when done or skipped
