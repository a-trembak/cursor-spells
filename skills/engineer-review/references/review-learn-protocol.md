# Review-learn protocol (self-strengthening)

After engineer-review (or a post-escape bug-fix) surfaces a **real miss**, capture a durable learning so the next review loads it. This is the kit's self-strengthening loop — find → generalize → store → reload.

**Reliability rules (non-negotiable):**

1. **Never** silently edit kit checklists (`agents/review-*.md`, `interaction-replay-checklist.md`, etc.) from a consumer-app review.
2. **Always** generalize: strip product names, ticket ids, and one-off widgets before writing.
3. **Prefer link-over-invent:** if the miss is already covered by R1–R7 (or another kit gate), record `links_to: R#` and a one-line trigger — do not duplicate the rule body.
4. **Dedup** by `miss_class` id. Same class → bump `hits` / `last_seen`, do not append a twin.
5. **Cap** consumer file at **20** active entries; move oldest to `## Archive` (keep last 20 archived).
6. Consumer writes are **append/update only** under `.cursor/review-learnings.md`. Kit promotion is **HITL-gated** (or only when the current repo *is* `cursor-spells`).

## Stores

| Store | Path | Who writes | Loaded by |
|-------|------|------------|-----------|
| Consumer ledger | `<project>/.cursor/review-learnings.md` | Orchestrator / `review-learn` after eligible findings | Every engineer-review / pr-review |
| Kit seed | `skills/engineer-review/references/learned-misses.md` | Humans or kit PRs after HITL promote | Every engineer-review (always) |
| Template | `skills/engineer-review/references/review-learnings-template.md` | — | First create of consumer file |

Optional durable write-up: offer `ce-compound` separately — do not block review-learn on it.

## When to capture (triggers)

Run the learn step when **any** of:

| Trigger | Example |
|---------|---------|
| A | Report has applied or clarify **P0** correctness/security with a clear mechanism (not lint noise) |
| B | Post-clarify R1 replay exposed a live-actor hazard that the first pass missed |
| C | User / bug-fix states a **production escape** that prior review should have caught |
| D | Human answers HITL **review-learn promote** / `learn:yes` |

Skip when only P2 residuals, pure style/lint, or no new miss class (`review_learn: n/a`).

## Capture shape (one entry)

```yaml
# frontmatter-ish fields inside the markdown entry
id: miss_<kebab-class>          # stable; e.g. miss_side-effect-live-actor
miss_class: side-effect × live actor
triggers:                       # diff signals that should load this hint
  - resetApiState | sync vs defer | remount/key=
  - stateful input inside filtering host
phases: [logic, architecture]   # which phases must apply the gate
gate: R1                        # existing kit rule id, or "propose:<name>"
rule_one_liner: >-
  After side-effect timing changes, replay live subscriptions/host widgets
  before closing.
anti_pattern: >-
  Diff-only review of the writer without naming still-mounted consumers.
hits: 1
last_seen: YYYY-MM-DD
source: engineer-review | bug-fix | production-escape
```

Body (3–6 lines max): mechanism → required check → test shape (competing actor). **No** product-specific endpoint or widget names.

## Process

### Load (before phase dispatch)

1. Read kit `learned-misses.md` (always).
2. Read consumer `.cursor/review-learnings.md` if present; if missing, do not create yet.
3. Build compact `learned_hints` (max ~15 lines / ~400 tokens): id, triggers, gate, rule_one_liner, phases.
4. Pass `learned_hints` into logic, architecture, security, and any phase listed on an entry. Coverage: `review_learnings: loaded N | absent`.

### Capture (after report settled)

1. From Fixed / Clarify / production-escape notes, extract candidate miss class(es). Max **2** per review round.
2. Generalize; map to existing **R#** / checklist section when possible.
3. If duplicate `id` in consumer or kit → increment `hits`, update `last_seen`, stop (`review_learn: deduped`).
4. Else append to consumer `.cursor/review-learnings.md` (create from template if needed) → `review_learn: appended`.
5. If the rule is **new** (no existing gate) **and** general across projects → ask HITL preset **Review-learn promote** (`promote` / `consumer_only` / `skip`).  
   - `promote` only when editing the kit repo, or open a kit checklist PR task for the human — **never** auto-patch kit from a leaf app.  
   - `consumer_only` → keep ledger entry only.  
   - `skip` → do not write (rare; prefer consumer_only).

### bug-fix escape path

When `bug-fix` / `/start-issue-task` closes a defect with “review should have caught this”, invoke the same capture with `source: production-escape` before ending.

## Coverage lines

```text
review_learnings: loaded <n> | absent
review_learn: appended | deduped | skipped | n/a
```

## Anti-patterns

- Auto-rewriting `interaction-replay-checklist.md` from an app review
- Storing ticket-only or component-only “learnings” that cannot fire on another diff
- Pasting full finding reports into the ledger (bloated; useless as hints)
- Creating a new R-number without HITL when R1–R7 already cover the miss
