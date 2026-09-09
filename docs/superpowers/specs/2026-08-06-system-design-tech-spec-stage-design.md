# System design pair at tech-spec stage

## Status

`approved` — implementation target for cursor-spells kit (brainstorm validated).

## Goal

Strengthen architectural decisions during the kit's design stage (`tech-spec` / brainstorming mechanics) by vendoring Anthropic's **system-design** framework and running a **designer + critic** agent pair before the implementation plan. The human receives a ready tech-spec for a single approval gate; inter-agent disputes are resolved without mid-flight questions.

## Decisions

| Decision | Choice |
|----------|--------|
| Packaging | Vendor Anthropic system-design framework into the kit (`skills/system-design`) + orchestration (approach 1) |
| Agent pair | Designer + critic (not two competing full designs by default) |
| When | During `tech-spec`, before `writing-plans` |
| Entry depth | HITL `light` \| `full` only in **agent** mode; **human** mode always **full** |
| Human mode | Human supplies a plan/notes → designer formats → critic audits |
| Agent light | Existing 7-section tech-spec path (no system-design pair) |
| Agent full | Designer + critic → merge into standard csp-tech-spec |
| Inter-agent disputes | Auto-consensus (revise / re-check rounds); do not ask the human |
| Mid-flight HITL | Only Blocker when AC lacks a business fact with no happy path |
| Design approval | No separate `approve-design`; only existing `approve-spec` / `revise` / `skip` |
| Approved artifact | Single `…-tech-spec.md`; `…-system-design.md` kept as `merged` reference |
| Post-plan critic | Unchanged (`implementation-critic` after plan approval) |

## Entry flow

1. Existing HITL: `human` \| `agent` (`hitl-choice`).
2. If **`human`**: always full system-design path. Require a plan path or pasted notes; do not start designer without them.
3. If **`agent`**: HITL `light tech-spec` \| `full system-design`.
4. **`light`**: current tech-spec spine (7 sections, question-discipline, `approve-spec`).
5. **`full`**: system-design pair (below), then merge, then `approve-spec`.

```
AC (+ optional human plan)
        │
   HITL: human | agent
        │
   ┌────┴────┐
human        agent
   │            │
   │       HITL: light | full
   │            │         │
   │         light      full
   │            │         │
   │         tech-spec    │
   │         (current)    │
   │                      ▼
   └──► designer writes draft system-design.md
              │
         critic audits same file (barrier after first draft)
              │
         auto-consensus rounds (no human for pair disputes)
              │
         Blocker stop only if AC silent on required business fact
              │
         merge → tech-spec.md (Status: draft)
              │
     HITL: approve-spec | revise | skip
              │
         writing-plans …
```

## Full path: designer + critic

### Brief

Shared input for both agents: Acceptance Criteria reference, optional human plan text, `.cursor/project-patterns.md` if present, detected stack label. Never invent business requirements.

### `csp-system-design-designer`

- Skill: vendored `skills/system-design` (Anthropic framework: requirements → high-level design → deep dive → scale/reliability → trade-off analysis).
- Modes: `format-human-plan` (structure/clarify human input) vs `draft-from-ac` (agent-authored design from AC + patterns).
- Writes `docs/superpowers/specs/YYYY-MM-DD-<topic>-system-design.md` (English).
- Does not set any approved status; does not ask the human about disputes with the critic.

### `system-design-critic`

- New agent `csp-system-design-critic` (not a reuse of `implementation-critic`).
- Read-only audit of the system-design draft.
- Lenses: YAGNI / unnecessary complexity, failure modes, operational risk, over-engineering, fit with existing patterns/stack.
- Findings: **Must-fix** / **Should-fix** / **Accept-risk** (same severity vocabulary as `implementation-critic`, scoped to design).

### Auto-consensus protocol

1. Designer produces or updates the draft.
2. Critic runs against that file.
3. Open **Must-fix** → designer revises the draft addressing them (or documents an explicit trade-off the critic can clear).
4. Critic re-checks; repeat for a small fixed round budget (implementation plan will set the cap; default target ≤3 rounds).
5. Remaining **Should-fix** may land in Rejected alternatives / Assumptions after merge; they do not block producing the tech-spec draft.
6. **Accept-risk** items the pair keeps must be written into Assumptions with claim / why / how to revoke — human sees them at `approve-spec`.
7. Forbidden: asking the human to break a designer↔critic tie.

### Blocker exception

If a business fact required for a happy path is missing from AC (and from the human plan in human mode), stop with one Blocker question via `hitl-choice`. Do not invent the fact. Local technical defaults remain Assumptions.

### Competing designs

Not the default. On a large architectural fork the orchestrator may present 2–3 options with trade-offs as a Decision-tier ask (existing question-discipline). Do not spawn two full designer agents unless a future design revisits that.

## Merge into tech-spec

After consensus, the tech-spec orchestrator maps system-design content into the existing 7-section template:

| System-design content | Tech-spec section |
|----------------------|-------------------|
| Components, data flow, storage, APIs | Changes by layer; Data model / contracts |
| Scale, reliability, monitoring, trade-offs | Rejected alternatives; Assumptions (as appropriate) |
| Explicit rollout / migration notes | Rollout sequence; Compatibility / migration / rollback |

Rules:

- Fill all seven sections; invent nothing in AC language.
- Apply `clean-decision-docs` (final-form truth only).
- Set system-design file header/status to `merged` and keep the file as reference (do not delete).
- Present the tech-spec for the existing gate: `approve-spec` / `revise` / `skip <reason>`.

## Components to add or change

| Artifact | Change |
|----------|--------|
| `skills/system-design/SKILL.md` | New — Anthropic framework + kit adaptations (AC, patterns, modes, English paths) |
| `agents/csp-system-design-designer.md` | New — draft/format system-design |
| `agents/csp-system-design-critic.md` | New — design audit + finding severities |
| `skills/tech-spec/SKILL.md` (+ refs as needed) | Entry HITL for light/full; full-path orchestration; merge; context budget |
| `agents/csp-tech-spec.md` | Same spine updates |
| `commands/csp-start-task.md`, `commands/csp-write-tech-spec.md` | Document new HITL steps |
| `docs/superpowers/pipeline-flow.md` (+ html if maintained) | Full vs light branch on csp-tech-spec |
| `README.md` | List new skill/agents |
| Dogfood checklist | Scenarios: human full, agent full, agent light |

## Context budget

- **Light:** load current tech-spec stack only; do not load system-design pair.
- **Full:** load `system-design`, designer, critic, tech-spec merge rules, `hitl-choice`, `clean-decision-docs`.

## Out of scope

- Changing `implementation-critic` or post-plan gates
- Dual competing designers as the default
- Auto-fetch of Jira/ticket bodies
- A standalone slash command only for system-design (entry remains `/csp-write-tech-spec` and `/csp-start-task`)
- Product/UX brainstorming outside engineering tech-spec

## Success criteria

- Human full path formats a supplied plan, critic runs, tech-spec appears ready for `approve-spec` without designer↔critic questions.
- Agent light path behavior matches today's tech-spec.
- Agent full path produces `…-system-design.md` (`merged`) + `…-tech-spec.md` (`draft` → human-approved).
- Blocker questions fire only when AC/human plan omit a required business fact.
- `writing-plans` still consumes only an `approved` or explicitly `skip`ped tech-spec.
