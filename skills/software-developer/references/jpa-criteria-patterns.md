# JPA Criteria patterns (Spring Data `Specification`)

Load when implementing or fixing JPA `Specification` builders, fetch joins, or EXISTS subqueries.

## Fetch join + EXISTS subquery

When a spec fetch-joins a single-valued association and filters with an EXISTS subquery on a related table:

```java
// CORRECT — correlate via the join/fetch handle
var installationFetch = root.fetch("installation", JoinType.INNER);
Join<Object, Object> installationJoin = (Join<Object, Object>) installationFetch;

Subquery<Integer> orgScope = query.subquery(Integer.class);
Root<InstallationOrganization> orgRoot = orgScope.from(InstallationOrganization.class);
orgScope.select(cb.literal(1)).where(
    cb.equal(orgRoot.get("id").get("installationUuid"), installationJoin.get("uuid")),
    cb.equal(orgRoot.get("id").get("organizationUuid"), orgUuid)
);
predicates.add(cb.exists(orgScope));
```

```java
// WRONG — root path through a fetch-joined association → Hibernate NPE at runtime
cb.equal(orgRoot.get("id").get("installationUuid"), root.get("installation").get("uuid"))
```

**Why:** with fetch join active, correlating via `root.get("association")` inside a subquery is not equivalent to using the join handle; query execution can NPE on scoped filters even when mock-based unit tests pass.

## Bag / collection joins

Never combine `fetch()` on one association with a regular `join()` on a **`@OneToMany` / `@ManyToMany` bag** on the same root for filtering. Use EXISTS (or a separate query) for collection membership filters instead.

## Count queries vs entity queries

In the same spec lambda:

- **Entity page queries** (`query.getResultType()` equals entity class): may use `fetch`.
- **Count queries**: use `join`, never `fetch`, for the same association predicates.

Share predicate logic; branch only on fetch vs join.

## Tests

Mockito spec tests must stub and verify the **same paths** production uses:

- If production uses `installationJoin.get("uuid")`, test must `verify(installationJoin).get("uuid")` and not only stub `root.get("installation")`.
- Mock-only coverage is insufficient for Hibernate — add or extend an integration test when changing org-scoped specs, or smoke with a **membership-scoped JWT** (not only fleet/admin token without membership claims).

## Follow-up fixes

When hardening a merged bugfix (null-safe maps, Optional guards):

1. Re-read the prior fix commit in the same file — do not revert query correlation or join strategy while adding guards elsewhere.
2. Scan **all callers** of shared helpers (`resolveLastResponsible*`, org grouping, same `Specification` builder) — partial null-safety on one endpoint leaves siblings broken.
