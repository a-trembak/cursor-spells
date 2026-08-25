---
description: Record a production miss into review-learnings without running a full engineer-review. Uses review-learn mode:capture with source production-escape.
argument-hint: "[what slipped]"
---

# /capture-escape

Thin entry for a **production miss** the pipeline did not catch. Writes a generalized learning; does **not** run `engineer-review`.

## Arguments

- Optional short description of what escaped (symptom + where it should have been caught). If omitted, ask in chat (open-ended — not a closed-set HITL gate).
- Optional path to a score `FAIL` log or pasted `FAIL <id>:` lines. If provided, use that as the miss description (`source: production-escape` unchanged).

## Steps

1. Read `skills/engineer-review/references/review-learn-protocol.md`.
2. Invoke agent **`review-learn`** with:
   - `mode: capture`
   - `source: production-escape`
   - the human's description (and any linked ticket/PR if they pasted one)
3. Follow capture rules: generalize; max 2 miss classes; map to existing R# when possible; dedup the consumer ledger `.cursor/review-learnings.md`.
4. If the capture proposes a **new** kit gate (`gate: propose:…`), ask via skill **`hitl-choice`** preset **Review-learn promote** (`consumer_only` / `promote` / `skip`). Never auto-edit kit checklists from a consumer repo.

## Notes

- Do **not** start `engineer-reviewer`, `bug-fixer`, or `/start-issue-task`. If the human also wants a fix, they run `/start-issue-task` or `/start-task` separately.
- Do not invent a miss class from an empty description — wait for the human.
- Coverage: `review_learn: appended|deduped|skipped|n/a`.
