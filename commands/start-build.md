---
description: Run the pre-build critique gate, then start executing an approved implementation plan
argument-hint: "[path/to/plan.md]"
---

# /start-build

Run skill `start-build`:

1. Write `.cursor/build-gate.pending` with the plan path.
2. Auto-run `implementation-critic` against the plan (no permission needed — read-only).
3. If `Verdict: clear`, delete the marker and dispatch `subagent-driven-development` to execute the plan.
4. If `Verdict` is `blocked` or `clear pending accept`, stop and show findings; wait for a plan revision or `accept F<id>` replies.

## Arguments

- Optional plan path. If omitted, use the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Notes

- This command never edits the plan itself — only `implementation-critic`'s own report output, unchanged.
- Do not start Task 1 while `Verdict: blocked`.
