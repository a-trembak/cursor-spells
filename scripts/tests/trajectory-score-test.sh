#!/usr/bin/env bash
# Score a recorded run against a golden-set case (hard sensors only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL $name: expected [$expected] got [$actual]" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_exit() {
  local name="$1" expected="$2"
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  assert_eq "$name" "$expected" "$actual"
}

assert_grep_out() {
  local name="$1" pattern="$2"
  shift 2
  local out
  out="$("$@" 2>&1 || true)"
  if grep -E -q "$pattern" <<<"$out"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in output:" >&2
    echo "$out" >&2
    fail=1
  fi
}

SCORE=(python3 "$ROOT/scripts/trajectory-cases.py" score --kit-root "$ROOT")

if ! python3 "$ROOT/scripts/trajectory-cases.py" score --help >/dev/null 2>&1; then
  echo "FAIL missing score subcommand" >&2
  exit 1
fi
echo "OK   score_help"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

write_json() {
  python3 -c 'import json,sys; json.dump(json.loads(sys.stdin.read()), open(sys.argv[1],"w"), indent=2)' "$1"
}

route_pass="$TMP/route-unknown-pass.json"
write_json "$route_pass" <<'JSON'
{
  "case_id": "route-unknown-asks-human",
  "input": {
    "invocation": "/start-task PROJ-1",
    "fetch": "ok",
    "jira_class": "unknown"
  },
  "stages_entered": ["jira-fetch", "jira-transition-in-progress", "pipeline-route-hitl"],
  "artifacts_present": [{"kind": "jira", "name": "in-progress"}],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "pipeline-route", "tokens_offered": ["issue", "full", "fast"]}
  ],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON

assert_exit pass_route_unknown 0 "${SCORE[@]}" --run "$route_pass"
assert_grep_out pass_route_unknown_line "PASS route-unknown-asks-human" "${SCORE[@]}" --run "$route_pass"

# Missing required stage
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["stages_entered"]=["jira-fetch"]; json.dump(d, open(p,"w"))' "$route_pass"
assert_exit missing_stage 1 "${SCORE[@]}" --run "$route_pass"
assert_grep_out missing_stage_sensor "FAIL route-unknown-asks-human: required_stages" "${SCORE[@]}" --run "$route_pass"

# Restore and ask a forbidden gate
write_json "$route_pass" <<'JSON'
{
  "case_id": "route-unknown-asks-human",
  "input": {
    "invocation": "/start-task PROJ-1",
    "fetch": "ok",
    "jira_class": "unknown"
  },
  "stages_entered": ["jira-fetch", "jira-transition-in-progress", "pipeline-route-hitl"],
  "artifacts_present": [{"kind": "jira", "name": "in-progress"}],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "pipeline-route", "tokens_offered": ["full", "fast", "issue"]},
    {"gate": "fast-vs-issue", "tokens_offered": ["issue", "stay_fast"]}
  ],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit must_not_ask 1 "${SCORE[@]}" --run "$route_pass"
assert_grep_out must_not_ask_sensor "FAIL route-unknown-asks-human: agent_must_not_ask" "${SCORE[@]}" --run "$route_pass"

# Merge observed
create_run="$TMP/create-pr.json"
write_json "$create_run" <<'JSON'
{
  "case_id": "create-pr-draft-never-merge",
  "input": {
    "invocation": "skill create-pr",
    "fetch": "ok",
    "jira_class": "feature"
  },
  "stages_entered": ["create-pr", "pipeline-finale-hitl"],
  "artifacts_present": [{"kind": "github", "name": "draft-pull-request"}],
  "actions_taken": ["merge-pull-request"],
  "human_gates_asked": [
    {"gate": "pipeline-finale", "tokens_offered": ["keep_draft", "ready", "keep_draft_jira", "ready_jira"]}
  ],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "draft",
    "review_report": "absent"
  }
}
JSON
assert_exit merge_forbidden 1 "${SCORE[@]}" --run "$create_run"
assert_grep_out merge_sensor "FAIL create-pr-draft-never-merge: forbidden:merge-pull-request" "${SCORE[@]}" --run "$create_run"

# Ready without asking finale (inferred)
write_json "$create_run" <<'JSON'
{
  "case_id": "create-pr-draft-never-merge",
  "input": {
    "invocation": "skill create-pr",
    "fetch": "ok",
    "jira_class": "feature"
  },
  "stages_entered": ["create-pr"],
  "artifacts_present": [{"kind": "github", "name": "draft-pull-request"}],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "ready",
    "review_report": "absent"
  }
}
JSON
assert_exit ready_before_finale 1 "${SCORE[@]}" --run "$create_run"
assert_grep_out ready_sensor "FAIL create-pr-draft-never-merge: forbidden:open-ready-before-finale" "${SCORE[@]}" --run "$create_run"

# writing-plans after review-gate
fixes_run="$TMP/fixes.json"
write_json "$fixes_run" <<'JSON'
{
  "case_id": "review-gate-fixes-to-build",
  "input": {
    "invocation": "/finish-plan",
    "fetch": "skip"
  },
  "stages_entered": ["review-gate", "writing-plans", "software-developer"],
  "artifacts_present": [{"kind": "gate", "name": "review-gate"}],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "review-gate", "tokens_offered": ["skip", "approve", "done", "fixes"]}
  ],
  "end": {
    "jira_status": null,
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit fixes_to_plan 1 "${SCORE[@]}" --run "$fixes_run"
assert_grep_out fixes_sensor "FAIL review-gate-fixes-to-build: forbidden:fixes-returns-to-writing-plans" "${SCORE[@]}" --run "$fixes_run"

# fetch fail then continued
fetch_run="$TMP/fetch-fail.json"
write_json "$fetch_run" <<'JSON'
{
  "case_id": "fetch-failure-stops",
  "input": {
    "invocation": "/start-task PROJ-1",
    "fetch": "fail"
  },
  "stages_entered": ["jira-fetch", "bootstrap", "tech-spec"],
  "artifacts_present": [{"kind": "report", "name": "stop-paste-ticket"}],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {
    "jira_status": null,
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit fetch_continued 1 "${SCORE[@]}" --run "$fetch_run"
assert_grep_out fetch_sensor "FAIL fetch-failure-stops: forbidden:url-only-stub-on-fetch-failure" "${SCORE[@]}" --run "$fetch_run"

# start-build without critique-clear (full-happy-path forbids that action)
full_run="$TMP/full.json"
write_json "$full_run" <<'JSON'
{
  "case_id": "full-happy-path",
  "input": {
    "invocation": "/start-task PROJ-1",
    "fetch": "ok",
    "jira_class": "feature"
  },
  "stages_entered": [
    "jira-fetch",
    "jira-transition-in-progress",
    "bootstrap",
    "tech-spec",
    "writing-plans",
    "approve-plan",
    "implementation-critic",
    "start-build",
    "software-developer",
    "review-gate",
    "engineer-review",
    "update-docs",
    "create-pr",
    "pipeline-finale-hitl"
  ],
  "artifacts_present": [
    {"kind": "file", "name": "tech-spec"},
    {"kind": "file", "name": "implementation-plan"},
    {"kind": "git", "name": "feature-branch"},
    {"kind": "github", "name": "draft-pull-request"},
    {"kind": "report", "name": "engineer-review"}
  ],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "tech-spec-entry", "tokens_offered": ["human", "agent"]},
    {"gate": "tech-spec-gate", "tokens_offered": ["approve-spec", "revise", "skip"]},
    {"gate": "approve-plan", "tokens_offered": ["approve-plan", "revise"]},
    {"gate": "review-gate", "tokens_offered": ["skip", "approve", "done", "fixes"]},
    {"gate": "docs-update", "tokens_offered": ["skip", "docs_md", "docs_repo", "confluence"]},
    {"gate": "pipeline-finale", "tokens_offered": ["keep_draft", "ready", "keep_draft_jira", "ready_jira"]},
    {"gate": "teach-review-miss", "tokens_offered": ["miss", "no_miss"]}
  ],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "draft",
    "review_report": "evidence-gated"
  }
}
JSON
assert_exit no_critique_clear 1 "${SCORE[@]}" --run "$full_run"
assert_grep_out no_clear_sensor "FAIL full-happy-path: forbidden:start-build-without-critique-clear" "${SCORE[@]}" --run "$full_run"
assert_grep_out missing_artifact_sensor "FAIL full-happy-path: required_artifacts" "${SCORE[@]}" --run "$full_run"

# Wrong human tokens
write_json "$route_pass" <<'JSON'
{
  "case_id": "route-unknown-asks-human",
  "input": {
    "invocation": "/start-task PROJ-1",
    "fetch": "ok",
    "jira_class": "unknown"
  },
  "stages_entered": ["jira-fetch", "jira-transition-in-progress", "pipeline-route-hitl"],
  "artifacts_present": [{"kind": "jira", "name": "in-progress"}],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "pipeline-route", "tokens_offered": ["full", "fast"]}
  ],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit wrong_tokens 1 "${SCORE[@]}" --run "$route_pass"
assert_grep_out wrong_tokens_sensor "FAIL route-unknown-asks-human: human_must_appear" "${SCORE[@]}" --run "$route_pass"

# Input mismatch
write_json "$route_pass" <<'JSON'
{
  "case_id": "route-unknown-asks-human",
  "input": {
    "invocation": "/start-task --fast PROJ-1",
    "fetch": "ok",
    "jira_class": "unknown"
  },
  "stages_entered": ["jira-fetch", "jira-transition-in-progress", "pipeline-route-hitl"],
  "artifacts_present": [{"kind": "jira", "name": "in-progress"}],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "pipeline-route", "tokens_offered": ["full", "fast", "issue"]}
  ],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit input_mismatch 1 "${SCORE[@]}" --run "$route_pass"
assert_grep_out input_sensor "FAIL route-unknown-asks-human: input" "${SCORE[@]}" --run "$route_pass"

# Invalid run (unknown stage) is exit 1
write_json "$route_pass" <<'JSON'
{
  "case_id": "route-unknown-asks-human",
  "input": {
    "invocation": "/start-task PROJ-1",
    "fetch": "ok",
    "jira_class": "unknown"
  },
  "stages_entered": ["not-a-stage"],
  "artifacts_present": [{"kind": "jira", "name": "in-progress"}],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {
    "jira_status": "In Progress",
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit invalid_run 1 "${SCORE[@]}" --run "$route_pass"

# Gate with omitted tokens: any non-empty offer PASSes; missing gate FAILs
any_token_case="$TMP/any-token-slice.json"
write_json "$any_token_case" <<'JSON'
{
  "id": "any-token-slice",
  "title": "Temp case for any-token human gates",
  "source": "docs/superpowers/specs/2026-08-25-agent-trajectory-golden-set-design.md",
  "pipeline": "slice",
  "end_to_end": false,
  "status": "active",
  "input": {"invocation": "/critique-plan", "fetch": "skip"},
  "required_stages": ["implementation-critic"],
  "required_artifacts": [{"kind": "report", "name": "critic-verdict-blocked"}],
  "forbidden": ["edit-plan-during-critic"],
  "human_must_appear": [{"gate": "critic-blocked"}],
  "agent_must_not_ask": ["review-gate"],
  "expected_end": {
    "jira_status": null,
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
any_token_run="$TMP/any-token-run.json"
write_json "$any_token_run" <<'JSON'
{
  "case_id": "any-token-slice",
  "input": {"invocation": "/critique-plan", "fetch": "skip"},
  "stages_entered": ["implementation-critic"],
  "artifacts_present": [{"kind": "report", "name": "critic-verdict-blocked"}],
  "actions_taken": [],
  "human_gates_asked": [
    {"gate": "critic-blocked", "tokens_offered": ["revise", "accept F1"]}
  ],
  "end": {
    "jira_status": null,
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit pass_any_tokens 0 "${SCORE[@]}" --case "$any_token_case" --run "$any_token_run"
assert_grep_out pass_any_tokens_line "PASS any-token-slice" "${SCORE[@]}" --case "$any_token_case" --run "$any_token_run"

write_json "$any_token_run" <<'JSON'
{
  "case_id": "any-token-slice",
  "input": {"invocation": "/critique-plan", "fetch": "skip"},
  "stages_entered": ["implementation-critic"],
  "artifacts_present": [{"kind": "report", "name": "critic-verdict-blocked"}],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {
    "jira_status": null,
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
assert_exit fail_any_tokens_missing 1 "${SCORE[@]}" --case "$any_token_case" --run "$any_token_run"
assert_grep_out fail_any_tokens_missing_line "FAIL any-token-slice: human_must_appear" "${SCORE[@]}" --case "$any_token_case" --run "$any_token_run"

# Committed pass fixtures
PASS_DIR="$ROOT/evals/trajectories/fixtures/pass"
if [[ ! -d "$PASS_DIR" ]]; then
  echo "FAIL missing $PASS_DIR" >&2
  fail=1
else
  echo "OK   pass_fixtures_dir"
  assert_exit pass_dir 0 "${SCORE[@]}" --runs-dir "$PASS_DIR"
  pass_count="$(find "$PASS_DIR" -name '*.json' | wc -l | tr -d ' ')"
  if [[ "$pass_count" -lt 4 ]]; then
    echo "FAIL pass_fixture_count: expected at least 4 got $pass_count" >&2
    fail=1
  else
    echo "OK   pass_fixture_count ($pass_count)"
  fi
  missing_fixtures=0
  for case_path in "$ROOT/evals/trajectories/cases"/*.json; do
    case_id="$(basename "$case_path" .json)"
    status="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("status",""))' "$case_path")"
    if [[ "$status" != "active" ]]; then
      continue
    fi
    fixture="$PASS_DIR/${case_id}.json"
    if [[ ! -f "$fixture" ]]; then
      echo "FAIL missing pass fixture for active case $case_id" >&2
      missing_fixtures=1
      fail=1
    fi
  done
  if [[ "$missing_fixtures" -eq 0 ]]; then
    echo "OK   pass_fixture_per_active_case"
  fi
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
