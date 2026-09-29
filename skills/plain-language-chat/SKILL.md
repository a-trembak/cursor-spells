---
name: plain-language-chat
description: >-
  Use when writing any chat message, review report, status update, Decision or
  Blocker option, recommendation, or question to the human. Use when tempted to
  write PR, CI, HITL, AC, SHA, P0, MCP, TTL, JWT, or other shortened jargon.
  Use when tempted to dump noun-phrase stacks, slash-joined alternatives, or
  telegram-style bullets. Use after english-humanizer, which leaves
  abbreviations in place. Use when the human asked for a full description
  without shortening. Use when choosing or applying the pipeline chat language.
---

# Plain language in chat

User-facing chat uses **full words** and **full sentences** in the **selected pipeline language**. No abbreviations. Short grammatical sentences are fine. Shortened terms and fragment stacks are not.

**Violating the letter of this rule is violating the spirit of this rule.**

## Pipeline language

1. Read `.cursor/csp-pipeline-language` via `scripts/csp-pipeline-language.sh get --root <project>` (default **`en`** when unset).
2. Write status updates, Decision / Blocker options, review chat, and asks in that language.
3. Kit documentation, canvas copy, and foreign-facing README text stay **English** regardless of this preference.
4. **Russian is never allowed** (sanctions policy of this project/kit). Never select or produce Russian. If the human writes in Russian: refuse to continue in Russian; reply in English or the selected non-Russian language; offer skill `hitl-choice` preset **Pipeline language**. See rule `pipeline-language-no-russian` and [`docs/superpowers/pipeline-language.md`](../../docs/superpowers/pipeline-language.md).
5. Do **not** auto-switch language just because the human wrote in another allowed language mid-run — keep the selected preference unless they change it via the Pipeline language gate.

Optional phrasing tables: [`references/en.md`](references/en.md) (default), [`references/uk.md`](references/uk.md) when language is `uk`. For other languages, apply the same clarity rules in that language without inventing clipped jargon.

## When to Use

- Every message the human will read in Cursor chat
- Review reports, plan notes, and status shown in chat
- Decision-tier / Blocker options, recommendations, and proposal lists
- After `english-humanizer` (that skill does not expand abbreviations)

Not for: identifiers inside backticks or code fences.

## Output contract

Write the complete phrase the first time and every time. Do not introduce a short form in parentheses. If the human used a short form in this turn, you may echo it once, then keep using the full phrase.

Every user-facing option, recommendation, status bullet, and ask must be a **full sentence** (who/what + verb + what it means for the human). "Short sentences are fine" means grammatical sentences — **not** noun-phrase stacks.

## Expand these (not exhaustive)

| Forbidden in chat | Write instead (English; adapt to selected language) |
|-------------------|------------------------------------------------------|
| PR | pull request |
| CI / CD | continuous integration / continuous delivery |
| HITL | human-in-the-loop / step that needs a human answer |
| AC | acceptance criteria |
| SHA | commit hash |
| P0 / P1 / P2 | highest / high / medium severity |
| MCP | Model Context Protocol |
| TTL | time-to-live |
| JWT | JSON Web Token |
| WIP | work in progress |
| LGTM | looks good to me |
| nits | minor remarks |
| PoC | proof of concept |
| LOC | lines of code |
| UI | user interface |
| API | application programming interface (or name the concrete interface) |

When language is `uk`, prefer the Ukrainian expansions in [`references/uk.md`](references/uk.md). Never use Latin letter clumps as standalone words in chat.

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

### Before / after (proposal shape, English)

**Before (forbidden):**

```
full host list (or allowlist generation rule from white-label configs);
SameSite (Lax vs None) under same-site cross-origin;
cookie-on-API + cross-site request forgery protection or separate backend-for-frontend / same-origin proxy;
who / where the configurator repo is and one-shot handoff;
Domain cookie: host-only on API or .energysave.se.
```

**After (required):**

```
We need to decide how browser cookies should work between marketing sites and the application programming interface server.

Option A — cookie only on the application programming interface host.
The browser stores the session only on that host. This is simpler, but marketing sites on other domains will not see this cookie directly.

Option B — cookie on the shared parent domain `.energysave.se`.
All sites under that domain can see the session. This is more convenient for sign-in, but widens the leak surface if any subdomain is compromised.

Option C — a separate backend-for-frontend on the same origin as the page.
The page talks only to its proxy; cross-site request forgery protection gets simpler. This is more infrastructure work.

Recommendation: option C if white labels already have a proxy; otherwise option A plus an explicit allowlist of hosts from white-label configs.
```

When language is `uk`, use the Ukrainian before/after in [`references/uk.md`](references/uk.md). Decision asks in any selected language use the same sentence shape (subject + verb + trade-off), not telegram fragments.

## Keep exact (inside backticks or fences)

File paths, symbol names, error strings, ticket keys (`ACP-2656`), URLs, slash-command names (`/csp-start-task`), CLI flags.

## Before / after (abbreviations, English)

**Before:** CI failed on the PR after HITL. SHA `abc1234`, this is P0.

**After:** Continuous integration failed on the pull request after the step that needs a human answer. Commit hash `abc1234`. This is highest severity.

## Red flags — rewrite before send

- A run of capital letters used as a word (PR, HITL, AC, SHA, MCP)
- Severity spoken only as `P0`
- “Humanizer already ran” used as a reason to keep jargon
- First-use expansion then switching back to the short form
- Bullet or option label with no verb
- Alternatives glued with only `;` / `+` / `/`
- “one-line trade-off” used as a reason to drop grammar
- Producing Russian (any dialect) despite human input — refuse and continue in an allowed language

| Excuse | Reality |
|--------|---------|
| "Engineers know PR" | This chat is for the human who asked for full words. |
| "english-humanizer wants short" | Short sentences, full terms. Humanizer does not override this. |
| "I'll expand on first use only" | Expand every time. |
| "Saving tokens" | Unreadable chat wastes more than a few extra words. |
| "question-discipline said one-line trade-off" | One or two short **sentences** of trade-off — not a fragment stack. |
| "Labels may be short" | Brief is fine; fragment stacks are not. |
| "Human wrote in Russian" | Refuse Russian; continue in English or the selected non-Russian language. |
