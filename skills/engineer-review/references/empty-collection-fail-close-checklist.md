# Empty-collection fail-close checklist

Canonical gate for `review-logic` when the diff builds candidate lists from an upstream collection that may be absent/empty as a wrapper **or** present with empty nested children, and may also add a scoped/fallback candidate.

Do **not** hardcode product names or ticket ids. Apply the rule; examples are illustration only.

---

## FC1 — Absent wrapper and empty children must share the same fail-close policy

**Trigger:** the diff short-circuits on an empty or absent upstream collection (`Optional.empty()`, null/absent response, empty list/map) **or** walks nested children of that collection, **and** also adds (or plans to add) a scoped, current-context, or other fallback candidate to the result.

**Required check:**

1. Identify every empty shape the upstream can take: wrapper absent/empty vs wrapper present with empty nested children (or empty leaf lists).
2. Trace whether each empty shape returns before candidate assembly or continues into the path that adds the scoped/fallback candidate.
3. Flag asymmetric fail-close: one empty shape returns an empty list while another empty shape still includes the scoped/fallback candidate — unless the product intent explicitly documents different policies and tests cover both shapes.
4. Require tests (or equivalent evidence) for **both** empty shapes when the happy path includes a scoped/fallback candidate.

**Anti-pattern:** reviewing only the "present but empty children" path (or only the happy path) while `Optional.empty()` / absent-wrapper early-returns before the scoped/fallback candidate is added.

**Illustration only:** empty partnership Optional returns `List.of()` before adding the caller's scoped org; partnerships present with empty children still add that org — inconsistent fail-close.
