---
description: Multi-repo engineer review (supervisor) for 2+ repositories
argument-hint: "[path ...] [--refresh]"
---

# /multi-review

Run the multi-repo review routing from `skills/engineer-review/references/multi-repo-protocol.md`.

## Arguments

- Paths: optional explicit repository override for this run.
- `--refresh`: force regeneration of parent `.cursor/multi-repo.json` when graphify is absent or unqueryable.

## Steps

1. Parse paths from args, if any, as `explicit_paths`.
2. Parse `--refresh` as `refresh: true`.
3. If paths were not provided, follow `multi-repo-protocol.md` discovery:
   - graphify at the workspace parent first;
   - otherwise parent `.cursor/multi-repo.json`;
   - regenerate the parent file only when missing/stale or `--refresh` was supplied.
4. Detect changed repos with the protocol's changed-repo detection.
5. Route:
   - If changed repo count is **< 2**, tell the user only one repo is changed and run `engineer-reviewer` for the current repo. Single-repo behavior is unchanged.
   - If changed repo count is **>= 2**, invoke agent `multi-repo-supervisor` with `explicit_paths` and `refresh` when present.

## Notes

- `multi-repo.json` lives only in the workspace parent `.cursor/` directory, never inside a single leaf repo.
- Do not create `multi-repo.json` when graphify answers successfully.
- Ticket-driven Jira/Linear discovery is deferred to v1.1; do not attempt ticket lookup in v1.
