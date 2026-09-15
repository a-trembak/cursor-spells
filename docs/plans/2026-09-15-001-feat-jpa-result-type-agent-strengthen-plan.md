---
title: JPA Result Type Agent Strengthen - Plan
type: feat
date: 2026-09-15
topic: jpa-result-type-agent-strengthen
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-brainstorm
execution: code
---

# JPA Result Type Agent Strengthen - Plan

## Goal Capsule

- **Objective:** Stop the kit software-developer and engineer-review logic phase from shipping or approving Spring Data repository diffs where a method return type disagrees with the Hibernate selection type on an org-scoped path while the fleet path already works.
- **Product authority:** This Product Contract, then Planning Contract / Implementation Units below. Broader Java five-hundred hardening (live Hibernate eval fixtures, mandatory HTTP smoke on every handoff) is not active scope.
- **Open blockers:** None.
- **Execution profile:** Kit instruction and contract-test changes only (`execution: code` in this repository). No consumer application repositories.
- **Tail ownership:** After U1–U5 land and Verification Contract commands pass, open or update the kit pull request; human merges. Deferred eval/smoke work stays out of this branch.

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

- R5. When R3 triggers, the logic phase Coverage must record `jpa_result_type` with a value in `{matched|mismatched|skipped|n/a}` stating whether return type and selection type were checked on both the scoped and fleet (or unscoped) paths when both exist.
- R6. Enforcement matches the existing `null_safety_callers` pattern: phase-protocol + logic agent require the key when the trigger applies; kit contract tests fail if that wiring is removed. When a Coverage section includes `jpa_result_type`, `validate-review-report.sh` rejects values outside the allowed set. Full “trigger fired but key omitted” is not inferred by the shell validator alone (same limit as other Coverage keys today).
- R7. Merge Coverage documentation in the phase protocol lists `jpa_result_type` alongside existing required coverage notes so orchestrator and phases agree.

**Contract proof**

- R8. Kit contract tests fail if the logic agent no longer opens the checklist, if the developer / bug-fix mirrors omit the load, or if the validator no longer enforces the allowed-value check for `jpa_result_type` when present.

**Explicit non-requirements this slice**

- R9. This slice does not require a live Hibernate fixture under `evals/code-quality/`, does not require a mandatory HTTP smoke with `orgUuid` on every handoff, and does not add a new review phase agent.

### Key Flows

- F1. Implementer changes a repository finder used on an org-scoped path → loads the mirror gate → compares method return type to query selection and to the fleet sibling → only then hands off. Covers R1, R4.
- F2. Engineer-review logic sees repository or query return-shape changes → opens checklist → traces scoped and fleet methods → sets Coverage per R5 → report validate per R6. Covers R3, R5, R6.
- F3. Bug-fix reproduces a scoped five-hundred with a result-type mismatch message → applies the same gate before coding a fix. Covers R4.

### Acceptance Examples

- AE1. Given a diff that adds or changes `find…By…OrgUuid` returning `List<String>` while the query selects an installation entity (or multiple columns), when logic review runs, it must not emit Coverage `matched` and must surface a finding or `mismatched` until the selection matches the declaration (explicit `@Query` scalar / projection / `Tuple` as appropriate). Covers R1, R3, R5.
- AE2. Given fleet already has an explicit scalar `@Query` and scoped uses a different method without a matching selection, review and developer gates both require checking both paths, not only the path named in the ticket. Covers R3, R4.
- AE3. Given a report whose Coverage line has `jpa_result_type: bogus`, `validate-review-report.sh` exits non-zero. Given the logic agent or phase-protocol no longer requires `jpa_result_type` on trigger, kit contract tests fail. Covers R6, R7, R8.
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

- Soft triggers may still be skipped if Coverage is marked `skipped` without challenge; prefer failing closed in checklist prose when the diff clearly touches repository return shapes (treat unjustified `skipped` as a logic finding).
- A second unread checklist competes with Criteria; keep the new file short and give logic a distinct trigger block so both stay openable.

**Outstanding questions**

- None blocking. Deferred eval/smoke work is out of scope per KD4 / R9.

### Success Criteria

- A scoped-versus-fleet return-type mismatch of the AE1/AE2 shape cannot pass a validated logic review without an explicit Coverage value and, on mismatch, a finding.
- Software-developer and bug-fix load paths name the same gate so both author and reviewer share one miss class.
- Contract tests guard the wiring; no live Hibernate stack is required for this slice to be considered done.

---

## Planning Contract

### Key Technical Decisions

- KTD1. Own the miss in a **sibling** checklist `skills/engineer-review/references/jpa-repository-result-checklist.md` (gate **RT1**), not inside `jpa-criteria-checklist.md`. Criteria gates stay fetch/`EXISTS` correlation; this gate is repository method return type versus Hibernate selection and scoped-versus-fleet asymmetry. Governs R1, R3.
- KTD2. Coverage token is exactly `jpa_result_type: matched|mismatched|skipped|n/a`. Wire it in `phase-protocol.md` merge Coverage list and in `csp-review-logic` trigger text. Governs R5, R7.
- KTD3. Developer mirror is `skills/software-developer/references/jpa-repository-result-patterns.md` plus a conditional load line in `skills/software-developer/SKILL.md` and a discoverability mention in `agents/csp-software-developer.md` (same pattern as Criteria patterns). Bug-fix loads the **same** checklist path (pointer in `skills/bug-fix/SKILL.md` skill-routing table and `agents/csp-bug-fixer.md`) when the fix touches repository / `@Query` / result-type mismatch — no duplicate prose body. Governs R4.
- KTD4. Validator change is **narrow**: if Coverage (or the report body outside fences) contains `jpa_result_type`, the value must match the enum; otherwise fail. Do not invent trigger detection in bash. Absence-on-trigger stays on phase-protocol + agent + contract greps, matching `null_safety_callers`. Governs R6, R8.
- KTD5. Seed `miss_jpa-repository-result-type-mismatch` in `learned-misses.md` with `phases: [logic]`, `gate: RT1`, checklist pointer to the new file. Update slim-context / do-not-delete lists and `engineer-review-context-budget-test.sh` the same way null-safety and jpa-criteria are guarded. Governs R2, R8.

### High-level design

```text
software-developer / bug-fixer
  └─ load jpa-repository-result-patterns.md  OR  shared checklist (bug-fix)
        └─ before handoff: RT1 (return type ↔ selection; scoped ↔ fleet)

csp-review-logic (on trigger)
  └─ open jpa-repository-result-checklist.md → RT1
  └─ Coverage: jpa_result_type: …

orchestrator merge (phase-protocol)
  └─ must note jpa_result_type when trigger applies

validate-review-report.sh
  └─ if jpa_result_type present → enum check only

contract tests
  └─ assert files exist, logic opens checklist, mirrors load, validator enum
```

### Assumptions

- A1. Pattern parity with `null-safety-checklist.md` / `null_safety_callers` is enough for R6 given the confirmed HOW scope; a future plan may harden bash trigger detection.
- A2. Extending `jpa-criteria-patterns.md` instead of a sibling developer file would blur Criteria versus repository concerns; rejected under KTD1/KTD3.

### Implementation constraints

- English-only instruction and commit messages; chat to humans stays full words per `plain-language-chat`.
- Never hardcode consumer product/server names (R2 / KD3).
- Do not edit consumer application repos.
- Prefer strengthen-in-place; do not add a new phase agent.
- Parent chat must not patch product trees; this work is kit-only and may be executed via nested coding agents per harness rules.

### Sequencing

1. U1 — checklist + learned-miss (authoritative rule text).
2. U2 — logic agent + phase-protocol Coverage (review path).
3. U3 — developer + bug-fix mirrors (author path).
4. U4 — validator enum check + fixtures.
5. U5 — contract tests + slim-context / do-not-delete wiring (RED first where practical, then green).

U2 and U3 may proceed in parallel after U1. U4 and U5 may proceed in parallel after U2 (U5 also needs U3 mirrors present for greps).

### Research inputs

- Grounding dossier (session): `/tmp/compound-engineering-1000/ce-brainstorm/aurora-500-strengthen/grounding.md`
- Patterns to mirror: `null-safety-checklist.md`, `jpa-criteria-checklist.md`, `software-developer` Criteria load, `engineer-review-context-budget-test.sh`, `validate-review-report.sh`, slim-context do-not-delete list.

---

## Implementation Units

### U1. Checklist RT1 + learned miss seed

- **Goal:** Canonical rule text for the miss class exists and is loadable by phases.
- **Requirements:** R1, R2, R9 (no product names; illustration-only QA shape).
- **Files:**
  - Create: `skills/engineer-review/references/jpa-repository-result-checklist.md`
  - Modify: `skills/engineer-review/references/learned-misses.md`
- **Approach:** Write gate **RT1** with triggers (repository method returning scalar/id collection; `@Query` / derived / Criteria selection; scoped versus fleet forks; Hibernate “result type did not match Query selection type” wording). Required checks: declare type versus selection type; compare scoped and fleet (or unscoped) siblings; flag entity or multi-column selection into `List<String>` (or similar); prefer explicit scalar `@Query` / projection / `Tuple` when declaring scalars. Anti-pattern: approving scoped finder while fleet already has matching `@Query`. Add YAML miss seed `miss_jpa-repository-result-type-mismatch` pointing at RT1 and this checklist; `phases: [logic]`.
- **Test scenarios:**
  - Checklist contains RT1, enum-aligned language for matched/mismatched, and forbids product server names.
  - Learned-miss id and `gate: RT1` present; `checklist` path points at the new file.
- **Verification:** File exists; greps for RT1 and miss id succeed; no product nickname strings.
- **Dependencies:** None.

### U2. Logic phase trigger + Coverage protocol

- **Goal:** Reviewer must open RT1 and emit `jpa_result_type` when triggered.
- **Requirements:** R3, R5, R7.
- **Files:**
  - Modify: `agents/csp-review-logic.md`
  - Modify: `skills/engineer-review/references/phase-protocol.md`
  - Modify: `docs/superpowers/specs/2026-09-09-slim-engineer-review-context-design.md` (do-not-delete / phase-only table) **or** whichever live slim-context list the budget test treats as source of truth — prefer the same files the existing jpa-criteria entries use (`engineer-review-context-budget-test.sh` do-not-delete loop + orch no-load-body list).
- **Approach:** Add a trigger block parallel to null-safety / Criteria: on repository / `@Query` / projection / scoped-versus-fleet identifier returns, open `jpa-repository-result-checklist.md` and apply **RT1**. Require Coverage `jpa_result_type: matched|mismatched|skipped|n/a`. Add the same must-note bullet under Orchestrator merge in `phase-protocol.md`. Include the new basename in do-not-delete / orch-must-not-load-body lists.
- **Test scenarios:**
  - Logic agent text opens the new checklist path.
  - Phase-protocol mentions `jpa_result_type` with the four allowed values.
  - Orchestrator still must not paste checklist bodies (existing orch_no_load_body asserts still pass for the new basename).
- **Verification:** Covered by U5 greps; manual read of trigger block.
- **Dependencies:** U1.

### U3. Software-developer and bug-fix mirrors

- **Goal:** Authors load the same gate before handoff / fix.
- **Requirements:** R4.
- **Files:**
  - Create: `skills/software-developer/references/jpa-repository-result-patterns.md`
  - Modify: `skills/software-developer/SKILL.md`
  - Modify: `agents/csp-software-developer.md`
  - Modify: `skills/bug-fix/SKILL.md`
  - Modify: `agents/csp-bug-fixer.md`
- **Approach:** Developer patterns file restates RT1 in implementer voice (correct scalar `@Query` sketch as directional guidance only; wrong entity selection into `List<String>`; check fleet sibling). Skill routing: when task touches repository methods, `@Query`, projections, or org-scoped versus fleet identifier queries, load the patterns file before handoff. Agent gets a one-line discoverability mention (Criteria already missing from agent — fix discoverability for both if cheap, but this unit only requires the new gate). Bug-fix skill-routing table row: load `jpa-repository-result-checklist.md` (shared) when the defect is result-type mismatch or the fix touches those surfaces.
- **Test scenarios:**
  - Developer skill references `jpa-repository-result-patterns.md`.
  - Bug-fix skill references `jpa-repository-result-checklist.md`.
  - Agent files mention the load or path tokens asserted by U5.
- **Verification:** U5 greps.
- **Dependencies:** U1.

### U4. Validator allowed-value check

- **Goal:** Invalid `jpa_result_type` values cannot pass report validation.
- **Requirements:** R6 (narrow), R8 (validator half).
- **Files:**
  - Modify: `scripts/validate-review-report.sh`
  - Modify or create fixtures under `scripts/tests/` (prefer extending `review-response-quality-test.sh` or adding a focused assert in an existing validate harness if one exists; otherwise add a small fixture + asserts beside that suite).
- **Approach:** After existing evidence checks, if the stripped BODY matches `jpa_result_type`, require `jpa_result_type:[[:space:]]*(matched|mismatched|skipped|n/a)\b`. Fail on other values. Add a fixture report with `jpa_result_type: bogus` expecting non-zero, and one with `matched` expecting zero (when other evidence rules are satisfied or isolated).
- **Test scenarios:**
  - Bogus value → exit non-zero with a clear FAIL line.
  - Allowed value → does not fail the enum check.
  - Report without any `jpa_result_type` → unchanged behavior versus today (no new failure).
- **Verification:** Run the chosen test script; see ALL PASS / exit 0.
- **Dependencies:** U2 (protocol documents the key; not a hard code dependency).

### U5. Contract tests (RED then GREEN)

- **Goal:** Wiring cannot silently regress.
- **Requirements:** R8, AE3, AE4.
- **Files:**
  - Modify: `scripts/tests/engineer-review-context-budget-test.sh`
  - Optionally: `scripts/tests/developer-reviewer-handoff-test.sh` or `teach-review-contract-test.sh` if they assert checklist inventories — only if greps already live there for jpa-criteria.
- **Approach:** Extend budget test: `assert_file` for the new checklist; `assert_grep` logic opens it; include basename in do-not-delete loop and orch_no_load_body loop; assert phase-protocol `jpa_result_type`; assert developer skill patterns path; assert bug-fix checklist path. Prefer adding failing asserts first, then implementing U1–U4 until green.
- **Test scenarios:**
  - Before instruction edits: new asserts fail.
  - After U1–U4: `bash scripts/tests/engineer-review-context-budget-test.sh` passes; validator fixture tests pass.
- **Verification:** `bash scripts/tests/engineer-review-context-budget-test.sh` and the U4 validator test command both exit 0.
- **Dependencies:** U1–U4 for green; may start RED asserts in parallel with U1.

---

## Verification Contract

- Primary: `bash scripts/tests/engineer-review-context-budget-test.sh`
- Validator: the U4 fixture command(s) added beside existing review-report tests (document the exact invocation in the unit when implementing; expected pattern `bash scripts/tests/<name>.sh`).
- Spot-check (manual): `rg -n 'jpa_result_type|jpa-repository-result|RT1|miss_jpa-repository-result-type' skills agents scripts docs/superpowers/specs`
- Out of scope: `evals/code-quality/` Java cases; live HTTP smoke; consumer app tests.

## Definition of Done

- All of U1–U5 merged intent present on the feature branch.
- Verification Contract commands exit 0.
- Product Contract R1–R8 satisfied; R9 respected (no live Hibernate eval, no mandatory smoke, no new phase agent).
- Pull request description names the miss class and points at RT1 / `jpa_result_type` without consumer product names.
- No unresolved blocking questions in this plan.
