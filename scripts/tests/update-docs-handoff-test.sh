#!/usr/bin/env bash
# Contract: update-docs must hand off to propose-commit / create-pr; not terminal.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_grep skill_next "skills/update-docs/SKILL.md" "next_skill: propose-commit \\| create-pr"
assert_grep skill_not_terminal "skills/update-docs/SKILL.md" "Never treat this skill as terminal"
assert_grep skill_clear_continue "skills/update-docs/SKILL.md" "still continue the handoff|Clear failure must not cancel"
assert_grep start_task_no_end "commands/csp-start-task.md" "Do not treat .update-docs. as the end|Do not end the turn here"
assert_grep start_task_create_pr "commands/csp-start-task.md" "create-pr.*immediately|Gate-marker clear failures"
assert_grep update_cmd_next "commands/csp-update-docs.md" "next_skill: propose-commit|next_skill: create-pr"
assert_grep gates_fallback "scripts/pipeline-gates.sh" "spells-gates|pg_gates_base"
assert_grep clear_nonzero "scripts/pipeline-gates.sh" "clear failed"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
