# Propose commit after engineer-review

## Status

`approved` — human chose `approve-spec` on the written design; implementation plan next.

## Goal

After plan (or fast/issue) substance is in the tree, **no product commit** happens until:

1. An **engineer-review** report for this run has settled, and
2. The **agent** has proposed the commit (message + file list), and
3. The **human** has answered that proposal with `approve-commit`.

Only then may `git commit` run. Push and draft pull request stay in `create-pr`.

## Problem

Today, `software-developer` / `csp-bug-fixer` leave work on a feature branch, and `create-pr` may **silently commit** remaining changes at the end of the pipeline. The human and engineer-reviewer never explicitly approve a commit proposal. Intermediate commits during implementation also bypass that gate.

## Decisions

| Decision | Choice |
|----------|--------|
| Commit gate timing | **After** engineer-review report is settled; **before** `update-docs` / `create-pr` as wired below |
| Commits during implement | **`no_commits_until_gate`** — zero `git commit` until the gate |
| Pipelines in scope | **All**: full `/csp-start-task`, `--fast`, and `/csp-start-issue-task` / `csp-bug-fixer` |
| Approval shape | **`human_only_after_both`** — commit only when a review report exists for this run **and** the human answers the agent proposal; no separate reviewer token |
| Approach | New skill **`propose-commit`** + gate marker; hard forbid commits in implementers; `create-pr` must not quietly commit ungated product changes |
| Docs on full path | First `propose-commit` (code + review auto-fixes) → `update-docs` → if docs left uncommitted files, a **second light** `propose-commit` for those files only → `create-pr` |
| Fast / issue | One `propose-commit` after engineer-review (docs as the route already defines) → `create-pr` |
| Push / draft PR | Unchanged ownership: **`create-pr`** only; `propose-commit` never pushes or opens a pull request |
| Diff visibility before any commit | Feature branch may have **zero commits ahead** of base. `SetActiveBranch` merge-base tab can be empty. **`finish-plan` / review-surface** (and fast/issue pre-review handoff) must still show the human the change set: at minimum paste or summarize `git status` + `git diff` (and per-repo maps) in chat; keep attempting `SetActiveBranch` for branch checkout. Do **not** create a placeholder commit to feed the tab |

## Pipeline placement (normative)

### Full path

1. Implement via `software-developer` (no commits).
2. `finish-plan` (review-surface + human `skip` / `approve` / `done` / `fixes`) — unchanged tokens.
3. Engineer-review (auto-fixes stay **uncommitted**).
4. When the report is settled → skill **`propose-commit`**.
5. `update-docs` (existing docs destination HITL).
6. If the work tree has uncommitted docs (or other intentional files from step 5) → **`propose-commit`** again (docs-only / residual scope).
7. `create-pr` (push + draft pull request + Pipeline finale). Requires `commit-approved` evidence for this run when commits were needed; must not invent a product commit without the skill.

### Fast and issue

1. Implement via `software-developer` `mode:fast` or `csp-bug-fixer` (no commits).
2. Engineer-review (no `finish-plan` HITL — unchanged).
3. **`propose-commit`**.
4. `create-pr` as today (after docs only if that route already inserts docs).

## Skill `propose-commit` (normative)

### When to use

- After engineer-review has produced a settled report for this pipeline run.
- Again on the full path after `update-docs` if uncommitted intentional files remain.
- Not from `finish-plan` review-surface.
- Not as a substitute for Pipeline finale.

### Preconditions

- Feature branch checked out in each target repo (not default branch).
- Engineer-review report for this run is settled (no blocking open clarifications that the pipeline treats as “not ready to continue”).
- `repo → branch` map (or resolvable current feature branch) present.

If a precondition fails: **stop** and say which one. Do not commit.

### Spine

1. Per changed repo: inspect `git status` / diff; stage **intentional** paths only (never `git add -A` / `git add .`).
2. Propose in chat: commit message (match repo conventional style) + file list.
3. HITL via skill **`hitl-choice`**: tokens `approve-commit` | `revise`.
   - `revise` → wait for message/file-list changes; re-propose; do not commit.
   - `approve-commit` → `git commit` in each repo that has staged changes.
4. Write marker: `.cursor/gates/commit-approved/<slug>` (plan path or run slug; same gating helpers as other pipeline gates when available).
5. Do **not** `git push`. Do **not** open or update a GitHub pull request.

### Multi-repo

Repeat propose + commit per changed repo in the map. One human gate may cover the whole proposal set for the run (single `approve-commit` applies to the listed repos/files), unless a repo has nothing to commit (skip that repo).

## Hard rules elsewhere

| Actor | Rule |
|-------|------|
| `software-developer` | Never `git commit` during pipeline implementation / verification handoff |
| `csp-bug-fixer` | Never `git commit` during pipeline fix work |
| Nested implementers / task agents under those skills | Same forbid |
| Engineer-review phase auto-fix | Allowed; leave changes uncommitted for `propose-commit` |
| `create-pr` | Must not silently commit ungated product changes. If product commits are still required and `commit-approved` is missing → stop and point at `propose-commit`. Push/draft/finale unchanged once commits exist |
| Default branch | No implementation commits on `main` / `master` / default (unchanged) |

## Artifacts (expected)

| Path | Role |
|------|------|
| `skills/propose-commit/SKILL.md` | Gate skill spine + hard rules |
| `skills/hitl-choice/SKILL.md` | Preset **Propose commit**: `approve-commit` / `revise` |
| `skills/software-developer/SKILL.md` | Explicit no-commit until gate |
| `skills/bug-fix/SKILL.md` (and/or `csp-bug-fixer` agent) | Explicit no-commit until gate |
| `skills/create-pr/SKILL.md` | Remove quiet product commit; require gate / already-committed tree |
| `skills/engineer-review/SKILL.md` + `update-docs` / `commands/csp-start-task.md` / `start-issue-task.md` | Wire `propose-commit` after settled review (and docs residual on full) |
| `scripts/tests/propose-commit-test.sh` (or equivalent) | Contract: skill exists, tokens, no-commit phrases, create-pr does not quiet-commit without gate |
| Gate dir | `.cursor/gates/commit-approved/<slug>` |

Exact file splits may be refined in the implementation plan; behavior above is normative.

## Out of scope

- Changing finish-plan HITL tokens (`skip` / `approve` / `done` / `fixes`)
- Changing Pipeline finale tokens or merge policy
- Force-push, `gh pr merge`, or auto-ready without human finale
- Requiring a separate engineer-reviewer approval token for the commit
- Building a new Cursor UI surface for uncommitted diffs (chat + existing checkout/`SetActiveBranch` only)
- Cloud Agent platform “always commit every turn” policy outside this kit (kit skills still forbid product commits until the gate when running kit pipelines)

## Success criteria

- On full / fast / issue kit pipelines, no product `git commit` occurs before a settled engineer-review report and human `approve-commit`.
- `propose-commit` shows message + files; `revise` loops without committing.
- After `approve-commit`, commits exist only on the feature branch; push/draft still happen only in `create-pr`.
- `create-pr` does not invent an ungated product commit.
- Contract test covers the skill, HITL tokens, implementer forbids, and create-pr guard.
