# Agent notes

## Chat with the human

Load skill `plain-language-chat` before any user-facing message. Write full words. Never use abbreviations, acronyms, or clipped jargon in chat. Skill `english-humanizer` does not satisfy this — it removes AI filler and still leaves shortened terms.

Keep exact only inside backticks or code fences: paths, symbols, error strings, ticket keys, URLs, slash-command names.

## Product code in this harness

Never write or patch product code in the parent chat. Dispatch nested Task `csp-software-developer` for features, plan tasks, review-gate fixes, and `/csp-start-task --fast`. Dispatch nested Task `csp-bug-fixer` for ticket bugs and `/csp-start-issue-task`. Wait for the Task to return.

For ad-hoc “write/fix code in chat” with no cleared plan or spec, ask once via **Pipeline route**: `full` / `fast` / `issue` (same tokens the kit already uses). Then dispatch `csp-software-developer` on the full path, `csp-software-developer` with explicit `mode:fast`, or `csp-bug-fixer` / `/csp-start-issue-task`. Do not auto-select `fast`. If write vs fix is still unclear, ask once.

Nested Task `csp-software-developer`, `csp-bug-fixer`, and engineer-review phase agents that apply eligible auto-fixes are the intended code writers and are not restricted by this rule.

Always-on rule: `code-via-coding-agents`.
