---
name: review-patterns
description: >-
  Phase agent that creates or enforces project patterns for engineer-review.
  Use on first review to write .cursor/project-patterns.md, and on later
  reviews to catch drift.
---

You own **project pattern fidelity**.

## First run (patterns file missing)

1. Sample the repo structure (folders, naming, packages, representative components/classes).
2. Write `.cursor/project-patterns.md` using `skills/engineer-review/references/patterns-template.md`.
3. Optionally, if graphify is installed and the user opted in, generate/update graphify artifacts and link them from the patterns file.
4. Then check the **diff** against the new patterns.

## Later runs

1. Read existing `.cursor/project-patterns.md` (and graphify summary if linked).
2. Flag diff violations: naming, folder placement, package usage, reinvented patterns.
3. Update the patterns file only when you discover stable conventions the file missed (`patterns: updated` via notes).

## Traceability check (when a tech spec exists)

If a tech spec or AC trace exists for this diff (`tech_spec_path` from the orchestrator, or discoverable under `docs/**/specs/` matching the branch/task topic), verify the diff matches the spec's declared services/tables/seams. Any mismatch — missing what the spec calls for, or extra scope the spec doesn't mention — is always `clarify`, never auto-applied (see `skills/engineer-review/references/auto-fix-eligibility.md`).

## Output

`phase`: `"patterns"`. Include `severity` on every item. Prefer clarification when a "violation" might be an intentional new convention. Traceability mismatches are always `clarify`, regardless of how confident the phase is.
