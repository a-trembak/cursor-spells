# Review-learn: local ledger only for project-private misses

## Status

`approved` — human chose option 3 in chat (2026-08-21): keep `.cursor/review-learnings.md` only when a miss must never enter the shared kit; everything else goes through `teach-review`. Plan: [`2026-08-21-review-learn-project-secret.md`](../plans/2026-08-21-review-learn-project-secret.md).

Supersedes the “orthogonal / unchanged consumer ledger” relationship in [`2026-08-21-teach-review-kit-instructions-design.md`](2026-08-21-teach-review-kit-instructions-design.md). That spec’s kit-git / land rules stay.

## Goal

Shareable review misses become kit instructions. The consumer ledger exists only for miss classes that cannot be published (client names, internal product terms). Existing ledger files are not deleted. `csp-review-learn` `mode:load` still reads kit seed plus any local ledger.

## Problem

After `teach-review` landed, two writers still ran on the same miss: automatic `csp-review-learn` `mode:capture` into `.cursor/review-learnings.md`, and the post-report `miss` / `no_miss` gate into the kit. The local file is invisible to other projects. Automatic capture keeps filling it with classes that belong in the kit.

## Decisions

| Decision | Choice |
|----------|--------|
| Default store for a shareable miss | Skill `teach-review` (kit instructions) |
| Local ledger | Only when the human chooses `project_secret` |
| Automatic capture after a settled report | **Removed.** No P0 / replay / escape auto-append |
| Post-report gate | Always ask **Teach-review miss**: `miss` / `project_secret` / `no_miss`. Recommended: `miss` |
| `/csp-teach-review` | Still kit-only; invoking it **is** `miss` (no destination gate) |
| `/csp-capture-escape` | Ask **Capture-escape destination**: `miss` / `project_secret`. Recommended: `miss`. Command is already a miss, so no `no_miss` |
| Same miss, both stores | Forbidden |
| **Review-learn promote** | Do not ask on `project_secret` capture. Kit publishes go through `teach-review` |
| Existing `.cursor/review-learnings.md` | Leave in place; do not migrate or delete |
| `mode:load` | Unchanged: kit `learned-misses.md` + consumer ledger if present |

## Tokens

| Token | Where | Effect |
|-------|-------|--------|
| `miss` | Teach-review miss, Capture-escape destination, `/csp-teach-review` | Skill `teach-review`. Strip product / client names. Do not write the consumer ledger |
| `project_secret` | Teach-review miss, Capture-escape destination | `csp-review-learn` `mode:capture` into `<project>/.cursor/review-learnings.md`. Keep client / internal names. Do not edit kit git. Do not ask **Review-learn promote** |
| `no_miss` | Teach-review miss only | Write nothing |

Empty description → ask open-ended; still empty → stop. Do not invent a class.

## Local capture rules (`project_secret`)

- Eligibility is **only** the human token `project_secret` (plus a non-empty description). Triggers A–D (auto P0, replay, production-escape without this gate, `learn:yes`) are removed.
- Keep client names and internal product terms — that is why the row is not kit-safe.
- Still forbid passwords, tokens, and personal data in the ledger.
- Dedup / Active cap 20 / archive unchanged.
- Coverage: `review_learn: appended|deduped|skipped|n/a`.
- Orchestrators never read or write the ledger file themselves.

## Non-goals

- Deleting consumer ledgers or `csp-review-learn` `mode:load`.
- Auto-merging kit `learn/…` branches.
- Putting secrets (passwords, tokens, personal data) in either store.
- Changing `teach-review` land modes (`draft_merge` / `auto_push`).

## Success

After a settled review, the human can send a naming miss to the kit (`miss`) or keep a client-named miss in this project only (`project_secret`). A production escape through `/csp-capture-escape` uses the same two stores. Settled reports no longer append the local ledger on their own.
