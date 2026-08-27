---
description: Record a production miss into kit instructions or this project's private ledger. Does not run a full engineer-review.
argument-hint: "[what slipped]"
---

# /capture-escape

Thin entry for a **production miss** the pipeline did not catch. Does **not** run `engineer-review`.

## Arguments

- Optional short description of what escaped (symptom + where it should have been caught). If omitted, ask in chat (open-ended — not a closed-set gate).
- Optional path to a score `FAIL` log or pasted `FAIL <id>:` lines. If provided, use that as the miss description (`source: production-escape` unchanged).

## Steps

1. If the description is empty, ask open-ended. Empty still → stop. Do not invent a miss class.
2. Ask via skill **`hitl-choice`** preset **Capture-escape destination** (`miss` / `project_secret`). Recommended: `miss`.
3. `miss` → read skill `teach-review` (`skills/teach-review/SKILL.md`) and follow it verbatim. Do not write `.cursor/review-learnings.md`.
4. `project_secret` → read `skills/engineer-review/references/review-learn-protocol.md`. Invoke agent **`review-learn`** with:
   - `mode: capture`
   - `source: production-escape`
   - destination `project_secret`
   - the human's description (and any linked ticket/PR if they pasted one)
   Follow capture rules: keep client / internal names; no passwords, tokens, or personal data; max 2 miss classes; map to existing R# / F# / I1 when possible as a pointer only; dedup `.cursor/review-learnings.md`. Do **not** ask **Review-learn promote**. Never edit kit files. Then score `capture-escape-no-review` per skill `trajectory-score`. Do not score `capture-escape-promote-new-gate` (that promote gate is retired).
5. Do not run both stores on the same miss. After `miss` (teach-review) also score `capture-escape-no-review` (no engineer-reviewer).

## Notes

- Do not start `engineer-reviewer`, `bug-fixer`, or `/start-issue-task` unless the human asks. If they also want a fix, they run `/start-issue-task` or `/start-task` separately.
- Coverage: `teach_review: invoked` or `review_learn: appended|deduped|skipped|n/a`.
