# Review surface before review-gate

## Status

`approved` — implementation target for cursor-spells kit (human confirmed: intermediate convenience, pipeline continues).

## Goal

When a plan has been executed, the human can open the new changes in Cursor (pull request tab + local folders on the feature branch), look at them, leave them as they are, then answer `approve` / `done`. Engineer-review starts next. The pipeline is **not** finished at this gate.

## Problem

`finish-plan` asked “want to do your own review first?” while:

1. Open workspace folders were often still on `main` (agent coded in a worktree, or only one of several repos was switched).
2. Cursor’s pull request / merge-base tab was empty because `SetActiveBranch` was never called.

The human had no convenient surface to look at. Opening a GitHub pull request at this point would look like the pipeline finale (`create-pr`), which is wrong — docs and engineer-review still follow.

## Decisions

| Decision | Choice |
|----------|--------|
| When | After writing `review-gate/<slug>`, **before** the review-gate HITL |
| Surface | `git checkout` in each folder the human has open + `SetActiveBranch` per repo |
| GitHub pull request | **No.** `create-pr` stays after engineer-review and `update-docs` |
| After `approve` / `done` / `skip` | Engineer-review (unchanged). Pipeline continues |
| After `fixes` | `software-developer`, then re-run review-surface, then re-ask the same gate |
| Worktrees | Not a substitute for the open folder |

## Out of scope

- Pipeline finale HITL, `gh pr ready`, Jira Review, merge
- Changing `--fast` / `/csp-start-issue-task` (those skip this HITL)

## Files

- `skills/finish-plan/references/review-surface.md`
- `skills/finish-plan/SKILL.md`, `commands/csp-finish-plan.md`
- `skills/software-developer/references/branch-setup.md`
- `rules/after-plan-review-gate.mdc`, `hooks/post-plan-review-gate.sh`
- `scripts/tests/review-surface-test.sh`
