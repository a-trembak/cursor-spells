# Multi-Repo Review Supervisor — Design

**Date:** 2026-07-22
**Status:** Approved
**Depends on:** engineer-review orchestrator kit (merged)

## Problem

A single task frequently spans multiple repositories at once — e.g. a Java/Spring API, a React web app, and a React Native app changing together. Running `engineer-reviewer` per repo by hand misses **cross-repo contract drift** (an endpoint removed in the API but still called by the web client, a shared type changed on one side only) and produces fragmented, per-repo reports with no single human-in-the-loop gate.

## Goals

- Add a **supervisor** layer above `engineer-reviewer` that fans out one orchestrator per changed repo and runs them in parallel.
- Add a **cross-repo phase** that detects contract/interface drift between repos.
- **Single HITL gate** for the whole multi-repo task (not one per repo).
- **Auto-route:** only engage the supervisor when 2+ repos changed; a single-repo task keeps using `engineer-reviewer` unchanged.
- **Repo discovery** with explicit path override, graphify as the preferred source when no paths are provided, or a parent `multi-repo.json` / sibling-scan fallback when graphify is absent or unqueryable.
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

1. **Explicit args (override, v1).** `/multi-review <path...>` supplies the repo set directly for that run. Stack heuristics still apply per path. Graphify may still be used later for cross-repo impact among those repos, but it must not replace or expand the chosen set.

2. **Graphify (preferred when no explicit paths).** If a workspace-level graphify build exists (parent dir over the repos, `graphify-out/`), query it:
   - map of repos and their languages/stacks
   - impact of the changed files across repos (`graphify query "modules impacted by <changed files>"`)
   No `multi-repo.json` is created in this mode; graphify is the source of truth.

3. **Parent `multi-repo.json` (fallback when no explicit paths).** If graphify is absent or unqueryable, read `<workspace-parent>/.cursor/multi-repo.json` when it exists.

4. **Sibling scan (last fallback when no explicit paths).** If graphify is absent or unqueryable and no parent file is available, scan sibling directories of the current repo (one level up) and classify each:
     - `pom.xml` / `build.gradle*` / `*.java` → `java-spring`
     - `package.json` with `react-native`/`expo` → `react-native`
     - `package.json` with `react`/`next` → `react-web`
     - `tsconfig.json` only → `typescript`
   - In `finish-plan` routing, keep this scan in memory only. Write **`<workspace-parent>/.cursor/multi-repo.json`** (parent folder that contains the sibling repos — never inside a single leaf repo) only after a multi-repo run is confirmed, or when `/multi-review --refresh` explicitly requests it.

5. **Ticket-driven discovery (v1.1 follow-up).** Jira (primary) and Linear (secondary) via MCP: resolve ticket → extract linked repos/PRs → feed supervisor. Not required for v1; core routing works without it.

### Probe vs persist

- **Probe (non-mutating):** used by `finish-plan` routing. It may read graphify, read existing parent `.cursor/multi-repo.json`, or scan siblings in memory, but it does not write `multi-repo.json`.
- **Persist (mutating):** write or refresh parent `.cursor/multi-repo.json` only when a multi-repo run is confirmed and graphify is absent or unqueryable, or when `/multi-review --refresh` explicitly requests it. Explicit-path runs do not persist; the paths are run-local.

### `multi-repo.json` shape (fallback only)

Lives at **workspace parent** `.cursor/multi-repo.json`:

```json
{
  "generatedBy": "cursor-spells finish-plan",
  "generatedAt": "2026-07-22T20:00:00Z",
  "repos": [
    { "path": "./api",    "stack": "java-spring" },
    { "path": "./web",    "stack": "react-web" },
    { "path": "./mobile", "stack": "react-native" }
  ]
}
```

Paths are relative to the workspace parent.

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
  1. Discover repos + changed ranges (explicit args → graphify → multi-repo.json → sibling scan).
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

Output: **always `clarify`** — never auto-apply cross-repo contract changes in v1 (even trivial client renames). Each item tagged with the repos involved and severity. IDs use a `C_CR` prefix to distinguish from per-repo `C`.

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
- Cross-repo findings always require clarification; per-repo P0/P1 unambiguous fixes still auto-applied by each orchestrator exactly as today.

## Success criteria

- 1 changed repo → `engineer-reviewer` runs, supervisor never engages.
- 2+ changed repos → supervisor runs per-repo reviewers in parallel + cross-repo phase.
- With graphify: repos + impact resolved from the graph, no `multi-repo.json` created.
- Without graphify: `.cursor/multi-repo.json` is generated only after a multi-repo run is confirmed, or on explicit `/multi-review --refresh`; single-repo `finish-plan` probes do not write it.
- Single HITL gate; unified report with a distinct Cross-repo impact section.
- No behavior change for existing single-repo users.

## Decisions (locked)

1. **`multi-repo.json` location:** workspace parent `.cursor/multi-repo.json` (folder that owns sibling repos).
2. **Cross-repo fixes:** always clarify in v1; no auto-apply of contract changes.
3. **Ticket discovery:** deferred to **v1.1** after core ships.
   - v1: `/multi-review` explicit paths → graphify → `multi-repo.json` fallback → sibling scan.
   - v1.1: Jira MCP (primary) + Linear MCP (secondary) ticket → repo resolution.
   - Rationale for split: core routing does not need a ticket tracker; Jira/Linear MCP auth and field shapes are a separate failure surface and should not block the supervisor.

## Out of scope for v1 (tracked for v1.1)

- Jira ticket → repos/PRs discovery (primary tracker)
- Linear ticket → repos/PRs discovery (secondary)
- Any cross-repo auto-apply heuristics
