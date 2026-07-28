---
description: HITL-approve an implementation plan, then auto-run the critic; on clear, start build
argument-hint: "[path/to/plan.md]"
---

# /approve-plan

Run skill `approve-plan`:

1. Write `.cursor/plan-gate.pending` with the plan path; clear any stale `.cursor/plan-critique.clear`.
2. **HITL:** wait for `approve-plan` or `revise`.
3. On `approve-plan`, auto-run `implementation-critic` (no permission needed — read-only).
4. If `Verdict: clear`, write `.cursor/plan-critique.clear` and invoke `/start-build`.
5. If `Verdict` is `blocked` or `clear pending accept`, stop; wait for a plan revision or `accept F<id>`.

## Arguments

- Optional plan path. If omitted, use the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Notes

- This command never edits the plan itself — only markers and the critic's report output.
- Do not start Task 1 while plan approval or critique is still pending.
- When a revision updates the plan file (human or agent), follow skill `clean-decision-docs`: rewrite as current truth; narrate the turn's edits in chat only.
