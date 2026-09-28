# Skill profile A/B (strict vs expert)

Live catch-rate experiment for kit miss classes when **L2** third-party skills are skipped (`expert`) versus allowed (`strict`). Kit **L1** checklists stay mandatory in both arms.

## Cases

| id | Miss class | Expected gates |
|----|------------|----------------|
| `sql-concat-idor` | security checklist skip | S1, S5 |
| `partial-null-callers` | partial null safety shared callers | N1 |
| `jpa-result-type` | JPA repository result type mismatch | RT1 |
| `sync-reset-api` | side-effect × live actor | R1 |

## Run

1. Dispatch isolated phase agents per case × profile (or reuse recorded runs under `runs/`).
2. Score:

```bash
python3 scripts/skill-profile-ab.py score-dir evals/harness/skill-profile-ab/runs --label live-ab
```

## Verdict rules

- `expert_ok` — expert catch rate ≥ strict − 1% and ≥ 75%
- `expert_regressed` — expert ≥25 points below strict
- otherwise `mixed` / `inconclusive`
