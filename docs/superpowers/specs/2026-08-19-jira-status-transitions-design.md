# Jira status transitions (In Progress / Review)

## Status

`approved` — implementation target for cursor-spells kit.

## Goal

When a pipeline starts from a Jira ticket, move that ticket to **In Progress**. When every opened GitHub pull request for that run is merged and every continuous-integration build succeeded, move it to **Review**. Do this through Atlassian MCP without inventing workflow ids and without merging the pull request.

## Decisions

| Decision | Choice |
|----------|--------|
| Shared matcher | `scripts/jira-issue.sh`: `jira_normalize_status`, `jira_status_matches_target`, `jira_pick_transition_id` |
| Merge + build gate | `scripts/pr-merge-ci.sh`: `pr_merge_ci_verdict` |
| Shared skill | `jira-transition` — `getTransitionsForJiraIssue` then `transitionJiraIssue` |
| Start trigger | After successful `jira-fetch` on `/csp-start-task` (full and `--fast`) and `/csp-start-issue-task` → target `in_progress` |
| Review trigger | `create-pr` after HITL `ready` or `ready_jira` when `jira_key` is known **and** `pr_merge_ci_verdict` is `all_merged_ci_success` → target `review` |
| Not Review | `keep_draft` / `keep_draft_jira`; ready tokens before every pull request is merged with successful builds; `ci_failed`; `closed_unmerged` |
| `/csp-write-tech-spec` | Fetch only — no transition |
| Match field | Destination status `to.name`, then transition `name` if needed |
| Missing transition / MCP error | Report and **continue** the pipeline (do not stop) |
| Comment failure | Report and stop; do not retry as a transition |
| GitHub merge | Never `gh pr merge`. The agent observes a later human merge and the build rollup; it does not merge |

## Why Review waits for merge and successful builds

`ready` / `ready_jira` only mark the GitHub pull request ready for review. Jira **Review** is the column after every opened pull request in the run is `MERGED` and every check in `statusCheckRollup` succeeded (CheckRun `SUCCESS` / `SKIPPED` / `NEUTRAL`, or commit-status `state: SUCCESS`, or no checks). Failed builds (`ci_failed`) do not move the ticket. A pull request closed without merge (`closed_unmerged`) does not wait in a loop. The kit never calls `gh pr merge`.

## `in_progress` names

In Progress, In-Progress, Doing, WIP, Started (case-insensitive; ignore spaces/hyphens/underscores).

## `review` names

Review, In Review, Code Review, Peer Review, To Review, Ready for Review.

## Flow

1. `/csp-start-task` or `/csp-start-issue-task` fetches the issue.
2. If already matching `in_progress`, skip. Else list transitions, pick id via `jira_pick_transition_id in_progress`, call `transitionJiraIssue`.
3. Pipeline continues even if the move fails.
4. At `create-pr`, after `ready` / `ready_jira`: observe every opened pull request (`state` + `statusCheckRollup`). Subscribe and wait while the verdict is `not_merged` or `pending_ci`. On `all_merged_ci_success`, same transition steps with target `review`.

## Out of scope

Done/QA columns beyond the Review names above; custom per-project status maps; inventing transition screens/fields; Linear; transitioning pasted (non-MCP) tickets without `jira_cloud_id`.

## New/changed artifacts

- `scripts/jira-issue.sh` + `scripts/tests/jira-issue-test.sh`
- `scripts/pr-merge-ci.sh` + `scripts/tests/pr-merge-ci-test.sh`
- `skills/jira-transition/SKILL.md`
- `commands/csp-start-task.md`, `commands/csp-start-issue-task.md`
- `skills/create-pr/SKILL.md`, `skills/hitl-choice/SKILL.md`
- `scripts/tests/jira-ac-router-finale-test.sh`
- README, pipeline-flow.md/html, dogfood checklist
