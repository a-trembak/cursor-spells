# Question discipline

Full protocol for agent-assisted tech-spec drafting. This reuses the question-loop mechanics from the `brainstorming` skill (one question at a time, multiple-choice preferred, 2-3 options with trade-offs) as the reference implementation for this narrower, engineering-only artifact — it is not `brainstorming` itself, and does not produce a product/UX design.

**Full-path note:** Designer↔critic disagreements are resolved by `skills/system-design/references/consensus-protocol.md`, not by Decision-tier HITL. Decision-tier HITL still applies on the light path, and on the full path only for human-facing forks the orchestrator chooses to surface (or Blockers when AC is silent).

## The three tiers

**Blocker** — no happy path, unclear data ownership, a security implication, or a breaking change with no named mitigation. The spec cannot be finalized while a Blocker is open. Stop and ask; do not draft around it with a guess.

**Decision** — two or more technically valid options exist with materially different impact (cost, risk, migration surface, or long-term maintenance). Present 2-3 concrete options with a recommendation and wait for the human's choice. Never silently pick one.

**Assumption** — a local technical default with no business impact (e.g. an index name, a column ordering convention already used elsewhere in the codebase). Write it directly into the spec's `Assumptions` section: the claim, why it's safe, and how to revoke it if wrong. Do not ask a question for this tier — surfacing it in writing is enough, since the human reviews it at `approve-spec`.

## How to ask

- One question per message. Do not batch multiple Blocker/Decision items into a single wall of text.
- Prefer multiple-choice framing over open-ended prompts.
- Use skill **`hitl-choice`**: present Blocker/Decision options via `hitl-choice` (AskQuestion required; stable option `id`s; typed tokens only after failed/missing tool).
- For a Decision-tier fork, always show 2-3 named options with a one-line trade-off each, plus your recommendation and why.
- Never proceed past an open Blocker or Decision by assuming an answer "for now" — wait for the reply.

## Self-check before finalizing a draft

Before presenting the spec for `approve-spec`, check: did every section that surfaced a Blocker or Decision actually get asked about, or did drafting momentum carry past one because it "seemed obvious"? If any section still contains an inference about business intent that wasn't confirmed, it is a Blocker, not an Assumption — go back and ask.
