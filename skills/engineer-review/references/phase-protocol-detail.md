# Phase protocol — phase detail

Phase-owned: JSON schema, process steps, apply detail, and skip conditions. Orchestrator loads [`phase-protocol.md`](phase-protocol.md) only (inputs, caps, order, merge, Coverage). Phases **must** load this file with the orch protocol.

## Severity (phases)

Every `fixed` and `clarify` item **must** include `severity`:

| Level | Meaning | Auto-apply eligible? |
|-------|---------|-----------------------|
| `P0` | Correctness bug, security hole, broken build, clear dead/dangerous code | Only if it also passes [`auto-fix-eligibility.md`](auto-fix-eligibility.md) |
| `P1` | Clear best-practice / pattern violation with low behavior risk | Only if it also passes [`auto-fix-eligibility.md`](auto-fix-eligibility.md) |
| `P2` | Nit / optional polish | **No** — Residual notes only (never silent apply) |

`unambiguous: true` on a `P0`/`P1` item is a phase agent's own signal that it believes the finding meets the [auto-fix eligibility test](auto-fix-eligibility.md) — severity classifies importance; eligibility is the separate, stricter gate for whether an apply is allowed at all.

## Traceability check (patterns phase)

When `tech_spec_path` is provided (or a tech spec is discoverable under `docs/**/specs/` matching the diff's branch/task topic), the `patterns` phase additionally verifies the diff matches the spec's declared services/tables/seams. Any mismatch — missing what the spec calls for, or extra scope the spec doesn't mention — is always `clarify`, per [`auto-fix-eligibility.md`](auto-fix-eligibility.md): a spec/diff mismatch has two plausible explanations (the spec is stale, or the diff's scope drifted), so it structurally fails the eligibility test's "single correct answer" condition and can never be auto-applied.

## Process

1. Respect the file list / chunk from the orchestrator (do not widen scope).
2. Load mapped skill for this phase if available (see [`skill-map.md`](skill-map.md)).
3. **Neighbors / call graph:** when `graphify_available` is true (or detect succeeds per [graphify-protocol.md](graphify-protocol.md)), prefer `graphify query` / short `GRAPH_REPORT.md` excerpts for callers, callees, and impact before walking path-adjacent files. When false or unqueryable, keep the phase’s existing diff-scoped / neighbor heuristics. When auth/session or overlay hosts are in scope, also apply [graphify-r3-force-include.md](graphify-r3-force-include.md).
4. Review **changed code** against checklist; use patterns file for local conventions. When `learned_hints` is present, apply any hint whose `triggers` match the diff **before** closing related items (link `gate` / R# — do not ignore loaded learnings). On match **open** the linked checklist body and run those gates.
5. Classify each issue into `fixed` (candidate or applied) or `clarify`, with severity.
6. **Evidence (mandatory):** every `fixed`/`clarify` item that names a file **must** include `path`, `start_line`, `end_line`, `snippet` (exact 3–15 lines of the problem), and `context` (1–2 sentences). No path-only findings. See [evidence-gate.md](evidence-gate.md) (orchestrator runs the gate at merge).
7. **Clarify choices (mandatory):** every `clarify` item **must** include structured `options` (`[{ "id", "label" }, …]`, 2–3 choices). Prefer `recommended` (option id) + `recommendation_why` for P0/P1 — safest / closest to patterns or AC. Use `recommended: null` only when product intent is genuinely unknown; never invent a fake recommendation.
8. Return **only** the JSON summary below.

## Apply rules

- In `find` mode: never mutate the tree; set `"applied": false` on candidates.
- Preferred kit default: parallel `find`, then one `apply` for `unambiguous && (P0|P1)` that also passes [`auto-fix-eligibility.md`](auto-fix-eligibility.md).
- Never apply clarify-class or `P2` items.
- `lint`'s apply step must only use the tool's own auto-fixer (e.g. `eslint --fix`) — never a hand-written edit to satisfy a lint rule.

## JSON summary schema

```json
{
  "phase": "lint|logic|patterns|deadcode|simplify|architecture|performance|security|figma",
  "status": "ok|partial|failed",
  "skipped": false,
  "skip_reason": null,
  "chunk_id": null,
  "fixed": [
    {
      "path": "src/foo.ts",
      "start_line": 18,
      "end_line": 24,
      "snippet": "  const x = await load();\n  return x.value;\n",
      "context": "load() fetches the current session user before reading .value.",
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
      "context": "New load path duplicates existing user fetch used by the auth middleware.",
      "options": [
        { "id": "A", "label": "Use existing helper Y" },
        { "id": "B", "label": "Keep the new helper" },
        { "id": "C", "label": "Need more product context" }
      ],
      "recommended": "A",
      "recommendation_why": "Matches patterns Do not reinvent; same semantics as Y.",
      "path": "src/foo.ts",
      "start_line": 40,
      "end_line": 48,
      "snippet": "  // exact lines the question is about\n",
      "severity": "P1"
    }
  ],
  "notes": ["optional short residual / P2 nits — if a nit points at a file, still include path+lines+snippet in a clarify/fixed item instead"]
}
```

**Required** on every `fixed`/`clarify` with code: `path`, `start_line`, `end_line`, `snippet`, `context`. **Required** on every `clarify`: `options` (id+label objects). Prefer `recommended` + `recommendation_why`; `recommended` may be `null`. Orchestrators must run the [evidence gate](evidence-gate.md) before user-facing output — backfill via `scripts/extract-review-snippet.sh` or drop the item. Never emit a bare `path: summary` line. Legacy string-array `options` must be normalized to `{ id, label }` (A/B/C…) before emit.

## Skip conditions

- `lint`: no resolvable lint/typecheck config for the detected stack → `skipped: true` with reason `no_lint_config`; tool not runnable in this environment → `skipped: true` with reason `tooling_unavailable` (note in Coverage — humans should know automated lint did not run)
- `security`: no sensitive surface in diff → `skipped: true`
- `figma`: not frontend, or no Figma URLs yet → `skipped: true` with reason `awaiting_figma_urls` or `not_frontend` or `user_said_no_figma`. Skip does **not** waive **V1–V4**; `patterns` still runs them on frontend.
- `patterns` first run: may create patterns file; that is not a skip
