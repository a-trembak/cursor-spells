# Fixture identifier conventions (device-family codes)

Canonical gate for `csp-review-logic` when tests bind identifier codes to a device family, platform, or product line. Catch **wrong family on a fixture code**: merge, count, or aggregation assertions look right, but the code would never occur for that family in production.

Do **not** hardcode product names or ticket ids. Apply the rule; examples are illustration only.

---

## I1 — Codes in fixtures must match the bound family

**Trigger:** the diff adds or changes tests, fixtures, or test factories that pair an identifier code (alert, error, protocol, SKU, or similar) with a device family, platform, product line, or other discriminator (constructor arguments, helper calls, table-driven rows).

**Required check:**

1. For each such pairing, look up how production constrains code shape or namespace per family (validators, parsers, filters, protocol docs, sibling fixtures for that family, or `.cursor/project-patterns.md` if it documents identifier conventions).
2. Flag a fixture that uses a family-restricted code on the wrong family — even when merge, count, or aggregation assertions pass.
3. Illustration only: a dash-suffixed code valid only for family A used on a fixture labeled family B.

**Out of scope for this miss class:** do not treat production filters that drop invalid family×code pairs as a defect of this class. The miss is the fixture pairing, not the production filter.

**Anti-pattern:** reviewing only that merge or aggregation tests pass, while the fixture's code would never occur for that family in production.
