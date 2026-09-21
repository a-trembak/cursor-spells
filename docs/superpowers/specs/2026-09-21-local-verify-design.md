# Local verify before create-pr

## Status

`approved` — human approved the implementation plan; this design is normative for the kit.

## Goal

After product commits (and full-path docs residual), optionally **raise and health-check** local services declared by the consumer repository, then hand off to `create-pr`. The kit **never invents** start commands from `package.json`, Compose files, or other heuristics.

## Problem

Draft pull requests open without proving the consumer stack can start on the agent machine. Inventing `docker compose` / `npm run` from manifests is brittle and unsafe. Embeding stack bring-up inside engineer-review lint mixes code-quality review with machine-local runtime.

## Decisions

| Decision | Choice |
|----------|--------|
| Contract file | Consumer `.cursor/spells-local-verify.yaml` (schema version 1) |
| Who knows what to start | **Only** the consumer contract (`up` argv arrays) |
| Who knows when to run | Kit pipeline — skill **`local-verify`** |
| Invent up from manifests | **Forbidden** |
| Merge into engineer-review lint | **Forbidden** |
| Default when no contract | **Skip** (`no_contract`); continue to `create-pr` |
| Blocking | Only when contract `blocking: true` (default `false`) |
| Pipeline placement | After `propose-commit` (+ `update-docs` / residual propose on full path), **immediately before** `create-pr` |
| Manual `/csp-engineer-review` | Does **not** auto-start `local-verify` |
| Secrets in chat | **Forbidden** — paths only; never values |
| Gate marker | `.cursor/gates/local-verify/<slug>` with status `pass` \| `fail` \| `skip` + reason |

## Contract schema (version 1)

File: `.cursor/spells-local-verify.yaml` at the consumer (or per-repo) root.

| Field | Type | Notes |
|-------|------|-------|
| `version` | number | Must be `1` |
| `enabled` | boolean | `false` → skip with `disabled` |
| `blocking` | boolean | Default **`false`**. When `true`, health fail stops until human HITL |
| `timeout_sec` | number | Max wait for health after `up` |
| `secrets.mode` | string | `skip_if_missing` \| `required` |
| `secrets.files` | string[] | **Paths only** (never secret values) |
| `services[]` | array | Declared services |
| `services[].id` | string | Stable id for reports |
| `services[].kind` | string | `compose` \| `npm` \| `node` \| `custom` \| `noop` |
| `services[].cwd` | string | Working directory relative to repo root |
| `services[].up` | string[] | Exact argv to run when health is not already green |
| `services[].health` | object | `http` \| `tcp` \| `command` (see skill references) |

`kind: noop` (or an explicit stack-noop signal in the contract) → skip with `stack_noop`; do not start processes.

Normative field detail: `skills/local-verify/references/contract-schema.md`.

## Skip / fail reason codes

| Code | Meaning |
|------|---------|
| `no_contract` | No `.cursor/spells-local-verify.yaml` (or unreadable) |
| `disabled` | Contract present with `enabled: false` |
| `stack_noop` | Declared noop / React Native-style no local services |
| `runtime_unavailable` | Required runtime for a declared `kind` missing (Docker / Node) |
| `secrets_missing` | `secrets.mode: required` and a listed file is absent |
| `fail` | Health check failed (after `up` and wait) |
| `pass` | All required services healthy |

Gate status maps: skip reasons → marker `skip` + reason; health failure → `fail`; success → `pass`.

## Pipeline placement (normative)

### Full path

1. … engineer-review settled + teach-review miss handled
2. `propose-commit`
3. `update-docs` (+ residual `propose-commit` if dirty)
4. **`local-verify`**
5. `create-pr`

### Fast / issue

1. … engineer-review settled + teach-review miss handled
2. `propose-commit`
3. **`local-verify`**
4. `create-pr`

### Manual

`/csp-engineer-review` does **not** auto-start `propose-commit`, `local-verify`, or `create-pr` unless the human asks. Slash `/csp-local-verify` runs the skill alone.

## Skill `local-verify` (normative)

### Spine (summary)

1. Find contract in consumer root (or each changed repo).
2. Classify skip (`no_contract` / `disabled` / `stack_noop` / …).
3. Check runtime **only** for declared `kind`s.
4. Per service: health-first; if already green, skip `up`; else run exact `up`; wait health to `timeout_sec`.
5. Write `.cursor/gates/local-verify/<slug>` (`pass` \| `fail` \| `skip` + reason).
6. If `blocking: true` and fail → HITL `fix` / `skip_verify` / `retry`.
7. Else `next_skill: create-pr`.

### Forbidden

- Inventing `up` from `package.json`, Compose discovery, or README heuristics
- Merging this stage into engineer-review lint / heuristic phases
- Printing secret **values** in chat or committing them into the kit
- Killing already-healthy services “just in case”

## Artifacts (expected)

| Path | Role |
|------|------|
| `skills/local-verify/SKILL.md` | Spine + hard rules |
| `skills/local-verify/references/*` | Schema, codes, example YAML |
| `agents/csp-local-verify.md` | Thin pointer |
| `commands/csp-local-verify.md` | Slash entry |
| `skills/hitl-choice/SKILL.md` | Preset **Local verify blocking fail** |
| Engineer-review step 15 + flow / README | Wire before `create-pr` |
| `scripts/tests/local-verify-contract-test.sh` | Grep contracts |
| Gate dir | `.cursor/gates/local-verify/<slug>` |

## Out of scope

- Browser / computer-use interactive smoke (separate, later)
- Kit-root enabled contract that starts services for the kit itself (kit has no app stack)
- Hardcoding product service names in the kit
- Changing Pipeline finale tokens or merge policy

## Success criteria

- Full / fast / issue pipelines invoke `local-verify` immediately before `create-pr`.
- Missing contract → skip `no_contract` and continue.
- Blocking fail asks HITL; non-blocking fail still continues to `create-pr`.
- Contract test asserts skill/agent/command, wiring, forbid invent, example YAML.
