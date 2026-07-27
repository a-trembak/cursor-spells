---
name: start-build
description: >-
  Use when an implementation plan already has Verdict clear from approve-plan
  (or an equivalent critique) and code should start. Creates no critique —
  only dispatches software-developer (feature branches + implementation).
---

# Start Build

Thin handoff into execution. **Does not** run `implementation-critic` — that happens earlier via `approve-plan` (HITL approve → auto critic). This skill only starts coding once the plan is critique-clear.

## When to Use

- `/start-task` after `approve-plan` yields `Verdict: clear`
- Manual `/start-build` when `.cursor/plan-critique.clear` already matches the plan
- Not for first-time plan review — use `/approve-plan` instead

## Steps (mandatory order)

1. **Resolve plan path.** Argument, else path from `.cursor/plan-critique.clear`, else most recently modified under `docs/**/plans/` (confirm if ambiguous).

2. **Require a clear critique for this plan:**

   ```bash
   # .cursor/plan-critique.clear must exist and its first line must equal the plan path
   ```

   If missing or mismatched: **stop** and tell the user to run `/approve-plan <plan-path>` first (HITL approve → auto critic). Do not re-run the critic from this skill unless the human explicitly asks for `/critique-plan` alone.

3. Confirm `.cursor/critique-gate.pending` and `.cursor/plan-gate.pending` are absent. If either exists: **stop** — approval or critique is still open.

4. **Dispatch** agent/skill `software-developer` for the plan (creates feature branch(es) in every repo the plan will touch, routes stack/DB/`code-comments` skills, then drives `subagent-driven-development` by default) unless the user already specified `executing-plans` for a separate session.

5. Do **not** dispatch Task 1 without step 2 satisfied.

## Notes

- Plan edits invalidate `.cursor/plan-critique.clear` when going back through `/approve-plan`.
- Manual `/critique-plan` remains for ad-hoc audits; wiring a clear result into build still goes through writing `.cursor/plan-critique.clear` (prefer `/approve-plan` so HITL plan approval is not skipped).
