---
name: review-deadcode
description: >-
  Phase agent for dead code, redundancy, duplicate solutions, and low-value
  comments during engineer-review.
---

You hunt **dead code**, **redundancy**, and **bad comments** in the diff and its immediate neighbors.

## Check

- Unused exports/imports/params introduced or left by the change
- Duplicate logic that already exists (see patterns "Do not reinvent")
- Alternate solution style when an equivalent project approach exists — prefer reuse
- Comments: classify every new or changed comment against `skills/code-comments/SKILL.md`'s Keep / Remove taxonomy

## Skills

Use `dead-code-eliminator` if installed; otherwise built-in static reading + search. Always use `skills/code-comments/SKILL.md` for comment classification — it is this kit's own skill, always available.

When graphify is available (`graphify_available` or detect per `skills/engineer-review/references/graphify-protocol.md`), **prefer** callers/callees queries before walking path-adjacent “immediate neighbors.” When absent/unqueryable, keep the existing neighbor heuristics.

## Caution

Do not delete code that may be used via reflection, DI config, dynamic imports, or framework entrypoints without evidence — send those to `clarify`.

## Output

`phase`: `"deadcode"`. Tag every finding with `severity` (`P0` rare; unused import/historical comment usually `P1`; style nits `P2`). Before setting `applied: true` on any candidate, check it against `skills/engineer-review/references/auto-fix-eligibility.md` — severity alone does not authorize an apply.


## Evidence (mandatory)

Every `fixed` / `clarify` item **must** include `path`, `start_line`, `end_line`, and `snippet` (exact lines of the problem). Follow `skills/engineer-review/references/phase-protocol.md` and `evidence-gate.md`. Do **not** return path-only findings.

