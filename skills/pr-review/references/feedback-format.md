# PR review feedback format

Extends shared [`../../engineer-review/references/feedback-format.md`](../../engineer-review/references/feedback-format.md) and **must** pass [`../../engineer-review/references/evidence-gate.md`](../../engineer-review/references/evidence-gate.md).

Same hard rules: full **Where** block (File + Lines + Jump + GitHub), numbered code fence, What/Why/Ask, `english-humanizer`. GitHub blob links are **required** when PR resolve succeeded.

## Report skeleton

```markdown
# PR Review

## Coverage
- pr: #<n> <url>
- range: `<BASE_SHA>..<HEAD_SHA>`
- mode: report-only | apply
- …

## Findings

### F1 — `P0|P1|P2` — …
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

## Residual (optional, max 5)

## PR comment draft
Each bullet: `path:line` — one concrete sentence. No jargon pile. Do not auto-post.
```

Do not fall back to `path: summary` one-liners. Incomplete evidence → backfill or drop.
