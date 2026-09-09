---
name: harness-status
description: >-
  Use when the human runs /harness-status, or before changing kit skills/agents
  and needs an inventory + last bench summary. Orientation only — never advances
  gates.
---

# Harness status

Thin orientation skill. Inventory of kit skills/commands/agents/rules, trajectory
wiring against `skills/trajectory-score/SKILL.md`, static context-size proxies,
and the newest bench report under `evals/harness/reports/` when present. Does
**not** write gates or run the full bench unless the human asks.

## When to Use

- When the human runs `/harness-status`
- Before editing skills or agents — confirm wiring and last bench
- Anytime an orchestrator needs harness inventory without advancing the pipeline

## How to run

1. Resolve kit root (cwd when it has `scripts/harness-health.py`, else kit path file / `$KIT`).
2. Run:

```bash
python3 scripts/harness-health.py
# optional machine record:
python3 scripts/harness-health.py --json
# optional explicit bench attach:
python3 scripts/harness-health.py --bench-report evals/harness/reports/<timestamp>.json
```

3. Print the inventory in the user-facing turn. Do **not** advance, clear, or invent gates.
4. To refresh the bench (may take a few minutes):

```bash
bash scripts/harness-bench.sh
```

Only start the bench when the human asked for it or when a dogfood checklist step requires it.

## Cursor context ring vs kit proxies

| Signal | What it measures | How to use it |
|--------|------------------|---------------|
| Cursor context ring (IDE) | Live tokens loaded into the **current chat** (open files, rules, skills pulled this turn) | Watch while working — trim open tabs / avoid loading huge skills mid-turn |
| Kit proxies from `harness-health` | Static **bytes/lines** for `rules/*.mdc`, `AGENTS.md`, and top-N `skills/*/SKILL.md` + `references/` | Spot oversized always-on files **before** changing skills; not a live ring substitute |
| Context budget flags | Whether named skills document a context-budget section | Missing flag → consider adding budget guidance in that skill |

Never claim the proxy numbers equal the ring. They are different instruments.

## Language contract

- Script stdout is a **machine / English skeleton** (stable labels for agents and tests).
- Adapt into the human’s language with skill `plain-language-chat` (full words; Ukrainian when the human writes Ukrainian).

## Failure

If the script is missing or exits non-zero: say in **one sentence** that harness orientation was skipped. Never invent wiring states.

## Hard rules

- Never mutate `.cursor/gates/`
- Never treat `/harness-status` as a gate that unlocks `start-build` or review
- Never copy `evals/` into consumer apps
