---
description: Orchestrate the full pipeline from Acceptance Criteria to a reviewed PR — bootstrap, tech spec, plan, pre-build critique, execution, and post-plan review, stopping only at established human-in-the-loop gates
argument-hint: "[ac-source]"
---

# /start-task

Entry point for the whole pipeline. Chains every stage automatically except the established human-in-the-loop (HITL) gates — it does not skip or soften any of them.

## Arguments

- Optional AC source: a ticket id, a Jira/tracker URL, a file path, or inline text. If omitted, ask for it.

## Pipeline (in order)

1. **Bootstrap** (automatic):
   - Read `.cursor/project-patterns.md` in the current project if present (create it via the `engineer-review` patterns flow on first use of this kit in a project, if entirely absent).
   - Detect the project's stack mechanically (same signals as `skill-map.md`'s stack-detection table: `package.json`, `pom.xml`, `docker-compose`, dependency names) — no reasoning call, a table lookup.
2. **Tech spec** — invoke skill `tech-spec` (agent `tech-spec`) with the AC source, the patterns file path (if found), and the detected stack label:
   - **HITL:** the entry question (`human` / `agent`).
   - **HITL:** any Blocker/Decision-tier questions the draft surfaces, per `references/question-discipline.md`.
   - **HITL:** `approve-spec` / `revise` / `skip <reason>`.
3. **Plan** (automatic once the spec's `Status` is `approved` or explicitly `skip`ped): invoke `writing-plans` with the tech spec as input to produce the implementation plan. Do not ask which execution strategy yet — that's decided in step 5.
4. **Pre-build critique** (automatic start, HITL only if blocked): invoke skill `start-build` on the new plan.
   - **HITL:** only if `implementation-critic`'s `Verdict` is `blocked` or `clear pending accept` — wait for a plan revision or `accept F<id>` replies.
5. **Execution** (automatic once `Verdict: clear`): dispatch `subagent-driven-development` by default (fresh implementer + task reviewer per task, continuous execution) — do not ask "which approach?" in this orchestrated flow. If the user has already indicated they want a separate session, honor `executing-plans` instead.
6. **Finish plan** (automatic invocation of the existing HITL gate): once all tasks are complete, invoke skill `finish-plan`:
   - **HITL:** `skip` / `approve` / `done` before `engineer-review` starts.
7. **Engineer review** (automatic once the HITL gate clears): run `engineer-reviewer` (or `multi-repo-supervisor` for 2+ changed repos).
   - **HITL:** only for `Needs clarification` items the review surfaces.

## Notes

- This command never invents an answer at any HITL gate above — it always stops and waits for the human's reply at exactly those points, and only those points.
- If AC do not exist yet, stop and say so — writing AC themselves is out of scope for this kit.
- A Jira/tracker URL is accepted as the AC source verbatim (recorded as a reference in the tech spec's "AC references" section) — this kit does not fetch ticket contents via an API; paste the relevant description/AC text alongside the link if the tech-spec agent needs more than the link itself.
