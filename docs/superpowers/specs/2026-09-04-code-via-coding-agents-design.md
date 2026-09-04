# Code via coding agents (parent chat)

## Status

`approved` — human chose routing option 3 and approved design approach B (always-on rule + `AGENTS.md` + installer + contract test).

## Goal

When working in this harness chat, the **parent / orchestrator** never writes or patches **product** code itself. Product implementation and bug fixes always go through the nested coding agents already defined by the kit.

## Problem

Pipeline commands (`/start-task`, `/start-build`, `/start-issue-task`) already dispatch `software-developer` or `bug-fixer`. Ad-hoc “write / fix this in chat” requests still tempt the parent agent to edit product trees directly, skipping branch setup, skill-map routing, verification, and (for bugs) the debug evidence gate.

## Decisions

| Decision | Choice |
|----------|--------|
| Approach | Always-on Cursor rule + short `AGENTS.md` section + installer copy (same pattern as `plain-language-chat`) |
| Features / plan tasks / review-gate `fixes` / `--fast` | Nested Task **`software-developer`** (full entry gates or explicit `mode:fast`) |
| Ticket bugs / `/start-issue-task` | Nested Task **`bug-fixer`** / skill `bug-fix` |
| Ambiguous write vs fix | Ask the human; do not code in the parent |
| Parent may still | Orchestrate, read, review, edit kit docs/skills/rules, pipeline markers, and meta tooling — not product logic in a consumer repo |
| Kit self-edits | Allowed when the human asked to change this kit (`cursor-spells`) itself |
| Review-phase auto-fix | Unchanged — phase agents apply eligible fixes under engineer-review protocol; that is not parent ad-hoc product patching |
| Pipeline rewrites | **Out of scope** — `/start-task` and `/start-issue-task` already dispatch correctly; this rule closes the ad-hoc gap |

## Routing (normative)

1. If the human asks to implement a feature, apply an accepted plan task, apply review-gate `fixes`, or run `/start-task --fast` → dispatch **`software-developer`** and wait for it to return.
2. If the human asks to fix a bug from an issue path or `/start-issue-task` → dispatch **`bug-fixer`** and wait for it to return.
3. If both could apply → ask once which path; do not invent product diffs in the parent.
4. Violating “I’ll just patch it here for speed” in the parent is a **protocol bug**.

## Artifacts

| Path | Role |
|------|------|
| `rules/code-via-coding-agents.mdc` | `alwaysApply: true` — parent must dispatch coding agents |
| `AGENTS.md` | Short section pointing at the rule / agents |
| `scripts/install-to-project.sh` | Copy rule to `~/.cursor/rules/` and project `.cursor/rules/` (with `plain-language-chat`) |
| `scripts/tests/code-via-coding-agents-test.sh` | File presence, key phrases, installer drops |
| `README.md` | One row in the rules / install table |

## Out of scope

- Renaming `software-developer` to “software engineer”
- Merging `bug-fixer` into `software-developer`
- Changing critic gates, review-gate HITL tokens, or create-pr finale
- New skills beyond the always-on rule (approach C rejected)

## Success criteria

- A parent agent following kit rules does not open a product implementation edit without first dispatching `software-developer` or `bug-fixer` as appropriate.
- `csp install` / `csp update` refreshes the rule for user-global and project installs.
- Contract test passes in `scripts/tests/`.
