---
title: JPA Result Type Agent Strengthen - Plan
type: feat
date: 2026-09-15
topic: jpa-result-type-agent-strengthen
artifact_contract: ce-unified-plan/v1
artifact_readiness: requirements-only
product_contract_source: ce-brainstorm
execution: code
---

# JPA Result Type Agent Strengthen - Plan

## Goal Capsule

- **Objective:** Stop the kit software-developer and engineer-review logic phase from shipping or approving Spring Data repository diffs where a method return type disagrees with the Hibernate selection type on an org-scoped path while the fleet path already works.
- **Product authority:** This Product Contract. Broader Java five-hundred hardening (new eval fixtures with a live Hibernate stack, mandatory HTTP smoke on every handoff) is not active scope.
- **Open blockers:** None that block planning.

---

## Product Contract

### Summary

Add a generalized miss class and matching gates so the coding agent and the logic reviewer must check repository return type versus query selection, and must compare org-scoped and fleet paths when both exist. Enforce the check with a required coverage key and a kit contract test. Do not add a new review phase or a live Hibernate eval in this slice.

### Problem Frame

Quality assurance proved a scoped `GET` with `orgUuid` returned HTTP 500 while the same list without org and a sibling summary with org returned 200. Hibernate rejected the result: the selection was an installation entity (multiple selections) while the repository method was declared as a list of strings. The fleet path already used an explicit `@Query` selecting scalars; the scoped finder did not. Existing kit gates cover Criteria correlation, null-safety across callers, and assumption-driven bugfix. None of them name return-type versus selection-type mismatch or asymmetric fleet versus scoped repository methods. Both the software-developer and the following engineer-reviewer missed the defect.

### Key Decisions

- KD1. Approach B — instructions plus required coverage key plus contract test. `(session-settled: user-directed — chosen over prose-only and over a first-slice live Hibernate eval with mandatory smoke: hard enough to block a silent close, cheap enough to land without a Java fixture stack.)` Governs R1–R8.
- KD2. One coherent miss class owned by the logic phase, mirrored into developer and bug-fix skill loads. `(session-settled: user-approved — chosen over a new review phase or a standalone agent: teach-review preference is strengthen existing checklists.)` Governs R1, R3, R4.
- KD3. Strip product server names from kit text; keep only transferable query and repository shapes. `(session-settled: user-approved — chosen over naming the consumer server in instructions: kit teach-review already strips product names.)` Governs R2.
- KD4. Defer live Hibernate code-quality cases and mandatory org-scoped HTTP smoke to a later plan. `(session-settled: user-directed — chosen over shipping them in this slice: first goal is to stop silent review close.)` Governs R9.

### Actors

- A1. Kit maintainer. Merges instruction and contract changes on the kit remote.
- A2. `csp-software-developer` (and implementer subagents). Must load and apply the gate before handoff when repository or query return shapes change.
- A3. `csp-review-logic` under `csp-engineer-reviewer` / `csp-pr-reviewer`. Must open the checklist on trigger and emit the coverage key.
- A4. `csp-bug-fixer` / bug-fix. Must load the same gate when fixing runtime query or repository five-hundreds of this shape.
- A5. Human running the pipeline. Sees a valid review report only when coverage rules pass; may teach further misses later.

### Requirements

**Miss class and instructions**

- R1. The kit defines one miss class for Spring Data / Hibernate cases where a repository method declares a scalar or identifier collection (for example `List<String>`) but the query selects an entity type or multiple columns that do not match that declaration.
- R2. Instruction text uses generalized triggers only (scoped versus fleet paths, `@Query` versus derived or Criteria selection, result-type error wording). It must not hardcode consumer product or server names.
- R3. The logic review phase opens the owning checklist whenever the diff touches repository methods, `@Query` strings, projections, or org-scoped versus fleet query forks that return identifiers or scalars.
- R4. The software-developer skill (and agent hard rules as needed for discoverability) and the bug-fix path load a developer-facing mirror of the same gate before handoff when those surfaces change.

**Coverage and validation**

- R5. When R3 triggers, the logic phase Coverage must record a stable key with values in `{matched|mismatched|skipped|n/a}` that states whether return type and selection type were checked on both the scoped and fleet (or unscoped) paths when both exist.
- R6. The review-report validator (or an adjacent always-run contract) fails when R3 triggers and the Coverage key from R5 is missing or uses a value outside the allowed set.
- R7. Merge Coverage documentation in the phase protocol lists the new key alongside existing required coverage notes so orchestrator and phases agree.

**Contract proof**

- R8. Kit contract tests fail if the logic agent no longer opens the checklist, if the developer / bug-fix mirrors omit the load, or if the validator no longer enforces R5–R6.

**Explicit non-requirements this slice**

- R9. This slice does not require a live Hibernate fixture under `evals/code-quality/`, does not require a mandatory HTTP smoke with `orgUuid` on every handoff, and does not add a new review phase agent.

### Key Flows

- F1. Implementer changes a repository finder used on an org-scoped path → loads the mirror gate → compares method return type to query selection and to the fleet sibling → only then hands off. Covers R1, R4.
- F2. Engineer-review logic sees repository or query return-shape changes → opens checklist → traces scoped and fleet methods → sets Coverage per R5 → report validate per R6. Covers R3, R5, R6.
- F3. Bug-fix reproduces a scoped five-hundred with a result-type mismatch message → applies the same gate before coding a fix. Covers R4.

### Acceptance Examples

- AE1. Given a diff that adds or changes `find…By…OrgUuid` returning `List<String>` while the query selects an installation entity (or multiple columns), when logic review runs, it must not emit Coverage `matched` and must surface a finding or `mismatched` until the selection matches the declaration (explicit `@Query` scalar / projection / `Tuple` as appropriate). Covers R1, R3, R5.
- AE2. Given fleet already has an explicit scalar `@Query` and scoped uses a different method without a matching selection, review and developer gates both require checking both paths, not only the path named in the ticket. Covers R3, R4.
- AE3. Given a review report where the trigger applied but the Coverage key is absent, `validate-review-report` (or the adjacent contract) exits non-zero and the report is not shown. Covers R6, R7.
- AE4. Given the checklist file is removed from the logic agent open-list or the developer mirror load line is deleted, kit contract tests fail. Covers R8.
- AE5. Quality-assurance shape from the motivating escape remains the golden story in examples only: scoped companies list with `orgUuid` → 500 and result-type mismatch text; without org → 200; sibling summary with org → 200. Instructions cite the shape, not the product name. Covers R2.

### Scope Boundaries

**In scope**

- Kit instruction files, learned-miss seed entry, coverage key, validator / contract tests, developer and bug-fix mirrors for this miss class.

**Deferred for later**

- Live Hibernate or Spring Data fixture under code-quality evals.
- Mandatory org-scoped HTTP smoke evidence on every software-developer handoff.
- Broadening to non-repository query APIs unrelated to return-type versus selection-type mismatch.

**Non-goals**

- Fixing any consumer application repository in this plan.
- Inventing a new always-on review phase.
- Replacing engineer-review with an eval score.

### Risks and Open Questions

**Risks**

- Soft triggers may still be skipped if Coverage is marked `skipped` without challenge; planning should prefer failing closed when the diff clearly touches repository return shapes.
- Overlap with existing Criteria checklists must strengthen or extend, not duplicate a parallel unread file.

**Deferred to Planning**

- Exact file layout: extend `jpa-criteria-checklist.md` versus a short sibling repository-result checklist under the same phase load.
- Exact Coverage key spelling (planning picks one stable token and wires validator + phase-protocol together).
- Whether bug-fix mirror is a short reference file or a pointer into the shared checklist.

### Success Criteria

- A scoped-versus-fleet return-type mismatch of the AE1/AE2 shape cannot pass a validated logic review without an explicit Coverage value and, on mismatch, a finding.
- Software-developer and bug-fix load paths name the same gate so both author and reviewer share one miss class.
- Contract tests guard the wiring; no live Hibernate stack is required for this slice to be considered done.
