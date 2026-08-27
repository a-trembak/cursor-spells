# Learned misses (kit seed)

Curated miss classes that every engineer-review load. Consumer projects may add more in `.cursor/review-learnings.md` (see [review-learn-protocol.md](review-learn-protocol.md)). Prefer linking gates over restating them.

---

### `miss_side-effect-live-actor`

```yaml
id: miss_side-effect-live-actor
miss_class: side-effect × live actor
triggers:
  - resetApiState | cache invalidate | sync vs defer
  - remount / key= | overlay open/close | isLoading→disabled
  - stateful input inside host that re-filters children each keystroke
phases: [logic, architecture, security]
gate: R1
also: [R2, R3, R4, R5, R6, R7]
rule_one_liner: >-
  When the diff changes when something runs, replay still-mounted
  subscriptions and host widgets before closing; writers≠probes;
  competing-actor tests required.
anti_pattern: >-
  Review only the changed writer/filter and skip live shells or nested
  inputs that react to the side-effect.
hits: 2
last_seen: 2026-08-06
source: production-escape
```

Mechanism: a timing or list-re-render side-effect interacts with actors that stay mounted (RTK subscribers writing shared auth; Menu/Popover autofocus remounting search). Diff-only review misses both.

Required check: [interaction-replay-checklist.md](interaction-replay-checklist.md) R1–R7. Auth shape: [auth-rtk-checklist.md](auth-rtk-checklist.md).

Test shape: competing actor (active subscription **or** open menu with focused search) across the side-effect — not isolated unwrap/matcher-only tests.

---

### `miss_device-family-specific-codes-in-fixtures`

```yaml
id: miss_device-family-specific-codes-in-fixtures
miss_class: device-family-specific codes in fixtures
triggers:
  - test fixture | test factory | table-driven test
  - identifier code paired with device family or platform
  - alert/error/protocol/SKU codes in tests
phases: [logic]
gate: I1
rule_one_liner: >-
  When tests bind identifier codes to a device family or platform, check
  those codes against that family's identifier conventions — not only that
  merge or aggregation logic is asserted.
anti_pattern: >-
  Pairing a family-restricted code with a fixture for a family that does
  not use that shape, while only reviewing merge or count assertions.
hits: 1
last_seen: 2026-08-27
source: engineer-review
```

Mechanism: tests can assert merge or aggregation correctly while the fixture binds a family-restricted identifier to the wrong family. Review that stops at assertion shape misses the invalid pairing.

Required check: [fixture-identifier-conventions.md](fixture-identifier-conventions.md) **I1**. Do not treat production filters that drop invalid family×code pairs as this miss class.

---

### `miss_figma-eyeball-skip`

```yaml
id: miss_figma-eyeball-skip
miss_class: figma eyeball skip
triggers:
  - figma.com/design | node-id | Figma URL
  - className | sx | theme token | CSS variable
  - accordion | tabs | table | dialog | modal
  - placeholder | empty cell | "--" | muted dashes
  - gap | padding | Stack | Grid | auto-layout
phases: [figma]
gate: F1
also: [F2, F3, F4, F5, F6, F7]
rule_one_liner: >-
  When Figma node URLs exist, walk F1–F7 against rendered UI and source;
  token and structure mismatches are P1, not nits.
anti_pattern: >-
  Treat "looks close enough" or pixel-perfect bikeshed as a pass while
  skipping auto-layout numbers, tokens, empty states, and DOM vs frames.
hits: 1
last_seen: 2026-08-27
source: production-escape
```

Mechanism: the phase compares a screenshot or JSX to Figma by vibe and skips readable token, spacing, hierarchy, and empty-placeholder misses.

Required check: [figma-markup-checklist.md](figma-markup-checklist.md) F1–F7.
