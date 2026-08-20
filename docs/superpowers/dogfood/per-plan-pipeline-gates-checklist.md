# Per-plan pipeline gates dogfood fixture

Manual checklist to verify parallel chats/tickets do not share one global marker. Helper tests (`bash scripts/tests/pipeline-gates-test.sh`) cover slug/migrate/clear isolation; this fixture checks skill/hook semantics in a consumer project.

Do not require CI to execute agents.

## Setup

From kit root, install into a throwaway consumer (or use any git repo that already has `csp` install):

```bash
chmod +x scripts/*.sh scripts/tests/*.sh
./scripts/install-to-project.sh /tmp/pg-dogfood
cp scripts/pipeline-gates.sh /tmp/pg-dogfood/scripts/pipeline-gates.sh
```

In the consumer, `source scripts/pipeline-gates.sh` (or run from kit with `PG_ROOT` unset and first arg = consumer root).

Fake plans (do not need real plan bodies for marker checks):

- `docs/superpowers/plans/2026-08-07-acp-2656-export-plan.md`
- `docs/superpowers/plans/2026-08-07-acp-2665-billing-plan.md`

---

## Scenario 1 — Parallel critique

```bash
ROOT=/tmp/pg-dogfood
source "$ROOT/scripts/pipeline-gates.sh"  # or kit scripts/pipeline-gates.sh

pg_write_gate "$ROOT" critique-gate "docs/superpowers/plans/2026-08-07-acp-2656-export-plan.md"
pg_write_gate "$ROOT" critique-gate "docs/superpowers/plans/2026-08-07-acp-2665-billing-plan.md"

test -f "$ROOT/.cursor/gates/critique-gate/ACP-2656"
test -f "$ROOT/.cursor/gates/critique-gate/ACP-2665"

# Chat B (2656) becomes clear and starts build while 2665 stays blocked
pg_clear_gate "$ROOT" critique-gate "docs/superpowers/plans/2026-08-07-acp-2656-export-plan.md"
pg_write_gate "$ROOT" plan-critique-clear "docs/superpowers/plans/2026-08-07-acp-2656-export-plan.md"

test ! -f "$ROOT/.cursor/gates/critique-gate/ACP-2656"
test -f "$ROOT/.cursor/gates/critique-gate/ACP-2665"
test -f "$ROOT/.cursor/gates/plan-critique-clear/ACP-2656"
test ! -f "$ROOT/.cursor/gates/plan-gate/ACP-2656"
```

| Check | Expect |
|-------|--------|
| Two critique files | `ACP-2656` and `ACP-2665` both exist under `critique-gate/` |
| `start-build` for 2656 | Allowed: this slug has `plan-critique-clear`, no this-slug `plan-gate` / `critique-gate` |
| Chat A (2665) | Still blocked on its own `critique-gate/ACP-2665` |
| Foreign clear | Agent must **not** `rm` `ACP-2665` while finishing 2656 |

Hook smoke (unknown plan path stays silent even if 2665 is pending; known 2656 path does not nudge 2665 after 2656 is clear):

```bash
mkdir -p /tmp/pg-dogfood/.cursor/hooks
cp hooks/pre-build-gate.sh /tmp/pg-dogfood/.cursor/hooks/   # from kit
printf '{}' | env -i PATH="$PATH" bash -c "cd /tmp/pg-dogfood && bash .cursor/hooks/pre-build-gate.sh"
# Expect {} — do not list ACP-2665. A followup here would auto-continue every chat.
printf '{"plan_path":"docs/superpowers/plans/2026-08-07-acp-2656-export-plan.md"}' | env -i PATH="$PATH" bash -c "cd /tmp/pg-dogfood && bash .cursor/hooks/pre-build-gate.sh"
# Expect {} — 2656 is clear; must not treat 2665 as this chat's block.
```

---

## Scenario 2 — Legacy migrate-on-read

```bash
ROOT=/tmp/pg-dogfood-legacy
mkdir -p "$ROOT/.cursor" "$ROOT/scripts"
cp scripts/pipeline-gates.sh "$ROOT/scripts/"
source "$ROOT/scripts/pipeline-gates.sh"
printf '%s\n' "docs/plans/legacy-acp-100.md" > "$ROOT/.cursor/critique-gate.pending"
pg_migrate_legacy "$ROOT" critique-gate "docs/plans/legacy-acp-100.md"
test -f "$ROOT/.cursor/gates/critique-gate/ACP-100"
test ! -f "$ROOT/.cursor/critique-gate.pending"
rm -rf "$ROOT"
```

| Check | Expect |
|-------|--------|
| Per-plan file | `.cursor/gates/critique-gate/ACP-100` exists, line 1 = plan path |
| Legacy gone | `.cursor/critique-gate.pending` deleted |
| Other plan | Writing a gate for a different plan does **not** steal this migrated file |

---

## Scenario 3 — Foreign clear refused

With both `critique-gate/ACP-2656` and `critique-gate/ACP-2665` present (re-run Scenario 1 write steps):

| Check | Expect |
|-------|--------|
| Agent in 2656 chat | Never `rm` / overwrite `ACP-2665` |
| Human says “clear the other gate” | HITL **Force-clear foreign gate** (`force-clear` / `leave`) via `hitl-choice`; prompt names slug + plan path |
| `leave` | Foreign file unchanged |
| `force-clear` | Only after that token, delete the named slug |

---

## Cleanup

```bash
rm -rf /tmp/pg-dogfood /tmp/pg-dogfood-legacy
# If you used a real consumer: rm -rf .cursor/gates
# and any leftover .cursor/{plan-gate.pending,critique-gate.pending,plan-critique.clear,review-gate.pending,docs-gate.pending}
```
