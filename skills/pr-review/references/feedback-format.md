# PR review feedback format

Extends shared [`../../engineer-review/references/feedback-format.md`](../../engineer-review/references/feedback-format.md). **Must** pass [`../../engineer-review/references/evidence-gate.md`](../../engineer-review/references/evidence-gate.md) and must **not** match [`../../engineer-review/references/forbidden-formats.md`](../../engineer-review/references/forbidden-formats.md).

## Absolute rule

The user-facing message is the full **Findings** list below — each item with **Context**, File / Lines / Jump / GitHub + a numbered code fence. Clarify items (`### C#`) also require **Options** + **Recommendation** (or explicit “none”).

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
- **Context:** …
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

### C1 — `P0|P1` — <concrete title>
- **Context:** …
- **What:** …
- **Where:**
  - File: [`src/bar.ts`](src/bar.ts)
  - Lines: **40–45**
  - Jump: [`src/bar.ts:40`](src/bar.ts#L40)
  - GitHub: [src/bar.ts#L40-L45](https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/src/bar.ts#L40-L45)
- **Why it matters:** …
- **Ask:** …
- **Options:**
  - **A (recommended):** …
  - **B:** …
- **Recommendation:** A — …

```ts
40|  …
```

### F2 — …
(same shape — never collapse F1–Fn into a numbered prose list)

## Residual (optional, max 5)
Only with Where + snippet when pointing at code.

## PR comment draft (appendix only)
Each bullet: `path:line` — one concrete sentence. Do not auto-post. This section must not replace Findings.
```

If a phase left `recommended` null, still list Options, omit `(recommended)` on any option, and write:

> **Recommendation:** none — pick based on product intent.

If **Needs clarification** is non-empty, after the validated report ask via skill **`hitl-choice`** preset **Engineer-review clarify** (sequential `AskQuestion` per `C#`; recommended option labeled). Each sequential `C#` question repeats that item’s **Where** block and numbered code fence. Text fallback:

> Prefer the buttons for each `C#` (one question at a time). Or reply in one message like `C1: A; C2: B` (or free text). I will re-run the affected phases and apply agreed fixes.

## Before showing the user

1. Evidence-gate every finding (backfill via `extract-review-snippet.sh` or drop).
2. Write draft markdown to a temp file.
3. Run `$KIT/scripts/validate-review-report.sh` — exit non-zero → rebuild, do not show.
4. `english-humanizer` then `plain-language-chat` on prose only (not paths/code).
