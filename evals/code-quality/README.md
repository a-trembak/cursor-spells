# Code-quality golden set

Hard-sensor contracts for tiny product-code outcomes. Kit-only — **not** installed into consumer apps.

Validate:

```bash
python3 scripts/code-quality-cases.py validate
bash scripts/tests/code-quality-cases-test.sh
```

Score golden pass workspaces:

```bash
python3 scripts/code-quality-cases.py score --runs-dir evals/code-quality/fixtures/pass
```

Sensors: expected files, forbidden paths, required/forbidden substrings, shell `test_commands`. No language-model judge.

See skill [`code-quality-score`](../../skills/code-quality-score/) and dogfood [`code-quality-evals-checklist.md`](../../docs/superpowers/dogfood/code-quality-evals-checklist.md).
