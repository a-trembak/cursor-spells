#!/usr/bin/env bash
# Contract: review-response-quality hard sensors + fixtures.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCORER="$ROOT/scripts/review-response-quality.py"
FIXTURES="$ROOT/evals/harness/fixtures/review-quality"
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

assert_file() {
  local path="$1"
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "FAIL missing $path" >&2
    fail=1
  else
    echo "OK   file $path"
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

assert_file "scripts/review-response-quality.py"
assert_file "evals/harness/fixtures/review-quality/pass/phase-complete.json"
assert_file "evals/harness/fixtures/review-quality/pass/phase-security-checklist.json"
assert_file "evals/harness/fixtures/review-quality/pass/report-complete.md"
assert_file "evals/harness/fixtures/review-quality/fail/phase-missing-evidence.json"
assert_file "evals/harness/fixtures/review-quality/fail/clarify-no-options.json"
assert_file "evals/harness/fixtures/review-quality/fail/report-digest-forbidden.md"

set +e
pass_phase="$("$SCORER" score "$FIXTURES/pass/phase-complete.json")"
pass_phase_code=$?
fail_phase="$("$SCORER" score "$FIXTURES/fail/phase-missing-evidence.json")"
fail_phase_code=$?
fail_clarify="$("$SCORER" score "$FIXTURES/fail/clarify-no-options.json")"
fail_clarify_code=$?
set -e

assert_eq pass_phase_exit "0" "$pass_phase_code"
assert_eq pass_phase_ok "True" "$(json_field "$pass_phase" 'd["ok"]')"
assert_eq fail_phase_exit_nonzero "1" "$([[ "$fail_phase_code" -ne 0 ]] && echo 1 || echo 0)"
assert_eq fail_phase_ok "False" "$(json_field "$fail_phase" 'd["ok"]')"
assert_eq fail_clarify_exit_nonzero "1" "$([[ "$fail_clarify_code" -ne 0 ]] && echo 1 || echo 0)"
assert_eq fail_clarify_ok "False" "$(json_field "$fail_clarify" 'd["ok"]')"

set +e
fixtures_json="$("$SCORER" score-fixtures --kit-root "$ROOT" --fixtures-dir "$FIXTURES" --json)"
fixtures_code=$?
set -e
assert_eq fixtures_exit "0" "$fixtures_code"
assert_eq fixtures_ok "True" "$(json_field "$fixtures_json" 'd["ok"]')"
assert_eq fixtures_count "6" "$(json_field "$fixtures_json" 'd["fixture_count"]')"
assert_eq fixtures_match "6" "$(json_field "$fixtures_json" 'd["fixture_match_count"]')"
assert_eq fixtures_evidence "1.0" "$(json_field "$fixtures_json" 'str(d["metrics"]["review_response_quality"]["evidence_complete_rate_avg"])')"

assert_file "scripts/harness-bench.sh"
assert_file "evals/harness/README.md"
assert_file "docs/superpowers/dogfood/harness-health-checklist.md"

if grep -F -q "review-response-quality" "$ROOT/scripts/harness-bench.sh"; then
  echo "OK   harness_wire"
else
  echo "FAIL harness_wire" >&2
  fail=1
fi
if grep -F -q "review-response-quality" "$ROOT/evals/harness/README.md"; then
  echo "OK   harness_readme"
else
  echo "FAIL harness_readme" >&2
  fail=1
fi
if grep -F -q "review-response-quality" "$ROOT/docs/superpowers/dogfood/harness-health-checklist.md"; then
  echo "OK   dogfood"
else
  echo "FAIL dogfood" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL TESTS PASSED"
exit 0
