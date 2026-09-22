# Agent notes

## Chat with the human

Load skill `plain-language-chat` before any user-facing message. Write full words. Never use abbreviations, acronyms, or clipped jargon in chat. Skill `english-humanizer` does not satisfy this — it removes AI filler and still leaves shortened terms.

Keep exact only inside backticks or code fences: paths, symbols, error strings, ticket keys, URLs, slash-command names.

## This repository is the kit — no pipeline dogfood

This git root **is** cursor-spells (the kit), not a consumer product app.

**Never** develop this repository with its own product shipping pipeline:

- Do not run `/csp-start-task`, `/csp-start-task --fast`, or `/csp-start-issue-task` on this repo
- Do not ask **Pipeline route** (`full` / `fast` / `issue`) for kit changes
- Do not dispatch nested Task `csp-software-developer` or `csp-bug-fixer` to ship kit edits
- Edit kit files directly in the parent chat; use ordinary feature branches, commits, and draft pull requests
- Kit work may be ticketless unless the human explicitly asks for a Jira card

Manual checklists under `docs/superpowers/dogfood/` and harness / contract tests remain allowed — those are verification, not `/csp-start-*`.

Always-on rule: `kit-no-pipeline-dogfood` (`rules/kit-no-pipeline-dogfood.mdc`). Kit-only — not installed into consumer projects.

## Product code in consumer harnesses

When the workspace is a **consumer** project that installed this kit (not this kit checkout), the parent chat must not write or patch product code itself. Dispatch nested Task `csp-software-developer` for features, plan tasks, review-gate fixes, and `/csp-start-task --fast`. Dispatch nested Task `csp-bug-fixer` for ticket bugs and `/csp-start-issue-task`. Wait for the Task to return.

For ad-hoc “write/fix code in chat” in a **consumer** project with no cleared plan or spec, ask once via **Pipeline route**: `full` / `fast` / `issue`. Then dispatch accordingly. Do not auto-select `fast`. If write vs fix is still unclear, ask once.

Nested Task `csp-software-developer`, `csp-bug-fixer`, and engineer-review phase agents that apply eligible auto-fixes are the intended code writers in consumer projects and are not restricted by that rule.

Always-on rule for consumers: `code-via-coding-agents`.
