---
name: engineer-review
description: >-
  Use when a plan just finished and human-in-the-loop review gate is next, when
  the user runs /engineer-review or asks for engineer-reviewer, or when
  approving automated post-plan code review across Java/Spring, React,
  TypeScript, or React Native changes. Findings must include Context,
  code snippets, clickable file:line links, english-humanizer prose, and
  structured clarify Options with a marked Recommendation (never invent
  recommended).
---

# Engineer Review

Thin orchestrator for multi-phase code review. Keeps the spine small; each phase runs as a separate subagent with its own skill. User-facing feedback must meet [references/feedback-format.md](references/feedback-format.md).

## When to Use

- After plan execution, once the user answers the HITL gate (`skip` / `approve` / `done`) — usually via skill `finish-plan`
- Manual `/engineer-review` or `@engineer-reviewer`
- Not for drive-by questions that are not a review of a diff/branch

## HITL gate (required before auto-review)

If this run was triggered because a **plan finished**, do **not** start phases until the user answers via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Finish-plan / engineer-review / multi-repo HITL**:

- `skip` — start review now
- `approve` or `done` — start after their own pass
- `fixes` / typed fix description — treat as “fix first”, then re-ask

Prefer skill/command `finish-plan` to set `.cursor/review-gate.pending` reliably. If `skip` / `approve` / `done` already appear in chat after the gate was asked, clear the marker and start — do not re-prompt.

Manual `/engineer-review` skips this gate.

## Early Figma ask (frontend)

After HITL approval (or at the start of manual review), if stack is `react-web` or `react-native`, ask **before** phase dispatch via skill **`hitl-choice`** preset **Figma ask** (AskQuestion required; text fallback only after failed/missing tool: paste links or `no figma`).

Pass URLs into clarifications for `review-figma-markup`. Do not block other phases on the answer if the user already said `no figma` / `no_figma`; if they have not answered yet, run non-figma phases first and keep figma skipped until URLs arrive.

## Spine (do this in order)

1. Resolve review range (`base..head`, default current branch vs `main`/`master`/`origin/main`).
2. Detect stack → read [references/skill-map.md](references/skill-map.md).
3. **Budget**: compute changed files / LOC (`git diff --name-only` + `--numstat`).
4. **Catastrophic abort** (see [phase-protocol.md](references/phase-protocol.md)): if files > **200** or LOC > **50_000**, stop and ask the user to narrow (path allow/deny list, smaller range, exclude generated/lockfile noise). Do not chunk-spam or sample randomly.
5. **Graphify scoping** (preferred when present): apply [references/graphify-protocol.md](references/graphify-protocol.md). Query impact for changed paths; build a compact `impact_hint`. If graphify is absent or unqueryable, skip this step — behavior matches today’s diff-only path. Never rebuild the graph during review.
6. If changed files > 40 or changed LOC > 2500 (and under the catastrophic caps), split into chunks (prefer graph modules when graphify answered; otherwise directory/package — see [phase-protocol.md](references/phase-protocol.md)).
7. Ensure consumer `.cursor/project-patterns.md` exists (create via patterns agent + [patterns-template.md](references/patterns-template.md) on first run).
8. Early Figma ask when frontend (above).
9. Dispatch phase subagents per phase-protocol (pass `graphify_available` + optional `impact_hint`). Run `review-lint` (deterministic tooling) first — it does not need patterns/skills and its findings are cheap and unambiguous. Then prefer parallel **find** passes for the remaining heuristic phases (**including** `review-simplify`); serialize **apply** for `unambiguous && (P0|P1)` only. Every fixed/clarify item **must** carry `path`, `start_line`, `end_line`, `snippet`, and `context`. Every clarify item **must** carry structured `options` (`[{ id, label }, …]`) and prefer `recommended` + `recommendation_why` for P0/P1 — never invent a recommendation when the phase left `recommended` null.
10. After the apply pass, re-run `review-lint` once in `find` mode as a verify step to confirm the diff still lints/typechecks clean. Then re-run `review-simplify` once in `find` mode over the final diff as a **quality verify** — catch leftover overbuilt / redundant / locally wasteful solutions that other phases' fixes did not remove. Add any new findings to the report; do not loop indefinitely.
11. Merge summaries → run [evidence-gate.md](references/evidence-gate.md) (backfill snippets via `scripts/extract-review-snippet.sh` or **drop** incomplete items) → draft report per [feedback-format.md](references/feedback-format.md) (never [forbidden-formats.md](references/forbidden-formats.md)):
   - **Context** + full Where block: File + Lines + Jump (+ GitHub when known)
   - Numbered code fence with real source
   - What / Why / Ask-or-fix; Clarify items also **Options** + **Recommendation** (or explicit “none”)
   - `english-humanizer` on prose
   - Coverage notes `graphify: used|absent|unqueryable`
   - Run `scripts/validate-review-report.sh` on the draft; rebuild until exit 0, then show the user
12. If **Needs clarification** is non-empty, stop and ask via skill **`hitl-choice`** preset **Engineer-review clarify** (sequential `AskQuestion` per `C#`; recommended option labeled; tokens `C1:A` / `C2:B`; batch text like `C1: A; C2: B` OK). On answers, re-dispatch only the affected phases with the answers embedded, then re-emit with the same evidence bar.

## Fix policy

- Apply immediately: unambiguous **P0/P1** that also passes [`references/auto-fix-eligibility.md`](references/auto-fix-eligibility.md) (bugs, dead code, obsolete historical comments, clear pattern violations, reinvented helpers).
- **P2** → Residual notes only.
- Clarify first: behavior/API/product/design/security tradeoffs, risky deletions, spec/diff traceability mismatches, anything without clear evidence or that fails the eligibility test.

## Phase agents

| Phase | Agent |
|-------|-------|
| Lint / typecheck / build (deterministic tooling) | `review-lint` |
| Logic + stack best practices | `review-logic` |
| Project patterns | `review-patterns` |
| Dead code / unused / comments | `review-deadcode` |
| Cleanliness / reuse / local efficiency | `review-simplify` (`ce-simplify-code`) |
| Architecture | `review-architecture` |
| Performance | `review-performance` |
| Security (conditional) | `review-security` |
| Figma markup (frontend + URLs) | `review-figma-markup` |

`review-lint` runs actual project tooling (eslint/tsc/checkstyle/…) rather than LLM judgment — it exists specifically to catch mechanical rule violations (e.g. `eslint import/first`, unused vars, type errors) that heuristic phases can miss.

`review-simplify` re-reads workable-but-messy solutions via compound-engineering **`ce-simplify-code`** (reuse / quality / efficiency personas), then always runs **Kit extensions** from [`references/simplify-checklist.md`](references/simplify-checklist.md). It defaults almost all findings to `clarify`; Lens A–C in that file are fallback only when the skill is missing.

Orchestrator agent: `engineer-reviewer`. Plan handoff: `finish-plan`. After a successful pipeline review (from `/start-task` / `finish-plan`), hand off to skill `update-docs` for the product-docs HITL destination gate — do not invent a docs destination. Manual `/engineer-review` does not auto-start `update-docs` unless the human asks.

## Multi-repo

If the caller is `multi-repo-supervisor`, or discovery finds **2+ changed repos**, defer to [references/multi-repo-protocol.md](references/multi-repo-protocol.md) and agent `multi-repo-supervisor`. If discovery finds 0 changed repos, stop with a no-changes message; if it finds 1 changed repo, the single-repo path above is unchanged.

## Context budget

Orchestrator loads this SKILL + reference indexes + `english-humanizer` for the final feedback pass. Do **not** paste full third-party skill bodies into the orchestrator. Subagents load stack skills themselves. Pass only compact JSON phase summaries upward. Enforce file/LOC caps via chunking; abort on catastrophic budgets instead of unbounded chunk fan-out.

When [graphify-protocol.md](references/graphify-protocol.md) detects a usable build, **prefer** short `GRAPH_REPORT.md` excerpts and `graphify query` answers over broad repo reads or pasting large diffs. Never paste full `graph.json`. When graphify is absent or unqueryable, keep the diff + chunk path unchanged.
