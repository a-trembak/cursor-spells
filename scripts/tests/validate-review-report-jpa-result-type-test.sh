#!/usr/bin/env bash
# Contract: validate-review-report.sh jpa_result_type enum (narrow).
# When BODY contains jpa_result_type, value must be matched|mismatched|skipped|n/a.
# Absence of the key must not introduce a new failure.
#
# Run: bash scripts/tests/validate-review-report-jpa-result-type-test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATOR="$ROOT/scripts/validate-review-report.sh"
FIXTURES="$ROOT/evals/harness/fixtures/validate-review-report"
fail=0

assert_exit() {
  local name="$1" expected="$2" file="$3"
  set +e
  out="$("$VALIDATOR" "$file" 2>&1)"
  code=$?
  set -e
  if [[ "$code" -eq "$expected" ]]; then
    echo "OK   $name (exit $code)"
  else
    echo "FAIL $name: expected exit $expected, got $code" >&2
    echo "$out" >&2
    fail=1
  fi
  if [[ "$expected" -ne 0 ]]; then
    if printf '%s\n' "$out" | grep -E -q 'jpa_result_type must be one of'; then
      echo "OK   ${name}_message"
    else
      echo "FAIL ${name}_message: missing clear jpa_result_type FAIL line" >&2
      echo "$out" >&2
      fail=1
    fi
  fi
}

assert_exit matched_pass 0 "$FIXTURES/pass-jpa-result-type-matched.md"
assert_exit bogus_fail 1 "$FIXTURES/fail-jpa-result-type-bogus.md"
assert_exit absent_pass 0 "$FIXTURES/pass-no-jpa-result-type.md"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
