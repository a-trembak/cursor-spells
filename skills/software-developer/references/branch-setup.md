# Implementation branch setup

First action of `software-developer` after entry conditions pass — **before** skill-heavy coding and **before** Task 1. No implementation commits land on `main` / `master` / the repo default branch.

## 1. Resolve target repos

Build the set of git repositories that the plan (and tech spec, if any) intend to change:

1. **Explicit in plan/spec** — paths or repo names listed in the plan's tasks, "Repos touched", or tech-spec "Changes by layer".
2. **Path prefixes in tasks** — e.g. `frontend/…`, `services/billing/…`, sibling folder names under a workspace parent.
3. **Fallback** — if the plan only describes the current checkout, the set is that single repo.

Map each path to a git root (`git -C <path> rev-parse --show-toplevel`). Deduplicate. Do **not** create branches in repos the plan does not touch.

If the set is empty or ambiguous (plan names a service that matches 0 or 2+ sibling repos): **stop and ask** — do not guess.

## 2. Derive branch name

One shared name for every target repo in this run (so multi-repo PRs stay correlated):

1. Human-supplied branch name for this run, if any.
2. Else ticket / AC id from the tech-spec AC references (slugified), e.g. `PROJ-123` → `feature/proj-123-<short-topic>`.
3. Else slug from the plan filename / topic: `docs/.../2026-07-24-foo-bar.md` → `feature/foo-bar`.
4. Lowercase kebab-case only. No spaces. Prefer `feature/<slug>` unless `.cursor/project-patterns.md` (or the human) declares another prefix.

If a target repo already has that local branch and it is checked out with a clean tree relative to the plan start: **reuse it**. Do not recreate.

## 3. Create and check out (each target repo)

For **each** repo in the set, from that repo's root:

1. Confirm it is a git repo; if not → stop and ask.
2. If the working tree is dirty (`git status --porcelain` non-empty) on a branch you would leave: **stop and ask** — do not stash silently, do not discard.
3. Resolve the base branch: `main` if it exists, else `master`, else the remote default (`origin/HEAD`). Prefer updating the local base from `origin` when the network is available (`git fetch origin <base>` then create from `origin/<base>`).
4. Create and switch:

   ```bash
   git checkout <base>
   git pull --ff-only origin <base>   # when remote reachable; else continue from local base and note it
   git checkout -b <branch-name>
   ```

   If `-b` fails because the branch exists: `git checkout <branch-name>` only when that is intentional reuse (step 2); otherwise stop and ask.
5. Record in the run handoff: `repo_path → branch-name` (and base used).

Do **not** `git push` unless the human or a later shipping skill asks for it. Local branch creation is enough to start implementation.

## 4. Multi-repo rules

- Create the branch in **every** target repo before writing code in any of them.
- Use the **same** `<branch-name>` in each.
- If creation succeeds in some repos and fails in others: **stop**, report which succeeded/failed, and do not start Task 1 until the set is consistent or the human narrows scope.
- Isolated worktrees (`using-git-worktrees`) are optional and complementary — they do not replace this branch step. If already inside a linked worktree on the correct feature branch for a target repo, treat that repo as done for branching.

## 5. Hard stops

- Never implement on `main` / `master` / the default branch.
- Never create a branch in a repo outside the resolved target set.
- Never invent a second repo "just in case".
