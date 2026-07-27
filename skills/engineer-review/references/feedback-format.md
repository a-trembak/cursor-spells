# Review feedback format

User-facing output for `engineer-review` / `engineer-reviewer` (and the shared base for `pr-review`). Every finding must answer: **what broke / looks wrong**, **where exactly**, **why it matters**, **what to do**.

## Hard requirements per finding

1. **Clickable location**
   - Repo-relative path with line(s): `` [`path/to/file.ts:42`](path/to/file.ts) `` (Cursor can open the path)
   - When a remote/`HEAD_SHA` is known (PR review, or `git remote get-url origin` resolves to GitHub), also add:
     `https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/<path>#L42` or `#L42-L55`
   - Never invent a SHA or owner/repo — omit the GitHub link if unknown

2. **Code snippet**
   - 3–15 lines of the code under review that shows the problem
   - Fenced with language tag; do not paraphrase the code in prose instead of quoting it
   - If the issue is “missing” code, quote the nearest call site / empty branch and say what is absent

3. **Human wording (mandatory)**
   - Load and apply skill `english-humanizer` to every user-visible sentence (finding titles, bodies, questions, Fixed summaries)
   - If `english-humanizer` is not installed: apply its engineer voice rules inline (lead with the point, concrete, no throat-clearing, no marketing inflation) — note `skill_missing: english-humanizer` in Coverage
   - **Never humanize** paths, symbol names, error strings, or code fences — only the prose around them
   - Ban vague phrases: “potential concern”, “consider reviewing”, “this may impact”, “worth noting”, “significant”, “robustness”, “alignment with best practices” without naming the concrete failure

4. **Structure each finding so a reader never asks “what? from where? what do they mean?”**
   - **What:** one sentence — the concrete problem (or what was fixed)
   - **Where:** links + snippet
   - **Why:** one sentence — user/system impact or incorrect behavior
   - **Ask / fix:** suggestion, what was applied, or a clarification with options A/B/C

## Report template

```markdown
# Engineer Review

## Coverage
- range: `<BASE_SHA>..<HEAD_SHA>`
- stack: …
- patterns: created | reused | updated
- chunks: …
- phases: …
- skills_missing: …
- budget: …

## Fixed now

### F1 — `P0|P1` — <short concrete title>
- **What:** …
- **Where:** [`src/foo.ts:18-24`](src/foo.ts) · [GitHub](…)  <!-- GitHub optional -->
- **Why it matters:** …
- **Fix applied:** …  <!-- or "Would fix:" in report-only contexts -->

```ts
// snippet
```

## Needs clarification

### C1 — `P0|P1` — <short concrete title>
- **What:** …
- **Where:** [`src/bar.ts:40`](src/bar.ts)
- **Why it matters:** …
- **Ask:** …  
  - Options: A / B / C

```ts
// snippet
```

## Residual notes
- Max 5 humanized nits; each still needs a Where link (and snippet when the nit is about specific code). Otherwise drop.
```

If **Needs clarification** is non-empty, end with:

> Reply with answers like `C1: A` (or free text). I will re-run the affected phases and apply agreed fixes.

After the follow-up apply round, re-emit the same schema with updated Fixed now and cleared/remaining clarifications.

## Mapping from phase JSON

| Phase field | Feedback field |
|-------------|----------------|
| `severity` | badge on the heading |
| `path` + `start_line`/`end_line` | Where links + snippet range |
| `snippet` | code fence (if missing, orchestrator must read `HEAD_SHA:path` / the file and fill 3–15 lines around `start_line`) |
| `summary` / `question` | What + Why + Ask/Fix after humanizer |
| `applied: true` | under **Fixed now** with **Fix applied** |
| `applied: false` (find-only / would-fix) | under **Fixed now** as **Would fix** or under clarification if not unambiguous |

Omit empty sections. Prefer fewer clear findings over a long laundry list of vague notes.

## Anti-patterns (reject / rewrite before emit)

- Finding with only a path and no snippet
- Finding with no line number when the issue is in existing code
- One-liner `` `P1` `path`: summary `` with no What/Where/Why
- “Improve error handling” / “consider edge cases” without naming which case and which lines
- Pasting phase/skill internal ids or checklist names at the reader
- Unhumanized LLM mush that would make a peer ask “what do they mean?”
