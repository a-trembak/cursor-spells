# Jira status transitions (In Progress / Review)

## Status

`approved` — implementation target for cursor-spells kit.

## Goal

When a pipeline starts from a Jira ticket, move that ticket to **In Progress**. When the GitHub PR is marked ready for review, move it to **Review**. Do this through Atlassian MCP without inventing workflow ids and without merging the PR.

## Decisions

| Decision | Choice |
|----------|--------|
| Shared matcher | `scripts/jira-issue.sh`: `jira_normalize_status`, `jira_status_matches_target`, `jira_pick_transition_id` |
| Shared skill | `jira-transition` — `getTransitionsForJiraIssue` then `transitionJiraIssue` |
| Start trigger | After successful `jira-fetch` on `/start-task` (full and `--fast`) and `/start-issue-task` → target `in_progress` |
| Review trigger | `create-pr` HITL `ready` or `ready_jira` when `jira_key` is known → target `review` |
| Not Review | `keep_draft` / `keep_draft_jira` (ticket stays In Progress) |
| `/write-tech-spec` | Fetch only — no transition |
| Match field | Destination status `to.name`, then transition `name` if needed |
| Missing transition / MCP error | Report and **continue** the pipeline (do not stop) |
| Comment failure | Unchanged: report and stop; do not retry as a transition |
| GitHub merge | Still **never** `gh pr merge`. Review means the Jira Review column while the PR is ready for review |

## Why Review is on ready, not GitHub merge

The kit never merges PRs (human merges later). Jira **Review** is the code-review column, which maps to marking the PR ready (`ready` / `ready_jira`), not to the merge event.

## `in_progress` names

In Progress, In-Progress, Doing, WIP, Started (case-insensitive; ignore spaces/hyphens/underscores).

## `review` names

Review, In Review, Code Review, Peer Review, To Review, Ready for Review.

## Flow

1. `/start-task` or `/start-issue-task` fetches the issue.
2. If already matching `in_progress`, skip. Else list transitions, pick id via `jira_pick_transition_id in_progress`, call `transitionJiraIssue`.
3. Pipeline continues even if the move fails.
4. At `create-pr`, after `ready` / `ready_jira`: same steps with target `review`.

## Out of scope

Done/QA columns after GitHub merge; custom per-project status maps; inventing transition screens/fields; Linear; transitioning pasted (non-MCP) tickets without `jira_cloud_id`.

## New/changed artifacts

- `scripts/jira-issue.sh` + `scripts/tests/jira-issue-test.sh`
- `skills/jira-transition/SKILL.md`
- `commands/start-task.md`, `commands/start-issue-task.md`
- `skills/create-pr/SKILL.md`, `skills/hitl-choice/SKILL.md`
- `scripts/tests/jira-ac-router-finale-test.sh`
- README, pipeline-flow.md/html, dogfood checklist
