#!/usr/bin/env bash
# Run kit harness regression suite and write a JSON report under evals/harness/reports/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORTS_DIR="${HARNESS_REPORTS_DIR:-$ROOT/evals/harness/reports}"
TESTS_GLOB="${HARNESS_TESTS_DIR:-$ROOT/scripts/tests}"
mkdir -p "$REPORTS_DIR"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report_path="$REPORTS_DIR/${timestamp}.json"
tmp_results="$(mktemp)"
trap 'rm -f "$tmp_results"' EXIT

echo "Harness bench starting at $timestamp"
echo "Reports → $report_path"

overall_start=$(date +%s)
failed=0

shopt -s nullglob
tests=("$TESTS_GLOB"/*.sh)
shopt -u nullglob

if [[ ${#tests[@]} -eq 0 ]]; then
  echo "FAIL no tests under $TESTS_GLOB" >&2
  failed=1
  # Record a failing row so report failed_count matches tests[] (no silent fail).
  printf '%s\t%s\t%s\t%s\n' "(no-tests)" "fail" "1" "0" >>"$tmp_results"
fi

for test_script in "${tests[@]}"; do
  name="$(basename "$test_script")"
  echo "==> $name"
  start=$(date +%s)
  set +e
  bash "$test_script"
  code=$?
  set -e
  end=$(date +%s)
  duration=$((end - start))
  status="pass"
  if [[ "$code" -ne 0 ]]; then
    status="fail"
    failed=$((failed + 1))
  fi
  printf '%s\t%s\t%s\t%s\n' "$name" "$status" "$code" "$duration" >>"$tmp_results"
  echo "    $status exit=$code duration_s=$duration"
done

# Trajectory validate + golden fixture score (always after shell tests)
traj_start=$(date +%s)
set +e
python3 "$ROOT/scripts/trajectory-cases.py" validate --kit-root "$ROOT"
traj_validate_code=$?
set -e
traj_mid=$(date +%s)
set +e
python3 "$ROOT/scripts/trajectory-cases.py" score --kit-root "$ROOT" \
  --runs-dir "$ROOT/evals/trajectories/fixtures/pass"
traj_score_code=$?
set -e
traj_end=$(date +%s)

traj_validate_status="pass"
if [[ "$traj_validate_code" -ne 0 ]]; then
  traj_validate_status="fail"
  failed=$((failed + 1))
fi
traj_score_status="pass"
if [[ "$traj_score_code" -ne 0 ]]; then
  traj_score_status="fail"
  failed=$((failed + 1))
fi

printf '%s\t%s\t%s\t%s\n' "trajectory-validate" "$traj_validate_status" "$traj_validate_code" "$((traj_mid - traj_start))" >>"$tmp_results"
printf '%s\t%s\t%s\t%s\n' "trajectory-score-fixtures" "$traj_score_status" "$traj_score_code" "$((traj_end - traj_mid))" >>"$tmp_results"
echo "==> trajectory-validate → $traj_validate_status ($traj_validate_code)"
echo "==> trajectory-score-fixtures → $traj_score_status ($traj_score_code)"

overall_end=$(date +%s)

# Derive test_count / failed_count / ok from recorded rows so they stay consistent.
# Also emit metrics.quality (pass rates) and metrics.speed (percentiles / slowest).
python3 - "$report_path" "$tmp_results" "$timestamp" "$overall_start" "$overall_end" <<'PY'
import json, sys
from pathlib import Path

report_path = Path(sys.argv[1])
results_path = Path(sys.argv[2])
timestamp = sys.argv[3]
overall_start = int(sys.argv[4])
overall_end = int(sys.argv[5])

tests = []
for line in results_path.read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    name, status, code, duration = line.split("\t")
    tests.append(
        {
            "name": name,
            "status": status,
            "exit_code": int(code),
            "duration_s": int(duration),
        }
    )

failed_count = sum(1 for t in tests if t["status"] != "pass")
pass_count = len(tests) - failed_count
total = len(tests)
pass_rate = (pass_count / total) if total else 0.0

TRAJ_VALIDATE = "trajectory-validate"
TRAJ_SCORE = "trajectory-score-fixtures"
traj_names = {TRAJ_VALIDATE, TRAJ_SCORE}
contract_tests = [t for t in tests if t["name"] not in traj_names]
contract_fail = sum(1 for t in contract_tests if t["status"] != "pass")
contract_pass = len(contract_tests) - contract_fail
contract_rate = (contract_pass / len(contract_tests)) if contract_tests else 0.0

def status_of(name: str):
    for t in tests:
        if t["name"] == name:
            return t["status"]
    return None

def percentile_nearest(sorted_vals, pct: float):
    if not sorted_vals:
        return None
    if len(sorted_vals) == 1:
        return sorted_vals[0]
    # Nearest-rank: index = ceil(p/100 * n) - 1
    import math
    rank = max(1, math.ceil(pct / 100.0 * len(sorted_vals)))
    return sorted_vals[rank - 1]

durations = sorted(t["duration_s"] for t in tests)
slowest = sorted(tests, key=lambda t: t["duration_s"], reverse=True)[:5]
slowest_rows = [{"name": t["name"], "duration_s": t["duration_s"], "status": t["status"]} for t in slowest]

metrics = {
    "quality": {
        "pass_count": pass_count,
        "fail_count": failed_count,
        "pass_rate": round(pass_rate, 4),
        "contract_pass_count": contract_pass,
        "contract_fail_count": contract_fail,
        "contract_pass_rate": round(contract_rate, 4),
        "trajectory_validate": status_of(TRAJ_VALIDATE),
        "trajectory_score_fixtures": status_of(TRAJ_SCORE),
    },
    "speed": {
        "total_duration_s": overall_end - overall_start,
        "p50_duration_s": percentile_nearest(durations, 50),
        "p95_duration_s": percentile_nearest(durations, 95),
        "max_duration_s": durations[-1] if durations else None,
        "min_duration_s": durations[0] if durations else None,
        "slowest": slowest_rows,
    },
}

payload = {
    "timestamp": timestamp,
    "ok": failed_count == 0,
    "test_count": total,
    "failed_count": failed_count,
    "duration_s": overall_end - overall_start,
    "tests": tests,
    "metrics": metrics,
}
report_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"Wrote {report_path}")
q = metrics["quality"]
s = metrics["speed"]
print(
    f"Metrics quality: pass_rate={q['pass_rate']} "
    f"contract_pass_rate={q['contract_pass_rate']} "
    f"trajectory_validate={q['trajectory_validate']} "
    f"trajectory_score_fixtures={q['trajectory_score_fixtures']}"
)
print(
    f"Metrics speed: total_s={s['total_duration_s']} "
    f"p50_s={s['p50_duration_s']} p95_s={s['p95_duration_s']} "
    f"max_s={s['max_duration_s']}"
)
if s["slowest"]:
    top = ", ".join(f"{r['name']}={r['duration_s']}s" for r in s["slowest"][:3])
    print(f"Metrics slowest: {top}")
PY

if [[ "$failed" -ne 0 ]]; then
  echo "Harness bench FAILED ($failed failing steps)" >&2
  exit 1
fi
echo "Harness bench PASS"
exit 0
