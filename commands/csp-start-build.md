---
description: Start executing a critique-clear implementation plan (branches + software-developer), wait, then finish-plan → engineer-reviewer — does not run the critic
argument-hint: "[path/to/plan.md]"
---

# /csp-start-build

Run skill `start-build`:

1. Require `.cursor/gates/plan-critique-clear/<slug>` matching **this** plan path (from `/csp-approve-plan`). If missing, stop and point to `/csp-approve-plan`.
2. Confirm **this slug's** plan-gate / critique-gate markers are absent. Other slugs' pending gates do not block.
3. Dispatch `csp-software-developer` as a nested Task (feature branch(es) in target repo(s), skill routing, then `subagent-driven-development` by default).
4. **Wait for** that Task to return. Fire-and-forget is a hard failure — do not stop after dispatch.
5. Immediately invoke skill `finish-plan` in this parent chat (review-surface + review-gate HITL, then `csp-engineer-reviewer` or `csp-multi-repo-supervisor`). Do not ask the human to type `/csp-finish-plan` or `/csp-engineer-review`. Do not treat `finish-plan` as the pipeline end.

## Arguments

- Optional plan path. If omitted, use `pg_list_gates plan-critique-clear` when exactly one row, else the most recently modified file under `docs/**/plans/` (confirm with the user).

## Notes

- This command does **not** run `implementation-critic`. Approve + critique happen in `/csp-approve-plan`.
- Do not start Task 1 without a matching `plan-critique-clear/<slug>` for this plan.
- Do not treat `csp-software-developer` dispatch as the end — **Wait for** the Task, then `finish-plan` → `csp-engineer-reviewer`.
