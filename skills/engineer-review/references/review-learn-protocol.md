# Review-learn protocol (self-strengthening)

After a human marks a miss as **project-private**, capture it in this project's ledger so the next review in **this** project can load it. Shareable misses go through skill `teach-review` (kit instructions), not this ledger.

## Quality vs orchestrator size (do not trade these off)

| Layer | Responsibility | Token rule |
|-------|----------------|------------|
| **Orchestrator** (`engineer-reviewer`) | Dispatch only — never deep-read ledgers or R1–R7 / F1–F7 / V1–V4 bodies | Pass paths + compact JSON from `review-learn`; max **~200 tokens** of hints in its own context |
| **`review-learn` (`mode:load`)** | Filter ledgers against the diff; return compact `learned_hints` JSON | Reads ledgers; returns ≤**5** matching hints, ≤**80 tokens** each |
| **Phase agents** (logic / architecture / security / figma / patterns…) | Apply full gates when a hint matches | On match: **must** open the linked checklist (`interaction-replay-checklist.md`, `auth-rtk-checklist.md`, `figma-markup-checklist.md`, `responsive-layout-checklist.md`, …) and run the real checks — the one-liner is a pointer, not the review |

Thin orchestrator ≠ thin review. Dropping full checklist loads from a matched hint is a **quality regression**; bloating the orchestrator with full ledgers is a **budget regression**. Fix by keeping work in `review-learn` + phases.

**Reliability rules (non-negotiable):**

1. **Never** silently edit kit checklists from a consumer-app review. Kit publishes use skill `teach-review`.
2. **`project_secret` may keep client / internal product names** — that is why the row stays in this project. Still strip passwords, tokens, and personal data.
3. **Prefer link-over-invent:** if covered by R1–R7, F1–F7, V1–V4, or another kit gate, record `gate: R#` / `F#` / `V#` / `I1` — do not duplicate the rule body in the ledger.
4. **Dedup** by `id`. Same class → bump `hits` / `last_seen`.
5. **Cap** consumer Active at **20**; archive oldest (keep last 20 archived).
6. **Never** ask HITL **Review-learn promote** on `project_secret` capture.
7. Orchestrator **must not** paste ledger markdown or checklist bodies into its own context — delegate to `review-learn` / phases.
8. Do not write the consumer ledger and kit instructions on the same miss.

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

### `mode:load` (before phase dispatch) — orchestrator stays thin

1. Orchestrator dispatches **`review-learn`** with `mode: load`, `BASE_SHA`/`HEAD_SHA` (or changed-path list). It does **not** read ledger files itself.
2. `review-learn` reads kit seed + consumer ledger (if any), matches `triggers` against the diff (path names + short diff skim — not full-tree).
3. Return compact JSON only:

```json
{
  "phase": "learn",
  "mode": "load",
  "review_learnings": "loaded",
  "learned_hints": [
    {
      "id": "miss_side-effect-live-actor",
      "gate": "R1",
      "phases": ["logic", "architecture", "security"],
      "rule_one_liner": "…",
      "checklist": "skills/engineer-review/references/interaction-replay-checklist.md"
    }
  ]
}
```

Caps: **≤5** hints; prefer highest `hits` then newest `last_seen`. Unmatched / empty → `learned_hints: []`, `review_learnings: absent|loaded`.
4. Orchestrator forwards `learned_hints` only to phases listed on each hint (do not broadcast to every phase).
5. **Phase quality rule:** if a hint’s `phases` includes this phase, the phase **must** read `checklist` (and auth specialization when `gate` is auth-shaped) and execute those checks. Skipping the checklist after a match is forbidden.

### `mode:capture` (only after `project_secret`)

1. Caller must pass destination `project_secret` and a non-empty description. Else `review_learn: n/a`.
2. Max **2** miss classes per round. Dedup → bump hits (`review_learn: deduped`) or append (`appended`). Create the ledger from the template if needed. Map to existing **R#** or **F#** (or another kit gate such as **I1**) when possible as a pointer only.
3. Never ask **Review-learn promote**. Never edit kit files.
4. Orchestrator records Coverage line only — does not re-read the ledger.

### bug-fix escape path

`/capture-escape` asks **Capture-escape destination**. `project_secret` → `mode:capture` with `source: production-escape`. `miss` → skill `teach-review` (not this protocol’s write path).

## Coverage lines

```text
review_learnings: loaded <n> | absent
review_learn: appended | deduped | skipped | n/a
```

## Anti-patterns

- Orchestrator loading full `learned-misses.md` / consumer ledger / R1–R7 / F1–F7 / V1–V4 into its own prompt
- Phase treating `rule_one_liner` as sufficient and skipping the linked checklist (**quality miss**)
- Auto-rewriting kit checklists from an app review
- Auto-capturing into the consumer ledger after a settled report without `project_secret`
- Running `teach-review` and `mode:capture` on the same miss
- Passwords, tokens, or personal data in the ledger
- Asking **Review-learn promote** after `project_secret`
- Inventing a new R-number or F-number when R1–R7 or F1–F7 already cover the miss
- Pasting full findings into the ledger
- Closing a table / expandable-card / overlay UI pass on the desktop Figma frame without **V1–V4** (`responsive-layout-checklist.md`)
