#!/usr/bin/env bash
# Verdicts for Jira Review: every pull request merged and every build succeeded.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../pr-merge-ci.sh
source "$ROOT/scripts/pr-merge-ci.sh"

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

verdict() {
  printf '%s' "$1" | pr_merge_ci_verdict
}

assert_eq empty_array "no_pull_requests" "$(verdict '[]')"
assert_eq empty_stdin "no_pull_requests" "$(printf '' | pr_merge_ci_verdict)"

assert_eq one_open "not_merged" "$(verdict '{"state":"OPEN","url":"https://example.com/1","statusCheckRollup":[]}')"

assert_eq mixed_open_merged "not_merged" "$(verdict '[
  {"state":"MERGED","url":"https://example.com/1","statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]},
  {"state":"OPEN","url":"https://example.com/2","statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]}
]')"

assert_eq closed_unmerged "closed_unmerged" "$(verdict '{"state":"CLOSED","url":"https://example.com/1","statusCheckRollup":[]}')"

assert_eq closed_beats_open "closed_unmerged" "$(verdict '[
  {"state":"OPEN","url":"https://example.com/1","statusCheckRollup":[]},
  {"state":"CLOSED","url":"https://example.com/2","statusCheckRollup":[]}
]')"

assert_eq all_merged_no_checks "all_merged_ci_success" "$(verdict '{"state":"MERGED","url":"https://example.com/1","statusCheckRollup":[]}')"

assert_eq all_merged_success "all_merged_ci_success" "$(verdict '[
  {"state":"MERGED","url":"https://example.com/1","statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]},
  {"state":"MERGED","url":"https://example.com/2","statusCheckRollup":[{"name":"lint","status":"COMPLETED","conclusion":"SUCCESS"}]}
]')"

assert_eq skipped_and_success "all_merged_ci_success" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[
    {"name":"build","status":"COMPLETED","conclusion":"SUCCESS"},
    {"name":"optional","status":"COMPLETED","conclusion":"SKIPPED"},
    {"name":"coverage","status":"COMPLETED","conclusion":"NEUTRAL"}
  ]
}')"

assert_eq one_failure "ci_failed" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[
    {"name":"build","status":"COMPLETED","conclusion":"SUCCESS"},
    {"name":"e2e","status":"COMPLETED","conclusion":"FAILURE"}
  ]
}')"

assert_eq timed_out "ci_failed" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"TIMED_OUT"}]
}')"

assert_eq pending_check "pending_ci" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[
    {"name":"build","status":"COMPLETED","conclusion":"SUCCESS"},
    {"name":"e2e","status":"IN_PROGRESS","conclusion":null}
  ]
}')"

assert_eq queued_check "pending_ci" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[{"name":"build","status":"QUEUED","conclusion":null}]
}')"

assert_eq failed_beats_pending "ci_failed" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[
    {"name":"build","status":"COMPLETED","conclusion":"FAILURE"},
    {"name":"e2e","status":"IN_PROGRESS","conclusion":null}
  ]
}')"

assert_eq not_merged_beats_failed "not_merged" "$(verdict '[
  {"state":"OPEN","url":"https://example.com/1","statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"FAILURE"}]},
  {"state":"MERGED","url":"https://example.com/2","statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]}
]')"

assert_eq commit_status_success "all_merged_ci_success" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[{"context":"ci/jenkins","state":"SUCCESS"}]
}')"

assert_eq commit_status_failure "ci_failed" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[{"context":"ci/jenkins","state":"FAILURE"}]
}')"

assert_eq commit_status_pending "pending_ci" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[{"context":"ci/jenkins","state":"PENDING"}]
}')"

assert_eq completed_null_conclusion "pending_ci" "$(verdict '{
  "state":"MERGED",
  "url":"https://example.com/1",
  "statusCheckRollup":[{"name":"build","status":"COMPLETED","conclusion":null}]
}')"

assert_eq script_as_program "all_merged_ci_success" "$(printf '%s' '{"state":"MERGED","url":"https://example.com/1","statusCheckRollup":[]}' | bash "$ROOT/scripts/pr-merge-ci.sh")"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
