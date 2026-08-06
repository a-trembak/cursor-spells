# Output schema

Emit this markdown. No persona text before or after.

```markdown
# System Design Critic

## Coverage
- system_design: `<path>`
- patterns: `read` | `not found`
- lenses: Y F O P

## Must-fix (blocks consensus clear)
1. **F1** (`lens Y|F|O|P`) — finding, quoting the draft line
   - Evidence: section / quote
   - Recommendation: concrete change to the draft

## Should-fix (non-blocking)
- **F2** (`lens Y|F|O|P`) — finding
  - Evidence: …
  - Recommendation: …

## Accept-risk (document in Assumptions after merge)
- **F3** (`lens Y|F|O|P`) — deliberate trade-off
  - Evidence: …
  - Risk: …
  - Merge note: claim / why / how to revoke for tech-spec Assumptions

## Verdict
- `blocked` — at least one Must-fix remains
- `clear` — no Must-fix remain (Should-fix / Accept-risk may still be listed)
```

## Rules

- Sequential ids `F1`, `F2`, … across all lenses.
- Do not use `clear pending accept` — humans do not accept mid-loop; Accept-risk is advisory for merge.
- Never edit the system-design file.
- Never ask the human questions.
