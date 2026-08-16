---
name: hitl-choice
description: >-
  Use for every discrete human-in-the-loop (HITL) gate in this kit. Must call
  Cursor AskQuestion (or alias) first for closed-set choices; typed reply tokens
  are fallback only after the tool fails or is missing. Use from approve-plan,
  finish-plan, update-docs, tech-spec, engineer-review, multi-repo-supervisor,
  start-issue-task blocked critic, blocked implementation-critic gates,
  pipeline route / Fast vs issue, and create-pr Pipeline finale.
---

# HITL Choice

Canonical UX for closed-set HITL questions. **Always attempt interactive buttons** via the session's question tool; keep typed tokens as the durable contract and last-resort fallback.

## When to Use

- Any kit HITL gate with a fixed option set (`approve-plan` / `revise`, `skip` / `approve` / `done`, `docs_md` / `docs_repo` / `confluence`, `human` / `agent`, `light` / `full`, Decision-tier forks, blocked-critic next steps, **engineer-review / pr-review Needs clarification**, **force-clear / leave** for a foreign pipeline gate, **Pipeline route**, **Fast vs issue**, **Pipeline finale**)
- Not for open-ended answers alone (Figma URL paste, docs-repo path, Confluence space/URL, long revise notes, free-form clarification replies after `Ci:other`, missing Jira paste) — those stay chat text after the closed choice, if any

## Protocol (mandatory)

1. **First action of every closed-set HITL gate: call the interactive question tool.** Do not open with a chat-only bullet list. Do not "prefer text". Do not skip the tool because you are unsure it exists — **attempt the call**.
2. **Resolve tool name** (first that exists in the session tool list / succeeds):
   1. `AskQuestion`
   2. `AskUserQuestion`
   3. `ask_question`
   4. `ask_user` / `request_user_input`
3. Set each option's **`id` to the canonical reply token** the calling skill already documents (`approve-plan`, `revise`, `skip`, `C1:A`, …). Labels may be short human-friendly prose; ids must stay the tokens.
4. Treat a selected option `id` exactly as if the user typed that token.
5. **On tool error or cancel: retry once** with the same prompt and options. Only after a second failure (or a hard `unknown tool` / not-found error on the first attempt with no alias left) use the **text fallback**: ask with the calling skill's exact wording and accept the same typed tokens. State briefly that buttons failed / were unavailable.
6. **Forbidden voluntary skips:**
   - Pasting options as markdown bullets while assuming the tool is missing (without having attempted a call)
   - Combining the gate into a long prose message without a tool call
   - Choosing text "for speed" or "because cloud"
7. **Free-text follow-ups stay in chat** after a closed choice when needed:
   - `revise` → wait for change description (or file edit), then continue the calling skill
   - `skip` on tech-spec → wait for `<reason>` if not already provided
   - `fixes` (finish-plan) → wait for the fix description, implement/fix, re-ask the gate
   - `have_urls` (Figma) → wait for pasted node URLs
   - `docs_repo` → wait for docs repo path or clone URL (optional branch / folder)
   - `confluence` → wait for space/parent or page URL
   - `accept F<id>` may be chosen via buttons; extra notes stay optional chat text
   - `Ci:other` (engineer-review clarify) → wait for free-text answer for that `Ci`, then continue the sequence
8. If the user types a canonical token while buttons are showing, honor the typed token.
9. Never invent a HITL answer when the picker is skipped/cancelled — re-ask via retry or text fallback, or wait.
10. **Do not re-ask** when a canonical token for this gate is already present in a later user message (e.g. user sent `approve` while a stop-hook followup re-prompted). Honor that token and continue the calling skill.
11. **At most one question-tool call per assistant message.** For multi-item clarifies, ask sequentially (one `Ci` per turn).

## Gate presets

Use these option ids (labels are suggestions). Calling skills may add context in the question prompt.

### Tech-spec entry

| id | label |
|----|-------|
| `human` | I will provide a plan / notes (full system-design path) |
| `agent` | Agent drafts (then choose light or full) |

### Tech-spec depth (agent mode only)

| id | label |
|----|-------|
| `light` | Light tech-spec (7 sections, no design pair) |
| `full` | Full system-design (designer + critic, then merge) |

Ask only after the human chose `agent` on Tech-spec entry. Do not ask in `human` mode (always full).

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

Prefer `allowMultiple: true` when the tool supports it so several `accept F<id>` ids can be chosen in one step. Text fallback remains: `accept F<id>` and/or revise + `/critique-plan` / re-run `approve-plan` / re-run issue critic.

### Engineer-review clarify (dynamic, sequential)

Use after a validated engineer-review / pr-review / multi-repo report when **Needs clarification** is non-empty. **One `Ci` per message** (question-tool limit).

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
6. Text fallback **only after** failed/missing question tool (see protocol):

   > Clarifications needed. Prefer answering one `C#` at a time, or reply in one message like `C1: A; C2: B` (or free text). Options and recommendations are in the report above.

7. When every `Ci` is answered, return control to the calling skill to re-dispatch affected phases.

### Force-clear foreign gate

| id | label |
|----|-------|
| `force-clear` | Clear the named foreign gate slug/path |
| `leave` | Leave foreign gate untouched |

Ask only when the human explicitly wants to remove another chat's gate. Option prompt must include the slug and plan path. Ids: `force-clear` requires a follow-up slug or path if not already in the prompt context; `leave` aborts.

### Review-learn promote

Use after `review-learn` proposes a **new** kit gate (`gate: propose:…`) that is not already an R# / checklist section.

| id | label |
|----|-------|
| `consumer_only` | Keep learning in this project's `.cursor/review-learnings.md` only (recommended default) |
| `promote` | Also promote into the cursor-spells kit (only when editing the kit repo, or as a human follow-up PR) |
| `skip` | Do not write this learning |

Prompt: one-line miss class + `rule_one_liner`. Default recommendation: `consumer_only`. Never auto-edit kit checklists from a leaf app on `promote` — if not in the kit repo, record the proposal for the human and still write the consumer entry unless `skip`.

### Pipeline route

Ask only from `/start-task` when a Jira issue was fetched and `jira_class` is `unknown` (and the human did **not** pass `--fast`). Never invent `--fast`.

| id | label |
|----|-------|
| `full` | Full pipeline (tech-spec → design → implement) |
| `fast` | Fast pipeline (`--fast`: skip spec) |
| `issue` | Issue pipeline (`/start-issue-task` / bug-fixer) |

### Fast vs issue

Ask only from `/start-task --fast` when `jira_class` is `bug`. The agent never auto-selects `--fast`; this gate only chooses whether to **leave** fast.

| id | label |
|----|-------|
| `issue` | Switch to `/start-issue-task` (root-cause bug path) |
| `stay_fast` | Stay on `--fast` |

### Pipeline finale

Ask from skill `create-pr` **after** a draft PR exists (never before). Default if the human abandons the picker: treat as `keep_draft` only after protocol retry/fallback — do not invent `ready`. Show Jira options **only** when `jira_key` is known.

| id | label | When shown |
|----|-------|------------|
| `keep_draft` | Keep draft (stop) | always |
| `ready` | Mark ready for review | always |
| `keep_draft_jira` | Keep draft + comment PR URL on Jira | Jira key known |
| `ready_jira` | Ready for review + comment PR URL on Jira | Jira key known |

On `ready` / `ready_jira`: `gh pr ready` per opened PR. On `*_jira`: `addCommentToJiraIssue` with PR URL(s) only — never `transitionJiraIssue`, never merge.

### Decision-tier / Blocker questions

Use the question tool with 2–3 options. Option `id`s must be stable slugs you can record into the spec (e.g. `opt_a_outbox`, `opt_b_sync`). Prompt includes the recommendation. One question per message (see `tech-spec` question-discipline).

## Notes

- Markers (`.cursor/gates/<kind>/<slug>`) and downstream skill steps are unchanged — only the ask UX changes. Never delete a foreign slug without this Force-clear preset.
- If the harness truly exposes no question tool, typed tokens still work **after** a hard missing-tool failure — goal is 100% attempt rate, not inventing UI.
- Slash commands and rules that restated HITL prompts should point here or say “use skill `hitl-choice` (AskQuestion required)”.
