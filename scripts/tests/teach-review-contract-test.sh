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
assert_not_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ still in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}
assert_file "skills/teach-review/SKILL.md"
assert_file "commands/csp-teach-review.md"
assert_grep skill_source "skills/teach-review/SKILL.md" "teach-review.sh"
assert_grep skill_one_class "skills/teach-review/SKILL.md" "One miss class"
assert_grep skill_no_local_merge "skills/teach-review/SKILL.md" "Do not merge"
assert_grep skill_create_pr "skills/teach-review/SKILL.md" 'gh pr create --repo'
assert_not_grep skill_no_draft_flag "skills/teach-review/SKILL.md" 'gh pr create --draft'
assert_grep skill_ready_pr "skills/teach-review/SKILL.md" "not a draft"
assert_grep skill_auto_push "skills/teach-review/SKILL.md" "auto_push"
assert_grep skill_refuse "skills/teach-review/SKILL.md" "not generalizable"
assert_grep skill_worktree "skills/teach-review/SKILL.md" "worktree"
assert_grep cmd_invoke "commands/csp-teach-review.md" "teach-review"
assert_grep hitl_heading "skills/hitl-choice/SKILL.md" "### Teach-review miss"
assert_grep token_miss "skills/hitl-choice/SKILL.md" '`miss`'
assert_grep token_no_miss "skills/hitl-choice/SKILL.md" '`no_miss`'
assert_grep token_project_secret "skills/hitl-choice/SKILL.md" '`project_secret`'
assert_grep dest_heading "skills/hitl-choice/SKILL.md" "### Capture-escape destination"
assert_grep protocol_secret_only "skills/engineer-review/references/review-learn-protocol.md" "project_secret"
assert_grep protocol_no_auto "skills/engineer-review/references/review-learn-protocol.md" "Do not capture from a settled report without"
assert_grep er_secret "agents/csp-engineer-reviewer.md" "project_secret"
assert_grep er_no_auto "agents/csp-engineer-reviewer.md" "Do not auto-capture"
assert_grep er_skill_secret "skills/engineer-review/SKILL.md" "project_secret"
assert_grep pr_secret "agents/csp-pr-reviewer.md" "project_secret"
assert_grep pr_skill_secret "skills/pr-review/SKILL.md" "project_secret"
assert_grep capture_dest "commands/csp-capture-escape.md" "Capture-escape destination"
assert_grep capture_teach "commands/csp-capture-escape.md" "teach-review"
assert_grep capture_secret "commands/csp-capture-escape.md" "project_secret"
assert_grep template_private "skills/engineer-review/references/review-learnings-template.md" "must not enter the shared kit"
assert_grep er_agent_gate "agents/csp-engineer-reviewer.md" "Teach-review miss"
assert_grep er_skill_gate "skills/engineer-review/SKILL.md" "Teach-review miss"
assert_grep pr_agent_gate "agents/csp-pr-reviewer.md" "Teach-review miss"
assert_grep pr_skill_gate "skills/pr-review/SKILL.md" "Teach-review miss"
assert_grep er_no_kit_git "agents/csp-engineer-reviewer.md" "never edit kit git"
assert_grep pr_invoke "agents/csp-pr-reviewer.md" "teach-review"
assert_grep readme_skill "README.md" "teach-review"
assert_grep readme_cmd "README.md" "/csp-teach-review"
assert_grep flow_teach "docs/superpowers/pipeline-flow.md" "teach-review"
assert_grep flow_ready_pr "docs/superpowers/pipeline-flow.md" "ready-for-review pull request"
assert_grep html_ready_pr "docs/superpowers/pipeline-flow.html" "ready-for-review pull request"
assert_grep dogfood_miss "docs/superpowers/dogfood/engineer-review-checklist.md" "Teach-review miss"
# Post-miss pipeline continue (positive) — phrases unique to the continue wire (not the Propose commit preset alone)
# Patterns use single quotes so backticks are literal for grep -E
assert_grep hitl_miss_continue "skills/hitl-choice/SKILL.md" 'continue to skill `propose-commit`'
assert_grep er_agent_propose_after_miss "agents/csp-engineer-reviewer.md" "propose-commit"
assert_grep er_agent_no_end_on_land "agents/csp-engineer-reviewer.md" "Do not end the turn"
assert_grep skill_return_caller "skills/teach-review/SKILL.md" "return to the caller"
assert_grep skill_never_terminal "skills/teach-review/SKILL.md" "never a pipeline terminal"
assert_grep skill_never_invoke_propose "skills/teach-review/SKILL.md" 'Never invoke skill `propose-commit`'
assert_grep dogfood_pipeline_continue "docs/superpowers/dogfood/engineer-review-checklist.md" "orientation strip"
# Bare teach / capture must not auto-start propose-commit (negative; avoid false-fail on "never invoke")
assert_not_grep cmd_no_auto_propose "commands/csp-teach-review.md" "propose-commit"
assert_not_grep skill_no_handoff_propose "skills/teach-review/SKILL.md" "next_skill: propose-commit"
assert_not_grep capture_no_propose "commands/csp-capture-escape.md" "propose-commit"
if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
