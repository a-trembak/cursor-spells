# Teach-review: publish generalized misses into kit instructions

## Status

`approved` — implementation target for cursor-spells kit (human approved the written spec). Plan: [`2026-08-21-teach-review-kit-instructions.md`](../plans/2026-08-21-teach-review-kit-instructions.md).

## Goal

When a human catches a miss that `csp-engineer-reviewer` (or a later remark) should have caught, turn that remark into **durable kit instructions** — checklists, skills, or agents — and land the change on the `cursor-spells` GitHub repository so every consumer project picks it up after the branch is merged to `main` and the kit checkout is updated.

This is not a per-repo memory file. The artifact is the same instruction set the reviewer already follows.

## Problem

Today `csp-review-learn` generalizes misses into `<project>/.cursor/review-learnings.md` (easy to write, invisible to other projects) or proposes kit promotion (hard to write: default `consumer_only`, never auto-edit kit checklists from a leaf app). The human’s actual request is the opposite of that default: **patch the reviewer’s instructions in the kit and send them to the kit remote.**

## Decisions

| Decision | Choice |
|----------|--------|
| Mechanism | New skill `teach-review` (not an extension of `csp-review-learn` capture) |
| Entries | Slash command `/csp-teach-review` **and** a mandatory post-report gate on every settled `engineer-review` / `pr-review` |
| Post-review gate | Always ask `miss` / `no_miss`. `no_miss` writes nothing |
| Routing | Skill chooses the kit file (existing phase/checklist/skill first; new skill/agent last) |
| New files | Allowed: new checklist, new skill, new agent; wire **always-on** into the review spine |
| Land modes | `auto_push` or `draft_merge`. Default `draft_merge` |
| Config layers | User-global **and** consumer-project. Project wins when it sets `land` |
| Config files | `csp install` / `csp update` create them with defaults if missing; never overwrite |
| Config comments | Installed file has `//` notes above `land`: purpose + every legal value |
| `auto_push` | Branch `learn/…` + `git push` only (no pull request) |
| `draft_merge` | Same branch shape + **ready-for-review** (mergeable) pull request into kit `main` |
| Local checkout | **Remote only** — do not merge/switch the kit checkout. Next review stays on old instructions until the human merges `learn/…` into `main` and updates the checkout |
| Consumer ledger | Out of scope for this loop’s kit git. Routing of local vs kit stores: [`2026-08-21-review-learn-project-secret-design.md`](2026-08-21-review-learn-project-secret-design.md) |

## Non-goals

- Deleting consumer ledgers or `csp-review-learn` `mode:load`. Capture eligibility is narrowed in [`2026-08-21-review-learn-project-secret-design.md`](2026-08-21-review-learn-project-secret-design.md).
- Auto-merging to `main` (neither land mode merges).
- Updating the local kit `main` checkout after push.
- Writing instructions into the consumer application repository.
- Inventing a miss class from an empty description.
- Teaching pipeline stages other than engineer/PR review in v1 (`tech-spec`, critic, `software-developer`).
- `confirm_then_push` as a third land mode (human already chose only `auto_push` / `draft_merge`).

## Rejected alternatives

- Draft pull request on `draft_merge` — rejected: a draft cannot be merged until marked ready; the kit needs a mergeable pull request after teaching.

## Config

### Paths

| Layer | Path |
|-------|------|
| Kit template | `skills/teach-review/references/cursor-spells-learn.json` |
| User-global | `~/.cursor/cursor-spells-learn.json` |
| Consumer project | `<project>/.cursor/cursor-spells-learn.json` |

### Settings (v1 catalog)

v1 has **one** key. Unknown keys are ignored. Do not invent extra keys at install time.

#### `land`

**What it does.** Chooses how `teach-review` sends a kit-instruction commit to the `cursor-spells` GitHub remote. It does **not** choose which instruction file to edit, does **not** merge to `main`, and does **not** update the local kit checkout.

| Value | Default? | What happens |
|-------|----------|----------------|
| `draft_merge` | **yes** | Create `learn/…` from `origin/main`, commit, `git push`, open a **ready-for-review** (mergeable) pull request into kit `main`. Never merge. Local checkout stays on whatever branch it was. |
| `auto_push` | no | Same branch + commit + `git push`. **No** pull request. Local checkout still unchanged. Reviews keep old instructions until a human merges `learn/…` into `main` and updates the checkout. |

No other values. Empty, missing, or garbage → behave as `draft_merge` and tell the human once.

### Template (comments live in the file)

Install copies this exact body when the destination is missing. Comments stay in the human-edited file so the variants are visible **above** the key. Runtime strips `//` lines before parse (JSONC).

```jsonc
{
  // land — how teach-review sends the new kit instructions to GitHub.
  // Does not merge to main. Does not switch or update this machine's kit checkout.
  //
  // Variants (pick exactly one string):
  //   "draft_merge"  (default) Push branch learn/<class>-<date> and open a
  //                  ready-for-review (mergeable) pull request into main.
  //                  You merge when you want the rule live.
  //   "auto_push"    Push the same learn/ branch only. No pull request.
  "land": "draft_merge"
}
```

### Install

`csp install` and `csp update` copy the kit template **only when the destination is missing** (same create-once idea as `check-project-patterns.sh`, not a refresh like hooks). Existing files are left untouched so a human `auto_push` (and their comments) are never reset.

| Mode | Writes if missing |
|------|-------------------|
| Always (including `--user-only`) | `~/.cursor/cursor-spells-learn.json` |
| Project targeted | also `<project>/.cursor/cursor-spells-learn.json` |

Both copies start with `land: draft_merge` and the comment block above. A project file with `land` set pins that project (project wins). To inherit the user-global file later, delete the project file or remove its `land` key. Missing files at runtime still resolve as `draft_merge` (skill must not crash if someone deleted them).

### Resolution (project wins)

1. If `<project>/.cursor/cursor-spells-learn.json` exists and `land` is `auto_push` or `draft_merge` → use it.
2. Else if `~/.cursor/cursor-spells-learn.json` has a valid `land` → use it.
3. Else `draft_merge`.

A project file with invalid `land` does **not** fall through to the user file: warn and use `draft_merge` (safer default). Only a **missing** project `land` key (or missing project file) falls through to the user file.

## Components

| Piece | Role |
|-------|------|
| Skill `teach-review` | Generalize, route, edit the kit checkout, commit, land |
| Command `/csp-teach-review` | Same chain; optional miss description as the argument |
| HITL **Teach-review miss** | After a validated review report: `miss` / `no_miss` |
| Git lander (inside the skill) | `learn/…` branch, push, optional ready-for-review pull request |
| Existing review spine | Gains always-on dispatch rows when `teach-review` creates a new phase agent |

`csp-engineer-reviewer` and `csp-pr-reviewer` **must not** edit kit git themselves. They collect the miss text (or skip) and invoke `teach-review`.

## Data flow

```
settled review report
  → HITL miss / no_miss
       no_miss → stop (report already shown)
       miss    → require free-text description → teach-review
/csp-teach-review [description]
  → if no description, ask open-ended (not a closed-set gate)
  → teach-review

teach-review:
  generalize → refuse if not generalizable
  route → existing file or new skill/agent + spine wiring
  resolve kit checkout → branch from origin/main → commit
  resolve land config → push; ready-for-review pull request if draft_merge
  tell human: class, files, branch, pull request URL if any,
              reminder that main is unchanged until they merge
```

One miss class per invocation. If the human describes two classes, take the primary and say the rest can be a second `/csp-teach-review`.

## Generalize

Reuse the quality bar from `review-learn-protocol.md` (do not copy product names, ticket ids, one-off widgets). Output:

- `miss_class` kebab id (e.g. `vague-function-names`)
- `rule` — the check the phase must run (imperative, file-agnostic)
- `anti_pattern` — what the reviewer did instead
- `target_kind` — `checklist` / `phase_agent` / `skill` / `new_skill_agent`
- `target_path` — kit-relative path(s) to edit or create
- `spine_wiring` — which orchestrator files must list a new agent (`csp-engineer-reviewer`, `csp-pr-reviewer`, `engineer-review` skill, `skill-map.md` as needed)

Refuse and ask for a check-shaped class when the only content is a ticket, a widget name, or “the file at path X” with no transferable rule.

If an existing kit checklist or phase already covers the class, **extend that file** (fill the hole). Do not create a parallel skill. Do not no-op as “already exists” unless the exact check is already written; a miss that happened is evidence the existing text was too weak or unenforced.

## Route (agent chooses)

Preference order:

1. Existing checklist under `skills/engineer-review/references/` (or the phase’s own skill body) that owns this concern — append a gate the phase already loads **every** run.
2. Existing phase agent (`csp-review-patterns`, `csp-review-logic`, `csp-review-deadcode`, `csp-review-simplify`, `code-comments` taxonomy, etc.).
3. New checklist file in `references/` plus an always-on load line in the phase that should own it.
4. Last resort: new `skills/<name>/SKILL.md` + `agents/<name>.md`, then always-on dispatch in **both** `csp-engineer-reviewer` and `csp-pr-reviewer` (same phase set), plus `skills/engineer-review/SKILL.md` / `skill-map.md` / README tables so `csp install` / `csp update` links them like every other agent.

New agents run on **every** review after the change exists on the checkout the consumer is linked to. Do not hide them behind `csp-review-learn` trigger matching.

Never write outside the kit checkout.

## Kit checkout and git

### Locate

Same as other kit helpers: `<project>/.cursor/cursor-spells-kit-path`, else `~/.cursor/cursor-spells-kit-path`. The path must be an existing git work tree whose remote is the kit (presence of `skills/engineer-review` + `agents/csp-engineer-reviewer.md` is enough). If missing or not the kit → stop with install hint (`csp install` / kit clone).

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
| `draft_merge` | Same push, then a **ready-for-review** (mergeable) pull request into `main` of the kit remote. Never merge. |

Do not `git checkout main`, do not merge `learn/…` into the local checkout, do not run `csp update` as a side effect.

If push or pull-request creation fails: report the error and the local branch name. Leave the local kit branch in place. Do not claim success.

## HITL

Add preset **Teach-review miss** to `hitl-choice`:

| id | label |
|----|-------|
| `miss` | The review missed something I will describe |
| `no_miss` | Nothing to teach; stop |

Ask **after** the validated report is shown, on:

- pipeline `csp-engineer-reviewer` (after `/csp-finish-plan` / `/csp-start-task` / `/csp-start-issue-task` / `--fast`)
- manual `/csp-engineer-review`
- `/csp-pr-review` (same phase set)

`no_miss` → do not invoke `teach-review`. `miss` → if the same message does not already contain the description, wait for free text (open-ended; not a second closed-set), then invoke.

Closed-set still uses `hitl-choice` (AskQuestion first). `/csp-teach-review` with a non-empty argument skips the `miss` / `no_miss` gate (the command **is** the miss).

Failure of `teach-review` after a report must **not** retract the report. Say that kit instructions were not updated and that `/csp-teach-review` can retry.

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
| Push / pull request failed | Report; keep local `learn/…` |

## Tests (implementation)

Shell tests against a temp git repo pretending to be the kit (same pattern as `scripts/tests/pipeline-gates-test.sh`):

- Config: missing / user only / project only / both (project wins) / garbage `land` → `draft_merge`
- Config comments: `//` lines above `land` do not break resolve
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
| `commands/csp-teach-review.md` | Slash command |
| `skills/hitl-choice/SKILL.md` | Preset **Teach-review miss** |
| `agents/csp-engineer-reviewer.md`, `skills/engineer-review/SKILL.md` | After validated report, always the miss gate; never edit kit git here |
| `agents/csp-pr-reviewer.md`, `skills/pr-review/SKILL.md` | Same miss gate |
| `README.md`, `docs/superpowers/pipeline-flow.md` (+ html if the post-review node needs a label) | Document command + gate |
| `skills/teach-review/references/cursor-spells-learn.json` | Default template with `land` comment catalog + `"draft_merge"` |
| `scripts/install-to-project.sh`, `README.md` install tables | Create-once user + project config copies |
| `scripts/` helper + `scripts/tests/…` | Config resolve + branch name + land-mode tests; install create-once |
| Dogfood checklist (engineer-review) | One row: post-report miss gate; `no_miss` skips git |

Runtime edits when teaching a **new** phase (produced by the skill, not by this spec PR): new `skills/` + `agents/` + spine rows + README tables.

## Relationship to `csp-review-learn`

Superseded for store routing by [`2026-08-21-review-learn-project-secret-design.md`](2026-08-21-review-learn-project-secret-design.md): shareable misses use this skill; `.cursor/review-learnings.md` only on `project_secret`. Do not run both stores on the same miss. Kit git / land rules in this spec still apply.

## Success

A human can remark “the reviewer allowed a meaningless function name”, the kit gains a generalized naming check in the right phase (or a new always-on agent if nothing fits), a `learn/…` branch exists on the kit remote (and a ready-for-review pull request when configured), and no consumer app repository is modified. After the human merges to `main` and updates the kit checkout, later reviews in **all** linked projects load that check.
