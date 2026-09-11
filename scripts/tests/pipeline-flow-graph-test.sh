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
assert_contains md_command_alias "$MD" "/csp-finish-plan"
assert_contains md_review_surface "$MD" "review-surface: checkout + SetActiveBranch"
assert_contains html_review_surface "$HTML" "SetActiveBranch"

assert_contains html_layer_plan "$HTML" 'class="layer plan"'
assert_contains html_layer_build "$HTML" 'class="layer build"'
assert_contains html_layer_review "$HTML" 'class="layer review"'
assert_contains html_review_gate_label "$HTML" '<div class="label">review-gate</div>'
assert_contains html_fixes_to_dev "$HTML" "csp-software-developer"
assert_contains html_view_id "$HTML" 'id="view-review-gate"'
assert_contains html_alias "$HTML" '"finish-plan": "review-gate"'

# Every data-go must resolve to an existing view-* id (honor JS aliases).
# Uses the same alias map the page ships (finish-plan → review-gate, etc.).
data_go_resolve_ok=1
alias_block="$(sed -n '/const aliases = {/,/};/p' "$HTML")"
while IFS= read -r go; do
  [[ -z "$go" || "$go" == "overview" ]] && continue
  resolved="$go"
  if printf '%s\n' "$alias_block" | grep -E -q "\"$go\"[[:space:]]*:"; then
    resolved="$(printf '%s\n' "$alias_block" | sed -n "s/.*\"$go\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -1)"
  fi
  view_id="view-${resolved}"
  if ! grep -F -q "id=\"${view_id}\"" "$HTML"; then
    echo "FAIL data_go_resolves: data-go=\"$go\" → id=\"${view_id}\" missing" >&2
    data_go_resolve_ok=0
    fail=1
  fi
done < <(grep -oE 'data-go="[^"]+"' "$HTML" | sed 's/data-go="//;s/"$//' | sort -u)
if [[ "$data_go_resolve_ok" -eq 1 ]]; then
  echo "OK   data_go_resolves_all_views"
fi

assert_contains html_tech_spec_alias "$HTML" '"csp-tech-spec": "tech-spec"'
# Alias target must be the live Tech Spec detail section
assert_contains html_view_tech_spec "$HTML" 'id="view-tech-spec"'

# Overview must not present the post-build HITL as a finish-plan plan step.
assert_absent html_overview_finish_label "$HTML" '<div class="label">finish-plan</div>'

assert_contains md_propose_commit "$MD" "propose-commit"
assert_contains html_propose_commit "$HTML" "propose-commit"

# Orientation query-param contract (live highlight)
assert_contains html_url_search_params "$HTML" "URLSearchParams"
assert_contains html_reads_layer "$HTML" 'get("layer")'
assert_contains html_reads_stage "$HTML" 'get("stage")'
assert_contains html_css_layer_done "$HTML" ".layer.done"
assert_contains html_css_layer_here "$HTML" ".layer.here"
assert_contains html_css_layer_waiting "$HTML" ".layer.waiting"
assert_contains html_css_node_here "$HTML" ".node.here"
assert_contains html_css_seq_here "$HTML" ".seq-strip li.here"
assert_contains html_css_waiting "$HTML" ".waiting"
# Document orientation param names (route, layer, stage)
assert_contains html_param_docs_route "$HTML" "route"
assert_contains html_param_docs_layer "$HTML" 'data-orientation-params="route,layer,stage"'

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
