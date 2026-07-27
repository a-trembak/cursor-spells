---
name: pr-review
description: >-
  Use when reviewing a GitHub pull request (URL, number, or current branch's
  PR) with the same multi-phase engineer-review pipeline. Resolves the PR
  diff range, then runs engineer-reviewer. Default report-only; optional
  apply for the author's own checkout. Use for /pr-review or "review this PR".
---

# PR Review

Thin wrapper around `engineer-review` / `engineer-reviewer` for **pull-request** entry. Same phase agents, skill-map, auto-fix eligibility, and output shape — different input resolution and default fix policy.

## When to Use

- `/pr-review [url|number|branch]` or the user asks to review a PR
- Reviewing someone else's open PR (report-only)
- Reviewing your own PR before merge (`apply` optional)
- Not a substitute for post-plan `/finish-plan` → engineer-review (that path stays unchanged)
- Not for plan critique (`/approve-plan` / `/critique-plan`)

## Arguments

| Token | Effect |
|-------|--------|
| PR URL or `#123` / `123` | Resolve that PR |
| Branch name | Find open PR for that head branch via `gh` |
| (empty) | Open PR for the current branch, else fail and ask |
| `apply` | After find, allow coordinated apply of unambiguous P0/P1 that pass auto-fix eligibility (default is **report-only**) |
| `no-figma` | Skip the Figma ask; treat as `no figma` |

## Resolve PR → review range

Follow [references/pr-resolve.md](references/pr-resolve.md). Summary:

1. Parse PR identity from args (URL / number / branch / current).
2. Use `gh pr view` (JSON) for `baseRefName`, `headRefName`, commits, files, title, body, author.
3. Set `BASE_SHA` / `HEAD_SHA` from the PR (merge-base of base…head, or `gh pr view --json commits` / `baseRefOid`/`headRefOid` when available).
4. Checkout is **not** required for report-only if `gh pr diff` / local fetch can supply the range; prefer local `git fetch` + SHAs so phase agents can `git diff`/`git show` as in engineer-review.
5. If `gh` is missing or the PR is inaccessible: stop and ask for a local base..head or a patch.

## Spine

1. Resolve PR + SHAs (above). Record PR number, title, URL in Coverage.
2. Read and follow skill `engineer-review` for stack detection, budget/chunking, patterns, phase dispatch, lint-first, verify pass, merge — **except**:
   - Skip the post-plan HITL gate (user already asked for PR review).
   - Default `mode`: **find only** (report-only). Run apply only if the user passed `apply` (or explicitly asked to fix in-repo).
3. Early Figma ask on frontend unless `no-figma`.
4. Dispatch the same phase agents as `engineer-reviewer` (`review-lint` … `review-figma-markup`).
5. Emit the report per engineer-review `output-schema.md`, titled **PR Review**, with Coverage including `pr: #<n> <url>`.
6. Append a short **PR comment draft** (English): 5–10 lines max — verdict, must-fix themes, open clarifications. Do not auto-post to GitHub unless the user asks; then use `gh pr comment` only when they confirm.

## Fix policy

- **Default (report-only):** never edit the working tree; list would-be Fixed now under a "Would fix" section or keep them in Needs clarification / Residual with severity.
- **`apply`:** same as engineer-review — unambiguous P0/P1 that pass `auto-fix-eligibility.md` only; still clarify the rest.
- Never apply to a dirty unrelated tree; if `apply` and the checkout is not the PR head, stop and ask to check out the PR branch first.

## Multi-repo

Single-repo PRs use this path. If the workspace is multi-repo and the PR touches contracts across siblings, after the PR review note that `/multi-review` / `multi-repo-supervisor` may still be needed for cross-repo drift — do not invent a second PR's diff.

## Context budget

Orchestrator loads this SKILL + `engineer-review` indexes only. Phase subagents load stack skills. Do not paste full third-party skill bodies here.
