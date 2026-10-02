# Graphify by pipeline stage

## software-developer

**After branch setup**, before Task 1:

1. `detect --root <repo>`
2. If `state=used`: `impact-hint` from plan file paths or AC-mentioned paths; keep `impact_hint` in session for implementers.

**After verification passes**, before handoff (each target repo):

1. `refresh --root <repo>`
2. Record `graphify_refresh` in handoff block.

## bug-fix

**After root cause is confirmed** (before minimal fix):

1. If `state=used`: `query` for callers/callees of the failing symbol or file.

**After verification**, before handoff:

1. `refresh --root <repo>` per target repo.

## implementation-critic

**Pass C (bug-fix plans)** or when the plan lists concrete paths:

1. If `state=used`: `impact-hint` for planned paths; cite compact output under blast-radius / regression risk (do not paste full graph).

Read-only — no refresh.

## engineer-review

Load [review-hook.md](review-hook.md) and existing `engineer-review/references/graphify-protocol.md` orchestrator hook. **Never refresh** during review.

## start-build / finish-plan

Orchestrators do not run graphify themselves; nested `csp-software-developer` / `csp-bug-fixer` own refresh before review.
