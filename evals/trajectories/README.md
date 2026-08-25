# Agent trajectory golden set

Contracts for how the kit agent must behave on a given invocation. These files are **not** product tests and are **not** installed into consumer apps.

Validate cases:

```bash
python3 scripts/trajectory-cases.py validate
bash scripts/tests/trajectory-cases-test.sh
```

Score a recorded run (hard sensors only — no language-model judge):

```bash
python3 scripts/trajectory-cases.py score --run evals/trajectories/fixtures/pass/route-unknown-asks-human.json
python3 scripts/trajectory-cases.py score --runs-dir evals/trajectories/fixtures/pass
bash scripts/tests/trajectory-score-test.sh
```

## Add a case

1. Copy a close neighbor under `evals/trajectories/cases/`.
2. Set `id` to the new filename stem (`kebab-case.json`).
3. Point `source` at an existing kit file (dogfood checklist, spec, or command).
4. Use only the closed vocabularies in `scripts/trajectory-cases.py` (`pipeline`, stages, forbidden actions, human gates).
5. If the case covers a whole `full` / `fast` / `issue` path, set `end_to_end` to `true`. Route, gate, and fixture slices stay `false`.
6. If `required_stages` includes `create-pr`, `forbidden` must include `merge-pull-request`.
7. Run the two commands above.

Do not put live ticket secrets in `acceptance_criteria`. Prefer the fixtures already documented in dogfood checklists.

A later slice will execute the pipeline and write run records. This directory holds the corpus plus a deterministic scorer for those records.
