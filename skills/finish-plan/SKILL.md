---
name: finish-plan
description: >-
  Use when an implementation plan has just been fully executed or you are about
  to declare plan work complete — before engineer-review or any post-plan wrap-up.
---

# Finish Plan

Reliable handoff into the engineer-review HITL gate. Prefer this over hoping a global rule fires.

## When to Use

- Last task of a plan is done
- User says the plan is complete
- Before claiming “ready for review/PR” after planned work

## Steps (mandatory order)

1. **Write marker** in the **current project** (not the kit):

   ```bash
   mkdir -p .cursor
   printf 'pending\n' > .cursor/review-gate.pending
   ```

2. **Stop.** Ask the HITL gate via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Finish-plan / engineer-review / multi-repo HITL**. Prompt/text fallback:

   > Plan done. Want to do your own review first?
   > - `skip` — start review now (engineer-reviewer or multi-repo-supervisor)
   > - `approve` / `done` — start after your review
   > - or describe fixes first

   All three of `skip` / `approve` / `done` mean **start review** after deleting the marker. Do not invent other meanings (e.g. “skip review” or “close without review”).

3. Do **not** start review until `skip` | `approve` | `done`. (`fixes` / a typed fix description means implement/fix first, then re-ask this gate.)

   **Already answered (mandatory):** If the user already sent `skip`, `approve`, or `done` in this chat after the gate was asked — including while a stop-hook followup was looping — treat that as the answer. Delete the marker and continue step 4 immediately. Do **not** re-ask.

4. On `skip` | `approve` | `done`:
   - Delete `.cursor/review-gate.pending` **first** (before any review work). If delete fails, stop and report the path — do not re-ask HITL.
   - Before starting review, read and apply `skills/engineer-review/references/multi-repo-protocol.md` routing with its **non-mutating probe** mode. This probe may read graphify, read an existing parent `.cursor/multi-repo.json`, or scan siblings in memory, but it **MUST NOT** write or refresh `multi-repo.json`.
   - Detect changed repos with the protocol.
   - If changed repo count is **0**, stop and say no changed repos were found.
   - If changed repo count is **>= 2**, invoke agent `multi-repo-supervisor` and pass:
     - `hitl_already_approved: true`
     - `figma_clarifications` only if Figma URLs were already collected in this flow
     The supervisor owns Figma clarification collection when none were already collected.
   - If changed repo count is **1**, keep the existing single-repo path unchanged:
     - If frontend stack (`react-web` / `react-native`): also ask Figma via skill **`hitl-choice`** preset **Figma ask** (or text: paste links / `no figma`).
     - Then run skill `engineer-review` / agent `engineer-reviewer` for the changed repo (pass Figma URLs in clarifications if provided).

## Notes

- Manual `/engineer-review` does not need this skill.
- If the user describes fixes first, implement/fix, then re-ask the HITL question (keep or rewrite the marker until review starts).
