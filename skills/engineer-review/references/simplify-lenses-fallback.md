# Simplify lenses A–C (fallback only)

Use when `ce-simplify-code` is **missing**. Prefer the real personas when the skill is present. Always also run **Kit extensions** in [`simplify-checklist.md`](simplify-checklist.md).

## Lens A — Reuse / redundancy *(fallback only)*

Use when `ce-simplify-code` is missing. Prefer the real `code-reuse-reviewer.md` persona when the skill is present.

| Catch | Signal | Typical severity |
|-------|--------|------------------|
| New helper duplicates an existing project utility | Same semantics already in patterns "Do not reinvent", shared utils, or adjacent package | `P1` clarify unless trivially identical and unused → deadcode |
| Inline logic reimplements stdlib / runtime primitive | Hand-rolled dedup/clone/merge/path join where the language API is behavior-equivalent | `P1` |
| Diff hand-maintains a framework guarantee | Redundant filter/projection/null-check the platform already enforces | `P1` clarify unless proven no-op |
| Near-duplicate blocks with slight variation | Copy-paste that should share one path or derive from one source of truth | `P1` clarify if merge changes structure; `P2` if tiny |

Do **not** invent a new shared abstraction for a one-off.

## Lens B — Cleanliness / readability *(fallback only)*

Prefer `code-quality-reviewer.md` when ce-simplify is present.

| Catch | Signal | Typical severity |
|-------|--------|------------------|
| Over-nesting | Ternary chains, nested if/else/switch **3+** levels | `P1` / `P2` |
| Parameter sprawl | New params bolted on instead of restructuring | `P1` clarify |
| Redundant state | Cached/derived values duplicated in state | `P1` |
| Stringly-typed vs existing enums/constants | Raw strings where typed constants exist | `P1` |
| Unnecessary wrappers / indirection | Pass-through methods, no-op layers, layout-free wrapper components | `P1` |
| Narrating WHAT comments | Hand off to `code-comments` / deadcode | coordinate |

**Balance:** fewer lines is not the goal. Skip if the “simpler” version is harder to follow.

## Lens C — Local efficiency *(fallback only)*

Prefer `efficiency-reviewer.md` when ce-simplify is present.

| Catch | Signal | Typical severity |
|-------|--------|------------------|
| Unnecessary work in the changed path | Repeated compute, duplicate reads/calls, discarded work | `P1` |
| Missed obvious concurrency | Independent awaits with no ordering need | `P1` clarify if ordering might matter |
| Overly broad loads | Read-all-then-filter when a scoped read exists | `P1` clarify on data layer |
| Unconditional no-op updates | State/store writes when nothing changed | `P1` |

Hot-path / systemic cost → `review-performance`.
