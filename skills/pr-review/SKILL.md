---
name: pr-review
description: >-
  Use when reviewing a GitHub pull request (URL, number, or current branch's
  PR) with the same multi-phase engineer-review pipeline. Resolves the PR
  diff range, then runs engineer-reviewer. Feedback must include code snippets,
  clickable file:line links, and english-humanizer prose. Default report-only;
  optional apply for the author's own checkout. Use for /pr-review or
  "review this PR".
---

# PR Review

Thin wrapper around `engineer-review` / `engineer-reviewer` for **pull-request** entry. Same phase agents and skill-map — different input resolution, default fix policy, and **stricter user-facing feedback** ([references/feedback-format.md](references/feedback-format.md)).

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

1. Resolve PR + SHAs (above). Record PR number, title, URL, `HEAD_SHA`, owner/repo in Coverage.
2. Read and follow skill `engineer-review` for stack detection, budget/chunking, patterns, phase dispatch, lint-first, verify pass, merge — **except**:
   - Skip the post-plan HITL gate (user already asked for PR review).
   - Default `mode`: **find only** (report-only). Run apply only if the user passed `apply` (or explicitly asked to fix in-repo).
3. Early Figma ask on frontend unless `no-figma`.
4. Dispatch the same phase agents as `engineer-reviewer` (`review-lint` … `review-figma-markup`). Ask phases to return `start_line` / `end_line` / `snippet` on findings when possible.
5. **Assemble feedback** per [references/feedback-format.md](references/feedback-format.md) — **not** the bare engineer-review one-liner list:
   - For every finding with a `path`, ensure line range + code snippet (backfill via `git show <HEAD_SHA>:path` / file read if the phase omitted them). Drop findings you cannot locate in code unless they are explicitly “missing code” with a nearby quote.
   - Add Cursor path links and GitHub `blob/<HEAD_SHA>/…#L…` links.
   - Structure each item as What / Where / Why / Ask-or-fix.
6. **Humanize** all prose with skill `english-humanizer` before showing the report or PR comment draft (paths and code fences unchanged). If missing, apply that skill’s engineer-voice rules inline and note `skill_missing: english-humanizer`.
7. Emit the **PR Review** report from the feedback-format template. Append a short **PR comment draft** (humanized). Do not auto-post to GitHub unless the user asks; then use `gh pr comment` only when they confirm.

## Fix policy

- **Default (report-only):** never edit the working tree; actionable items stay under Findings (Would fix / Ask).
- **`apply`:** same as engineer-review — unambiguous P0/P1 that pass `auto-fix-eligibility.md` only; still clarify the rest.
- Never apply to a dirty unrelated tree; if `apply` and the checkout is not the PR head, stop and ask to check out the PR branch first.

## Multi-repo

Single-repo PRs use this path. If the workspace is multi-repo and the PR touches contracts across siblings, after the PR review note that `/multi-review` / `multi-repo-supervisor` may still be needed for cross-repo drift — do not invent a second PR's diff.

## Context budget

Orchestrator loads this SKILL + feedback-format + `engineer-review` indexes + `english-humanizer` (for the final pass). Phase subagents load stack skills. Do not paste full third-party skill bodies here.
