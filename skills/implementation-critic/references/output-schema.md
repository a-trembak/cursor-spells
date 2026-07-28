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
  - Evidence: `path:line` or plan section
  - Recommendation: concrete suggestion

## Accept-risk candidates (require explicit human accept)
- **F3** (`pass A|B`) — deliberate trade-off the plan makes
  - Evidence: `path:line` or plan section
  - Risk: what could go wrong
  - Needs: human reply `accept F3` to unblock, or a plan revision

## Verdict
- `blocked` (an open, un-accepted must-fix item) | `clear pending accept` (must-fix resolved/accepted; an accept-risk item awaits acceptance) | `clear` (no open must-fix and no un-accepted accept-risk items)
```

## Rules

- Finding ids are a single sequential namespace (`F1`, `F2`, `F3`, …) across both passes — do not restart numbering per pass.
- `pass` on every finding is `A` or `B`, matching which lens produced it.
- `accept F<id>` applies to any open finding by id — a `must-fix` item as well as an `accept-risk` item — and removes it from the "open" count for the Verdict rules below.
- `Verdict` is `blocked` whenever at least one `must-fix` item is still open (no matching `accept F<id>` reply on record); it is `clear pending accept` once every `must-fix` item is resolved or accepted but at least one `accept-risk` item has not yet been explicitly accepted; it is `clear` only when every `must-fix` item is resolved or accepted and every `accept-risk` item has been explicitly accepted (or there are no findings at all).
- If `Verdict` is `blocked` or `clear pending accept`, end the report with the text fallback below, then ask next steps via skill **`hitl-choice`** preset **Blocked / pending-accept critic** (prefer `AskQuestion` with `revise` + one `accept F<id>` option per open finding; `allowMultiple` when supported):

  > Reply `accept F<id>` to accept a specific finding by id, or revise the plan and re-run `/critique-plan`. Implementation should not start while `Verdict` is not `clear`.
