---
description: Audit an implementation plan for complexity, risk, scope drift, and (for bug-fix plans) root-cause / regression quality before coding starts
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
4. If `Verdict` is `blocked` or `clear pending accept`, stop and wait for the user to either revise the plan and re-run this command, or reply `accept F<id>` for a specific finding.

## Notes

- This command never edits the plan or any source file — it only reports.
- Do not proceed to implementation while `Verdict` is `blocked`. If `Verdict` is `clear pending accept`, the human must reply `accept F<id>` for each remaining accept-risk finding (or revise the plan) before implementation starts. Only a `clear` verdict means nothing is outstanding.
- In the `/start-task` pipeline, prefer `/approve-plan` so the human approves the plan before this critic runs automatically.
