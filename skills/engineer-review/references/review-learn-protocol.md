# Review-learn protocol (orchestrator + load)

After a human marks a miss as **project-private**, capture it in this project's ledger so the next review in **this** project can load it. Shareable misses go through skill `teach-review` (kit instructions), not this ledger.

**Load routing:** orchestrator reads **this** file only (dispatch / caps / never read ledgers). Capture shape and store rules: [`review-learn-capture.md`](review-learn-capture.md) — owned by `csp-review-learn`. Checklist bodies stay phase-owned.

## Quality vs orchestrator size (do not trade these off)

| Layer | Responsibility | Token rule |
|-------|----------------|------------|
| **Orchestrator** (`csp-engineer-reviewer`) | Dispatch only — never deep-read ledgers or R1–R7 / F1–F7 / V1–V4 bodies | Pass paths + compact JSON from `csp-review-learn`; max **~200 tokens** of hints in its own context |
| **`csp-review-learn` (`mode:load`)** | Filter ledgers against the diff; return compact `learned_hints` JSON | Reads ledgers; returns ≤**5** matching hints, ≤**80 tokens** each |
| **Phase agents** (logic / architecture / security / figma / patterns…) | Apply full gates when a hint matches | On match: **must** open the linked checklist (`interaction-replay-checklist.md`, `auth-rtk-checklist.md`, `figma-markup-checklist.md`, `responsive-layout-checklist.md`, …) and run the real checks — the one-liner is a pointer, not the review |

Thin orchestrator ≠ thin review. Dropping full checklist loads from a matched hint is a **quality regression**; bloating the orchestrator with full ledgers is a **budget regression**.

**Reliability rules (orchestrator):**

1. **Never** silently edit kit checklists from a consumer-app review. Kit publishes use skill `teach-review`.
2. Orchestrator **must not** paste ledger markdown or checklist bodies into its own context — delegate to `csp-review-learn` / phases.
3. Do not write the consumer ledger and kit instructions on the same miss.
4. Never ask HITL **Review-learn promote** on `project_secret` capture.

## `mode:load` (before phase dispatch) — orchestrator stays thin

1. Orchestrator dispatches **`csp-review-learn`** with `mode: load`, `BASE_SHA`/`HEAD_SHA` (or changed-path list). It does **not** read ledger files itself (including kit `learned-misses.md`).
2. `csp-review-learn` returns compact JSON only:

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
3. Orchestrator forwards `learned_hints` only to phases listed on each hint (do not broadcast to every phase).
4. **Phase quality rule:** if a hint’s `phases` includes this phase, the phase **must** read `checklist` and execute those checks. Skipping the checklist after a match is forbidden.

## `mode:capture` (orchestrator dispatch only)

After Teach-review miss → `project_secret` (non-empty description): dispatch `csp-review-learn` `mode:capture` with destination `project_secret`. Coverage: `review_learn: appended|deduped|skipped|n/a`. Do not ask **Review-learn promote**. Never edit kit files. Capture shape: [`review-learn-capture.md`](review-learn-capture.md). **Do not capture from a settled report without** `project_secret`. On capture, map to existing **R#** or **F#** (or another kit gate) as a pointer only — detail in the capture file.

## Coverage lines

```text
review_learnings: loaded <n> | absent
review_learn: appended | deduped | skipped | n/a
```

## Anti-patterns (orchestrator)

- Orchestrator loading full `learned-misses.md` / consumer ledger / R1–R7 / F1–F7 / V1–V4 into its own prompt
- Running `teach-review` and `mode:capture` on the same miss
- Asking **Review-learn promote** after `project_secret`
