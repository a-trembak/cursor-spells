#!/usr/bin/env bash
# Contract: comments must not justify code by naming a screen, chart, widget,
# or Figma node. Canonical taxonomy lives in code-comments; software-developer
# must apply it on backend stacks, not only on react-web UI work.
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

assert_file "skills/code-comments/SKILL.md"
assert_file "skills/software-developer/SKILL.md"
assert_file "agents/csp-software-developer.md"
assert_file "agents/csp-review-deadcode.md"
assert_file "skills/engineer-review/references/auto-fix-eligibility.md"

# Taxonomy forbids presentation-tied comments and still keeps real invariants.
assert_grep taxonomy_remove_heading "skills/code-comments/SKILL.md" "^## Remove / never write$"
assert_grep taxonomy_chart "skills/code-comments/SKILL.md" "chart"
assert_grep taxonomy_presentation "skills/code-comments/SKILL.md" "screen|widget|Figma"
assert_grep taxonomy_backend "skills/code-comments/SKILL.md" "backend"
assert_grep taxonomy_invariant "skills/code-comments/SKILL.md" "invariant"
assert_grep taxonomy_keep_why "skills/code-comments/SKILL.md" "Why / invariant"

# software-developer applies this on backend services, independent of Figma UI check.
assert_grep dev_skill_backend "skills/software-developer/SKILL.md" "backend"
assert_grep dev_skill_chart_comment "skills/software-developer/SKILL.md" "chart"
assert_grep dev_skill_loads_comments "skills/software-developer/SKILL.md" "code-comments"
assert_grep dev_agent_backend "agents/csp-software-developer.md" "backend"
assert_grep dev_agent_chart_comment "agents/csp-software-developer.md" "chart"
assert_grep dev_agent_loads_comments "agents/csp-software-developer.md" "code-comments"

# Review still classifies these comments; mixed invariant+chart is clarify, not silent delete.
assert_grep deadcode_taxonomy "agents/csp-review-deadcode.md" "skills/code-comments/SKILL.md"
assert_grep deadcode_presentation "agents/csp-review-deadcode.md" "chart|screen|widget|Figma"
assert_grep eligibility_mixed_clarify "skills/engineer-review/references/auto-fix-eligibility.md" "chart"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
