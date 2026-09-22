# Business-logic tests only (T1)

## Role

Writers (`software-developer`) and reviewers (`csp-review-logic`, `csp-review-simplify`) use this when the diff **adds or expands unit/integration tests**, or when a review would otherwise ask for more tests.

## T1 — Prefer business decisions; skip presentation cosmetics

**Trigger (any):** new or changed tests; review finding that demands additional tests; export/report/UI styling diffs paired with test files.

**Gate:**

1. Keep or require tests that assert **business decisions**: gates, domain transforms, offline/online rules, column inclusion, null/zero semantics, authz outcomes, error contracts with domain meaning.
2. Do **not** add or demand tests that only pin **presentation constants** or cosmetics: hex/rgb fill colors, border width/style strings, font names/sizes, opacity literals, stylesheet XML wiring for colors/borders, snapshot of visual chrome without a domain rule.
3. Flag a find as over-testing when the test body is `assertEquals("F0F0F0", CONST)` / `stylesXml.contains(borderColor)` with no decision under test.
4. Visual correctness of colors/borders is verified by **manual or design review** (screenshot, Figma, export open-in-Excel), not by proliferating unit tests.

**Anti-pattern:** every styling tweak (lighter gray, thin border so gridlines survive Excel fill) gets its own unit test asserting the hex and `style="thin"` in `xl/styles.xml`.

**Severity:** `P1` clarify — drop or refuse the presentation-only test; keep business-behavior coverage.
