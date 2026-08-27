#!/usr/bin/env bash
# Contract: review-figma-markup must walk structured Figma markup gates
# instead of eyeballing "looks close enough".
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_file() {
  local path="$1"
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "FAIL missing file: $path" >&2
    fail=1
  else
    echo "OK   file $path"
  fi
}

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_absent() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ still in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

CHECKLIST="skills/engineer-review/references/figma-markup-checklist.md"
AGENT="agents/review-figma-markup.md"
LEARN="skills/engineer-review/references/learned-misses.md"
FEEDBACK="skills/engineer-review/references/feedback-format.md"
PHASE="skills/engineer-review/references/phase-protocol.md"
ORCH="agents/engineer-reviewer.md"
SKILL="skills/engineer-review/SKILL.md"
PR_AGENT="agents/pr-reviewer.md"
DOGFOOD="docs/superpowers/dogfood/engineer-review-checklist.md"
SKILLMAP="skills/engineer-review/references/skill-map.md"
LEARN_PROTO="skills/engineer-review/references/review-learn-protocol.md"

assert_file "$CHECKLIST"
assert_file "$AGENT"

# Gates F1–F7 live in the checklist the phase always loads
assert_grep f1_extract "$CHECKLIST" "F1"
assert_grep f2_tokens "$CHECKLIST" "F2"
assert_grep f3_structure "$CHECKLIST" "F3"
assert_grep f4_states "$CHECKLIST" "F4"
assert_grep f5_components "$CHECKLIST" "F5"
assert_grep f6_rendered "$CHECKLIST" "F6"
assert_grep f7_coverage "$CHECKLIST" "F7"
assert_grep token_not_nit "$CHECKLIST" "not a nit"
assert_grep empty_placeholder "$CHECKLIST" "placeholder"
assert_grep auto_layout "$CHECKLIST" "auto-layout"
assert_grep coverage_values "$CHECKLIST" "figma_markup: compared"
assert_grep source_only "$CHECKLIST" "source-only"
assert_grep no_eyeball "$CHECKLIST" "looks close enough"

# Phase agent always opens the checklist — hint one-liner is not enough
assert_grep agent_loads_checklist "$AGENT" "figma-markup-checklist.md"
assert_grep agent_always_on "$AGENT" "Always load"
assert_grep agent_coverage "$AGENT" "figma_markup:"
assert_grep agent_awaiting_skipped "$AGENT" "awaiting_figma_urls"
assert_grep agent_awaiting_not_na "$AGENT" "awaiting_figma_urls.*skipped"
assert_grep f7_awaiting_skipped "$CHECKLIST" "awaiting_figma_urls"
assert_grep learn_capture_f_gates "$LEARN_PROTO" "map to existing \\*\\*R#\\*\\* or \\*\\*F#\\*\\*"

# The old cop-out that let reviewers skip token/structure misses
assert_absent agent_bikeshed_copout "$AGENT" "Do not bikeshed pixel-perfect without tokens/evidence"

# Kit seed + coverage wiring
assert_grep miss_id "$LEARN" "miss_figma-eyeball-skip"
assert_grep miss_phases "$LEARN" "figma"
assert_grep miss_checklist "$LEARN" "figma-markup-checklist.md"
assert_grep feedback_coverage "$FEEDBACK" "figma_markup:"
assert_grep phase_coverage "$PHASE" "figma_markup:"
assert_grep orch_coverage "$ORCH" "figma_markup:"
assert_grep skill_coverage "$SKILL" "figma_markup:"
assert_grep pr_coverage "$PR_AGENT" "figma_markup:"
assert_grep skillmap_checklist "$SKILLMAP" "figma-markup-checklist.md"
assert_grep learn_proto_checklist "$LEARN_PROTO" "figma-markup-checklist.md"
assert_grep dogfood_row "$DOGFOOD" "figma_markup"
assert_grep readme_checklist "README.md" "figma-markup-checklist.md"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
