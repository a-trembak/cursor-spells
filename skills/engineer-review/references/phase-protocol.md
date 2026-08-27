# Phase protocol

Every phase subagent follows this contract. Orchestrator merges JSON only — not raw transcripts.

## Inputs (provided by orchestrator)

- `BASE_SHA`, `HEAD_SHA` (or explicit file list / chunk file list)
- `stack`: `react-web` | `react-native` | `typescript` | `java-spring` | `mixed` | `unknown`
- `patterns_path`: usually `.cursor/project-patterns.md`
- `tech_spec_path`: optional; path to the diff's tech spec / AC trace if one exists (see Traceability check below)
- `clarifications`: map of prior answers (`C1` → text), may be empty
- `mode`: `find` (read-only findings) or `apply` (apply unambiguous fixes)
- `chunk_id`: optional string when the orchestrator split a large diff
- `graphify_available`: optional boolean — `true` when orchestrator detect/query succeeded ([graphify-protocol.md](graphify-protocol.md))
- `impact_hint`: optional compact module/path list from graphify impact (never raw `graph.json`)
- `learned_hints`: optional compact miss-class rows from `review-learn` `mode:load` ([review-learn-protocol.md](review-learn-protocol.md)) — **only** rows whose `phases` include this phase; never full ledgers. On match the phase **must** open `checklist` and run those gates (one-liner is not enough).

## Budget hard caps (per phase invocation)

| Cap | Default | Behavior |
|-----|---------|----------|
| Max files to deep-read | **40** | If diff touches more, orchestrator chunks by top-level package/dir and runs the phase per chunk |
| Max changed LOC (insertions+deletions) | **2500** | Same chunking rule |
| Max notes | **8** | Drop lowest-value residuals |
| Max clarify items | **12** per phase | Overflow → single clarify "batch remaining in Residual notes" |

### Catastrophic budget (abort before chunking)

Chunking alone cannot save a diff that is mostly noise or an entire tree. **Before** graphify / chunk dispatch, if either threshold is exceeded, **stop** and ask the user to narrow scope — do not spawn dozens/hundreds of phase runs:

| Cap | Default | Behavior |
|-----|---------|----------|
| Max files in review range | **200** | Abort with a short clarify: show file count + top path prefixes; ask for a path allowlist, path denylist, or a smaller `base..head` |
| Max changed LOC (insertions+deletions) | **50_000** | Same abort |

When aborting, suggest excluding typical noise (`node_modules/`, `dist/`, `build/`, lockfiles, generated clients, minified bundles, binary/assets) and re-running with an explicit file list or path filter. Do **not** silently sample a random 40-file subset.

Orchestrator computes `git diff --numstat` / file list **before** dispatch, applies the catastrophic check, then applies [graphify-protocol.md](graphify-protocol.md) when present (impact hint + smarter chunk boundaries). If graphify is absent/unqueryable, behavior is unchanged. Subagents must not silently expand into the whole repo.

## Severity

Every `fixed` and `clarify` item **must** include `severity`:

| Level | Meaning | Auto-apply eligible? |
|-------|---------|-----------------------|
| `P0` | Correctness bug, security hole, broken build, clear dead/dangerous code | Only if it also passes [`auto-fix-eligibility.md`](auto-fix-eligibility.md) |
| `P1` | Clear best-practice / pattern violation with low behavior risk | Only if it also passes [`auto-fix-eligibility.md`](auto-fix-eligibility.md) |
| `P2` | Nit / optional polish | **No** — Residual notes only (never silent apply) |

`unambiguous: true` on a `P0`/`P1` item is a phase agent's own signal that it believes the finding meets the [auto-fix eligibility test](auto-fix-eligibility.md) — severity classifies importance, the eligibility test is the separate, stricter gate for whether an apply is allowed at all.

Orchestrator apply pass: only `unambiguous: true` AND (`P0` OR `P1`) AND passing the eligibility test.

## Traceability check (patterns phase)

When `tech_spec_path` is provided (or a tech spec is discoverable under `docs/**/specs/` matching the diff's branch/task topic), the `patterns` phase additionally verifies the diff matches the spec's declared services/tables/seams. Any mismatch — missing what the spec calls for, or extra scope the spec doesn't mention — is always `clarify`, per [`auto-fix-eligibility.md`](auto-fix-eligibility.md): a spec/diff mismatch has two plausible explanations (the spec is stale, or the diff's scope drifted), so it structurally fails the eligibility test's "single correct answer" condition and can never be auto-applied.

## Process

1. Respect the file list / chunk from the orchestrator (do not widen scope).
2. Load mapped skill for this phase if available (see skill-map.md).
3. **Neighbors / call graph:** when `graphify_available` is true (or detect succeeds per [graphify-protocol.md](graphify-protocol.md)), prefer `graphify query` / short `GRAPH_REPORT.md` excerpts for callers, callees, and impact before walking path-adjacent files. When false or unqueryable, keep the phase’s existing diff-scoped / neighbor heuristics.
4. Review **changed code** against checklist; use patterns file for local conventions. When `learned_hints` is present, apply any hint whose `triggers` match the diff **before** closing related items (link `gate` / R# — do not ignore loaded learnings).
5. Classify each issue into `fixed` (candidate or applied) or `clarify`, with severity.
6. **Evidence (mandatory):** every `fixed`/`clarify` item that names a file **must** include `path`, `start_line`, `end_line`, `snippet` (exact 3–15 lines of the problem), and `context` (1–2 sentences). No path-only findings. See [evidence-gate.md](evidence-gate.md).
7. **Clarify choices (mandatory):** every `clarify` item **must** include structured `options` (`[{ "id", "label" }, …]`, 2–3 choices). Prefer `recommended` (option id) + `recommendation_why` for P0/P1 — safest / closest to patterns or AC. Use `recommended: null` only when product intent is genuinely unknown; never invent a fake recommendation.
8. Return **only** the JSON summary below.

## Phase order

`lint` runs **first**, before every heuristic phase, and does not depend on `patterns` or a stack skill — it just executes the project's own linter/typechecker/build. Its findings are deterministic (a tool said so, not an LLM guess), so they are cheap to trust and apply. Heuristic phases (`patterns`, `deadcode`, `simplify`, `logic`, `architecture`, `performance`, `security`, `figma`) run after, in parallel for `find`.

**Apply-conflict order** when phases touch the same lines: `lint → patterns → deadcode → simplify → logic → architecture → performance → security → figma`.

`simplify` sits after `deadcode` so unused junk is owned by deadcode first; simplify then challenges overbuilt / redundant / locally wasteful code that still runs. It does not steal hot-path systemic perf (`performance`) or layering (`architecture`).

**Verify passes:** after the orchestrator applies unambiguous `P0`/`P1` fixes across all phases:
1. Re-run `review-lint` once in `find` mode over the final diff (lint regressions, e.g. unused import left by a deadcode removal).
2. Re-run `review-simplify` once in `find` mode as a **quality verify** (leftover overbuilt / redundant / locally wasteful solutions).

Fold any new findings into the same apply/clarify pass; do not repeat either verify pass more than once per review round.

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

## Orchestrator merge

- **Fixed now**: `fixed` where `applied: true` (P0/P1 only)
- **Needs clarification**: all `clarify` (renumber ids globally to `C1…`)
- **Residual notes**: phase `notes` + any `P2` candidates
- Coverage lists phases, chunks, skips, and `graphify: used|absent|unqueryable`
- When auth/session **or** interactive overlay/filter is in scope: Coverage **must** note `interaction_replay: auth|overlay-focus|both|skipped|n/a` (**R7**). Optional: `auth_flow_walk: …` for concrete auth flows walked.
- When the figma phase is in scope (frontend, not `user_said_no_figma`): Coverage **must** note `figma_markup: compared|source-only|skipped|n/a` (**F7**). Optional: `figma_nodes: …`. Detail: [`figma-markup-checklist.md`](figma-markup-checklist.md).
- When tables, expandable cards, dialogs, or overlays are in scope: Coverage **must** note `narrow_viewport: tablet+phone|source-only|skipped|n/a` (**V4**). Figma skip does not waive this — `review-patterns` still records it. Detail: [`responsive-layout-checklist.md`](responsive-layout-checklist.md).
- Coverage notes `review_learnings: loaded N|absent` and, after the learn step, `review_learn: appended|deduped|skipped|n/a`.

## Post-clarify re-sim (R1 — timing / listeners / host remount)

After HITL clarify answers that change **when** something runs (cache reset sync vs defer, listener effects, auth matchers, remount/`key=`, overlay autofocus / Menu props):

1. Re-dispatch **logic** and **architecture** (not only the phase that asked) with the answers embedded.
2. Require an explicit `interaction_replay` brief in phase notes (or a competing-actor regression in the tree) per **R1**:

   `trigger → route/shell still mounted → active subscriptions / host widgets → shared writers (auth, focus, selection) → user-visible outcome`

3. Do **not** treat the clarify answer as applied until that replay is recorded in phase notes **or** a matching competing-actor regression exists (**R6**).
4. Detail: `skills/engineer-review/references/interaction-replay-checklist.md` (auth specialization: `auth-rtk-checklist.md`).

Example miss class: picking sync `resetApiState` without re-simulating live shell subscribers that still hold a probe query (fulfill writes auth); or accepting filter-in-menu without checking whether the host steals focus on each filtered re-render.
