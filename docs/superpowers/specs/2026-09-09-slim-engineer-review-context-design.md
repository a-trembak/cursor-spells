# Slim engineer-review orchestrator context

## Status

`approved` — shrink orchestrator prompt load for `engineer-review` / `csp-engineer-reviewer` without deleting phase checklists or regressing review quality.

## Goal

Cut bytes the **orchestrator** must load up front so more of the context window stays available for dispatch, budget, and Coverage. Phase agents and `csp-review-learn` keep full checklist quality. Merge/report loads feedback formatting only when a report will be shown.

## Decisions

### Always-on (orchestrator)

| File | Why |
|------|-----|
| `skills/engineer-review/SKILL.md` | Canonical spine (HITL, budget, dispatch, teach-review, pipeline handoff) |
| `agents/csp-engineer-reviewer.md` | Thin pointer + hard rules tests and safety require |
| `references/phase-protocol.md` | Inputs, caps, order, merge, Coverage (orch-owned) |
| `references/review-learn-protocol.md` | Thin load/dispatch: ≤5 hints; never read ledgers |
| `references/graphify-protocol.md` | Detect + `impact_hint` + orchestrator hook |
| `references/skill-map-orch.md` | Stack-detect (+ lint command table) only |
| `references/auto-fix-eligibility.md` | Apply gate for unambiguous P0/P1 |
| `references/patterns-template.md` | First-run patterns create |
| `references/multi-repo-protocol.md` | Only when multi-repo path applies |

Abort / skip / catastrophic-narrow paths use **only** always-on files. They must not require the merge pack.

### Phase-only (never paste bodies into orchestrator)

| File | Owner |
|------|--------|
| `references/phase-protocol-detail.md` | JSON schema, process, apply detail, skip conditions |
| `references/skill-map.md` | Full map (Database ids, phase→skills, installer source of truth) |
| `references/review-learn-capture.md` | Capture shape + store rules for `csp-review-learn` |
| `references/graphify-r3-force-include.md` | R3 force-include neighborhood |
| `references/interaction-replay-checklist.md` | R1–R7 |
| `references/auth-rtk-checklist.md` | Auth specialization |
| `references/figma-markup-checklist.md` | F1–F7 |
| `references/responsive-layout-checklist.md` | V1–V4 |
| `references/null-safety-checklist.md` | N1 |
| `references/jpa-criteria-checklist.md` | J1–J2 |
| `references/jpa-repository-result-checklist.md` | RT1 |
| `references/styling-checklist.md` | S1–S2 |
| `references/fixture-identifier-conventions.md` | I1 |
| `references/simplify-checklist.md` | Kit extensions (+ pointer to lenses) |
| `references/simplify-lenses-fallback.md` | Lens A–C when `ce-simplify-code` missing |
| `references/learned-misses.md` | Kit seed — `csp-review-learn` `mode:load` only |
| `references/review-learnings-template.md` | Capture create |
| Phase agent prompts (`agents/review-*.md`) | Trigger → open full checklist |

Orchestrator may **point** phases / `csp-review-learn` at these paths. It must **not** instruct loading their bodies into orchestrator context (except naming them as phase-owned).

### Merge-only (load at report time, not at start)

| File / skill | When |
|--------------|------|
| `references/feedback-format.md` | After merge, before user-facing report |
| `references/evidence-gate.md` | Same |
| `references/forbidden-formats.md` | Same |
| `references/output-schema.md` | Same |
| skill `english-humanizer` | Final prose pass |
| skill `plain-language-chat` | Final prose pass |

If the run aborts (catastrophic budget) or skips without a findings report, do **not** load this pack.

## Do-not-delete checklist list

Never delete or empty these quality bodies (shrink is load-routing only):

- `interaction-replay-checklist.md`
- `auth-rtk-checklist.md`
- `figma-markup-checklist.md`
- `responsive-layout-checklist.md`
- `null-safety-checklist.md`
- `jpa-criteria-checklist.md`
- `jpa-repository-result-checklist.md`
- `styling-checklist.md`
- `simplify-checklist.md` (Kit extensions)
- `fixture-identifier-conventions.md`
- `learned-misses.md`
- `auto-fix-eligibility.md`
- `feedback-format.md` / `evidence-gate.md` / `forbidden-formats.md` / `output-schema.md`

## Spine ownership

- **One canonical spine** lives in `skills/engineer-review/SKILL.md`.
- `agents/csp-engineer-reviewer.md` is a short pointer plus hard rules that existing greps and safety require (clarify evidence, teach-review tokens, skill-map link, no mid-run `npx skills add`, Coverage keys, never edit kit git).

## Regression tests required

- New: `scripts/tests/engineer-review-context-budget-test.sh` (picked up by `scripts/harness-bench.sh` via `scripts/tests/*.sh`)
  - Context budget section lists always vs phase-only vs merge-only
  - Orchestrator SKILL/agent must **not** instruct loading bodies of the checklist set above (and `learned-misses.md`) into orch context
  - Phase agents with triggers still require opening the full checklist (`csp-review-logic`, `csp-review-architecture`; figma already has Always-load)
- Existing must stay green: `clarify-question-evidence`, `figma-markup-checklist`, `teach-review-contract`, `mapped-third-party-skills`, `propose-commit`, `plain-language-chat`, `code-comments`, `developer-reviewer-handoff`

## Non-goals

- Deleting checklist content to fake a size win
- Changing review severity / apply eligibility semantics
- Inventing new phases or gates beyond load routing
- Editing the user’s plan file under `/opt/cursor/artifacts/plans/`

## Test plan

1. Unit scripts listed above exit 0
2. `bash scripts/harness-bench.sh` exits 0
3. Record before/after sizes for SKILL, agent, references tree, skill tree total
