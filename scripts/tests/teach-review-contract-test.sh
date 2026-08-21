#!/usr/bin/env bash
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
assert_file "skills/teach-review/SKILL.md"
assert_file "commands/teach-review.md"
assert_grep skill_source "skills/teach-review/SKILL.md" "teach-review.sh"
assert_grep skill_one_class "skills/teach-review/SKILL.md" "One miss class"
assert_grep skill_no_local_merge "skills/teach-review/SKILL.md" "Do not merge"
assert_grep skill_draft "skills/teach-review/SKILL.md" "gh pr create --draft"
assert_grep skill_auto_push "skills/teach-review/SKILL.md" "auto_push"
assert_grep skill_refuse "skills/teach-review/SKILL.md" "not generalizable"
assert_grep cmd_invoke "commands/teach-review.md" "teach-review"
assert_grep hitl_heading "skills/hitl-choice/SKILL.md" "### Teach-review miss"
assert_grep token_miss "skills/hitl-choice/SKILL.md" '`miss`'
assert_grep token_no_miss "skills/hitl-choice/SKILL.md" '`no_miss`'
assert_grep er_agent_gate "agents/engineer-reviewer.md" "Teach-review miss"
assert_grep er_skill_gate "skills/engineer-review/SKILL.md" "Teach-review miss"
assert_grep pr_agent_gate "agents/pr-reviewer.md" "Teach-review miss"
assert_grep pr_skill_gate "skills/pr-review/SKILL.md" "Teach-review miss"
assert_grep er_no_kit_git "agents/engineer-reviewer.md" "never edit kit git"
assert_grep pr_invoke "agents/pr-reviewer.md" "teach-review"
assert_grep readme_skill "README.md" "teach-review"
assert_grep readme_cmd "README.md" "/teach-review"
assert_grep flow_teach "docs/superpowers/pipeline-flow.md" "teach-review"
assert_grep dogfood_miss "docs/superpowers/dogfood/engineer-review-checklist.md" "Teach-review miss"
if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
