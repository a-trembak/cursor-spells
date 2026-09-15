# Kit harness bench

Machine-checkable health for the cursor-spells kit. **Not** installed into consumer apps (`csp install` never copies `evals/`).

## Inventory (no bench required)

```bash
python3 scripts/harness-health.py
python3 scripts/harness-health.py --json
python3 scripts/harness-health.py --bench-report evals/harness/reports/<timestamp>.json
```

Shows skill/command/agent/rule inventory, trajectory wiring vs `skills/trajectory-score/SKILL.md`, context-size proxies, and optional last bench summary.

## Full bench (before changing skills or agents)

```bash
bash scripts/harness-bench.sh
```

Runs every `scripts/tests/*.sh` with durations, then trajectory `validate` + `score --runs-dir evals/trajectories/fixtures/pass`. Writes `evals/harness/reports/<timestamp>.json`. Live report JSON is gitignored (keep `.gitkeep`).

Slash command `/csp-harness-status` and skill `harness-status` are orientation only — they do not advance pipeline gates.

## Related

- Trajectory corpus: [`../trajectories/README.md`](../trajectories/README.md)
- Code-quality evals: [`../code-quality/`](../code-quality/) (when present)
- Dogfood: [`../../docs/superpowers/dogfood/harness-health-checklist.md`](../../docs/superpowers/dogfood/harness-health-checklist.md)
- Security checklist contract (S1–S10 shared by reviewer + writers): `bash scripts/tests/security-hardening-checklist-test.sh`
