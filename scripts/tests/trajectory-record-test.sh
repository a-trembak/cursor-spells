#!/usr/bin/env bash
# Recorder ledger for agent-trajectory score.
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

assert_command_error() {
  local name="$1" pattern="$2"
  shift 2
  local actual=0 out
  out="$("$@" 2>&1)" || actual=$?
  assert_eq "${name}_exit" 1 "$actual"
  if grep -F -q -- "$pattern" <<<"$out"; then
    echo "OK   ${name}_message"
  else
    echo "FAIL ${name}_message: [$pattern] not in output:" >&2
    echo "$out" >&2
    fail=1
  fi
  if grep -F -q -- "Traceback" <<<"$out"; then
    echo "FAIL ${name}_no_traceback: traceback in output:" >&2
    echo "$out" >&2
    fail=1
  else
    echo "OK   ${name}_no_traceback"
  fi
}

REC=(python3 "$ROOT/scripts/trajectory-cases.py" record)
SCORE=(python3 "$ROOT/scripts/trajectory-cases.py" score --kit-root "$ROOT")

if ! python3 "$ROOT/scripts/trajectory-cases.py" record --help >/dev/null 2>&1; then
  echo "FAIL missing record subcommand" >&2
  exit 1
fi
echo "OK   record_help"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LEDGER="$TMP/fetch.json"

MISSING="$TMP/missing.json"
assert_command_error missing_stage "ledger file does not exist" \
  "${REC[@]}" stage --ledger "$MISSING" jira-fetch
assert_command_error missing_dump "ledger file does not exist" \
  "${REC[@]}" dump --ledger "$MISSING"

MISSING_CLASS="$TMP/missing-class.json"
assert_exit init_ok_requires_jira_class 1 "${REC[@]}" init \
  --ledger "$MISSING_CLASS" \
  --case-id create-pr-draft-never-merge \
  --invocation "skill create-pr" \
  --fetch ok
if [[ -e "$MISSING_CLASS" ]]; then
  echo "FAIL init_ok_requires_jira_class_no_ledger: ledger was created" >&2
  fail=1
else
  echo "OK   init_ok_requires_jira_class_no_ledger"
fi

assert_exit init_fetch 0 "${REC[@]}" init \
  --ledger "$LEDGER" \
  --case-id fetch-failure-stops \
  --invocation "/csp-start-task PROJ-1" \
  --fetch fail

python3 - "$LEDGER" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
assert data["stages_entered"] == []
assert data["end"]["pull_request"] == "absent"
assert "jira_class" not in data["input"] or data["input"].get("jira_class") is None
print("OK   init_shape")
PY

assert_exit stage_fetch 0 "${REC[@]}" stage --ledger "$LEDGER" jira-fetch
assert_exit dump_partial 0 "${REC[@]}" dump --ledger "$LEDGER" --out "$TMP/partial.json"

# Partial run is a valid record but must FAIL the case (missing stop-paste-ticket).
assert_exit score_partial 1 "${SCORE[@]}" --run "$TMP/partial.json"
assert_grep_out score_partial_line "FAIL fetch-failure-stops: required_artifacts" \
  "${SCORE[@]}" --run "$TMP/partial.json"

assert_exit artifact 0 "${REC[@]}" artifact --ledger "$LEDGER" --kind report --name stop-paste-ticket
assert_exit end_absent 0 "${REC[@]}" end --ledger "$LEDGER" \
  --pull-request absent --review-report absent --jira-status null
assert_exit dump_full 0 "${REC[@]}" dump --ledger "$LEDGER" --out "$TMP/full.json"
assert_exit score_full 0 "${SCORE[@]}" --run "$TMP/full.json"
assert_grep_out score_full_line "PASS fetch-failure-stops" "${SCORE[@]}" --run "$TMP/full.json"

assert_exit bad_stage 1 "${REC[@]}" stage --ledger "$LEDGER" not-a-stage

ACTION="$TMP/action.json"
assert_exit action_init 0 "${REC[@]}" init \
  --ledger "$ACTION" \
  --case-id fetch-failure-stops \
  --invocation "/csp-start-task PROJ-1" \
  --fetch fail
assert_exit action_append 0 "${REC[@]}" action --ledger "$ACTION" merge-pull-request
assert_exit action_duplicate 0 "${REC[@]}" action --ledger "$ACTION" merge-pull-request
python3 - "$ACTION" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
assert data["actions_taken"] == ["merge-pull-request"]
print("OK   action_duplicate_no_dup")
PY
assert_exit action_unknown 1 "${REC[@]}" action --ledger "$ACTION" not-an-action

# create-pr slice: fetch ok requires jira_class; score after gate tokens, still draft.
CPR="$TMP/cpr.json"
assert_exit init_cpr 0 "${REC[@]}" init \
  --ledger "$CPR" \
  --case-id create-pr-draft-never-merge \
  --invocation "skill create-pr" \
  --fetch ok \
  --jira-class feature
assert_exit cpr_stage1 0 "${REC[@]}" stage --ledger "$CPR" create-pr
assert_exit cpr_stage2 0 "${REC[@]}" stage --ledger "$CPR" pipeline-finale-hitl
assert_exit cpr_art 0 "${REC[@]}" artifact --ledger "$CPR" --kind github --name draft-pull-request
assert_exit cpr_gate 0 "${REC[@]}" gate --ledger "$CPR" --gate pipeline-finale \
  --tokens keep_draft,ready,keep_draft_jira,ready_jira
assert_exit cpr_end 0 "${REC[@]}" end --ledger "$CPR" \
  --pull-request draft --review-report absent --jira-status "In Progress"
assert_exit cpr_dump 0 "${REC[@]}" dump --ledger "$CPR"
assert_exit cpr_score 0 "${SCORE[@]}" --run "$CPR"

READY_OBSERVED="$TMP/cpr-ready-observed.json"
cp "$CPR" "$READY_OBSERVED"
assert_exit ready_observed_end 0 "${REC[@]}" end --ledger "$READY_OBSERVED" \
  --pull-request ready --review-report absent --jira-status "In Progress"
assert_exit ready_observed_dump 0 "${REC[@]}" dump --ledger "$READY_OBSERVED"
assert_exit ready_observed_score 1 "${SCORE[@]}" --run "$READY_OBSERVED"
assert_grep_out ready_observed_line \
  "FAIL create-pr-draft-never-merge: expected_end .*pull_request case='draft' run='ready'" \
  "${SCORE[@]}" --run "$READY_OBSERVED"

# Marking ready without recording the gate must fail open-ready-before-finale.
BAD="$TMP/ready-early.json"
assert_exit init_bad 0 "${REC[@]}" init \
  --ledger "$BAD" \
  --case-id create-pr-draft-never-merge \
  --invocation "skill create-pr" \
  --fetch ok \
  --jira-class feature
assert_exit bad_st 0 "${REC[@]}" stage --ledger "$BAD" create-pr
assert_exit bad_art 0 "${REC[@]}" artifact --ledger "$BAD" --kind github --name draft-pull-request
assert_exit bad_end 0 "${REC[@]}" end --ledger "$BAD" \
  --pull-request ready --review-report absent --jira-status "In Progress"
assert_exit bad_dump 0 "${REC[@]}" dump --ledger "$BAD"
assert_exit bad_score 1 "${SCORE[@]}" --run "$BAD"
assert_grep_out bad_line "forbidden:open-ready-before-finale" "${SCORE[@]}" --run "$BAD"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
