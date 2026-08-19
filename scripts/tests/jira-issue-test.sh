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

assert_eq norm_in_progress "inprogress" "$(jira_normalize_status "In Progress")"
assert_eq norm_hyphen "inprogress" "$(jira_normalize_status "in-progress")"
assert_eq norm_review "inreview" "$(jira_normalize_status "In Review")"

match_ip="$(jira_status_matches_target in_progress "In Progress" && echo yes || echo no)"
assert_eq match_in_progress "yes" "$match_ip"
match_doing="$(jira_status_matches_target in_progress "Doing" && echo yes || echo no)"
assert_eq match_doing "yes" "$match_doing"
match_todo="$(jira_status_matches_target in_progress "To Do" && echo yes || echo no)"
assert_eq match_todo_not_in_progress "no" "$match_todo"

match_rev="$(jira_status_matches_target review "Review" && echo yes || echo no)"
assert_eq match_review "yes" "$match_rev"
match_in_rev="$(jira_status_matches_target review "In Review" && echo yes || echo no)"
assert_eq match_in_review "yes" "$match_in_rev"
match_code_rev="$(jira_status_matches_target review "Code Review" && echo yes || echo no)"
assert_eq match_code_review "yes" "$match_code_rev"
match_rfr="$(jira_status_matches_target review "Ready for Review" && echo yes || echo no)"
assert_eq match_ready_for_review "yes" "$match_rfr"
match_ip_as_rev="$(jira_status_matches_target review "In Progress" && echo yes || echo no)"
assert_eq match_in_progress_not_review "no" "$match_ip_as_rev"

picked="$(printf '11\tTo Do\n21\tIn Progress\n31\tDone\n' | jira_pick_transition_id in_progress)"
assert_eq pick_in_progress "21" "$picked"
picked_rev="$(printf '11\tStart Progress\n41\tIn Review\n' | jira_pick_transition_id review)"
assert_eq pick_review "41" "$picked_rev"
picked_none="$(printf '11\tTo Do\n31\tDone\n' | jira_pick_transition_id review || true)"
assert_eq pick_none "" "$picked_none"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
