# Skill profile A/B — live catch rates (`strict` vs `expert`)

## Status

`measured` — eight isolated phase reviews on four kit miss-class fixtures.

## Design

| Arm | Rule |
|-----|------|
| `strict` | May load third-party **L2** if installed; must open kit **L1** checklist |
| `expert` | Must **not** load L2 bodies; must still open kit **L1** checklist |

Fixtures under `evals/harness/skill-profile-ab/fixtures/`; cases under `cases/`; scorer `scripts/skill-profile-ab.py`.

## Results (live-ab)

| Profile | Runs | Caught | Catch rate | L2 loaded |
|---------|------|--------|------------|-----------|
| `strict` | 4 | 4 | **100%** | 0 (mapped third-party skills not installed in this environment) |
| `expert` | 4 | 4 | **100%** | 0 (forbidden by profile) |

**Verdict: `expert_ok`** — expert did not regress versus strict on these miss classes.

### Per case

| Case | Miss | Gates | strict | expert |
|------|------|-------|--------|--------|
| `sql-concat-idor` | security checklist skip | S1, S5 | catch | catch |
| `partial-null-callers` | partial null shared callers | N1 | catch | catch |
| `jpa-result-type` | JPA result type mismatch | RT1 | catch | catch |
| `sync-reset-api` | side-effect × live actor | R1 (+R2/R3/…) | catch | catch |

## Interpretation

1. Kit **L1** checklists alone were enough to catch these four production/teach-review miss classes when agents actually opened them.
2. In this Cloud Agent checkout, third-party L2 skills were not installed, so `strict` could not demonstrate extra catch from L2 — both arms ran L1-heavy. That strengthens the enrichment thesis: L2 is optional when L1 floors are solid.
3. This does **not** prove L2 never helps on other stacks or weaker models; it does support shipping `expert` / writer-lean as a safe default **when L1 triggers fire**.

## How to re-run

```bash
# after fresh agent runs land under runs/
python3 scripts/skill-profile-ab.py score-dir evals/harness/skill-profile-ab/runs --label live-ab
```

Report artifact: `evals/harness/skill-profile-ab/reports/*-live-ab.json` (gitignored live JSON; copy kept under `/opt/cursor/artifacts/` when generated in Cloud Agent).
