---
name: graphify-pipeline
description: >-
  Use on cursor-spells pipeline stages when a local graphify build exists: detect
  artifacts, run compact impact/caller queries to save tokens, and refresh the
  graph after verified code changes. Engineer-review stays read-only on the graph;
  implement and plan-audit stages may refresh after changes.
---

# Graphify pipeline

Shared graphify usage for **implementation**, **bug-fix**, **plan critique**, and **engineer-review** (review never rebuilds the graph).

## When to Use

- Before coding: scope blast radius from plan paths or symbols (compact `impact_hint`)
- During bug diagnosis: callers/callees instead of repo-wide search in the agent
- During implementation-critic Pass C: regression blast radius from planned paths
- After **verified** code changes (lint/tests green): refresh graph so review uses current structure
- During engineer-review: detect + query only (see [references/review-hook.md](references/review-hook.md))

Skip silently when `state=absent` or `cli_missing` — never block the pipeline.

## Helper script (preferred)

From the consumer project root (or pass `--root`):

```bash
bash "$KIT/scripts/graphify-pipeline.sh" detect --root .
bash "$KIT/scripts/graphify-pipeline.sh" impact-hint --root . --paths "src/foo.ts,src/bar.tsx"
bash "$KIT/scripts/graphify-pipeline.sh" query --root . --question "what calls / is called by: MySymbol"
bash "$KIT/scripts/graphify-pipeline.sh" refresh --root .
```

`$KIT` = cursor-spells kit root (`~/.cursor/cursor-spells-kit-path` or repo `scripts/../`).

Resolve `artifacts_root` from repo `graphify-out/` first, then workspace parent (sibling repos).

## Token rules

1. Prefer script output or short `GRAPH_REPORT.md` excerpts — not full `graph.json`.
2. Pass only a compact **`impact_hint`** (module names / path prefixes) into subagents.
3. Never paste megabyte JSON into chat context.

## Refresh policy

| Stage | Refresh allowed? |
|-------|------------------|
| software-developer / bug-fix **after verify** | **Yes** — run `refresh` per target repo |
| engineer-review / review phases | **No** — read-only queries |
| implementation-critic | **No** — queries only |
| Mid-implementation (before verify) | **No** — wait until tests/lint pass |

On refresh failure: note `graphify_refresh=failed` in handoff; continue handoff — do not block on graphify.

## Stage routing

See [references/stages.md](references/stages.md) for which calling skill loads this file.

## Coverage fields

Handoffs and review reports should include when relevant:

- `graphify: used|absent|unqueryable`
- `graphify_refresh: ok|skipped|failed` (implement paths only)
