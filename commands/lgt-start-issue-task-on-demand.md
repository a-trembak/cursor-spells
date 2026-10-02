---
description: Bug-fix issue pipeline with on-demand budget defaults — Flash orchestrator, Composer 2.5 nested Tasks, graphify scope/refresh, narrow context.
argument-hint: "[jira-key|jira-url]"
---

# /lgt-start-issue-task-on-demand

Same pipeline as **`/lgt-start-issue-task`**, with a fixed **on-demand budget orchestration contract** (models, graphify, scope). Use when included Cursor usage is exhausted and you pay per token.

**Do not** ask the human to paste the contract below — it is already binding for this invocation.

## On-demand orchestration contract (mandatory)

Apply for the **entire** run unless the human overrides in the same message:

### Models

| Role | Model | Notes |
|------|--------|--------|
| **This chat** (orchestrator — all steps) | **GLM 5.3 Flash** | Jira, plan, HITL, dispatch nested Tasks, orientation; keep replies concise |
| **Every pipeline nested Task** (steps 4–6) | **`composer-2.5`** | Standard Composer 2.5 — **not** `composer-2.5-fast` |

The human sets **only** the parent Agent model to **GLM 5.3 Flash**. They do **not** switch the parent to Composer for critic or review.

### Nested Task `model` parameter (mandatory)

Cursor inherits the parent model when `model` is omitted. In this mode that would run critics and fixers on Flash — **forbidden**.

For **each** nested **Task** in steps 4–6, pass an explicit model slug:

```text
model: "composer-2.5"
```

| Step | `subagent_type` | `model` |
|------|-----------------|--------|
| 4 — Critic | `csp-implementation-critic` | `composer-2.5` |
| 5 — Fix | `csp-bug-fixer` | `composer-2.5` |
| 6 — Engineer review | `csp-engineer-reviewer` or `csp-multi-repo-supervisor` | `composer-2.5` |

- Dispatch in the **same turn** as the decision to run that step — **wait** for the Task to return before the next pipeline step.
- **Forbidden:** status-only chat ("launching plan critic") without a Task call.
- **Forbidden:** running Pass A/B/C or product edits **inline** in the parent on Flash — those steps belong in the nested Task on `composer-2.5`.
- If Task dispatch fails, retry once with the same `subagent_type` and `model: "composer-2.5"`. If it still fails, stop and report the error — do not ask the human to change the **parent** model to Composer unless they opt in.

Engineer-review **phase** subagents spawned by `csp-engineer-reviewer` follow that agent's protocol; the orchestrator's step-6 Task still uses `model: "composer-2.5"`.

### Graphify

Load skill **`graphify-pipeline`** when artifacts exist under the project (or workspace parent):

- During plan / critic: compact **impact-hint** or caller queries for planned paths (read-only).
- **`csp-bug-fixer`:** callers/callees after root cause; **`graphify-pipeline.sh refresh`** after verify (per target repo).
- **Engineer-review:** read-only graph; never `refresh` during review.

If absent, skip without blocking.

### Scope and cost

- Minimal fix only; no drive-by refactors.
- Narrow `@` context and file reads to the ticket and plan paths.
- Prefer **tiny-diff** engineer-review phase skip when [phase-protocol tiny-diff rules](skills/engineer-review/references/phase-protocol.md) apply; record `phase_skip: tiny-diff (...)` in Coverage when used.
- Do not run optional browser/Figma loops unless the ticket requires UI proof.

## Arguments

- Jira issue key (`PROJ-123`) or browse URL. If omitted, ask for it (typed chat).

## Pipeline

**Load and execute** [`commands/lgt-start-issue-task.md`](lgt-start-issue-task.md) **in full**, with the **On-demand orchestration contract** above taking precedence over default model habits.

Do not duplicate or replace the issue-task steps — only add the contract constraints.

## Notes

- Full-price / default models → use `/lgt-start-issue-task` without this wrapper (nested Tasks may inherit the parent model).
- Feature work → `/lgt-start-task` or `/lgt-start-task --fast`, not this command.
