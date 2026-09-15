# JPA repository result-type checklist

Canonical gate for `csp-review-logic` when a Spring Data repository method declares a scalar or identifier collection return type that may disagree with the Hibernate / JPA selection type — especially when an org-scoped path and a fleet (or unscoped) path diverge.

Do **not** hardcode product names, ticket ids, or server nicknames. Apply the rule; examples are illustration only.

Coverage token when this checklist applies: `jpa_result_type: matched|mismatched|skipped|n/a`.

---

## RT1 — Repository return type must match query selection (scoped and fleet)

**Triggers (any):**

- Repository methods returning a scalar or identifier collection (for example `List<String>`, `Set<UUID>`, `List<Long>`).
- `@Query` strings, derived finders, or Criteria selections that project identifiers or scalars.
- Org-scoped versus fleet (or unscoped) forks of the same finder family.
- Hibernate / JPA wording such as `result type did not match Query selection type` or `multiple selections: use Tuple or array`.

**Required check:**

1. The **declared method return type** must match what the query **selects**. Entity roots or multi-column selections must not be mapped into a scalar collection declaration.
2. When both a **scoped** and a **fleet** (or unscoped) sibling exist, open and compare **both** — do not review only the method named in the ticket.
3. Flag entity selection or multi-column selection into `List<String>` (or similar scalar collections). Prefer an explicit scalar `@Query`, a projection interface/DTO, or `Tuple` / array when declaring scalars.
4. Treat unjustified `jpa_result_type: skipped` as a logic finding when the diff clearly touches repository return shapes.
5. Coverage must record `jpa_result_type: matched|mismatched|skipped|n/a` stating whether return type versus selection was checked on both paths when both exist (`matched` only when they agree).

**Anti-pattern:** Approving a scoped finder while the fleet sibling already uses a matching explicit scalar `@Query` (or equivalent projection) and the scoped method still selects an entity or multiple columns into a scalar list.

**Illustration only (QA shape):** scoped list request with `orgUuid` → HTTP 500 and result-type mismatch text; same list without org → 200; sibling summary path with org → 200. Cite the shape, not a product or server name.
