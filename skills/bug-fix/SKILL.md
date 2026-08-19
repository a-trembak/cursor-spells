---
name: bug-fix
description: >-
  Use when fixing a bug from a Jira/issue ticket or a cleared fix plan: find
  root cause before changing code, apply a minimal fix with a regression test,
  then verify. Use from /start-issue-task after implementation-critic Verdict
  clear, or when asked to fix a diagnosed bug. Not for feature work (use
  software-developer).
---

# Bug Fix

Implements a **minimal, root-cause fix** from a critiqued-clear fix plan (or an equivalent diagnosed bug brief). Diagnosis-first; no shotgun patches.

## When to Use

- `/start-issue-task` after `implementation-critic` yields `Verdict: clear`
- Human asks to implement an already-cleared bug-fix plan
- Not for greenfield features (`software-developer`) and not for writing/critiquing the plan itself

## Entry conditions

1. Fix plan exists (typically `docs/superpowers/plans/YYYY-MM-DD-<jira-key>-fix.md`) **or** the caller passed an equivalent root-cause brief with reproduction steps.
2. For `/start-issue-task`: `.cursor/gates/plan-critique-clear/<slug>` matches that plan path (critic `Verdict: clear`).
3. Ticket / bug description is available (Jira fields already fetched by the orchestrator, or pasted text).

If a gate is missing: **stop** and name it. Do not code.

## Skill routing (required)

Load when available; note `skill_missing: <id>` and continue on built-in discipline — do not block the run, do not auto-install Tier-2 skills:

| Skill | Role |
|-------|------|
| `systematic-debugging` | No fix without root-cause investigation |
| `ce-debug` with `mode:pipeline` | Non-interactive diagnosis loop when installed |
| `verification-before-completion` | Evidence before claiming done |
| `code-comments` | Keep/Remove taxonomy; English-only comments |
| skill-map stack (+ DB rows if migrations) | Same mechanical lookup as `software-developer` |
| `tdd` / project test conventions | Failing test that proves the bug **before** the fix |

## Spine

1. **Branch setup** — follow `skills/software-developer/references/branch-setup.md`. Prefer `fix/<jira-key>-<short-topic>` when a ticket id exists.
2. **Reproduce** — confirm the failure (test, script, or documented steps). If unreproducible: stop and report; do not guess a fix.
3. **Root cause** — complete systematic-debugging / `ce-debug mode:pipeline` until the causal chain has no gaps. Do not propose a patch before this.
4. **Regression test first** — add or extend a test that fails for the bug and would pass after the fix (project conventions; `tdd` if installed).
5. **Minimal fix** — change only what the root cause requires. No “while I’m here” refactors.
6. **Verify** — run the new/updated test plus relevant project lint/test/typecheck (`verification-before-completion`). Keep evidence.
7. **Handoff** — return `next_skill: engineer-reviewer`, `repo → branch` map, root-cause summary (1–3 sentences), verification evidence, and any `skill_missing` notes. **nested Task:** stop after that block (no `AskQuestion` / `engineer-reviewer` from the Task). Callers **Wait for** the return then run `engineer-reviewer` then `create-pr` (do not skip those for `/start-issue-task`).
8. **Review-learn on escapes** — if this defect was a **production escape** (or the plan states prior review should have caught it), after the fix is verified invoke agent `review-learn` with `source: production-escape` per `skills/engineer-review/references/review-learn-protocol.md` so the miss class strengthens future reviews. Do not block the fix handoff on HITL promote.

## Hard rules

- Never expand scope beyond the fix plan / diagnosed bug.
- Never ship a symptom-only patch when the root cause is known and in-repo.
- If Jira/MCP facts conflict with repo evidence: **stop and ask** (HITL via `hitl-choice` when a closed choice exists).
- Never implement on `main` / `master` / the default branch.
- Source-code comments: English only; apply `code-comments`.

## Output

Working tree changes on the feature branch, failing-then-passing regression coverage, verification evidence, and the handoff fields above.
