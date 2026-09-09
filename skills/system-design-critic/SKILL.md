---
name: system-design-critic
description: >-
  Use on the tech-spec full path after a system-design draft exists. Audits the
  draft for YAGNI, failure modes, operational risk, and patterns fit. Read-only;
  never asks the human; used inside designer↔critic auto-consensus.
---

# System Design Critic

Read-only audit of a **system-design draft** before it merges into a tech-spec. Complements (does not replace) post-plan `implementation-critic`.

## When to Use

- Full tech-spec path after `csp-system-design-designer` wrote `…-system-design.md`
- Consensus re-check rounds
- Not for light tech-spec; not for implementation plans; not for code review

## Lenses

See [references/lenses.md](references/lenses.md): Y (YAGNI), F (failure modes), O (ops), P (patterns/stack).

## Spine

1. Require system-design file path; read it in full.
2. Read `.cursor/project-patterns.md` in the current project if present.
3. Run all four lenses; apply anti-confabulation.
4. Emit report per [references/output-schema.md](references/output-schema.md).
5. Do not edit files; do not ask the human.

## Context budget

This skill + both reference files + the draft path under review.
