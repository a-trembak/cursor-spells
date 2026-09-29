# Skill load optimization — before / after results

## Status

`measured` — plan executed on branch `cursor/skill-load-optimization-investigation-a044`.

## What changed

1. **Plan:** `docs/superpowers/plans/2026-09-28-skill-load-optimization-plan.md`
2. **Budget meter:** `scripts/skill-load-budget.py` (token proxy = `ceil(bytes/4)`)
3. **Taxonomy + L0→L1→L2 + Skill profile** in `skill-map.md` (default `strict`)
4. **Lazy `hitl-choice`:** protocol stays in `SKILL.md`; presets moved to `references/presets.md` (load one `###` section)
5. **Tiny-diff phase skip** in `phase-protocol.md` (≤3 files, ≤40 LOC, non-risky)
6. Writers / review phases honor L2 profile; kit L1 checklists remain mandatory on triggers

## Token proxy (skill-load budget)

| Metric | Baseline (before) | After (lean path) | Delta |
|--------|-------------------|-------------------|-------|
| Composite review-turn estimate | 48 631 | 33 550 | **−15 081 (−31% vs baseline composite)** |
| Lean savings vs same-build strict | 0% (no lean path) | 33.1% vs after-strict | lean unlocked |
| `hitl-choice` full catalog | 5 226 | 5 464 (split files slightly larger total) | — |
| `hitl-choice` protocol + one preset | n/a (not instructed) | **1 855** | **−64% vs old full skill** |
| Writer with L2 stack placeholder | same as lean | lean **9 245** vs strict **12 245** | −3 000 when L2 off |
| Logic phase lean vs strict | n/a | **11 457** vs **14 457** | −3 000 when L2 off |
| Tiny-diff phases run | 7 heuristics | 3 (`lint`/`patterns`/`logic`) | −4 phase dispatches × ~2 500 tok |

Notes:

- Estimates are **kit-controlled context proxies**, not live Cursor billing. Third-party L2 sizes use documented placeholders when skills are not installed in this checkout.
- After-build **strict** composite is slightly higher than baseline (~50 k) because skill-map grew with taxonomy docs and presets were split (total hitl bytes up a little). The **lean** path is the intended optimized run.

Artifact copies: `/opt/cursor/artifacts/skill-load-baseline.json`, `skill-load-after.json`.

## Quality (harness bench)

| Metric | Baseline bench | After bench |
|--------|----------------|-------------|
| `pass_rate` | 0.9756 (1 contract fail) | **1.0** |
| `contract_pass_rate` | 0.9737 | **1.0** |
| Trajectory validate | pass | pass |
| Trajectory score fixtures | pass | pass |
| Review-response quality fixtures | pass (`fixture_pass_rate=1.0`) | pass (`1.0`) |
| Evidence / clarify averages | 1.0 / 1.0 | 1.0 / 1.0 |

Baseline single failure was `teach-review-contract-test.sh` asserting outdated wording (`continue to skill propose-commit`) after `local-diff-review-gate` was inserted on `main`. The assert now matches the real preset text (`local-diff-review-gate` then `propose-commit`). That is a contract fix, not a quality regression from lean loading.

Artifact copies: `/opt/cursor/artifacts/harness-bench-baseline.json`, `harness-bench-after.json`.

## Quality verdict

**We did not lose harness quality.** After optimization the full bench is green (`pass_rate=1.0`), trajectory golden fixtures still pass, and review-response quality fixtures still score complete evidence and clarify options.

What this does **not** prove: live multi-model A/B that an `expert` profile catches the same production escapes as `strict` with L2 bodies loaded. That remains the Conditional-Go experiment from the investigation. Kit L1 floors (security, interaction-replay, JPA, …) were explicitly kept mandatory.

## How to re-run

```bash
python3 scripts/skill-load-budget.py --label snapshot
bash scripts/harness-bench.sh
python3 scripts/harness-health.py
```

## Follow-up: skill profile A/B

Live catch-rate experiment (`strict` vs `expert`) on four miss-class fixtures: **both arms 4/4 (100%)**, verdict `expert_ok`. See [`2026-09-28-skill-profile-ab-results.md`](2026-09-28-skill-profile-ab-results.md).

