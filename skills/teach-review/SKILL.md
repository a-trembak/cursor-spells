---
name: teach-review
description: >-
  Turn a human remark about an engineer-review miss into generalized kit
  instructions (checklist, skill, or agent), commit on learn/…, and land on
  the cursor-spells remote. Use after Teach-review miss (miss) or /teach-review.
---

# Teach-review

You write **kit instructions**, not a consumer ledger. Do not edit the application repository. Do not invoke `review-learn` `mode:capture` as a substitute.

## When to Use

- Human chose `miss` after a validated `engineer-reviewer` / `pr-reviewer` report and pasted a description
- Slash command `/teach-review` (argument is the description)

## Inputs

- Miss description (required). Empty → stop; do not invent a class.
- Current consumer project root (cwd) for config + kit-path files
- Kit checkout path (read from `<project>/.cursor/cursor-spells-kit-path`, else `~/.cursor/cursor-spells-kit-path`)

## Steps

1. If the description is empty, ask open-ended for the miss (not a closed-set). Still empty → stop.
2. **Generalize** (One miss class per run). Strip product names, ticket ids, widgets. Produce:
   - `miss_class` kebab (example: `vague-function-names`)
   - `rule` — imperative check
   - `anti_pattern`
   - `target_kind`: `checklist` | `phase_agent` | `skill` | `new_skill_agent`
   - `target_path` kit-relative
   - `spine_wiring` if new agent
   Refuse when not generalizable — the only content is a ticket, a widget name, or a path with no transferable rule. Ask for a check-shaped class. Do not commit.
   If two classes are described, take the primary; tell the human to run `/teach-review` again for the rest.
3. **Route** (you choose the file). Preference:
   1. Existing checklist under `skills/engineer-review/references/` or the phase skill body — append a gate that phase already loads every run.
   2. Existing phase agent (`review-patterns`, `review-logic`, `review-deadcode`, `review-simplify`, `code-comments`, …).
   3. New checklist in `references/` plus an always-on load line in the owning phase.
   4. Last resort: new `skills/<name>/SKILL.md` + `agents/<name>.md`, always-on dispatch in **both** `engineer-reviewer` and `pr-reviewer`, plus `skills/engineer-review/SKILL.md`, `skill-map.md`, and README tables.
   If a checklist already covers the class but the miss still happened, **strengthen that file** — do not no-op and do not clone a parallel skill.
   Never write a path outside the kit checkout.
4. Resolve kit path, then source helpers (`"$KIT/scripts/teach-review.sh"`). Do not call `tr_kit_path` before sourcing.
   - Read `KIT` from `<project>/.cursor/cursor-spells-kit-path`, else `~/.cursor/cursor-spells-kit-path` (trim newline). Empty or missing → stop with `csp install` / clone hint.
   - `tr_is_kit_checkout "$KIT"` — fail → same stop
   - `tr_kit_is_dirty "$KIT"` — dirty → stop; do not stash-mix
   - `land="$(tr_resolve_land "$PWD")"`
5. In the kit only (primary checkout stays on its current branch — never `checkout -b` on `$KIT` itself):
   - `git -C "$KIT" fetch origin` (all heads, so remote `learn/…` names are visible)
   - `base="$(tr_learn_branch_base "$miss_class")"`
   - `branch="$(tr_unique_learn_branch "$KIT" "$base")"`
   - `TMP="$(mktemp -d)"`; `git -C "$KIT" worktree add "$TMP" -b "$branch" origin/main`
   - Apply instruction edits under `"$TMP"`; `git -C "$TMP" add` only those kit files
   - `git -C "$TMP" commit -m "feat(review): teach <miss_class>"` (English; no secrets)
6. **Land** (Do not merge; do not checkout `main` on `$KIT`; do not run `csp update`):
   - `git -C "$TMP" push -u origin "$branch"`
   - `repo="$(git -C "$KIT" remote get-url origin)"` — use for `gh --repo`
   - If `tr_land_opens_pr "$land"` (i.e. `draft_merge`):
     `gh pr create --draft --repo "$repo" --base main --head "$branch" --title "feat(review): teach <miss_class>" --body "<rule one-liner + file list>"`
   - `auto_push`: skip `gh pr create`
   - Push or `gh` failure: report error + branch name; do not claim success
   - Always: `git -C "$KIT" worktree remove "$TMP"` (even after failure, if the worktree was added)
7. Tell the human (full words in chat): `miss_class`, rule one-liner, kit-relative paths, branch name, pull request URL if `draft_merge` succeeded, and that reviews keep old instructions until `learn/…` is merged to `main` and this machine’s kit checkout points at that `main`.

## Hard rules

- Never edit consumer app files (including `.cursor/review-learnings.md`) in this loop.
- Never merge to `main`. Never mark the pull request ready.
- Never auto-edit kit checklists from `review-learn` promote; this skill is the kit-edit path.
- Failure after a review report must not retract the report; say `/teach-review` can retry.
