# Simplify checklist

## Role of this file

| When | What to use |
|------|-------------|
| `ce-simplify-code` **installed** | Read that skill + three personas **verbatim** as primary. Then **always** run **Kit extensions** below. |
| `ce-simplify-code` **missing** | Note `skill_missing: ce-simplify-code`. Run **Lens A–C** (fallback mirrors of the personas) **and** **Kit extensions**. |

Behavior-preserving only: same outputs, errors, side effects, and ordering for current callers. Prefer `clarify` with a concrete simpler alternative. See [`auto-fix-eligibility.md`](auto-fix-eligibility.md).

---

## Kit extensions (beyond ce-simplify)

**Always run** after the ce-simplify personas (or after Lens A–C when falling back). These are engineer-review gaps ce-simplify does **not** cover well — especially “works but is a poor solution” vs plan/patterns.

Do **not** re-flag what personas already own (bit-identical utility reuse, nested ternaries, unused imports, N+1, listener leaks, etc.). Hand those off or skip.

| Catch | Signal | Typical severity |
|-------|--------|------------------|
| **Over-engineering / YAGNI in the implemented diff** | Strategy/plugin/factory/config knobs or “for later” branches **not** required by the tech spec / plan / AC | `P1` clarify — never silent-delete intentional extension points without evidence |
| **Alternate project approach** | Diff solves a job the repo already solves via patterns “Do not reinvent” or the stack idiom — even if the new code is **not** a bit-identical duplicate of one helper | `P1` clarify (reuse existing approach vs keep) |
| **Duplicated conditional navigation routing** | New local href/path builder when spec or a sibling component already defines the same routing; copy of conditional path logic (e.g. installation-type gate) without a shared util | `P1` — require the shared helper; verify **each branch** of the gate in tests without mocking the gate to a constant |
| **Spec/plan complexity drift** | Implementation is materially heavier than declared AC/seams (extra layers, options, states) with no settled decision justifying it | `P1` clarify |
| **Error-handling theater** | Catch-and-rethrow with no enrichment; empty catches; swallow-and-log that hides failures on the changed path | `P1` (logic may also care — keep the simplify angle: delete theater / propagate) |
| **Magic numbers / unexplained constants** | Literals introduced by the diff with no name, shared constant, or nearby comment of non-obvious WHY | `P1` or `P2` if obvious domain literal |
| **God-method growth** | A changed function ballooned past local readability without extracting *meaningful* seams | `P1` clarify — **balance:** do not invent abstractions for one-offs |
| **Test-only complexity** | Production code shaped awkwardly only so a weak/overfitted test passes | `P1` clarify (fix test vs simplify prod) |
| **Premature generalization / flag soup** | Boolean/enum flag piles steering divergent behaviors that should be separate paths or are unused by AC | `P1` clarify |
| **Dead feature flags / constant branches** | Always-true or always-false guards left in the change (control-flow dead, not merely unused symbols) | `P1` — coordinate with deadcode if the whole symbol is unused |
| **Inconsistent naming with neighbors** | New names fight the module’s existing vocabulary (same concept, different words) | `P2` residual or `P1` if it collides with a documented pattern |
| **API surface sprawl** | New public methods that are thin aliases / pass-throughs expanding the surface without need | `P1` clarify (inline at call sites vs keep façade) |

### Intentionally not duplicated here

| Topic | Owner |
|-------|--------|
| Missing close/unsubscribe / listener leaks | ce-simplify **efficiency** (memory) — escalate to `review-performance` / `review-security` when systemic |
| Unused imports/exports, commented-out code | `review-deadcode` |
| Hot-path N+1, pagination, re-render storms | `review-performance` |
| Layering / package boundaries | `review-architecture` |

---

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

---

## Never auto-apply

Anything that fails [`auto-fix-eligibility.md`](auto-fix-eligibility.md) — especially behavior/API tradeoffs, speculative refactors, and "looks cleaner" without a single correct shape.

## Safety pins

Never propose removing: trust-boundary validation, authz/escaping/sanitization, data-loss guards, accessibility affordances, or structure pinned by a tech-spec / `session-settled` decision.
