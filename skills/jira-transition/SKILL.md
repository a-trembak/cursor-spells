---
name: jira-transition
description: >-
  Move a Jira issue to In Progress or Review via Atlassian MCP. Use from
  /start-task and /start-issue-task (in_progress after fetch) and from
  create-pr (review after ready / ready_jira). Never merges GitHub PRs.
  Never invents transition ids.
---

# Jira Transition

Set a fetched Jira issue to a named workflow column. Matching uses `scripts/jira-issue.sh` (consumer copy after `csp update`, or kit path).

## When to Use

- `/start-task` (full or `--fast`) after `jira-fetch` succeeds → target `in_progress`
- `/start-issue-task` after `jira-fetch` succeeds (or reuse of an already-fetched issue) → target `in_progress`
- `create-pr` after HITL `ready` or `ready_jira` when `jira_key` is known → target `review`
- Not from `/write-tech-spec`. Not on `keep_draft` / `keep_draft_jira`. Not as a substitute for `addCommentToJiraIssue`.

## Required inputs

| Field | Source |
|-------|--------|
| `jira_key` | `jira-fetch` handoff |
| `jira_cloud_id` | `jira-fetch` handoff |
| `target` | `in_progress` or `review` |
| `jira_status` | current status name when known |

If `jira_key` or `jira_cloud_id` is missing, **return** without MCP calls. The caller continues the pipeline.

## Match helpers

Source `scripts/jira-issue.sh`:

1. If `jira_status` is set and `jira_status_matches_target "<target>" "<jira_status>"` is true → **skip** (already there). Report `skipped: already <status>`.
2. Match **destination status** (`to.name`), not only the transition button label (e.g. "Start Progress" → In Progress).

**`in_progress` destinations:** In Progress, In-Progress, Doing, WIP, Started.

**`review` destinations:** Review, In Review, Code Review, Peer Review, To Review, Ready for Review.

Use `jira_pick_transition_id "<target>"` on `id<TAB>to.name` lines.

## MCP steps (mandatory order)

1. Discover Atlassian MCP. Required: `getTransitionsForJiraIssue`, `transitionJiraIssue`.
2. Call `getTransitionsForJiraIssue` with `cloudId` (`jira_cloud_id`) and `issueIdOrKey` (`jira_key`). Read each transition's `to.name` (and `id`).
3. Build `id<TAB>to.name` lines and run `jira_pick_transition_id "<target>"`. If empty, retry matching `transition.name` the same way.
4. If no id: report available destination names and **return without blocking**. Do not guess an id. Do not create a workflow.
5. Call `transitionJiraIssue` with `cloudId`, `issueIdOrKey`, `transition: { id }`. Do not invent extra `fields`. If Jira requires a transition screen with unknown values, report and return.
6. On MCP/auth/error: report and **return**. Callers must not stop `/start-task` or `create-pr` for a failed transition. Do not retry a failed transition as a Jira comment.

## Hard rules

- Never invent transition ids or status names that `getTransitionsForJiraIssue` did not return.
- Never call `transitionJiraIssue` for any target other than `in_progress` or `review` from this kit.
- Never `gh pr merge`. Never approve GitHub reviews.
- Never transition from `/write-tech-spec`.
- Idempotent: already-matching current status is a skip, not an error.

## Output

| Field | Value |
|-------|--------|
| `jira_transition` | `moved` / `skipped` / `failed` |
| `jira_status_after` | Destination name when moved, else previous |
| `jira_transition_note` | One line (id used, skip reason, or error) |
