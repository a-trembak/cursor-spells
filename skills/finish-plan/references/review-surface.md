# Review surface (before review-gate HITL)

Intermediate convenience step: show the finished work in the human's Cursor client **before** asking `skip` / `approve` / `done` / `fixes`. This **does not end the pipeline**.

The human looks at the merge-base diff (the pull request tab in Cursor) when commits exist on the feature branch; when the branch has **zero commits ahead of base** or only uncommitted work, they review the **working tree** via chat (`git status` / `git diff` summaries you paste). They leave the changes as they are or describe fixes, then answer the gate. After `skip` / `approve` / `done`, **engineer-review** runs, then `propose-commit`, then `update-docs`, then `create-pr` (the real shipping draft). Do not open a GitHub pull request here.

## When

Skill `finish-plan`, after the review-gate marker is written, **before** skill `hitl-choice` (Finish-plan HITL). **Re-run review-surface** after `fixes` land, before asking the same gate again.

Not for manual `/csp-engineer-review` (no review-gate). Not for `/csp-start-task --fast` or `/csp-start-issue-task` (those skip this HITL).

## Inputs

- `repo_branch_map` from the `csp-software-developer` (or `csp-bug-fixer`) handoff
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

## 2. Activate the pull request tab

For **each** open folder from step 1, call the session tool **`SetActiveBranch`**:

| Argument | Value |
|----------|--------|
| `path` | Absolute git root of the folder the human has open |
| `branchName` | The shared feature branch |

This is what shows the merge-base diff in the client's pull request tab. It is **not** a GitHub pull request. Calling it for only one repo in a multi-repo workspace leaves the other folders on the old branch.

Attempt the call. Do not skip because you are “unsure the tool exists”. If the tool is missing after a hard not-found, keep the `git checkout` and say in chat that the pull request tab could not be activated.

Do **not** `git push`. Do **not** invoke skill `create-pr`. Do **not** run `gh pr create`. The shipping draft comes later, after engineer-review, `propose-commit`, and `update-docs`.

## 2b. Uncommitted change set (mandatory when ahead is empty)

Product pipelines may have **zero commits** on the feature branch ahead of base until `propose-commit`. The merge-base pull request tab can be empty even when the work tree is full of changes.

For **each** repo in the map, after checkout:

1. Run `git -C <open-folder> status --porcelain` and `git -C <open-folder> diff` (and `git diff --cached` if needed).
2. If `git rev-list --count <base>..<branch>` is `0` **or** the porcelain output is non-empty, paste or summarize in chat: dirty paths + a concise diff summary (cap huge diffs; point to paths).
3. State clearly that the pull request tab may be empty until commits exist; the human is reviewing the **working tree**.
4. **Do not** create a placeholder commit to feed the tab.

Keep attempting `SetActiveBranch` (step 2) for checkout visibility.

## 3. Then ask HITL — pipeline continues

Only after steps 1–2b were attempted, ask skill `hitl-choice` preset **Finish-plan / engineer-review / multi-repo HITL**.

In the question prompt, include each `repo → branch` so the human can open the tab. State clearly that this is their own look at the diff, not the end of the pipeline: after `approve` / `done` / `skip`, engineer-review starts.

Do not ask Pipeline finale.

## Hard rules

- Never ask the review-gate HITL before attempting this protocol.
- Never treat a linked worktree as the human's open folder.
- Never skip `SetActiveBranch` for a repo that was checked out.
- Never invoke `create-pr` here. Never `gh pr create`. Never `gh pr ready`. Never merge. Never ask Pipeline finale.
- After `skip` / `approve` / `done`, continue `finish-plan` into engineer-review. Do not stop as if the pipeline were finished.
