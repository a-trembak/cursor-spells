---
description: Publish a review miss into cursor-spells kit instructions (learn/ branch + land config).
argument-hint: "[what the reviewer missed]"
---

# /teach-review

Turn a human remark into generalized **kit** instructions. Does **not** write `.cursor/review-learnings.md`. Does **not** run `engineer-review`.

## Arguments

- Optional miss description (symptom + the check that should have caught it). If omitted, ask in chat (open-ended — not Teach-review miss).

## Steps

1. Read skill `teach-review` (`skills/teach-review/SKILL.md`).
2. If the argument is empty, ask for the description. Empty still → stop.
3. Follow `teach-review` verbatim (generalize → route → kit git → land).
4. Skip the closed-set Teach-review miss gate — invoking this command **is** `miss` (kit). For a miss that must stay in this project, use `/capture-escape` and choose `project_secret` instead.

## Notes

- Do not start `engineer-reviewer` or `/capture-escape` unless the human asks.
- One miss class per invocation.
