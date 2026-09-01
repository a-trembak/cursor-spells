---
name: software-developer
description: >-
  Use when an approved tech spec and a critiqued-clear implementation plan are
  ready to turn into code, or from /start-task --fast (mode:fast) with a short
  AC brief. Creates feature branch(es), routes stack/DB skills from skill-map,
  applies code-comments, and verifies before handoff. On react-web UI work,
  compares the rendered result to Figma via ce-test-browser when URLs exist.
---

# Software Developer

Writes code **strictly** to the tech spec + implementation plan (full path), or to the short AC brief in **`mode:fast`**. Skill routing is a mechanical lookup against `engineer-review`'s [`skill-map.md`](../engineer-review/references/skill-map.md) — never silent third-party installs.

## When to Use

- `/start-task` execution after `approve-plan` → clear critic → `start-build`
- `/start-task --fast` with `mode:fast` (no tech-spec / critique-clear required)
- Human asks to implement a plan that already passed `/approve-plan` (`Verdict: clear`)
- Not for bug-fix plans from `/start-issue-task` (use `bug-fix` / `bug-fixer`)
- Not for drafting specs/plans, critiquing plans, or running engineer-review

## Entry conditions

### Full path (default)

All required:

1. Tech spec `Status` is `approved`, or explicitly `skip (<reason>)` with the reason logged
2. Implementation plan exists (from `writing-plans`)
3. `implementation-critic` has no open Must-fix findings (or each is explicitly `accept`ed) — typically already enforced by `approve-plan` (HITL approve → auto critic → `.cursor/gates/plan-critique-clear/<slug>`) before `start-build`

If any condition fails: **stop** and say which gate is missing. Do not start coding.

### `mode:fast` (explicit)

When the caller passes **`mode:fast`** (only from `/start-task --fast` or an explicit human ask for the lean path):

1. AC source / short task brief is present in the conversation
2. Tech-spec Status, implementation-plan file, and `.cursor/gates/plan-critique-clear/<slug>` are **not** required
3. Scope is the AC brief only — do not invent a full tech-spec

If the brief is missing: stop and ask for AC. Do not silently enter `mode:fast` from the full path.

## Branch setup (mandatory, before any code)

Immediately after entry conditions pass, follow [references/branch-setup.md](references/branch-setup.md):

1. Resolve which git repo(s) the plan/spec will change (one or many).
2. Derive one shared feature branch name for this run.
3. Create and check out that branch in **each** target repo from its base (`main`/`master`/default). Call `SetActiveBranch` for each folder the human has open.
4. Do not start Task 1 until every target repo is on that branch (or the human narrowed the set).

Never implement on the default branch. Never invent repos the plan does not touch.

## Skill routing

1. **Stack detection** — mechanical table lookup in [`skill-map.md`](../engineer-review/references/skill-map.md) (same signals as engineer-review). Zero inventing of stack labels. Detect **per target repo** when the run spans multiple.
2. **Always-on for this run:**
   - matched stack skill(s) from the map
   - `code-comments` (this kit) while writing — including backend services: no comments tied to charts, screens, widgets, or Figma
   - `mattpocock/skills@tdd` when the task has observable behavior to test (if installed; else note `skill_missing: tdd` and still write tests with the project's conventions)
3. **Database-aware routing** — when the plan/task touches migrations/schema, load the matching rows from [Database skill routing](../engineer-review/references/skill-map.md#database-skill-routing)
4. **JPA Criteria** — when the task touches `Specification`, Criteria fetch/join/subquery code, or org-scoped alert/installation queries: load [jpa-criteria-patterns.md](references/jpa-criteria-patterns.md) and apply before handoff
5. **Conditional** — only if the plan/spec touches that surface: performance / security / architecture skills from the map
6. **UI vs design (web):** when stack is `react-web` and the task changes user-visible UI:
   - If Figma node URLs are available (from the task/spec/clarifications): load Figma skills/MCP while implementing (`figma-use`, `figma-design-to-code` as available)
   - After the UI slice is runnable: follow **`ce-test-browser`** to open affected routes and compare the **rendered** UI to those Figma nodes
   - Missing skill / no browser / no URLs → continue coding; note `skill_missing: ce-test-browser`, `browser_review_unavailable`, or `awaiting_figma_urls` in the handoff — do not invent pixel diffs
7. **Before handoff:** run `verification-before-completion` (or the project's own lint/test/typecheck) — never claim done without evidence

Missing mapped skill → proceed on built-in checklist; report `skill_missing: <id>`. Never auto-install Tier-2 skills; follow skill-map's Skill resolution protocol (ask the human).

## Hard rules

- Do not expand scope beyond the plan's tasks (full) or the AC brief (`mode:fast`)
- Do not make "while I'm here" improvements outside scope
- Do not silently change the data model described in the tech spec (full path)
- If plan/spec/brief conflicts with the repo: **stop and ask** — do not silently deviate
- Source-code comments: English only; apply `code-comments` Keep/Remove taxonomy
- **Every stack, including backend Java/Spring services:** never write comments that name a chart, screen, widget, or Figma node as the reason for a query, filter, or merge. Restate the data invariant, or omit. Independent of the react-web Figma check — backend work still follows this
- Do not write implementation commits on `main` / `master` / the default branch

## Execution engine

Default: dispatch `subagent-driven-development` (fresh implementer + task reviewer per task) with the skill set for this run loaded into context, **after** branch setup succeeds. If the user already asked for a separate session, honor `executing-plans` instead. In `mode:fast`, a single-pass implement + verify is acceptable when the change is tiny; still run verification before handoff.

## Handoff

Emit this block to the caller (required), then follow the nested-vs-parent rule:

```
next_skill: finish-plan          # full path
next_skill: engineer-reviewer    # mode:fast only
mode: full | fast
plan_path: <path or none>
repo_branch_map:
  - <repo> → <branch>
verification: <lint/test/typecheck evidence>
```

- **Full path `next_skill`:** `finish-plan` (do not skip the HITL review gate).
- **`mode:fast` `next_skill`:** `engineer-reviewer` then the caller runs `create-pr` — do **not** invoke `finish-plan`.

**nested Task** (dispatched by `start-build` / `/start-task` / `/start-task --fast`): after the block, **STOP** and return to the caller. Do **not** invoke `finish-plan`, `engineer-reviewer`, `AskQuestion`, or `hitl-choice` from the nested Task — the parent chat owns that continue.

**Parent chat** (user invoked `@software-developer` with no caller waiting): after the block, immediately invoke `next_skill` in this chat.
