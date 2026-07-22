---
description: Mark plan complete and enter engineer-review HITL gate
---

# /finish-plan

Run skill `finish-plan`:

1. Write `.cursor/review-gate.pending`
2. Stop and ask HITL (`skip` starts review now via `engineer-reviewer` or `multi-repo-supervisor`; `approve` / `done` starts after the user's review)
3. After approval, run `multi-repo-protocol.md` routing before review:
   - **< 2 changed repos**: keep the current single-repo `engineer-reviewer` path unchanged; optionally ask for Figma URLs on frontend.
   - **>= 2 changed repos**: start `multi-repo-supervisor` with `hitl_already_approved: true`, and pass `figma_clarifications` if they were already collected.
