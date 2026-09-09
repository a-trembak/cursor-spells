---
description: Draft or structure a developer's technical action plan from agreed Acceptance Criteria, before writing an implementation plan
argument-hint: "[ac-source]"
---

# /csp-write-tech-spec

Run the **tech-spec** agent.

## Arguments

- Optional AC source: a ticket id, a Jira URL, a file path, or inline text. If omitted, ask for it before proceeding — never draft against an assumed feature.

## Steps

1. If the AC source looks like a Jira issue, invoke skill **`jira-fetch`** first. Use assembled `ac_text` as the AC body; record the key/URL as the AC reference. On fetch failure, stop and ask for pasted text.
2. Read and follow skill `tech-spec` (`skills/tech-spec/SKILL.md`).
3. Invoke agent `csp-tech-spec` with the AC text (fetched or pasted).
4. Follow the entry question (`human` / `agent`) via skill `hitl-choice` (AskQuestion required; text only after failed/missing tool).
5. **If `agent`:** follow the depth HITL (`light` / `full`) via `hitl-choice`.
   - **`light`:** draft the 7-section tech-spec per `references/template.md` + `references/question-discipline.md` (Blocker/Decision asks also use `hitl-choice`).
   - **`full`:** run the system-design designer + critic consensus loop, then merge into tech-spec per `references/full-path.md` (designer mode `draft-from-ac`).
6. **If `human`:** wait for a plan path or pasted notes; always run the full path per `references/full-path.md` (designer mode `format-human-plan`), then merge into tech-spec.
7. Stop for `approve-spec` / `revise` / `skip <reason>` via `hitl-choice` before any implementation plan is written.
8. On `revise`, rewrite the file as current truth per skill `clean-decision-docs` (summarize the turn's edits in chat only); if revision needs design rework, re-enter full-path consensus on the system-design file then re-merge.
9. After the spec file exists, invoke skill **`trajectory-judge`**. When scoring the order-export dogfood criteria, score `tech-spec-no-invented-facts` per skill `trajectory-score`.

## Notes

- Do not proceed to `writing-plans` until the spec's `Status` is `approved` or explicitly `skip`ped with a reason recorded in the file.
- This command never writes an implementation plan itself — only the tech spec.
- Spec files must not contain revision archaeology ("fixed", "changed to", What-changed sections); see `clean-decision-docs`.
