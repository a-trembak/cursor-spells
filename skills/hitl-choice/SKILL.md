---
name: hitl-choice
description: >-
  Use for every discrete human-in-the-loop (HITL) gate in this kit. Prefers
  Cursor AskQuestion interactive buttons when the tool is available; falls back
  to the calling skill's exact typed reply tokens. Use from approve-plan,
  finish-plan, update-docs, tech-spec, engineer-review, multi-repo-supervisor,
  and blocked implementation-critic gates.
---

# HITL Choice

Canonical UX for closed-set HITL questions. **Prefer interactive buttons** via Cursor's `AskQuestion` tool; keep typed tokens as the durable contract.

## When to Use

- Any kit HITL gate with a fixed option set (`approve-plan` / `revise`, `skip` / `approve` / `done`, `docs_md` / `docs_repo` / `confluence`, `human` / `agent`, Decision-tier forks, blocked-critic next steps, **engineer-review / pr-review Needs clarification**)
- Not for open-ended answers alone (Figma URL paste, docs-repo path, Confluence space/URL, long revise notes, free-form clarification replies after `Ci:other`) — those stay chat text after the closed choice, if any

## Protocol (mandatory)

1. **If `AskQuestion` is in the session tool list**, call it for the gate. Do not only paste a bullet list when the tool is available.
2. Set each option's **`id` to the canonical reply token** the calling skill already documents (`approve-plan`, `revise`, `skip`, `C1:A`, …). Labels may be short human-friendly prose; ids must stay the tokens.
3. Treat a selected option `id` exactly as if the user typed that token.
4. **Text fallback** (required when `AskQuestion` is missing, fails, is skipped, or is cancelled): ask with the calling skill's exact wording and accept the same typed tokens.
5. **Free-text follow-ups stay in chat** after a closed choice when needed:
   - `revise` → wait for change description (or file edit), then continue the calling skill
   - `skip` on tech-spec → wait for `<reason>` if not already provided
   - `fixes` (finish-plan) → wait for the fix description, implement/fix, re-ask the gate
   - `have_urls` (Figma) → wait for pasted node URLs
   - `docs_repo` → wait for docs repo path or clone URL (optional branch / folder)
   - `confluence` → wait for space/parent or page URL
   - `accept F<id>` may be chosen via buttons; extra notes stay optional chat text
   - `Ci:other` (engineer-review clarify) → wait for free-text answer for that `Ci`, then continue the sequence
6. If the user types a canonical token while buttons are showing, honor the typed token.
7. Never invent a HITL answer when the picker is skipped/cancelled — re-ask via fallback text or wait.
8. Do not pretend buttons were shown if the tool was unavailable; use text quietly.
9. **Do not re-ask** when a canonical token for this gate is already present in a later user message (e.g. user sent `approve` while a stop-hook followup re-prompted). Honor that token and continue the calling skill.
10. **At most one `AskQuestion` per assistant message.** For multi-item clarifies, ask sequentially (one `Ci` per turn).

## Gate presets

Use these option ids (labels are suggestions). Calling skills may add context in the question prompt.

### Tech-spec entry

| id | label |
|----|-------|
| `human` | I will write / provide the spec |
| `agent` | Agent drafts via interview |

### Tech-spec gate

| id | label |
|----|-------|
| `approve-spec` | Approve spec |
| `revise` | Revise (describe changes next) |
| `skip` | Skip spec (reason next) |

### Approve-plan gate

| id | label |
|----|-------|
| `approve-plan` | Approve plan (critic runs next) |
| `revise` | Revise (describe changes next) |

### Finish-plan / engineer-review / multi-repo HITL

| id | label |
|----|-------|
| `skip` | Start review now |
| `approve` | I reviewed — start review |
| `done` | Done reviewing — start review |
| `fixes` | Describe fixes first |

`approve` and `done` are equivalent. `fixes` is the structured stand-in for “or describe fixes first”; after selection, wait for the description.

### Figma ask (frontend)

| id | label |
|----|-------|
| `no_figma` | No Figma |
| `have_urls` | I will paste Figma node URLs |

On `no_figma`, treat as typed `no figma`. On `have_urls`, wait for pasted URLs before `review-figma-markup`.

### Docs update destination

| id | label |
|----|-------|
| `skip` | Skip docs this run |
| `docs_md` | Markdown under `docs/` in this repo |
| `docs_repo` | Separate documentation repository |
| `confluence` | Confluence page |

On `docs_repo` / `confluence`, wait for the free-text location details before drafting. `skip` clears the docs gate without writing.

### Blocked / pending-accept critic

Build options dynamically:

| id | label |
|----|-------|
| `revise` | Revise the plan |
| `accept F<id>` | Accept finding F\<id\> (one option per open finding) |

Prefer `allowMultiple: true` when the tool supports it so several `accept F<id>` ids can be chosen in one step. Text fallback remains: `accept F<id>` and/or revise + `/critique-plan` / re-run `approve-plan`.

### Engineer-review clarify (dynamic, sequential)

Use after a validated engineer-review / pr-review / multi-repo report when **Needs clarification** is non-empty. **One `Ci` per message** (AskQuestion limit).

Build options dynamically from that item's structured choices:

| id | label |
|----|-------|
| `Ci:X` | Option label (e.g. `C1:A` → “Use existing helper Y”). If this `X` is `recommended`, prefix the label with `Recommended: ` |
| `Ci:other` | Something else (I will type it) |

Rules:

1. Prompt: short title + one-line Context + Jump path from the report (do not paste the full code fence into the question).
2. Canonical reply tokens are **`Ci:X`** (no space), e.g. `C1:A`, `C2:B`. Multi-repo uses the same shape with repo prefix already in the id if present (`api:C1:A`).
3. Mark the recommended option in the **label** only when `recommended` is set; never invent a recommendation.
4. After `Ci:other`, wait for free text for that item, then continue with the next unanswered `Cj`.
5. If the user answers in batch chat (`C1: A; C2: B` or `C1:A; C2:B`) at any time, accept those tokens, skip AskQuestion for answered items, and continue only for remaining ones.
6. Text fallback when AskQuestion is unavailable:

   > Clarifications needed. Prefer answering one `C#` at a time, or reply in one message like `C1: A; C2: B` (or free text). Options and recommendations are in the report above.

7. When every `Ci` is answered, return control to the calling skill to re-dispatch affected phases.

### Decision-tier / Blocker questions

Use `AskQuestion` with 2–3 options. Option `id`s must be stable slugs you can record into the spec (e.g. `opt_a_outbox`, `opt_b_sync`). Prompt includes the recommendation. One question per message (see `tech-spec` question-discipline).

## Notes

- Markers (`.cursor/*.pending`) and downstream skill steps are unchanged — only the ask UX changes.
- Cloud / model sessions without `AskQuestion` must keep working via text tokens alone.
- Slash commands and rules that restated HITL prompts should point here or say “use skill `hitl-choice`”.
