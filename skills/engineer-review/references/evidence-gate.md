# Evidence gate (mandatory before user-facing review output)

Orchestrators (`csp-engineer-reviewer`, `csp-pr-reviewer`, `csp-multi-repo-supervisor` merge) **must not** show a Fixed / Clarify / Findings item until it passes this gate. Phase agents **must** fill these fields in JSON; if they do not, the orchestrator backfills or drops the item.

Also read [forbidden-formats.md](forbidden-formats.md): a “Verdict / Blockers / Блокери” digest with class names but **no** File/Jump/snippet is a failed report even if the analysis is right.

## Required fields (every `fixed` / `clarify` with a file)

| Field | Rule |
|-------|------|
| `path` | Repo-relative path to the file |
| `start_line` | 1-based integer; first line of the problem (or of the nearest quote if code is missing) |
| `end_line` | ≥ `start_line`; span ≤ 15 lines |
| `snippet` | Exact text of those lines (no ellipsis that hides the bug). Plain string; orchestrator will fence it. |
| `context` | 1–2 sentences for the user-facing **Context** line (what this code/scenario does). Orchestrator may draft from `summary`/`question` if missing, but prefer phase-filled. |

### Extra required on every `clarify`

| Field | Rule |
|-------|------|
| `question` | Full decision text the human must answer — plain sentences, not a one-word title. |
| `what` | What is wrong (1–2 sentences). Prefer phase-filled; orchestrator may draft once from `context` + `question`. |
| `when_shows` | When a developer or user hits this problem (concrete scenario, 1–2 sentences). Prefer phase-filled; orchestrator may draft once from `context` + `question`. |
| `options` | Array of `{ "id": "A"\|"B"\|"C"…, "label": "…" }` — 2–3 choices (escape “other” is added by HITL, not required in JSON) |
| `recommended` | Option `id` string, or `null` when the phase cannot recommend |
| `recommendation_why` | One short line when `recommended` is set; omit or empty when null |

**Handoff rule:** phase Task results must return these strings in full. Truncating `context` / `what` / `when_shows` / `question` / `snippet` / option labels before the parent merge is a failed phase return — treat as incomplete evidence.

Items that are only free-text philosophy with no file → do not put them in Fixed/Clarify; at most one Residual note, or drop.

## Phase agent duty

Before returning JSON: for each finding, open the file (or `git show HEAD_SHA:path`), set `start_line`/`end_line`, copy the lines into `snippet`, and write `context`. For clarify items, fill structured `options`, prefer a `recommended` id for P0/P1 (safest / closest to patterns or AC), plus `recommendation_why`. **No path-only findings.** Lint tools already give line numbers — always copy them into `start_line` and pull the snippet.

## Orchestrator backfill (if phase omitted evidence)

For each incomplete item:

```bash
# From the consumer repo root; use HEAD_SHA from the review range (or WORKTREE if checked out)
KIT="$(cat .cursor/cursor-spells-kit-path 2>/dev/null || cat "$HOME/.cursor/cursor-spells-kit-path")"
"$KIT/scripts/extract-review-snippet.sh" "<HEAD_SHA|WORKTREE>" "<path>" "<start_line>" "<end_line>"
```

If `start_line` is missing but `path` is known: search the diff hunk (`git diff BASE HEAD -- path`) for the symbol named in `summary`, then extract. If still impossible → **drop the finding** (or demote to a single Residual that says evidence was unavailable) — never print a bare `path: summary` bullet.

If `options` are missing on a clarify item: derive 2–3 labeled choices from `question` when possible; otherwise drop or demote. Do **not** invent a `recommended` id when the phase left it null — emit **Recommendation:** none.

## User-facing Where block (exact shape — do not invent a thinner one)

Every finding in the markdown report **must** contain this block verbatim in structure:

```markdown
- **Where:**
  - File: [`src/foo.ts`](src/foo.ts)
  - Lines: **18–24**
  - Jump: [`src/foo.ts:18`](src/foo.ts#L18)
  - GitHub: [blob link](https://github.com/<owner>/<repo>/blob/<HEAD_SHA>/src/foo.ts#L18-L24)
```

Omit the GitHub bullet only when owner/repo/`HEAD_SHA` cannot be resolved. Never omit File / Lines / Jump. Prefer `#Lstart` on Jump and `#Lstart-Lend` on GitHub so the reader can open the exact span from chat.

Then immediately the code fence:

````markdown
```ts
18|  const x = ...
19|  ...
```
````

Prefer numbering lines in the fence (`N| code`) so the reader sees the same numbers as Jump. Language tag from file extension.

Do not call `open_resource` for every finding; workspace markdown links are enough. Open a file via `open_resource` (`file:///…#L…`) only when the user explicitly asks.

## Emit gate checklist

Before sending the report to the user, verify for **every** Fixed / Clarify / Findings item:

- [ ] `path` present
- [ ] `start_line` and `end_line` present
- [ ] Code fence with real source (not “see file”, not empty)
- [ ] Where block with File + Lines + Jump links
- [ ] **Context** line present
- [ ] What / Why / Ask-or-fix prose humanized
- [ ] Each Clarify has **What**, **When it shows up**, **Options**, and **Recommendation** (or explicit none)
- [ ] Report is **not** a Verdict/Blockers digest ([forbidden-formats.md](forbidden-formats.md))
- [ ] Clarify fields were not re-summarized away from phase JSON (verbatim handoff)

Then write the markdown to a temp file and run:

```bash
KIT="$(cat .cursor/cursor-spells-kit-path 2>/dev/null || cat "$HOME/.cursor/cursor-spells-kit-path")"
"$KIT/scripts/validate-review-report.sh" /tmp/review-report.md
# or: ./scripts/validate-review-report.sh /tmp/review-report.md
```

If the validator exits non-zero → rebuild or drop items; **do not** show the failed markdown to the user.
