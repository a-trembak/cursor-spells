# Harness health and bench

## Status

`approved` — kit-only inventory and regression bench for cursor-spells. Scope is orientation plus hard-sensor bench; no new pipeline gates.

## Goal

Give maintainers a fast answer to “is the harness still healthy?” before changing skills or agents: what is wired, how large context proxies are, and whether the full shell test suite plus trajectory golden fixtures still pass.

## Decisions

| Decision | Choice |
|----------|--------|
| Inventory script | `python3 scripts/harness-health.py` — stdlib only; reports inventory without requiring a full bench |
| Bench script | `bash scripts/harness-bench.sh` — runs every `scripts/tests/*.sh` sequentially with durations, then `python3 scripts/trajectory-cases.py validate` and `score --runs-dir evals/trajectories/fixtures/pass` |
| Bench reports | Write JSON under `evals/harness/reports/<timestamp>.json` (kit-only) with per-step durations plus a `metrics` object: `quality` (pass rates, trajectory validate/score status), `speed` (total, p50/p95/max, slowest steps), and `review_response_quality` (evidence completeness, clarify options, markdown validator on golden fixtures via `scripts/review-response-quality.py`). Live `*.json` gitignored; keep `.gitkeep` (same pattern as `evals/trajectories/runs/`) |
| Slash command | `/csp-harness-status` — orientation only; does **not** advance gates |
| Skill | `harness-status` — same contract; prints inventory / last bench; never writes `.cursor/gates/` |
| Wiring matrix | Each `active` trajectory case → `wired` / `unwired` / `retired` from mention in `skills/trajectory-score/SKILL.md` (retired when the skill marks the case retired; wired when the case id appears; else unwired) |
| Context proxies | Bytes and line counts for `rules/*.mdc`, `AGENTS.md`, and the top-N largest `skills/*/SKILL.md` plus each skill’s `references/` tree |
| Context budget flags | Explicit section flags presence of budget guidance for `tech-spec`, `implementation-critic`, `engineer-review`, and `system-design` skills |
| Output | Human-readable text by default; `--json` for machine records |
| Bench attach | `--bench-report PATH` attaches that JSON; otherwise auto-pick the newest file under `evals/harness/reports/` when present |
| Install | Skills/commands install via existing glob in `scripts/install-to-project.sh`. Never copy `evals/` into consumer apps |

## Live pipeline metrics (consumer projects)

Separate from kit bench reports: `scripts/pipeline-metrics.py` appends JSONL rows under the consumer project's `.cursor/gates/pipeline-metrics/history.jsonl` at wired score stops (`mark-start` after ledger init, `append-score` wrapping trajectory score, `append-review` after a validated review report). Humans run `summary` / `export --format csv` to graph pass rate and duration over time. Wired from `skills/trajectory-score`, `skills/create-pr`, and `skills/engineer-review`. Contract: `scripts/tests/pipeline-metrics-test.sh`.

## Non-goals

- Advancing or clearing pipeline gates
- Replacing dogfood checklists or engineer-review
- Installing harness reports into consumer repositories
- Language-model judging of bench output
- Building a chart UI inside the kit (export CSV/JSONL for external graphing)

## Test plan

- `scripts/tests/harness-health-test.sh` — inventory JSON shape, wiring keys for known cases, `--json` exit 0
- `scripts/tests/harness-bench-test.sh` — bench writes a report JSON with expected fields including `metrics.quality` / `metrics.speed`; fails when a child test fails (isolated fake suite)
- `scripts/tests/pipeline-metrics-test.sh` — live JSONL journal: mark-start, append-score, append-review, summary, export; skills mention the wire-up
- Full `bash scripts/harness-bench.sh` green on the kit before merging skill/agent changes
