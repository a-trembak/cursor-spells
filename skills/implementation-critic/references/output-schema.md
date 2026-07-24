# Output schema

Emit this markdown to the user. Keep it scannable. No persona text before or after it.

```markdown
# Implementation Critic

## Coverage
- plan: `<path>`
- tech_spec: `<path>` | none provided
- patterns: `read` | `not found`
- pass_a: ran (`plan-reviewer`) | ran (built-in fallback) | skill_missing
- pass_b: ran (`project-verify-plan`) | ran (built-in fallback) | skill_missing

## Must-fix (blocks implementation)
1. **F1** (`pass A|B`) — finding, quoting the plan/spec line it targets
   - Evidence: `path:line` or plan section
   - Recommendation: concrete alternative

## Should-fix (visible, non-blocking)
- **F2** (`pass A|B`) — finding
  - Recommendation: concrete suggestion

## Accept-risk candidates (require explicit human accept)
- **F3** (`pass A|B`) — deliberate trade-off the plan makes
  - Risk: what could go wrong
  - Needs: human reply `accept F3` to unblock, or a plan revision

## Verdict
- `blocked` (open must-fix) | `clear` (no open must-fix) | `clear pending accept` (only accept-risk items remain)
```

## Rules

- Finding ids are a single sequential namespace (`F1`, `F2`, `F3`, …) across both passes — do not restart numbering per pass.
- `pass` on every finding is `A` or `B`, matching which lens produced it.
- `Verdict` is `blocked` whenever at least one `must-fix` item has no matching `accept F<id>` reply on record; it becomes `clear pending accept` once every remaining open item is `accept-risk` and has been explicitly accepted; it is `clear` only when there are no open must-fix or un-accepted accept-risk items at all.
- If **Must-fix** is non-empty, end the report with:

  > Reply `accept F<id>` to accept a specific risk, or revise the plan and re-run `/critique-plan`. Implementation should not start while `Verdict: blocked`.
