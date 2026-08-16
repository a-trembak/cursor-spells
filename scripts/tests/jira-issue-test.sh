#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../jira-issue.sh
source "$ROOT/scripts/jira-issue.sh"

fail=0
assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL $name: expected [$expected] got [$actual]" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_eq key_bare "ACP-2656" "$(jira_extract_key "ACP-2656")"
assert_eq key_lower "ACP-2656" "$(jira_extract_key "fix acp-2656 please")"
assert_eq key_browse "PROJ-12" "$(jira_extract_key "https://ex.atlassian.net/browse/PROJ-12")"
assert_eq key_selected "ABC-9" "$(jira_extract_key "https://ex.atlassian.net/jira/software/projects/ABC/boards/1?selectedIssue=ABC-9")"
assert_eq key_issues_path "TEAM-100" "$(jira_extract_key "https://ex.atlassian.net/jira/software/projects/TEAM/issues/TEAM-100")"

none="$(jira_extract_key "please implement login" || true)"
assert_eq key_none "" "$none"

assert_eq site_from_url "ex.atlassian.net" "$(jira_extract_site "https://ex.atlassian.net/browse/PROJ-12")"
assert_eq site_from_key "" "$(jira_extract_site "PROJ-12")"

assert_eq class_bug "bug" "$(jira_classify_type "Bug")"
assert_eq class_defect "bug" "$(jira_classify_type "Defect")"
assert_eq class_incident "bug" "$(jira_classify_type "Incident")"
assert_eq class_story "feature" "$(jira_classify_type "Story")"
assert_eq class_task "feature" "$(jira_classify_type "Task")"
assert_eq class_epic "feature" "$(jira_classify_type "Epic")"
assert_eq class_spike "unknown" "$(jira_classify_type "Spike")"
assert_eq class_empty "unknown" "$(jira_classify_type "")"
assert_eq class_subtask "unknown" "$(jira_classify_type "Sub-task")"

looks="$(jira_looks_like_issue "https://ex.atlassian.net/browse/PROJ-12" && echo yes || echo no)"
assert_eq looks_url "yes" "$looks"
looks2="$(jira_looks_like_issue "paste this AC: users can export" && echo yes || echo no)"
assert_eq looks_prose "no" "$looks2"
looks3="$(jira_looks_like_issue "ACP-1" && echo yes || echo no)"
assert_eq looks_key "yes" "$looks3"
looks4="$(jira_looks_like_issue "please fix ACP-2656 in login" && echo yes || echo no)"
assert_eq looks_prose_with_key "no" "$looks4"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
