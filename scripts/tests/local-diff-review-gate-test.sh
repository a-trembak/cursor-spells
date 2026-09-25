#!/usr/bin/env bash
# Contract: pipeline local-diff-review-gate before propose-commit.
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

assert_no_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path" 2>/dev/null; then
    echo "FAIL $name: /$pattern/ unexpectedly in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file "skills/local-diff-review-gate/SKILL.md"
assert_file "skills/engineer-review/SKILL.md"
assert_file "skills/hitl-choice/SKILL.md"
assert_file "rules/hitl-askquestion.mdc"
assert_file "agents/csp-engineer-reviewer.md"

assert_grep gate_name "skills/local-diff-review-gate/SKILL.md" "^name: local-diff-review-gate$"
assert_grep gate_approve "skills/local-diff-review-gate/SKILL.md" "approve-diff"
assert_grep gate_comment "skills/local-diff-review-gate/SKILL.md" "comment"
assert_grep gate_plugin "skills/local-diff-review-gate/SKILL.md" "review-local-diff"
assert_grep gate_kind "skills/local-diff-review-gate/SKILL.md" "local-diff-review/comments"
assert_grep gate_no_commit "skills/local-diff-review-gate/SKILL.md" "Do \\*\\*not\\*\\* \`git commit\`|Never commit"
assert_grep gate_no_pr "skills/local-diff-review-gate/SKILL.md" "pull request"
assert_grep gate_run_log "skills/local-diff-review-gate/SKILL.md" "stage local-diff-review"
assert_grep gate_missing "skills/local-diff-review-gate/SKILL.md" "skipped-missing-plugin"
assert_grep gate_clean "skills/local-diff-review-gate/SKILL.md" "skipped-clean"
assert_grep gate_one_repo "skills/local-diff-review-gate/SKILL.md" "never.*two|Never.*two|one repo at a time|one dirty repo"
assert_grep gate_no_vendor "skills/local-diff-review-gate/SKILL.md" "Do not vendor|do not vendor"
assert_grep gate_manual_skip "skills/local-diff-review-gate/SKILL.md" "Manual.*does not auto-start|Not.*manual"

assert_grep er_step15 "skills/engineer-review/SKILL.md" "local-diff-review-gate"
assert_grep er_before_propose "skills/engineer-review/SKILL.md" "local-diff-review-gate.*propose-commit|propose-commit"
assert_grep er_residual "skills/engineer-review/SKILL.md" "local-diff-review-gate.*once more|once more.*propose-commit"
assert_grep er_manual "skills/engineer-review/SKILL.md" "does \\*\\*not\\*\\* auto-start \`local-diff-review-gate\`"

assert_grep agent_gate "agents/csp-engineer-reviewer.md" "local-diff-review-gate"
assert_grep multi_gate "agents/csp-multi-repo-supervisor.md" "local-diff-review-gate"

assert_grep hitl_preset "skills/hitl-choice/SKILL.md" "Local Diff Review gate"
assert_grep hitl_approve_diff "skills/hitl-choice/SKILL.md" "approve-diff"
assert_grep hitl_comment_token "skills/hitl-choice/SKILL.md" "Open Local Diff Review canvas"
assert_grep rule_tokens "rules/hitl-askquestion.mdc" "approve-diff"

assert_grep start_full "commands/csp-start-task.md" "local-diff-review-gate"
assert_grep start_fast "commands/csp-start-task.md" "local-diff-review-gate"
assert_grep start_issue "commands/csp-start-issue-task.md" "local-diff-review-gate"
assert_grep propose_when "skills/propose-commit/SKILL.md" "local-diff-review-gate"

assert_grep flow_md "docs/superpowers/pipeline-flow.md" "local-diff-review-gate"
assert_grep flow_html "docs/superpowers/pipeline-flow.html" "local-diff-review-gate"
assert_grep readme "README.md" "local-diff-review-gate"

assert_no_grep gate_not_vendor_body "skills/local-diff-review-gate/SKILL.md" "useCanvasState\\(\"outbound\"\\).*FILES"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
