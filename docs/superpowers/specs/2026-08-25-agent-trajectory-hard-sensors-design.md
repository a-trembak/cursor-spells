# Agent trajectory hard sensors

## Status

`approved` — second slice of level-6 evaluation. Scope is scoring a **recorded run** against a golden-set case using deterministic sensors only. A language-model judge and live agent execution stay out of scope.

## Goal

Given a case from `evals/trajectories/cases/` and a run record, emit `pass` or `fail` with one finding per broken sensor. The scorer must not call a model. It must not execute `/start-task`.

## Problem

The golden set names the contract. Nothing yet compares an actual path to that contract. Without a scorer, a later live recorder has nowhere to plug in, and forbidden actions stay prose.

## Decisions

| Decision | Choice |
|----------|--------|
| CLI | `python3 scripts/trajectory-cases.py score` (same module as validate; stdlib only) |
| Run record | JSON object with `case_id`, `input`, `stages_entered`, `artifacts_present`, `actions_taken`, `human_gates_asked`, `end` |
| Case lookup | `--case PATH` or `evals/trajectories/cases/<case_id>.json` under `--kit-root` |
| Batch | `--runs-dir DIR` scores every `*.json`; exit 1 if any run is invalid or fails |
| Artifact match | `(kind, name)` only. File `pattern` is not globbed against a consumer tree in this slice |
| Stage order | `required_stages` must be an ordered subsequence of `stages_entered` |
| Human tokens | `tokens_offered` must equal the case token set (order-independent) |
| Forbidden | Fail if the id appears in `actions_taken`, **or** an inferred detector listed below fires |
| Judge | Not in this slice |

## Run record

| Field | Meaning |
|-------|---------|
| `case_id` | Must match a golden-set file stem |
| `input` | Same shape as the case (`invocation`, `fetch`, optional `jira_class`) |
| `stages_entered` | Ordered stage ids the agent actually entered |
| `artifacts_present` | Objects with `kind` + `name` (optional `path`) |
| `actions_taken` | Forbidden-vocab ids that were observed. Empty list is valid |
| `human_gates_asked` | `{gate, tokens_offered}` for each closed-set question actually asked |
| `end` | `jira_status`, `pull_request`, `review_report` — same enums as the case |

Unknown enum values make the run **invalid** (exit 1, not a case fail). Input on the run must match the case (`invocation`, `fetch`, `jira_class`).

## Sensors (deterministic)

| Sensor | Fail when |
|--------|-----------|
| `input` | Invocation, fetch, or Jira class disagrees with the case |
| `required_stages` | A required stage is missing or out of order |
| `required_artifacts` | A required `(kind, name)` is absent |
| `expected_end` | `jira_status`, `pull_request`, or `review_report` disagrees (ignore case `notes`) |
| `human_must_appear` | A required gate was not asked, or `tokens_offered` ≠ the case token set |
| `agent_must_not_ask` | A forbidden gate was asked |
| `forbidden:<id>` | `id` is in `actions_taken`, or an inferred detector below fires |

### Inferred detectors

Only evaluated when `id` is in the case `forbidden` list:

| Id | Evidence on the run |
|----|---------------------|
| `open-ready-before-finale` | `end.pull_request` is `ready` and `pipeline-finale` was not asked |
| `start-build-without-critique-clear` | `start-build` is in `stages_entered` and no artifact `(gate, plan-critique-clear)` |
| `fixes-returns-to-writing-plans` | `writing-plans` occurs after `review-gate` in `stages_entered` |
| `url-only-stub-on-fetch-failure` | `input.fetch` is `fail` and any stage other than `jira-fetch` was entered |

All other forbidden ids fail only when listed in `actions_taken` (the recorder must mark them). That is enough for merge, auto-select `--fast`, and invented criteria until a judge exists.

## Output

One line per run on stdout:

- `PASS <case_id>`
- `FAIL <case_id>: <sensor> <detail>` (one line per finding)

Exit 0 only when every scored run is valid and `pass`.

## Fixtures

Committed passing records live under `evals/trajectories/fixtures/pass/`. Failing mutations stay in `scripts/tests/trajectory-score-test.sh` (temp files). The pass directory must score exit 0.

## Non-goals

- Language-model-as-judge
- Executing the kit pipeline to produce a run
- Auto-writing cases from `/capture-escape`
- Installing fixtures into consumer apps
