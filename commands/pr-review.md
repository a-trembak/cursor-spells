---
description: Review a GitHub pull request with the engineer-review phase pipeline (default report-only; PR Review Canvas on)
argument-hint: "[PR url|number|branch] [apply] [no-figma] [no-canvas]"
---

# /pr-review

Run the **pr-review** flow (orchestrator `pr-reviewer`) — PR Review Canvas for diff orientation, then engineer-review phases on a PR diff.

## Arguments

- PR URL, number, or head branch. If omitted, use the open PR for the current branch.
- Optional `apply` — allow unambiguous P0/P1 fixes on the PR head checkout (default: report-only).
- Optional `no-figma` — skip the Figma URL ask.
- Optional `no-canvas` — skip the PR Review Canvas step (default: build canvas after PR resolve).

## Steps

1. Read and follow skill `pr-review` (`skills/pr-review/SKILL.md`).
2. Resolve the PR to `BASE_SHA` / `HEAD_SHA` per `references/pr-resolve.md`.
3. Unless `no-canvas`: follow `references/canvas.md` — skill `pr-review-canvas` with the resolved PR URL/number (Cursor plugin; do not vendor). Missing plugin → continue with `skill_missing` in Coverage.
4. Invoke agent `pr-reviewer` with that range, PR metadata, and mode (`find` or `find`+`apply`).
5. Run shared `evidence-gate.md` (backfill or drop). Draft full **Findings** (File/Lines/Jump/GitHub + numbered fence) — **never** Verdict/Блокери digest. Validate with `scripts/validate-review-report.sh`; rebuild until exit 0. Then emit; `english-humanizer` on prose. Point at the canvas if built. Optional PR comment draft only as appendix.
6. If clarifications remain, wait for answers like `C1: A` or `F2: B`, then re-dispatch affected phases and re-emit with the same evidence bar.

## Notes

- Does **not** replace `/finish-plan` → `engineer-reviewer` after plan execution.
- Does **not** auto-post the comment to GitHub; ask before `gh pr comment`.
- Ad-hoc plan audits stay on `/critique-plan` / `/approve-plan`.
- Path-only, snippet-less, or Verdict/Blockers digests are a hard failure — backfill/rebuild or drop before showing the user.
- Canvas orients the diff; Findings remain the contractual review output.
