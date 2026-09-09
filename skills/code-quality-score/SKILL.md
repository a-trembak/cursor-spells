---
name: code-quality-score
description: >-
  Validate and hard-score kit code-quality golden fixtures. Use when checking
  product-tree sensors for evals/code-quality cases. Never replaces
  engineer-reviewer. No language-model judge.
---

# Code quality score

Kit-owned **product-tree** harness: golden case → workspace fixture → hard-sensor
`score`. Measures files, substrings, and shell tests — not agent path contracts
(those stay under `evals/trajectories/` + skill `trajectory-score`).

## When to Use

- After editing `evals/code-quality/cases/` or fixtures
- When a dogfood checklist asks to validate/score code-quality cases
- Not for scoring chat logs. Not a sixth engineer-review phase

## Resolve kit

```bash
KIT="$(tr -d '\n' < .cursor/cursor-spells-kit-path 2>/dev/null || true)"
if [[ -z "$KIT" ]]; then
  KIT="$(tr -d '\n' < "$HOME/.cursor/cursor-spells-kit-path" 2>/dev/null || true)"
fi
```

Skip when the kit path or scorer is missing. Continue the calling workflow. Say in one full sentence that code-quality score was skipped.

## Validate then score

```bash
python3 "$KIT"/scripts/code-quality-cases.py validate --kit-root "$KIT"
python3 "$KIT"/scripts/code-quality-cases.py score --kit-root "$KIT" \
  --runs-dir "$KIT"/evals/code-quality/fixtures/pass
# or one run:
python3 "$KIT"/scripts/code-quality-cases.py score --kit-root "$KIT" \
  --run "$KIT"/evals/code-quality/fixtures/pass/<case_id>.json
# or an arbitrary workspace:
python3 "$KIT"/scripts/code-quality-cases.py score --kit-root "$KIT" \
  --case "$KIT"/evals/code-quality/cases/<case_id>.json \
  --workspace /path/to/tree
```

## Hard sensors (no LLM judge)

- Expected files exist under the workspace
- Forbidden paths are absent
- Required substrings present; forbidden substrings absent
- Each `test_commands` entry exits 0 with cwd = workspace

## On FAIL

Print the `FAIL` lines. Do not invent a language-model re-judge. Fix the tree or the case, then re-score.

## Hard rules

- Do not replace `csp-engineer-reviewer` with this skill
- Do not copy `evals/` into consumer apps
- Do not fold these cases into `trajectory-cases.py`
- `mode:fast` cases must keep forbidding invented plan/tech-spec files when that is the contract
