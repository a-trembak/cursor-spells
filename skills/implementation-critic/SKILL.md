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
5. Emit the report per `references/output-schema.md`. Do not edit the plan file.

## Fix policy

This skill **never applies fixes**. It is read-only on the plan. All findings go to the human or the plan author to act on; a re-run after edits produces a fresh report.

## Gate

If any `must-fix` finding is open, the developer agent must not start implementing the plan until it is resolved in the plan or explicitly `accept`ed by the human for that finding's id.

## Context budget

Load this skill and its two reference files only. Do not paste full third-party skill bodies (`plan-reviewer`, `project-verify-plan`) into context — read only what's needed for the specific plan under review.
