# Phase protocol

Every phase subagent follows this contract. Orchestrator merges JSON only — not raw transcripts.

## Inputs (provided by orchestrator)

- `BASE_SHA`, `HEAD_SHA` (or explicit file list / chunk file list)
- `stack`: `react-web` | `react-native` | `typescript` | `java-spring` | `mixed` | `unknown`
- `patterns_path`: usually `.cursor/project-patterns.md`
- `clarifications`: map of prior answers (`C1` → text), may be empty
- `mode`: `find` (read-only findings) or `apply` (apply unambiguous fixes)
- `chunk_id`: optional string when the orchestrator split a large diff

## Budget hard caps (per phase invocation)

| Cap | Default | Behavior |
|-----|---------|----------|
| Max files to deep-read | **40** | If diff touches more, orchestrator chunks by top-level package/dir and runs the phase per chunk |
| Max changed LOC (insertions+deletions) | **2500** | Same chunking rule |
| Max notes | **8** | Drop lowest-value residuals |
| Max clarify items | **12** per phase | Overflow → single clarify “batch remaining in Residual notes” |

Orchestrator computes `git diff --numstat` / file list **before** dispatch. Subagents must not silently expand into the whole repo.

## Severity

Every `fixed` and `clarify` item **must** include `severity`:

| Level | Meaning | Auto-apply when `unambiguous: true`? |
|-------|---------|--------------------------------------|
| `P0` | Correctness bug, security hole, broken build, clear dead/dangerous code | **Yes** in apply mode |
| `P1` | Clear best-practice / pattern violation with low behavior risk | **Yes** in apply mode |
| `P2` | Nit / optional polish | **No** — Residual notes only (never silent apply) |

Orchestrator apply pass: only `unambiguous: true` AND (`P0` OR `P1`).

## Process

1. Respect the file list / chunk from the orchestrator (do not widen scope).
2. Load mapped skill for this phase if available (see skill-map.md).
3. Review **changed code** against checklist; use patterns file for local conventions.
4. Classify each issue into `fixed` (candidate or applied) or `clarify`, with severity.
5. Return **only** the JSON summary below.

## Phase order

`lint` runs **first**, before every heuristic phase, and does not depend on `patterns` or a stack skill — it just executes the project's own linter/typechecker/build. Its findings are deterministic (a tool said so, not an LLM guess), so they are cheap to trust and apply. Heuristic phases (`patterns`, `deadcode`, `logic`, `architecture`, `performance`, `security`, `figma`) run after, in parallel for `find`.

**Apply-conflict order** when phases touch the same lines: `lint → patterns → deadcode → logic → architecture → performance → security → figma`.

**Verify pass:** after the orchestrator applies unambiguous `P0`/`P1` fixes across all phases, re-run `review-lint` once more in `find` mode over the final diff. This catches lint regressions introduced by another phase's fix (e.g. a `deadcode` removal that leaves a now-unused import). Fold any new `lint` findings into the same apply/clarify pass; do not repeat the verify pass more than once per review round.

## Apply rules

- In `find` mode: never mutate the tree; set `"applied": false` on candidates.
- Preferred kit default: parallel `find`, then one `apply` for `unambiguous && (P0|P1)`.
- Never apply clarify-class or `P2` items.
- `lint`'s apply step must only use the tool's own auto-fixer (e.g. `eslint --fix`) — never a hand-written edit to satisfy a lint rule.

## JSON summary schema

```json
{
  "phase": "lint|logic|patterns|deadcode|architecture|performance|security|figma",
  "status": "ok|partial|failed",
  "skipped": false,
  "skip_reason": null,
  "chunk_id": null,
  "fixed": [
    {
      "path": "src/foo.ts",
      "summary": "Removed unused import",
      "severity": "P1",
      "unambiguous": true,
      "applied": true
    }
  ],
  "clarify": [
    {
      "id": "C1",
      "question": "Should X use existing helper Y?",
      "options": ["Use Y", "Keep new helper", "Need more context"],
      "path": "src/foo.ts",
      "severity": "P1"
    }
  ],
  "notes": ["optional short residual / P2 nits"]
}
```

## Skip conditions

- `lint`: no resolvable lint/typecheck config for the detected stack → `skipped: true` with reason `no_lint_config`; tool not runnable in this environment → `skipped: true` with reason `tooling_unavailable` (note in Coverage — humans should know automated lint did not run)
- `security`: no sensitive surface in diff → `skipped: true`
- `figma`: not frontend, or no Figma URLs yet → `skipped: true` with reason `awaiting_figma_urls` or `not_frontend` or `user_said_no_figma`
- `patterns` first run: may create patterns file; that is not a skip

## Orchestrator merge

- **Fixed now**: `fixed` where `applied: true` (P0/P1 only)
- **Needs clarification**: all `clarify` (renumber ids globally to `C1…`)
- **Residual notes**: phase `notes` + any `P2` candidates
- Coverage lists phases, chunks, skips
