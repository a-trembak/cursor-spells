# Review surface (before review-gate HITL)

Intermediate convenience step: give the human a **draft** GitHub pull request URL they can open in Cursor, with local folders on the feature branch, **before** asking `skip` / `approve` / `done` / `fixes`. This **does not end the pipeline**.

The human opens that draft in Cursor, looks at the changes, leaves them as they are or describes fixes, then answers the gate. After `skip` / `approve` / `done`, **engineer-review** runs, then `update-docs`. Later `create-pr` `mode:pipeline` **reuses** the same draft and only then asks Pipeline finale. Do not mark the draft ready here. Do not ask Pipeline finale here.

## When

Skill `finish-plan`, after the review-gate marker is written, **before** skill `hitl-choice` (Finish-plan HITL). **Re-run review-surface** after `fixes` land, before asking the same gate again (push new commits onto the same draft).

Not for manual `/engineer-review` (no review-gate). Not for `/start-task --fast` or `/start-issue-task` (those skip this HITL).

## Inputs

- `repo_branch_map` from the `software-developer` (or `bug-fixer`) handoff
- If the map is missing: the current git root and its current branch, when that branch is not the default (`main` / `master` / `origin/HEAD`)

If the map is empty and the current branch is the default: skip surface, then continue `finish-plan` (later routing may still stop with “no changed repos”).

## 1. Check out the branch the human has open

For **each** `repo → branch` in the map:

1. Resolve the folder the human has open for that repo (workspace folder / multi-root folder). That path is what `SetActiveBranch` and `git checkout` must use.
2. A linked worktree where the agent coded is **not** a substitute. If the open folder is still on the default branch, check it out onto the feature branch even when a worktree already has that branch.
3. Confirm it is a git repo (`git -C <open-folder> rev-parse --show-toplevel`). If not → stop and ask.
4. If the open folder is dirty (`git status --porcelain` non-empty) and is on a **different** branch: **stop and ask**. Do not stash silently. Do not discard.
5. Check out the feature branch in that folder:

   ```bash
   git -C <open-folder> checkout <branch>
   ```

6. Repeat for **every** repo in the map (same branch name in each).

## 2. Activate the Cursor pull request tab

For **each** open folder from step 1, call the session tool **`SetActiveBranch`**:

| Argument | Value |
|----------|--------|
| `path` | Absolute git root of the folder the human has open |
| `branchName` | The shared feature branch |

This is what shows the related draft in the client's pull request tab. Calling it for only one repo in a multi-repo workspace leaves the other folders on the old branch.

Attempt the call. Do not skip because you are “unsure the tool exists”. If the tool is missing after a hard not-found, keep the `git checkout` and still paste the draft URL in chat.

## 3. Open a draft pull request and paste the URL

After checkouts and `SetActiveBranch`:

1. Invoke skill `create-pr` with **`mode:surface`** (commit remaining intentional files if needed, push, create or reuse a **draft** GitHub pull request per changed repo).
2. **Stop after step 7** of `create-pr`. Do not ask Pipeline finale. Do not run trajectory score. Do not `gh pr ready`. Do not merge. Do not invoke `jira-transition`.
3. Paste each draft URL in chat (and in the HITL prompt). The human opens that link in Cursor.
4. If `gh` / auth fails: report the error, keep the local checkouts and `SetActiveBranch`, and continue to the HITL question. A missing remote draft must not block the human's local look.
5. If the harness has `ManagePullRequest` `create_pr` and no working `gh`: open a **draft** that way. Still never mark ready.

```bash
gh pr create --draft --title "<title>" --body "<body>"
```

Later `create-pr` `mode:pipeline` (after engineer-review and `update-docs`) reuses these drafts and then asks Pipeline finale.

## 4. Then ask HITL — pipeline continues

Only after steps 1–3 were attempted, ask skill `hitl-choice` preset **Finish-plan / engineer-review / multi-repo HITL**.

In the question prompt, include each `repo → branch` **and each draft pull request URL**. State clearly that this is their own look at the draft, not the end of the pipeline: after `approve` / `done` / `skip`, engineer-review starts.

Do not ask Pipeline finale.

## Hard rules

- Never ask the review-gate HITL before attempting this protocol.
- Never treat a linked worktree as the human's open folder.
- Never skip `SetActiveBranch` for a repo that was checked out.
- Never mark the draft ready. Never merge. Never ask Pipeline finale.
- After `skip` / `approve` / `done`, continue `finish-plan` into engineer-review. Do not stop as if the pipeline were finished.
