# Evidence gate (mandatory before user-facing review output)

Orchestrators (`engineer-reviewer`, `pr-reviewer`, `multi-repo-supervisor` merge) **must not** show a Fixed / Clarify / Findings item until it passes this gate. Phase agents **must** fill these fields in JSON; if they do not, the orchestrator backfills or drops the item.

## Required fields (every `fixed` / `clarify` with a file)

| Field | Rule |
|-------|------|
| `path` | Repo-relative path to the file |
| `start_line` | 1-based integer; first line of the problem (or of the nearest quote if code is missing) |
| `end_line` | ≥ `start_line`; span ≤ 15 lines |
| `snippet` | Exact text of those lines (no ellipsis that hides the bug). Plain string; orchestrator will fence it. |

Items that are only free-text philosophy with no file → do not put them in Fixed/Clarify; at most one Residual note, or drop.

## Phase agent duty

Before returning JSON: for each finding, open the file (or `git show HEAD_SHA:path`), set `start_line`/`end_line`, copy the lines into `snippet`. **No path-only findings.** Lint tools already give line numbers — always copy them into `start_line` and pull the snippet.

## Orchestrator backfill (if phase omitted evidence)

For each incomplete item:

```bash
# From the consumer repo root; use HEAD_SHA from the review range (or WORKTREE if checked out)
KIT="$(cat .cursor/cursor-spells-kit-path 2>/dev/null || cat "$HOME/.cursor/cursor-spells-kit-path")"
"$KIT/scripts/extract-review-snippet.sh" "<HEAD_SHA|WORKTREE>" "<path>" "<start_line>" "<end_line>"
```

If `start_line` is missing but `path` is known: search the diff hunk (`git diff BASE HEAD -- path`) for the symbol named in `summary`, then extract. If still impossible → **drop the finding** (or demote to a single Residual that says evidence was unavailable) — never print a bare `path: summary` bullet.

## User-facing Where block (exact shape — do not invent a thinner one)

Every finding in the markdown report **must** contain this block verbatim in structure:

```markdown
- **Where:**
  - File: [`src/foo.ts`](src/foo.ts)
  - Lines: **18–24**
  - Jump: [`src/foo.ts:18`](src/foo.ts#L18)
  - GitHub: [blob link](https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/src/foo.ts#L18-L24)
```

Omit the GitHub bullet only when owner/repo/`HEAD_SHA` cannot be resolved. Never omit File / Lines / Jump.

Then immediately the code fence:

````markdown
```ts
18|  const x = ...
19|  ...
```
````

Prefer numbering lines in the fence (`N| code`) so the reader sees the same numbers as Jump. Language tag from file extension.

## Emit gate checklist

Before sending the report to the user, verify for **every** Fixed / Clarify / Findings item:

- [ ] `path` present
- [ ] `start_line` and `end_line` present
- [ ] Code fence with real source (not “see file”, not empty)
- [ ] Where block with File + Lines + Jump links
- [ ] What / Why / Ask-or-fix prose humanized

If any checkbox fails → fix or remove that item, then emit.
