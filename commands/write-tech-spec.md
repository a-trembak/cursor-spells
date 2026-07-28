---
description: Draft or structure a developer's technical action plan from agreed Acceptance Criteria, before writing an implementation plan
argument-hint: "[ac-source]"
---

# /write-tech-spec

Run the **tech-spec** agent.

## Arguments

- Optional AC source: a ticket id, a file path, or inline text. If omitted, ask for it before proceeding — never draft against an assumed feature.

## Steps

1. Read and follow skill `tech-spec` (`skills/tech-spec/SKILL.md`).
2. Invoke agent `tech-spec` with the AC source.
3. Follow the entry question (`human` / `agent`) and, in agent mode, the three-tier question protocol from `references/question-discipline.md`.
4. Stop for `approve-spec` / `revise` / `skip <reason>` before any implementation plan is written.
5. On `revise`, rewrite the file as current truth per skill `clean-decision-docs` (summarize the turn's edits in chat only).

## Notes

- Do not proceed to `writing-plans` until the spec's `Status` is `approved` or explicitly `skip`ped with a reason recorded in the file.
- This command never writes an implementation plan itself — only the tech spec.
- Spec files must not contain revision archaeology ("fixed", "changed to", What-changed sections); see `clean-decision-docs`.
