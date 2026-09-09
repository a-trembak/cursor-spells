#!/usr/bin/env bash
# Contract tests for scripts/harness-health.py
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/harness-health.py"
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

if [[ ! -f "$SCRIPT" ]]; then
  echo "FAIL script_missing: $SCRIPT" >&2
  exit 1
fi

human_out="$(python3 "$SCRIPT" --kit-root "$ROOT")"
assert_contains human_header "$human_out" "Harness health"
assert_contains human_no_gates "$human_out" "does not advance gates"
assert_contains human_wiring "$human_out" "Wiring matrix"
assert_contains human_ring "$human_out" "Cursor context ring"

json_out="$(python3 "$SCRIPT" --json --kit-root "$ROOT")"
assert_eq json_has_wiring "True" "$(json_field "$json_out" '"wiring" in d')"
assert_eq json_has_inventory "True" "$(json_field "$json_out" '"inventory" in d')"
assert_eq json_has_proxies "True" "$(json_field "$json_out" '"context_proxies" in d')"
assert_eq json_has_budget "True" "$(json_field "$json_out" '"context_budget" in d')"

# Known active case must appear in wiring
wired_fetch="$(json_field "$json_out" 'next((r["wiring"] for r in d["wiring"] if r["id"]=="fetch-failure-stops"), "")')"
assert_eq fetch_wired "wired" "$wired_fetch"

# capture-escape-promote-new-gate is draft — must not appear in active wiring matrix
promote_in="$(json_field "$json_out" 'any(r["id"]=="capture-escape-promote-new-gate" for r in d["wiring"])')"
assert_eq promote_not_active "False" "$promote_in"

# Context budget keys present
for skill in tech-spec implementation-critic engineer-review system-design; do
  present="$(json_field "$json_out" "\"$skill\" in d[\"context_budget\"]")"
  assert_eq "budget_key_$skill" "True" "$present"
done

# Attach a fake bench report
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fake_report="$TMP/fake-bench.json"
cat >"$fake_report" <<'EOF'
{
  "timestamp": "20260101T000000Z",
  "ok": true,
  "test_count": 1,
  "failed_count": 0,
  "duration_s": 1,
  "tests": [{"name": "demo.sh", "status": "pass", "exit_code": 0, "duration_s": 1}]
}
EOF
attached="$(python3 "$SCRIPT" --json --kit-root "$ROOT" --bench-report "$fake_report")"
assert_eq attached_ok "True" "$(json_field "$attached" 'd["bench"]["ok"]')"
assert_eq attached_count "1" "$(json_field "$attached" 'd["bench"]["test_count"]')"

# Auto-discover latest under evals/harness/reports when present
REPORTS="$ROOT/evals/harness/reports"
mkdir -p "$REPORTS"
discovered="$REPORTS/zzz-harness-health-test.json"
cp "$fake_report" "$discovered"
cleanup_report() { rm -f "$discovered"; }
trap 'rm -rf "$TMP"; rm -f "$discovered"' EXIT
auto="$(python3 "$SCRIPT" --json --kit-root "$ROOT")"
assert_eq auto_bench "True" "$(json_field "$auto" 'd.get("bench") is not None and d["bench"].get("ok") is True')"
assert_contains auto_path "$(json_field "$auto" 'd.get("bench_report_path") or ""')" "zzz-harness-health-test.json"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL TESTS PASSED"
exit 0
