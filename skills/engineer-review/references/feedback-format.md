# Review feedback format

User-facing output for `engineer-review` / `engineer-reviewer` (and the shared base for `pr-review`). Every finding must answer: **what broke / looks wrong**, **where exactly**, **why it matters**, **what to do**.

**Before emitting:** pass every item through [evidence-gate.md](evidence-gate.md) and reject anything in [forbidden-formats.md](forbidden-formats.md). No exception for “small” nits that still name a file.

**Do not** replace this template with a short Verdict / Blockers / Блокери digest. Class or migration names without File + Jump + code fence are not locations.

## Hard requirements per finding

1. **Clickable location (exact Where block)** — see evidence-gate.md. Must include File link, Lines, Jump (`path#L…`), and GitHub blob when known.
2. **Code snippet** — fenced, preferably `N| code` line prefixes matching `start_line`…`end_line`. Never “see file above” or empty fences.
3. **Human wording** — `english-humanizer` (or its voice rules). Never humanize paths/code.
4. **What / Where / Why / Ask-or-fix** structure.

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
- **Where:**
  - File: [`src/foo.ts`](src/foo.ts)
  - Lines: **18–24**
  - Jump: [`src/foo.ts:18`](src/foo.ts#L18)
  - GitHub: [src/foo.ts#L18-L24](https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/src/foo.ts#L18-L24)
- **Why it matters:** …
- **Fix applied:** …  <!-- or "Would fix:" -->

```ts
18|  const x = await load();
19|  if (!x) return;
20|  return x.value;
```

## Needs clarification

### C1 — `P0|P1` — <short concrete title>
- **What:** …
- **Where:**
  - File: [`src/bar.ts`](src/bar.ts)
  - Lines: **40–45**
  - Jump: [`src/bar.ts:40`](src/bar.ts#L40)
- **Why it matters:** …
- **Ask:** …  
  - Options: A / B / C

```ts
40|  // …
```

## Residual notes
Only nits that still include Where + snippet when they point at code. Max 5. Otherwise drop.
```

If **Needs clarification** is non-empty, end with:

> Reply with answers like `C1: A` (or free text). I will re-run the affected phases and apply agreed fixes.

## Mapping from phase JSON

| Phase field | Feedback field |
|-------------|----------------|
| `severity` | badge on the heading |
| `path` + `start_line`/`end_line` | Where File / Lines / Jump |
| `snippet` | fenced body (orchestrator adds `N\|` prefixes if missing) |
| `summary` / `question` | What + Why + Ask/Fix after humanizer |

## Anti-patterns (block emit)

- Any finding without a code fence of real source
- Any finding without Jump / File links
- One-liner `` `P1` `path`: summary ``
- “See `src/foo.ts`” without lines + snippet
- Executive digests: `Verdict:…`, `### Blockers (P0)`, `### Блокери`, `### Also (P1)` without per-finding Where + fences — see [forbidden-formats.md](forbidden-formats.md)
- Shipping a PR comment draft **instead of** the full Findings section

After drafting, run `scripts/validate-review-report.sh` on the markdown; fix until exit 0.
