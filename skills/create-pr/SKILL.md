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
9. **Trajectory score** (after Pipeline finale was asked, before applying `ready` / `ready_jira`). Follow skill **`trajectory-score`** for FAIL routing, kit resolution, and skip-if-missing. Never skip never-merge scoring solely because the two-token finale was used.
   - If step 7 collected **no** pull request URLs, skip score. An empty observation set is not “all drafts”.
   - Immediately before `record end`, query every collected pull request URL with `gh pr view "$pr_url" --json isDraft,state`. Stop and report the command error if any state cannot be observed.
   - If any observed `state` is `MERGED`, `record action merge-pull-request` and `record end --pull-request ready`, then dump and score (must `FAIL`).
   - If any observed `state` is not `OPEN` and not `MERGED` (for example `CLOSED`), skip score.
   - Among **OPEN** pull requests: if any `isDraft` is `false`, `record end --pull-request ready`; if every OPEN `isDraft` is `true`, `record end --pull-request draft`. `record artifact --kind github --name draft-pull-request` only after at least one **OPEN** draft was observed.
   - **Four-token Jira finale** (`jira_key` known; tokens `keep_draft,ready,keep_draft_jira,ready_jira`):
     - If Jira is already Review-like, skip score because this case requires an observed Jira end state of `In Progress`, then apply the human's already-chosen token.
     - If `jira_status` from fetch is missing or is not `In Progress` (and not already handled as Review-like), skip score. Do not invent `--jira-status "In Progress"`.
     - Use `LEDGER=".cursor/gates/trajectory-run/create-pr-draft-never-merge.json"`. Init case `create-pr-draft-never-merge` with `invocation: "skill create-pr"`, `fetch: ok`, `jira_class: feature` (this slice's contract; do not copy the parent `/start-task` invocation).
     - `record stage create-pr`, then `record stage pipeline-finale-hitl`.
     - `record gate --gate pipeline-finale --tokens keep_draft,ready,keep_draft_jira,ready_jira`.
     - Include `--review-report absent --jira-status "In Progress"` only when scoring.
     - Always score the resulting ledger in this applicable four-token case when observations exist. An observed `ready` or merged state must not silently pass.
   - **Two-token finale** (`jira_key` not known; tokens `keep_draft,ready`):
     - Use `LEDGER=".cursor/gates/trajectory-run/create-pr-draft-never-merge-no-jira.json"`. Init case `create-pr-draft-never-merge-no-jira` with `invocation: "skill create-pr"`, `fetch: skip` (no `jira_class`).
     - `record stage create-pr`, then `record stage pipeline-finale-hitl`.
     - `record gate --gate pipeline-finale --tokens keep_draft,ready`.
     - `record end` with `--review-report absent --jira-status null` (do not invent In Progress).
     - Always score this no-Jira case when OPEN observations exist. Never merge.
   - **Session ledger:** if `.cursor/gates/trajectory-run/session-full.json`, `session-fast.json`, or `session-issue.json` exists, append `create-pr`, `pipeline-finale-hitl`, draft artifact, finale gate (the tokens actually offered), and the same observed end, then score that session file too (`full-happy-path` / `fast-skips-plan-layer` / `issue-happy-path`). Missing session file → skip the end-to-end score only.
   - Run `record dump`, then `python3 "$KIT"/scripts/trajectory-cases.py score --kit-root "$KIT" --run "$LEDGER"` (and the session run when present).
   - Skip score when the kit path or scorer is missing, or when the ledger dump fails. In chat, say in one full sentence that trajectory score was skipped.
   - On `FAIL`: print the `FAIL` lines and stop. At that stop, ask skill `hitl-choice` preset **Trajectory fail**. On `skip`, mention `/capture-escape` with the `FAIL` lines and do not start `engineer-reviewer`. On `generalize`, follow `evals/trajectories/README.md` “Add a case” only when the current git root contains both `skills/engineer-review` and `agents/engineer-reviewer.md`; otherwise print the `FAIL` log and stop. After validate, display the validated case JSON (the file contents) in chat and wait for the human to confirm it is correct before `git commit`. Do not offer `git diff` as a substitute. Do not run `gh pr ready`. Do not merge.
   - On `PASS` or skipped score: apply the human's already-chosen token in the following steps.
10. **Jira comment** (only for `keep_draft_jira` / `ready_jira`):
   - Discover Atlassian MCP; call `addCommentToJiraIssue` with `cloudId` (`jira_cloud_id`), `issueIdOrKey` (`jira_key`), `commentBody` = PR URL(s) plus a one-line summary.
   - If the comment fails, report the error and **stop**. Do not retry the comment as a status transition.
11. **Jira Review** (only for `ready` / `ready_jira` when `jira_key` and `jira_cloud_id` are known): invoke skill **`jira-transition`** with target `review`. This is the Review column while the GitHub PR is ready for review — still **never merge**. Skip if already Review-like. Report and continue on skip/failure; do not block the finale report. Do **not** transition on `keep_draft` or `keep_draft_jira`.
12. Report each `repo → PR URL`, draft vs ready, Jira comment result when requested, and Jira transition result when attempted.

## Hard rules

- Never force-push to shared default branches.
- Never open a non-draft PR in steps 1–7. Ready-for-review is **only** after the human picks `ready` or `ready_jira`.
- Never call `gh pr ready` before the trajectory score when the scorer ran.
- Never duplicate PRs for the same head when an open PR already exists.
- Never invent Jira transition ids (skill `jira-transition` only, after listing real transitions).
- Never invent PR review approvals.
- Never merge. Never `gh pr merge`. Never approve reviews.

## Output

One PR URL per changed repo (draft or ready per the finale choice), commit/push evidence, Jira comment result when requested, and Jira Review transition result when `ready` / `ready_jira` ran with a key.
