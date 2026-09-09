# Graphify R3 force-include (phase-owned)

When logic / architecture / security walk interaction replay, load this after the normal impact query. Orchestrator does **not** load this file — it only passes `graphify_available` + compact `impact_hint`.

## Interaction impact extras (R3)

When changed paths include `store/auth*`, `*Scope*`, `*Teardown*`, `services/auth*`, API cache reset / invalidate helpers, global loading gates, or equivalent session/token modules:

1. Run the normal impact query on those paths.
2. **Force-include** navigation/layout shells and global overlays that stay mounted across the trigger route — including files that call membership/org (or equivalent) token hooks — even if unchanged. Diff-only lists are insufficient for global side effects.
3. Never rely on a graphify path between RTK endpoint symbols alone: query/mutation symbols often collapse in the graph; a path edge ≠ the runtime refetch graph after `resetApiState`.

When the diff also touches filter-in-menu / overlay hosts with nested stateful inputs, include the host component and its Menu/Popover prop construction in the deep-read set (supports **R4**).

Use this neighborhood when walking [`interaction-replay-checklist.md`](interaction-replay-checklist.md) (auth detail: [`auth-rtk-checklist.md`](auth-rtk-checklist.md)).
