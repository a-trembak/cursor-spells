---
name: pipeline-status
description: >-
  Use before every hitl-choice closed-set ask, and when the human runs
  /pipeline-status. Resolves where-am-I from disk gates + session ledger,
  prints a chat orientation strip and canvas link. Never advances gates.
---

# Pipeline status

Thin orientation skill. Derives route / layer / stage from existing
`.cursor/gates/*` markers and optional trajectory session ledgers. Does **not**
write gates or invent a new gate kind.

## When to Use

- **Required** before every `hitl-choice` closed-set ask (same user-visible turn as the question)
- When the human runs `/pipeline-status`
- Anytime an orchestrator needs a “where am I” strip without advancing the pipeline

## How to run

1. Resolve the consumer project root (cwd of the active workspace folder).
2. Find the resolver script (first that exists):
   - `$KIT/scripts/pipeline-status.sh` when kit path is known (`.cursor/cursor-spells-kit-path` or `$KIT`)
   - `scripts/pipeline-status.sh` in the project (after install)
3. Run:

```bash
bash scripts/pipeline-status.sh --root <project-root>
# optional machine record:
bash scripts/pipeline-status.sh --json --root <project-root>
# optional canvas path with query + hash:
bash scripts/pipeline-status.sh --canvas-url --root <project-root> [--kit-root <kit-or-project>]
```

4. Print the strip (and canvas link) in the user-facing turn. Do **not** advance, clear, or invent gates.

## Language contract

- Script stdout is a **machine / English skeleton** only (stable field labels for agents and tests).
- The orchestrator **must** adapt the strip into the human’s language using skill `plain-language-chat` (full words; Ukrainian when the human writes Ukrainian). Do not paste jargon-heavy skeleton text unchanged when the human is not writing English.

## Strip template (after adapting language)

- Route · layer · current stage
- Next stages (one short line, 1–3 names)
- Legal returns (or “none — happy path only”) — **informational only** in v1; no `/pipeline-back`
- Canvas link with `?route=&layer=&stage=` (and hash when present)

## Failure

If the script is missing or exits non-zero: say in **one sentence** that orientation was skipped, then continue the calling skill (still ask the human gate). Never invent a stage id.

## Hard rules

- Never invent `stage` / `layer` when the resolver fails
- Never mutate `.cursor/gates/`
- Legal returns are prose for humans — not actions that rewind the pipeline
