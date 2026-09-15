# JPA repository result-type patterns

Load when implementing or fixing Spring Data repository methods that return scalar or identifier collections, `@Query` / derived / Criteria selections, projections, or org-scoped versus fleet (or unscoped) identifier queries.

## Return type must match selection

The method's declared return type must match what the query selects. Do **not** declare `List<String>` (or similar) when the query selects an entity root or multiple columns.

```java
// WRONG — entity (or multi-column) selection into List<String>
@Query("SELECT i FROM Installation i WHERE …")
List<String> findIdsBy…(…);

// Also wrong: derived finder that returns List<String> while Spring Data
// materializes the entity / multi-column path for that method name.
```

```java
// CORRECT — explicit scalar selection matching List<String>
@Query("SELECT i.uuid FROM Installation i WHERE …")
List<String> findIdsBy…(…);
```

Prefer an explicit scalar `@Query`, a projection interface/DTO, or `Tuple` / array when the declare type is scalar. Treat the sketches above as directional guidance — match the project's repository conventions.

## Scoped versus fleet siblings

When both an org-scoped finder and a fleet (or unscoped) sibling exist:

1. Open **both** methods before handoff.
2. If fleet already uses a matching scalar `@Query` (or projection), the scoped sibling must use the same selection shape — do not leave scoped selecting an entity into a scalar list.
3. Do not treat “ticket only names the scoped method” as permission to skip the fleet check.

## Runtime signal

Hibernate wording such as `result type did not match Query selection type` or `multiple selections: use Tuple or array` is this miss class. Fix the selection or the declare type; do not paper over with catch-and-empty.

## Illustration only (QA shape)

Scoped list with `orgUuid` → HTTP 500 and result-type mismatch text; same list without org → 200; sibling summary with org → 200. Cite the shape, not a product or server name.
