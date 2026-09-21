---
name: local-verify
description: >-
  Use after propose-commit (and full-path update-docs / residual propose) in a
  kit pipeline, immediately before create-pr. Reads consumer
  .cursor/spells-local-verify.yaml, starts only declared services, health-checks,
  writes local-verify gate. Default skip when no contract. Never invents up
  commands. Also use via /csp-local-verify for a manual run.
---

# Local Verify

Optional post-commit stack bring-up before opening a draft pull request.
Implements `docs/superpowers/specs/2026-09-21-local-verify-design.md`.

## When to Use

- On a **pipeline** run (full / `--fast` / issue) after `propose-commit` (and after `update-docs` + residual `propose-commit` on the full path), **immediately before** `create-pr`
- Manual `/csp-local-verify` when the human asks to verify the local stack outside the automatic wire
- Not as a substitute for engineer-review lint
- Not from `finish-plan` review-surface
- Manual `/csp-engineer-review` does **not** auto-start this skill

## Preconditions

All required for a pipeline handoff:

1. Feature branch checked out in each target repo (not default).
2. Product commits for this run already handled via `propose-commit` when commits were needed (or tree intentionally clean).
3. `repo → branch` map (or resolvable current feature branch).
4. `plan_path` when known; if `plan_path: none`, use synthetic `runs/<feature-branch-name>` for the gate slug.

If a precondition fails on a pipeline run: **stop** and say which one. Do not invent services.

## Consumer adoption

Product repositories opt in by copying the example contract and editing services:

1. Copy `skills/local-verify/references/example-spells-local-verify.yaml` to `.cursor/spells-local-verify.yaml` in the **product** repo root.
2. Set `enabled: true`, adjust `blocking`, `timeout_sec`, `secrets.files`, and each `services[]` `up` / `health`.
3. Do **not** enable a verify contract at the cursor-spells kit root (the kit has no application stack).

## Spine

1. **Find contract** — in the consumer project root (or each changed repo in the map): `.cursor/spells-local-verify.yaml`. Multi-repo: one contract per repo; aggregate the report.
2. **Classify skip** (write gate + continue to `create-pr` unless noted):
   - Missing / unreadable → `skip` / `no_contract`
   - `enabled: false` → `skip` / `disabled`
   - All services `kind: noop` or explicit stack-noop → `skip` / `stack_noop`
3. **Secrets (paths only)** — if `secrets.files` lists paths:
   - `mode: skip_if_missing` and a file is absent → treat as skip for that concern or continue per contract (do not print file contents)
   - `mode: required` and a file is absent → `fail` or `skip` with `secrets_missing` (prefer fail when `blocking: true`; otherwise report and continue per blocking rules)
   - **Never** print secret values in chat. **Never** commit secret values into the kit.
4. **Runtime** — for each **declared** `kind` only (`compose` → Docker; `npm` / `node` → Node). Missing runtime → `skip` / `runtime_unavailable` (or fail only if the contract/`blocking` requires stopping). Do **not** probe runtimes for kinds not listed.
5. **Per service** (skip `noop`):
   - **Health-first:** if health is already green, do **not** run `up` and do not kill the process.
   - Else run **exactly** the `up` argv array with `cwd` (no shell string invention, no `package.json` / Compose heuristics).
   - Wait until health passes or `timeout_sec` elapses.
6. **Write gate** in the current project (consumer root):

   ```bash
   source scripts/pipeline-gates.sh   # consumer copy or kit path
   # Marker path: .cursor/gates/local-verify/<slug>
   # File body: plan path on line 1; then status=pass|fail|skip and reason=<code>
   pg_write_gate "$(pwd)" local-verify "<plan-path-or-runs-branch>"
   ```

   Append or ensure the marker records `status` and `reason` (`pass` / `fail` / `skip` + code from `references/skip-fail-codes.md`).
7. **Blocking HITL** — if overall result is fail and contract `blocking: true`: ask via skill **`hitl-choice`** preset **Local verify blocking fail** (`fix` / `skip_verify` / `retry`).
   - `fix` — stop; human remediates; do not open the pull request yet.
   - `skip_verify` — continue to `create-pr` with fail recorded.
   - `retry` — re-run spine from step 5 (or from find contract if secrets/runtime changed).
   - If `blocking: false` (default): report fail, still hand off to `create-pr`.
8. On pass or non-blocking fail or skip: **`next_skill: create-pr`**. Do **not** push. Do **not** open or merge a GitHub pull request.

## Hard rules

- Never invent `up` from `package.json`, Compose discovery, README, or “usual” scripts.
- Never merge this stage into engineer-review lint or heuristic phases.
- Never print secret **values** in chat or store them in kit git.
- Never kill already-healthy services “just in case”.
- Never `gh pr create` / `gh pr merge` / `git push` from this skill.
- Default skip when no contract; block the pipeline only when `blocking: true` and verify failed (until HITL).

## Output

```
next_skill: create-pr
plan_path: <path>
repo_branch_map:
  - <repo> → <branch>
local_verify: pass | fail | skip
reason: <code>
blocking_applied: true | false
```
