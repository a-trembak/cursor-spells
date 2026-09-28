---
name: plain-language-chat
description: >-
  Use when writing any chat message, review report, status update, Decision or
  Blocker option, recommendation, or question to the human. Use when tempted to
  write PR, CI, HITL, AC, SHA, P0, MCP, TTL, JWT, or other shortened jargon.
  Use when tempted to dump noun-phrase stacks, slash-joined alternatives, or
  telegram-style bullets. Use after english-humanizer, which leaves
  abbreviations in place. Use when the human asked for a full description
  without shortening.
---

# Plain language in chat

User-facing chat uses **full words** and **full sentences**. No abbreviations. Short grammatical sentences are fine. Shortened terms and fragment stacks are not.

**Violating the letter of this rule is violating the spirit of this rule.**

## When to Use

- Every message the human will read in Cursor chat
- Review reports, plan notes, and status shown in chat
- Decision-tier / Blocker options, recommendations, and proposal lists
- After `english-humanizer` (that skill does not expand abbreviations)

Not for: identifiers inside backticks or code fences.

## Output contract

Write the complete phrase the first time and every time. Do not introduce a short form in parentheses. If the human used a short form in this turn, you may echo it once, then keep using the full phrase.

When the human writes Ukrainian, reply in Ukrainian. Prefer the Ukrainian phrasing in the table. Never use Latin letter clumps.

Every user-facing option, recommendation, status bullet, and ask must be a **full sentence** (who/what + verb + what it means for the human). "Short sentences are fine" means grammatical sentences — **not** noun-phrase stacks.

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

## Proposal / Decision / status shape

Expanding abbreviations alone is not enough. A pile of full words with no grammar is still unreadable.

**Required shape for each option or proposal bullet:**

1. Name the decision in plain words (what we are choosing).
2. Say what this option **does** in one short sentence.
3. Say what you **gain or give up** in one short sentence (trade-off).
4. Keep attribute names and hostnames in backticks when needed (`SameSite`, `.energysave.se`).

**Banned shapes:**

- Noun-phrase stacks with no verb
- Alternatives joined only by `;` / `+` / `/` / bare em dashes
- Labels that only an insider on this repo could decode
- Mixing three decisions into one compressed line

**Self-check before send:** Could someone who does not work in this repository understand the choice without opening other messages?

### Before / after (proposal shape)

**Before (forbidden):**

```
повний перелік хостів (або правило генерації allowlist з конфігів white-label);
SameSite (Lax vs None) під same-site cross-origin;
cookie-on-API + захист від підробки міжсайтових запитів чи окремий бекенд-для-фронту / same-origin проксі;
хто / де репо конфігуратора й одноразовий handoff;
Domain cookie: host-only на API чи .energysave.se.
```

**After (required):**

```
Потрібно вирішити, як браузерні файли cookie мають працювати між маркетинговими сайтами та сервером програмного інтерфейсу.

Варіант A — cookie лише на хості програмного інтерфейсу.
Браузер зберігає сесію тільки на хості програмного інтерфейсу. Це простіше, але маркетингові сайти на інших доменах не побачать цю cookie безпосередньо.

Варіант B — cookie на спільному батьківському домені `.energysave.se`.
Усі сайти під цим доменом можуть бачити сесію. Це зручніше для входу, але розширює поверхню витоку, якщо якийсь піддомен скомпрометовано.

Варіант C — окремий бекенд-для-фронту на тому ж походженні, що й сторінка.
Сторінка говорить лише зі своїм проксі; захист від підробки міжсайтових запитів спрощується. Це більше роботи з інфраструктури.

Рекомендація: варіант C, якщо білі мітки вже мають проксі; інакше варіант A плюс явний перелік дозволених хостів із конфігів білих міток.
```

English Decision asks use the same sentence shape (subject + verb + trade-off), not telegram fragments.

## Keep exact (inside backticks or fences)

File paths, symbol names, error strings, ticket keys (`ACP-2656`), URLs, slash-command names (`/csp-start-task`), CLI flags.

## Before / after (abbreviations)

**Before:** CI впав на PR після HITL. SHA `abc1234`, це P0.

**After:** Безперервна інтеграція впала на запиті на злиття після кроку, де потрібна відповідь людини. Хеш коміту `abc1234`. Це найвища серйозність.

## Red flags — rewrite before send

- A run of capital letters used as a word (PR, HITL, AC, SHA, MCP)
- Severity spoken only as `P0`
- “Humanizer already ran” used as a reason to keep jargon
- First-use expansion then switching back to the short form
- Bullet or option label with no verb
- Alternatives glued with only `;` / `+` / `/`
- “one-line trade-off” used as a reason to drop grammar

| Excuse | Reality |
|--------|---------|
| "Engineers know PR" | This chat is for the human who asked for full words. |
| "english-humanizer wants short" | Short sentences, full terms. Humanizer does not override this. |
| "I'll expand on first use only" | Expand every time. |
| "Saving tokens" | Unreadable chat wastes more than a few extra words. |
| "question-discipline said one-line trade-off" | One or two short **sentences** of trade-off — not a fragment stack. |
| "Labels may be short" | Brief is fine; fragment stacks are not. |
