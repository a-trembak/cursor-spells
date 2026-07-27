# PR review feedback format

User-facing output for `pr-review` / `pr-reviewer`. Replaces the thin engineer-review report for this entry point. Every finding must answer: **what broke / looks wrong**, **where exactly**, **why it matters**, **what to do**.

## Hard requirements per finding

1. **Clickable location**
   - Repo-relative path with line(s): `` [`path/to/file.ts:42`](path/to/file.ts) `` (Cursor can open the path)
   - And a GitHub blob link when PR metadata exists:
     `https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/<path>#L42` or `#L42-L55` for a range
   - Build owner/repo from the PR URL; use `HEAD_SHA` (or head ref OID) from resolve step — never invent a SHA

2. **Code snippet**
   - 3–15 lines of the **current** side of the diff (or surrounding context) that shows the problem
   - Fenced with language tag; do not paraphrase the code in prose instead of quoting it
   - If the issue is “missing” code, quote the nearest call site / empty branch and say what is absent

3. **Human wording (mandatory)**
   - Load and apply skill `english-humanizer` to every user-visible sentence in the report and the PR comment draft (finding titles, bodies, questions, verdict)
   - If `english-humanizer` is not installed: apply its engineer voice rules inline (lead with the point, concrete, no throat-clearing, no marketing inflation) — note `skill_missing: english-humanizer` in Coverage
   - **Never humanize** paths, symbol names, error strings, or code fences — only the prose around them
   - Ban vague phrases: “potential concern”, “consider reviewing”, “this may impact”, “worth noting”, “significant”, “robustness”, “alignment with best practices” without naming the concrete failure

4. **Structure each finding so a reader never asks “what? from where? what do they mean?”**
   - **What:** one sentence — the concrete problem
   - **Where:** links + snippet
   - **Why:** one sentence — user/system impact or incorrect behavior
   - **Ask / fix:** suggestion or a clarification with options A/B/C

## Report template

```markdown
# PR Review

## Coverage
- pr: #<n> <url>
- range: `<BASE_SHA>..<HEAD_SHA>`
- mode: report-only | apply
- stack: …
- phases: …
- skills_missing: …

## Findings

### F1 — `P0|P1|P2` — <short concrete title>
- **What:** …
- **Where:** [`src/foo.ts:18-24`](src/foo.ts) · [GitHub](https://github.com/org/repo/blob/<HEAD_SHA>/src/foo.ts#L18-L24)
- **Why it matters:** …
- **Ask / fix:** … (or Options: A / B / C for clarifications)

```ts
// snippet
```

### F2 — …

## Residual (optional, max 5)
Short humanized nits only if they still include Where links; otherwise drop.

## PR comment draft
Humanized English, ready to paste. For each serious finding: one bullet with path:line and the point — no jargon pile. Do not auto-post.
```

## Mapping from phase JSON

When merging phase summaries into Findings:

| Phase field | Feedback field |
|-------------|----------------|
| `severity` | badge on the heading |
| `path` + `start_line`/`end_line` | Where links + snippet range |
| `snippet` | code fence (if missing, orchestrator must `git show HEAD_SHA:path` / read file and fill 3–15 lines around `start_line`) |
| `summary` / `question` | What + Why + Ask after humanizer |

Omit empty sections. Prefer fewer clear findings over a long laundry list of vague notes.

## Anti-patterns (reject / rewrite before emit)

- Finding with only a path and no snippet
- Finding with no line number when the issue is in existing code
- “Improve error handling” / “consider edge cases” without naming which case and which lines
- Pasting phase/skill internal ids or checklist names at the reader
- Unhumanized LLM mush that would make a peer ask “what do they mean?”
