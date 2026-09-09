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
| Bench reports | Write JSON under `evals/harness/reports/<timestamp>.json` (kit-only). Live `*.json` gitignored; keep `.gitkeep` (same pattern as `evals/trajectories/runs/`) |
| Slash command | `/csp-harness-status` — orientation only; does **not** advance gates |
| Skill | `harness-status` — same contract; prints inventory / last bench; never writes `.cursor/gates/` |
| Wiring matrix | Each `active` trajectory case → `wired` / `unwired` / `retired` from mention in `skills/trajectory-score/SKILL.md` (retired when the skill marks the case retired; wired when the case id appears; else unwired) |
| Context proxies | Bytes and line counts for `rules/*.mdc`, `AGENTS.md`, and the top-N largest `skills/*/SKILL.md` plus each skill’s `references/` tree |
| Context budget flags | Explicit section flags presence of budget guidance for `tech-spec`, `implementation-critic`, `engineer-review`, and `system-design` skills |
| Output | Human-readable text by default; `--json` for machine records |
| Bench attach | `--bench-report PATH` attaches that JSON; otherwise auto-pick the newest file under `evals/harness/reports/` when present |
| Install | Skills/commands install via existing glob in `scripts/install-to-project.sh`. Never copy `evals/` into consumer apps |

## Non-goals

- Advancing or clearing pipeline gates
- Replacing dogfood checklists or engineer-review
- Installing harness reports into consumer repositories
- Language-model judging of bench output

## Test plan

- `scripts/tests/harness-health-test.sh` — inventory JSON shape, wiring keys for known cases, `--json` exit 0
- `scripts/tests/harness-bench-test.sh` — bench writes a report JSON with expected fields; fails when a child test fails (isolated fake suite)
- Full `bash scripts/harness-bench.sh` green on the kit before merging skill/agent changes
