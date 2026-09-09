#!/usr/bin/env bash
# Contract tests for scripts/harness-bench.sh (isolated fake suite — not full kit bench).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BENCH="$ROOT/scripts/harness-bench.sh"
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

assert_contains() {
  local name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "OK   $name"
  else
    echo "FAIL $name: [$needle] not in output" >&2
    fail=1
  fi
}

json_field() {
  local json="$1" expr="$2"
  printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print($expr)"
}

if [[ ! -f "$BENCH" ]]; then
  echo "FAIL script_missing: $BENCH" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_TESTS="$TMP/tests"
FAKE_REPORTS="$TMP/reports"
mkdir -p "$FAKE_TESTS" "$FAKE_REPORTS"

# Pass case: one green shell test; trajectory steps still hit real kit (needed for green validate/score)
cat >"$FAKE_TESTS/ok.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
chmod +x "$FAKE_TESTS/ok.sh"

set +e
HARNESS_TESTS_DIR="$FAKE_TESTS" HARNESS_REPORTS_DIR="$FAKE_REPORTS" \
  bash "$BENCH" >"$TMP/pass.out" 2>"$TMP/pass.err"
pass_code=$?
set -e
assert_eq pass_exit "0" "$pass_code"

reports=( "$FAKE_REPORTS"/*.json )
assert_eq pass_report_count "1" "${#reports[@]}"
pass_json="$(cat "${reports[0]}")"
assert_eq pass_ok "True" "$(json_field "$pass_json" 'd["ok"]')"
assert_eq pass_failed "0" "$(json_field "$pass_json" 'd["failed_count"]')"
assert_contains pass_has_ok_test "$(json_field "$pass_json" '" ".join(t["name"] for t in d["tests"])')" "ok.sh"
assert_contains pass_has_validate "$(json_field "$pass_json" '" ".join(t["name"] for t in d["tests"])')" "trajectory-validate"
assert_contains pass_has_score "$(json_field "$pass_json" '" ".join(t["name"] for t in d["tests"])')" "trajectory-score-fixtures"

# Fail case: child test fails → non-zero exit + ok=false
rm -f "$FAKE_REPORTS"/*.json
cat >"$FAKE_TESTS/bad.sh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$FAKE_TESTS/bad.sh"

set +e
HARNESS_TESTS_DIR="$FAKE_TESTS" HARNESS_REPORTS_DIR="$FAKE_REPORTS" \
  bash "$BENCH" >"$TMP/fail.out" 2>"$TMP/fail.err"
fail_code=$?
set -e
assert_eq fail_exit_nonzero "1" "$([[ "$fail_code" -ne 0 ]] && echo 1 || echo 0)"

fail_reports=( "$FAKE_REPORTS"/*.json )
assert_eq fail_report_count "1" "${#fail_reports[@]}"
fail_json="$(cat "${fail_reports[0]}")"
assert_eq fail_ok "False" "$(json_field "$fail_json" 'd["ok"]')"
bad_status="$(json_field "$fail_json" 'next(t["status"] for t in d["tests"] if t["name"]=="bad.sh")')"
assert_eq bad_status_fail "fail" "$bad_status"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL TESTS PASSED"
exit 0
