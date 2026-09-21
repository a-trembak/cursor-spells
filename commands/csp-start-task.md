---
description: Orchestrate the full pipeline from Acceptance Criteria to a reviewed draft PR — or lean --fast mode (no HITL planning) that implements, engineer-reviews, and opens a draft PR. Full mode stops only at established human-in-the-loop gates. Jira keys/URLs are fetched via MCP; Bug tickets route to the issue pipeline.
argument-hint: "[--fast] [ac-source]"
---

# /csp-start-task

Entry point for feature work. Default mode chains every quality stage and stops only at established HITL gates. **`--fast`** skips planning/review HITL for small tasks: implement → engineer-review → draft PR.

## Arguments

- Optional `--fast` — lean path (see below). May appear before or after the AC source.
- Optional AC source: a ticket id, a Jira/tracker URL, a file path, or inline text. If omitted, ask for it.
- For bug fixes driven by a Jira ticket with root-cause discipline, prefer `/csp-start-issue-task` instead — `/csp-start-task` will auto-route classified Bug tickets there.

## Mode selection

1. If args contain `--fast` → remember **fast intent** (strip the flag; remainder is AC source). Do **not** start implementing yet.
2. If AC source is omitted, ask for it and stop until provided.
3. **Jira fetch** — if the source looks like a Jira issue (skill `jira-fetch` / `jira_looks_like_issue`): invoke skill **`jira-fetch`**. On fetch failure, stop (paste text). Record and score `fetch-failure-stops` per skill `jira-fetch`; skip score if the ledger or kit is missing. On success, the assembled `ac_text` **is** the AC; the key/URL is the AC reference. Never treat a Jira URL as a stub.
4. **Jira In Progress** — if fetch succeeded with `jira_key` and `jira_cloud_id`: invoke skill **`jira-transition`** with target `in_progress`. Skip when already In Progress. If MCP/transition is missing or no matching destination exists, **report and continue** — do not stop the pipeline. `/csp-write-tech-spec` does not transition.
5. **Route** (mechanical; never auto-select `--fast`):

   | Condition | Path |
   |-----------|------|
   | Fast intent **and** `jira_class` is `bug` | HITL via `hitl-choice` preset **Fast vs issue**: `issue` (run issue pipeline) / `stay_fast` (continue fast). After this ask, score `fast-bug-asks-human` per skill `trajectory-score` |
   | Fast intent **and** not bug | **Fast mode** with fetched or pasted AC |
   | No fast intent **and** `jira_class` is `bug` | **Issue pipeline** — run `/csp-start-issue-task` from its step 3 (fix plan) using the already-fetched issue; do not re-fetch. After issue-fix-plan starts, score `route-bug-to-issue` per skill `trajectory-score` |
   | No fast intent **and** `jira_class` is `unknown` (Jira fetched) | HITL via `hitl-choice` preset **Pipeline route**: `full` / `fast` / `issue`. After this ask, score `route-unknown-asks-human` per skill `trajectory-score` |
   | Otherwise (feature class, or non-Jira AC) | **Full mode** unless fast intent is set. After tech-spec-entry is asked, score `route-feature-to-full` per skill `trajectory-score` |

6. If AC still do not exist after fetch/paste, stop — writing AC themselves is out of scope.

---

## Full mode (default)

Chains every stage automatically except the established human-in-the-loop (HITL) gates — it does not skip or soften any of them.

### Pipeline (in order)

1. **Bootstrap** (automatic):
   - Read `.cursor/project-patterns.md` in the current project if present (create it via the `engineer-review` patterns flow on first use of this kit in a project, if entirely absent).
   - Detect the project's stack mechanically (same signals as `skill-map.md`'s stack-detection table: `package.json`, `pom.xml`, `docker-compose`, dependency names) — no reasoning call, a table lookup.
2. **Tech spec** — invoke skill `tech-spec` (agent `csp-tech-spec`) with the AC text (fetched `ac_text` or pasted/file source), the patterns file path (if found), and the detected stack label:
   - **HITL:** the entry question (`human` / `agent`) via skill `hitl-choice` (AskQuestion required; text only after failed/missing tool).
   - **HITL (agent only):** depth (`light` / `full`) via `hitl-choice`.
   - **If `human` or `full`:** system-design designer + critic consensus per `references/full-path.md`, merge into tech-spec (`format-human-plan` for human entry; `draft-from-ac` for agent+full).
   - **If `light`:** existing tech-spec interview path — draft 7 sections per `references/template.md` + `references/question-discipline.md`; **HITL** any Blocker/Decision-tier questions via `hitl-choice`.
   - **HITL:** `approve-spec` / `revise` / `skip <reason>` via `hitl-choice`. On `revise`, rewrite the spec as current truth (`clean-decision-docs`); if revision needs design rework, re-enter full-path consensus then re-merge; chat may summarize edits.
3. **Plan** (automatic once the spec's `Status` is `approved` or explicitly `skip`ped): invoke `writing-plans` with the tech spec as input to produce the implementation plan.
4. **Approve plan + critic** — invoke skill `approve-plan` on the new plan:
   - **HITL:** `approve-plan` / `revise` via `hitl-choice`. Plan revisions follow `clean-decision-docs` (no revision archaeology in the file).
   - **Automatic after `approve-plan`:** run `implementation-critic` (no HITL to start the critic).
   - **HITL:** only if `Verdict` is `blocked` or `clear pending accept` — wait for a plan revision or `accept F<id>` replies (`hitl-choice`).
   - **Automatic on `Verdict: clear`:** hand off to `start-build`.
5. **Execution** (automatic once critique is clear): skill `start-build` dispatches `csp-software-developer` as a nested Task — feature branch(es) in every repo the plan will touch, skill-map routing, then `subagent-driven-development` by default. **Wait for** the Task to return. **Do not treat dispatch as the end** of the pipeline. `start-build` then immediately invokes `finish-plan` in this parent chat. Do not ask "which approach?" in this orchestrated flow. If the user has already indicated they want a separate session, honor `executing-plans` instead. On `react-web` UI tasks with Figma URLs, `csp-software-developer` also runs `ce-test-browser` against the design.
6. **Finish plan** (automatic, from `start-build` after the developer returns — do not wait for the human to type `/csp-finish-plan`):
   - Apply `review-surface` (`SetActiveBranch` + checkout in each open folder) so the human can see the diff. Do **not** invoke `create-pr` here — this is not the pipeline end.
   - **HITL:** `skip` / `approve` / `done` via `hitl-choice` before `engineer-review` starts.
   - If `finish-plan` already started in this chat after the developer returned, do not re-ask — continue from its remaining steps.
7. **Engineer review** (automatic once the HITL gate clears): run `csp-engineer-reviewer` (or `csp-multi-repo-supervisor` for 2+ changed repos).
   - **HITL:** only for `Needs clarification` items the review surfaces.
7b. **Propose commit** (automatic after review settles): invoke skill **`propose-commit`** (HITL `approve-commit` / `revise`). Zero product commits before this step.
8. **Update docs** (automatic invocation after propose-commit): invoke skill `update-docs`:
   - **HITL:** `skip` / `docs_md` / `docs_repo` / `confluence` via `hitl-choice` — where product/internal docs should land (current-repo Markdown, a separate docs repo, or Confluence). Never invent the destination.
   - On a non-skip choice, **resolve style first** (required for `docs_repo` / `confluence`): human custom style for user and/or engineer → existing house docs at the destination → kit dual-audience default. Then draft, polish with `english-humanizer` without fighting house voice, and publish.
9. **Propose commit (residual)** — if `update-docs` left uncommitted intentional files, invoke **`propose-commit`** again.
9b. **Local verify** (automatic): invoke skill **`local-verify`** (consumer `.cursor/spells-local-verify.yaml`; default skip when no contract). Do not invent start commands.
10. **Create PR** (automatic): invoke skill **`create-pr`** (push + draft + Pipeline finale). Do not expect `create-pr` to invent product commits. Open or reuse a **draft** GitHub PR per changed repo, then the **Pipeline finale** HITL (`keep_draft` / `ready` / Jira comment when a key is known).

### Full-mode notes

- This command never invents an answer at any HITL gate above — it always stops and waits for the human's reply at exactly those points, and only those points.
- **Orientation:** every closed-set human gate uses skill `hitl-choice`, which prints a `pipeline-status` orientation strip before the question. Humans may run `/csp-pipeline-status` anytime for the same strip + canvas link (does not advance gates). Applies on full, `--fast`, and issue human gates alike.
- **Do not treat dispatch as the end** of the pipeline: after `csp-software-developer` returns, `finish-plan` then `csp-engineer-reviewer` must run in this chat.
- If AC do not exist yet, stop and say so — writing AC themselves is out of scope for this kit.
- Pass `jira_key` / `jira_cloud_id` / `jira_status` through to `create-pr` when fetch succeeded (finale may wait for every pull request to merge and continuous integration to succeed, then transition to Review; trajectory score needs the observed status).
- **Session ledger:** after routing to **full** mode, init `.cursor/gates/trajectory-run/session-full.json` for case `full-happy-path` per skill `trajectory-score` (exact invocation `/csp-start-task PROJ-1`). Append stages and gates along the path. `create-pr` scores it when a draft exists and Pipeline finale was asked.
- After routing to **fast** mode (not while waiting on Fast vs issue), init `session-fast.json` for case `fast-skips-plan-layer` (exact invocation `/csp-start-task --fast PROJ-1`).
- Append to the session ledger after every named stage and human gate (skill `trajectory-score`).

---

## Fast mode (`--fast`)

For small tasks that do not need tech-spec, plan approval, critic, finish-plan, or update-docs. Still runs engineer-review and opens a draft PR.

### Pipeline (in order)

1. **Bootstrap** — same as full mode (patterns + stack detect).
2. **AC required** — fetched `ac_text` or pasted/file source. If still empty, stop.
3. **Short task brief** (automatic, in chat only — not a tech-spec file): 3–6 bullets covering goal, touched areas if obvious, and done criteria from the AC. Do not run `tech-spec`, `writing-plans`, `approve-plan`, or `implementation-critic`.
4. **Execute** — create feature branch(es) per `software-developer` branch-setup; implement with skill **`software-developer`** via nested Task **`csp-software-developer`** using **`mode:fast`** (entry gates for tech-spec Status / critique-clear are skipped — see that skill). Prefer `subagent-driven-development` when available; verify with lint/test/typecheck before handoff. **Wait for** `csp-software-developer` to return. Do not treat dispatch as the end.
5. **Engineer review** — immediately after that return, run `csp-engineer-reviewer` (or `csp-multi-repo-supervisor` for 2+ repos). Skip `finish-plan` HITL. Skip Figma ask unless node URLs were already in the AC/context. HITL only for **Needs clarification**.
5b. **Propose commit** — invoke skill **`propose-commit`**.
5c. **Local verify** — invoke skill **`local-verify`** (skip when no contract).
6. **Create PR** — invoke skill **`create-pr`** (push + draft + Pipeline finale). Do not expect `create-pr` to invent product commits.

### Fast-mode notes

- Do not silently upgrade fast mode into full mode. If mid-flight the work is clearly large (multi-service design, migrations, ambiguous product decisions), **stop** and recommend re-running without `--fast` or using `/csp-start-issue-task` for bugs.
- Fast mode never invents AC. Closed-set HITL (clarify, Fast vs issue, Pipeline finale) still uses `hitl-choice` with AskQuestion required.
- Pass `jira_key` / `jira_cloud_id` / `jira_status` through to `create-pr`. Init and append `session-fast.json` (`fast-skips-plan-layer`) per skill `trajectory-score`.
