---
name: system-design
description: >-
  Use during tech-spec full path to design systems, services, and architectures
  from agreed AC (or to format a human-supplied plan). Trigger when tech-spec
  selects full system-design, or when drafting API/data/service boundaries
  before writing-plans. Adapted from Anthropic system-design; never invents
  business requirements.
---

# System Design

Help design systems and evaluate architectural decisions for the kit's **full** tech-spec path. Produces a structured design draft that a critic audits and that tech-spec later merges into the 7-section tech-spec.

## When to Use

- `tech-spec` full path (`human` always; `agent` + `full`)
- Not for light tech-spec, not for implementation task breakdown (`writing-plans`), not for post-plan `implementation-critic`

## Modes

| Mode | Input | Behavior |
|------|-------|----------|
| `format-human-plan` | Human plan path or pasted notes + AC | Structure/clarify into the template; do not replace human intent with a new architecture |
| `draft-from-ac` | AC + optional `.cursor/project-patterns.md` + stack label | Draft design from AC and patterns; stop on Blocker if a required business fact is missing |

## Framework

### 1. Requirements Gathering
- Functional requirements (trace to AC ids only — do not rewrite AC prose)
- Non-functional requirements (scale, latency, availability, cost) when AC/patterns imply them; otherwise Assumption or Open question
- Constraints (team size, timeline, existing tech stack / patterns file)

### 2. High-Level Design
- Component diagram (Mermaid or ASCII)
- Data flow
- API contracts (names/shapes at design level)
- Storage choices

### 3. Deep Dive
- Data model design
- API endpoint design (REST, GraphQL, gRPC as fits stack)
- Caching strategy
- Queue/event design
- Error handling and retry logic

### 4. Scale and Reliability
- Load estimation (even order-of-magnitude, marked Assumption if guessed)
- Horizontal vs. vertical scaling
- Failover and redundancy
- Monitoring and alerting

### 5. Trade-off Analysis
- Every material decision: choice, alternatives, why this wins
- Consider: complexity, cost, team familiarity, time to market, maintainability
- Note what to revisit as the system grows

## Output

Write English file per [references/template.md](references/template.md). Explicit assumptions, trade-offs, and "revisit later" notes required. Never set `Status: merged` or tech-spec `approved` — orchestrator owns those.

## Hard rules

- Never invent business requirements missing from AC / human plan.
- Never ask the human to resolve a dispute with `system-design-critic` — revise the draft or document a trade-off for the consensus protocol.
- On Blocker (no happy path without a missing business fact): stop and surface to the tech-spec orchestrator for one `hitl-choice` ask — do not guess.

## Context budget

Load this skill, `references/template.md`, and (when in a consensus loop) `references/consensus-protocol.md`.
