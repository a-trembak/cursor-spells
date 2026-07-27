---
description: Review a GitHub pull request with the engineer-review phase pipeline (default report-only)
argument-hint: "[PR url|number|branch] [apply] [no-figma]"
---

# /pr-review

Run the **pr-review** flow (orchestrator `pr-reviewer`) — engineer-review phases on a PR diff.

## Arguments

- PR URL, number, or head branch. If omitted, use the open PR for the current branch.
- Optional `apply` — allow unambiguous P0/P1 fixes on the PR head checkout (default: report-only).
- Optional `no-figma` — skip the Figma URL ask.

## Steps

1. Read and follow skill `pr-review` (`skills/pr-review/SKILL.md`).
2. Resolve the PR to `BASE_SHA` / `HEAD_SHA` per `references/pr-resolve.md`.
3. Invoke agent `pr-reviewer` with that range, PR metadata, and mode (`find` or `find`+`apply`).
4. Run shared `evidence-gate.md` (backfill or drop). Emit **PR Review** per `skills/pr-review/references/feedback-format.md`: File/Lines/Jump/GitHub + numbered code fence + What/Why/Ask; `english-humanizer` on prose.
5. If clarifications remain, wait for answers like `C1: A` or `F2: B`, then re-dispatch affected phases and re-emit with the same evidence bar.

## Notes

- Does **not** replace `/finish-plan` → `engineer-reviewer` after plan execution.
- Does **not** auto-post the comment to GitHub; ask before `gh pr comment`.
- Ad-hoc plan audits stay on `/critique-plan` / `/approve-plan`.
- Path-only or snippet-less findings are a hard failure — backfill or drop before showing the user.
