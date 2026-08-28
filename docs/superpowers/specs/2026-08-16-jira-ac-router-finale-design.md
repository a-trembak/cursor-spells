# Jira AC fetch, pipeline router, PR finale

## Status

`approved` — implementation target for cursor-spells kit (closes remaining workflow gaps named after the per-plan gates work).

## Goal

1. Full and fast `/start-task` **fetch** Jira ticket text via Atlassian MCP when the AC source is a key or browse URL — never invent AC, never treat a URL as a stub.
2. **Route** mechanically among full / fast / issue so a Bug ticket does not silently take the feature path, and `--fast` is never chosen automatically.
3. After `create-pr` opens a **draft** PR, one HITL gate can mark it ready and/or comment the PR URL on Jira. Never merge. **Status transitions** are specified in [`2026-08-19-jira-status-transitions-design.md`](2026-08-19-jira-status-transitions-design.md) (In Progress on start; Review after every opened pull request is merged and continuous integration succeeded).
4. Thin `/capture-escape` entry for production misses → `review-learn` `mode:capture` `source:production-escape`.

## Decisions

| Decision | Choice |
|----------|--------|
| Shared parse helper | `scripts/jira-issue.sh` (key, site, looks-like, type class) |
| Shared fetch skill | `jira-fetch` — Atlassian MCP; stop + paste on failure |
| Auto-route | `/start-task` + classified **bug** → issue pipeline (no extra HITL) |
| Never auto-fast | `--fast` is explicit only |
| `--fast` + bug | HITL `issue` / `stay_fast` |
| Jira type unknown | HITL `full` / `fast` / `issue` |
| `/start-issue-task` | Always issue path even if type is Story |
| PR finale | One HITL after draft exists; default `keep_draft` |
| Jira write | Comment with PR URL; status moves as in the 2026-08-19 transitions spec |
| Writing AC | Still out of scope |

## Jira fetch

Trigger when `jira_looks_like_issue` is true (bare `PROJ-123` or `*.atlassian.net` URL with a key). Prose that happens to mention a key is **not** a fetch.

1. `jira_extract_key` / `jira_extract_site`.
2. `cloudId`: URL hostname first (`site.atlassian.net`); else `getAccessibleAtlassianResources` and try until `getJiraIssue` succeeds.
3. `getJiraIssue` with `responseContentFormat: markdown`. Use summary, description, issuetype, status. Do not invent missing description.
4. Assemble AC text: key, summary, type, status, description. Record the ticket as an AC reference.
5. Classify issuetype name via `jira_classify_type`:
   - **bug:** Bug, Defect, Fault, Incident, Problem, Error
   - **feature:** Story, Task, Feature, New Feature, Epic, Improvement, Change Request
   - **unknown:** everything else (Spike, Sub-task, empty)
6. MCP missing/unauthenticated/error: **stop**. Ask to paste ticket text. Do not continue on a URL-only stub.

`/write-tech-spec` uses the same fetch when its AC source looks like a Jira issue.

## Router (`/start-task`)

After bootstrap + optional fetch:

| Signal | Path |
|--------|------|
| `--fast` and class `bug` | HITL **Fast vs issue**: `issue` / `stay_fast` |
| `--fast` and not bug | Fast pipeline (fetched AC if any) |
| no `--fast` and class `bug` | Run `/start-issue-task` pipeline (reuse fetched issue; do not re-fetch) |
| no `--fast` and class `feature` or non-Jira AC | Full pipeline |
| no `--fast` and class `unknown` (Jira) | HITL **Pipeline route**: `full` / `fast` / `issue` |
| Explicit `/start-issue-task` | Issue pipeline always |

Still stop if no AC exist after fetch/paste. Still never write AC.

Mid-flight `--fast` rules unchanged: if work is clearly large, stop and recommend full or issue.

## PR finale (`create-pr`)

Steps 1–7 unchanged (always create/reuse **draft** first). Then:

**HITL Pipeline finale** via `hitl-choice` (AskQuestion required):

| id | When shown | Effect |
|----|------------|--------|
| `keep_draft` | always | Stop. Draft stays draft. |
| `ready` | always | `gh pr ready` per opened PR. |
| `keep_draft_jira` | Jira key known | Draft + Jira comment with PR URL(s). |
| `ready_jira` | Jira key known | Ready + Jira comment. |

Comment body: PR URL(s) + one-line summary. `addCommentToJiraIssue` for `*_jira`. `ready` / `ready_jira` do **not** run `jira-transition` on the token itself. When a key is known, wait until `pr_merge_ci_verdict` is `all_merged_ci_success`, then run `jira-transition` target `review`. If comment fails, report and do not retry as a transition. Never merge. Never approve reviews.

## Capture-escape

Command `/capture-escape`: ask HITL **Capture-escape destination**. `miss` → skill `teach-review`. `project_secret` → `review-learn` `mode:capture` with `source: production-escape`. Does not run engineer-review. Store routing: [`2026-08-21-review-learn-project-secret-design.md`](2026-08-21-review-learn-project-secret-design.md).

## Out of scope

Writing AC; auto-installing skills; merge (the agent still never `gh pr merge`; it observes merge + build success); deploy; a11y/i18n phases; Linear fetch; multi-repo ticket→repo discovery (still v1.1). Jira status transitions: see 2026-08-19 spec.

## New/changed artifacts

- `scripts/jira-issue.sh` + `scripts/tests/jira-issue-test.sh`
- `scripts/pr-merge-ci.sh` + `scripts/tests/pr-merge-ci-test.sh`
- `skills/jira-fetch/SKILL.md`
- `commands/start-task.md`, `commands/start-issue-task.md`, `commands/write-tech-spec.md`
- `skills/create-pr/SKILL.md`, `skills/hitl-choice/SKILL.md`
- `commands/capture-escape.md`
- `scripts/install-to-project.sh`, README, pipeline-flow.md/html, dogfood checklist
