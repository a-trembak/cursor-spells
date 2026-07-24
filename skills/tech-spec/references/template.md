# Tech spec template

## File placement

- **Separate file**, English only, regardless of the team's working/conversation language.
- Path: `docs/superpowers/specs/YYYY-MM-DD-<topic>-tech-spec.md` (adjust to an existing project's own convention if one is already established for tech specs specifically — do not reuse a product/PRD-spec folder without checking first).

## Sections (in order)

1. **AC references** — which acceptance criteria this closes; do not restate the AC's business language, just reference it (e.g. "Closes AC-3, AC-4").
2. **Changes by layer** — service → storage → API → jobs → …, in the order they're touched. Name exact tables, endpoints, modules — not "the backend."
3. **Data model / contracts** — tables, fields, FKs, events; exact names and types, not placeholders.
4. **Rollout sequence** — the order changes land so the system is never half-migrated (e.g. "add nullable column, backfill, add NOT NULL, deploy code that reads/writes it, remove fallback").
5. **Compatibility / migration / rollback** — how to undo each step, or `N/A` with a one-line reason why rollback isn't needed.
6. **Rejected alternatives** — one line each: what was considered and why it lost. This is the critic's primary input for its Pass A checks.
7. **Open questions / Assumptions** — any unresolved Decision-tier items still pending (spec cannot be `approved` while any remain) and the full list of Assumption-tier defaults made during drafting.

## Status header

Every tech spec starts with:

```markdown
# <Feature> — Technical Spec

**Status:** draft | approved | skip (<reason>)
**AC:** <references>
```

`approved` is set only after the human confirms at the Gate. `skip` requires a human-stated reason recorded in this line, not assumed by the agent.
