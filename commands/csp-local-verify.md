---
description: Optional local stack verify from consumer contract (before create-pr)
argument-hint: "[plan-path]"
---

# /csp-local-verify

Run skill **`local-verify`** (`skills/local-verify/SKILL.md`).

## Arguments

- Optional plan path (or recover from handoff / synthetic `runs/<feature-branch-name>`).

## Steps

1. Read and follow skill `local-verify`.
2. Invoke agent `csp-local-verify` with the `repo → branch` map when known.
3. Report `local_verify` status + reason; on pipeline handoff set `next_skill: create-pr` (unless blocking fail and human chose `fix`).

## Notes

- Without `.cursor/spells-local-verify.yaml` → skip `no_contract` and continue.
- Never invent start commands from `package.json` or Compose heuristics.
- Manual use does not replace engineer-review; pipeline wiring places this stage immediately before `create-pr`.
