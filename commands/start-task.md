---
description: Bootstrap a new task — load Acceptance Criteria, project patterns, and stack, then hand off to the tech spec
argument-hint: "[ac-source]"
---

# /start-task

Thin entry point for beginning a new task. Bootstraps context, then delegates to `/write-tech-spec` — it makes no drafting decisions itself.

## Arguments

- Optional AC source: a ticket id, a file path, or inline text. If omitted, ask for it.

## Steps

1. Read `.cursor/project-patterns.md` in the **current project** if present (create it via the `engineer-review` patterns flow on first use of this kit in a project, if entirely absent).
2. Detect the project's stack mechanically (same signals as `skill-map.md`'s stack-detection table: `package.json`, `pom.xml`, `docker-compose`, dependency names) — no reasoning call, a table lookup.
3. Hand off to `/write-tech-spec` with the AC source, the patterns file path (if found), and the detected stack label.

## Notes

- This command never drafts a tech spec itself — it only prepares context for `/write-tech-spec`.
- If AC do not exist yet, stop and say so — writing AC themselves is out of scope for this kit.
