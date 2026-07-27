# PR review feedback format

Extends shared [`../../engineer-review/references/feedback-format.md`](../../engineer-review/references/feedback-format.md). **Must** pass [`../../engineer-review/references/evidence-gate.md`](../../engineer-review/references/evidence-gate.md) and must **not** match [`../../engineer-review/references/forbidden-formats.md`](../../engineer-review/references/forbidden-formats.md).

## Absolute rule

The user-facing message is the full **Findings** list below — each item with File / Lines / Jump / GitHub + a numbered code fence.  

**Never** send a compact “Verdict / Блокери (P0) / Також (P1) / Draft” digest as the review (that shape is banned even when the analysis is correct). A PR comment draft is optional **appendix only**, after Findings.

## Report skeleton

```markdown
# PR Review

## Coverage
- pr: #<n> <url>
- range: `<BASE_SHA>..<HEAD_SHA>`
- mode: report-only | apply
- …

## Findings

### F1 — `P0|P1|P2` — <concrete title>
- **What:** …
- **Where:**
  - File: [`src/foo.ts`](src/foo.ts)
  - Lines: **18–24**
  - Jump: [`src/foo.ts:18`](src/foo.ts#L18)
  - GitHub: [src/foo.ts#L18-L24](https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/src/foo.ts#L18-L24)
- **Why it matters:** …
- **Ask / fix:** …

```ts
18|  …
```

### F2 — …
(same shape — never collapse F1–Fn into a numbered prose list)

## Residual (optional, max 5)
Only with Where + snippet when pointing at code.

## PR comment draft (appendix only)
Each bullet: `path:line` — one concrete sentence. Do not auto-post. This section must not replace Findings.
```

## Before showing the user

1. Evidence-gate every finding (backfill via `extract-review-snippet.sh` or drop).
2. Write draft markdown to a temp file.
3. Run `scripts/validate-review-report.sh` — exit non-zero → rebuild, do not show.
4. `english-humanizer` on prose only (not paths/code).
