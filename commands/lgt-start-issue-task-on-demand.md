---
description: Bug-fix issue pipeline with on-demand budget defaults — Flash orchestrator, Composer bug-fixer, graphify scope/refresh, narrow context.
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
| **This chat** (Jira fetch, plan, critic, HITL, orientation) | **GLM 5.3 Flash** | Cheapest orchestration; keep replies concise |
| **Nested Task `csp-bug-fixer`** | **Composer 2.5** (standard, **not** Fast) | Tool use and edits in Cursor |

**Before step 5 (Fix):** if the active agent model is not Composer 2.5 standard, **stop once** and tell the human to switch the Agent model to **Composer 2.5** (not Fast), then continue with dispatch. Do not dispatch `csp-bug-fixer` on Flash or frontier models unless the human explicitly opts out in chat after the prompt.

After `csp-bug-fixer` returns, the human may switch back to **GLM 5.3 Flash** for short HITL before engineer-review.

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

- Full-price / default models → use `/lgt-start-issue-task` without this wrapper.
- Feature work → `/lgt-start-task` or `/lgt-start-task --fast`, not this command.
