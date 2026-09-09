# Review-learn capture (phase / review-learn owned)

Capture shape, stores, and `mode:load` filtering details for agent `review-learn`. Orchestrator does **not** load this file — see thin [`review-learn-protocol.md`](review-learn-protocol.md).

## Reliability rules (capture)

1. **Never** silently edit kit checklists from a consumer-app review. Kit publishes use skill `teach-review`.
2. **`project_secret` may keep client / internal product names** — that is why the row stays in this project. Still strip passwords, tokens, and personal data.
3. **Prefer link-over-invent:** if covered by R1–R7, F1–F7, V1–V4, or another kit gate, record `gate: R#` / `F#` / `V#` / `I1` — do not duplicate the rule body in the ledger.
4. **Dedup** by `id`. Same class → bump `hits` / `last_seen`.
5. **Cap** consumer Active at **20**; archive oldest (keep last 20 archived).
6. **Never** ask HITL **Review-learn promote** on `project_secret` capture.
7. Do not write the consumer ledger and kit instructions on the same miss.

## Stores

| Store | Path | Who writes | Who reads |
|-------|------|------------|-----------|
| Consumer ledger | `<project>/.cursor/review-learnings.md` | `review-learn` `mode:capture` **only after** `project_secret` | `review-learn` `mode:load` only |
| Kit seed | `skills/engineer-review/references/learned-misses.md` | Humans / kit pull requests via `teach-review` | `review-learn` `mode:load` only |
| Template | `skills/engineer-review/references/review-learnings-template.md` | — | First create on capture |

Do not delete an existing consumer ledger. Leave it in place even if new rows are rare.

Optional: `ce-compound` as a separate follow-up — never block review-learn on it.

## When to capture (triggers)

| Trigger | When |
|---------|------|
| `project_secret` | Human chose token `project_secret` on **Teach-review miss** or **Capture-escape destination**, and the description is non-empty |

Do not capture from a settled report without `project_secret`. Do not auto-append on highest-severity findings, replay misses, or production escapes. Production escapes use `/capture-escape`, which asks destination first.

Skip otherwise → `review_learn: n/a`.

## Capture shape (one entry)

```yaml
id: miss_<kebab-class>
miss_class: side-effect × live actor
triggers:
  - resetApiState | sync vs defer | remount/key=
phases: [logic, architecture]
gate: R1                          # existing kit gate pointer, or omit
rule_one_liner: >-
  After side-effect timing changes, replay live actors before closing.
anti_pattern: >-
  Diff-only review of the writer without still-mounted consumers.
hits: 1
last_seen: YYYY-MM-DD
source: engineer-review | bug-fix | production-escape
destination: project_secret
```

Body ≤6 lines. Client / internal names allowed. No passwords, tokens, or personal data.

## Process

### `mode:load` (before phase dispatch)

1. Read kit seed + consumer ledger (if any), match `triggers` against the diff (path names + short diff skim — not full-tree).
2. Return compact JSON only (≤**5** hints; ≤**80 tokens** each). Prefer highest `hits` then newest `last_seen`.
3. Each hint: `id`, `gate`, `phases`, `rule_one_liner`, `checklist` path — never full ledger bodies or checklist text.
4. Unmatched / empty → `learned_hints: []`, `review_learnings: absent|loaded`.

### `mode:capture` (only after `project_secret`)

1. Caller must pass destination `project_secret` and a non-empty description. Else `review_learn: n/a`.
2. Max **2** miss classes per round. Dedup → bump hits (`review_learn: deduped`) or append (`appended`). Create the ledger from the template if needed. Map to existing **R#** or **F#** (or another kit gate such as **I1**) when possible as a pointer only.
3. Never ask **Review-learn promote**. Never edit kit files.

### bug-fix escape path

`/capture-escape` asks **Capture-escape destination**. `project_secret` → `mode:capture` with `source: production-escape`. `miss` → skill `teach-review` (not this protocol’s write path).

## Anti-patterns

- Phase treating `rule_one_liner` as sufficient and skipping the linked checklist (**quality miss**)
- Auto-rewriting kit checklists from an app review
- Auto-capturing into the consumer ledger after a settled report without `project_secret`
- Running `teach-review` and `mode:capture` on the same miss
- Passwords, tokens, or personal data in the ledger
- Asking **Review-learn promote** after `project_secret`
- Inventing a new R-number or F-number when R1–R7 or F1–F7 already cover the miss
- Pasting full findings into the ledger
- Closing a table / expandable-card / overlay UI pass on the desktop Figma frame without **V1–V4** (`responsive-layout-checklist.md`)
- Orchestrator loading this file or full ledgers into its own prompt
