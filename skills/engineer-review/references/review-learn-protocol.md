# Review-learn protocol (self-strengthening)

After engineer-review (or a post-escape bug-fix) surfaces a **real miss**, capture a durable learning so the next review loads it. Loop: find → generalize → store → reload.

## Quality vs orchestrator size (do not trade these off)

| Layer | Responsibility | Token rule |
|-------|----------------|------------|
| **Orchestrator** (`engineer-reviewer`) | Dispatch only — never deep-read ledgers or R1–R7 bodies | Pass paths + compact JSON from `review-learn`; max **~200 tokens** of hints in its own context |
| **`review-learn` (`mode:load`)** | Filter ledgers against the diff; return compact `learned_hints` JSON | Reads ledgers; returns ≤**5** matching hints, ≤**80 tokens** each |
| **Phase agents** (logic / architecture / security…) | Apply full gates when a hint matches | On match: **must** open the linked checklist (`interaction-replay-checklist.md`, `auth-rtk-checklist.md`, …) and run the real checks — the one-liner is a pointer, not the review |

Thin orchestrator ≠ thin review. Dropping full checklist loads from a matched hint is a **quality regression**; bloating the orchestrator with full ledgers is a **budget regression**. Fix by keeping work in `review-learn` + phases.

**Reliability rules (non-negotiable):**

1. **Never** silently edit kit checklists from a consumer-app review.
2. **Always** generalize: strip product names, ticket ids, and one-off widgets before writing.
3. **Prefer link-over-invent:** if covered by R1–R7 (or another kit gate), record `gate: R#` — do not duplicate the rule body in the ledger.
4. **Dedup** by `id`. Same class → bump `hits` / `last_seen`.
5. **Cap** consumer Active at **20**; archive oldest (keep last 20 archived).
6. Kit promotion is **HITL-gated** (or only when cwd is `cursor-spells`).
7. Orchestrator **must not** paste ledger markdown or checklist bodies into its own context — delegate to `review-learn` / phases.

## Stores

| Store | Path | Who writes | Who reads |
|-------|------|------------|-----------|
| Consumer ledger | `<project>/.cursor/review-learnings.md` | `review-learn` `mode:capture` | `review-learn` `mode:load` only |
| Kit seed | `skills/engineer-review/references/learned-misses.md` | Humans / kit PRs | `review-learn` `mode:load` only |
| Template | `skills/engineer-review/references/review-learnings-template.md` | — | First create on capture |

Optional: `ce-compound` as a separate follow-up — never block review-learn on it.

## When to capture (triggers)

| Trigger | When |
|---------|------|
| A | Settled report has **P0** correctness/security with a clear mechanism (not lint noise) |
| B | Post-clarify R1 replay exposed a live-actor hazard the first pass missed |
| C | bug-fix / user: **production escape** prior review should have caught |
| D | Human chose HITL **Review-learn promote** / `learn:yes` |

Skip otherwise → `review_learn: n/a`.

## Capture shape (one entry)

```yaml
id: miss_<kebab-class>
miss_class: side-effect × live actor
triggers:
  - resetApiState | sync vs defer | remount/key=
phases: [logic, architecture]
gate: R1                          # or propose:<name>
rule_one_liner: >-
  After side-effect timing changes, replay live actors before closing.
anti_pattern: >-
  Diff-only review of the writer without still-mounted consumers.
hits: 1
last_seen: YYYY-MM-DD
source: engineer-review | bug-fix | production-escape
```

Body ≤6 lines. No product-specific names.

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

### `mode:capture` (after report settled)

1. Max **2** miss classes per round. Generalize; map to existing **R#** when possible.
2. Dedup → bump hits (`review_learn: deduped`) or append (`appended`).
3. New gate (`propose:…`) → HITL **Review-learn promote**. Never auto-patch kit from a leaf app.
4. Orchestrator records Coverage line only — does not re-read the ledger.

### bug-fix escape path

Production escape → `mode:capture` with `source: production-escape` (does not require a full engineer-review re-run). Slash command `/capture-escape` is the standalone entry for that path.

## Coverage lines

```text
review_learnings: loaded <n> | absent
review_learn: appended | deduped | skipped | n/a
```

## Anti-patterns

- Orchestrator loading full `learned-misses.md` / consumer ledger / R1–R7 into its own prompt
- Phase treating `rule_one_liner` as sufficient and skipping the linked checklist (**quality miss**)
- Auto-rewriting kit checklists from an app review
- Ticket-only or widget-only ledger entries
- Pasting full findings into the ledger
- Inventing a new R-number when R1–R7 already cover the miss
