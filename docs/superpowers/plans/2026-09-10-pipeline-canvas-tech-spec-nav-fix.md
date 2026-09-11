# Fix: pipeline canvas Tech Spec drill-down and call-graph load routing

**Goal:** Restore pipeline-flow canvas navigation into the Tech Spec detail view, and make phase agents reliably load the call-graph / `graphify` walk instructions after the slim engineer-review split.

**Repo:** `cursor-spells` (this kit)

## Reported failure

1. After the `csp-` prefix rename, clicking Tech Spec (or “Далі: Tech Spec”) on `docs/superpowers/pipeline-flow.html` does not open the Tech Spec detail view — the overview stays put.
2. After the slim engineer-review context change, review phases often skip neighbors / call-graph / `graphify query` walks because the Process step lives only in `phase-protocol-detail.md`, which most phase agent prompts never name.

## Reproduction

1. Open `docs/superpowers/pipeline-flow.html`.
2. Click the overview node with `data-go="csp-tech-spec"` (or the Bootstrap primary button with the same `data-go`).
3. Observe: no section with `id="view-csp-tech-spec"` exists; the live section is `id="view-tech-spec"`. `show()` resolves to a missing view → no drill-down.
4. Contract gap: `scripts/tests/pipeline-flow-graph-test.sh` never asserts every `data-go` resolves to a `view-*` id (or alias).

Call-graph soft miss:

1. Open `skills/engineer-review/references/phase-protocol.md` — Process / Neighbors / call graph is absent (moved to `phase-protocol-detail.md`).
2. Grep `agents/csp-review-*.md` for `phase-protocol-detail` — only logic, lint, and architecture name it; deadcode, performance, patterns, simplify, security, figma, cross-repo do not.
3. Those phases still cite `phase-protocol.md` for mandatory fields only → models can skip the detail file and therefore skip the call-graph step.

## Root cause

1. **Canvas:** In `#59` / `b590a9b`, overview `data-go` / `data-stage` for Tech Spec were renamed to `csp-tech-spec`, but the detail section id stayed `view-tech-spec`. Other overview nodes keep short view slugs (`build`, `review`) while putting the agent id in `data-stage` only. Tech Spec broke that pattern. Old `#csp-tech-spec` hashes also miss unless aliased.
2. **Call graph:** In `#58` slim split, “Neighbors / call graph” moved from always-read `phase-protocol.md` into phase-owned `phase-protocol-detail.md` without updating every phase agent (and dispatch wording) to require loading the detail file.

## Minimal fix

### Canvas

1. Set every Tech Spec `data-go` value to `tech-spec` (matches `id="view-tech-spec"`). Keep `data-stage="csp-tech-spec"` for orientation / `pipeline-status`.
2. Add HTML alias `"csp-tech-spec": "tech-spec"` next to the existing `"finish-plan": "review-gate"` so bookmarks / prior `history.replaceState` hashes still open the detail view.
3. Extend `scripts/tests/pipeline-flow-graph-test.sh` so every `data-go` resolves to an existing `view-*` (honor `aliases`), and so the `csp-tech-spec` alias maps to `view-tech-spec`.

### Call-graph load routing

4. Canonical Follow sentence (exact):

   `Follow skills/engineer-review/references/phase-protocol.md and phase-protocol-detail.md.`

   Ensure that exact sentence appears in:

   - `agents/csp-review-patterns.md`
   - `agents/csp-review-deadcode.md`
   - `agents/csp-review-simplify.md`
   - `agents/csp-review-performance.md`
   - `agents/csp-review-security.md`
   - `agents/csp-review-figma-markup.md`
   - `agents/csp-review-cross-repo.md`
   - `agents/csp-review-architecture.md` (normalize from the shorter `Follow phase-protocol.md + phase-protocol-detail.md.` form)

   Leave `csp-review-logic.md` / `csp-review-lint.md` alone if they already contain this exact sentence (or an equivalent Follow that already includes both paths); if logic already matches, do not churn it.

5. Dispatch hardening:

   - `agents/csp-engineer-reviewer.md` — replace the weak parenthetical (“phases also load…”) with an explicit instruction that every heuristic phase Task prompt must tell the phase to load `phase-protocol-detail.md`.
   - `agents/csp-pr-reviewer.md` — same explicit load instruction on phase dispatch.
   - `agents/csp-multi-repo-supervisor.md` — on the `csp-review-cross-repo` dispatch step, require loading `phase-protocol-detail.md` (agent Follow line alone is not enough).

6. Contract tests in `scripts/tests/engineer-review-context-budget-test.sh` (**required**, fail-before / pass-after):

   - Exact Follow sentence present in every file listed in (4).
   - For `csp-engineer-reviewer.md`: assert a stronger unique token of the new dispatch wording (must match both `Task prompt` and `phase-protocol-detail` in the dispatch block — plain `phase-protocol-detail` alone is insufficient because the weak parenthetical already contains it).
   - For `csp-pr-reviewer.md` and `csp-multi-repo-supervisor.md`: assert `phase-protocol-detail` appears in the dispatch / phase-load wording.

## Out of scope

- Renaming `view-tech-spec` to `view-csp-tech-spec`.
- Rebuilding consumer `graphify-out/` artifacts.
- Rewriting Mermaid diagrams.
- Changing graphify policy (still preferred-when-present, never required).
- Runtime enforcement beyond prompt + contract strings (models can still ignore text; the contract proves the instruction surface is present). **Accepted risk F4.**

## Rejected alternatives

- Alias-only fix without correcting `data-go` — leaves overview buttons inconsistent with `build` / `review` view-slug pattern.
- Moving Neighbors / call graph back into orch `phase-protocol.md` — undoes the slim context budget decision.
- Relying only on “Phases also load detail” in `phase-protocol.md` — already weak without per-agent and dispatch cites.
- Optional / partial context-budget asserts covering only three agents — leaves patterns, security, figma, cross-repo unguarded.
- Substring-only assert on `csp-engineer-reviewer.md` for `phase-protocol-detail` — already green before the dispatch upgrade.

## Test plan

1. RED: add `data-go` ↔ `view-*` (+ alias) asserts to `pipeline-flow-graph-test.sh`; run → FAIL on current HTML.
2. RED: add required Follow-sentence and dispatch-token asserts to `engineer-review-context-budget-test.sh`; run → FAIL on current agents.
3. Apply canvas + agent + dispatch edits.
4. Re-run both scripts → PASS.
5. Open `pipeline-flow.html`: Tech Spec drill-down, Back, and `#csp-tech-spec` hash all open `view-tech-spec`.
6. `bash scripts/harness-bench.sh` (or at least those two scripts) stays green.

## Blast radius

- `docs/superpowers/pipeline-flow.html` navigation / aliases only.
- Named review agent prompts, orchestrator / pr-reviewer / multi-repo-supervisor dispatch wording, and two contract tests.
- No product application code.
