# Tech-spec dogfood fixture

Manual checklist to verify the tech-spec agent behaves. Do not require CI to execute agents.

## Setup

Give the agent (via `/csp-write-tech-spec`, `agent` mode) this deliberately underspecified AC:

> AC-1: As a customer, I can download a file containing my past orders.

This AC is silent on:
- File format (CSV, PDF, or both) — a Decision-tier fork with materially different implementation cost.
- How very large order histories are handled (paginate/limit vs. a background job with a notification) — a second Decision-tier fork with perf/UX impact.
- Nothing in the AC specifies which order fields the export must contain — a real gap the agent must not silently fill in.

## Expected agent behavior

| Check | Expect |
|-------|--------|
| Entry question | Asks `human` vs `agent` before reading or drafting anything |
| Decision-tier Q1 | Asks about export file format with 2-3 named options (e.g. CSV only / PDF only / both) and a recommendation, as its own message |
| Decision-tier Q2 | Asks about handling large order histories (e.g. paginate with a hard row cap / synchronous with a size limit / background job with a download link) as a separate message from Q1 |
| Blocker or Decision on fields | Either stops as a Blocker (unclear what data the export exposes) or raises it as a Decision-tier question with named options — does not silently draft a field list into section 3 without having surfaced it first |
| No invented business fact | Across all three gaps (format, large-history handling, field list), the draft never states a concrete choice that wasn't first raised as a question — if any one of them appears already decided in the draft without a prior question, that is a fixture failure |
| One question per message | Q1 and Q2 arrive in separate messages, not batched into one |
| Assumption logged, not asked | At least one small technical default (e.g. endpoint naming, module placement, response encoding) appears in the spec's `Open questions / Assumptions` section with a stated reason — it was not asked as a question. Absence of any Assumption entry, when the draft clearly made such a default silently elsewhere, is a fixture failure. |
| Output file | Written to `docs/superpowers/specs/YYYY-MM-DD-order-export-tech-spec.md`, English only, with a `**Status:** draft` header line matching `references/template.md`'s Status header format |
| Gate | Does not treat the spec as final or hand off to `writing-plans` until the user replies `approve-spec`, `revise`, or `skip <reason>` |
| Clean revise | On a forced `revise` that changes a prior Decision, the file body has no "fixed/changed to/was previously/What changed" archaeology — chat may narrate; see `clean-decision-docs` dogfood |

## Cleanup

Delete the generated spec file after the dogfood run:

```bash
rm docs/superpowers/specs/*-order-export-tech-spec.md
```
