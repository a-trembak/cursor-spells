# Skill load optimization — implementation plan

> **For agentic workers:** Execute task-by-task. Checkboxes track progress. Kit-only work (no `/csp-start-task`).

**Goal:** Cut third-party and process context waste without skipping kit miss-class checklists or always-on rules. Prove with before/after skill-load budget estimates and harness quality metrics.

**Architecture:** Behavior stays mechanical (triggers + skill-map). Add explicit skill classes and load levels (L0→L1→L2). Split `hitl-choice` presets so callers load one gate. Add tiny-diff heuristic phase skip. Optional consumer skill profile modulates **L2 only**.

**Tech stack:** Markdown skill/agent contracts, bash/python harness scripts (stdlib).

## Constraints

- Rules (`rules/*.mdc`) stay constants — never behind a profile skip list.
- Kit miss checklists (R/S/F/J/N/RT/V/…) stay trigger-gated **L1** — never model-IQ skipped.
- Third-party mapped skills become **L2 enrichment** (same pattern as security-review).
- Do not vendor third-party bodies. Do not undo slim orchestrator context budget.
- Measurement uses kit-controlled byte/token proxies plus harness-bench quality — live Cursor bill is out of band.

## Success metrics

| Metric | Pass if |
|--------|---------|
| Harness bench `metrics.quality.pass_rate` | Still `1.0` after change |
| Trajectory validate + score fixtures | Still pass |
| Review-response quality fixtures | Still pass |
| Skill-load budget `lean` estimated tokens | Strictly lower than baseline `strict` for the same scenario set |
| Kit L1 checklist paths still required on triggers | Contract tests green |

---

### Task 1: Measurement harness (baseline before behavior change)

**Files:**
- Create: `scripts/skill-load-budget.py`
- Create: `scripts/tests/skill-load-budget-test.sh`
- Create: `evals/harness/skill-load/.gitignore` (ignore `*.json` reports; keep `.gitkeep`)

**Steps:**
1. Script estimates tokens (`ceil(bytes/4)`) for scenarios: always-on rules+orch, engineer-review phase with/without L2 placeholders, `hitl-choice` full vs single-preset, software-developer with/without L2.
2. Emits JSON under `evals/harness/skill-load/<timestamp>-<label>.json` and a short text summary.
3. Contract test: script exits 0, JSON has `scenarios` + `totals`.
4. Run baseline: `python3 scripts/skill-load-budget.py --label baseline` and `bash scripts/harness-bench.sh`; save paths in the comparison doc later.

---

### Task 2: Taxonomy + load levels in skill-map

**Files:**
- Modify: `skills/engineer-review/references/skill-map.md`
- Modify: `skills/engineer-review/references/skill-map-orch.md` (one-line pointer)
- Modify: `skills/software-developer/SKILL.md` (Skill routing respects L2 / profile)
- Modify: `agents/csp-review-logic.md`, `agents/csp-review-architecture.md`, `agents/csp-review-performance.md`, `agents/csp-review-deadcode.md`, `agents/csp-review-simplify.md` (L2 enrichment wording)
- Modify: `scripts/tests/mapped-third-party-skills-test.sh` or new asserts in skill-load / engineer-review tests for taxonomy headings

**Steps:**
1. Add sections: Skill classes, Load levels (L0/L1/L2), Skill profile (`strict`/`balanced`/`expert`), Enrichment policy.
2. Phase → skills table: mark stack/third-party rows as L2; kit checklists remain L1 on trigger.
3. Writers/phases: missing L2 → `skill_missing` or `skill_skipped_by_profile` + built-in/kit path; never skip L1.

---

### Task 3: Lazy `hitl-choice` presets

**Files:**
- Create: `skills/hitl-choice/references/presets.md` (move Gate presets body)
- Modify: `skills/hitl-choice/SKILL.md` (protocol stays; instruct open **only** the named preset heading)
- Update contract tests that grepped presets in `SKILL.md` to also accept `references/presets.md`

**Steps:**
1. Move `## Gate presets` content to `references/presets.md`.
2. SKILL protocol: after resolving the gate name, load only that `###` section from presets (not the whole catalog).
3. Fix tests (`propose-commit`, `teach-review`, `jira-ac-router-finale`, `trajectory-wiring`, `local-diff-review-gate`, `clarify-question-evidence`, …).

---

### Task 4: Tiny-diff heuristic phase skip

**Files:**
- Modify: `skills/engineer-review/references/phase-protocol.md`
- Modify: `skills/engineer-review/SKILL.md` (spine note)
- Modify: `agents/csp-engineer-reviewer.md` if hard-rule pointer needed
- Modify: `scripts/tests/engineer-review-context-budget-test.sh` (assert skip policy text)

**Steps:**
1. When changed files ≤ **3** and changed LOC ≤ **40**, and paths are non-risky (no auth/migration/security sinks/JPA/schema), orchestrator may skip heuristic phases `deadcode`, `simplify`, `architecture`, `performance` in `find`.
2. Always keep `lint` + `logic` + `patterns` (patterns may no-op quickly). Security/figma still follow their own triggers.
3. Coverage must list `phase_skip: tiny-diff (<phases>)`.

---

### Task 5: After metrics + comparison write-up

**Files:**
- Create: `docs/superpowers/specs/2026-09-28-skill-load-optimization-results.md`
- Run: `python3 scripts/skill-load-budget.py --label after`
- Run: `bash scripts/harness-bench.sh`

**Steps:**
1. Compare baseline vs after token estimates and quality rates.
2. Pass/fail against Success metrics above.
3. Note residual risks (agents ignoring lazy preset instruction; profile not wired into Cursor product settings).

---

## Out of scope

- Auto model-capability detection.
- Deleting checklist bodies.
- Changing auto-fix eligibility or severity semantics.
- Live billed-token capture from Cursor cloud (use proxies + harness).
