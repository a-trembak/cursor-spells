---
name: create-pr
description: >-
  Use at the end of a kit pipeline (/start-task, /start-task --fast,
  /start-issue-task) or when asked to open a draft PR for the current feature
  branch work. Commits remaining changes if needed, pushes, creates or updates a
  draft GitHub PR, then HITL Pipeline finale (keep draft / ready / Jira comment).
  Never merges. On ready / ready_jira with a Jira key, transitions the ticket to Review.
---

# Create PR

Shared **pipeline finale**: ensure work is on a feature branch, committed, pushed, and represented by a **draft** GitHub pull request, then one HITL gate. Prefer third-party `ce-commit-push-pr` with `mode:pipeline` when installed; otherwise use the built-in `gh` steps below.

## When to Use

- End of full `/start-task` (after `update-docs`)
- End of `/start-task --fast` (after `engineer-reviewer`)
- End of `/start-issue-task` (after `engineer-reviewer`)
- Human asks to open/update a draft PR for the current kit-driven branch

## Defaults (non-interactive until the draft exists)

| Choice | Default |
|--------|---------|
| PR state | **Draft first** (`gh pr create --draft`) |
| Existing open PR for this head | Update title/body only if body is empty or a clear placeholder; otherwise leave body, report URL |
| Base branch | Repo default (`main` / `master` / `origin/HEAD`) |
| After draft | HITL **Pipeline finale** via `hitl-choice` (AskQuestion required) |

Callers must pass `jira_key` / `jira_cloud_id` when `jira-fetch` succeeded so Jira comment options can appear.

## Spine

1. Resolve target repo(s) from the handoff `repo → branch` map, or the current git root. Multi-repo: repeat steps 2–6 **per changed repo**.
2. Confirm you are **not** on the default branch. If still on default with changes: create/check out the shared feature branch from the handoff (or derive via `software-developer/references/branch-setup.md`) before continuing.
3. If `ce-commit-push-pr` is installed: run it with `mode:pipeline` (and any PR ref already known). Prefer its commit grouping and PR body conventions. Skip to step 7 when it succeeds (it must still create/reuse a **draft**).
4. Else **built-in path**:
   - `git status` / `git diff` — stage intentional files only (never `git add -A` / `git add .`).
   - Commit if there are staged/uncommitted changes; match recent commit style (default `fix:` when ambiguous for bug work, `feat:` only for new capability).
   - `git push -u origin <branch>` (retry with backoff on network errors).
5. Check for an existing open PR: `gh pr list --head <branch> --state open …`. Exit 0 + `[]` → create. Non-zero `gh` → stop and report auth/connectivity (do not assume “no PR”).
6. Create draft PR if none:
   ```bash
   gh pr create --draft --title "<title>" --body "<body>"
   ```
   Title/body sources (first non-empty wins for title): Jira key + short summary, AC one-liner, plan/tech-spec title, latest commit subject. Body should include: summary, test/verification notes, link to Jira/AC/plan path when known.
7. Collect each `repo → PR URL` (and draft status). **Do not stop yet.**
8. **HITL Pipeline finale** via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Pipeline finale**.
   - Always offer `keep_draft` and `ready`.
   - Offer `keep_draft_jira` and `ready_jira` **only** when `jira_key` is known.
   - `keep_draft` — stop. Draft stays draft.
   - `ready` — `gh pr ready` for each opened PR in this run.
   - `keep_draft_jira` — leave draft; comment Jira (below).
   - `ready_jira` — `gh pr ready` then comment Jira.
9. **Jira comment** (only for `keep_draft_jira` / `ready_jira`):
   - Discover Atlassian MCP; call `addCommentToJiraIssue` with `cloudId` (`jira_cloud_id`), `issueIdOrKey` (`jira_key`), `commentBody` = PR URL(s) plus a one-line summary.
   - If the comment fails, report the error and **stop**. Do not retry the comment as a status transition.
10. **Jira Review** (only for `ready` / `ready_jira` when `jira_key` and `jira_cloud_id` are known): invoke skill **`jira-transition`** with target `review`. This is the Review column while the GitHub PR is ready for review — still **never merge**. Skip if already Review-like. Report and continue on skip/failure; do not block the finale report. Do **not** transition on `keep_draft` or `keep_draft_jira`.
11. Report each `repo → PR URL`, draft vs ready, Jira comment result when requested, and Jira transition result when attempted.

## Hard rules

- Never force-push to shared default branches.
- Never open a non-draft PR in steps 1–7. Ready-for-review is **only** after the human picks `ready` or `ready_jira`.
- Never duplicate PRs for the same head when an open PR already exists.
- Never invent Jira transition ids (skill `jira-transition` only, after listing real transitions).
- Never invent PR review approvals.
- Never merge. Never `gh pr merge`. Never approve reviews.

## Output

One PR URL per changed repo (draft or ready per the finale choice), commit/push evidence, Jira comment result when requested, and Jira Review transition result when `ready` / `ready_jira` ran with a key.
