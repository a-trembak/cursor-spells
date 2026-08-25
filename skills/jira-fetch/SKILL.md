---
name: jira-fetch
description: >-
  Fetch a Jira issue via Atlassian MCP and assemble AC text. Use from
  /start-task, /start-issue-task, or /write-tech-spec when the AC source is a
  Jira key or atlassian.net URL. Never invents ticket contents. Stops if MCP
  fails.
---

# Jira Fetch

Load a Jira issue as Acceptance Criteria / bug source of truth. Parsing uses `scripts/jira-issue.sh` (consumer copy after `csp update`, or kit path).

## When to Use

- `/start-task` / `--fast` / `/write-tech-spec` when the AC source looks like a Jira issue
- `/start-issue-task` (always — this is the fetch step)
- Not for writing AC, Linear, or inventing description text

## Detect

Source `scripts/jira-issue.sh`, then:

1. `jira_looks_like_issue "<source>"` must be true (bare `PROJ-123` **or** `*.atlassian.net` URL). A prose paragraph that merely mentions a key is **not** a fetch — use it as pasted AC.
2. `jira_extract_key` → `ISSUE_KEY`. If that fails, stop (not a Jira source).
3. `jira_extract_site` → optional hostname for `cloudId`.

## Fetch (mandatory order)

1. Discover Atlassian MCP tools (`GetMcpTools` / schema helpers). Required: `getJiraIssue`. For comments later, `addCommentToJiraIssue` is **not** required here.
2. Resolve `cloudId`:
   - If the source URL has a site hostname, pass that hostname first (`ex.atlassian.net`).
   - On failure, call `getAccessibleAtlassianResources` and retry `getJiraIssue` per cloud until one succeeds.
3. Call `getJiraIssue` with `issueIdOrKey`, `cloudId`, `responseContentFormat: "markdown"`. Prefer fields `summary`, `description`, `issuetype`, `status` (defaults are fine).
4. **On any MCP/auth/not-found failure: stop.** Ask the human to paste the ticket text (summary + description + AC). Do not continue on a URL-only stub. Do not invent fields.

On that stop, if a kit checkout is known, record and score case `fetch-failure-stops`. Skip score when the kit path, scorer, or ledger is missing (still stop for pasted ticket text).

```bash
KIT="$(tr -d '\n' < .cursor/cursor-spells-kit-path 2>/dev/null || true)"
# else ~/.cursor/cursor-spells-kit-path
LEDGER=".cursor/gates/trajectory-run/fetch-failure-stops.json"
python3 "$KIT/scripts/trajectory-cases.py" record init \
  --ledger "$LEDGER" --case-id fetch-failure-stops \
  --invocation "/start-task PROJ-1" --fetch fail
python3 "$KIT/scripts/trajectory-cases.py" record stage --ledger "$LEDGER" jira-fetch
python3 "$KIT/scripts/trajectory-cases.py" record artifact --ledger "$LEDGER" \
  --kind report --name stop-paste-ticket
python3 "$KIT/scripts/trajectory-cases.py" record dump --ledger "$LEDGER"
python3 "$KIT/scripts/trajectory-cases.py" score --kit-root "$KIT" --run "$LEDGER"
```

If score prints `FAIL`, print its `FAIL` lines and stop. Do not continue bootstrap. Do not ask Pipeline route. Do not invent acceptance criteria. If score prints `PASS` or score was skipped, still wait for pasted ticket text. In chat, say in one full sentence when trajectory score was skipped.

Use the real invocation string from the chat when it is a `/start-task` key. If the caller was `/start-issue-task` or `/write-tech-spec`, skip this case because its input would not match; still stop for pasted ticket text and skip score.

## Assemble AC text

Do not add requirements that are not in the ticket.

```markdown
# <KEY>: <summary>
Type: <issuetype name>
Status: <status name>

## Description
<description or "(empty)">
```

If both description and summary are empty, treat as fetch failure (paste).

## Classify

`class="$(jira_classify_type "<issuetype name>")"` → `bug` | `feature` | `unknown`.

## Output (handoff)

Pass to the caller (do not start tech-spec or bug-fixer yourself):

| Field | Value |
|-------|--------|
| `jira_key` | Uppercased key |
| `jira_site` | Hostname or empty |
| `jira_cloud_id` | The `cloudId` that worked |
| `jira_type` | Issuetype display name |
| `jira_class` | `bug` / `feature` / `unknown` |
| `jira_status` | Status name |
| `ac_text` | Assembled markdown above |
| `browse_url` | Source URL if it was a URL, else empty |

Record `jira_key` (and browse URL when known) as the tech-spec **AC references** entry. The assembled `ac_text` is the AC body — not a stub link.

Callers `/start-task` and `/start-issue-task` next invoke skill `jira-transition` target `in_progress`. `/write-tech-spec` does not.
