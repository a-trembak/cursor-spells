#!/usr/bin/env bash
# Pull-request merge + continuous-integration verdicts (sourceable library).
# Usage:
#   source scripts/pr-merge-ci.sh
#   printf '%s' "$json_array" | pr_merge_ci_verdict
#   printf '%s' "$json_array" | bash scripts/pr-merge-ci.sh
# stdin: one GitHub pull-request JSON object, or an array of them
#        (fields: state, url, statusCheckRollup[].status / conclusion / state).
# stdout: no_pull_requests | not_merged | closed_unmerged | pending_ci | ci_failed | all_merged_ci_success

pr_merge_ci_verdict() {
  python3 -c '
import json
import sys

raw = sys.stdin.read().strip()
if not raw:
    print("no_pull_requests")
    raise SystemExit(0)

data = json.loads(raw)
if isinstance(data, dict):
    data = [data]
if not isinstance(data, list) or not data:
    print("no_pull_requests")
    raise SystemExit(0)

SUCCESS_CONCLUSIONS = {"SUCCESS", "SKIPPED", "NEUTRAL"}
FAIL_CONCLUSIONS = {
    "FAILURE",
    "ERROR",
    "CANCELLED",
    "CANCELED",
    "TIMED_OUT",
    "ACTION_REQUIRED",
    "STARTUP_FAILURE",
    "STALE",
}
PENDING_STATUSES = {
    "QUEUED",
    "IN_PROGRESS",
    "WAITING",
    "PENDING",
    "REQUESTED",
    "WAITING_FOR_DEPLOYMENT",
    "EXPECTED",
}
FAIL_STATES = {"FAILURE", "ERROR"}
SUCCESS_STATES = {"SUCCESS"}
PENDING_STATES = {"PENDING", "EXPECTED"}


def classify_check(check):
    conclusion = str(check.get("conclusion") or "").upper()
    status = str(check.get("status") or "").upper()
    state = str(check.get("state") or "").upper()
    if conclusion in FAIL_CONCLUSIONS or state in FAIL_STATES:
        return "fail"
    if status in PENDING_STATUSES or state in PENDING_STATES:
        return "pending"
    if conclusion in SUCCESS_CONCLUSIONS or state in SUCCESS_STATES:
        return "success"
    if status == "COMPLETED" and not conclusion:
        return "pending"
    if not status and not conclusion and not state:
        return "pending"
    return "fail"


closed_unmerged = False
not_merged = False
ci_failed = False
pending_ci = False

for pr in data:
    pr_state = str(pr.get("state") or "").upper()
    if pr_state == "CLOSED":
        closed_unmerged = True
        continue
    if pr_state != "MERGED":
        not_merged = True
        continue
    checks = pr.get("statusCheckRollup") or []
    for check in checks:
        kind = classify_check(check)
        if kind == "fail":
            ci_failed = True
        elif kind == "pending":
            pending_ci = True

if closed_unmerged:
    print("closed_unmerged")
elif not_merged:
    print("not_merged")
elif ci_failed:
    print("ci_failed")
elif pending_ci:
    print("pending_ci")
else:
    print("all_merged_ci_success")
'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  pr_merge_ci_verdict
fi
