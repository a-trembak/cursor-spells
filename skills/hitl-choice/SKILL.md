---
name: hitl-choice
description: >-
  Use for every discrete human-in-the-loop (HITL) gate in this kit. Must call
  Cursor AskQuestion (or alias) first for closed-set choices; typed reply tokens
  are fallback only after the tool fails or is missing. Use from approve-plan,
  finish-plan, update-docs, tech-spec, engineer-review, multi-repo-supervisor,
  start-issue-task blocked critic, blocked implementation-critic gates,
  pipeline route / Fast vs issue, create-pr Pipeline finale, Teach-review miss,
  approve-commit, and Capture-escape destination.
---

# HITL Choice

Canonical UX for closed-set HITL questions. **Always attempt interactive buttons** via the session's question tool; keep typed tokens as the durable contract and last-resort fallback.

## When to Use

- Any kit HITL gate with a fixed option set (`approve-plan` / `revise`, `skip` / `approve` / `done`, `docs_md` / `docs_repo` / `confluence`, `human` / `agent`, `light` / `full`, Decision-tier forks, blocked-critic next steps, **engineer-review / pr-review Needs clarification**, **force-clear / leave** for a foreign pipeline gate, **Review-learn promote**, **Teach-review miss** (`miss` / `project_secret` / `no_miss`), **Capture-escape destination** (`miss` / `project_secret`), **Pipeline route**, **Fast vs issue**, **Propose commit** (`approve-commit` / `revise`), **Pipeline finale**)
- Not for open-ended answers alone (Figma URL paste, docs-repo path, Confluence space/URL, long revise notes, free-form clarification replies after `Ci:other`, missing Jira paste) — those stay chat text after the closed choice, if any

## Protocol (mandatory)

0. **Orientation strip (before the question):** load skill `pipeline-status` (or run `scripts/pipeline-status.sh --root <project> [--invocation <invocation_id>]` when `invocation_id` is known) and include the adapted status strip in the **same** user-visible turn as the question. Missing or failing script → one-sentence skip (“orientation skipped”), then still ask the gate. Never invent a stage.
0b. **After the closed-set token is recorded** (same stop that appends the session ledger when applicable): dual-write `scripts/pipeline-run-log.sh append --root <project> --invocation <invocation_id> [--plan <path>] --stage <gate-stage> --note "<token>"`. Once the plan path is known, always pass `--plan`. Missing helper or missing `invocation_id` → one-sentence skip. Notes are short tokens only — no chat transcripts or ticket bodies.
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

`approve` and `done` are equivalent. `fixes` is the structured stand-in for “or describe fixes first”; after selection, wait for the description. On the finish-plan path, a new Local Diff Review canvas outbound (`kind: local-diff-review/comments`, `intent: apply-fixes`) is the same fix cycle — see `skills/finish-plan/references/local-diff-review.md`. When a Local Diff Review canvas was built, the question prompt must tell the human to keep **Current thread** and press **Send** (or use `approve` / `done` / `skip`). Asking this gate does **not** end the pipeline: after `skip` / `approve` / `done`, engineer-review starts. Do not invoke `create-pr` here.

### Figma ask (frontend)

| id | label |
|----|-------|
| `no_figma` | No Figma |
| `have_urls` | I will paste Figma node URLs |

On `no_figma`, treat as typed `no figma`. On `have_urls`, wait for pasted URLs before `csp-review-figma-markup`.

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

Prefer `allowMultiple: true` when the tool supports it so several `accept F<id>` ids can be chosen in one step. Text fallback remains: `accept F<id>` and/or revise + `/csp-critique-plan` / re-run `approve-plan` / re-run issue critic.

### Engineer-review clarify (dynamic, sequential)

Use after a validated engineer-review / pr-review / multi-repo report when **Needs clarification** is non-empty. **One `Ci` per message** (question-tool limit).

Build options dynamically from that item's structured choices:

| id | label |
|----|-------|
| `Ci:X` | Option label (e.g. `C1:A` → “Use existing helper Y”). If this `X` is `recommended`, prefix the label with `Recommended: ` |
| `Ci:other` | Something else (I will type it) |

Each question is **self-contained**. A fixer answering `C2` must not need the report still on screen. Prose must pass skill **`plain-language-chat`** (full words, no jargon clumps).

Rules:

1. **Prompt recipe (required shape — paste into the question tool):**
   - `C#` id and short title
   - **Context:** 1–2 sentences from the report (what this code does)
   - **What is wrong:** the problem in plain sentences (from `what` / report **What**)
   - **When it shows up:** concrete developer or user scenario (from `when_shows`)
   - **Where:** File path (linked), Lines **start–end**, Jump (`path#Lstart`), GitHub blob when known
   - The **numbered code fence** from that finding (same `snippet`, already ≤15 lines)
   - **Ask:** the decision in one or two sentences
   Option buttons stay in the tool. Do not drop File / Lines / Jump / fence / What / When it shows up to keep the prompt “short”. If the question tool truncates, repeat File + numbered fence in the same assistant message — still call the tool.
2. Canonical reply tokens are **`Ci:X`** (no space), e.g. `C1:A`, `C2:B`. Multi-repo uses the same shape with repo prefix already in the id if present (`api:C1:A`).
3. Mark the recommended option in the **label** only when `recommended` is set; never invent a recommendation.
4. After `Ci:other`, wait for free text for that item, then continue with the next unanswered `Cj`.
5. **`C1: A; C2: B` is a reply shape only.** If the user answers in batch chat (`C1: A; C2: B` or `C1:A; C2:B`) at any time, accept those tokens, skip AskQuestion for answered items, and continue only for remaining ones. **Never** use a batch letter list as the ask body (no “Waiting for confirmation: C1: A; C2: A; …” without per-item Context / What / When it shows up / Where / fence).
6. Text fallback **only after** failed/missing question tool (see protocol). The fallback message must still include that item’s What, When it shows up, File, Lines, Jump, and numbered fence — not “see the report above”:

   > Clarifications needed. Prefer answering one `C#` at a time, or reply in one message like `C1: A; C2: B` (or free text). File, line range, and the code snippet for this `C#` are in this message.

7. When every `Ci` is answered, return control to the calling skill to re-dispatch affected phases.
8. Orchestrator must lift phase JSON fields **verbatim** into this prompt. Do not re-summarize a rich phase finding into a title + letters.

**Example prompt (minimum):**

````
C1 — New helper duplicates loadUser
- **Context:** Profile screen loads the signed-in user on mount.
- **What is wrong:** A second user-fetch helper duplicates the existing loadUser path.
- **When it shows up:** Opens when someone lands on Profile after sign-in and the two helpers can disagree on which user record is current.
- **Where:**
  - File: [`src/bar.ts`](src/bar.ts)
  - Lines: **40–45**
  - Jump: [`src/bar.ts:40`](src/bar.ts#L40)
- **Ask:** Keep the new helper, or call existing `loadUser`?

```ts
40|  async function loadProfile() {
41|    return fetchUser();
42|  }
```
````

| Excuse | Reality |
|--------|---------|
| "The report already has the snippet" | Sequential questions hide the report. Repeat File + fence. |
| "AskQuestion is too short for a fence" | Evidence-gate already caps snippets at 15 lines. Paste them. |
| "Jump path is enough" | A fixer cannot judge options from a path alone. |
| "Batch letters are faster" | Batch is a reply shape only. Ask one `C#` with full body each turn. |
| "Phase already explained it privately" | Parent only sees Task JSON — phases must return full evidence upward. |

### Force-clear foreign gate

| id | label |
|----|-------|
| `force-clear` | Clear the named foreign gate slug/path |
| `leave` | Leave foreign gate untouched |

Ask only when the human explicitly wants to remove another chat's gate. Option prompt must include the slug and plan path. Ids: `force-clear` requires a follow-up slug or path if not already in the prompt context; `leave` aborts.

### Review-learn promote

Do **not** ask this after **Teach-review miss** or **Capture-escape destination** — those gates already chose the store. Kit publishes go through skill `teach-review`. `project_secret` capture never runs this preset.

Keep the tokens only if an older prompt still surfaces them:

| id | label |
|----|-------|
| `consumer_only` | Keep learning in this project's `.cursor/review-learnings.md` only |
| `promote` | Do not edit kit git here — tell the human to run `/csp-teach-review` instead |
| `skip` | Do not write this learning |

Never auto-edit kit checklists from a leaf app.

### Teach-review miss

Ask **after** a validated `csp-engineer-reviewer` or `csp-pr-reviewer` report is shown (pipeline and manual `/csp-engineer-review` / `/csp-pr-review`). Do not ask on `/csp-teach-review` (the command is already `miss`). Recommended: `miss`.

| id | label |
|----|-------|
| `miss` | Teach the shared kit (strip client names) |
| `project_secret` | Keep in this project only (internal names that must not enter the kit) |
| `no_miss` | Nothing to record |

`no_miss` → do not invoke `teach-review`; do not run `csp-review-learn` `mode:capture`. `miss` → if this message has no description, wait for free text (open-ended), then invoke skill `teach-review`. `project_secret` → if this message has no description, wait for free text, then dispatch `csp-review-learn` `mode:capture` (never **Review-learn promote**, never kit git). Failure of `teach-review` must not retract the report. Do not write both stores on the same miss.

After `no_miss`, after skill `teach-review` returns (success or failure), or after `project_secret` capture settles: on a **pipeline** review the **calling** pipeline skill must continue to skill `propose-commit` per engineer-review step 15. Do **not** ask Propose commit from inside this miss preset — the calling skill owns that gate. Manual `/csp-engineer-review` / `/csp-pr-review` do **not** auto-start `propose-commit` unless the human asks.

### Capture-escape destination

Ask from `/csp-capture-escape` after a non-empty miss description. The command is already a miss, so do not offer `no_miss`. Recommended: `miss`.

| id | label |
|----|-------|
| `miss` | Teach the shared kit (strip client names) |
| `project_secret` | Keep in this project only (internal names that must not enter the kit) |

`miss` → skill `teach-review`. `project_secret` → `csp-review-learn` `mode:capture` `source: production-escape`. Never both. Never **Review-learn promote** on `project_secret`.

### Pipeline route

Ask only from `/csp-start-task` when a Jira issue was fetched and `jira_class` is `unknown` (and the human did **not** pass `--fast`). Never invent `--fast`.

| id | label |
|----|-------|
| `full` | Full pipeline (tech-spec → design → implement) |
| `fast` | Fast pipeline (`--fast`: skip spec) |
| `issue` | Issue pipeline (`/csp-start-issue-task` / bug-fixer) |

### Fast vs issue

Ask only from `/csp-start-task --fast` when `jira_class` is `bug`. The agent never auto-selects `--fast`; this gate only chooses whether to **leave** fast.

| id | label |
|----|-------|
| `issue` | Switch to `/csp-start-issue-task` (root-cause bug path) |
| `stay_fast` | Stay on `--fast` |

### Propose commit

Ask from skill `propose-commit` after a settled engineer-review report (and again after `update-docs` when residual files remain). Never ask before engineer-review. Never treat this as Pipeline finale.

| id | label |
|----|-------|
| `approve-commit` | Approve commit message and file list |
| `revise` | Revise message or files (describe next) |

On `revise`, wait for free-text changes, then re-propose. On `approve-commit`, the calling skill runs `git commit` only (no push).

### Pipeline finale

Ask from skill `create-pr` **after** a draft PR exists (never before). Default if the human abandons the picker: treat as `keep_draft` only after protocol retry/fallback — do not invent `ready`. Show Jira options **only** when `jira_key` is known.

| id | label | When shown |
|----|-------|------------|
| `keep_draft` | Keep draft (stop) | always |
| `ready` | Mark ready for review | always |
| `keep_draft_jira` | Keep draft + comment PR URL on Jira | Jira key known |
| `ready_jira` | Ready for review + comment PR URL on Jira | Jira key known |

On `ready` / `ready_jira`: `gh pr ready` per opened PR. On `*_jira`: `addCommentToJiraIssue` with PR URL(s). Do not run `jira-transition` on the ready token itself. After `ready` / `ready_jira` when `jira_key` is known: wait until `pr_merge_ci_verdict` is `all_merged_ci_success` (every opened pull request merged and every continuous-integration build succeeded), then skill **`jira-transition`** target `review`. `closed_unmerged` reports and stops the wait. Never merge. Do not transition on `keep_draft` / `keep_draft_jira`.

### Trajectory fail

Ask only after `python3 scripts/trajectory-cases.py score` printed `FAIL` at a wired stop. Do not ask on `PASS` or when score was skipped.

| id | label |
|----|-------|
| `generalize` | This fail should become (or bump) a golden-set case |
| `skip` | Do not add a case; optional `/csp-capture-escape` with the FAIL lines |

Never auto-write `evals/trajectories/cases/`. `generalize` in a consumer app cannot edit the kit — paste the FAIL log for a later kit change. Default if the human abandons the picker: `skip`.

### Decision-tier / Blocker questions

Use the question tool with 2–3 options. Option `id`s must be stable slugs you can record into the spec (e.g. `opt_a_outbox`, `opt_b_sync`). Prompt includes the recommendation. One question per message (see `tech-spec` question-discipline).

## Notes

- Markers (`.cursor/gates/<kind>/<slug>`) and downstream skill steps are unchanged — only the ask UX changes. Never delete a foreign slug without this Force-clear preset.
- If the harness truly exposes no question tool, typed tokens still work **after** a hard missing-tool failure — goal is 100% attempt rate, not inventing UI.
- Slash commands and rules that restated HITL prompts should point here or say “use skill `hitl-choice` (AskQuestion required)”.
