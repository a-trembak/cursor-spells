# System Design Pair at Tech-Spec Stage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor Anthropic's system-design framework into cursor-spells and wire a designer + critic pair into the `tech-spec` stage so architectural decisions are stress-tested before `writing-plans`, with human-always-full / agent light|full entry and a single `approve-spec` gate after merge.

**Architecture:** New `skills/system-design` plus `system-design-designer` and `system-design-critic` agents produce a temporary `…-system-design.md`. The existing `tech-spec` orchestrator chooses light vs full, runs auto-consensus rounds (≤3) without asking the human to break designer↔critic ties, merges into the standard 7-section tech-spec, and keeps the existing `approve-spec` HITL. Blocker asks remain only when AC/human plan omit a required business fact.

**Tech Stack:** Markdown Cursor skills/agents/commands/rules (prompt kit, not compiled software) — same format as `skills/tech-spec/` and `agents/implementation-critic.md`.

## Global Constraints

- Never invent business requirements; Blocker when AC/human plan lacks a happy-path business fact.
- Designer↔critic disputes: auto-consensus only — no mid-flight HITL to break ties.
- No separate `approve-design` gate; only `approve-spec` / `revise` / `skip`.
- Human mode always full; light only after agent chooses `light`.
- Approved artifact is always `…-tech-spec.md`; system-design file ends as `Status: merged` reference.
- English-only decision files under `docs/superpowers/specs/`.
- Apply `clean-decision-docs` on every draft/revise/merge.
- Frequent small commits — one per task.
- Nested code fences: if a step needs fences inside fences, use a 4-space-indented presentation block (kit `task-brief` tooling breaks on equal-length nested triple backticks).
- Spec source of truth: `docs/superpowers/specs/2026-08-06-system-design-tech-spec-stage-design.md`.

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `skills/system-design/SKILL.md` | Anthropic framework + kit modes (`format-human-plan`, `draft-from-ac`), paths, output rules |
| `skills/system-design/references/template.md` | System-design draft sections + status header (`draft` / `merged`) |
| `skills/system-design/references/consensus-protocol.md` | Designer↔critic round rules, round cap ≤3, finding handling |
| `skills/system-design-critic/SKILL.md` | When to use, lenses, severity, read-only rule |
| `skills/system-design-critic/references/lenses.md` | Built-in checklists (YAGNI, failure modes, ops risk, patterns fit) |
| `skills/system-design-critic/references/output-schema.md` | Report shape + Verdict for consensus loop |
| `agents/system-design-designer.md` | Agent spine for drafting/formatting |
| `agents/system-design-critic.md` | Agent spine for audit |
| `skills/tech-spec/SKILL.md` | Entry light/full; full orchestration; merge; context budget |
| `skills/tech-spec/references/full-path.md` | Full-path orchestration + merge map (new) |
| `skills/tech-spec/references/question-discipline.md` | Note: full-path pair disputes ≠ Decision HITL |
| `agents/tech-spec.md` | Updated spine |
| `skills/hitl-choice/SKILL.md` | Preset: Tech-spec depth (`light` / `full`) |
| `commands/write-tech-spec.md`, `commands/start-task.md` | Document new HITL |
| `docs/superpowers/pipeline-flow.md`, `pipeline-flow.html` | Diagram branch |
| `README.md` | Skill/agent rows |
| `docs/superpowers/dogfood/system-design-tech-spec-checklist.md` | Manual fixtures: human full, agent full, agent light |

---

### Task 1: Vendor `system-design` skill + draft template

**Files:**
- Create: `skills/system-design/SKILL.md`
- Create: `skills/system-design/references/template.md`

**Interfaces:**
- Produces: skill name `system-design`; template path `references/template.md`; modes `format-human-plan` | `draft-from-ac`; draft path pattern `docs/superpowers/specs/YYYY-MM-DD-<topic>-system-design.md`.

- [ ] **Step 1: Create the skill file**

Write `skills/system-design/SKILL.md` with exactly this content:

````markdown
---
name: system-design
description: >-
  Use during tech-spec full path to design systems, services, and architectures
  from agreed AC (or to format a human-supplied plan). Trigger when tech-spec
  selects full system-design, or when drafting API/data/service boundaries
  before writing-plans. Adapted from Anthropic system-design; never invents
  business requirements.
---

# System Design

Help design systems and evaluate architectural decisions for the kit's **full** tech-spec path. Produces a structured design draft that a critic audits and that tech-spec later merges into the 7-section tech-spec.

## When to Use

- `tech-spec` full path (`human` always; `agent` + `full`)
- Not for light tech-spec, not for implementation task breakdown (`writing-plans`), not for post-plan `implementation-critic`

## Modes

| Mode | Input | Behavior |
|------|-------|----------|
| `format-human-plan` | Human plan path or pasted notes + AC | Structure/clarify into the template; do not replace human intent with a new architecture |
| `draft-from-ac` | AC + optional `.cursor/project-patterns.md` + stack label | Draft design from AC and patterns; stop on Blocker if a required business fact is missing |

## Framework

### 1. Requirements Gathering
- Functional requirements (trace to AC ids only — do not rewrite AC prose)
- Non-functional requirements (scale, latency, availability, cost) when AC/patterns imply them; otherwise Assumption or Open question
- Constraints (team size, timeline, existing tech stack / patterns file)

### 2. High-Level Design
- Component diagram (Mermaid or ASCII)
- Data flow
- API contracts (names/shapes at design level)
- Storage choices

### 3. Deep Dive
- Data model design
- API endpoint design (REST, GraphQL, gRPC as fits stack)
- Caching strategy
- Queue/event design
- Error handling and retry logic

### 4. Scale and Reliability
- Load estimation (even order-of-magnitude, marked Assumption if guessed)
- Horizontal vs. vertical scaling
- Failover and redundancy
- Monitoring and alerting

### 5. Trade-off Analysis
- Every material decision: choice, alternatives, why this wins
- Consider: complexity, cost, team familiarity, time to market, maintainability
- Note what to revisit as the system grows

## Output

Write English file per [references/template.md](references/template.md). Explicit assumptions, trade-offs, and "revisit later" notes required. Never set `Status: merged` or tech-spec `approved` — orchestrator owns those.

## Hard rules

- Never invent business requirements missing from AC / human plan.
- Never ask the human to resolve a dispute with `system-design-critic` — revise the draft or document a trade-off for the consensus protocol.
- On Blocker (no happy path without a missing business fact): stop and surface to the tech-spec orchestrator for one `hitl-choice` ask — do not guess.

## Context budget

Load this skill, `references/template.md`, and (when in a consensus loop) `references/consensus-protocol.md`.
````


- [ ] **Step 2: Create the template reference**

Write `skills/system-design/references/template.md`:

````markdown
# System-design draft template

## File placement

- Separate file, English only.
- Path: `docs/superpowers/specs/YYYY-MM-DD-<topic>-system-design.md`

## Status header

```markdown
# <Feature> — System Design

**Status:** draft | merged
**AC:** <references>
**Mode:** format-human-plan | draft-from-ac
**Source plan:** <path or `n/a`>
```

`merged` is set only by the tech-spec orchestrator after successful merge into the tech-spec. Designer and critic never set `merged`.

## Sections (in order)

1. **Requirements** — functional (AC ids), non-functional, constraints
2. **High-level design** — components, data flow, API contracts, storage (include a Mermaid or ASCII diagram)
3. **Deep dive** — data model, endpoints, cache, queues/events, errors/retries
4. **Scale and reliability** — load, scaling, failover, monitoring
5. **Trade-offs** — each material decision with alternatives and rationale; "revisit later" list
6. **Assumptions / open questions** — Assumption-tier defaults (claim, why, revoke); Open questions only for unresolved Blockers awaiting human (should be empty before merge unless orchestrator is mid-Blocker)

## Clean final form

Every revise in the consensus loop rewrites the file as current truth (`clean-decision-docs`). No changelog archaeology inside the file.
````

- [ ] **Step 3: Verify files exist**

Run:

```bash
test -f skills/system-design/SKILL.md && test -f skills/system-design/references/template.md && rg -n '^name: system-design$' skills/system-design/SKILL.md
```

Expected: both files exist; `name: system-design` matches.

- [ ] **Step 4: Commit**

```bash
git add skills/system-design/SKILL.md skills/system-design/references/template.md
git commit -m "feat(system-design): vendor Anthropic framework skill and draft template"
```

---

### Task 2: Consensus protocol reference

**Files:**
- Create: `skills/system-design/references/consensus-protocol.md`

**Interfaces:**
- Consumes: critic finding severities `must-fix` | `should-fix` | `accept-risk` and Verdict vocabulary from Task 4's output schema (use these exact strings).
- Produces: round cap `MAX_ROUNDS = 3`; orchestrator steps for auto-consensus.

- [ ] **Step 1: Write consensus protocol**

Write `skills/system-design/references/consensus-protocol.md`:

````markdown
# Designer ↔ critic consensus protocol

Used only on tech-spec **full** path. The human is not asked to break designer↔critic ties.

## Roles

- **Designer** (`system-design-designer`): writes/revises `…-system-design.md`
- **Critic** (`system-design-critic`): read-only audit; emits findings + Verdict
- **Orchestrator** (`tech-spec` skill/agent): runs the loop, merges, owns HITL

## Loop

1. Designer writes or updates the system-design draft (`Status: draft`).
2. Critic runs against that file path (barrier: never start critic before the draft file exists).
3. If Verdict is `clear`: exit loop; proceed to merge.
4. If open **must-fix** findings exist: designer revises the draft to address each Must-fix (or documents an explicit trade-off the critic can clear on re-check). Do **not** ask the human.
5. Critic re-checks the updated file.
6. Repeat until Verdict `clear` or `MAX_ROUNDS` (3) is reached.

## After MAX_ROUNDS

- Remaining **must-fix**: designer must fold each into Trade-offs / Assumptions with a concrete choice and rationale so the draft is mergeable; orchestrator then merges and surfaces residual risk in tech-spec Assumptions for `approve-spec`. Still no designer↔critic tie-break HITL.
- **should-fix**: may become Rejected alternatives one-liners or Assumptions after merge; never block merge.
- **accept-risk**: must appear in tech-spec Assumptions (claim, why, how to revoke) after merge; human reviews at `approve-spec`.

## Forbidden

- Asking the human which agent is "right"
- Separate `approve-design` gate
- Inventing AC business facts to clear a Must-fix
- Starting a second competing full designer by default

## Blocker exception (orchestrator)

If either agent surfaces a missing business fact with no happy path, orchestrator stops the loop and asks one Blocker question via `hitl-choice`. After the human answers, resume from step 1 with updated brief.
````

- [ ] **Step 2: Link from skill**

In `skills/system-design/SKILL.md`, ensure Context budget already mentions `references/consensus-protocol.md` (added in Task 1). If missing, append under Context budget:

```markdown
and (when in a consensus loop) `references/consensus-protocol.md`.
```

- [ ] **Step 3: Commit**

```bash
git add skills/system-design/references/consensus-protocol.md skills/system-design/SKILL.md
git commit -m "feat(system-design): add designer-critic consensus protocol"
```

---

### Task 3: `system-design-designer` agent

**Files:**
- Create: `agents/system-design-designer.md`

**Interfaces:**
- Consumes: skill `system-design`, modes from Task 1, consensus protocol from Task 2.
- Produces: agent name `system-design-designer` for tech-spec orchestrator dispatch.

- [ ] **Step 1: Write the agent file**

Write `agents/system-design-designer.md`:

````markdown
---
name: system-design-designer
description: >-
  Drafts or formats a system-design document for the tech-spec full path using
  skill system-design. Use when tech-spec selects full system-design (human plan
  formatting or agent draft-from-ac). Never invents business requirements; never
  asks the human to resolve critic disputes.
---

You are the **system-design designer**. You produce or revise a system-design draft; you do not approve specs or write implementation plans.

## Preconditions

1. Read skill `system-design` (`skills/system-design/SKILL.md`).
2. Require AC (text, ticket reference, or path). If none, stop and tell the orchestrator — do not draft.
3. Require mode `format-human-plan` or `draft-from-ac` from the orchestrator.
4. For `format-human-plan`, require human plan path or pasted notes.

## Spine

1. Read AC; read `.cursor/project-patterns.md` in the current project if present; note stack label if provided.
2. If `format-human-plan`: read the human plan; map it into [references/template.md](../skills/system-design/references/template.md) without replacing the human's architectural intent.
3. If `draft-from-ac`: draft all template sections from AC + patterns using the Framework in the skill.
4. Write `docs/superpowers/specs/YYYY-MM-DD-<topic>-system-design.md` with `Status: draft`.
5. On consensus revise requests: rewrite affected sections as current truth (`clean-decision-docs`); address each Must-fix id cited by the critic or document an explicit trade-off.

## Hard rules

- Never invent Blocker-tier business facts.
- Never ask the human to choose between your design and the critic — revise or document trade-offs.
- Never set `Status: merged` or write the tech-spec file (orchestrator merges).
- Never write implementation plan tasks.
- Source-code identifiers in examples: English only.

## Output

The system-design file path, plus a short note listing any Blocker that needs the orchestrator (missing AC fact). No persona padding.
````

- [ ] **Step 2: Verify**

Run:

```bash
test -f agents/system-design-designer.md && rg -n 'system-design-designer|format-human-plan|draft-from-ac' agents/system-design-designer.md
```

Expected: file exists; mode strings present.

- [ ] **Step 3: Commit**

```bash
git add agents/system-design-designer.md
git commit -m "feat(agents): add system-design-designer"
```

---

### Task 4: `system-design-critic` skill, lenses, schema, agent

**Files:**
- Create: `skills/system-design-critic/SKILL.md`
- Create: `skills/system-design-critic/references/lenses.md`
- Create: `skills/system-design-critic/references/output-schema.md`
- Create: `agents/system-design-critic.md`

**Interfaces:**
- Consumes: path to `…-system-design.md`.
- Produces: markdown report with Verdict `blocked` | `clear`; finding ids `F1`…; severities `must-fix` | `should-fix` | `accept-risk`.
- Note: Unlike `implementation-critic`, this critic does **not** HITL the human for accept — orchestrator/designer consume the report inside auto-consensus. Verdict `clear pending accept` is **not** used; `accept-risk` findings stay in the report for merge into Assumptions, and Verdict is `clear` when no open must-fix remain.

- [ ] **Step 1: Write lenses**

Write `skills/system-design-critic/references/lenses.md`:

````markdown
# System-design critic lenses

Run all lenses every time. Quote the exact draft line before recording a finding.

## Lens Y — YAGNI / complexity

- Unnecessary services, queues, or caches for the stated AC scale
- Premature multi-region / sharding / event-sourcing
- Abstractions with one concrete use
- Simpler alternative clearly available in patterns or stack

## Lens F — Failure modes

- Missing timeout/retry/idempotency where the design implies remote calls
- Single points of failure called out without mitigation
- Partial-failure behavior unspecified for multi-step flows
- Data loss / duplicate processing paths unnamed

## Lens O — Operational risk

- No monitoring/alerting hooks for new critical paths
- Migrations/rollout omitted when storage shape changes
- Secrets/PII handling absent when data model implies sensitive fields
- Runbook-level operability ignored (how on-call knows it broke)

## Lens P — Patterns / stack fit

- Conflicts with `.cursor/project-patterns.md` without explicit trade-off
- Storage/API style inconsistent with detected stack without rationale
- Cross-service contracts that ignore existing module boundaries

## Anti-confabulation

No finding without a same-turn quote from the system-design draft (section heading + line) or patterns file `path`. If evidence is missing, drop the finding.
````

- [ ] **Step 2: Write output schema**

Write `skills/system-design-critic/references/output-schema.md`:

````markdown
# Output schema

Emit this markdown. No persona text before or after.

```markdown
# System Design Critic

## Coverage
- system_design: `<path>`
- patterns: `read` | `not found`
- lenses: Y F O P

## Must-fix (blocks consensus clear)
1. **F1** (`lens Y|F|O|P`) — finding, quoting the draft line
   - Evidence: section / quote
   - Recommendation: concrete change to the draft

## Should-fix (non-blocking)
- **F2** (`lens Y|F|O|P`) — finding
  - Evidence: …
  - Recommendation: …

## Accept-risk (document in Assumptions after merge)
- **F3** (`lens Y|F|O|P`) — deliberate trade-off
  - Evidence: …
  - Risk: …
  - Merge note: claim / why / how to revoke for tech-spec Assumptions

## Verdict
- `blocked` — at least one Must-fix remains
- `clear` — no Must-fix remain (Should-fix / Accept-risk may still be listed)
```

## Rules

- Sequential ids `F1`, `F2`, … across all lenses.
- Do not use `clear pending accept` — humans do not accept mid-loop; Accept-risk is advisory for merge.
- Never edit the system-design file.
- Never ask the human questions.
````

- [ ] **Step 3: Write critic skill**

Write `skills/system-design-critic/SKILL.md`:

````markdown
---
name: system-design-critic
description: >-
  Use on the tech-spec full path after a system-design draft exists. Audits the
  draft for YAGNI, failure modes, operational risk, and patterns fit. Read-only;
  never asks the human; used inside designer↔critic auto-consensus.
---

# System Design Critic

Read-only audit of a **system-design draft** before it merges into a tech-spec. Complements (does not replace) post-plan `implementation-critic`.

## When to Use

- Full tech-spec path after `system-design-designer` wrote `…-system-design.md`
- Consensus re-check rounds
- Not for light tech-spec; not for implementation plans; not for code review

## Lenses

See [references/lenses.md](references/lenses.md): Y (YAGNI), F (failure modes), O (ops), P (patterns/stack).

## Spine

1. Require system-design file path; read it in full.
2. Read `.cursor/project-patterns.md` in the current project if present.
3. Run all four lenses; apply anti-confabulation.
4. Emit report per [references/output-schema.md](references/output-schema.md).
5. Do not edit files; do not ask the human.

## Context budget

This skill + both reference files + the draft path under review.
````

- [ ] **Step 4: Write critic agent**

Write `agents/system-design-critic.md`:

````markdown
---
name: system-design-critic
description: >-
  Audits a system-design draft on the tech-spec full path for YAGNI, failure
  modes, operational risk, and patterns fit. Use inside designer↔critic
  consensus. Read-only; never writes files; never asks the human.
---

You are the **system-design critic**. You read; you never write design files, tech-specs, plans, or code.

## Preconditions

1. Read skill `system-design-critic`.
2. Require a `…-system-design.md` path. If missing, stop with an error to the orchestrator.

## Spine

1. Read the system-design draft in full.
2. Read `.cursor/project-patterns.md` if present.
3. Run lenses Y/F/O/P from `references/lenses.md`.
4. Classify findings; emit report per `references/output-schema.md`.
5. Verdict `blocked` if any Must-fix; else `clear`.

## Hard rules

- Never edit any file.
- Never ask the human (including Accept-risk).
- Never record a finding without a quote from the draft or patterns file.
- Never soften Must-fix to Should-fix to force `clear`.

## Output

Only the markdown report from the output schema.
````

- [ ] **Step 5: Verify**

Run:

```bash
test -f skills/system-design-critic/SKILL.md && test -f agents/system-design-critic.md && rg -n 'Verdict|must-fix|Never ask the human' skills/system-design-critic/references/output-schema.md agents/system-design-critic.md
```

Expected: files exist; no-human and Verdict language present.

- [ ] **Step 6: Commit**

```bash
git add skills/system-design-critic agents/system-design-critic.md
git commit -m "feat(system-design-critic): add skill, lenses, schema, and agent"
```

---

### Task 5: HITL preset for tech-spec depth

**Files:**
- Modify: `skills/hitl-choice/SKILL.md` (Gate presets section, after Tech-spec entry)

**Interfaces:**
- Produces: preset **Tech-spec depth** with option ids `light` and `full` (exact tokens).

- [ ] **Step 1: Insert preset after Tech-spec entry**

In `skills/hitl-choice/SKILL.md`, immediately after the Tech-spec entry table, add:

```markdown
### Tech-spec depth (agent mode only)

| id | label |
|----|-------|
| `light` | Light tech-spec (7 sections, no design pair) |
| `full` | Full system-design (designer + critic, then merge) |

Ask only after the human chose `agent` on Tech-spec entry. Do not ask in `human` mode (always full).
```

Also add `light` / `full` to the "When to Use" bullet examples if that list enumerates tokens (keep consistent with existing style).

- [ ] **Step 2: Verify**

Run:

```bash
rg -n 'Tech-spec depth|^\| `light`|^\| `full`' skills/hitl-choice/SKILL.md
```

Expected: preset heading and both option ids.

- [ ] **Step 3: Commit**

```bash
git add skills/hitl-choice/SKILL.md
git commit -m "feat(hitl-choice): add tech-spec depth light/full preset"
```

---

### Task 6: Tech-spec full-path orchestration + skill updates

**Files:**
- Create: `skills/tech-spec/references/full-path.md`
- Modify: `skills/tech-spec/SKILL.md`
- Modify: `skills/tech-spec/references/question-discipline.md` (short clarification only)

**Interfaces:**
- Consumes: agents `system-design-designer`, `system-design-critic`; consensus protocol; merge map.
- Produces: orchestrated full path ending in standard tech-spec draft for `approve-spec`.

- [ ] **Step 1: Write full-path reference**

Write `skills/tech-spec/references/full-path.md`:

````markdown
# Tech-spec full path (system-design pair)

## When

- Entry `human` → always this path (after human plan is available)
- Entry `agent` → only if depth HITL returns `full`

## Brief

Collect once: AC source, optional human plan path/text, `.cursor/project-patterns.md` if present, stack label from `/start-task` bootstrap when available.

## Steps

1. Dispatch `system-design-designer`:
   - `human` → mode `format-human-plan`
   - `agent`+`full` → mode `draft-from-ac`
2. Wait until `…-system-design.md` exists with `Status: draft`.
3. Run consensus loop per `skills/system-design/references/consensus-protocol.md` (dispatch `system-design-critic`, revise via designer, max 3 rounds).
4. On Blocker from missing business fact: one `hitl-choice` ask; resume loop with updated brief.
5. Merge into tech-spec per map below; write `docs/superpowers/specs/YYYY-MM-DD-<topic>-tech-spec.md` with `Status: draft`.
6. Set system-design file `Status: merged` (keep file).
7. Present tech-spec gate: `approve-spec` / `revise` / `skip` via `hitl-choice`.

## Merge map

| From system-design | Into tech-spec section |
|--------------------|------------------------|
| High-level design + deep dive (components, APIs, storage, data model) | Changes by layer; Data model / contracts |
| Scale/reliability + trade-offs (losing alternatives) | Rejected alternatives; Assumptions |
| Rollout/migration notes if present; else derive minimal safe sequence from storage/API changes | Rollout sequence; Compatibility / migration / rollback |
| AC ids | AC references |
| Accept-risk + Assumptions | Open questions / Assumptions |

All seven tech-spec sections required. Use `clean-decision-docs`. Do not copy system-design headers wholesale — rewrite into the tech-spec template voice.

## Context budget

Full path may load: `tech-spec`, `full-path.md`, `template.md`, `question-discipline.md`, `system-design` (+ template + consensus), `system-design-critic` (+ refs), `hitl-choice`, `clean-decision-docs`.

Light path must **not** load system-design pair skills.
````

- [ ] **Step 2: Update `skills/tech-spec/SKILL.md`**

Replace the Spine and Entry sections so they match this behavior (keep When to Use / Template / Gate; rewrite Spine and add Depth + Full path):

After the existing Entry question (`human` / `agent`), insert:

```markdown
## Depth question (agent mode only)

If entry was `agent`, ask via skill `hitl-choice` preset **Tech-spec depth**:

> Tech spec depth?
> - `light` — standard 7-section tech-spec (current path)
> - `full` — system-design designer + critic, then merge into tech-spec

If entry was `human`, skip this question — always **full**. Require a plan file path or pasted notes before starting the designer.
```

Replace **Spine** with:

```markdown
## Spine

1. Ask entry (`human` / `agent`) via `hitl-choice`.
2. If `human`: wait for plan path/paste; then follow [references/full-path.md](references/full-path.md) with designer mode `format-human-plan`.
3. If `agent`: ask depth (`light` / `full`).
4. If `light`: read AC + patterns; draft 7 sections per `template.md` + `question-discipline.md`; write tech-spec `Status: draft`.
5. If `full`: follow [references/full-path.md](references/full-path.md) with designer mode `draft-from-ac`.
6. Present `approve-spec` / `revise` / `skip` via `hitl-choice`.
7. On `revise`: rewrite affected tech-spec sections as current truth (`clean-decision-docs`); if revision needs design rework, re-enter full-path consensus on the system-design file then re-merge — chat summarizes; files stay final-form.
```

Update **Context budget** line to mention light vs full loading rules from `full-path.md`.

- [ ] **Step 3: Clarify question-discipline**

At the top of `skills/tech-spec/references/question-discipline.md` (after the opening paragraph), add:

```markdown
**Full-path note:** Designer↔critic disagreements are resolved by `skills/system-design/references/consensus-protocol.md`, not by Decision-tier HITL. Decision-tier HITL still applies on the light path, and on the full path only for human-facing forks the orchestrator chooses to surface (or Blockers when AC is silent).
```

- [ ] **Step 4: Verify**

Run:

```bash
rg -n 'full-path|Tech-spec depth|format-human-plan|consensus-protocol' skills/tech-spec/SKILL.md skills/tech-spec/references/full-path.md skills/tech-spec/references/question-discipline.md
```

Expected: matches in all three.

- [ ] **Step 5: Commit**

```bash
git add skills/tech-spec/SKILL.md skills/tech-spec/references/full-path.md skills/tech-spec/references/question-discipline.md
git commit -m "feat(tech-spec): orchestrate full system-design path and light depth"
```

---

### Task 7: Update `agents/tech-spec.md` + commands

**Files:**
- Modify: `agents/tech-spec.md`
- Modify: `commands/write-tech-spec.md`
- Modify: `commands/start-task.md`

- [ ] **Step 1: Rewrite tech-spec agent spine**

Update `agents/tech-spec.md` Spine / Hard rules to match Task 6:

- Entry → (agent) depth → light or full-path
- Human → always full-path with `format-human-plan`
- Hard rule: never ask human to resolve designer↔critic disputes
- Hard rule: never set approved without `approve-spec`
- Reference `references/full-path.md`

Keep preconditions (require AC). Remove the old behavior that human mode only checks a pre-written 7-section file for structural gaps — human mode now supplies a **plan** for formatting via system-design (per approved design). If the human instead provides an already-complete tech-spec file and asks to skip design, they can still use `skip` after a minimal draft or choose agent/light — do not invent a third entry mode in this task.

- [ ] **Step 2: Update `/write-tech-spec`**

In `commands/write-tech-spec.md` Steps, after step mentioning entry question, add depth HITL for agent mode and note full path uses system-design pair + merge. Keep gate step unchanged.

- [ ] **Step 3: Update `/start-task`**

In `commands/start-task.md` pipeline step 2 (Tech spec), document:

- HITL entry `human` / `agent`
- If `agent`: HITL `light` / `full`
- If `human` or `full`: system-design designer + critic consensus, merge, then `approve-spec`
- If `light`: existing tech-spec interview path

- [ ] **Step 4: Verify**

Run:

```bash
rg -n 'light|full|system-design|format-human-plan' agents/tech-spec.md commands/write-tech-spec.md commands/start-task.md
```

Expected: all three files mention the new depth/full path.

- [ ] **Step 5: Commit**

```bash
git add agents/tech-spec.md commands/write-tech-spec.md commands/start-task.md
git commit -m "feat(tech-spec): wire agents and commands to full/light paths"
```

---

### Task 8: Pipeline docs + README

**Files:**
- Modify: `docs/superpowers/pipeline-flow.md` (section 2 Tech spec)
- Modify: `docs/superpowers/pipeline-flow.html` (same branch if the HTML mirrors section 2)
- Modify: `README.md` (Skills + Agents tables)

- [ ] **Step 1: Update Mermaid in pipeline-flow.md section 2**

Replace the tech-spec flowchart so that after `entryHitl`:

- `human` → require plan → fullPath[[system-design pair]] → writeFile
- `agent` → depthHitl light|full → light keeps uncertainty loop; full → fullPath → writeFile
- Then existing gate → toPlan

Keep legend/markers unchanged.

- [ ] **Step 2: Mirror in pipeline-flow.html**

If section 2 exists as Mermaid or structured nodes, apply the same human/full vs agent/light branch. Do not redesign unrelated sections.

- [ ] **Step 3: README rows**

Add to Skills table:

```markdown
| [`system-design`](skills/system-design/) | Anthropic-style system design draft for tech-spec full path (format human plan or draft-from-ac) |
| [`system-design-critic`](skills/system-design-critic/) | Read-only audit of system-design drafts inside auto-consensus |
```

Add to Agents table:

```markdown
| `system-design-designer` | Formats/drafts system-design for tech-spec full path |
| `system-design-critic` | Critiques system-design drafts; no human asks mid-loop |
```

Update the `tech-spec` skill/agent one-liners to mention light|full.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/pipeline-flow.md docs/superpowers/pipeline-flow.html README.md
git commit -m "docs: document system-design full path in pipeline and README"
```

---

### Task 9: Dogfood checklist

**Files:**
- Create: `docs/superpowers/dogfood/system-design-tech-spec-checklist.md`

- [ ] **Step 1: Write dogfood fixture**

Write `docs/superpowers/dogfood/system-design-tech-spec-checklist.md` covering three scenarios:

**Scenario A — human full**

- Provide underspecified AC-1 order export (same as tech-spec dogfood) plus a short human plan preferring "CSV sync endpoint".
- Expect: no depth question; designer formats; critic runs; no mid-loop asks for critic disputes; tech-spec draft for `approve-spec`; `…-system-design.md` ends `merged` after merge.

**Scenario B — agent full**

- Entry `agent` then `full`.
- Expect: depth ask; designer `draft-from-ac`; Blocker/Decision only for missing AC business facts (not critic ties); merge + `approve-spec`.

**Scenario C — agent light**

- Entry `agent` then `light`.
- Expect: no system-design file created; behavior matches existing `tech-spec-checklist.md`.

Include cleanup `rm` globs for generated `*-system-design.md` and `*-tech-spec.md` from the fixture topic.

- [ ] **Step 2: Verify file**

Run:

```bash
rg -n 'Scenario A|Scenario B|Scenario C|merged|approve-spec' docs/superpowers/dogfood/system-design-tech-spec-checklist.md
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/dogfood/system-design-tech-spec-checklist.md
git commit -m "test(dogfood): add system-design tech-spec full/light checklist"
```

---

### Task 10: Integration self-check (no agent runtime required)

**Files:**
- None new — verify wiring

- [ ] **Step 1: File inventory**

Run:

```bash
test -f skills/system-design/SKILL.md \
  && test -f skills/system-design/references/template.md \
  && test -f skills/system-design/references/consensus-protocol.md \
  && test -f skills/system-design-critic/SKILL.md \
  && test -f skills/system-design-critic/references/lenses.md \
  && test -f skills/system-design-critic/references/output-schema.md \
  && test -f agents/system-design-designer.md \
  && test -f agents/system-design-critic.md \
  && test -f skills/tech-spec/references/full-path.md \
  && test -f docs/superpowers/dogfood/system-design-tech-spec-checklist.md \
  && rg -n 'Tech-spec depth' skills/hitl-choice/SKILL.md \
  && rg -n 'full-path' skills/tech-spec/SKILL.md agents/tech-spec.md
```

Expected: all tests succeed (exit 0).

- [ ] **Step 2: Spec coverage grep**

Run:

```bash
rg -n 'approve-design|MAX_ROUNDS|format-human-plan|never ask the human|Status: merged' \
  skills/system-design skills/system-design-critic skills/tech-spec agents/system-design-designer.md agents/system-design-critic.md agents/tech-spec.md
```

Expected: `format-human-plan`, `MAX_ROUNDS` or `3`, `merged`, and no-human rules present; **no** `approve-design` gate instructions ( Mentions saying it is forbidden/absent are OK).

- [ ] **Step 3: Final commit only if Step 1–2 forced fixes**

If fixes were needed, commit them:

```bash
git add -u skills agents commands docs README.md
git commit -m "fix: close system-design tech-spec wiring gaps from integration check"
```

If clean, skip commit.

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| Vendor Anthropic system-design | Task 1 |
| Designer + critic agents | Tasks 3–4 |
| Human always full; agent light\|full | Tasks 5–7 |
| Human plan → format → critic | Tasks 3, 6 |
| Auto-consensus, no tie-break HITL | Tasks 2, 4, 6 |
| Blocker only for missing AC fact | Tasks 1, 2, 6 |
| No `approve-design`; only `approve-spec` | Tasks 2, 6, 7 |
| Merge to 7-section tech-spec; keep `merged` design file | Task 6 |
| Light context budget excludes pair | Task 6 |
| Pipeline + README | Task 8 |
| Dogfood human/full/light | Task 9 |
| Post-plan critic unchanged | No task (explicit non-change) |

## Placeholder scan

Plan uses concrete file bodies, option ids (`light`/`full`), `MAX_ROUNDS = 3`, merge map, and verify commands. No TBD/TODO steps remain.
