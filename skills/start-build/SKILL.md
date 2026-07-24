---
name: start-build
description: >-
  Use when an implementation plan is approved and about to be executed
  task-by-task (subagent-driven-development or executing-plans), before Task
  1 is dispatched. Auto-runs the implementation-critic gate so a human
  doesn't have to remember to critique the plan first.
---

# Start Build

Reliable handoff from an approved plan into execution. Auto-runs `implementation-critic` so build never starts on an uncritiqued plan — prefer this over hoping a global rule fires.

## When to Use

- An implementation plan exists (from `writing-plans`) and is about to be executed
- Before dispatching Task 1 via `subagent-driven-development` or `executing-plans`
- Not for re-running critique on a plan already `clear` for this exact revision (skip straight to execution)

## Steps (mandatory order)

1. **Write marker** in the **current project** (not the kit):

   ```bash
   mkdir -p .cursor
   printf '%s\n' "<plan-path>" > .cursor/build-gate.pending
   ```

2. **Auto-run the critique** — no HITL needed to start it, `implementation-critic` is read-only:
   - Invoke skill `implementation-critic` (or `/critique-plan <plan-path>`) against the plan.
3. **On `Verdict: clear`:**
   - Delete `.cursor/build-gate.pending`.
   - Proceed directly to execution: dispatch `subagent-driven-development` (default) unless the user already specified `executing-plans` for a separate session.
4. **On `Verdict: blocked` or `clear pending accept`:**
   - Keep the marker.
   - **Stop** and show the critic's report. Wait for the user to revise the plan (re-run this skill after) or reply `accept F<id>` for open findings.
5. Do **not** dispatch Task 1 until `Verdict` is `clear` (with any accept-risk items explicitly accepted).

## Notes

- Re-running after a plan revision produces a fresh critique — the marker keeps the gate honest across turns.
- Manual `/critique-plan` still works standalone for an ad-hoc look; this skill is the enforced pre-build path.
