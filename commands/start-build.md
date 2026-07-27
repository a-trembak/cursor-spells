---
description: Start executing a critique-clear implementation plan (branches + software-developer) — does not run the critic
argument-hint: "[path/to/plan.md]"
---

# /start-build

Run skill `start-build`:

1. Require `.cursor/plan-critique.clear` matching the plan path (from `/approve-plan`). If missing, stop and point to `/approve-plan`.
2. Confirm plan-gate / critique-gate markers are absent.
3. Dispatch `software-developer` (feature branch(es) in target repo(s), skill routing, then `subagent-driven-development` by default).

## Arguments

- Optional plan path. If omitted, use the path in `.cursor/plan-critique.clear` or the most recently modified file under `docs/**/plans/` (confirm with the user).

## Notes

- This command does **not** run `implementation-critic`. Approve + critique happen in `/approve-plan`.
- Do not start Task 1 without a matching `plan-critique.clear`.
