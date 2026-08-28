#!/usr/bin/env bash
# Pull-request merge + continuous-integration verdicts (sourceable library).
# Usage: source scripts/pr-merge-ci.sh
# stdin: one GitHub pull-request JSON object, or an array of them
#        (fields: state, url, statusCheckRollup[].status, statusCheckRollup[].conclusion).
# stdout: no_pull_requests | not_merged | pending_ci | ci_failed | all_merged_ci_success

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
}

not_merged = False
ci_failed = False
pending_ci = False

for pr in data:
    state = str(pr.get("state") or "").upper()
    if state != "MERGED":
        not_merged = True
        continue
    checks = pr.get("statusCheckRollup") or []
    for check in checks:
        status = str(check.get("status") or "").upper()
        conclusion = str(check.get("conclusion") or "").upper()
        if conclusion in FAIL_CONCLUSIONS:
            ci_failed = True
            continue
        if status in PENDING_STATUSES or (not status and not conclusion):
            pending_ci = True
            continue
        if conclusion in SUCCESS_CONCLUSIONS:
            continue
        if status in {"COMPLETED", "SUCCESS"} and not conclusion:
            continue
        ci_failed = True

if not_merged:
    print("not_merged")
elif ci_failed:
    print("ci_failed")
elif pending_ci:
    print("pending_ci")
else:
    print("all_merged_ci_success")
'
}
