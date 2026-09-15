---
name: trajectory-score
description: >-
  Record a kit trajectory ledger and score it against a golden case at the
  natural stop. Use from /csp-start-task, /csp-start-issue-task, create-pr, finish-plan,
  critique-plan, capture-escape, tech-spec, and other wired pipeline stops.
  Never invents human-gate answers. Never replaces engineer-reviewer.
---

# Trajectory score

Kit-owned **harness loop**: golden case → session or slice ledger → hard-sensor `score` at the moment the contract is provable → on `FAIL`, ask **Trajectory fail**. Evaluation measures the **agent path**, not product-code taste. `csp-engineer-reviewer` stays the diff reviewer.

## When to Use

- A wired stop below says to score a named case
- After a language-model **trajectory-judge** writes `actions_taken` and you must re-score
- Not for scoring chat logs. Not a sixth engineer-review phase named “eval”

## Resolve kit

```bash
KIT="$(tr -d '\n' < .cursor/cursor-spells-kit-path 2>/dev/null || true)"
if [[ -z "$KIT" ]]; then
  KIT="$(tr -d '\n' < "$HOME/.cursor/cursor-spells-kit-path" 2>/dev/null || true)"
fi
LEDGER=".cursor/gates/trajectory-run/<case_id>.json"
```

Skip score when the kit path, scorer, or ledger dump is missing. Continue the existing pipeline stop. In chat, say in one full sentence that trajectory score was skipped. Do not brick old chats.

Never substitute a live ticket key for the case `input.invocation`. Exact strings come from `evals/trajectories/cases/<id>.json`.

## Record then score

Init a **fresh** slice ledger at the stop (do not reuse a full-path ledger for a slice case):

```bash
python3 "$KIT"/scripts/trajectory-cases.py record init \
  --ledger "$LEDGER" --case-id <case_id> \
  --invocation "<exact case invocation>" --fetch <ok|fail|skip> [--jira-class <feature|bug|unknown>]
# Start the live metrics clock (consumer project history; safe to skip if the script is missing)
python3 "$KIT"/scripts/pipeline-metrics.py mark-start --ledger "$LEDGER" [--ticket "<live ticket key>"]
# then record stage / artifact / gate / action / end as the case requires
python3 "$KIT"/scripts/trajectory-cases.py record dump --ledger "$LEDGER"
# Score and append one history row (quality + duration) for later graphs
python3 "$KIT"/scripts/pipeline-metrics.py append-score --kit-root "$KIT" --run "$LEDGER" [--ticket "<live ticket key>"]
# If pipeline-metrics.py is missing, fall back to:
# python3 "$KIT"/scripts/trajectory-cases.py score --kit-root "$KIT" --run "$LEDGER"
```

If `record dump` fails, skip score. Missing `pipeline-metrics.py` → score only; do not invent history rows.

History default path (consumer project, not the kit): `.cursor/gates/pipeline-metrics/history.jsonl`. Summarize later with `python3 "$KIT"/scripts/pipeline-metrics.py summary`. Export for graphing with `export --format csv`.

## On FAIL

Print the `FAIL` lines and **stop**. Ask skill `hitl-choice` preset **Trajectory fail**. On `skip`, mention `/csp-capture-escape` with the `FAIL` lines and do not start `csp-engineer-reviewer`. On `generalize`, follow `evals/trajectories/README.md` “Add a case” only when the current git root contains both `skills/engineer-review` and `agents/csp-engineer-reviewer.md`; otherwise print the `FAIL` log and stop. After validate, display the validated case JSON (the file contents) in chat and wait for the human to confirm it is correct before `git commit`. Do not offer `git diff` as a substitute. Do not invent `approve-spec` / `skip` / `ready`. Do not run `gh pr ready`. Do not merge.

## On PASS or skipped score

Continue the existing stop (wait for pasted text, wait for the human's already-chosen token, or continue the pipeline).

## Session ledger (end-to-end)

Path: `.cursor/gates/trajectory-run/session-full.json`, `session-fast.json`, or `session-issue.json`.

1. **Init once** at pipeline start with the matching end-to-end case input (`full-happy-path`, `fast-skips-plan-layer`, `issue-happy-path`). Use the case's exact invocation (`/csp-start-task PROJ-1`, `/csp-start-task --fast PROJ-1`, `/csp-start-issue-task PROJ-1`) — not the live ticket key.
2. **Append** after every named stage, artifact, or human gate on that path (`record stage` / `record artifact` / `record gate`). Do not re-init.
3. **Score** at `create-pr` after Pipeline finale was asked and an OPEN draft exists — in addition to the slice `create-pr-draft-never-merge` / `create-pr-draft-never-merge-no-jira` ledger. Missing session ledger → skip the end-to-end score only.
4. Init `session-issue` only when `jira_class` is `bug` (matches `issue-happy-path`). Explicit `/csp-start-issue-task` on a Story/Task (`jira_class` feature) scores the slice `start-issue-story-stays-issue` instead.

A dishonest agent can still write a canned PASS ledger. First slice is orchestrator-appended records, not a chat parser.

## Slice cases (score when the contract is provable)

| Case | When | Init notes |
|------|------|------------|
| `fetch-failure-stops` | Jira fetch failed; stop for pasted text | `--invocation "/csp-start-task PROJ-1" --fetch fail`. Skip if caller was `/csp-start-issue-task` or `/csp-write-tech-spec` |
| `route-unknown-asks-human` | After Pipeline route was asked (`jira_class` unknown, no `--fast`) | `--invocation "/csp-start-task PROJ-1" --fetch ok --jira-class unknown`. Gate tokens `full,fast,issue` |
| `route-feature-to-full` | After tech-spec-entry was asked (feature, no `--fast`) | `--jira-class feature`. Gate tokens `human,agent` |
| `route-bug-to-issue` | After issue-fix-plan starts from `/csp-start-task` without re-fetch | `--jira-class bug`. Do not ask pipeline-route / fast-vs-issue / tech-spec-entry |
| `fast-bug-asks-human` | After Fast vs issue was asked (`--fast` + bug) | `--invocation "/csp-start-task --fast PROJ-1" --jira-class bug`. Tokens `issue,stay_fast` |
| `start-issue-story-stays-issue` | Explicit `/csp-start-issue-task` after fix-plan + critic, even when type is Story | `--invocation "/csp-start-issue-task PROJ-1" --jira-class feature` |
| `review-gate-fixes-to-build` | `/csp-finish-plan` after the human picked `fixes` **and** `software-developer` returned | `--invocation "/csp-finish-plan" --fetch skip`. Then re-ask review-gate |
| `critic-blocks-flawed-plan` | Verdict blocked on the fixture notification-plugin plan; after critic-blocked was asked | Exact fixture invocation. Tokens may be any non-empty `revise` / `accept F<id>` set. Plan file must stay byte-identical |
| `capture-escape-no-review` | `/csp-capture-escape` after **Capture-escape destination** (typical path; no engineer-reviewer) | Do **not** ask review-learn-promote. Score this for both `miss` and `project_secret` |
| `capture-escape-promote-new-gate` | Retired. `/csp-capture-escape` never asks Review-learn promote; kit publishes go through `teach-review` on `miss` | Do not score this case |
| `tech-spec-no-invented-facts` | `/csp-write-tech-spec` with the order-export acceptance criteria, after entry + decision-blocker + tech-spec-gate | Run skill `trajectory-judge` first, then score |
| `clean-revise-no-archaeology` | `clean-decision-docs` on a forced revise, after tech-spec-gate | Run skill `trajectory-judge` first, then score |
| `create-pr-draft-never-merge` | Four-token Pipeline finale (`jira_key` known) after the ask, before `gh pr ready` | See skill `create-pr`. Observe OPEN drafts via `gh pr view` |
| `create-pr-draft-never-merge-no-jira` | Two-token Pipeline finale (`jira_key` not known) after the ask, before `gh pr ready` | `--fetch skip`. Tokens `keep_draft,ready`. Never skip never-merge scoring solely because Jira options were absent |
| `full-happy-path` / `fast-skips-plan-layer` / `issue-happy-path` | Session ledger at `create-pr` (draft + finale asked) | Do not score these during engineer-review before a draft exists |

## Hard rules

- Do not add a review phase named “eval”.
- Do not jump to overnight unsupervised loops (Eledath 7) or agent-to-agent teams without an orchestrator (Eledath 8).
- Do not copy `evals/` into consumer apps (`csp install` never copies it).
- Missing kit/ledger → skip score; do not invent Jira `In Progress`.
- `evals/` is kit-only. Dogfood does not require live `/csp-start-task` inside kit continuous integration.
