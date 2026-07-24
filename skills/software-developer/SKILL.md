---
name: software-developer
description: >-
  Use when an approved tech spec and a critiqued-clear implementation plan are
  ready to turn into code. Routes stack/DB skills from skill-map, applies
  code-comments while writing, and verifies before handoff. On react-web UI
  work, compares the rendered result to Figma via ce-test-browser when URLs
  exist. Use from /start-task execution or when asked to implement a cleared plan.
---

# Software Developer

Writes code **strictly** to the tech spec + implementation plan. Skill routing is a mechanical lookup against `engineer-review`'s `skill-map.md` — never silent third-party installs.

## When to Use

- `/start-task` step 5 (execution) after `start-build` returns `Verdict: clear`
- Human asks to implement a plan that already passed the critic gate
- Not for drafting specs/plans, critiquing plans, or running engineer-review

## Entry conditions (all required)

1. Tech spec `Status` is `approved`, or explicitly `skip (<reason>)` with the reason logged
2. Implementation plan exists (from `writing-plans`)
3. `implementation-critic` has no open Must-fix findings (or each is explicitly `accept`ed) — typically already enforced by `start-build`

If any condition fails: **stop** and say which gate is missing. Do not start coding.

## Skill routing

1. **Stack detection** — mechanical table lookup in `skills/engineer-review/references/skill-map.md` (same signals as engineer-review). Zero inventing of stack labels.
2. **Always-on for this run:**
   - matched stack skill(s) from the map
   - `code-comments` (this kit) while writing
   - `mattpocock/skills@tdd` when the task has observable behavior to test (if installed; else note `skill_missing: tdd` and still write tests with the project's conventions)
3. **Database-aware routing** — when the plan/task touches migrations/schema, load the matching rows from skill-map § Database skill routing
4. **Conditional** — only if the plan/spec touches that surface: performance / security / architecture skills from the map
5. **UI vs design (web):** when stack is `react-web` and the task changes user-visible UI:
   - If Figma node URLs are available (from the task/spec/clarifications): load Figma skills/MCP while implementing (`figma-use`, `figma-design-to-code` as available)
   - After the UI slice is runnable: follow **`ce-test-browser`** to open affected routes and compare the **rendered** UI to those Figma nodes
   - Missing skill / no browser / no URLs → continue coding; note `skill_missing: ce-test-browser`, `browser_review_unavailable`, or `awaiting_figma_urls` in the handoff — do not invent pixel diffs
6. **Before handoff:** run `verification-before-completion` (or the project's own lint/test/typecheck) — never claim done without evidence

Missing mapped skill → proceed on built-in checklist; report `skill_missing: <id>`. Never auto-install Tier-2 skills; follow skill-map's Skill resolution protocol (ask the human).

## Hard rules

- Do not expand scope beyond the plan's tasks
- Do not make "while I'm here" improvements outside scope
- Do not silently change the data model described in the tech spec
- If plan/spec conflicts with the repo: **stop and ask** — do not silently deviate from the spec
- Source-code comments: English only; apply `code-comments` Keep/Remove taxonomy

## Execution engine

Default: dispatch `subagent-driven-development` (fresh implementer + task reviewer per task) with the skill set for this run loaded into context. If the user already asked for a separate session, honor `executing-plans` instead.

## Handoff

When all plan tasks are done and verification evidence exists, hand off to `finish-plan` (do not skip the HITL review gate).
