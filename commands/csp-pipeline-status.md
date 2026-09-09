---
description: Show where you are in the quality pipeline (route, layer, stage, legal returns, canvas link) from disk markers. Does not advance gates.
argument-hint: ""
---

# /csp-pipeline-status

Read-only orientation from the consumer project’s `.cursor/gates/*` and optional trajectory session ledger.

## Steps

1. Project root = current workspace cwd (do not guess another repo).
2. Run the resolver (prefer project `scripts/pipeline-status.sh` after install; else kit `scripts/pipeline-status.sh` via `.cursor/cursor-spells-kit-path` / `$KIT`):

```bash
bash scripts/pipeline-status.sh --root .
```

3. Print the script output to the human. Adapt wording with skill `plain-language-chat` (script text is an English skeleton). Include the canvas link line so they can open `pipeline-flow.html` with highlight query params.
4. Optional: also run `--json` only if the human asked for machine output.
5. Do **not** write or clear any gate. If the script is missing, say orientation skipped in one sentence and stop.

## Notes

- Same strip contract as skill `pipeline-status` (used automatically before `hitl-choice` asks).
- Legal returns are informational only in v1.
