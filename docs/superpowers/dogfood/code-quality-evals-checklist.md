# Dogfood: code-quality evals

Manual checks for kit-only hard-sensor code-quality cases.

## Preconditions

- Working tree is the `cursor-spells` kit checkout
- Python 3 available as `python3`

## Steps

1. **Validate cases:**

   ```bash
   python3 scripts/code-quality-cases.py validate
   bash scripts/tests/code-quality-cases-test.sh
   ```

   Expect: exit 0; four `active` cases under `evals/code-quality/cases/`.

2. **Score golden pass fixtures:**

   ```bash
   python3 scripts/code-quality-cases.py score --runs-dir evals/code-quality/fixtures/pass
   ```

   Expect: `PASS` for each case id; process exit 0.

3. **Spot-check sensors** (optional): copy a fixture, delete an expected file, re-score with `--workspace` — expect `FAIL` and exit 1.

4. **Confirm install hygiene:** `csp install` / `scripts/install-to-project.sh` still does not copy `evals/` into consumer apps.

## Pass criteria

- [ ] `validate` green on committed cases
- [ ] Golden pass runs score green
- [ ] Hard sensors only (no language-model judge)
- [ ] `mode:fast` case forbids inventing plan/tech-spec paths
- [ ] Skill `code-quality-score` documents how to run validate/score
