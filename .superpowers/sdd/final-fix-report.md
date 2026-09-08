# Final whole-branch review fixes

Branch: `cursor/propose-commit-gate-c095`  
Date: 2026-09-08

## Important (fixed)

1. **`skills/create-pr/SKILL.md`** — Pre-push pipeline guard now requires `pg__find_gate_for_plan` for `commit-approved` (via `pipeline-gates.sh`); stops when commits were needed but marker missing; clears with `pg_clear_gate` after successful push or confirmed up-to-date branch. Hard rules updated.

2. **`skills/propose-commit/SKILL.md`** — On `approve-commit`, stages only approved paths (`git restore --staged` for extras); verifies `git diff --cached --name-only` exactly matches approved list before `git commit`; re-proposes on mismatch.

3. **`skills/update-docs/SKILL.md` + `references/writing-guide.md`** — `docs_repo` leaves files uncommitted; no commit or PR from update-docs; docs repo included in `repo_branch_map` for residual `propose-commit`. Writing guide no longer says open PR / leave committed branch.

## Mandatory minors (fixed)

4. **`skills/finish-plan/references/review-surface.md`** — HITL gate text: steps 1–2b (was 1–2).

5. **`README.md`** — Skills table: `create-pr` described as push + draft (not commit/push).

6. **`skills/bug-fix/SKILL.md`** — Handoff chain: engineer-reviewer → propose-commit → create-pr.

## Tests

Updated `scripts/tests/propose-commit-test.sh` greps for `pg__find_gate_for_plan`, `pg_clear_gate` + `commit-approved`, staged-file match, and docs_repo uncommitted gate.

```
bash scripts/tests/propose-commit-test.sh       — ALL PASS
bash scripts/tests/pipeline-flow-graph-test.sh  — ALL PASS
bash scripts/tests/pipeline-gates-test.sh       — ALL PASS
bash scripts/tests/review-surface-test.sh       — ALL PASS
```

## Deferred (optional)

- Mermaid residual labels / section 11 standalone chart — not changed.
