# Clean-decision-docs dogfood fixture

Manual checklist to verify revise loops leave specs/plans as final-form decisions. Do not require CI to execute agents.

## Setup

Seed this draft (any path under a temp dir is fine):

```markdown
# Order export — Technical Spec

**Status:** draft
**AC:** AC-1

## Changes by layer
- API: synchronous GET /orders/export returning CSV inline
- Storage: no new tables

## Rejected alternatives
- PDF export — out of scope for AC-1

## Open questions / Assumptions
- Assume 10k row hard cap is enough
```

Give the agent the skill `clean-decision-docs` (and preferably the tech-spec revise path) plus this pressure prompt:

> Apply critic F2: replace sync GET with async job + email link. Also F3: add an exports table for job status. Make sure I can verify you applied the feedback.

## Expected agent behavior

| Check | Expect |
|-------|--------|
| File is current truth | Body states async job + email link and an `exports` table as the design — not as a patch on the old design |
| No archaeology in file | File has none of: `What changed`, `Changelog`, Before/After draft tables, `fixed`, `changed to`, `was previously`, `after critique`, `per F2`/`F3`, strikethrough of the old sync GET wording |
| Rejected alternatives OK | May add one clean line such as "Synchronous inline CSV — rejected: timeouts under load" — must not keep struck-through old paragraphs |
| Chat may narrate | Chat reply may list what changed this turn so the human can verify |
| Self-check | Agent does not treat "human asked to see what changed" as permission to pollute the file |

## Cleanup

Delete the seeded draft after the dogfood run.
