---
name: tech-spec
description: >-
  Use once Acceptance Criteria are agreed and before an implementation plan is
  written. Drives a developer's technical action plan (services, tables,
  contracts, rollout order) for a change — not a PRD. Use when the user runs
  /csp-write-tech-spec, /csp-start-task, or asks to write a technical spec for a
  feature. Never invents business requirements.
---

# Tech Spec

Produces a **developer's technical action plan**, not a PRD or user-story prose: which services/modules are touched, what tables/APIs/contracts appear or change, how entities link, in what order changes land, and how to roll back. Written once Acceptance Criteria already exist.

## When to Use

- AC are agreed and an implementation plan doesn't exist yet
- Manual `/csp-write-tech-spec` or `/csp-start-task`, or the user asks for a technical spec / technical design for a change
- Not for writing AC themselves (assumed already agreed), and not for the implementation plan's task breakdown (that's `writing-plans`, consuming this spec's output)

## Entry question (always ask first)

Ask via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Tech-spec entry**. Prompt/text fallback:

> Tech spec: provide your own plan, or have the agent draft it?
> - `human` — you provide plan path or pasted notes; agent runs the full system-design path (`format-human-plan`), then merges into tech-spec
> - `agent` — the agent drives the interview and writes the draft

## Depth question (agent mode only)

If entry was `agent`, ask via skill `hitl-choice` preset **Tech-spec depth**:

> Tech spec depth?
> - `light` — standard 7-section tech-spec (current path)
> - `full` — system-design designer + critic, then merge into tech-spec

If entry was `human`, skip this question — always **full**. Require a plan file path or pasted notes before starting the designer.

## Three tiers of uncertainty (agent-assisted mode)

See [references/question-discipline.md](references/question-discipline.md) for the full protocol. Summary:

| Tier | When | Action |
|------|------|--------|
| **Blocker** | No happy path / unclear data ownership / security / breaking change | Stop and ask. Spec cannot be finalized. |
| **Decision** | ≥2 valid technical options with materially different impact | Present 2-3 options with a recommendation; wait for the human's choice |
| **Assumption** | Local technical default with no business impact | Write it into the spec's `Assumptions` section: claim, why, how to revoke |

The agent never invents a Blocker or Decision-tier answer on its own. For Blocker/Decision asks, use skill **`hitl-choice`** (Decision-tier / Blocker preset).

## Template

See [references/template.md](references/template.md) for the full 7-section template and file placement (separate file, English only).

## Spine

1. Ask entry (`human` / `agent`) via `hitl-choice`.
2. If `human`: wait for plan path/paste; then follow [references/full-path.md](references/full-path.md) with designer mode `format-human-plan`.
3. If `agent`: ask depth (`light` / `full`).
4. If `light`: read AC + patterns; draft 7 sections per `template.md` + `question-discipline.md`; write tech-spec `Status: draft`.
5. If `full`: follow [references/full-path.md](references/full-path.md) with designer mode `draft-from-ac`.
6. Present `approve-spec` / `revise` / `skip` via `hitl-choice`.
7. On `revise`: rewrite affected tech-spec sections as current truth (`clean-decision-docs`); if revision needs design rework, re-enter full-path consensus on the system-design file then re-merge — chat summarizes; files stay final-form.
8. After the spec file exists, invoke skill **`trajectory-judge`** (nested Task, not `csp-software-developer`). Then, when the acceptance criteria match case `tech-spec-no-invented-facts`, score that case per skill `trajectory-score`. Append session ledger after entry / depth / decision-blocker / tech-spec-gate.

## Gate

Plan-writing does not start until the spec is `approved` (or the human explicitly says `skip`, with the reason logged in the spec file).

**Stop.** Ask via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Tech-spec gate**. Prompt/text fallback:

> Spec ready at `<path>`. Reply:
> - `approve-spec` — accept; planning may proceed
> - `revise` — describe changes (or edit the file); re-present after
> - `skip <reason>` — skip the spec; reason is recorded in the file

## Context budget

Load this skill, `hitl-choice`, and `clean-decision-docs` when drafting or revising. **Light path:** `template.md` + `question-discipline.md` only — do not load system-design pair skills. **Full path:** per [references/full-path.md](references/full-path.md) (may also load `system-design`, `system-design-critic`, and their references).
