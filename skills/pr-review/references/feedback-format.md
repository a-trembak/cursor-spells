# PR review feedback format

Extends the shared review feedback in [`../../engineer-review/references/feedback-format.md`](../../engineer-review/references/feedback-format.md).

Same hard rules: **What / Where / Why / Ask**, code **snippet**, clickable path + **GitHub** `blob/<HEAD_SHA>/…#L…`, prose through **`english-humanizer`**.

## PR-only extras

1. Coverage must include `pr: #<n> <url>` and `mode: report-only|apply`.
2. GitHub blob links are **required** when PR resolve succeeded (owner/repo + `HEAD_SHA` are known) — not optional.
3. Title the report `# PR Review`.
4. Append a **PR comment draft** (humanized English, ready to paste). For each serious finding: one bullet with `path:line` and the point. Do not auto-post.

## Report skeleton

```markdown
# PR Review

## Coverage
- pr: #<n> <url>
- range: `<BASE_SHA>..<HEAD_SHA>`
- mode: report-only | apply
- … (same as engineer-review Coverage)

## Findings
### F1 — `P0|P1|P2` — …   <!-- same What/Where/Why/Ask + snippet as shared format -->

## Residual (optional, max 5)

## PR comment draft
…
```

Use **Findings** for both would-fix and clarifications in report-only mode (label Ask vs Would fix in the Ask/fix field). Do not fall back to the old one-line `path: summary` list.
