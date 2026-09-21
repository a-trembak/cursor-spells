#!/usr/bin/env bash
# Contract: local-verify stage before create-pr; never invent up commands.
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
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_not_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "FAIL $name: /$pattern/ unexpectedly in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file "skills/local-verify/SKILL.md"
assert_file "agents/csp-local-verify.md"
assert_file "commands/csp-local-verify.md"
assert_file "skills/local-verify/references/contract-schema.md"
assert_file "skills/local-verify/references/skip-fail-codes.md"
assert_file "skills/local-verify/references/example-spells-local-verify.yaml"
assert_file "docs/superpowers/specs/2026-09-21-local-verify-design.md"

assert_grep skill_name "skills/local-verify/SKILL.md" "^name: local-verify$"
assert_grep skill_no_contract "skills/local-verify/SKILL.md" "no_contract"
assert_grep skill_blocking "skills/local-verify/SKILL.md" "blocking"
assert_grep skill_invent "skills/local-verify/SKILL.md" "Never invent|never invent"
assert_grep skill_next "skills/local-verify/SKILL.md" "next_skill: create-pr"
assert_grep skill_gate "skills/local-verify/SKILL.md" "local-verify"
assert_grep skill_adoption "skills/local-verify/SKILL.md" "Consumer adoption"

assert_grep agent_pointer "agents/csp-local-verify.md" "local-verify"
assert_grep agent_invent "agents/csp-local-verify.md" "Never invent"
assert_grep agent_secrets "agents/csp-local-verify.md" "secret"
assert_grep agent_noop "agents/csp-local-verify.md" "noop"

assert_grep cmd_invoke "commands/csp-local-verify.md" "local-verify"

assert_grep er_step_local "skills/engineer-review/SKILL.md" "local-verify"
assert_grep er_step_before_pr "skills/engineer-review/SKILL.md" "local-verify.*create-pr|create-pr"
assert_grep er_manual_no_auto "skills/engineer-review/SKILL.md" "does \\*\\*not\\*\\* auto-start.*local-verify|local-verify unless the human asks"

assert_grep er_agent_local "agents/csp-engineer-reviewer.md" "local-verify"
assert_grep er_agent_step15 "agents/csp-engineer-reviewer.md" "Pipeline continue after miss"

assert_grep hitl_preset "skills/hitl-choice/SKILL.md" "Local verify blocking fail"
assert_grep hitl_fix "skills/hitl-choice/SKILL.md" '`fix`'
assert_grep hitl_skip_verify "skills/hitl-choice/SKILL.md" '`skip_verify`'
assert_grep hitl_retry "skills/hitl-choice/SKILL.md" '`retry`'

assert_grep create_pr_follows "skills/create-pr/SKILL.md" "local-verify"
assert_grep propose_next "skills/propose-commit/SKILL.md" "local-verify"

assert_grep flow_md "docs/superpowers/pipeline-flow.md" "local-verify"
assert_grep flow_html "docs/superpowers/pipeline-flow.html" "local-verify"
assert_grep readme_skill "README.md" "local-verify"
assert_grep start_full "commands/csp-start-task.md" "local-verify"
assert_grep start_issue "commands/csp-start-issue-task.md" "local-verify"
assert_grep status_ship "scripts/pipeline-status.sh" "local-verify"
assert_grep gates_kind "scripts/pipeline-gates.sh" "local-verify"
assert_grep example_yaml "skills/local-verify/references/example-spells-local-verify.yaml" "version: 1"
assert_grep spec_approved "docs/superpowers/specs/2026-09-21-local-verify-design.md" '`approved`'

# Negatives: must not instruct opening/merging a pull request or inventing npm from package.json
assert_not_grep skill_no_merge_invoke "skills/local-verify/SKILL.md" "gh pr merge --"
assert_not_grep skill_no_create_pr_flag "skills/local-verify/SKILL.md" "gh pr create --"
assert_not_grep skill_no_pkg_scripts_up "skills/local-verify/SKILL.md" "package\\.json scripts|scripts.*package\\.json"
assert_grep skill_forbid_pkg "skills/local-verify/SKILL.md" "package\\.json"
assert_grep skill_forbid_merge_phrase "skills/local-verify/SKILL.md" "Never.*gh pr merge|never.*gh pr merge|Do \\*\\*not\\*\\*.*merge"
assert_not_grep agent_no_merge_invoke "agents/csp-local-verify.md" "gh pr merge --"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
