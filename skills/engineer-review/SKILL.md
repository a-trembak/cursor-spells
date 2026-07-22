---
name: engineer-review
description: >-
  Use when a plan just finished and human-in-the-loop review gate is next, when
  the user runs /review (or /engineer-review), asks for engineer-reviewer, or when
  approving automated post-plan code review across Java/Spring, React,
  TypeScript, or React Native changes.
---

# Engineer Review

Thin orchestrator for multi-phase code review. Keeps the spine small; each phase runs as a separate subagent with its own skill.

## When to Use

- After plan execution, once the user answers the HITL gate (`skip` / `approve` / `done`) — usually via skill `finish-plan`
- Manual `/engineer-review` or `@engineer-reviewer`
- Not for drive-by questions that are not a review of a diff/branch

## HITL gate (required before auto-review)

If this run was triggered because a **plan finished**, do **not** start phases until the user replies:

- `skip` — start review now
- `approve` or `done` — start after their own pass
- otherwise treat as “fix first”, then re-ask

Prefer skill/command `finish-plan` to set `.cursor/review-gate.pending` reliably.

Manual `/engineer-review` skips this gate.

## Early Figma ask (frontend)

After HITL approval (or at the start of manual review), if stack is `react-web` or `react-native`, ask **before** phase dispatch:

> Any Figma node URLs for markup review? Paste links, or say `no figma`.

Pass URLs into clarifications for `review-figma-markup`. Do not block other phases on the answer if the user already said `no figma`; if they have not answered yet, run non-figma phases first and keep figma skipped until URLs arrive.

## Spine (do this in order)

1. Resolve review range (`base..head`, default current branch vs `main`/`master`/`origin/main`).
2. Detect stack → read [references/skill-map.md](references/skill-map.md).
3. **Budget**: if changed files > 40 or changed LOC > 2500, split into directory/package chunks (see [phase-protocol.md](references/phase-protocol.md)).
4. Ensure consumer `.cursor/project-patterns.md` exists (create via patterns agent + [patterns-template.md](references/patterns-template.md) on first run).
5. Early Figma ask when frontend (above).
6. Dispatch phase subagents per phase-protocol. Prefer parallel **find** passes; serialize **apply** for `unambiguous && (P0|P1)` only.
7. Merge summaries → emit report per [output-schema.md](references/output-schema.md).
8. If **Needs clarification** is non-empty, stop and wait. On answers, re-dispatch only the affected phases with the answers embedded.

## Fix policy

- Apply immediately: unambiguous **P0/P1** (bugs, dead code, obsolete historical comments, clear pattern violations, reinvented helpers).
- **P2** → Residual notes only.
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

Orchestrator agent: `engineer-reviewer`. Plan handoff: `finish-plan`.

## Context budget

Orchestrator loads this SKILL + reference indexes only. Do **not** paste full third-party skill bodies into the orchestrator. Subagents load stack skills themselves. Pass only compact JSON phase summaries upward. Enforce file/LOC caps via chunking.
