# Jira AC fetch, router, and PR finale dogfood

Manual + helper checks for the remaining workflow gaps after per-plan gates: Jira fetch on `/start-task`, mechanical route, Pipeline finale HITL, `/capture-escape`.

Do not require CI to execute agents or live Atlassian MCP.

## Helper tests

From kit root:

```bash
bash scripts/tests/jira-issue-test.sh
bash scripts/tests/pipeline-gates-test.sh
bash scripts/tests/jira-ac-router-finale-test.sh
bash scripts/tests/pipeline-flow-graph-test.sh
bash scripts/tests/trajectory-cases-test.sh
bash scripts/tests/trajectory-score-test.sh
bash scripts/tests/trajectory-record-test.sh
bash scripts/tests/trajectory-wiring-test.sh
```

| Check | Expect |
|-------|--------|
| Key / site / class | ALL PASS (`jira-issue-test.sh`) |
| Prose that mentions a key | `jira_looks_like_issue` is false (not a fetch) |
| Bare `PROJ-123` or `*.atlassian.net` URL | looks-like true |
| Bug-like types | `bug` (Bug, Defect, Fault, Incident, Problem, Error) |
| Feature-like types | `feature` (Story, Task, Feature, New Feature, Epic, Improvement, Change Request) |
| Spike / Sub-task / empty | `unknown` |
| Token contract | `jira-ac-router-finale-test.sh` ALL PASS |

Install refresh (optional throwaway consumer):

```bash
./scripts/install-to-project.sh /tmp/jira-ac-dogfood
test -x /tmp/jira-ac-dogfood/scripts/jira-issue.sh
test -x /tmp/jira-ac-dogfood/scripts/pipeline-gates.sh
rm -rf /tmp/jira-ac-dogfood
```

## Route table (agent / HITL)

Use with a real or pasted ticket. Never invent AC. Never auto-select `--fast`.

| Invocation | `jira_class` | Expect |
|------------|--------------|--------|
| `/start-task PROJ-1` | `bug` | Issue pipeline from `/start-issue-task` step 3 (no re-fetch) |
| `/start-task PROJ-1` | `feature` | Full pipeline |
| `/start-task PROJ-1` | `unknown` | HITL **Pipeline route** `full` / `fast` / `issue` |
| `/start-task --fast PROJ-1` | `bug` | HITL **Fast vs issue** `issue` / `stay_fast` |
| `/start-task --fast PROJ-1` | not bug | Fast pipeline |
| `/start-issue-task PROJ-1` | Story (feature) | **Still** issue pipeline |
| MCP missing / 401 / not found | any | Stop + paste. No URL-only stub |
| Prose AC that mentions `PROJ-1` | n/a | No fetch; treat as pasted AC |

## Pipeline finale tokens

After a **draft** PR exists, `create-pr` must AskQuestion **Pipeline finale**:

| Token | Shown | Effect |
|-------|-------|--------|
| `keep_draft` | always | Draft stays draft (Jira stays In Progress) |
| `ready` | always | `gh pr ready` + `jira-transition` target `review` when key known |
| `keep_draft_jira` | only if `jira_key` known | Draft + `addCommentToJiraIssue` (PR URL); no Review transition |
| `ready_jira` | only if `jira_key` known | Ready + Jira comment + `jira-transition` target `review` |

Forbidden: inventing transition ids, `gh pr merge`, review approve, opening ready-for-review before this HITL, transitioning from `/write-tech-spec`.

After a successful `/start-task` or `/start-issue-task` fetch: `jira-transition` target `in_progress` (skip if already there; failure does not stop the pipeline).

## Capture-escape

`/capture-escape` → HITL **Capture-escape destination**. `miss` → `teach-review`. `project_secret` → `review-learn` `mode:capture` `source: production-escape`. No `engineer-reviewer`. No **Review-learn promote** on `project_secret`.

## Canvas

Open `docs/superpowers/pipeline-flow.html`: overview shows **Jira fetch + router** before bootstrap, **create-pr** as HITL (not automatic-only), layers Plan → Build → Review, and **review-gate** after `software-developer` (not a return to the plan layer).
