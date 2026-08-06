# System-design critic lenses

Run all lenses every time. Quote the exact draft line before recording a finding.

## Lens Y — YAGNI / complexity

- Unnecessary services, queues, or caches for the stated AC scale
- Premature multi-region / sharding / event-sourcing
- Abstractions with one concrete use
- Simpler alternative clearly available in patterns or stack

## Lens F — Failure modes

- Missing timeout/retry/idempotency where the design implies remote calls
- Single points of failure called out without mitigation
- Partial-failure behavior unspecified for multi-step flows
- Data loss / duplicate processing paths unnamed

## Lens O — Operational risk

- No monitoring/alerting hooks for new critical paths
- Migrations/rollout omitted when storage shape changes
- Secrets/PII handling absent when data model implies sensitive fields
- Runbook-level operability ignored (how on-call knows it broke)

## Lens P — Patterns / stack fit

- Conflicts with `.cursor/project-patterns.md` without explicit trade-off
- Storage/API style inconsistent with detected stack without rationale
- Cross-service contracts that ignore existing module boundaries

## Anti-confabulation

No finding without a same-turn quote from the system-design draft (section heading + line) or patterns file `path`. If evidence is missing, drop the finding.
