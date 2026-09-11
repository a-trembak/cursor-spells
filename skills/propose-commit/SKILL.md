---
name: propose-commit
description: >-
  Use after a settled engineer-review report in a kit pipeline (full, --fast,
  or issue) when product changes are still uncommitted. Proposes commit message
  and file list, HITL approve-commit / revise, then git commit only. Never push
  or open a pull request — create-pr owns that. Also use after update-docs when
  residual docs files remain uncommitted.
---

# Propose Commit

Human-gated product commit after engineer-review. Implements the design in
`docs/superpowers/specs/2026-09-08-propose-commit-after-review-design.md`.

## When to Use

- After engineer-review (or multi-repo-supervisor) has produced a **settled** report for this pipeline run
- Again on the full path after `update-docs` if intentional files remain uncommitted
- Not from `finish-plan` review-surface
- Not as a substitute for Pipeline finale
- Not for kit self-edits outside a consumer product pipeline unless the human is running this skill on purpose

## Preconditions

All required:

1. Each target repo is on the **feature branch** (not `main` / `master` / default).
2. An engineer-review report for **this run** is settled (no blocking open clarifications that the pipeline treats as not ready to continue).
3. `repo → branch` map from the handoff, or a resolvable current feature branch.
4. `plan_path` when known (implementation plan or issue fix plan). If the handoff has `plan_path: none` (fast brief only), use synthetic path `runs/<feature-branch-name>` as the plan path argument to gate helpers.

If any fail: **stop** and say which precondition is missing. Do not commit.

## Spine

1. For each `repo → branch` in the map (or the single current repo):
   - `git -C <repo> status` / `git diff` / `git diff --cached`
   - Build the intentional file list. **Never** `git add -A` or `git add .`.
2. Propose in chat (full words per `plain-language-chat`):
   - Commit message (match recent conventional style in that repo; default `fix:` when ambiguous for bug work, `feat:` only for new capability)
   - Per-repo file list to stage
3. HITL via skill **`hitl-choice`** (AskQuestion required; text only after failed/missing tool). Preset: **Propose commit**.
   - `revise` — wait for message and/or file-list changes; re-propose; do **not** commit.
   - `approve-commit` — continue.
4. On `approve-commit`, per repo with changes:
   - Stage **only** the human-approved paths for that repo (`git add -- <path>…`). If anything else is staged, `git restore --staged -- <extra-path>…` until the index matches the approved list.
   - **Pre-commit check:** `git diff --cached --name-only` (sorted) must match the approved file list (sorted) exactly. If it does not: **stop**, do **not** commit, re-propose the message and file list.
   - Confirm not on default branch before committing.
   - `git commit` with the approved message.
5. Write the gate in the **current project** (consumer root):

   ```bash
   KIT="$(tr -d '\n' < .cursor/cursor-spells-kit-path 2>/dev/null || true)"
   if [[ -z "$KIT" ]]; then
     KIT="$(tr -d '\n' < "$HOME/.cursor/cursor-spells-kit-path" 2>/dev/null || true)"
   fi
   source "$KIT/scripts/pipeline-gates.sh"
   pg_write_gate "$(pwd)" commit-approved "<plan-path-or-runs-branch>"
   ```

6. **Do not** `git push`. **Do not** open or update a GitHub pull request. Hand off to the caller (`update-docs` or `create-pr`).

## Multi-repo

One human gate may cover the whole proposal set for the run. Skip repos with a clean work tree. Do not push any repo.

## Hard rules

- Never commit without a settled engineer-review report for this run **and** `approve-commit`.
- Never push. Never `gh pr create` / `gh pr ready`. Never merge.
- Never commit on the default branch.
- Never `git add -A` / `git add .`.
- Nested implementers must not have already committed; if the branch is unexpectedly ahead with no `commit-approved` marker, stop and ask — do not invent history rewrites.

## Output

```
next_skill: update-docs | create-pr   # per caller wiring
plan_path: <path>
repo_branch_map:
  - <repo> → <branch>
commit_approved: true
```
