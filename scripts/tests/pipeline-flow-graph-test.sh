#!/usr/bin/env bash
# Graph contract: after software-developer the canvas names review-gate
# (not a return to the plan layer), and cycles are explicit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MD="$ROOT/docs/superpowers/pipeline-flow.md"
HTML="$ROOT/docs/superpowers/pipeline-flow.html"
fail=0

assert_contains() {
  local name="$1" path="$2" needle="$3"
  if grep -F -q "$needle" "$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: [$needle] not in ${path#$ROOT/}" >&2
    fail=1
  fi
}

assert_absent() {
  local name="$1" path="$2" needle="$3"
  if grep -F -q "$needle" "$path"; then
    echo "FAIL $name: [$needle] still in ${path#$ROOT/}" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_contains md_layers "$MD" "Plan layer"
assert_contains md_build_layer "$MD" "Build layer"
assert_contains md_review_layer "$MD" "Review layer"
assert_contains md_review_gate_node "$MD" 'reviewGate[/"review-gate"/]'
assert_contains md_fixes_to_build "$MD" 'reviewGate -.->|"fixes"| softwareDev'
assert_contains md_fixes_not_plan "$MD" "back to Build, not Plan"
assert_contains md_command_alias "$MD" "/finish-plan"
assert_contains md_review_surface "$MD" "review-surface: checkout + SetActiveBranch"
assert_contains html_review_surface "$HTML" "SetActiveBranch"

assert_contains html_layer_plan "$HTML" 'class="layer plan"'
assert_contains html_layer_build "$HTML" 'class="layer build"'
assert_contains html_layer_review "$HTML" 'class="layer review"'
assert_contains html_review_gate_label "$HTML" '<div class="label">review-gate</div>'
assert_contains html_fixes_to_dev "$HTML" "software-developer"
assert_contains html_view_id "$HTML" 'id="view-review-gate"'
assert_contains html_alias "$HTML" '"finish-plan": "review-gate"'

# Overview must not present the post-build HITL as a finish-plan plan step.
assert_absent html_overview_finish_label "$HTML" '<div class="label">finish-plan</div>'

assert_contains md_propose_commit "$MD" "propose-commit"
assert_contains html_propose_commit "$HTML" "propose-commit"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
