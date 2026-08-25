# Agent trajectory golden set

## Status

`approved` — first slice of level-6 evaluation for the cursor-spells kit. Scope is the corpus and a machine-checkable contract. Running an agent against these cases is out of scope.

## Goal

Replace “remember to dogfood by hand” with a **golden set of agent-trajectory contracts**: what the kit agent must do, must not do, where a human must appear, and which artifacts must exist. A later harness can score a live run against these files. This change only makes the files validatable without executing an agent.

## Problem

Dogfood checklists under `docs/superpowers/dogfood/` are prose. Continuous integration already greps skill text and tests shell helpers. Nothing states, in one machine-owned place, “on this invocation the agent must take this path and must not merge.” Without that corpus, adding more agents is not evaluation.

## Decisions

| Decision | Choice |
|----------|--------|
| Location | Kit-root `evals/trajectories/` — not copied into consumer apps on `csp install` |
| Case format | One JSON file per case under `evals/trajectories/cases/<id>.json`; `id` equals the filename stem |
| Vocabulary | Closed enums in `scripts/trajectory-cases.py` (pipeline, stages, artifacts, forbidden actions, human-gate names) |
| Validation | `python3 scripts/trajectory-cases.py validate` — stdlib only, no extra packages |
| Tests | `scripts/tests/trajectory-cases-test.sh` — temp invalid fixtures must fail; committed cases must pass |
| Human manuals | Existing dogfood markdown stays. Each case points at a `source` path that must exist in the kit |
| Runner | Not in this slice. No agent execution, no scoring of chat logs |

## Case contract

Every case is a JSON object with:

| Field | Meaning |
|-------|---------|
| `id` | Stable kebab id; must match the filename |
| `title` | One-line English summary |
| `source` | Kit-relative path of the dogfood checklist, spec, or command that owns the behavior |
| `pipeline` | `full` / `fast` / `issue` / `slice` |
| `end_to_end` | `true` only when the case covers the whole named pipeline; `false` for a route, gate, or fragment |
| `status` | `active` (in the golden set) or `draft` |
| `input` | Invocation, optional Jira class, optional acceptance-criteria text, fetch outcome |
| `required_stages` | Ordered kit stage ids the agent must enter |
| `required_artifacts` | Files, gate markers, git/github/jira/report objects that must exist at the expected end |
| `forbidden` | Closed-set action ids the agent must never take on this path |
| `human_must_appear` | Gates (from `hitl-choice` presets) with the exact reply tokens |
| `agent_must_not_ask` | Gates or decisions the agent must not present |
| `expected_end` | Jira status, pull-request state, review-report shape |

`input.fetch` is `ok`, `fail`, or `skip` (no Jira fetch). `input.jira_class` is `feature`, `bug`, `unknown`, or omitted when fetch is `skip`.

### End-to-end completeness

When `end_to_end` is `true`, `required_stages` must include every stage in the pipeline’s required set and must not include any stage in that pipeline’s forbidden set (defined in `scripts/trajectory-cases.py`). Slice cases (`end_to_end` false) list only the stages they cover.

Any case whose `required_stages` includes `create-pr` must include forbidden action `merge-pull-request`.

## Non-goals

- Executing `/start-task` or scoring transcripts
- Replacing dogfood checklists
- Installing the corpus into consumer repositories
- Auto-writing new cases from `/capture-escape` (later slice)

## Test plan

- Invalid JSON, unknown enum, filename/id mismatch, missing `source` file → validator exit 1
- Duplicate `id` across files → exit 1
- Committed `evals/trajectories/cases/*.json` → exit 0
- At least ten `active` cases covering full, fast, issue, and slice paths
