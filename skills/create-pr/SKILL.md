---
name: create-pr
description: >-
  Use at the end of a kit pipeline (/start-task, /start-task --fast,
  /start-issue-task) or when asked to open a draft PR for the current feature
  branch work. Commits remaining changes if needed, pushes, and creates or
  updates a draft GitHub PR. Non-interactive (pipeline defaults).
---

# Create PR

Shared **pipeline finale**: ensure work is on a feature branch, committed, pushed, and represented by a **draft** GitHub pull request. Prefer third-party `ce-commit-push-pr` with `mode:pipeline` when installed; otherwise use the built-in `gh` steps below.

## When to Use

- End of full `/start-task` (after `update-docs`)
- End of `/start-task --fast` (after `engineer-reviewer`)
- End of `/start-issue-task` (after `engineer-reviewer`)
- Human asks to open/update a draft PR for the current kit-driven branch

## Defaults (non-interactive)

| Choice | Default |
|--------|---------|
| PR state | **Draft** (`gh pr create --draft`) |
| Existing open PR for this head | Update title/body only if body is empty or a clear placeholder; otherwise leave body, report URL |
| Base branch | Repo default (`main` / `master` / `origin/HEAD`) |
| HITL | None — never invent answers; use these defaults |

## Spine

1. Resolve target repo(s) from the handoff `repo → branch` map, or the current git root. Multi-repo: repeat steps 2–6 **per changed repo**.
2. Confirm you are **not** on the default branch. If still on default with changes: create/check out the shared feature branch from the handoff (or derive via `software-developer/references/branch-setup.md`) before continuing.
3. If `ce-commit-push-pr` is installed: run it with `mode:pipeline` (and any PR ref already known). Prefer its commit grouping and PR body conventions. Skip to step 7 when it succeeds.
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
7. Report each `repo → PR URL` (and draft status) to the user. Pipeline complete.

## Hard rules

- Never force-push to shared default branches.
- Never open a non-draft PR unless the human explicitly asked for ready-for-review.
- Never duplicate PRs for the same head when an open PR already exists.
- Never invent Jira transitions or PR review approvals.

## Output

One draft PR URL per changed repo (or confirmation that an existing PR was reused/updated), plus commit/push evidence.
