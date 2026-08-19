---
name: plain-language-chat
description: >-
  Use when writing any chat message, review report, status update, or question
  to the human. Use when tempted to write PR, CI, HITL, AC, SHA, P0, MCP, TTL,
  JWT, or other shortened jargon. Use after english-humanizer, which leaves
  abbreviations in place. Use when the human asked for a full description
  without shortening.
---

# Plain language in chat

User-facing chat uses **full words**. No abbreviations. Short sentences are fine. Shortened terms are not.

**Violating the letter of this rule is violating the spirit of this rule.**

## When to Use

- Every message the human will read in Cursor chat
- Review reports, plan notes, and status shown in chat
- After `english-humanizer` (that skill does not expand abbreviations)

Not for: identifiers inside backticks or code fences.

## Output contract

Write the complete phrase the first time and every time. Do not introduce a short form in parentheses. If the human used a short form in this turn, you may echo it once, then keep using the full phrase.

When the human writes Ukrainian, reply in Ukrainian. Prefer the Ukrainian phrasing in the table. Never use Latin letter clumps.

## Expand these (not exhaustive)

| Forbidden in chat | Write instead |
|-------------------|---------------|
| PR | pull request / запит на злиття |
| CI / CD | continuous integration / continuous delivery |
| HITL | human-in-the-loop / крок, де потрібна відповідь людини |
| AC | acceptance criteria / критерії приймання |
| SHA | commit hash / хеш коміту |
| P0 / P1 / P2 | highest / high / medium severity |
| MCP | Model Context Protocol |
| TTL | time-to-live / час життя |
| JWT | JSON Web Token |
| WIP | work in progress / робота ще не завершена |
| LGTM | looks good to me |
| nits | minor remarks |
| PoC | proof of concept |
| LOC | lines of code |
| UI | user interface / інтерфейс |
| API | application programming interface (or name the concrete interface) |

Also expand clipped Ukrainian (`репозиторій` not `репо`, `коміт` is a loanword — keep it, do not invent `кмт`).

## Keep exact (inside backticks or fences)

File paths, symbol names, error strings, ticket keys (`ACP-2656`), URLs, slash-command names (`/start-task`), CLI flags.

## Before / after

**Before:** CI впав на PR після HITL. SHA `abc1234`, це P0.

**After:** Безперервна інтеграція впала на запиті на злиття після кроку, де потрібна відповідь людини. Хеш коміту `abc1234`. Це найвища серйозність.

## Red flags — rewrite before send

- A run of capital letters used as a word (PR, HITL, AC, SHA, MCP)
- Severity spoken only as `P0`
- “Humanizer already ran” used as a reason to keep jargon
- First-use expansion then switching back to the short form

| Excuse | Reality |
|--------|---------|
| "Engineers know PR" | This chat is for the human who asked for full words. |
| "english-humanizer wants short" | Short sentences, full terms. Humanizer does not override this. |
| "I'll expand on first use only" | Expand every time. |
| "Saving tokens" | Unreadable chat wastes more than a few extra words. |
