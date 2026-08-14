---
description: HITL-approve an implementation plan, then auto-run the critic; on clear, start build
argument-hint: "[path/to/plan.md]"
---

# /approve-plan

Run skill `approve-plan`:

1. Write `.cursor/gates/plan-gate/<slug>` with the plan path (`pg_write_gate plan-gate`); clear this plan's stale `.cursor/gates/plan-critique-clear/<slug>`.
2. **HITL:** wait for `approve-plan` or `revise` via skill `hitl-choice` (AskQuestion required; typed tokens only after failed/missing tool).
3. On `approve-plan`, auto-run `implementation-critic` (no permission needed — read-only).
4. If `Verdict: clear`, write `.cursor/gates/plan-critique-clear/<slug>` and invoke `/start-build`.
5. If `Verdict` is `blocked` or `clear pending accept`, stop; ask via `hitl-choice` (`revise` / `accept F<id>`) or wait for a plan revision / typed `accept F<id>`.

## Arguments

- Optional plan path. If omitted, use the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Notes

- This command never edits the plan itself — only this plan's gates and the critic's report output.
- Do not start Task 1 while **this plan's** plan-gate or critique-gate is still pending. Other slugs do not block.
- Never delete another slug's gate without HITL `force-clear`.
- When a revision updates the plan file (human or agent), follow skill `clean-decision-docs`: rewrite as current truth; narrate the turn's edits in chat only.
