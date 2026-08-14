---
description: Start executing a critique-clear implementation plan (branches + software-developer) — does not run the critic
argument-hint: "[path/to/plan.md]"
---

# /start-build

Run skill `start-build`:

1. Require `.cursor/gates/plan-critique-clear/<slug>` matching **this** plan path (from `/approve-plan`). If missing, stop and point to `/approve-plan`.
2. Confirm **this slug's** plan-gate / critique-gate markers are absent. Other slugs' pending gates do not block.
3. Dispatch `software-developer` (feature branch(es) in target repo(s), skill routing, then `subagent-driven-development` by default).

## Arguments

- Optional plan path. If omitted, use `pg_list_gates plan-critique-clear` when exactly one row, else the most recently modified file under `docs/**/plans/` (confirm with the user).

## Notes

- This command does **not** run `implementation-critic`. Approve + critique happen in `/approve-plan`.
- Do not start Task 1 without a matching `plan-critique-clear/<slug>` for this plan.
