# JPA Criteria / Specification checklist

Canonical gates for `review-logic` when the diff touches JPA `Specification`, Criteria API subqueries, fetch joins, or collection joins on entities.

Do **not** hardcode product names or ticket ids. Apply the rule; examples are illustration only.

---

## J1 — EXISTS correlation must use the join handle when installation is fetch-joined

**Trigger:** the diff adds or changes a `Specification` / Criteria query that:

- fetch-joins a `@ManyToOne` or `@OneToOne` association (e.g. `root.fetch("installation", …)`), **and**
- filters scope with an `EXISTS` subquery on a related table keyed by that association's id.

**Required check:**

1. The EXISTS `where` clause must correlate using the **same join/fetch handle** already created for the association (e.g. `installationJoin.get("uuid")`), not `root.get("associationName").get("id")`.
2. Flag a change that replaces a join-handle correlation with a root path "for consistency" — Hibernate can throw `NullPointerException` at **query execution time** on org-scoped paths even when unit tests pass.
3. Illustration only: alert spec with fetch on `installation` + EXISTS on `installation_organization` must correlate via the fetch join, not `root.get("installation").get("uuid")`.

**Anti-pattern:** approving a "cleanup" that rewrites correlation to the root association path while fetch join remains.

---

## J2 — Criteria spec unit tests must assert the runtime correlation path

**Trigger:** the diff adds or changes Mockito-based tests for a Criteria `Specification` (mock `Root`, `Join`, `Subquery`).

**Required check:**

1. Read which path the production spec uses in the EXISTS / join correlation (`installationJoin.get(...)` vs `root.get("installation").get(...)`).
2. Flag tests that stub and verify a **different** path than production — they give false confidence for Hibernate runtime NPEs.
3. Prefer asserting `verify(installationJoin).get("uuid")` and `verify(root, never()).get("installation")` when J1 applies.
4. Note in findings when only mock spec tests exist and no integration test covers the org-scoped query path.

**Anti-pattern:** test stubs `root.get("installation")` while production must use the fetch join handle.

---

## N1 — Partial hardening must not revert a working fix in the same hotspot

**Trigger:** a follow-up PR adds null-safety, refactors, or "aligns" code in a file that already received a production bugfix in the last one or two merges on the same branch area.

**Required check:**

1. Diff the hotspot against the **immediately prior fix commit**, not only against pre-bug main.
2. Flag any line restored to an older shape (especially query correlation, join type, or map collectors) while new guards are added elsewhere in the same method/file.
3. Require evidence that org-scoped / membership-scoped paths were smoke-tested — curl without membership JWT is not enough when the bug is membership-scoped.

**Anti-pattern:** merging null-safe mapping while silently reverting a Criteria correlation line that fixed the original 500.

**Shared callers:** when null guards are added in service A, scan other callers of the same repository/spec/Feign helper (search, dashboard list, occurrences) for the same null shape — do not treat one endpoint as done if siblings share the unfixed path.
