# Agent code-quality evals

## Status

`approved` — kit-only hard-sensor corpus for small product-code outcomes. Separate from trajectory path scoring. No language-model judge.

## Goal

Measure whether an agent’s **resulting tree** satisfies closed acceptance sensors (files present, forbidden paths untouched, tests green, required/forbidden substrings) for tiny fixtures. Complements trajectory evals (which score the agent path, not product-code taste).

## Decisions

| Decision | Choice |
|----------|--------|
| Location | Kit-root `evals/code-quality/` — not copied into consumer apps |
| Cases | `evals/code-quality/cases/<id>.json`; `id` equals filename stem; 3–5 `active` cases |
| Fixtures | Minimal trees under `evals/code-quality/fixtures/<id>/` (golden **pass** workspace used by score tests) |
| Pass run records | `evals/code-quality/fixtures/pass/<id>.json` pointing at the fixture workspace |
| Scorer | `python3 scripts/code-quality-cases.py validate\|score` — stdlib only; **not** folded into `trajectory-cases.py` |
| Hard sensors | Expected files exist; forbidden paths absent (or untouched / not created); `test_commands` exit 0; required substrings present; forbidden substrings absent |
| Judge | None — no LLM judge in `score` |
| Skill | `code-quality-score` — how to validate/score; never replaces `csp-engineer-reviewer` |
| Modes covered | Include at least one `mode:fast` case that forbids inventing plan/tech-spec files |
| Install | No special install; never copy `evals/` |

## Case contract

| Field | Meaning |
|-------|---------|
| `id` | Stable kebab id; matches filename |
| `title` | One-line English summary |
| `source` | Kit-relative path that owns the behavior (dogfood or spec) |
| `status` | `active` or `draft` |
| `mode` | `fast` / `full` / `issue` / `slice` — documentation of the intended pipeline mode |
| `fixture` | Kit-relative directory of the workspace tree to score |
| `expected_files` | Paths relative to fixture that must exist as files |
| `forbidden_paths` | Paths relative to fixture that must **not** exist |
| `required_substrings` | Map of relative file path → list of substrings that must appear |
| `forbidden_substrings` | Map of relative file path → list of substrings that must not appear |
| `test_commands` | List of shell commands run with cwd = fixture; each must exit 0 |

## Score run contract

A run JSON is:

| Field | Meaning |
|-------|---------|
| `case_id` | Must match a case file stem |
| `workspace` | Optional override directory; default = case `fixture` |

## Case ideas (v1)

1. Fix off-by-one bug + keep regression test green
2. Add a small function with a unit test
3. Must not touch an unrelated file / forbidden path
4. `mode:fast` — deliver code without inventing plan or tech-spec files under `docs/`

## Non-goals

- Replacing `csp-engineer-reviewer` or trajectory scoring
- Executing a live coding agent inside continuous integration
- Subjective style or design taste scoring

## Test plan

- Invalid case / missing fixture → `validate` exit 1
- Committed cases → `validate` exit 0
- Golden `fixtures/pass/*.json` → `score` exit 0
- Temp workspace missing expected file or failing test → `score` exit 1
- `bash scripts/tests/code-quality-cases-test.sh`
