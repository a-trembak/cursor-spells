# Simplify checklist

## Role of this file

| When | What to use |
|------|-------------|
| `ce-simplify-code` **installed** | Read that skill + three personas **verbatim** as primary. Then **always** run **Kit extensions** below. |
| `ce-simplify-code` **missing** | Note `skill_missing: ce-simplify-code`. Run **Lens A–C** from [`simplify-lenses-fallback.md`](simplify-lenses-fallback.md) **and** **Kit extensions**. |

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

Lens A–C fallback tables: [`simplify-lenses-fallback.md`](simplify-lenses-fallback.md).

---

## Never auto-apply

Anything that fails [`auto-fix-eligibility.md`](auto-fix-eligibility.md) — especially behavior/API tradeoffs, speculative refactors, and "looks cleaner" without a single correct shape.

## Safety pins

Never propose removing: trust-boundary validation, authz/escaping/sanitization, data-loss guards, accessibility affordances, or structure pinned by a tech-spec / `session-settled` decision.
