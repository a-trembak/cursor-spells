# Implementation Critic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a read-only `implementation-critic` skill/agent and a `/critique-plan` command that audit an existing implementation plan for unnecessary complexity, abstraction violations, missing risk coverage, and scope drift — before any developer agent starts writing code.

**Architecture:** A single agent runs two sequential, complementary lenses (Pass A design/YAGNI, Pass B risk/migration) over a plan file and its tech spec, each backed by a named third-party skill with a built-in fallback checklist when that skill isn't installed. Findings are classified `must-fix` / `should-fix` / `accept-risk` and emitted as a markdown report; the agent never edits the plan or any source file.

**Tech Stack:** Markdown-based Cursor skill/agent/command definitions (this is a prompt-engineering kit, not compiled software) — same format as the existing `skills/engineer-review/` and `agents/review-*.md` artifacts in this repo.

## Global Constraints

- Never vendor third-party skill bodies into the kit — reference `plan-reviewer` (mblode/agent-skills) and `project-verify-plan` (envoydev/agents-stack) by id only, with an inline built-in fallback checklist for when they're not installed (same pattern as `agents/review-architecture.md`'s `architecture-review` reference).
- The critic is **read-only**: it never edits the plan file, never edits source files, and never auto-applies any finding.
- Every finding must cite a fresh, same-turn quote of the plan/spec line or repo `file:line` it targets — never a finding based on memory or inference.
- Source-code comments in any code samples inside these files: English only.
- Do not skip a pass because its skill is missing — always fall back to the built-in checklist and report `skill_missing` instead of silently omitting the pass.
- Frequent, small commits — one per task.

---

## File Structure

- `skills/implementation-critic/SKILL.md` — entry skill: when to use, the two-lens table, spine, fix policy, gate rule
- `skills/implementation-critic/references/lenses.md` — Pass A and Pass B checklists (used verbatim as fallback when the named skill isn't installed) + the anti-confabulation rule
- `skills/implementation-critic/references/output-schema.md` — the exact markdown report shape, field names, and `Verdict` rule
- `agents/implementation-critic.md` — the agent definition (preconditions, spine, hard rules, output contract)
- `commands/critique-plan.md` — `/critique-plan [path]` entry point
- `docs/superpowers/dogfood/implementation-critic-checklist.md` — manual verification fixture (mirrors `docs/superpowers/dogfood/engineer-review-checklist.md`)
- `README.md` — add rows to the Skills/Agents tables + a short Usage note

Each file has one responsibility: the skill file is the "what and why", the references are the two swappable checklists, the agent file is the "how to run it", the command is the entry point, the dogfood file is the acceptance fixture. This mirrors the existing split between `skills/engineer-review/SKILL.md`, its `references/*.md`, and `agents/engineer-reviewer.md`.

---

### Task 1: Create the `implementation-critic` skill entry file

**Files:**
- Create: `skills/implementation-critic/SKILL.md`

**Interfaces:**
- Produces: the skill name `implementation-critic`, links to `references/lenses.md` and `references/output-schema.md` (paths that Tasks 2–4 must create with these exact names), and the two-lens table naming `plan-reviewer` (Pass A) / `project-verify-plan` (Pass B).

- [ ] **Step 1: Write the skill file**

```markdown
---
name: implementation-critic
description: >-
  Use after an implementation plan (and its tech spec, if any) is written and
  before any code is written. Audits the plan for unnecessary complexity,
  abstraction violations, missed risks, and scope drift. Use when the user
  runs /critique-plan, asks to critique/audit a plan, or before dispatching
  a developer agent to implement a plan.
---

# Implementation Critic

Audits an existing implementation plan **before code is written**. Never writes plans or code — only produces a structured critique the plan author or a human acts on.

## When to Use

- A plan exists (from `writing-plans` or elsewhere) and a developer is about to start implementing it
- Manual `/critique-plan <path>` or `@implementation-critic`
- Not for reviewing a code diff (that's `engineer-review`) and not for writing a new plan (that's `writing-plans`)

## Two lenses, both required

| Pass | Skill | Catches |
|------|-------|---------|
| **A — Design** | `plan-reviewer` (mblode/agent-skills) if installed | Unnecessary complexity, YAGNI violations, simpler alternatives, premature/wrong abstractions |
| **B — Risk** | `project-verify-plan` (envoydev/agents-stack) if installed | Missing failure modes, scope drift vs. requirements, missing edge/safety cases, migration & rollback risk, fit with existing architecture |

If a lens's skill is not installed, fall back to its built-in checklist (see [references/lenses.md](references/lenses.md)) and note `skill_missing` in Coverage — never skip a pass or block the whole run for a missing skill.

## Spine

1. Read the plan file (and tech spec / AC if a path was given or discoverable next to the plan).
2. Read `.cursor/project-patterns.md` in the **current project** (not the kit) if present — Pass A's "simpler alternative" and "existing abstraction" checks need it.
3. Run Pass A, then Pass B, over the same plan (see [references/lenses.md](references/lenses.md) for each pass's checklist).
4. Classify every finding as `must-fix`, `should-fix`, or `accept-risk` (see [references/output-schema.md](references/output-schema.md)).
5. Emit the report per `output-schema.md`. Do not edit the plan file.

## Fix policy

This skill **never applies fixes**. It is read-only on the plan. All findings go to the human or the plan author to act on; a re-run after edits produces a fresh report.

## Gate

If any `must-fix` finding is open, the developer agent must not start implementing the plan until it is resolved in the plan or explicitly `accept`ed by the human for that finding's id.

## Context budget

Load this skill and its two reference files only. Do not paste full third-party skill bodies (`plan-reviewer`, `project-verify-plan`) into context — read only what's needed for the specific plan under review.
```

- [ ] **Step 2: Verify the file has the required frontmatter and links**

Run: `grep -c "^name: implementation-critic$" skills/implementation-critic/SKILL.md && grep -c "references/lenses.md" skills/implementation-critic/SKILL.md && grep -c "references/output-schema.md" skills/implementation-critic/SKILL.md`
Expected: `1`, `2`, `1` (the file legitimately links `references/lenses.md` twice — once in the fallback note, once in Spine step 3)

- [ ] **Step 3: Commit**

```bash
git add skills/implementation-critic/SKILL.md
git commit -m "Add implementation-critic skill entry file"
```

---

### Task 2: Create the two-lens checklist reference

**Files:**
- Create: `skills/implementation-critic/references/lenses.md`

**Interfaces:**
- Consumes: the Pass A / Pass B naming from Task 1.
- Produces: the exact checklist bullet lists and the anti-confabulation rule that `agents/implementation-critic.md` (Task 4) and the dogfood fixture (Task 6) reference by name.

- [ ] **Step 1: Write the lenses reference file**

```markdown
# Critic lenses

Both lenses run on every critic invocation — one alone misses a different class of plan defect (a plan can be simple but silently unsafe on migration, or safe but over-engineered).

## Pass A — Design (skill: `plan-reviewer`, mblode/agent-skills)

Install: `npx skills add https://github.com/mblode/agent-skills --skill plan-reviewer`

### Checklist

Used verbatim when the skill is installed; used as the built-in fallback checklist when it is not.

- **KISS** — Is this the simplest thing that could work? Could a developer unfamiliar with this plan understand it in one read?
- **YAGNI** — Is every abstraction, config option, or generalization justified by a *current* requirement in the tech spec/AC, not a hypothetical future one?
- **Simpler alternative** — Is there a solution with fewer moving parts (fewer new files, fewer new abstractions, fewer new dependencies) that satisfies the same AC?
- **Existing abstractions** — Does the plan reuse existing helpers/services/patterns from `.cursor/project-patterns.md` and the codebase, or does it reinvent something that already exists?
- **Tracer bullet** — Does the plan deliver a minimal working slice across the full stack first, rather than building all of one layer before any of another?
- **Duplication over wrong abstraction** — Are new abstractions justified by actual repetition already present in the plan/codebase, not by speculation about future reuse?

## Pass B — Risk (skill: `project-verify-plan`, envoydev/agents-stack)

Install: `npx skills add https://github.com/envoydev/agents-stack --skill project-verify-plan`

### Checklist

Used verbatim when the skill is installed; used as the built-in fallback checklist when it is not.

- **Risk coverage** — Does the plan name the non-obvious failure modes this change will hit (data-access, lifecycle, concurrency, boundary traps for its stack)? A trap the plan doesn't name is a trap the build inherits.
- **Scope match** — Does the plan cover exactly what the tech spec / AC ask for — nothing missing, nothing speculative added?
- **Edges + safety** — Are boundary, empty, and error cases named (not assumed)? Is every auth / migration-order / data-loss / concurrency surface called out with its safeguard?
- **Soundness** — Does the approach match the repo's existing architecture (not introduce a second, competing one)? Are dependencies between tasks correctly ordered? Is this the smallest plan that meets the tech spec?

## Anti-confabulation rule (applies to both passes)

Before recording any finding, quote the exact plan/spec line or the exact repo `file:line` it is judging, read fresh in this pass — never infer from the branch name, working directory, or memory of an earlier pass. If a finding cannot be backed by a fresh quote, do not record it.

## Skill-missing fallback

If `plan-reviewer` or `project-verify-plan` is not installed, run the corresponding checklist above directly (it is written to work standalone) and set that pass's Coverage line to `ran (built-in fallback)` plus `skill_missing: <skill-id>`. Do not skip the pass and do not block the run.
```

- [ ] **Step 2: Verify both checklists and the anti-confabulation rule are present**

Run: `grep -c "^## Pass A" skills/implementation-critic/references/lenses.md && grep -c "^## Pass B" skills/implementation-critic/references/lenses.md && grep -c "Anti-confabulation rule" skills/implementation-critic/references/lenses.md`
Expected: `1`, `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add skills/implementation-critic/references/lenses.md
git commit -m "Add implementation-critic Pass A/B lens checklists"
```

---

### Task 3: Create the output schema reference

**Files:**
- Create: `skills/implementation-critic/references/output-schema.md`

**Interfaces:**
- Consumes: `must-fix` / `should-fix` / `accept-risk` classification names from Task 1.
- Produces: the exact report field names (`Coverage`, `Must-fix`, `Should-fix`, `Accept-risk candidates`, `Verdict`, finding id prefix `F`) that `agents/implementation-critic.md` (Task 4), `commands/critique-plan.md` (Task 5), and the dogfood fixture (Task 6) all depend on matching exactly.

- [ ] **Step 1: Write the output schema file**

```markdown
# Output schema

Emit this markdown to the user. Keep it scannable. No persona text before or after it.

```markdown
# Implementation Critic

## Coverage
- plan: `<path>`
- tech_spec: `<path>` | none provided
- patterns: `read` | `not found`
- pass_a: ran (`plan-reviewer`) | ran (built-in fallback) | skill_missing
- pass_b: ran (`project-verify-plan`) | ran (built-in fallback) | skill_missing

## Must-fix (blocks implementation)
1. **F1** (`pass A|B`) — finding, quoting the plan/spec line it targets
   - Evidence: `path:line` or plan section
   - Recommendation: concrete alternative

## Should-fix (visible, non-blocking)
- **F2** (`pass A|B`) — finding
  - Recommendation: concrete suggestion

## Accept-risk candidates (require explicit human accept)
- **F3** (`pass A|B`) — deliberate trade-off the plan makes
  - Risk: what could go wrong
  - Needs: human reply `accept F3` to unblock, or a plan revision

## Verdict
- `blocked` (open must-fix) | `clear` (no open must-fix) | `clear pending accept` (only accept-risk items remain)
```

## Rules

- Finding ids are a single sequential namespace (`F1`, `F2`, `F3`, …) across both passes — do not restart numbering per pass.
- `pass` on every finding is `A` or `B`, matching which lens produced it.
- `Verdict` is `blocked` whenever at least one `must-fix` item has no matching `accept F<id>` reply on record; it becomes `clear pending accept` once every remaining open item is `accept-risk` and has been explicitly accepted; it is `clear` only when there are no open must-fix or un-accepted accept-risk items at all.
- If **Must-fix** is non-empty, end the report with:

  > Reply `accept F<id>` to accept a specific risk, or revise the plan and re-run `/critique-plan`. Implementation should not start while `Verdict: blocked`.
```

- [ ] **Step 2: Verify the schema defines the Verdict states and finding id convention**

Run: `grep -c "Verdict" skills/implementation-critic/references/output-schema.md && grep -c "accept F" skills/implementation-critic/references/output-schema.md`
Expected: at least `3` for the first (schema block + rules text use it multiple times), at least `2` for the second

- [ ] **Step 3: Commit**

```bash
git add skills/implementation-critic/references/output-schema.md
git commit -m "Add implementation-critic output schema"
```

---

### Task 4: Create the `implementation-critic` agent

**Files:**
- Create: `agents/implementation-critic.md`

**Interfaces:**
- Consumes: skill name and reference file paths from Tasks 1–3 (`skills/implementation-critic/SKILL.md`, `references/lenses.md`, `references/output-schema.md`), the `must-fix`/`should-fix`/`accept-risk` and `Verdict` vocabulary from Task 3.
- Produces: the agent name `implementation-critic` that `commands/critique-plan.md` (Task 5) invokes.

- [ ] **Step 1: Write the agent file**

```markdown
---
name: implementation-critic
description: >-
  Audits an implementation plan (and tech spec, if any) before any code is
  written: unnecessary complexity, abstraction violations, missing risks,
  scope drift. Use when the user runs /critique-plan or asks to critique a
  plan. Never writes plans or code.
---

You are the **implementation critic**. You read; you never write plans or code. Your only output is a structured report.

## Preconditions

1. Read skill `implementation-critic` (`skills/implementation-critic/SKILL.md` in the cursor-spells kit, or linked install path).
2. Require a plan file path. If not given, look for the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Spine

1. Read the plan file in full.
2. If a tech spec is referenced by the plan or discoverable alongside it (matching filename topic under `docs/**/specs/`), read it too — Pass B's scope-match check needs the AC it traces to.
3. Read `.cursor/project-patterns.md` in the **current project** if present.
4. Run **Pass A** using `plan-reviewer` if installed, else the built-in checklist in `references/lenses.md`.
5. Run **Pass B** using `project-verify-plan` if installed, else the built-in checklist in `references/lenses.md`.
6. For every candidate finding, apply the anti-confabulation rule from `references/lenses.md`: quote the exact plan/spec line or repo `file:line` before recording it.
7. Classify each finding:
   - `must-fix` — unnecessary complexity with a clearly simpler alternative; violates an existing abstraction; unnamed safety/migration risk; scope drift vs. the tech spec/AC
   - `should-fix` — weak test plan, poor task granularity, a missing non-critical edge case
   - `accept-risk` — a deliberate, named trade-off that a human must explicitly accept
8. Emit the report per `references/output-schema.md`. Set `Verdict` per the rules there.

## Hard rules

- Never edit the plan file or any source file.
- Never record a finding without a fresh same-turn quote of the plan/spec line or repo evidence it targets.
- Never skip a pass because its skill is missing — use the built-in fallback checklist and note `skill_missing` in Coverage instead.
- Never soften a `must-fix` to `should-fix` to avoid blocking — if a finding meets the must-fix bar, it stays must-fix until a human accepts it or the plan changes.
- Do not install, search for, or recommend installing a skill yourself beyond noting `skill_missing` — skill discovery/installation is out of scope for this agent.

## Output

Return the markdown report from `output-schema.md` directly to the user — no additional persona text before or after it.
```

- [ ] **Step 2: Verify the agent references both checklists and the schema by exact path**

Run: `grep -c "references/lenses.md" agents/implementation-critic.md && grep -c "references/output-schema.md" agents/implementation-critic.md && grep -c "^name: implementation-critic$" agents/implementation-critic.md`
Expected: `3`, `1`, `1` (the agent's Spine legitimately references `references/lenses.md` on three lines — Pass A, Pass B, and the anti-confabulation rule)

- [ ] **Step 3: Commit**

```bash
git add agents/implementation-critic.md
git commit -m "Add implementation-critic agent"
```

---

### Task 5: Create the `/critique-plan` command

**Files:**
- Create: `commands/critique-plan.md`

**Interfaces:**
- Consumes: agent name `implementation-critic` from Task 4, `Verdict: blocked` vocabulary from Task 3.

- [ ] **Step 1: Write the command file**

```markdown
---
description: Audit an implementation plan for complexity, risk, and scope drift before coding starts
argument-hint: "[path/to/plan.md]"
---

# /critique-plan

Run the **implementation-critic** agent against an existing plan.

## Arguments

- Optional plan path. If omitted, use the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Steps

1. Read and follow skill `implementation-critic` (`skills/implementation-critic/SKILL.md`).
2. Invoke agent `implementation-critic` with the plan path (and tech spec path, if discoverable).
3. Emit the report per `references/output-schema.md`.
4. If `Verdict: blocked`, stop and wait for the user to either revise the plan and re-run this command, or reply `accept F<id>` for specific accept-risk-eligible findings.

## Notes

- This command never edits the plan or any source file — it only reports.
- Do not proceed to implementation while `Verdict: blocked`. A `clear` or `clear pending accept` verdict (with the human's explicit accepts) is required first.
```

- [ ] **Step 2: Verify the command invokes the right agent and skill**

Run: `grep -c "implementation-critic" commands/critique-plan.md`
Expected: `3` (skill reference, agent invocation, and the header title match)

- [ ] **Step 3: Commit**

```bash
git add commands/critique-plan.md
git commit -m "Add /critique-plan command"
```

---

### Task 6: Create the dogfood verification fixture

**Files:**
- Create: `docs/superpowers/dogfood/implementation-critic-checklist.md`

**Interfaces:**
- Consumes: `must-fix`/`should-fix`/`Verdict` vocabulary (Task 3) and the Pass A/B checklist items (Task 2) to derive expected findings for the fixture plan below.

- [ ] **Step 1: Write the dogfood checklist with an embedded flawed fixture plan**

```markdown
# Implementation-critic dogfood fixture

Manual checklist to verify the critic behaves. Do not require CI to execute agents.

## Setup

Create a deliberately flawed plan file at `docs/superpowers/plans/2099-01-01-fixture-notification-plugin.md`:

```markdown
# Notification Plugin System Implementation Plan

**Goal:** Add an email notification when a user completes onboarding.

**Architecture:** Build a generic, pluggable notification-channel registry (email, SMS, push, webhook) with a strategy pattern, a config-driven channel loader, and a queue-backed dispatcher, so any future channel can be added without code changes.

**Tech Stack:** Node.js, MySQL

## Global Constraints
- None specified.

---

### Task 1: Add `notifications` and `notification_channels` tables

**Files:**
- Create: `db/migration/20990101_add_notifications.sql`

- [ ] **Step 1: Write migration**

\`\`\`sql
CREATE TABLE notification_channels (id INT PRIMARY KEY, type VARCHAR(50));
CREATE TABLE notifications (id INT PRIMARY KEY, channel_id INT, payload JSON);
\`\`\`

- [ ] **Step 2: Run migration against dev DB**

### Task 2: Build the channel registry and strategy interface

**Files:**
- Create: `src/notifications/ChannelRegistry.ts`
- Create: `src/notifications/EmailChannel.ts`

- [ ] **Step 1: Implement `ChannelRegistry` with dynamic strategy loading**
- [ ] **Step 2: Implement `EmailChannel` sending the onboarding email**
```

This fixture deliberately has:
- A generic multi-channel plugin architecture for a single, immediate requirement (email only) — Pass A YAGNI / simpler-alternative violation.
- A new-table migration with no rollback/down-migration step and no mention of how it relates to the existing `users`/`onboarding` tables it must join against — Pass B risk-coverage and soundness violation.
- No test tasks anywhere in the plan — Pass B should-fix.

## Expected critic behavior

| Check | Expect |
|-------|--------|
| Pass A | `must-fix` — plan builds a generic multi-channel registry for a single required channel (email); a simpler alternative (a single `sendOnboardingEmail` function/service) satisfies the same goal |
| Pass B | `must-fix` — migration has no rollback/down-migration step and doesn't name how `notification_channels`/`notifications` relate to the existing `users`/`onboarding` tables |
| Pass B | `should-fix` — no test tasks anywhere in the plan |
| Coverage | Notes `skill_missing` for `pass_a`/`pass_b` if `plan-reviewer`/`project-verify-plan` are not installed, and still produces the findings above via the built-in fallback checklist from `references/lenses.md` |
| Verdict | `blocked` (at least one must-fix open) |
| Report format | Matches `skills/implementation-critic/references/output-schema.md` exactly — Coverage, Must-fix, Should-fix, Accept-risk candidates, Verdict |
| No plan edits | `docs/superpowers/plans/2099-01-01-fixture-notification-plugin.md` is byte-identical before and after the run |

## Cleanup

Delete the fixture plan file after the dogfood run:

```bash
rm docs/superpowers/plans/2099-01-01-fixture-notification-plugin.md
```
```

- [ ] **Step 2: Verify the fixture file has the setup, expected table, and cleanup sections**

Run: `grep -c "^## Setup" docs/superpowers/dogfood/implementation-critic-checklist.md && grep -c "^## Expected critic behavior" docs/superpowers/dogfood/implementation-critic-checklist.md && grep -c "^## Cleanup" docs/superpowers/dogfood/implementation-critic-checklist.md`
Expected: `1`, `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/dogfood/implementation-critic-checklist.md
git commit -m "Add implementation-critic dogfood fixture"
```

---

### Task 7: Document the new skill/agent/command in README

**Files:**
- Modify: `README.md:57-61` (Skills table)
- Modify: `README.md:65-77` (Agents table)

**Interfaces:**
- Consumes: skill path `skills/implementation-critic/`, agent name `implementation-critic`, command `/critique-plan` from Tasks 1, 4, 5.

- [ ] **Step 1: Add a row to the Skills table**

In `README.md`, change:

```markdown
| [`engineer-review`](skills/engineer-review/) | Multi-phase review orchestrator (stack-aware subagents, P0–P2, chunking) |
```

to:

```markdown
| [`engineer-review`](skills/engineer-review/) | Multi-phase review orchestrator (stack-aware subagents, P0–P2, chunking) |
| [`implementation-critic`](skills/implementation-critic/) | Pre-code plan audit — complexity/YAGNI lens + risk/migration lens, must-fix/should-fix/accept-risk |
```

- [ ] **Step 2: Add a row to the Agents table**

In `README.md`, change:

```markdown
| `review-cross-repo` | Reports cross-repo contract drift as clarification-only findings |
```

to:

```markdown
| `review-cross-repo` | Reports cross-repo contract drift as clarification-only findings |
| `implementation-critic` | Audits a plan before code — complexity (Pass A) + risk (Pass B) lenses, read-only |
```

- [ ] **Step 3: Add a Usage note**

In `README.md`, after the existing `**Manual review:** /engineer-review` line, add:

```markdown
### Critique a plan before coding

`/critique-plan [path]` audits an implementation plan for unnecessary complexity, abstraction violations, missing risk coverage, and scope drift — before a developer starts implementing it. If the report's `Verdict` is `blocked`, revise the plan (or reply `accept F<id>` for accept-risk-eligible findings) and re-run.
```

- [ ] **Step 4: Verify all three additions landed**

Run: `grep -c "implementation-critic" README.md`
Expected: `3` or more (one per table row plus the usage note)

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "Document implementation-critic in README"
```

---

## Self-Review

**1. Spec coverage:** Every element of design spec §2 (`docs/superpowers/specs/2026-07-24-quality-pipeline-design.md`) is covered: two-lens table (Task 1/2), Must-fix/Should-fix/Accept-risk output contract (Task 3), read-only scope + gate rule (Task 1/4), anti-confabulation citation rule (Task 2/4), `skill_missing` fallback without blocking the run (Task 2/4), and the `New/changed artifacts` list's `agents/implementation-critic.md` entry (Task 4). The tech-spec-agent, DB routing, skill-resolver, and comments-policy items from the design remain out of scope for this plan by design (they are sub-projects 4, 2, and 1 respectively).

**2. Placeholder scan:** No `TBD`/`TODO`/"implement later" text anywhere in the plan's file contents. Every step contains the literal file content to write, not a description of it.

**3. Type/name consistency:** `implementation-critic` is spelled identically as the skill name (Task 1), agent name (Task 4), and directory name (Tasks 1–3) throughout. The finding id prefix `F` and fields `must-fix`/`should-fix`/`accept-risk`/`Verdict`/`pass_a`/`pass_b` are used identically across Tasks 3, 4, 5, and 6 — no renamed variants.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-24-implementation-critic.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
