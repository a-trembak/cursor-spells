---
description: Audit an implementation plan for complexity, risk, and scope drift before coding starts
argument-hint: "[path/to/plan.md]"
---

# /critique-plan

Run the **implementation-critic** agent against an existing plan.

## Arguments

- Optional plan path. If omitted, use the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Steps

1. Read and follow skill `implementation-critic` (`skills/implementation-critic/SKILL.md`).
2. Invoke agent `implementation-critic` with the plan path (and tech spec path, if discoverable).
3. Emit the report per `references/output-schema.md`.
4. If `Verdict: blocked`, stop and wait for the user to either revise the plan and re-run this command, or reply `accept F<id>` for specific accept-risk-eligible findings.

## Notes

- This command never edits the plan or any source file — it only reports.
- Do not proceed to implementation while `Verdict: blocked`. A `clear` or `clear pending accept` verdict (with the human's explicit accepts) is required first.
