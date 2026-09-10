# System-design + tech-spec dogfood fixture

Manual checklist to verify the tech-spec full path (designer + critic + merge) and light path behave. Do not require CI to execute agents.

Shared fixture topic: **order export** (`order-export` in generated filenames).

---

## Scenario A — human full

### Setup

Start via `/csp-write-tech-spec` or `/csp-start-task`. When asked `human` vs `agent`, choose **`human`**.

Provide the same deliberately underspecified AC as [tech-spec-checklist.md](tech-spec-checklist.md):

> AC-1: As a customer, I can download a file containing my past orders.

Also supply a short human plan (path or paste) that prefers a **CSV sync endpoint** — e.g.:

> Plan: synchronous GET endpoint that returns CSV inline; no background job for v1.

The AC is still silent on file format beyond what the plan states, large-history handling, and which order fields the export must contain.

### Expected agent behavior

| Check | Expect |
|-------|--------|
| Entry question | Asks `human` vs `agent` before reading or drafting anything |
| No depth question | Does **not** ask `light` vs `full` — human mode is always full |
| Designer mode | Runs `format-human-plan` (structures/clarifies the human plan; does not replace CSV sync intent) |
| System-design file | Writes `docs/superpowers/specs/YYYY-MM-DD-order-export-system-design.md` with `**Status:** draft` per `skills/system-design/references/template.md` |
| Critic runs | `csp-system-design-critic` audits the draft after the first designer pass |
| No mid-loop HITL for pair disputes | Never asks the human to break a designer↔critic tie; auto-consensus rounds only (≤3) |
| Blocker / Decision scope | Blocker or Decision-tier asks only when AC + human plan omit a required business fact — not for critic Must-fix / Should-fix |
| Merge | Orchestrator merges into `docs/superpowers/specs/YYYY-MM-DD-order-export-tech-spec.md` with `**Status:** draft` (7 sections, English only) |
| System-design final status | After merge, `…-order-export-system-design.md` header ends as `**Status:** merged` (reference file kept, not deleted) |
| Gate | Presents tech-spec for `approve-spec` / `revise` / `skip <reason>` — no separate `approve-design` gate |
| Clean revise | On forced `revise`, file body has no "fixed/changed to/was previously/What changed" archaeology — see [clean-decision-docs-checklist.md](clean-decision-docs-checklist.md) |

---

## Scenario B — agent full

### Setup

Start via `/csp-write-tech-spec` or `/csp-start-task`. When asked `human` vs `agent`, choose **`agent`**.

When asked tech-spec depth, choose **`full`**.

Provide only the underspecified AC (no human plan):

> AC-1: As a customer, I can download a file containing my past orders.

Same gaps as [tech-spec-checklist.md](tech-spec-checklist.md): format, large-history handling, field list.

### Expected agent behavior

| Check | Expect |
|-------|--------|
| Entry question | Asks `human` vs `agent` before reading or drafting anything |
| Depth question | Asks `light tech-spec` vs `full system-design` after choosing `agent` |
| Designer mode | Runs `draft-from-ac` (design from AC + patterns; no human plan to format) |
| System-design file | Writes `docs/superpowers/specs/YYYY-MM-DD-order-export-system-design.md` with `**Status:** draft` |
| Critic + consensus | Critic runs; designer↔critic disputes resolved in auto-consensus rounds — no human tie-break |
| Blocker / Decision scope | Blocker or Decision-tier questions only for missing AC business facts (format, large histories, fields) — **not** for critic findings the pair can resolve |
| No invented business fact | Does not silently decide format, large-history strategy, or field list without first raising Blocker or Decision-tier question |
| Merge + gate | Merges to `…-order-export-tech-spec.md` (`**Status:** draft`); system-design file ends `**Status:** merged`; waits for `approve-spec` / `revise` / `skip` |

---

## Scenario C — agent light

### Setup

Start via `/csp-write-tech-spec` or `/csp-start-task`. When asked `human` vs `agent`, choose **`agent`**.

When asked tech-spec depth, choose **`light`**.

Provide the same underspecified AC:

> AC-1: As a customer, I can download a file containing my past orders.

### Expected agent behavior

| Check | Expect |
|-------|--------|
| Entry question | Asks `human` vs `agent` before reading or drafting anything |
| Depth question | Asks `light tech-spec` vs `full system-design` after choosing `agent` |
| No system-design file | Does **not** create `…-order-export-system-design.md` or load the designer/critic pair |
| Light path only | Behavior matches [tech-spec-checklist.md](tech-spec-checklist.md): Decision-tier Q1 (format), Q2 (large histories), Blocker/Decision on fields, one question per message, assumptions logged not asked, output `…-order-export-tech-spec.md` with `**Status:** draft`, gate on `approve-spec` |

---

## Cleanup

Delete generated spec files after each dogfood run:

```bash
rm docs/superpowers/specs/*-order-export-system-design.md
rm docs/superpowers/specs/*-order-export-tech-spec.md
```
