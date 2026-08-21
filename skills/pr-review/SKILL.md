---
name: pr-review
description: >-
  Use when reviewing a GitHub pull request (URL, number, or current branch's
  PR) with the same multi-phase engineer-review pipeline. Resolves the PR
  diff range, emits a PR Review Canvas for diff orientation, then runs
  engineer-reviewer. Feedback must include Context, code snippets, clickable
  file:line links, english-humanizer prose, and structured clarify Options
  with a marked Recommendation. Default report-only; optional apply for the
  author's own checkout. Use for /pr-review or "review this PR".
---

# PR Review

Thin wrapper around `engineer-review` / `engineer-reviewer` for **pull-request** entry. Same phase agents and skill-map — different input resolution, default fix policy, **stricter user-facing feedback** ([references/feedback-format.md](references/feedback-format.md)), and a **diff-orientation canvas** via Cursor plugin skill `pr-review-canvas` ([references/canvas.md](references/canvas.md)).

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
| `no-canvas` | Skip the PR Review Canvas step |

## Resolve PR → review range

Follow [references/pr-resolve.md](references/pr-resolve.md). Summary:

1. Parse PR identity from args (URL / number / branch / current).
2. Use `gh pr view` (JSON) for `baseRefName`, `headRefName`, commits, files, title, body, author.
3. Set `BASE_SHA` / `HEAD_SHA` from the PR (merge-base of base…head, or `gh pr view --json commits` / `baseRefOid`/`headRefOid` when available).
4. Checkout is **not** required for report-only if `gh pr diff` / local fetch can supply the range; prefer local `git fetch` + SHAs so phase agents can `git diff`/`git show` as in engineer-review.
5. If `gh` is missing or the PR is inaccessible: stop and ask for a local base..head or a patch.

## Spine

1. Resolve PR + SHAs (above). Record PR number, title, URL, `HEAD_SHA`, owner/repo in Coverage.
2. **PR Review Canvas** (default on) — follow [references/canvas.md](references/canvas.md):
   - Skip if `no-canvas`, or if PR URL/number is unavailable.
   - Otherwise read and follow skill `pr-review-canvas` (Cursor plugin; do not vendor) with the resolved PR URL/number; write the canvas per the Canvas skill.
   - Canvas orients the reviewer (core logic → wiring → boilerplate). It does **not** replace Findings or the evidence gate.
   - If the plugin/skill is missing: continue; note `skill_missing: pr-review-canvas` in Coverage.
3. Read and follow skill `engineer-review` for stack detection, budget/chunking, patterns, phase dispatch, lint-first, verify pass, merge — **except**:
   - Skip the post-plan HITL gate (user already asked for PR review).
   - Default `mode`: **find only** (report-only). Run apply only if the user passed `apply` (or explicitly asked to fix in-repo).
4. Early Figma ask on frontend unless `no-figma`.
5. Dispatch the same phase agents as `engineer-reviewer` (`review-lint` … `review-figma-markup`), including `learned_hints` from kit `learned-misses.md` + consumer `.cursor/review-learnings.md` when present. Phase JSON **must** include `path`, `start_line`, `end_line`, `snippet`, and `context` on every finding; clarify items **must** include structured `options` and prefer `recommended` + `recommendation_why`.
6. **Assemble feedback** per [references/feedback-format.md](references/feedback-format.md), shared [evidence-gate.md](../engineer-review/references/evidence-gate.md), and [forbidden-formats.md](../engineer-review/references/forbidden-formats.md):
   - Require `path` + lines + `snippet` + `context`; backfill with `extract-review-snippet.sh` + `HEAD_SHA` or **drop** the item.
   - **Context** + full Where block including **required** GitHub `blob/<HEAD_SHA>/…#L…` when PR resolve succeeded; numbered code fence.
   - Clarify items: **Options** + **Recommendation** (or explicit “none” — never invent `recommended`).
   - **Never** a Verdict / Blockers / Блокери digest — even if shorter.
   - What / Where / Why / Ask-or-fix.
7. **Humanize** all prose with skill `english-humanizer`, then expand abbreviations with skill `plain-language-chat`, before showing the report or PR comment draft (paths and code fences unchanged). If humanizer is missing, apply that skill’s engineer-voice rules inline and note `skill_missing: english-humanizer`.
8. Write the draft report to a temp file; run `scripts/validate-review-report.sh`. Rebuild until exit 0, then emit. Point at the canvas (if built). Append an optional **PR comment draft** appendix only after Findings. Do not auto-post to GitHub unless the user asks; then use `gh pr comment` only when they confirm.
9. If **Needs clarification** is non-empty, stop and ask via skill **`hitl-choice`** preset **Engineer-review clarify** (sequential `AskQuestion` per `C#`; recommended option labeled; tokens `C1:A`; batch text like `C1: A; C2: B` OK). On answers, re-dispatch affected phases and re-emit with the same evidence bar.
10. After the report is settled, run `review-learn` per [`review-learn-protocol.md`](../engineer-review/references/review-learn-protocol.md) (same self-strengthen loop as engineer-review).
11. **Teach-review miss:** ask `hitl-choice` preset **Teach-review miss**. `no_miss` → stop. `miss` → description then skill `teach-review`. Never edit kit git here.

## Fix policy

- **Default (report-only):** never edit the working tree; actionable items stay under Findings (Would fix / Ask).
- **`apply`:** same as engineer-review — unambiguous P0/P1 that pass `auto-fix-eligibility.md` only; still clarify the rest.
- Never apply to a dirty unrelated tree; if `apply` and the checkout is not the PR head, stop and ask to check out the PR branch first.

## Multi-repo

Single-repo PRs use this path. If the workspace is multi-repo and the PR touches contracts across siblings, after the PR review note that `/multi-review` / `multi-repo-supervisor` may still be needed for cross-repo drift — do not invent a second PR's diff.

## Context budget

Orchestrator loads this SKILL + feedback-format + canvas reference + `engineer-review` indexes + `english-humanizer` + `plain-language-chat` (for the final pass). Load `pr-review-canvas` / Canvas only for the canvas step. Phase subagents load stack skills. Do not paste full third-party or plugin skill bodies here.
