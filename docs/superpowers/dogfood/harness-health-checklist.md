# Dogfood: harness health

Manual checks for kit harness inventory and the full regression bench.

## Preconditions

- Working tree is the `cursor-spells` kit checkout
- Python 3 available as `python3`

## Steps

1. **Inventory without bench:**

   ```bash
   python3 scripts/harness-health.py
   python3 scripts/harness-health.py --json
   ```

   Expect: skill/command/agent/rule counts, a wiring line per **active** trajectory case (`wired` / `unwired` / `retired`), context proxies, context-budget flags, and either a last bench summary or “none”.

2. **Optional slash command:** run `/csp-harness-status` in chat. Expect orientation only — no new files under `.cursor/gates/`.

3. **Full bench** (before merging skill or agent edits; may take a few minutes):

   ```bash
   bash scripts/harness-bench.sh
   ```

   Expect: every `scripts/tests/*.sh` runs with a duration line; trajectory validate + fixture score run; a new `evals/harness/reports/<timestamp>.json` with `"ok": true` and a `metrics` object (`quality.pass_rate`, `speed.p50_duration_s` / `p95_duration_s`, `speed.slowest`); process exit 0.

4. **Re-read health with the new report:**

   ```bash
   python3 scripts/harness-health.py
   ```

   Expect: Bench report path points at the new file; `ok=true`.

5. **Contract tests:**

   ```bash
   bash scripts/tests/harness-health-test.sh
   bash scripts/tests/harness-bench-test.sh
   bash scripts/tests/security-hardening-checklist-test.sh
   bash scripts/tests/review-response-quality-test.sh
   bash scripts/tests/pipeline-metrics-test.sh
   ```

## Pass criteria

- [ ] Inventory JSON includes `wiring`, `context_proxies`, `context_budget`
- [ ] Active cases are classified from `skills/trajectory-score/SKILL.md`
- [ ] `/csp-harness-status` does not write gates
- [ ] Full bench exits 0 and writes a report under `evals/harness/reports/`
- [ ] Report includes `metrics.quality` (pass rates), `metrics.speed` (p50/p95/slowest), and `metrics.review_response_quality`
- [ ] `bash scripts/tests/pipeline-metrics-test.sh` exits 0 (live JSONL journal for consumer pipeline runs)
- [ ] `python3 scripts/harness-health.py` shows quality/speed lines when a bench report exists
- [ ] Live report `*.json` stays gitignored (`.gitkeep` remains)
- [ ] Diagrams + plain-language guide exist: [`../pipeline-metrics-guide.md`](../pipeline-metrics-guide.md) (images under `docs/superpowers/images/`)

## Related reading

- Ukrainian plain-language guide with architecture pictures: [`../pipeline-metrics-guide.md`](../pipeline-metrics-guide.md)
- English harness README: [`../../../evals/harness/README.md`](../../../evals/harness/README.md)
