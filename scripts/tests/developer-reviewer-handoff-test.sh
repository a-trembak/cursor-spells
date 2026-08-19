#!/usr/bin/env bash
# Contract: after software-developer (or bug-fixer) returns, the parent
# pipeline must wait and launch engineer-reviewer. Fire-and-forget dispatch
# is the bug this file guards.
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

assert_file "skills/start-build/SKILL.md"
assert_file "commands/start-build.md"
assert_file "skills/software-developer/SKILL.md"
assert_file "agents/software-developer.md"
assert_file "commands/start-task.md"
assert_file "commands/start-issue-task.md"
assert_file "agents/bug-fixer.md"

# start-build must wait for the developer Task and continue to finish-plan.
assert_grep start_build_wait "skills/start-build/SKILL.md" "Wait for"
assert_grep start_build_finish "skills/start-build/SKILL.md" "finish-plan"
assert_grep start_build_reviewer "skills/start-build/SKILL.md" "engineer-reviewer"
assert_grep start_build_no_forget "skills/start-build/SKILL.md" "Fire-and-forget"
assert_grep start_build_cmd_wait "commands/start-build.md" "Wait for"
assert_grep start_build_cmd_finish "commands/start-build.md" "finish-plan"
assert_grep start_build_cmd_reviewer "commands/start-build.md" "engineer-reviewer"

# Nested developer must return next_skill, not AskQuestion in the Task.
assert_grep dev_skill_next "skills/software-developer/SKILL.md" "next_skill"
assert_grep dev_skill_nested "skills/software-developer/SKILL.md" "nested Task"
assert_grep dev_skill_no_ask "skills/software-developer/SKILL.md" "AskQuestion"
assert_grep dev_agent_next "agents/software-developer.md" "next_skill"
assert_grep dev_agent_nested "agents/software-developer.md" "nested Task"
assert_grep dev_agent_no_ask "agents/software-developer.md" "AskQuestion"

# /start-task full: wait then finish-plan; fast: wait then engineer-reviewer.
assert_grep start_task_wait "commands/start-task.md" "Wait for"
assert_grep start_task_not_end "commands/start-task.md" "Do not treat dispatch as the end"
assert_grep start_task_fast_wait "commands/start-task.md" "mode:fast"
assert_grep start_task_fast_review "commands/start-task.md" "Wait for .*software-developer|after .*returns"

# /start-issue-task: wait for bug-fixer then engineer-reviewer.
assert_grep issue_wait "commands/start-issue-task.md" "Wait for"
assert_grep issue_reviewer "commands/start-issue-task.md" "engineer-reviewer"
assert_grep fixer_next "agents/bug-fixer.md" "next_skill"
assert_grep fixer_nested "agents/bug-fixer.md" "nested Task"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
