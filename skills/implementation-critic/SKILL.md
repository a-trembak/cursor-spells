---
name: implementation-critic
description: >-
  Use after an implementation plan (and its tech spec, if any) is written and
  before any code is written. Audits the plan for unnecessary complexity,
  abstraction violations, missed risks, scope drift, and — for bug-fix plans —
  root-cause quality and regression risk. Use when the user runs /critique-plan,
  /start-issue-task, asks to critique/audit a plan, or before dispatching a
  developer or bug-fixer agent.
---

# Implementation Critic

Audits an existing implementation plan **before code is written**. Never writes plans or code — only produces a structured critique the plan author or a human acts on.

## When to Use

- A plan exists (from `writing-plans` or elsewhere) and a developer is about to start implementing it
- Bug-fix plans from `/start-issue-task` (Pass C required)
- Manual `/critique-plan <path>` or `@implementation-critic`
- Not for reviewing a code diff (that's `engineer-review`) and not for writing a new plan (that's `writing-plans`)

## Lenses

| Pass | Skill | Catches | When |
|------|-------|---------|------|
| **A — Design** | `plan-reviewer` (mblode/agent-skills) if installed | Unnecessary complexity, YAGNI, simpler alternatives, wrong abstractions | Always |
| **B — Risk** | `project-verify-plan` (envoydev/agents-stack) if installed | Failure modes, scope drift, edges/safety, migration & architecture fit | Always |
| **C — Bug fix** | Built-in checklist only | Root cause vs symptom, regression blast radius, better alternative, tests catch the bug | Bug-fix plans only |

If a lens's skill is not installed, fall back to its built-in checklist (see [references/lenses.md](references/lenses.md)) and note `skill_missing` in Coverage — never skip a required pass or block the whole run for a missing skill.

## Spine

1. Read the plan file (and tech spec / AC / Jira context if a path was given or discoverable next to the plan).
2. Read `.cursor/project-patterns.md` in the **current project** (not the kit) if present — Pass A's "simpler alternative" and "existing abstraction" checks need it.
3. Run Pass A, then Pass B, over the same plan (see [references/lenses.md](references/lenses.md) for each pass's checklist).
4. If this is a bug-fix plan (path/topic `-fix`, `/start-issue-task`, or plan states it fixes a defect): run **Pass C**. Otherwise set Coverage `pass_c: n/a (not a bug-fix plan)`.
5. Classify every finding as `must-fix`, `should-fix`, or `accept-risk` (see [references/output-schema.md](references/output-schema.md)).
6. Emit the report per `references/output-schema.md`. Do not edit the plan file. If `Verdict` is `blocked` or `clear pending accept`, ask next steps via skill `hitl-choice` when this skill is driving the gate directly (AskQuestion required; text only after failed/missing tool); callers like `approve-plan` / `/start-issue-task` also own that ask.

## Fix policy

This skill **never applies fixes**. It is read-only on the plan. All findings go to the human or the plan author to act on; a re-run after edits produces a fresh report.

## Gate

If any `must-fix` finding is open, the developer agent must not start implementing the plan until it is resolved in the plan or explicitly `accept`ed by the human for that finding's id.

## Context budget

Load this skill and its two reference files only. Do not paste full third-party skill bodies (`plan-reviewer`, `project-verify-plan`) into context — read only what's needed for the specific plan under review.
