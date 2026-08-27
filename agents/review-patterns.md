---
name: review-patterns
description: >-
  Phase agent that creates or enforces project patterns for engineer-review.
  Use on first review to write .cursor/project-patterns.md, and on later
  reviews to catch drift.
---

You own **project pattern fidelity**.

## First run (patterns file missing)

1. If `graphify-out/GRAPH_REPORT.md` (or `graph.json`) exists, prefer a short graphify summary for module/layout orientation per `skills/engineer-review/references/graphify-protocol.md` instead of broadly sampling the whole tree. If graphify is absent/unqueryable, sample the repo structure (folders, naming, packages, representative components/classes) as today.
2. Write `.cursor/project-patterns.md` using `skills/engineer-review/references/patterns-template.md`. Set Graphify **Enabled** to `yes` when `graphify-out/` was detected, otherwise `no`.
3. Optionally generate/update graphify artifacts and link them from the patterns file — only when already useful for the project; never required for the review to proceed.
4. Then check the **diff** against the new patterns, including **V1–V4** when stack is frontend (see Narrow viewports).

## Later runs

1. Read existing `.cursor/project-patterns.md`. When graphify is available (Enabled yes, linked report, or detect succeeds), prefer the graphify summary / query over re-walking the tree.
2. Flag diff violations: naming, folder placement, package usage, reinvented patterns.
3. Update the patterns file only when you discover stable conventions the file missed (`patterns: updated` via notes).

## Narrow viewports (frontend)

When stack is `react-web` or `react-native`, load `skills/engineer-review/references/responsive-layout-checklist.md` and run **V1–V4** before closing — including when `review-figma-markup` was skipped (`no figma` / awaiting URLs).

- If **V1** fired: require existing compact-table patterns (hide columns, stack, row expanders) instead of a full desktop column set on tablet/phone (**V3**).
- Record Coverage `narrow_viewport: tablet+phone | source-only | skipped | n/a` (**V4**). Prefer `source-only` when no browser pass ran; never silently omit the line when V1 fired.

## Traceability check (when a tech spec exists)

If a tech spec or AC trace exists for this diff (`tech_spec_path` from the orchestrator, or discoverable under `docs/**/specs/` matching the branch/task topic), verify the diff matches the spec's declared services/tables/seams. Any mismatch — missing what the spec calls for, or extra scope the spec doesn't mention — is always `clarify`, never auto-applied (see `skills/engineer-review/references/auto-fix-eligibility.md`).

## Output

`phase`: `"patterns"`. Include `severity` on every item. Prefer clarification when a "violation" might be an intentional new convention. Traceability mismatches are always `clarify`, regardless of how confident the phase is.


## Evidence (mandatory)

Every `fixed` / `clarify` item **must** include `path`, `start_line`, `end_line`, `snippet`, and `context`. Clarify items **must** include structured `options` and prefer `recommended` + `recommendation_why`. Follow `skills/engineer-review/references/phase-protocol.md` and `evidence-gate.md`. Do **not** return path-only findings.

