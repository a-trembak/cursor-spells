---
description: Mark plan complete and enter engineer-review HITL gate
---

# /finish-plan

Run skill `finish-plan`:

1. Write `.cursor/review-gate.pending`
2. Stop and ask HITL (`skip` starts review now via `engineer-reviewer` or `multi-repo-supervisor`; `approve` / `done` starts after the user's review)
3. After approval, run `multi-repo-protocol.md` routing before review using the **non-mutating probe** only (read graphify / existing parent `.cursor/multi-repo.json` / sibling scan in memory; do not write `multi-repo.json`):
   - **0 changed repos**: stop and say no changed repos were found.
   - **1 changed repo**: keep the current single-repo `engineer-reviewer` path unchanged; optionally ask for Figma URLs on frontend.
   - **>= 2 changed repos**: start `multi-repo-supervisor` with `hitl_already_approved: true`, and pass `figma_clarifications` if they were already collected. If none were collected, the supervisor asks once for the whole multi-repo task.
