#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q -- "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_not_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q -- "$pattern" "$ROOT/$path"; then
    echo "FAIL $name: /$pattern/ unexpectedly in $path" >&2
    fail=1
  else
    echo "OK   $name"
  fi
}

assert_grep fetch_score "skills/jira-fetch/SKILL.md" "trajectory-cases.py score"
assert_grep fetch_case "skills/jira-fetch/SKILL.md" "fetch-failure-stops"
assert_grep fetch_skip "skills/jira-fetch/SKILL.md" "skip score"
assert_grep fetch_exact_input "skills/jira-fetch/SKILL.md" '--invocation "/start-task PROJ-1"'
assert_not_grep fetch_no_live_input "skills/jira-fetch/SKILL.md" "(live|real) invocation string"
assert_grep start_score "commands/start-task.md" "fetch-failure-stops"
assert_grep cpr_score "skills/create-pr/SKILL.md" "trajectory-cases.py score"
assert_grep cpr_case "skills/create-pr/SKILL.md" "create-pr-draft-never-merge"
assert_grep cpr_before_ready "skills/create-pr/SKILL.md" "before.*gh pr ready|before applying"
assert_grep cpr_after_ask "skills/create-pr/SKILL.md" "after.*Pipeline finale"
assert_grep cpr_four_tokens "skills/create-pr/SKILL.md" "keep_draft,ready,keep_draft_jira,ready_jira"
assert_grep cpr_score_four_only "skills/create-pr/SKILL.md" "[Ss]core.*only.*four-token|only.*four-token.*score"
assert_grep cpr_skip_two_tokens "skills/create-pr/SKILL.md" "two-token.*jira_key.*not known.*skip score|skip score.*two-token.*jira_key.*not known"
assert_grep cpr_observe_pr_state "skills/create-pr/SKILL.md" 'gh pr view.*--json isDraft'
assert_grep cpr_record_ready "skills/create-pr/SKILL.md" 'record end.*--pull-request ready'
assert_grep cpr_skip_review_like "skills/create-pr/SKILL.md" 'already Review-like.*skip score|skip score.*already Review-like'
assert_grep cpr_progress_only_when_scoring "skills/create-pr/SKILL.md" '--jira-status "In Progress".*only when scoring'
assert_grep dogfood "docs/superpowers/dogfood/jira-ac-router-finale-checklist.md" "trajectory-wiring-test.sh"
assert_grep readme "README.md" "fetch-failure-stops"
assert_grep hitl_heading "skills/hitl-choice/SKILL.md" "### Trajectory fail"
assert_grep token_gen "skills/hitl-choice/SKILL.md" '`generalize`'
assert_grep token_skip "skills/hitl-choice/SKILL.md" '`skip`'
assert_grep fetch_ask "skills/jira-fetch/SKILL.md" "Trajectory fail"
assert_grep cpr_ask "skills/create-pr/SKILL.md" "Trajectory fail"
assert_grep capture_fail "commands/capture-escape.md" "FAIL "
assert_grep readme_gen "evals/trajectories/README.md" "generalize"
assert_grep readme_human_confirm "evals/trajectories/README.md" "wait for the human to confirm.*before.*git commit"
assert_grep readme_show_json "evals/trajectories/README.md" "[Ss]how.*validated case JSON|[Dd]isplay.*validated case JSON"
assert_not_grep readme_no_diff_alt "evals/trajectories/README.md" "case JSON or"
assert_grep fetch_show_json "skills/jira-fetch/SKILL.md" "[Ss]how.*validated case JSON|[Dd]isplay.*validated case JSON"
assert_not_grep fetch_no_diff_alt "skills/jira-fetch/SKILL.md" "case JSON or"
assert_grep cpr_show_json "skills/create-pr/SKILL.md" "[Ss]how.*validated case JSON|[Dd]isplay.*validated case JSON"
assert_not_grep cpr_no_diff_alt "skills/create-pr/SKILL.md" "case JSON or"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FETCH_LEDGER="$TMP/fetch-failure-stops.json"
CREATE_PR_LEDGER="$TMP/create-pr-draft-never-merge.json"

python3 "$ROOT/scripts/trajectory-cases.py" record init \
  --ledger "$FETCH_LEDGER" --case-id fetch-failure-stops \
  --invocation "/start-task PROJ-1" --fetch fail
python3 "$ROOT/scripts/trajectory-cases.py" record stage \
  --ledger "$FETCH_LEDGER" jira-fetch
python3 "$ROOT/scripts/trajectory-cases.py" record artifact \
  --ledger "$FETCH_LEDGER" --kind report --name stop-paste-ticket
python3 "$ROOT/scripts/trajectory-cases.py" record dump --ledger "$FETCH_LEDGER"
fetch_score="$(
  python3 "$ROOT/scripts/trajectory-cases.py" score \
    --kit-root "$ROOT" --run "$FETCH_LEDGER"
)"
echo "$fetch_score"
if [[ "$fetch_score" != *"PASS fetch-failure-stops"* ]]; then
  echo "FAIL fetch executable score did not pass" >&2
  exit 1
fi

python3 "$ROOT/scripts/trajectory-cases.py" record init \
  --ledger "$CREATE_PR_LEDGER" --case-id create-pr-draft-never-merge \
  --invocation "skill create-pr" --fetch ok --jira-class feature
python3 "$ROOT/scripts/trajectory-cases.py" record stage \
  --ledger "$CREATE_PR_LEDGER" create-pr
python3 "$ROOT/scripts/trajectory-cases.py" record stage \
  --ledger "$CREATE_PR_LEDGER" pipeline-finale-hitl
python3 "$ROOT/scripts/trajectory-cases.py" record artifact \
  --ledger "$CREATE_PR_LEDGER" --kind github --name draft-pull-request
python3 "$ROOT/scripts/trajectory-cases.py" record gate \
  --ledger "$CREATE_PR_LEDGER" --gate pipeline-finale \
  --tokens keep_draft,ready,keep_draft_jira,ready_jira
python3 "$ROOT/scripts/trajectory-cases.py" record end \
  --ledger "$CREATE_PR_LEDGER" --pull-request draft \
  --review-report absent --jira-status "In Progress"
python3 "$ROOT/scripts/trajectory-cases.py" record dump --ledger "$CREATE_PR_LEDGER"
create_pr_score="$(
  python3 "$ROOT/scripts/trajectory-cases.py" score \
    --kit-root "$ROOT" --run "$CREATE_PR_LEDGER"
)"
echo "$create_pr_score"
if [[ "$create_pr_score" != *"PASS create-pr-draft-never-merge"* ]]; then
  echo "FAIL create-pr executable score did not pass" >&2
  exit 1
fi

echo "ALL PASS"
