# Review surface before review-gate

## Status

`approved` — implementation target for cursor-spells kit (human confirmed: intermediate convenience, pipeline continues).

## Goal

When a plan has been executed, the human gets a **draft** GitHub pull request URL they can open in Cursor, with local folders on the feature branch. They look at the changes, leave them as they are, then answer `approve` / `done`. Engineer-review starts next. The pipeline is **not** finished at this gate (no Pipeline finale, no ready).

## Problem

`finish-plan` asked “want to do your own review first?” while:

1. Open workspace folders were often still on `main` (agent coded in a worktree, or only one of several repos was switched).
2. Cursor’s pull request / merge-base tab was empty because `SetActiveBranch` was never called.

The human had no convenient surface to look at: no draft URL, folders still on `main`, and Cursor’s pull request tab empty because `SetActiveBranch` was never called.

Opening a **ready** pull request or asking Pipeline finale at this point would look like the pipeline end, which is wrong — engineer-review and docs still follow. A **draft** URL is the convenience surface; finale stays later.

## Decisions

| Decision | Choice |
|----------|--------|
| When | After writing `review-gate/<slug>`, **before** the review-gate HITL |
| Surface | `git checkout` in each open folder + `SetActiveBranch` + **draft** GitHub pull request URL |
| GitHub pull request | **Draft only.** `create-pr` `mode:surface` before the gate; `mode:pipeline` after engineer-review and `update-docs` reuses it and asks Pipeline finale |
| After `approve` / `done` / `skip` | Engineer-review (unchanged). Pipeline continues |
| After `fixes` | `software-developer`, then re-run review-surface, then re-ask the same gate |
| Worktrees | Not a substitute for the open folder |

## Out of scope

- Pipeline finale HITL, `gh pr ready`, Jira Review, merge
- Changing `--fast` / `/start-issue-task` (those skip this HITL)

## Files

- `skills/finish-plan/references/review-surface.md`
- `skills/finish-plan/SKILL.md`, `commands/finish-plan.md`
- `skills/software-developer/references/branch-setup.md`
- `rules/after-plan-review-gate.mdc`, `hooks/post-plan-review-gate.sh`
- `scripts/tests/review-surface-test.sh`
