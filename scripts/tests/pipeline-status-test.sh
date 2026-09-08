#!/usr/bin/env bash
# Contract tests for scripts/pipeline-status.sh orientation resolver.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/pipeline-status.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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

if [[ ! -x "$SCRIPT" && ! -f "$SCRIPT" ]]; then
  echo "FAIL script_missing: $SCRIPT" >&2
  exit 1
fi

# --- Fixture: empty → idle / unknown ---
EMPTY="$TMP/empty"
mkdir -p "$EMPTY"
empty_json="$("$SCRIPT" --json --root "$EMPTY")"
assert_eq empty_route "unknown" "$(json_field "$empty_json" 'd["route"]')"
assert_eq empty_layer "idle" "$(json_field "$empty_json" 'd["layer"]')"
assert_eq empty_stage "idle" "$(json_field "$empty_json" 'd["stage"]')"
assert_eq empty_pending_count "0" "$(json_field "$empty_json" 'len(d["pending_gates"])')"
assert_eq empty_critique "False" "$(json_field "$empty_json" 'd["critique_clear"]')"

# --- Fixture: review-gate pending → layer=review stage=review-gate ---
REV="$TMP/review"
mkdir -p "$REV/.cursor/gates/review-gate" "$REV/.cursor/gates/trajectory-run"
printf '%s\n' "docs/plans/demo.md" >"$REV/.cursor/gates/review-gate/DEMO"
cat >"$REV/.cursor/gates/trajectory-run/session-full.json" <<'EOF'
{
  "case_id": "full-happy-path",
  "stages_entered": ["start-build", "software-developer"],
  "artifacts_present": [],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {}
}
EOF
rev_json="$("$SCRIPT" --json --root "$REV")"
assert_eq review_route "full" "$(json_field "$rev_json" 'd["route"]')"
assert_eq review_layer "review" "$(json_field "$rev_json" 'd["layer"]')"
assert_eq review_stage "review-gate" "$(json_field "$rev_json" 'd["stage"]')"
assert_eq review_pending_kind "review-gate" "$(json_field "$rev_json" 'd["pending_gates"][0]["kind"]')"
assert_eq review_pending_slug "DEMO" "$(json_field "$rev_json" 'd["pending_gates"][0]["slug"]')"
assert_eq review_legal_to "Build/software-developer" "$(json_field "$rev_json" 'next((x["to"] for x in d["legal_returns"] if "fixes" in x.get("how","") or x["to"].startswith("Build")), "")')"
# legal_returns for review-gate includes Build / fixes
legal_how="$(json_field "$rev_json" '" ".join(x.get("how","") for x in d["legal_returns"])')"
assert_contains review_legal_fixes "$legal_how" "fixes"

# --- Fixture: docs-gate beats review-gate ---
BOTH="$TMP/both"
mkdir -p "$BOTH/.cursor/gates/review-gate" "$BOTH/.cursor/gates/docs-gate"
printf '%s\n' "docs/plans/a.md" >"$BOTH/.cursor/gates/review-gate/A"
printf '%s\n' "docs/plans/a.md" >"$BOTH/.cursor/gates/docs-gate/A"
both_json="$("$SCRIPT" --json --root "$BOTH")"
assert_eq docs_wins_stage "docs-gate" "$(json_field "$both_json" 'd["stage"]')"
assert_eq docs_wins_layer "ship" "$(json_field "$both_json" 'd["layer"]')"

# --- Fixture: session-full.json only → last stage from ledger ---
LED="$TMP/ledger"
mkdir -p "$LED/.cursor/gates/trajectory-run"
cat >"$LED/.cursor/gates/trajectory-run/session-full.json" <<'EOF'
{
  "case_id": "full-happy-path",
  "stages_entered": ["tech-spec", "writing-plans", "software-developer"],
  "artifacts_present": [],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {}
}
EOF
led_json="$("$SCRIPT" --json --root "$LED")"
assert_eq ledger_route "full" "$(json_field "$led_json" 'd["route"]')"
assert_eq ledger_stage "software-developer" "$(json_field "$led_json" 'd["stage"]')"
assert_eq ledger_layer "build" "$(json_field "$led_json" 'd["layer"]')"
assert_eq ledger_entered_last "software-developer" "$(json_field "$led_json" 'd["stages_entered"][-1]')"

# --- Fixture: plan-critique-clear alone (no pending → active plan unknown) ---
CLR_ORPHAN="$TMP/clear-orphan"
mkdir -p "$CLR_ORPHAN/.cursor/gates/plan-critique-clear" "$CLR_ORPHAN/.cursor/gates/trajectory-run"
printf '%s\n' "docs/plans/demo.md" >"$CLR_ORPHAN/.cursor/gates/plan-critique-clear/DEMO"
cat >"$CLR_ORPHAN/.cursor/gates/trajectory-run/session-full.json" <<'EOF'
{
  "case_id": "full-happy-path",
  "stages_entered": ["start-build"],
  "artifacts_present": [],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {}
}
EOF
clr_orphan_json="$("$SCRIPT" --json --root "$CLR_ORPHAN")"
assert_eq critique_clear_orphan_false "False" "$(json_field "$clr_orphan_json" 'd["critique_clear"]')"

# --- Fixture: matching clear for active pending plan → critique_clear true ---
CLR_MATCH="$TMP/clear-match"
mkdir -p "$CLR_MATCH/.cursor/gates/review-gate" "$CLR_MATCH/.cursor/gates/plan-critique-clear"
printf '%s\n' "docs/plans/demo.md" >"$CLR_MATCH/.cursor/gates/review-gate/DEMO"
printf '%s\n' "docs/plans/demo.md" >"$CLR_MATCH/.cursor/gates/plan-critique-clear/DEMO"
clr_match_json="$("$SCRIPT" --json --root "$CLR_MATCH")"
assert_eq critique_clear_match_true "True" "$(json_field "$clr_match_json" 'd["critique_clear"]')"
assert_eq critique_clear_match_stage "review-gate" "$(json_field "$clr_match_json" 'd["stage"]')"

# --- Fixture: foreign clear does not count when pending gate is for another plan ---
CLR_FOREIGN="$TMP/clear-foreign"
mkdir -p "$CLR_FOREIGN/.cursor/gates/review-gate" "$CLR_FOREIGN/.cursor/gates/plan-critique-clear"
printf '%s\n' "docs/plans/plan-a.md" >"$CLR_FOREIGN/.cursor/gates/review-gate/PLAN-A"
printf '%s\n' "docs/plans/other.md" >"$CLR_FOREIGN/.cursor/gates/plan-critique-clear/OTHER"
clr_foreign_json="$("$SCRIPT" --json --root "$CLR_FOREIGN")"
assert_eq critique_clear_foreign_false "False" "$(json_field "$clr_foreign_json" 'd["critique_clear"]')"
assert_eq critique_clear_foreign_stage "review-gate" "$(json_field "$clr_foreign_json" 'd["stage"]')"
assert_eq critique_clear_foreign_slug "PLAN-A" "$(json_field "$clr_foreign_json" 'd["pending_gates"][0]["slug"]')"

# --- Fixture: bootstrap stage maps to plan layer (not fetch) ---
BOOT="$TMP/bootstrap"
mkdir -p "$BOOT/.cursor/gates/trajectory-run"
cat >"$BOOT/.cursor/gates/trajectory-run/session-full.json" <<'EOF'
{
  "case_id": "full-happy-path",
  "stages_entered": ["pipeline-route-hitl", "bootstrap"],
  "artifacts_present": [],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {}
}
EOF
boot_json="$("$SCRIPT" --json --root "$BOOT")"
assert_eq bootstrap_stage "bootstrap" "$(json_field "$boot_json" 'd["stage"]')"
assert_eq bootstrap_layer "plan" "$(json_field "$boot_json" 'd["layer"]')"
# fetch-family stage still maps to fetch
FETCH="$TMP/fetch-stage"
mkdir -p "$FETCH/.cursor/gates/trajectory-run"
cat >"$FETCH/.cursor/gates/trajectory-run/session-full.json" <<'EOF'
{
  "case_id": "full-happy-path",
  "stages_entered": ["jira-fetch", "pipeline-route-hitl"],
  "artifacts_present": [],
  "actions_taken": [],
  "human_gates_asked": [],
  "end": {}
}
EOF
fetch_json="$("$SCRIPT" --json --root "$FETCH")"
assert_eq fetch_family_stage "pipeline-route-hitl" "$(json_field "$fetch_json" 'd["stage"]')"
assert_eq fetch_family_layer "fetch" "$(json_field "$fetch_json" 'd["layer"]')"

# --- Source guard: sourcing defines functions only; no CLI record printed ---
src_stdout="$(mktemp)"
src_stderr="$(mktemp)"
# shellcheck disable=SC1090
if bash -c 'source "$1"; declare -F ps__build_record >/dev/null && declare -F ps__layer_for_stage >/dev/null && echo funcs_ok' bash "$SCRIPT" \
    >"$src_stdout" 2>"$src_stderr"; then
  src_body="$(cat "$src_stdout")"
  assert_eq source_defines_funcs "funcs_ok" "$src_body"
  if [[ "$src_body" == *"Route:"* ]] || [[ "$src_body" == *"\"stage\""* ]]; then
    echo "FAIL source_no_cli_output: sourced script printed orientation record" >&2
    fail=1
  else
    echo "OK   source_no_cli_output"
  fi
else
  echo "FAIL source_guard: sourcing failed" >&2
  cat "$src_stderr" >&2 || true
  fail=1
fi
rm -f "$src_stdout" "$src_stderr"

# --- Canvas URL shape ---
canvas_url="$("$SCRIPT" --canvas-url --root "$REV" --kit-root "$ROOT")"
assert_contains canvas_route "$canvas_url" "route=full"
assert_contains canvas_layer "$canvas_url" "layer=review"
assert_contains canvas_stage "$canvas_url" "stage=review-gate"
assert_contains canvas_hash "$canvas_url" "#review-gate"
assert_contains canvas_path "$canvas_url" "pipeline-flow.html"

# --- Human strip non-empty ---
strip="$("$SCRIPT" --root "$REV")"
[[ -n "$strip" ]] || { echo "FAIL empty_strip" >&2; fail=1; }
assert_contains strip_route "$strip" "full"
assert_contains strip_layer "$strip" "review"
assert_contains strip_stage "$strip" "review-gate"

# --- Required JSON keys ---
keys="$(json_field "$rev_json" '",".join(sorted(d.keys()))')"
for k in route layer stage pending_gates critique_clear ledger_path stages_entered legal_returns canvas; do
  assert_contains "json_key_$k" "$keys" "$k"
done
canvas_keys="$(json_field "$rev_json" '",".join(sorted(d["canvas"].keys()))')"
for k in path hash query; do
  assert_contains "canvas_key_$k" "$canvas_keys" "$k"
done

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
