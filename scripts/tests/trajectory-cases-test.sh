#!/usr/bin/env bash
# Contract tests for the agent-trajectory golden set validator.
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

VALIDATOR=(python3 "$ROOT/scripts/trajectory-cases.py" validate)

if [[ ! -f "$ROOT/scripts/trajectory-cases.py" ]]; then
  echo "FAIL missing scripts/trajectory-cases.py" >&2
  exit 1
fi
echo "OK   validator_exists"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CASES="$TMP/cases"
mkdir -p "$CASES"

minimal_valid() {
  local dest="$1"
  cat >"$dest" <<'JSON'
{
  "id": "minimal-slice",
  "title": "Minimal valid slice case",
  "source": "docs/superpowers/specs/2026-08-25-agent-trajectory-golden-set-design.md",
  "pipeline": "slice",
  "end_to_end": false,
  "status": "active",
  "input": {
    "invocation": "/write-tech-spec",
    "fetch": "skip"
  },
  "required_stages": ["tech-spec"],
  "required_artifacts": [
    {"kind": "file", "name": "tech-spec", "pattern": "docs/superpowers/specs/*-tech-spec.md"}
  ],
  "forbidden": ["invent-business-facts"],
  "human_must_appear": [
    {"gate": "tech-spec-entry", "tokens": ["human", "agent"]}
  ],
  "agent_must_not_ask": ["pipeline-route"],
  "expected_end": {
    "jira_status": null,
    "pull_request": "absent",
    "review_report": "absent"
  }
}
JSON
}

minimal_valid "$CASES/minimal-slice.json"
assert_exit valid_temp 0 "${VALIDATOR[@]}" --dir "$CASES"

printf '{not json' >"$CASES/minimal-slice.json"
assert_exit invalid_json 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["id"]="other-id"; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit id_filename_mismatch 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["pipeline"]="turbo"; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit unknown_pipeline 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["source"]="docs/does-not-exist.md"; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit missing_source 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["required_stages"]=["not-a-stage"]; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit unknown_stage 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["forbidden"]=["eat-the-sun"]; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit unknown_forbidden 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
cp "$CASES/minimal-slice.json" "$CASES/duplicate-copy.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); json.dump(d, open(p,"w"))' "$CASES/duplicate-copy.json"
assert_exit duplicate_id 1 "${VALIDATOR[@]}" --dir "$CASES"
rm -f "$CASES/duplicate-copy.json"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["pipeline"]="fast"; d["end_to_end"]=True; d["required_stages"]=["tech-spec"]; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit fast_end_to_end_rejects_tech_spec 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["required_stages"]=["tech-spec","create-pr"]; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit create_pr_requires_never_merge 1 "${VALIDATOR[@]}" --dir "$CASES"

minimal_valid "$CASES/minimal-slice.json"
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["human_must_appear"]=[{"gate":"nope","tokens":["x"]}]; json.dump(d, open(p,"w"))' "$CASES/minimal-slice.json"
assert_exit unknown_human_gate 1 "${VALIDATOR[@]}" --dir "$CASES"

# Committed catalog
CATALOG="$ROOT/evals/trajectories/cases"
if [[ ! -d "$CATALOG" ]]; then
  echo "FAIL missing evals/trajectories/cases" >&2
  fail=1
else
  echo "OK   catalog_dir"
  assert_exit catalog_valid 0 "${VALIDATOR[@]}" --dir "$CATALOG" --kit-root "$ROOT"
  active_count="$(python3 -c 'import json,pathlib,sys; d=pathlib.Path(sys.argv[1]); print(sum(1 for p in d.glob("*.json") if json.loads(p.read_text()).get("status")=="active"))' "$CATALOG")"
  if [[ "$active_count" -lt 10 ]]; then
    echo "FAIL active_case_count: expected at least 10 got $active_count" >&2
    fail=1
  else
    echo "OK   active_case_count ($active_count)"
  fi
  pipelines="$(python3 -c 'import json,pathlib,sys; d=pathlib.Path(sys.argv[1]); print(" ".join(sorted({json.loads(p.read_text())["pipeline"] for p in d.glob("*.json")})))' "$CATALOG")"
  for need in fast full issue slice; do
    if [[ " $pipelines " != *" $need "* ]]; then
      echo "FAIL catalog missing pipeline $need (have: $pipelines)" >&2
      fail=1
    else
      echo "OK   catalog_pipeline_$need"
    fi
  done
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
