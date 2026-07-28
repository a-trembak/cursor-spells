---
name: tech-spec
description: >-
  Use once Acceptance Criteria are agreed and before an implementation plan is
  written. Drives a developer's technical action plan (services, tables,
  contracts, rollout order) for a change — not a PRD. Use when the user runs
  /write-tech-spec, /start-task, or asks to write a technical spec for a
  feature. Never invents business requirements.
---

# Tech Spec

Produces a **developer's technical action plan**, not a PRD or user-story prose: which services/modules are touched, what tables/APIs/contracts appear or change, how entities link, in what order changes land, and how to roll back. Written once Acceptance Criteria already exist.

## When to Use

- AC are agreed and an implementation plan doesn't exist yet
- Manual `/write-tech-spec` or `/start-task`, or the user asks for a technical spec / technical design for a change
- Not for writing AC themselves (assumed already agreed), and not for the implementation plan's task breakdown (that's `writing-plans`, consuming this spec's output)

## Entry question (always ask first)

Ask via skill **`hitl-choice`** (prefer `AskQuestion` buttons; text fallback). Preset: **Tech-spec entry**. Prompt/text fallback:

> Tech spec: write it yourself, or have the agent draft it?
> - `human` — you provide the file; the agent only structures/asks about gaps
> - `agent` — the agent drives the interview and writes the draft

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

1. Ask the entry question. If `human`, wait for the file path and check it against `references/template.md`'s section list and Status header — report any structural gaps as questions.
2. If `agent`: read AC and `.cursor/project-patterns.md` (current project) if present.
3. Draft the spec section by section, following [references/template.md](references/template.md), applying the three-tier protocol from [references/question-discipline.md](references/question-discipline.md) as each section surfaces uncertainty.
4. Write the file per the template's path convention. Apply skill **`clean-decision-docs`**: the file is final-form current truth, never a changelog of prior drafts.
5. Present it for `approve-spec` (see Gate).
6. On `revise`: rewrite affected sections in place per `clean-decision-docs` (chat may summarize what changed; the file body must not). Re-present for `approve-spec`.

## Gate

Plan-writing does not start until the spec is `approved` (or the human explicitly says `skip`, with the reason logged in the spec file).

**Stop.** Ask via skill **`hitl-choice`** (prefer `AskQuestion` buttons; text fallback). Preset: **Tech-spec gate**. Prompt/text fallback:

> Spec ready at `<path>`. Reply:
> - `approve-spec` — accept; planning may proceed
> - `revise` — describe changes (or edit the file); re-present after
> - `skip <reason>` — skip the spec; reason is recorded in the file

## Context budget

Load this skill, its two reference files, `hitl-choice`, and `clean-decision-docs` when drafting or revising.
