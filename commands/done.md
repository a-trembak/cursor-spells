---
description: Mark plan done → HITL gate → engineer review
---

# /done

Run skill `finish-plan`:

1. Write `.cursor/review-gate.pending`
2. Ask HITL: `skip` / `approve` / `done`
3. On frontend, ask Figma URLs or `no figma`
4. Start `engineer-reviewer` (`/review`)

Alias: `/finish-plan` (same flow).
