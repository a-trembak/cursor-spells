# Null safety checklist (N1)

Canonical gate for `csp-review-logic` when a diff fixes NPE, 500, or null-pointer failures in a service method, shared helper, repository query, or mapper. Catch **partial null hardening**: one path gets guards while sibling endpoints or other callers of the same helper still use the unsafe pattern.

Do **not** hardcode product names, ticket ids, or endpoint labels. Apply the rule; examples are illustration only.

---

## N1 — Trace all callers and sibling endpoints after null fixes

**Trigger:** the diff fixes or hardens null handling — e.g. adds null guards, filters null associations, changes map lookup patterns, or fixes an NPE/500 in a shared helper or service method.

**Required check:**

1. List every **caller** of each touched helper (including private methods extracted for reuse). Open and read each caller — not only the diff hunk.
2. List **sibling endpoints** on the same service/controller path that share the same data-loading or mapping pipeline. Review each for the same unsafe pattern.
3. For each caller and sibling, verify:
   - Null keys before `groupingBy`, `Collectors.toMap`, or composite-key access (e.g. `getId().getX()` without guard).
   - Map lookups: `getOrDefault` does **not** protect against **null values** in the map — require an explicit null check on the returned value when the source map can contain null entries.
   - Association traversal: filter or guard before `entity.getRelation().getField()` when the relation can be missing.
4. Require tests or explicit phase notes for **each** caller/sibling — not only the endpoint named in the ticket or repro.
5. Do **not** approve if one path is hardened but another caller or sibling endpoint still uses the unsafe pattern.

**Anti-pattern:** Approving a fix that hardens one endpoint while a sibling endpoint on the same service path or another caller of the same helper still lacks the equivalent null guard; or accepting `getOrDefault(key, default)` when map **values** can be null and no explicit null check follows.
