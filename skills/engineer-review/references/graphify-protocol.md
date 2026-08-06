# Graphify protocol (token budget)

Shared detect / query / fallback rules for **single-repo** engineer-review scoping and for callers that need compact architecture context. Multi-repo discovery still follows [`multi-repo-protocol.md`](multi-repo-protocol.md); this file owns the shared “prefer when present, never require” contract.

## Policy

- **Preferred when present.** If a graphify build exists and can answer, use it to narrow deep-reads and answer call/impact questions instead of broad repo walks or pasting large diffs.
- **Absent = current path.** If artifacts or the CLI are missing, or a query cannot answer, continue with `git diff` + chunking + targeted reads. Do not fail, block, or ask the user to install graphify mid-review.
- **Never rebuild during review.** Do not run a full `graphify` build/regenerate under review. Only read existing artifacts and run `graphify query` against them. Generating or refreshing a graph remains optional outside this protocol (e.g. patterns phase may offer it; never invent a rebuild).

## Detect

Check the **current repo root** first, then the **workspace parent** (folder that owns sibling repos) when reviewing in a multi-repo layout:

```bash
test -f graphify-out/GRAPH_REPORT.md || test -f graphify-out/graph.json
```

Treat graphify as:

| State | Meaning |
|-------|---------|
| `used` | Artifacts present and at least one query/report read answered usefully |
| `absent` | Neither file exists at repo root or workspace parent |
| `unqueryable` | Artifacts missing **or** CLI unavailable **or** query/report cannot answer the asked question |

Coverage must note `graphify: used|absent|unqueryable`.

## Compact sources (token order)

Prefer the cheapest source that answers the question:

1. Short excerpts from `graphify-out/GRAPH_REPORT.md` (headings / relevant modules only — not the whole file when it is huge).
2. `graphify query "…"` with a focused question.
3. **Never** paste full `graphify-out/graph.json` into orchestrator or phase context.

## Single-repo queries

From the repo that owns `graphify-out/` (or the workspace parent when that is where the build lives):

```bash
graphify query "modules impacted by: <comma-separated changed paths>"
graphify query "what calls / is called by: <symbol or path>"
```

Use the impact query after `git diff --name-only` to prioritize deep-read paths and smarter chunk boundaries (group by graph modules when that is tighter than top-level directory alone). Use callers/callees queries inside architecture, deadcode, logic, and performance when they would otherwise walk “neighbors” by path heuristics.

Pass only a compact **`impact_hint`** upward/to phases: short module names and/or path prefixes (typically a few dozen tokens), never the raw graph.

## Orchestrator hook

After computing the changed file list / `--numstat`, **before** chunking:

1. If the range exceeds catastrophic caps in [`phase-protocol.md`](phase-protocol.md) (200 files / 50k LOC), abort and ask to narrow — do not run graphify or chunk fan-out.
2. Run detect.
3. If available, run the impact query (or read the matching `GRAPH_REPORT.md` section).
4. Prefer graph modules for chunk boundaries when files > 40 or LOC > 2500; otherwise use the hint only to prioritize deep-reads within the same caps.
5. Pass `graphify_available: true` and optional `impact_hint` into phase inputs.
6. If absent/unqueryable — **no-op**: identical to today’s `git diff` + directory/package chunking.

Caps in [`phase-protocol.md`](phase-protocol.md) (40 files / 2500 LOC for chunks; 200 files / 50k LOC abort) still apply whether or not graphify answered.

## Phase hook

When `graphify_available` is true (or detect succeeds inside the phase):

- Prefer graphify callers/callees / impact before expanding into immediate path neighbors or sampling the whole tree.
- Prefer `GRAPH_REPORT.md` / query for “what calls what” and layering questions.

When false or unqueryable: keep the phase’s existing diff-scoped / patterns-file behavior unchanged.

## Multi-repo

Workspace-parent discovery and cross-repo impact queries remain documented in [`multi-repo-protocol.md`](multi-repo-protocol.md). That protocol’s detect checks and “absent or unqueryable” language match this file; do not create `multi-repo.json` when graphify answers successfully.

## Interaction impact extras (R3)

When changed paths include `store/auth*`, `*Scope*`, `*Teardown*`, `services/auth*`, API cache reset / invalidate helpers, global loading gates, or equivalent session/token modules:

1. Run the normal impact query on those paths.
2. **Force-include** navigation/layout shells and global overlays that stay mounted across the trigger route — including files that call membership/org (or equivalent) token hooks — even if unchanged. Diff-only lists are insufficient for global side effects.
3. Never rely on a graphify path between RTK endpoint symbols alone: query/mutation symbols often collapse in the graph; a path edge ≠ the runtime refetch graph after `resetApiState`.

When the diff also touches filter-in-menu / overlay hosts with nested stateful inputs, include the host component and its Menu/Popover prop construction in the deep-read set (supports **R4**).

Use this neighborhood when logic/architecture walk [`interaction-replay-checklist.md`](interaction-replay-checklist.md) (auth detail: [`auth-rtk-checklist.md`](auth-rtk-checklist.md)).
