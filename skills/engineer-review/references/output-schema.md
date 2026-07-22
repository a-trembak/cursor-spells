# Output schema

Emit this markdown to the user. Keep it scannable. No persona dump, no skill internals.

```markdown
# Engineer Review

## Coverage
- range: `<base>..<head>`
- stack: `<label>`
- patterns: `created` | `reused` | `updated`
- chunks: `1` | `N (by package/dir)` 
- phases:
  - logic: ran
  - patterns: ran
  - deadcode: ran
  - architecture: ran
  - performance: ran
  - security: skipped (no sensitive surface)
  - figma: skipped (awaiting node URLs) | ran | skipped (user said no)
- skills_missing: []
- budget: files=… loc=… (chunked if over caps)

## Fixed now
- `P0|P1` `path`: summary

## Needs clarification
1. **C1** (`P0|P1`) — question
   - Options: A / B / C
   - File: `path` (if any)

## Residual notes
- `P2` / non-blocking bullets (max 5 shown; mention if truncated)
```

If **Needs clarification** is non-empty, end with:

> Reply with answers like `C1: A` (or free text). I will re-run the affected phases and apply agreed fixes.

After the follow-up apply round, re-emit the same schema with an updated Fixed now section and cleared/remaining clarifications.
