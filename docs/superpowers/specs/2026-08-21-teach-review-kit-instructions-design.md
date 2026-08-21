# Teach-review: publish generalized misses into kit instructions

## Status

`draft` — brainstorm validated in chat; this file is the implementation target after human review of the written spec.

## Goal

When a human catches a miss that `engineer-reviewer` (or a later remark) should have caught, turn that remark into **durable kit instructions** — checklists, skills, or agents — and land the change on the `cursor-spells` GitHub repository so every consumer project picks it up after the branch is merged to `main` and the kit checkout is updated.

This is not a per-repo memory file. The artifact is the same instruction set the reviewer already follows.

## Problem

Today `review-learn` generalizes misses into `<project>/.cursor/review-learnings.md` (easy to write, invisible to other projects) or proposes kit promotion (hard to write: default `consumer_only`, never auto-edit kit checklists from a leaf app). The human’s actual request is the opposite of that default: **patch the reviewer’s instructions in the kit and send them to the kit remote.**

## Decisions

| Decision | Choice |
|----------|--------|
| Mechanism | New skill `teach-review` (not an extension of `review-learn` capture) |
| Entries | Slash command `/teach-review` **and** a mandatory post-report gate on every settled `engineer-review` / `pr-review` |
| Post-review gate | Always ask `miss` / `no_miss`. `no_miss` writes nothing |
| Routing | Skill chooses the kit file (existing phase/checklist/skill first; new skill/agent last) |
| New files | Allowed: new checklist, new skill, new agent; wire **always-on** into the review spine |
| Land modes | `auto_push` or `draft_merge`. Default `draft_merge` |
| Config layers | User-global **and** consumer-project. Project wins when it sets `land` |
| Config files | `csp install` / `csp update` create them with defaults if missing; never overwrite |
| `auto_push` | Branch `learn/…` + `git push` only (no pull request) |
| `draft_merge` | Same branch shape + **draft** pull request into kit `main` |
| Local checkout | **Remote only** — do not merge/switch the kit checkout. Next review stays on old instructions until the human merges `learn/…` into `main` and updates the checkout |
| Consumer ledger | Out of scope for this loop. `review-learn` + `.cursor/review-learnings.md` stay as they are |

## Non-goals

- Replacing `review-learn` `mode:load` / `mode:capture` or deleting consumer ledgers.
- Auto-merging to `main` (neither land mode merges).
- Updating the local kit `main` checkout after push.
- Writing instructions into the consumer application repository.
- Inventing a miss class from an empty description.
- Teaching pipeline stages other than engineer/PR review in v1 (`tech-spec`, critic, `software-developer`).
- `confirm_then_push` as a third land mode (human already chose only `auto_push` / `draft_merge`).

## Config

### Paths

| Layer | Path |
|-------|------|
| Kit template | `skills/teach-review/references/cursor-spells-learn.json` |
| User-global | `~/.cursor/cursor-spells-learn.json` |
| Consumer project | `<project>/.cursor/cursor-spells-learn.json` |

### Schema

```json
{
  "land": "draft_merge"
}
```

`land` is exactly `auto_push` or `draft_merge`. Unknown keys are ignored. Unknown or empty `land` → treat as `draft_merge` and tell the human once.

### Install

`csp install` and `csp update` copy the kit template **only when the destination is missing** (same create-once idea as `check-project-patterns.sh`, not a refresh like hooks). Existing files are left untouched so a human `auto_push` is never reset.

| Mode | Writes if missing |
|------|-------------------|
| Always (including `--user-only`) | `~/.cursor/cursor-spells-learn.json` |
| Project targeted | also `<project>/.cursor/cursor-spells-learn.json` |

Both copies start as `{ "land": "draft_merge" }`. A project file with `land` set pins that project (project wins). To inherit the user-global file later, delete the project file or remove its `land` key. Missing files at runtime still resolve as `draft_merge` (skill must not crash if someone deleted them).

### Resolution (project wins)

1. If `<project>/.cursor/cursor-spells-learn.json` exists and `land` is `auto_push` or `draft_merge` → use it.
2. Else if `~/.cursor/cursor-spells-learn.json` has a valid `land` → use it.
3. Else `draft_merge`.

A project file with invalid `land` does **not** fall through to the user file: warn and use `draft_merge` (safer default). Only a **missing** project `land` key (or missing project file) falls through to the user file.

## Components

| Piece | Role |
|-------|------|
| Skill `teach-review` | Generalize, route, edit the kit checkout, commit, land |
| Command `/teach-review` | Same chain; optional miss description as the argument |
| HITL **Teach-review miss** | After a validated review report: `miss` / `no_miss` |
| Git lander (inside the skill) | `learn/…` branch, push, optional draft pull request |
| Existing review spine | Gains always-on dispatch rows when `teach-review` creates a new phase agent |

`engineer-reviewer` and `pr-reviewer` **must not** edit kit git themselves. They collect the miss text (or skip) and invoke `teach-review`.

## Data flow

```
settled review report
  → HITL miss / no_miss
       no_miss → stop (report already shown)
       miss    → require free-text description → teach-review
/teach-review [description]
  → if no description, ask open-ended (not a closed-set gate)
  → teach-review

teach-review:
  generalize → refuse if not generalizable
  route → existing file or new skill/agent + spine wiring
  resolve kit checkout → branch from origin/main → commit
  resolve land config → push; draft pull request if draft_merge
  tell human: class, files, branch, pull request URL if any,
              reminder that main is unchanged until they merge
```

One miss class per invocation. If the human describes two classes, take the primary and say the rest can be a second `/teach-review`.

## Generalize

Reuse the quality bar from `review-learn-protocol.md` (do not copy product names, ticket ids, one-off widgets). Output:

- `miss_class` kebab id (e.g. `vague-function-names`)
- `rule` — the check the phase must run (imperative, file-agnostic)
- `anti_pattern` — what the reviewer did instead
- `target_kind` — `checklist` / `phase_agent` / `skill` / `new_skill_agent`
- `target_path` — kit-relative path(s) to edit or create
- `spine_wiring` — which orchestrator files must list a new agent (`engineer-reviewer`, `pr-reviewer`, `engineer-review` skill, `skill-map.md` as needed)

Refuse and ask for a check-shaped class when the only content is a ticket, a widget name, or “the file at path X” with no transferable rule.

If an existing kit checklist or phase already covers the class, **extend that file** (fill the hole). Do not create a parallel skill. Do not no-op as “already exists” unless the exact check is already written; a miss that happened is evidence the existing text was too weak or unenforced.

## Route (agent chooses)

Preference order:

1. Existing checklist under `skills/engineer-review/references/` (or the phase’s own skill body) that owns this concern — append a gate the phase already loads **every** run.
2. Existing phase agent (`review-patterns`, `review-logic`, `review-deadcode`, `review-simplify`, `code-comments` taxonomy, etc.).
3. New checklist file in `references/` plus an always-on load line in the phase that should own it.
4. Last resort: new `skills/<name>/SKILL.md` + `agents/<name>.md`, then always-on dispatch in **both** `engineer-reviewer` and `pr-reviewer` (same phase set), plus `skills/engineer-review/SKILL.md` / `skill-map.md` / README tables so `csp install` / `csp update` links them like every other agent.

New agents run on **every** review after the change exists on the checkout the consumer is linked to. Do not hide them behind `review-learn` trigger matching.

Never write outside the kit checkout.

## Kit checkout and git

### Locate

Same as other kit helpers: `<project>/.cursor/cursor-spells-kit-path`, else `~/.cursor/cursor-spells-kit-path`. The path must be an existing git work tree whose remote is the kit (presence of `skills/engineer-review` + `agents/engineer-reviewer.md` is enough). If missing or not the kit → stop with install hint (`csp install` / kit clone).

### Cleanliness

If the kit work tree has uncommitted changes, **stop**. Do not stash-mix a teach commit with unrelated kit edits. Tell the human to commit or stash in the kit checkout first.

### Branch

1. `git fetch origin main` in the kit checkout.
2. Create `learn/<miss_class>-<YYYYMMDD>` from `origin/main` (not from a dirty or divergent local `HEAD`).
3. If that branch name exists locally or on `origin`, append `-2`, `-3`, … Do not force-push; do not silently reset a branch that already has commits.

### Commit

Commit **only** instruction files in the kit (skill/agent/checklist/spine/README as needed). Message matches kit conventional commits, e.g. `feat(review): teach <miss_class>`. English commit subject; no secrets.

### Land

| `land` | GitHub |
|--------|--------|
| `auto_push` | `git push -u origin learn/…` only. No pull request. |
| `draft_merge` | Same push, then a **draft** pull request into `main` of the kit remote. Never merge. Never mark ready. |

Do not `git checkout main`, do not merge `learn/…` into the local checkout, do not run `csp update` as a side effect.

If push or pull-request creation fails: report the error and the local branch name. Leave the local kit branch in place. Do not claim success.

## HITL

Add preset **Teach-review miss** to `hitl-choice`:

| id | label |
|----|-------|
| `miss` | The review missed something I will describe |
| `no_miss` | Nothing to teach; stop |

Ask **after** the validated report is shown, on:

- pipeline `engineer-reviewer` (after `/finish-plan` / `/start-task` / `/start-issue-task` / `--fast`)
- manual `/engineer-review`
- `/pr-review` (same phase set)

`no_miss` → do not invoke `teach-review`. `miss` → if the same message does not already contain the description, wait for free text (open-ended; not a second closed-set), then invoke.

Closed-set still uses `hitl-choice` (AskQuestion first). `/teach-review` with a non-empty argument skips the `miss` / `no_miss` gate (the command **is** the miss).

Failure of `teach-review` after a report must **not** retract the report. Say that kit instructions were not updated and that `/teach-review` can retry.

## Human-visible result

Always include:

- Generalized `miss_class` and the rule one-liner
- Kit-relative paths changed
- Branch name
- Pull request URL when `draft_merge` succeeded
- Explicit sentence: reviews keep the old instructions until `learn/…` is merged to `main` and this machine’s kit checkout points at that `main`

## Errors (hard stop)

| Condition | Action |
|-----------|--------|
| No kit path / not a kit git checkout | Stop; how to install |
| Empty miss description | Stop; do not invent |
| Not generalizable | Stop; ask for a transferable check |
| Target path outside kit | Stop |
| Dirty kit work tree | Stop; do not mix commits |
| Invalid `land` in the **project** file | Warn; `draft_merge` |
| Push / draft pull request failed | Report; keep local `learn/…` |

## Tests (implementation)

Shell tests against a temp git repo pretending to be the kit (same pattern as `scripts/tests/pipeline-gates-test.sh`):

- Config: missing / user only / project only / both (project wins) / garbage `land` → `draft_merge`
- Install: missing destinations get the template; a second run must not overwrite `auto_push`
- Generalize fixture: “rename `getData` in service X” → rule with no product/service name
- Refuse fixture: “ticket ACP-1” with no class
- Route fixture: naming miss prefers patterns/comments, not a new agent
- Land fixture: `learn/` branch created; `draft_merge` attempts pull-request create (stub); `auto_push` does not
- Review spine: after a fake settled report the next closed-set is `miss` / `no_miss`; `no_miss` does not touch git

## Files to add or change (implementation)

| Path | Change |
|------|--------|
| `skills/teach-review/SKILL.md` | New skill |
| `commands/teach-review.md` | Slash command |
| `skills/hitl-choice/SKILL.md` | Preset **Teach-review miss** |
| `agents/engineer-reviewer.md`, `skills/engineer-review/SKILL.md` | After validated report, always the miss gate; never edit kit git here |
| `agents/pr-reviewer.md`, `skills/pr-review/SKILL.md` | Same miss gate |
| `README.md`, `docs/superpowers/pipeline-flow.md` (+ html if the post-review node needs a label) | Document command + gate |
| `skills/teach-review/references/cursor-spells-learn.json` | Default template `{ "land": "draft_merge" }` |
| `scripts/install-to-project.sh`, `README.md` install tables | Create-once user + project config copies |
| `scripts/` helper + `scripts/tests/…` | Config resolve + branch name + land-mode tests; install create-once |
| Dogfood checklist (engineer-review) | One row: post-report miss gate; `no_miss` skips git |

Runtime edits when teaching a **new** phase (produced by the skill, not by this spec PR): new `skills/` + `agents/` + spine rows + README tables.

## Relationship to `review-learn`

Orthogonal. Production escapes and consumer-ledger capture stay on `/capture-escape` and `review-learn`. Skill `teach-review` (this spec) is the path that edits kit instructions and lands on the kit remote. Do not auto-run both on the same miss unless the human invoked both.

The old HITL **Review-learn promote** (`consumer_only` / `promote` / `skip`) is unchanged for the ledger path.

## Success

A human can remark “the reviewer allowed a meaningless function name”, the kit gains a generalized naming check in the right phase (or a new always-on agent if nothing fits), a `learn/…` branch exists on the kit remote (and a draft pull request when configured), and no consumer app repository is modified. After the human merges to `main` and updates the kit checkout, later reviews in **all** linked projects load that check.
