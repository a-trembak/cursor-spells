# Phase protocol

Every phase subagent follows this contract. Orchestrator merges JSON only — not raw transcripts.

**Load routing:** orchestrator keeps this file (inputs / caps / order / merge / Coverage). Phases also load [`phase-protocol-detail.md`](phase-protocol-detail.md) for process, apply rules, JSON schema, and skip conditions.

## Inputs (provided by orchestrator)

- `BASE_SHA`, `HEAD_SHA` (or explicit file list / chunk file list)
- `stack`: `react-web` | `react-native` | `typescript` | `java-spring` | `mixed` | `unknown`
- `patterns_path`: usually `.cursor/project-patterns.md`
- `tech_spec_path`: optional; path to the diff's tech spec / AC trace if one exists
- `clarifications`: map of prior answers (`C1` → text), may be empty
- `mode`: `find` (read-only findings) or `apply` (apply unambiguous fixes)
- `chunk_id`: optional string when the orchestrator split a large diff
- `graphify_available`: optional boolean — `true` when orchestrator detect/query succeeded ([graphify-protocol.md](graphify-protocol.md))
- `impact_hint`: optional compact module/path list from graphify impact (never raw `graph.json`)
- `learned_hints`: optional compact miss-class rows from `csp-review-learn` `mode:load` ([review-learn-protocol.md](review-learn-protocol.md)) — **only** rows whose `phases` include this phase; never full ledgers. On match the phase **must** open `checklist` and run those gates (one-liner is not enough).

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

Orchestrator apply pass: only `unambiguous: true` AND (`P0` OR `P1`) AND passing [`auto-fix-eligibility.md`](auto-fix-eligibility.md). Severity meanings live in [`phase-protocol-detail.md`](phase-protocol-detail.md).

## Phase order

`lint` runs **first**, before every heuristic phase, and does not depend on `patterns` or a stack skill — it just executes the project's own linter/typechecker/build. Its findings are deterministic (a tool said so, not an LLM guess), so they are cheap to trust and apply. Heuristic phases (`patterns`, `deadcode`, `simplify`, `logic`, `architecture`, `performance`, `security`, `figma`) run after, in parallel for `find`.

**Apply-conflict order** when phases touch the same lines: `lint → patterns → deadcode → simplify → logic → architecture → performance → security → figma`.

`simplify` sits after `deadcode` so unused junk is owned by deadcode first; simplify then challenges overbuilt / redundant / locally wasteful code that still runs. It does not steal hot-path systemic perf (`performance`) or layering (`architecture`).

**Verify passes:** after the orchestrator applies unambiguous `P0`/`P1` fixes across all phases:
1. Re-run `csp-review-lint` once in `find` mode over the final diff (lint regressions, e.g. unused import left by a deadcode removal).
2. Re-run `csp-review-simplify` once in `find` mode as a **quality verify** (leftover overbuilt / redundant / locally wasteful solutions).

Fold any new findings into the same apply/clarify pass; do not repeat either verify pass more than once per review round.

## Orchestrator merge

- **Fixed now**: `fixed` where `applied: true` (P0/P1 only)
- **Needs clarification**: all `clarify` (renumber ids globally to `C1…`)
- Copy each clarify item’s `context`, `what`, `when_shows`, `question`, `snippet`, `options`, and `recommendation_why` **verbatim** into the report and into each sequential clarify question. Do not re-summarize, drop fields, or replace a full finding with “C1 needs a choice”. Incomplete phase JSON (missing snippet / context / question / when_shows / options) → backfill or **drop**; never invent a letter-only ask.
- **Residual notes**: phase `notes` + any `P2` candidates
- Coverage lists phases, chunks, skips, and `graphify: used|absent|unqueryable`
- When auth/session **or** interactive overlay/filter is in scope: Coverage **must** note `interaction_replay: auth|overlay-focus|both|skipped|n/a` (**R7**). Optional: `auth_flow_walk: …` for concrete auth flows walked.
- When the figma phase is in scope (frontend, not `user_said_no_figma`): Coverage **must** note `figma_markup: compared|source-only|skipped|n/a` (**F7**). Optional: `figma_nodes: …`. Detail: [`figma-markup-checklist.md`](figma-markup-checklist.md) (phase-owned — orchestrator does not load the body).
- When tables, expandable cards, dialogs, or overlays are in scope: Coverage **must** note `narrow_viewport: tablet+phone|source-only|skipped|n/a` (**V4**). Figma skip does not waive this — `csp-review-patterns` still records it. Detail: [`responsive-layout-checklist.md`](responsive-layout-checklist.md) (phase-owned).
- When null-hardening triggers apply: Coverage **must** note `null_safety_callers: traced|partial|skipped|n/a` (**N1**) from logic/architecture notes.
- When repository / result-type triggers apply: Coverage **must** note `jpa_result_type: matched|mismatched|skipped|n/a` (**RT1**) from logic notes. Detail: [`jpa-repository-result-checklist.md`](jpa-repository-result-checklist.md) (phase-owned — orchestrator does not load the body).
- Coverage notes `review_learnings: loaded N|absent` and, after the learn step, `review_learn: appended|deduped|skipped|n/a`.

At merge/report time only, load [`evidence-gate.md`](evidence-gate.md) + [`feedback-format.md`](feedback-format.md) + [`forbidden-formats.md`](forbidden-formats.md); never *emit* formats banned by [`forbidden-formats.md`](forbidden-formats.md). Abort/skip without a report does not load that pack.

## Post-clarify re-sim (R1 — timing / listeners / host remount)

After HITL clarify answers that change **when** something runs (cache reset sync vs defer, listener effects, auth matchers, remount/`key=`, overlay autofocus / Menu props):

1. Re-dispatch **logic** and **architecture** (not only the phase that asked) with the answers embedded.
2. Require an explicit `interaction_replay` brief in phase notes (or a competing-actor regression in the tree) per **R1** — phases open [`interaction-replay-checklist.md`](interaction-replay-checklist.md) (auth: [`auth-rtk-checklist.md`](auth-rtk-checklist.md)); orchestrator does **not** load those bodies.
3. Do **not** treat the clarify answer as applied until that replay is recorded in phase notes **or** a matching competing-actor regression exists (**R6**).

Example miss class: picking sync `resetApiState` without re-simulating live shell subscribers that still hold a probe query (fulfill writes auth); or accepting filter-in-menu without checking whether the host steals focus on each filtered re-render.
