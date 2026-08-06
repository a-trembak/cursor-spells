# System-design draft template

## File placement

- Separate file, English only.
- Path: `docs/superpowers/specs/YYYY-MM-DD-<topic>-system-design.md`

## Status header

```markdown
# <Feature> — System Design

**Status:** draft | merged
**AC:** <references>
**Mode:** format-human-plan | draft-from-ac
**Source plan:** <path or `n/a`>
```

`merged` is set only by the tech-spec orchestrator after successful merge into the tech-spec. Designer and critic never set `merged`.

## Sections (in order)

1. **Requirements** — functional (AC ids), non-functional, constraints
2. **High-level design** — components, data flow, API contracts, storage (include a Mermaid or ASCII diagram)
3. **Deep dive** — data model, endpoints, cache, queues/events, errors/retries
4. **Scale and reliability** — load, scaling, failover, monitoring
5. **Trade-offs** — each material decision with alternatives and rationale; "revisit later" list
6. **Assumptions / open questions** — Assumption-tier defaults (claim, why, revoke); Open questions only for unresolved Blockers awaiting human (should be empty before merge unless orchestrator is mid-Blocker)

## Clean final form

Every revise in the consensus loop rewrites the file as current truth (`clean-decision-docs`). No changelog archaeology inside the file.
