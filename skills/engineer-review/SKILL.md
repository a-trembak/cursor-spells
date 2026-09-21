---
name: engineer-review
description: >-
  Use when a plan just finished and human-in-the-loop review gate is next, when
  the user runs /csp-engineer-review or asks for engineer-reviewer, or when
  approving automated post-plan code review across Java/Spring, React,
  TypeScript, or React Native changes. Findings must include Context,
  code snippets, clickable file:line links, english-humanizer prose, and
  structured clarify Options with a marked Recommendation (never invent
  recommended).
---

# Engineer Review

Thin orchestrator for multi-phase code review. **This file is the canonical spine.** Agent `csp-engineer-reviewer` is a short pointer plus hard rules. User-facing feedback must meet [references/feedback-format.md](references/feedback-format.md) — load that pack **at merge/report time only**.

## When to Use

- After plan execution, once the user answers the HITL gate (`skip` / `approve` / `done`) — usually via skill `finish-plan`
- Manual `/csp-engineer-review` or `@csp-engineer-reviewer`
- Not for drive-by questions that are not a review of a diff/branch

## HITL gate (required before auto-review)

If this run was triggered because a **plan finished**, do **not** start phases until the user answers via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Finish-plan / engineer-review / multi-repo HITL**:

- `skip` — start review now
- `approve` or `done` — start after their own pass
- `fixes` / typed fix description — treat as “fix first”, then re-ask

Prefer skill/command `finish-plan` to set `.cursor/gates/review-gate/<slug>` reliably. If `skip` / `approve` / `done` already appear in chat after the gate was asked, clear this plan's marker and start — do not re-prompt.

Manual `/csp-engineer-review` skips this gate.

## Early Figma ask (frontend)

After HITL approval (or at the start of manual review), if stack is `react-web` or `react-native`, ask **before** phase dispatch via skill **`hitl-choice`** preset **Figma ask** (AskQuestion required; text fallback only after failed/missing tool: paste links or `no figma`).

Pass URLs into clarifications for `csp-review-figma-markup`. Do not block other phases on the answer if the user already said `no figma` / `no_figma`; if they have not answered yet, run non-figma phases first and keep figma skipped until URLs arrive.

## Spine (do this in order)

1. Resolve review range (`base..head`, default current branch vs `main`/`master`/`origin/main`).
2. Detect stack → read [references/skill-map-orch.md](references/skill-map-orch.md) (full map is phase/installer-owned: [skill-map.md](references/skill-map.md)).
3. **Budget**: compute changed files / LOC (`git diff --name-only` + `--numstat`).
4. **Catastrophic abort** (see [phase-protocol.md](references/phase-protocol.md)): if files > **200** or LOC > **50_000**, stop and ask the user to narrow (path allow/deny list, smaller range, exclude generated/lockfile noise). Do not chunk-spam or sample randomly. Abort does **not** load the merge feedback pack.
5. **Graphify scoping** (preferred when present): apply [references/graphify-protocol.md](references/graphify-protocol.md) (detect + `impact_hint` only). If graphify is absent or unqueryable, skip — behavior matches today’s diff-only path. Never rebuild the graph during review. Phases load [graphify-r3-force-include.md](references/graphify-r3-force-include.md) when triggered.
6. **Learnings (thin):** dispatch `csp-review-learn` `mode:load` — orchestrator does **not** read ledgers or `learned-misses.md`. Forward ≤5 `learned_hints` only to listed phases. See [review-learn-protocol.md](references/review-learn-protocol.md). Coverage: `review_learnings: loaded N|absent`.
7. If changed files > 40 or changed LOC > 2500 (and under the catastrophic caps), split into chunks (prefer graph modules when graphify answered; otherwise directory/package — see [phase-protocol.md](references/phase-protocol.md)).
8. Ensure consumer `.cursor/project-patterns.md` exists (create via patterns agent + [patterns-template.md](references/patterns-template.md) on first run).
9. Early Figma ask when frontend (above).
10. Dispatch phase subagents per phase-protocol (pass `graphify_available` + optional `impact_hint` + per-phase `learned_hints`). Run `csp-review-lint` first; then parallel **find** for remaining heuristic phases (**including** `csp-review-simplify`); serialize **apply** for `unambiguous && (P0|P1)` only (eligibility: [auto-fix-eligibility.md](references/auto-fix-eligibility.md)). Phases own checklist bodies — orchestrator does not load them.
11. After apply: verify `csp-review-lint` + `csp-review-simplify` once each in `find`; do not loop.

12. **Merge → report (lazy feedback pack):** load [evidence-gate.md](references/evidence-gate.md) → [feedback-format.md](references/feedback-format.md) + [forbidden-formats.md](references/forbidden-formats.md) + [output-schema.md](references/output-schema.md) **only now**; never *emit* formats banned by [forbidden-formats.md](references/forbidden-formats.md). Coverage: `graphify:…`, `review_learnings:…`, when in scope `interaction_replay:…` (**R7**), `figma_markup:…` (**F7**), `narrow_viewport:…` (**V4**), `null_safety_callers:…` (**N1**), and `jpa_result_type:…` (**RT1**). Validate with `scripts/validate-review-report.sh`. When the kit path is known, also append a live quality row: `python3 "$KIT"/scripts/pipeline-metrics.py append-review --kit-root "$KIT" --path <validated-report> [--ticket "<live ticket key>"]` (skip quietly if `pipeline-metrics.py` is missing). Then `english-humanizer` then `plain-language-chat` on prose.
13. Needs clarification → HITL **Engineer-review clarify**; each sequential question repeats File, Lines, Jump, and numbered fence; re-dispatch affected phases. R1 timing/host answers also re-dispatch logic + architecture with `interaction_replay` (phases load checklists — orchestrator does not).
14. **Teach-review miss:** after the validated report is shown, ask via skill `hitl-choice` preset **Teach-review miss** (`miss` / `project_secret` / `no_miss`). Recommended: `miss`. **Never edit kit git** in this orchestrator. Do not auto-capture.
    - `no_miss` → do not invoke `teach-review`; do not dispatch `csp-review-learn` `mode:capture`.
    - `miss` → collect description (open-ended if needed), invoke skill `teach-review`. If `teach-review` fails, keep the report; tell the human to retry with `/csp-teach-review`.
    - `project_secret` → collect description (open-ended if needed), dispatch `csp-review-learn` `mode:capture` with destination `project_secret`. Coverage: `review_learn: appended|deduped|skipped|n/a`. Do not ask **Review-learn promote**. Never edit kit files.
    Do not write both stores on the same miss. Production misses **without** a full review use slash command `/csp-capture-escape` (destination `miss` or `project_secret`). Append session ledger per skill `trajectory-score` (stage `engineer-review`, gate `teach-review-miss`, artifact report `engineer-review`, end `review_report: evidence-gated`).
15. After a successful **pipeline** review (from `/csp-start-task` / `finish-plan` / `/csp-start-task --fast` / `/csp-start-issue-task`), once the report is settled and teach-review-miss is handled: invoke skill **`propose-commit`** next. Then:
    - Full path: `update-docs` (existing destination HITL), then if the tree is still dirty invoke **`propose-commit`** again for residual docs, then skill **`local-verify`**, then `create-pr`.
    - Fast / issue: skill **`local-verify`**, then `create-pr` (no `update-docs` unless the human asked).
    Manual `/csp-engineer-review` does **not** auto-start `propose-commit`, `update-docs`, or `local-verify` unless the human asks.

## Fix policy

- Apply immediately: unambiguous **P0/P1** that also passes [`references/auto-fix-eligibility.md`](references/auto-fix-eligibility.md) (bugs, dead code, obsolete historical comments, clear pattern violations, reinvented helpers).
- **P2** → Residual notes only.
- Clarify first: behavior/API/product/design/security tradeoffs, risky deletions, spec/diff traceability mismatches, anything without clear evidence or that fails the eligibility test.

## Phase agents

| Phase | Agent |
|-------|-------|
| Lint / typecheck / build (deterministic tooling) | `csp-review-lint` |
| Logic + stack best practices | `csp-review-logic` |
| Project patterns | `csp-review-patterns` |
| Dead code / unused / comments | `csp-review-deadcode` |
| Cleanliness / reuse / local efficiency | `csp-review-simplify` (`ce-simplify-code`) |
| Architecture | `csp-review-architecture` |
| Performance | `csp-review-performance` |
| Security (conditional) | `csp-review-security` |
| Figma markup (frontend + URLs) | `csp-review-figma-markup` (always opens [figma-markup-checklist.md](references/figma-markup-checklist.md) F1–F7 — phase-owned) |
| Learn / load hints (before phases); capture only after `project_secret` | `csp-review-learn` |

`csp-review-lint` runs actual project tooling rather than LLM judgment.

`csp-review-simplify` uses compound-engineering **`ce-simplify-code`**, then **Kit extensions** from [`references/simplify-checklist.md`](references/simplify-checklist.md). Lens A–C are fallback only ([`simplify-lenses-fallback.md`](references/simplify-lenses-fallback.md)).

`csp-review-learn`: **`load`** before phases (orchestrator never reads ledgers); **`capture`** only after `project_secret`. Matched hints require phases to open the linked checklist.

Orchestrator agent: `csp-engineer-reviewer`. Plan handoff: `finish-plan`.

## Multi-repo

If the caller is `csp-multi-repo-supervisor`, or discovery finds **2+ changed repos**, defer to [references/multi-repo-protocol.md](references/multi-repo-protocol.md) and agent `csp-multi-repo-supervisor`. If discovery finds 0 changed repos, stop with a no-changes message; if it finds 1 changed repo, the single-repo path above is unchanged.

## Context budget

### Always-on (orchestrator)

- This `SKILL.md` + agent `csp-engineer-reviewer` hard rules
- [phase-protocol.md](references/phase-protocol.md) (inputs / caps / order / merge / Coverage)
- [review-learn-protocol.md](references/review-learn-protocol.md) (thin load/dispatch)
- [graphify-protocol.md](references/graphify-protocol.md) (detect + `impact_hint`)
- [skill-map-orch.md](references/skill-map-orch.md)
- [auto-fix-eligibility.md](references/auto-fix-eligibility.md)
- [patterns-template.md](references/patterns-template.md) when creating patterns
- [multi-repo-protocol.md](references/multi-repo-protocol.md) only on the multi-repo path

### Phase-only (do **not** load bodies into orchestrator)

- [phase-protocol-detail.md](references/phase-protocol-detail.md), [skill-map.md](references/skill-map.md), [review-learn-capture.md](references/review-learn-capture.md), [graphify-r3-force-include.md](references/graphify-r3-force-include.md)

- Checklists: `interaction-replay-checklist.md`, `auth-rtk-checklist.md`, `figma-markup-checklist.md`, `responsive-layout-checklist.md`, `null-safety-checklist.md`, `jpa-criteria-checklist.md`, `jpa-repository-result-checklist.md`, `styling-checklist.md`, `fixture-identifier-conventions.md`, `simplify-checklist.md`, `simplify-lenses-fallback.md`, `security-hardening-checklist.md`
- [learned-misses.md](references/learned-misses.md) (except pointing `csp-review-learn` at it)
- Phase agent prompts (`agents/csp-review-*.md`)

### Merge-only (load at report time — not at start; skip on abort)

- [feedback-format.md](references/feedback-format.md), [evidence-gate.md](references/evidence-gate.md), [forbidden-formats.md](references/forbidden-formats.md), [output-schema.md](references/output-schema.md)
- skills `english-humanizer` then `plain-language-chat`

Pass only compact JSON phase summaries upward. Enforce file/LOC caps via chunking; abort on catastrophic budgets instead of unbounded chunk fan-out.

`learned_hints` in orchestrator context: ≤**~200 tokens** total (≤5 rows). Quality lives in the phase that opens `checklist` on a match.

When [graphify-protocol.md](references/graphify-protocol.md) detects a usable build, **prefer** short `GRAPH_REPORT.md` excerpts and `graphify query` answers over broad repo reads. Never paste full `graph.json`.
