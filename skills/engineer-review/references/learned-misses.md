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

### `miss_narrow-viewport-layout`

```yaml
id: miss_narrow-viewport-layout
miss_class: narrow-viewport-layout
triggers:
  - table | DataGrid | columns | breakpoint | hide column
  - accordion | expandable | Collapse | nested table
  - Dialog | Modal | Drawer | Popover | overlay
phases: [figma, patterns]
gate: V2
also: [V1, V3, V4]
rule_one_liner: >-
  When the diff touches tables, expandable cards, dialogs, or overlays,
  verify tablet and phone layouts (or existing compact-table patterns)
  before closing; a desktop Figma frame is not enough.
anti_pattern: >-
  Review only the desktop design frame or desktop browser width while
  dense nested tables, expanders, or overlay chrome collide, clip, or
  overflow from tablet down to phone.
hits: 1
last_seen: 2026-08-27
source: engineer-review
```

Mechanism: markup review matches the desktop Figma frame; tablet and phone widths (and existing hide-column / stack / row-expander patterns) are never opened, so overlay chrome and nested tables break only on narrower viewports.

Required check: [responsive-layout-checklist.md](responsive-layout-checklist.md) V1–V4. Figma skip does not waive the gate — `review-patterns` still runs it.
