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

2. **Stop.** Ask exactly:

   > Plan done. Want to do your own review first?
   > - `skip` — start engineer-reviewer now
   > - `approve` / `done` — start after your review
   > - or describe fixes first

3. Do **not** start `engineer-reviewer` until `skip` | `approve` | `done`.

4. On that reply:
   - Delete `.cursor/review-gate.pending`
   - If frontend stack (`react-web` / `react-native`): also ask  
     > Any Figma node URLs for markup review? Paste links, or say `no figma`.
   - Then run skill `engineer-review` / agent `engineer-reviewer` (pass Figma URLs in clarifications if provided).

## Notes

- Manual `/review` does not need this skill.
- If the user describes fixes first, implement/fix, then re-ask the HITL question (keep or rewrite the marker until review starts).
