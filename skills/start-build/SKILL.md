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
- Manual `/start-build` when this plan's `.cursor/gates/plan-critique-clear/<slug>` already matches the plan
- Not for first-time plan review — use `/approve-plan` instead

## Steps (mandatory order)

1. **Resolve plan path.** Argument, else from `pg_list_gates "$(pwd)" plan-critique-clear` if exactly one row, else most recently modified under `docs/**/plans/` (confirm if ambiguous).

2. **Require a clear critique for this plan only:**

   ```bash
   # Prefer (consumer project):
   #   source scripts/pipeline-gates.sh
   #   pg_migrate_legacy "$(pwd)" plan-critique-clear "<plan-path>"
   # .cursor/gates/plan-critique-clear/<slug> must exist and line 1 must equal the plan path
   ```

   If missing or mismatched: **stop** and tell the user to run `/approve-plan <plan-path>` first (HITL approve → auto critic). Do not re-run the critic from this skill unless the human explicitly asks for `/critique-plan` alone.

3. Stop only if **this slug** still has `plan-gate/<slug>` or `critique-gate/<slug>`. If either exists: **stop** — approval or critique is still open for this plan.

   Other slugs' pending gates **do not** block. Never delete or overwrite a foreign slug; if the human explicitly wants that, ask HITL via skill **`hitl-choice`** preset **Force-clear foreign gate** first.

4. **Dispatch** agent/skill `software-developer` for the plan (creates feature branch(es) in every repo the plan will touch, routes stack/DB/`code-comments` skills, then drives `subagent-driven-development` by default) unless the user already specified `executing-plans` for a separate session.

5. Do **not** dispatch Task 1 without step 2 satisfied.

## Notes

- Plan edits invalidate this plan's `plan-critique-clear/<slug>` when going back through `/approve-plan`.
- Manual `/critique-plan` remains for ad-hoc audits; wiring a clear result into build still goes through writing `.cursor/gates/plan-critique-clear/<slug>` (prefer `/approve-plan` so HITL plan approval is not skipped).
