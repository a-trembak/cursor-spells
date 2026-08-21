#!/usr/bin/env bash
# Contract checks for Jira fetch / router / Pipeline finale / capture-escape.
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

assert_no_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ unexpectedly in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_file "skills/jira-fetch/SKILL.md"
assert_file "skills/jira-transition/SKILL.md"
assert_file "commands/capture-escape.md"
assert_file "scripts/jira-issue.sh"

assert_grep hitl_pipeline_route "skills/hitl-choice/SKILL.md" "### Pipeline route"
assert_grep hitl_fast_vs_issue "skills/hitl-choice/SKILL.md" "### Fast vs issue"
assert_grep hitl_finale "skills/hitl-choice/SKILL.md" "### Pipeline finale"
assert_grep token_full "skills/hitl-choice/SKILL.md" '`full`'
assert_grep token_fast "skills/hitl-choice/SKILL.md" '`fast`'
assert_grep token_issue "skills/hitl-choice/SKILL.md" '`issue`'
assert_grep token_stay_fast "skills/hitl-choice/SKILL.md" '`stay_fast`'
assert_grep token_keep_draft "skills/hitl-choice/SKILL.md" '`keep_draft`'
assert_grep token_ready "skills/hitl-choice/SKILL.md" '`ready`'
assert_grep token_keep_draft_jira "skills/hitl-choice/SKILL.md" '`keep_draft_jira`'
assert_grep token_ready_jira "skills/hitl-choice/SKILL.md" '`ready_jira`'

assert_grep start_task_fetch "commands/start-task.md" "jira-fetch"
assert_grep start_task_never_auto_fast "commands/start-task.md" "never auto-select"
assert_grep start_task_bug_route "commands/start-task.md" "jira_class.*bug"
assert_grep start_issue_reuse "commands/start-issue-task.md" "do not re-fetch|already-fetched"
assert_grep write_spec_fetch "commands/write-tech-spec.md" "jira-fetch"
assert_grep create_pr_draft_first "skills/create-pr/SKILL.md" "Draft first"
assert_grep create_pr_gh_ready "skills/create-pr/SKILL.md" "gh pr ready"
assert_grep create_pr_comment "skills/create-pr/SKILL.md" "addCommentToJiraIssue"
assert_grep create_pr_review_transition "skills/create-pr/SKILL.md" "jira-transition"
assert_grep create_pr_review_target "skills/create-pr/SKILL.md" "target \`review\`"
assert_grep create_pr_never_merge "skills/create-pr/SKILL.md" "Never merge"
assert_grep start_task_in_progress "commands/start-task.md" "jira-transition"
assert_grep start_task_in_progress_target "commands/start-task.md" "in_progress"
assert_grep start_issue_in_progress "commands/start-issue-task.md" "jira-transition"
assert_grep hitl_ready_review "skills/hitl-choice/SKILL.md" "jira-transition"
assert_grep jira_transition_get "skills/jira-transition/SKILL.md" "getTransitionsForJiraIssue"
assert_grep jira_transition_do "skills/jira-transition/SKILL.md" "transitionJiraIssue"
assert_grep jira_transition_in_progress "skills/jira-transition/SKILL.md" "in_progress"
assert_grep jira_transition_review "skills/jira-transition/SKILL.md" '`review`'
assert_no_grep write_spec_no_transition "commands/write-tech-spec.md" "jira-transition"
assert_grep capture_mode "commands/capture-escape.md" "mode: capture"
assert_grep capture_source "commands/capture-escape.md" "source: production-escape"
assert_grep capture_dest "commands/capture-escape.md" "Capture-escape destination"
assert_grep capture_secret "commands/capture-escape.md" "project_secret"
assert_grep capture_teach "commands/capture-escape.md" "teach-review"
assert_grep install_jira_helper "scripts/install-to-project.sh" "jira-issue.sh"
assert_grep readme_create_pr "README.md" "skills/create-pr"
assert_grep readme_jira_fetch "README.md" "skills/jira-fetch"
assert_grep readme_jira_transition "README.md" "skills/jira-transition"
assert_grep flow_jira_transition "docs/superpowers/pipeline-flow.md" "jira-transition"
assert_no_grep readme_no_stub "README.md" "URL is a stub"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
