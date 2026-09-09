---
description: Multi-repo engineer review (supervisor) for 2+ repositories
argument-hint: "[path ...] [--refresh]"
---

# /csp-multi-review

Run the multi-repo review routing from `skills/engineer-review/references/multi-repo-protocol.md`.

## Arguments

- Paths: optional explicit repository override for this run. When provided, these paths are the repo set; discovery must not replace or expand them.
- `--refresh`: force regeneration of parent `.cursor/multi-repo.json` when graphify is absent or unqueryable.

## Steps

1. Parse paths from args, if any, as `explicit_paths`.
2. Parse `--refresh` as `refresh: true`.
3. Resolve repos:
   - If paths were provided, use exactly those `explicit_paths` for this run. Apply stack heuristics per path. Graphify may still be used later for cross-repo impact among the chosen repos, but must not choose a different repo set.
   - If paths were not provided, follow `multi-repo-protocol.md` discovery:
     - graphify at the workspace parent first;
     - otherwise existing parent `.cursor/multi-repo.json`;
     - otherwise scan siblings in memory.
     - Refresh the parent file only when `--refresh` was supplied and graphify is absent or unqueryable.
4. Detect changed repos with the protocol's changed-repo detection.
5. Route:
   - If changed repo count is **0**, stop and tell the user no changed repos were found.
   - If changed repo count is **1**, run `csp-engineer-reviewer` for that repo. Single-repo behavior is unchanged.
   - If changed repo count is **>= 2**, persist parent `.cursor/multi-repo.json` only when no explicit paths were supplied, graphify is absent or unqueryable, and the repo set came from a sibling scan (or `--refresh` was supplied). Then invoke agent `csp-multi-repo-supervisor` with `explicit_paths` and `refresh` when present.

## Notes

- `multi-repo.json` lives only in the workspace parent `.cursor/` directory, never inside a single leaf repo.
- Do not create `multi-repo.json` when graphify answers successfully.
- Do not create `multi-repo.json` for explicit-path runs; explicit paths are a run-local override.
- Ticket-driven Jira/Linear discovery is deferred to v1.1; do not attempt ticket lookup in v1.
