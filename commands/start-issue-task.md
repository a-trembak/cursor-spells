---
description: Orchestrate a bug-fix pipeline from a Jira ticket — fetch issue, write fix plan, auto-critique (incl. regression/root-cause), fix via bug-fixer, engineer-review, draft PR. HITL only when critic is blocked or pending accept (plus review clarifications).
argument-hint: "[jira-key|jira-url]"
---

# /start-issue-task

Bug-fix entry point. Chains diagnose → plan → critic → fix → review → draft PR. Does **not** run tech-spec, approve-plan HITL, finish-plan HITL, or update-docs.

## Arguments

- Jira issue key (`PROJ-123`) or browse URL. If omitted, ask for it (typed chat — not a closed-set HITL gate).

## Pipeline (in order)

1. **Bootstrap** (automatic):
   - Read `.cursor/project-patterns.md` in the current project if present.
   - Detect stack mechanically via `skills/engineer-review/references/skill-map.md`.

2. **Fetch Jira** (automatic):
   - Resolve issue key from the argument/URL.
   - Read the issue via **Atlassian MCP** (`getJiraIssue` or equivalent after discovering tools with the MCP schema helpers).
   - Use summary, description, acceptance criteria / repro steps, status, and links as the bug source of truth.
   - If MCP is missing, unauthenticated, or the fetch fails: **stop**. Ask the human to paste the ticket text (and optionally retry MCP). Do not invent ticket contents. Do not continue on a URL-only stub.

3. **Fix plan** (automatic):
   - Investigate enough to draft a root-cause-oriented fix plan (read-only exploration + ticket facts). Prefer loading `systematic-debugging` / `ce-debug mode:pipeline` while diagnosing for the plan.
   - Write English plan to `docs/superpowers/plans/YYYY-MM-DD-<jira-key>-fix.md` following `clean-decision-docs` (final-form only).
   - Plan must include: reported failure, reproduction, hypothesized root cause, proposed minimal fix, regression/blast-radius notes, test plan that would catch the bug, rejected alternatives (one line each).

4. **Critic** (automatic — no plan-approve HITL):
   - `pg_write_gate` critique-gate for this plan path; `pg_clear_gate` plan-critique-clear for a prior revision of **this** plan only.
   - Run `implementation-critic` / agent `implementation-critic` with **Pass A, B, and C** (bug-fix plan).
   - On `Verdict: clear`: `pg_clear_gate` critique-gate; `pg_write_gate` plan-critique-clear (plan path); continue.
   - On `blocked` or `clear pending accept`: keep this plan's `critique-gate/<slug>`; **stop** and ask via skill **`hitl-choice`** preset **Blocked / pending-accept critic** (AskQuestion required; text only after failed/missing tool). On `revise`, rewrite the plan (`clean-decision-docs`) and re-run from step 4. On `accept F<id>` until clear, continue.

5. **Fix** (automatic on clear): dispatch agent **`bug-fixer`** / skill **`bug-fix`** for that plan (feature branch, reproduce, root cause, regression test, minimal fix, verify).

6. **Engineer review** (automatic): run agent **`engineer-reviewer`** (or `multi-repo-supervisor` when 2+ repos changed per multi-repo probe). Skip `finish-plan` HITL. Skip Figma ask unless node URLs were already in the ticket/context. HITL only for **Needs clarification** via `hitl-choice`.

7. **Create PR** (automatic): invoke skill **`create-pr`**. Draft PR title includes the Jira key; body links the ticket and fix plan path.

## Notes

- This command never invents answers at critic/clarify HITL gates.
- Full feature work with AC → use `/start-task`. Small non-bug tasks without Jira → `/start-task --fast`.
- Unlike full `/start-task`, this pipeline **does** fetch Jira via MCP (it does not treat the URL as a reference-only stub).
