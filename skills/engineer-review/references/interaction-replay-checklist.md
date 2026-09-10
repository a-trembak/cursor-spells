# Interaction replay checklist (R1–R7)

Canonical gates for `csp-review-logic`, `csp-review-architecture`, and orchestrator post-clarify. Catch **side-effect × live actor** misses: a diff changes timing/list re-render, but review never checks what is still mounted and reacts (subscribers writing shared state; host widgets stealing focus).

Do **not** hardcode product-specific probes or filter widgets. Apply the rules; use examples only as illustration.

Auth/session specialization: [`auth-rtk-checklist.md`](auth-rtk-checklist.md).

---

## R1 — Interaction replay after side-effect timing changes

**Trigger:** diff changes **when** something runs — e.g. `resetApiState`, cache invalidate, sync vs defer, remount/`key=`, open/close overlay, `isLoading`→disabled.

**Required brief** (phase notes or competing-actor test):

`trigger → route/shell still mounted → active subscriptions / host widgets → shared writers (auth, focus, selection) → user-visible outcome`

HITL clarify answers that pick sync/defer/reset timing (or remount vs stable host) do **not** close until this replay is in phase notes **or** a competing-actor regression test exists.

---

## R2 — Writers vs probes (shared state)

For auth / session / equivalent shared store:

1. List matchers/listeners that **write** the shared fields (token/user/org or equivalent).
2. Separate **session writers** (login, membership/org token mutations, intentional scope switches) from **probes** (capability / menu / hasRoles / “am I still valid?” queries).
3. Probes must **not** share the same fulfill→write path as session writers after cache reset/refetch.

---

## R3 — Unchanged shells in impact set

When the diff touches API cache reset, auth/session, membership, or global loading gates:

- **Force-include** navigation/layout shells and global overlays that stay mounted across the trigger route — even if unchanged in the diff.
- Diff-only file lists are insufficient for global side effects.
- Graphify: impact query **plus** force-include shells; never rely on a path between RTK endpoint symbols alone (symbols collapse; path ≠ runtime refetch graph). See [`graphify-protocol.md`](graphify-protocol.md).

---

## R4 — Host-controlled focus & selection

When a stateful input (search, inline edit, date) lives inside a host that re-renders children on each local state change (Select Menu, virtualized list, accordion, Popover):

- Verify the host does **not** steal focus or remount the input when the list filters / children change.
- Check stability of Menu/Popover props (referential identity), item keys, and autofocus behavior (`disableAutoFocusItem` or platform equivalent).
- Require a note or test: typing N characters keeps focus and accumulates value.

---

## R5 — Dual source of truth

If Redux+localStorage, props+local state, or cache+slice coexist: after mutation/reset, verify what the **next screen actually reads** (headers, selectors, navigate target, displayed selection). Divergence → `P0`/`P1`.

---

## R6 — Competing-actor regression shape

Changes to listeners, auth matchers, `resetApiState`, or filter-in-menu / overlay hosts require tests with a **competing actor** (active subscription, open menu with search focused, second writer) — not only isolated unit unwrap/matcher tests.

---

## R7 — Coverage gate

When auth/session **or** interactive overlay/filter is in review scope, engineer-review Coverage **must** include:

```text
interaction_replay: auth | overlay-focus | both | skipped | n/a
```

- `auth` / `overlay-focus` / `both` — R1 brief (or competing-actor test) was recorded for that surface
- `skipped` — surface in scope but replay was not done (treat as incomplete review; prefer clarify or residual call-out)
- `n/a` — neither surface in scope

Optional detail line (when auth walked): `auth_flow_walk: view-as|membership-switch|logout|…` for the concrete flow(s).
