---
description: Mark plan complete and enter engineer-review HITL gate
---

# /finish-plan

Run skill `finish-plan`:

1. Write `.cursor/review-gate.pending`
2. Stop and ask HITL (`skip` / `approve` / `done`)
3. After approval, optionally ask for Figma URLs on frontend, then start `engineer-reviewer`
