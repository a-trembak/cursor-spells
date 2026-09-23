# Multi-repo protocol

Contract for `csp-multi-repo-supervisor`, `finish-plan` routing, and `/csp-multi-review`. Per-repo review reuses `csp-engineer-reviewer` (including its graphify scoping via [`graphify-protocol.md`](graphify-protocol.md)); this document covers discovery, routing, merge, and unified output only.

## Routing algorithm

1. **Resolve** the repo set (see Discovery precedence below).
2. **Detect changed repos** (see Changed-repo detection) for each discovered path.
3. **Route:**
   - If changed repo count is **0** → stop with a message that no changed repos were found.
   - If changed repo count is **1** → invoke `csp-engineer-reviewer` for that repo only and **stop**. Single-repo behavior is unchanged; the supervisor never engages.
   - If changed repo count **≥ 2** → continue as **`csp-multi-repo-supervisor`**: one HITL gate for the whole task, parallel per-repo `csp-engineer-reviewer` dispatch, cross-repo phase, unified merge.

`finish-plan` and manual `/csp-multi-review` both use this algorithm before any review phases run. `finish-plan` uses the non-mutating probe only; it never writes or refreshes parent `.cursor/multi-repo.json` during routing.

## Discovery precedence

Resolve the repo set in this order; stop at the first source that succeeds:

1. **Explicit paths (override, v1).** If the caller provided `explicit_paths` or `/csp-multi-review <path...>` paths, those paths are the repo set for that run. Graphify and parent `.cursor/multi-repo.json` do not replace or expand this set. Stack heuristics still apply per path. Graphify may still be queried later for cross-repo impact among the chosen repos.
2. **Graphify (preferred when no explicit paths).** Workspace-level build under the parent folder that contains sibling repos (`graphify-out/`). Query for repo map and cross-repo impact. **Do not create `multi-repo.json`** when graphify answers successfully.
3. **Parent `.cursor/multi-repo.json` (fallback when no explicit paths).** Read `<workspace-parent>/.cursor/multi-repo.json` if graphify is absent or unqueryable.
4. **Sibling scan (last fallback when no explicit paths).** Scan sibling directories in memory and classify them with stack heuristics. Persist only under the rules in Probe vs persist.

**Deferred (v1.1):** ticket-driven discovery (Jira primary, Linear secondary via MCP). Not required for v1 routing.

## Probe vs persist

Discovery has two modes:

1. **Probe (non-mutating).** Used by `finish-plan` routing. It may read graphify, read an existing parent `.cursor/multi-repo.json`, or scan siblings in memory, but it **MUST NOT** write or refresh `multi-repo.json`.
2. **Persist (mutating).** Write or refresh `<workspace-parent>/.cursor/multi-repo.json` only when:
   - a multi-repo run is confirmed (**≥ 2 changed repos**) and graphify is absent or unqueryable; or
   - `--refresh` was explicitly requested on `/csp-multi-review` and graphify is absent or unqueryable.

Persist never applies when explicit paths were supplied; explicit paths are a run-local override. `multi-repo.json` always lives at the workspace parent `.cursor/` directory, never inside a single leaf repo.

## Graphify queries

Shared detect / compact-source / no-rebuild rules: [`graphify-protocol.md`](graphify-protocol.md). Per-repo `csp-engineer-reviewer` also uses that protocol for single-repo token scoping.

When graphify is available, run from the **workspace parent** (folder that owns sibling repos):

```bash
# From workspace parent
test -f graphify-out/GRAPH_REPORT.md || test -f graphify-out/graph.json
graphify query "list repositories / top-level modules and their stacks"
graphify query "modules impacted by: <comma-separated changed paths>"
```

Use the first query to build the repo → stack map. Use the second after collecting changed paths from git to determine which repos are in scope and which modules may be impacted across repo boundaries.

If both `test` checks fail, fall through to `multi-repo.json` or the fallback scan. Treat graphify as **absent or unqueryable** when the build is missing, the binary is unavailable, or a query cannot answer the repo map (same states as `graphify-protocol.md`).

## Fallback scan

When graphify is absent or unqueryable:

1. From the **workspace parent**, list sibling directories one level up from the current leaf repo.
2. Classify each sibling using stack heuristics:
   - `pom.xml` / `build.gradle*` / `*.java` → `java-spring`
   - `package.json` with `react-native` / `expo` → `react-native`
   - `package.json` with `react` / `next` → `react-web`
   - `tsconfig.json` only (no React deps) → `typescript`
3. In probe mode, keep the result in memory. In persist mode, write **`<workspace-parent>/.cursor/multi-repo.json`** (never inside a single leaf repo):

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

Paths are relative to the workspace parent. Later runs read this file; refresh only under the persist rules above.

## Changed-repo detection

For each repo path from discovery:

```bash
git -C <path> status --porcelain
git -C <path> diff --name-only <base>..<head>
```

A repo is **changed** if either command reports any output. Collect all changed repos; route 0 to a stop message, 1 to `csp-engineer-reviewer`, and ≥ 2 to `csp-multi-repo-supervisor`.

Per-repo `base` and `head` SHAs are resolved independently (default: current branch vs `main` / `master` / `origin/main` within that repo).

## Supervisor inputs/outputs

The supervisor holds only the repo map, compact per-repo JSON summaries, and the cross-repo summary. Full diffs and skill bodies never reach the supervisor.

**Envelope** (internal JSON between supervisor, per-repo orchestrators, and cross-repo phase):

```json
{
  "repos": [
    {
      "path": "./api",
      "stack": "java-spring",
      "base": "<sha>",
      "head": "<sha>",
      "summary": { "...engineer-review phase merge...": true }
    }
  ],
  "cross_repo": {
    "phase": "cross-repo",
    "clarify": [
      {
        "id": "C_CR1",
        "severity": "P0",
        "context": "Profile settings screen loads user prefs on mount.",
        "question": "api removed GET /users/{id}/settings; web ProfileScreen.tsx still calls it.",
        "options": [
          { "id": "A", "label": "Restore endpoint" },
          { "id": "B", "label": "Update web client" }
        ],
        "recommended": "B",
        "recommendation_why": "API removal looks intentional; client should follow the new contract.",
        "repos": ["api", "web"],
        "unambiguous": false
      }
    ],
    "fixed": [],
    "notes": []
  }
}
```

Each repo's `summary` follows the normal `csp-engineer-reviewer` phase merge (see [phase-protocol.md](phase-protocol.md)). Cross-repo output is **always clarify** in v1: `cross_repo.fixed` stays empty; contract drift is never auto-applied.

## Merge rules

1. **Per-repo clarify ids** — renumber globally so unified markdown ids stay unique. Use a repo prefix in the unified report, e.g. `api:C1` or `C1@api`. Keep the original per-repo ids inside each repo's JSON summary.
2. **Cross-repo ids** — always `C_CR1`, `C_CR2`, … Never renumber cross-repo items into per-repo sequences.
3. **Cross-repo findings** — always land in **Needs clarification** (unified markdown) / `cross_repo.clarify` (JSON). **Never** put cross-repo items into `fixed` or **Fixed now**, even when the fix looks trivial (e.g. a client rename after an API removal).
4. **Per-repo fixed** — unchanged from [phase-protocol.md](phase-protocol.md): `fixed` where `applied: true` and severity `P0`/`P1` only.
5. **Residual notes** — per-repo phase `notes` and cross-repo `notes` are merged into each repo's **Residual notes** section or a dedicated cross-repo notes block; do not promote cross-repo items to fixed.

After merge, if any clarification (per-repo or `C_CR*`) is non-empty, stop and wait for one consolidated answer round. Route each answer to the owning repo orchestrator or the cross-repo phase.

## Unified markdown template

Emit this markdown to the user. Keep it scannable. No persona dump, no skill internals.

```markdown
# Multi-Repo Review

## Repos
- api/ (java-spring)     [3 fixed, 1 clarify]
- web/ (react-web)       [1 fixed, 0 clarify]
- mobile/ (react-native) [0 fixed, 2 clarify]

## Cross-repo impact
- C_CR1 (P0) — api removed GET /users/{id}/settings; web ProfileScreen.tsx still calls it.
  - **Context:** Profile settings screen loads user prefs on mount.
  - **Options:** A) restore endpoint  B) **update web client (recommended)**
  - **Recommendation:** B — API removal looks intentional; client should follow the new contract.
  - Repos: api, web

## Per-repo details
### api/
Fixed now / Needs clarification / Residual (standard engineer-review report — each item with **Context**; clarify items with **Options** + **Recommendation**)
### web/
...
### mobile/
...
```

If **Needs clarification** (per-repo or cross-repo) is non-empty, ask via skill **`hitl-choice`** preset **Engineer-review clarify** (sequential `AskQuestion` per item; recommended option labeled). Each sequential question repeats that item’s Context, What, When it shows up, File, Lines, Jump, and numbered fence. Batch letter lists are a **reply shape only**. Text fallback tokens:

> `api:C1:A`, `C_CR1:B`, or batch `api:C1: A; C_CR1: B` (or free text). I will route each answer to the correct repo orchestrator or cross-repo phase and apply agreed per-repo fixes only.

Per-repo detail sections follow [output-schema.md](output-schema.md). Cross-repo items appear only under **Cross-repo impact** and in the clarification prompt — never under **Fixed now**.
