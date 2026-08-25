#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_grep fetch_score "skills/jira-fetch/SKILL.md" "trajectory-cases.py score"
assert_grep fetch_case "skills/jira-fetch/SKILL.md" "fetch-failure-stops"
assert_grep fetch_skip "skills/jira-fetch/SKILL.md" "skip score"
assert_grep start_score "commands/start-task.md" "fetch-failure-stops"
assert_grep cpr_score "skills/create-pr/SKILL.md" "trajectory-cases.py score"
assert_grep cpr_case "skills/create-pr/SKILL.md" "create-pr-draft-never-merge"
assert_grep cpr_before_ready "skills/create-pr/SKILL.md" "before.*gh pr ready|before applying"
assert_grep cpr_after_ask "skills/create-pr/SKILL.md" "after.*Pipeline finale"
assert_grep dogfood "docs/superpowers/dogfood/jira-ac-router-finale-checklist.md" "trajectory-wiring-test.sh"
assert_grep readme "README.md" "fetch-failure-stops"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
