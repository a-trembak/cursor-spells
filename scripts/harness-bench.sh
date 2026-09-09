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
test_count=0

shopt -s nullglob
tests=("$TESTS_GLOB"/*.sh)
shopt -u nullglob

if [[ ${#tests[@]} -eq 0 ]]; then
  echo "FAIL no tests under $TESTS_GLOB" >&2
  failed=1
fi

for test_script in "${tests[@]}"; do
  name="$(basename "$test_script")"
  test_count=$((test_count + 1))
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
ok=true
if [[ "$failed" -ne 0 ]]; then
  ok=false
fi

python3 - "$report_path" "$tmp_results" "$timestamp" "$overall_start" "$overall_end" "$test_count" "$failed" "$ok" <<'PY'
import json, sys
from pathlib import Path

report_path = Path(sys.argv[1])
results_path = Path(sys.argv[2])
timestamp = sys.argv[3]
overall_start = int(sys.argv[4])
overall_end = int(sys.argv[5])
test_count = int(sys.argv[6])
failed_count = int(sys.argv[7])
ok = sys.argv[8] == "true"

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

payload = {
    "timestamp": timestamp,
    "ok": ok,
    "test_count": test_count,
    "failed_count": failed_count,
    "duration_s": overall_end - overall_start,
    "tests": tests,
}
report_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"Wrote {report_path}")
PY

if [[ "$failed" -ne 0 ]]; then
  echo "Harness bench FAILED ($failed failing steps)" >&2
  exit 1
fi
echo "Harness bench PASS"
exit 0
