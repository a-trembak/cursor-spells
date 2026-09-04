# Agent notes

## Chat with the human

Load skill `plain-language-chat` before any user-facing message. Write full words. Never use abbreviations, acronyms, or clipped jargon in chat. Skill `english-humanizer` does not satisfy this — it removes AI filler and still leaves shortened terms.

Keep exact only inside backticks or code fences: paths, symbols, error strings, ticket keys, URLs, slash-command names.

## Product code in this harness

Never write or patch product code in the parent chat. Dispatch nested Task `software-developer` for features, plan tasks, review-gate fixes, and `/start-task --fast`. Dispatch nested Task `bug-fixer` for ticket bugs and `/start-issue-task`. Wait for the Task to return. If the path is unclear, ask once. Always-on rule: `code-via-coding-agents`.
