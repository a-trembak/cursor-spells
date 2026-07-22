# Multi-Repo Review Supervisor — Design

**Date:** 2026-07-22
**Status:** Draft (for review)
**Depends on:** engineer-review orchestrator kit (merged)

## Problem

A single task frequently spans multiple repositories at once — e.g. a Java/Spring API, a React web app, and a React Native app changing together. Running `engineer-reviewer` per repo by hand misses **cross-repo contract drift** (an endpoint removed in the API but still called by the web client, a shared type changed on one side only) and produces fragmented, per-repo reports with no single human-in-the-loop gate.

## Goals

- Add a **supervisor** layer above `engineer-reviewer` that fans out one orchestrator per changed repo and runs them in parallel.
- Add a **cross-repo phase** that detects contract/interface drift between repos.
- **Single HITL gate** for the whole multi-repo task (not one per repo).
- **Auto-route:** only engage the supervisor when 2+ repos changed; a single-repo task keeps using `engineer-reviewer` unchanged.
- **Repo discovery** with graphify as the source of truth, or an auto-generated `multi-repo.json` fallback when graphify is absent.
- Unified report: per-repo findings + a dedicated cross-repo impact section.

## Non-goals

- Replacing `engineer-reviewer` or its phase agents (supervisor reuses them as-is).
- Cross-repo automatic fixes to contracts (drift is surfaced as clarify by default; only same-repo unambiguous fixes are auto-applied by the per-repo orchestrators).
- Orchestrating deploys, migrations, or release coordination.
- Monorepo-internal package fan-out (single repo → single orchestrator already covers it; supervisor is for physically separate repos).

## Routing (who runs)

`finish-plan` (and manual entry) decides the route:

```
finish-plan (HITL) / manual
   │
   ├─ detect changed repos (see Discovery)
   │
   ├─ changed repos >= 2 ?
   │     YES → multi-repo-supervisor
   │     NO  → engineer-reviewer   (current behavior, unchanged)
```

Single-repo projects are completely unaffected: no new files are required, no behavior changes.

## Repo discovery

Order of precedence:

1. **Graphify (preferred).** If a workspace-level graphify build exists (parent dir over the repos, `graphify-out/`), query it:
   - map of repos and their languages/stacks
   - impact of the changed files across repos (`graphify query "modules impacted by <changed files>"`)
   No `multi-repo.json` is created in this mode; graphify is the source of truth.

2. **Auto-generated `multi-repo.json` (fallback).** If graphify is not installed/available:
   - On first multi-repo run, scan sibling directories of the current repo (one level up) and classify each:
     - `pom.xml` / `build.gradle*` / `*.java` → `java-spring`
     - `package.json` with `react-native`/`expo` → `react-native`
     - `package.json` with `react`/`next` → `react-web`
     - `tsconfig.json` only → `typescript`
   - Write `.cursor/multi-repo.json` in the workspace/current repo `.cursor/`.
   - Later runs read that file (regenerate only if a listed path is missing or `--refresh`).

3. **Explicit args / ticket (override).** `/multi-review <path...>` or a Linear/Jira ticket (via MCP) can supply repos directly; this overrides discovery for that run.

### `multi-repo.json` shape (fallback only)

```json
{
  "generatedBy": "cursor-spells finish-plan",
  "generatedAt": "2026-07-22T20:00:00Z",
  "repos": [
    { "path": "../api",    "stack": "java-spring" },
    { "path": "../web",    "stack": "react-web" },
    { "path": "../mobile", "stack": "react-native" }
  ]
}
```

## Architecture

```
cursor-spells/
├── agents/
│   ├── multi-repo-supervisor.md   # NEW: top orchestrator
│   └── review-cross-repo.md       # NEW: contract drift via graphify / heuristics
├── commands/
│   └── multi-review.md            # NEW: /multi-review [paths | ticket]
└── skills/engineer-review/references/
    ├── multi-repo-protocol.md     # NEW: supervisor contract + discovery + merge
    └── skill-map.md               # UPDATE: graphify cross-repo usage note
```

Reused unchanged: `engineer-reviewer` and all `review-*` phase agents, `finish-plan` (extended only with the routing check), hooks, patterns cache.

## Flow

```
multi-repo-supervisor
  1. Discover repos + changed ranges (graphify → multi-repo.json → args).
  2. Single HITL gate for the whole task:
       > Task spans: api/ (java), web/ (react), mobile/ (rn)
       > skip / approve / done  (+ Figma URLs if any frontend repo)
  3. Parallel dispatch: one engineer-reviewer per changed repo,
     each with its own BASE..HEAD, stack, patterns cache.
     Each returns its normal JSON summary (Fixed / Clarify / Residual).
  4. Cross-repo phase: review-cross-repo consumes each repo's
     graphify GRAPH_REPORT.md (or falls back to interface heuristics)
     and reports contract drift with ids C_CR1…
  5. Merge into one unified report.
  6. Clarifications answered once, routed to the owning repo's
     orchestrator (or cross-repo) for the follow-up apply round.
```

Context budget: supervisor holds only the repo map + each orchestrator's compact JSON summary + the cross-repo summary. Full diffs and skill bodies never reach the supervisor. Each per-repo orchestrator keeps its own 200k budget with existing chunking.

## Cross-repo phase (`review-cross-repo`)

Detects drift **between** repos, not within a single one:

- **REST/API surface:** endpoints added/removed/changed on the server vs still-referenced calls on clients.
- **Shared types / DTOs / schemas:** a field/type changed on one side only.
- **Events / message contracts:** producer/consumer payload mismatch.
- **Versioned packages:** a shared internal package bumped in one repo but not consumed consistently.

Inputs (cheap, token-efficient):
- Each repo's `graphify-out/GRAPH_REPORT.md` (preferred), or
- The per-repo orchestrators' summaries + targeted reads of changed interface files (fallback).

Output: `clarify`-class items by default (contract decisions are human calls), each tagged with the repos involved and severity. IDs use a `C_CR` prefix to distinguish from per-repo `C`.

## Unified output

```markdown
# Multi-Repo Review

## Repos
- api/ (java-spring)     [3 fixed, 1 clarify]
- web/ (react-web)       [1 fixed, 0 clarify]
- mobile/ (react-native) [0 fixed, 2 clarify]

## Cross-repo impact
- C_CR1 (P0) — api removed GET /users/{id}/settings; web ProfileScreen.tsx
  still calls it. Options: A) restore endpoint  B) update web client
  Repos: api, web

## Per-repo details
### api/
Fixed now / Needs clarification / Residual (standard engineer-review report)
### web/
...
### mobile/
...
```

## Human-in-the-loop

- One gate for the whole task before any repo review starts.
- One consolidated clarification round; answers reference `C…` (per repo) or `C_CR…` (cross-repo). The supervisor routes each answer to the correct orchestrator / cross-repo phase.
- Cross-repo contract changes never auto-applied; per-repo P0/P1 unambiguous fixes still auto-applied by each orchestrator exactly as today.

## Success criteria

- 1 changed repo → `engineer-reviewer` runs, supervisor never engages.
- 2+ changed repos → supervisor runs per-repo reviewers in parallel + cross-repo phase.
- With graphify: repos + impact resolved from the graph, no `multi-repo.json` created.
- Without graphify: `.cursor/multi-repo.json` auto-generated on first run, reused after.
- Single HITL gate; unified report with a distinct Cross-repo impact section.
- No behavior change for existing single-repo users.

## Open questions (for reviewer)

1. Where should `multi-repo.json` live — workspace parent `.cursor/` vs the current repo's `.cursor/`? (Leaning: workspace parent so all repos share it.)
2. Should the cross-repo phase ever auto-apply the trivial client-side fix (e.g. rename a call to match a renamed endpoint), or always clarify? (Leaning: clarify-only in v1.)
3. Ticket-driven discovery (Linear/Jira MCP) — include in v1 or defer to a follow-up? (Leaning: defer; graphify + fallback covers the main flow.)
