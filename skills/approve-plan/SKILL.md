---
name: approve-plan
description: >-
  Use right after writing-plans produces an implementation plan, before any
  critique or code. HITL approve-plan/revise, then auto-runs implementation-
  critic. On Verdict clear, hands off to start-build. Use from /start-task or
  /approve-plan.
---

# Approve Plan

Human reads and accepts the implementation plan **before** the critic runs. Critique starts automatically after `approve-plan` — no second permission to start the critic. Build starts only after `Verdict: clear`.

## When to Use

- `/start-task` after `writing-plans` finishes
- Manual `/approve-plan` when a plan exists and has not been approved for this revision
- Not for ad-hoc critique alone (`/critique-plan`) and not for starting code (`/start-build`)

## Steps (mandatory order)

1. **Resolve plan path.** Argument, else most recently modified under `docs/**/plans/`, confirm with the user if ambiguous.

2. **Write HITL marker** in the **current project** (not the kit):

   ```bash
   mkdir -p .cursor
   printf '%s\n' "<plan-path>" > .cursor/plan-gate.pending
   # A revise invalidates any prior clear critique for this plan:
   rm -f .cursor/plan-critique.clear
   ```

3. **Stop.** Ask exactly:

   > Plan ready. Review it, then reply:
   > - `approve-plan` — accept this plan; critic runs next automatically
   > - `revise` — describe changes (or edit the file); re-run this skill after

4. Do **not** run the critic or start build until `approve-plan`.

5. **On `approve-plan`:**
   - Delete `.cursor/plan-gate.pending`
   - Write `.cursor/critique-gate.pending` (one line: the plan path)
   - Auto-run `implementation-critic` / `/critique-plan` against the plan (read-only — no permission needed to start it)
6. **On `Verdict: clear`:**
   - Delete `.cursor/critique-gate.pending`
   - Write `.cursor/plan-critique.clear` (one line: the plan path)
   - Proceed automatically to skill `start-build` for that plan (branches + `software-developer`)
7. **On `Verdict: blocked` or `clear pending accept`:**
   - Keep `.cursor/critique-gate.pending`
   - **Stop** and show the critic's report. Wait for a plan revision (then re-run this skill from step 1) or `accept F<id>` for open findings. After accepts yield `clear`, continue from step 6.
8. **On `revise`:** keep or re-write `.cursor/plan-gate.pending`, ensure `.cursor/plan-critique.clear` is removed, wait for the updated plan, then re-ask step 3.

## Notes

- Critic is **not** a HITL start — only plan approval and blocked/accept-risk findings are HITL.
- Manual `/critique-plan` still works ad-hoc; it does not replace this gate for `/start-task`.
- Re-approving after a plan edit always re-runs the critic (clear marker was deleted in step 2 / revise).
