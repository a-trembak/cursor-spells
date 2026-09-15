#!/usr/bin/env bash
# Contract: live pipeline-metrics journal (mark-start → append-score/append-review → summary/export).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
METRICS="$ROOT/scripts/pipeline-metrics.py"
SCORER="$ROOT/scripts/trajectory-cases.py"
REVIEW="$ROOT/scripts/review-response-quality.py"
PASS_LEDGER="$ROOT/evals/trajectories/fixtures/pass/full-happy-path.json"
PASS_REVIEW="$ROOT/evals/harness/fixtures/review-quality/pass/phase-complete.json"
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
    echo "FAIL $name: [$needle] not in:" >&2
    echo "$haystack" >&2
    fail=1
  fi
}

assert_file "scripts/pipeline-metrics.py"
assert_file "scripts/trajectory-cases.py"
assert_file "scripts/review-response-quality.py"

if [[ ! -f "$PASS_LEDGER" ]]; then
  echo "FAIL missing pass ledger fixture $PASS_LEDGER" >&2
  exit 1
fi
if [[ ! -f "$PASS_REVIEW" ]]; then
  echo "FAIL missing review quality fixture $PASS_REVIEW" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HISTORY="$TMP/history.jsonl"
ACTIVE="$TMP/active"

help_out="$(python3 "$METRICS" --help 2>&1)"
assert_contains help_mark_start "$help_out" "mark-start"
assert_contains help_append_score "$help_out" "append-score"
assert_contains help_append_review "$help_out" "append-review"
assert_contains help_summary "$help_out" "summary"
assert_contains help_export "$help_out" "export"

python3 "$METRICS" mark-start --ledger "$PASS_LEDGER" --ticket PROJ-9 --active-dir "$ACTIVE" >/dev/null
sleep 1
score_code=0
score_out="$(python3 "$METRICS" append-score --kit-root "$ROOT" --run "$PASS_LEDGER" \
  --history "$HISTORY" --active-dir "$ACTIVE" --duration-s 12.5 2>&1)" || score_code=$?
assert_eq score_exit 0 "$score_code"
assert_contains score_pass "$score_out" "PASS full-happy-path"
assert_contains score_append_ok "$score_out" "metrics-append"

mark_count="$(find "$ACTIVE" -type f 2>/dev/null | wc -l | tr -d ' ')"
assert_eq mark_cleaned 0 "$mark_count"

python3 - "$HISTORY" <<'PY'
import json, sys
path = sys.argv[1]
rows = [json.loads(line) for line in open(path, encoding="utf-8") if line.strip()]
assert rows, "empty history"
last = rows[-1]
assert last.get("kind") == "trajectory_score", last
assert last.get("verdict") == "PASS", last
assert last.get("case_id") == "full-happy-path", last
assert last.get("ticket") == "PROJ-9", last
assert last.get("duration_s") == 12.5, last
assert last.get("pipeline") == "full", last.get("pipeline")
print("OK   history_trajectory_fields")
PY

review_code=0
review_out="$(python3 "$METRICS" append-review --kit-root "$ROOT" --path "$PASS_REVIEW" \
  --history "$HISTORY" --ticket PROJ-9 2>&1)" || review_code=$?
assert_eq review_exit 0 "$review_code"
assert_contains review_append_ok "$review_out" "metrics-append"

python3 - "$HISTORY" <<'PY'
import json, sys
path = sys.argv[1]
rows = [json.loads(line) for line in open(path, encoding="utf-8") if line.strip()]
kinds = [row.get("kind") for row in rows]
assert "review_response_quality" in kinds, kinds
review = [row for row in rows if row.get("kind") == "review_response_quality"][-1]
assert review.get("verdict") == "PASS", review
q = review.get("quality") or {}
assert q.get("ok") is True, q
assert isinstance(q.get("evidence_complete_rate"), (int, float)), q
print("OK   history_review_fields")
PY

sum_out="$(python3 "$METRICS" summary --history "$HISTORY" 2>&1)"
assert_contains summary_header "$sum_out" "pipeline-metrics summary"
assert_contains summary_traj "$sum_out" "trajectory_score"
assert_contains summary_review "$sum_out" "review_response_quality"

csv_out="$(python3 "$METRICS" export --format csv --history "$HISTORY" 2>&1)"
assert_contains csv_header "$csv_out" "recorded_at,kind,case_id"
assert_contains csv_row "$csv_out" "trajectory_score"
assert_contains csv_row2 "$csv_out" "review_response_quality"

assert_contains skill_traj_mark "$(cat "$ROOT/skills/trajectory-score/SKILL.md")" "pipeline-metrics.py mark-start"
assert_contains skill_traj_score "$(cat "$ROOT/skills/trajectory-score/SKILL.md")" "pipeline-metrics.py append-score"
assert_contains skill_create_pr "$(cat "$ROOT/skills/create-pr/SKILL.md")" "pipeline-metrics.py append-score"
assert_contains skill_engineer "$(cat "$ROOT/skills/engineer-review/SKILL.md")" "pipeline-metrics.py append-review"

bare=0
python3 "$SCORER" score --kit-root "$ROOT" --run "$PASS_LEDGER" >/dev/null || bare=$?
assert_eq bare_score_still_works 0 "$bare"

bare_r=0
python3 "$REVIEW" score "$PASS_REVIEW" --kit-root "$ROOT" >/dev/null || bare_r=$?
assert_eq bare_review_still_works 0 "$bare_r"

if [[ "$fail" -ne 0 ]]; then
  echo "FAIL pipeline-metrics-test" >&2
  exit 1
fi
echo "OK   pipeline-metrics-test"
exit 0
