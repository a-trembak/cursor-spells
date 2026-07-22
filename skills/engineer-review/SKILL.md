---
name: engineer-review
description: >-
  Use when a plan just finished and human-in-the-loop review gate is next, when
  the user runs /engineer-review or asks for engineer-reviewer, or when
  approving automated post-plan code review across Java/Spring, React,
  TypeScript, or React Native changes.
---

# Engineer Review

Thin orchestrator for multi-phase code review. Keeps the spine small; each phase runs as a separate subagent with its own skill.

## When to Use

- After plan execution, once the user answers the HITL gate (`skip` / `approve` / `done`)
- Manual `/engineer-review` or `@engineer-reviewer`
- Not for drive-by questions that are not a review of a diff/branch

## HITL gate (required before auto-review)

If this run was triggered because a **plan finished**, do **not** start phases until the user replies:

- `skip` — start review now
- `approve` or `done` — start after their own pass
- otherwise treat as “fix first”, then re-ask

Manual `/engineer-review` skips this gate.

## Spine (do this in order)

1. Resolve review range (`base..head`, default current branch vs `main`/`master`/`origin/main`).
2. Detect stack → read [references/skill-map.md](references/skill-map.md).
3. Ensure consumer `.cursor/project-patterns.md` exists (create via patterns agent + [patterns-template.md](references/patterns-template.md) on first run).
4. Dispatch phase subagents per [phase-protocol.md](references/phase-protocol.md). Prefer parallel **find** passes; serialize **apply** when touching the same files.
5. Merge summaries → emit report per [output-schema.md](references/output-schema.md).
6. If **Needs clarification** is non-empty, stop and wait. On answers, re-dispatch only the affected phases with the answers embedded.

## Fix policy

- Apply immediately: unambiguous defects, dead code, obsolete historical comments, clear pattern violations, reinvented helpers that already exist.
- Clarify first: behavior/API/product/design/security tradeoffs, risky deletions, anything without clear evidence.

## Phase agents

| Phase | Agent |
|-------|-------|
| Logic + stack best practices | `review-logic` |
| Project patterns | `review-patterns` |
| Dead code / redundancy / comments | `review-deadcode` |
| Architecture | `review-architecture` |
| Performance | `review-performance` |
| Security (conditional) | `review-security` |
| Figma markup (frontend + URLs) | `review-figma-markup` |

Orchestrator agent: `engineer-reviewer`.

## Context budget

Orchestrator loads this SKILL + reference indexes only. Do **not** paste full third-party skill bodies into the orchestrator. Subagents load stack skills themselves. Pass only compact JSON phase summaries upward.
