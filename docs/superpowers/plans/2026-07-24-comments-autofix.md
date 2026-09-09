# Comments Policy & Auto-fix Eligibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `code-comments` skill with an explicit keep/remove taxonomy, and replace `engineer-review`'s feel-based "P0/P1 = auto-apply" rule with a hard 4-condition auto-fix eligibility test, applied uniformly across every review phase plus a new spec/diff traceability check.

**Architecture:** Two new shared reference artifacts (`skills/code-comments/SKILL.md`, `skills/engineer-review/references/auto-fix-eligibility.md`) become the single source of truth that existing `engineer-review` files (`csp-review-deadcode`, `csp-review-patterns`, `phase-protocol.md`, the top-level `engineer-review` `SKILL.md`, and the `project-patterns.md` template) reference instead of duplicating inline policy. This is a reinforcement of the existing orchestrator, not a rewrite — no new phases, no new agents.

**Tech Stack:** Markdown-based Cursor skill/agent/command definitions (this is a prompt-engineering kit, not compiled software) — same format as the `implementation-critic` and `tech-spec` sub-projects already shipped on this branch.

## Global Constraints

- The auto-fix eligibility test's four conditions and their exact wording must be identical everywhere they're referenced — one canonical copy in `auto-fix-eligibility.md`, every other file links to it rather than restating it.
- The comments keep/remove taxonomy's exact wording must be identical everywhere — one canonical copy in `skills/code-comments/SKILL.md`, `project-patterns.md`'s template inherits it by reference instead of duplicating an inline mini-policy.
- Severity (`P0`/`P1`/`P2`) still classifies importance; it is necessary but never sufficient for auto-apply — every file that currently implies "P0/P1 = auto-apply" must be corrected to say auto-apply also requires passing the eligibility test.
- Traceability mismatches (diff vs. tech spec) are always `clarify`, never auto-applied, by construction (they fail the eligibility test's "single correct answer" condition).
- No new phases or agents — this reinforces `csp-review-deadcode`, `csp-review-patterns`, and the shared reference docs that all phases already read.
- Frequent, small commits — one per task.
- Before creating any file with a fenced code example, check whether it needs more than one level of code-fence nesting; if so, use a 4-space-indented presentation block instead of stacking same-length triple-backtick fences (see `docs/superpowers/plans/2026-07-24-implementation-critic.md` Task 6 for the precedent and why).
- All `grep`-based verification-count expectations in this plan were computed by writing each task's exact draft content to a scratch file and running the real `grep -c` command against it before finalizing the expected numbers (the practice that produced zero miscounted expectations in the `tech-spec-agent` sub-project, vs. 4 miscounts in the first, `implementation-critic`, sub-project).

---

## File Structure

- `skills/code-comments/SKILL.md` (new) — the canonical Keep/Remove comment taxonomy, shared by developer agents and `csp-review-deadcode`
- `skills/engineer-review/references/auto-fix-eligibility.md` (new) — the canonical 4-condition auto-fix test + worked examples table
- `agents/csp-review-deadcode.md` (modified) — adopts the code-comments taxonomy by reference; apply decisions now gated by the eligibility test, not severity alone
- `skills/engineer-review/references/phase-protocol.md` (modified) — Severity section reworded to require passing the eligibility test for auto-apply; new Traceability check subsection; `Apply rules` updated to match
- `agents/csp-review-patterns.md` (modified) — adds the traceability check (tech spec / AC trace vs. diff mismatch → always `clarify`)
- `skills/engineer-review/references/patterns-template.md` (modified) — `Comments policy` section now points at `skills/code-comments/SKILL.md` instead of a duplicated inline mini-policy
- `skills/engineer-review/SKILL.md` (modified) — `Fix policy` section updated to reference the eligibility test, so the top-level skill doesn't contradict `phase-protocol.md`'s more precise rule
- `README.md` — add a `code-comments` Skills-table row + one sentence describing the new eligibility test

Each new file has one responsibility (comment taxonomy vs. apply-eligibility test); every modified file is a targeted, minimal change that removes a duplicated or imprecise rule in favor of a reference to the new canonical source.

---

### Task 1: Create the `code-comments` skill

**Files:**
- Create: `skills/code-comments/SKILL.md`

**Interfaces:**
- Produces: the skill name `code-comments`, the Keep/Remove taxonomy tables, and a reference to `skills/engineer-review/references/auto-fix-eligibility.md` (Task 2) that Tasks 3 and 6 also depend on for wording consistency.

- [ ] **Step 1: Write the skill file**

```markdown
---
name: code-comments
description: >-
  Use when writing or reviewing code comments: what to keep, what to remove,
  and when a comment is a crutch for an unclear name. Shared by developer
  agents (prevention) and engineer-review's deadcode phase (enforcement). Use
  when the user asks about comment style, or when review-deadcode or a
  developer agent needs the keep/remove taxonomy.
---

# Code Comments

A comment is worth keeping only if it tells a reader something the code itself cannot.

## Keep

| What | Why |
|------|-----|
| `TODO` / `FIXME` (**never delete**, ideally with an owner/ticket ref) | Marks known follow-up work; deleting it hides the debt, it doesn't resolve it |
| Why / invariant / non-obvious constraint / security or perf trade-off | Explains intent the code can't state on its own |
| Non-obvious call-site parameter labels (`/* enabled= */ true`) when refactoring for clarity isn't feasible | Disambiguates an unclear call site without a full rename |
| Public API documentation | Communicates contract to callers who won't read the implementation |

## Remove / never write

| What | Why |
|------|-----|
| AI narrative ("Helper function that…", "Import dependencies") | Restates what the code already says; adds no information |
| Changelog-style ("previously used X, now Y") | Git history already carries this; it rots the moment the next change lands |
| Commented-out code | Dead weight; git history is the place for old versions |
| Comments that just restate the type/parameter name | Zero information beyond the signature itself |

## Preference order

Rename or simplify the code before reaching for a comment to compensate for an unclear name. A comment explaining what a poorly-named variable does is a signal to rename the variable, not evidence the comment is earning its place.

## Who uses this

- **Developer agents**: apply this taxonomy while writing new code — don't introduce what "Remove" lists in the first place.
- **`csp-review-deadcode`** (engineer-review phase): apply this taxonomy to classify comment findings in a diff; see `skills/engineer-review/references/auto-fix-eligibility.md` for which of these are safe to auto-apply vs. must go to `clarify`.
```

- [ ] **Step 2: Verify frontmatter and structure**

Run: `grep -c "^name: code-comments$" skills/code-comments/SKILL.md && grep -c "^## Keep$" skills/code-comments/SKILL.md && grep -c "^## Remove / never write$" skills/code-comments/SKILL.md && grep -c "auto-fix-eligibility.md" skills/code-comments/SKILL.md`
Expected: `1`, `1`, `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add skills/code-comments/SKILL.md
git commit -m "Add code-comments skill with Keep/Remove taxonomy"
```

---

### Task 2: Create the auto-fix eligibility test reference

**Files:**
- Create: `skills/engineer-review/references/auto-fix-eligibility.md`

**Interfaces:**
- Produces: the 4-condition test, its exact wording, and the worked-examples table that Tasks 3, 4, 5, and 7 all link to and must not restate differently.

- [ ] **Step 1: Write the reference file**

```markdown
# Auto-fix eligibility test

Replaces "P0/P1 = auto-apply" as a feel-based severity judgement with a hard test. Applies uniformly across every `engineer-review` phase, the comments policy (`skills/code-comments/`), and traceability checks.

## The test

Auto-fix is allowed only when **all four** hold:

1. **Deterministic check** — backed by a tool result or an explicit, quoted spec value, not the agent's opinion.
2. **Single correct answer** — no reasonable alternative interpretation exists (`2+2=5` → `2+2=4`: there's no "maybe they meant 5").
3. **No information loss** — the fix doesn't remove anything that could carry intent (dynamic usage, a future contract).
4. **Zero blast radius on data or user-facing behavior** — it's syntax/junk/a proven mistake, not business logic.

If any condition fails: `clarify`, never a silent apply — regardless of how "obvious" it looks. Severity (`P0`/`P1`/`P2`) still classifies how important a finding is; this test is the separate, stricter gate for whether it may be applied without asking.

## Worked examples

| Finding | Auto-fix? | Why |
|---|---|---|
| Lint/typecheck/compiler error | Yes | Tool-verified, not an opinion |
| Commented-out code | Yes | Removing it changes nothing about execution |
| Historical/changelog comment | Yes | Pure narrative, carries no behavior information |
| Statically-confirmed unused import/export (no reflection/DI path) | Yes | Deterministically proven unused |
| Diff contradicts an explicit spec value/formula | Yes | Spec gives one correct value; condition 2 holds |
| Diff deviates from spec but the reason is unclear (spec stale? scope intentionally grew?) | No — clarify | Two plausible explanations, fails condition 2 |
| Any migration/schema change, even "obviously better" | No — clarify | Always fails condition 4 (blast radius on data) |
| Dead code that might be used via reflection/DI/dynamic import | No — clarify | Fails condition 3 |
| Security or logic bug, even one that looks clearly wrong | No — clarify | May be undocumented intended behavior; condition 2 not guaranteed without domain knowledge |

Traceability drift (spec vs. diff mismatch) is `clarify`-only by construction — it structurally fails condition 2 (two plausible explanations: the spec is stale, or the diff scope drifted), not because it's arbitrarily out of scope.

This is a different case from the "Diff contradicts an explicit spec value/formula" row above: that row applies only when the spec states one exact value or formula and the code computes something else within the same declared scope — a single quoted correct answer exists, so condition 2 holds. Traceability drift is about scope itself (services/tables/seams present or missing relative to what the spec declares), where the cause of the mismatch cannot be determined from the diff alone — always `clarify`, never the "Yes" row above.

## How phases use this

Every phase's `apply` pass (per `phase-protocol.md`) checks a candidate fix against this test before setting `applied: true`, in addition to being `unambiguous: true` and `P0`/`P1` severity. Severity alone is necessary but not sufficient.
```

- [ ] **Step 2: Verify structure**

Run: `grep -c "^## The test$" skills/engineer-review/references/auto-fix-eligibility.md && grep -c "^## Worked examples$" skills/engineer-review/references/auto-fix-eligibility.md && grep -c "^## How phases use this$" skills/engineer-review/references/auto-fix-eligibility.md && grep -c "^[1-4]\. \*\*" skills/engineer-review/references/auto-fix-eligibility.md`
Expected: `1`, `1`, `1`, `4`

- [ ] **Step 3: Commit**

```bash
git add skills/engineer-review/references/auto-fix-eligibility.md
git commit -m "Add auto-fix eligibility test reference"
```

---

### Task 3: Update `csp-review-deadcode` to use the new taxonomy and eligibility test

**Files:**
- Modify: `agents/csp-review-deadcode.md` (full replacement)

**Interfaces:**
- Consumes: `skills/code-comments/SKILL.md` (Task 1) and `skills/engineer-review/references/auto-fix-eligibility.md` (Task 2).

- [ ] **Step 1: Replace the file content**

```markdown
---
name: review-deadcode
description: >-
  Phase agent for dead code, redundancy, duplicate solutions, and low-value
  comments during engineer-review.
---

You hunt **dead code**, **redundancy**, and **bad comments** in the diff and its immediate neighbors.

## Check

- Unused exports/imports/params introduced or left by the change
- Duplicate logic that already exists (see patterns "Do not reinvent")
- Alternate solution style when an equivalent project approach exists — prefer reuse
- Comments: classify every new or changed comment against `skills/code-comments/SKILL.md`'s Keep / Remove taxonomy

## Skills

Use `dead-code-eliminator` if installed; otherwise built-in static reading + search. Always use `skills/code-comments/SKILL.md` for comment classification — it is this kit's own skill, always available.

## Caution

Do not delete code that may be used via reflection, DI config, dynamic imports, or framework entrypoints without evidence — send those to `clarify`.

## Output

`phase`: `"deadcode"`. Tag every finding with `severity` (`P0` rare; unused import/historical comment usually `P1`; style nits `P2`). Before setting `applied: true` on any candidate, check it against `skills/engineer-review/references/auto-fix-eligibility.md` — severity alone does not authorize an apply.
```

- [ ] **Step 2: Verify cross-references**

Run: `grep -c "^name: review-deadcode$" agents/csp-review-deadcode.md && grep -c "skills/code-comments/SKILL.md" agents/csp-review-deadcode.md && grep -c "auto-fix-eligibility.md" agents/csp-review-deadcode.md`
Expected: `1`, `2`, `1`

- [ ] **Step 3: Commit**

```bash
git add agents/csp-review-deadcode.md
git commit -m "Wire review-deadcode to code-comments taxonomy and auto-fix eligibility test"
```

---

### Task 4: Update `phase-protocol.md` with the eligibility gate and traceability check

**Files:**
- Modify: `skills/engineer-review/references/phase-protocol.md` (full replacement)

**Interfaces:**
- Consumes: `skills/engineer-review/references/auto-fix-eligibility.md` (Task 2).
- Produces: the `tech_spec_path` input field and the Traceability check section that Task 5 (`review-patterns.md`) also implements.

- [ ] **Step 1: Replace the file content**

```markdown
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

## Budget hard caps (per phase invocation)

| Cap | Default | Behavior |
|-----|---------|----------|
| Max files to deep-read | **40** | If diff touches more, orchestrator chunks by top-level package/dir and runs the phase per chunk |
| Max changed LOC (insertions+deletions) | **2500** | Same chunking rule |
| Max notes | **8** | Drop lowest-value residuals |
| Max clarify items | **12** per phase | Overflow → single clarify "batch remaining in Residual notes" |

Orchestrator computes `git diff --numstat` / file list **before** dispatch. Subagents must not silently expand into the whole repo.

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
3. Review **changed code** against checklist; use patterns file for local conventions.
4. Classify each issue into `fixed` (candidate or applied) or `clarify`, with severity.
5. Return **only** the JSON summary below.

## Phase order

`lint` runs **first**, before every heuristic phase, and does not depend on `patterns` or a stack skill — it just executes the project's own linter/typechecker/build. Its findings are deterministic (a tool said so, not an LLM guess), so they are cheap to trust and apply. Heuristic phases (`patterns`, `deadcode`, `logic`, `architecture`, `performance`, `security`, `figma`) run after, in parallel for `find`.

**Apply-conflict order** when phases touch the same lines: `lint → patterns → deadcode → logic → architecture → performance → security → figma`.

**Verify pass:** after the orchestrator applies unambiguous `P0`/`P1` fixes across all phases, re-run `csp-review-lint` once more in `find` mode over the final diff. This catches lint regressions introduced by another phase's fix (e.g. a `deadcode` removal that leaves a now-unused import). Fold any new `lint` findings into the same apply/clarify pass; do not repeat the verify pass more than once per review round.

## Apply rules

- In `find` mode: never mutate the tree; set `"applied": false` on candidates.
- Preferred kit default: parallel `find`, then one `apply` for `unambiguous && (P0|P1)` that also passes [`auto-fix-eligibility.md`](auto-fix-eligibility.md).
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
```

- [ ] **Step 2: Verify the new sections and reference count**

Run: `grep -c "auto-fix-eligibility.md" skills/engineer-review/references/phase-protocol.md && grep -c "^## Traceability check" skills/engineer-review/references/phase-protocol.md && grep -c "tech_spec_path" skills/engineer-review/references/phase-protocol.md`
Expected: `5`, `1`, `2`

- [ ] **Step 3: Commit**

```bash
git add skills/engineer-review/references/phase-protocol.md
git commit -m "Gate phase-protocol auto-apply on eligibility test; add traceability check"
```

---

### Task 5: Add the traceability check to `csp-review-patterns`

**Files:**
- Modify: `agents/csp-review-patterns.md` (full replacement)

**Interfaces:**
- Consumes: `tech_spec_path` input and the Traceability check concept from Task 4; `skills/engineer-review/references/auto-fix-eligibility.md` (Task 2).

- [ ] **Step 1: Replace the file content**

```markdown
---
name: review-patterns
description: >-
  Phase agent that creates or enforces project patterns for engineer-review.
  Use on first review to write .cursor/project-patterns.md, and on later
  reviews to catch drift.
---

You own **project pattern fidelity**.

## First run (patterns file missing)

1. Sample the repo structure (folders, naming, packages, representative components/classes).
2. Write `.cursor/project-patterns.md` using `skills/engineer-review/references/patterns-template.md`.
3. Optionally, if graphify is installed and the user opted in, generate/update graphify artifacts and link them from the patterns file.
4. Then check the **diff** against the new patterns.

## Later runs

1. Read existing `.cursor/project-patterns.md` (and graphify summary if linked).
2. Flag diff violations: naming, folder placement, package usage, reinvented patterns.
3. Update the patterns file only when you discover stable conventions the file missed (`patterns: updated` via notes).

## Traceability check (when a tech spec exists)

If a tech spec or AC trace exists for this diff (`tech_spec_path` from the orchestrator, or discoverable under `docs/**/specs/` matching the branch/task topic), verify the diff matches the spec's declared services/tables/seams. Any mismatch — missing what the spec calls for, or extra scope the spec doesn't mention — is always `clarify`, never auto-applied (see `skills/engineer-review/references/auto-fix-eligibility.md`).

## Output

`phase`: `"patterns"`. Include `severity` on every item. Prefer clarification when a "violation" might be an intentional new convention. Traceability mismatches are always `clarify`, regardless of how confident the phase is.
```

- [ ] **Step 2: Verify structure**

Run: `grep -c "^name: review-patterns$" agents/csp-review-patterns.md && grep -c "^## Traceability check" agents/csp-review-patterns.md && grep -c "auto-fix-eligibility.md" agents/csp-review-patterns.md`
Expected: `1`, `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add agents/csp-review-patterns.md
git commit -m "Add traceability check to review-patterns"
```

---

### Task 6: Point `patterns-template.md`'s Comments policy at `code-comments`

**Files:**
- Modify: `skills/engineer-review/references/patterns-template.md` (full replacement)

**Interfaces:**
- Consumes: `skills/code-comments/SKILL.md` (Task 1).

- [ ] **Step 1: Replace the file content**

```markdown
# Project patterns

> Generated by engineer-review for this repository. Update when conventions drift.
> Path in consumer projects: `.cursor/project-patterns.md`

## Stack

- Primary: <!-- e.g. react-web + typescript -->
- Package manager / build: <!-- npm|pnpm|yarn|gradle|maven -->

## Naming

- Files:
- Components / classes:
- Hooks / utilities / packages:
- Tests:

## Folder structure

- Source roots:
- Feature vs layer layout:
- Colocation rules (styles, tests, stories):

## Components / classes

- Preferred component style (function, hooks, etc.):
- State / data-fetching patterns:
- Backend layering (controllers, services, repos) if applicable:

## Packages and imports

- Path aliases:
- Allowed shared packages:
- Import order / barrel files:

## Code techniques

- Error handling:
- Async patterns:
- Validation:
- Logging:

## Do not reinvent

List existing helpers/modules that new code must reuse:

- `path` — purpose

## Comments policy

This project follows `skills/code-comments/SKILL.md`'s Keep / Remove taxonomy as-is. Note any project-specific exceptions here:

- Exceptions (if any):

## Graphify (optional)

- Enabled: no | yes
- Report path: `graphify-out/GRAPH_REPORT.md`
```

- [ ] **Step 2: Verify structure**

Run: `grep -c "^## Comments policy$" skills/engineer-review/references/patterns-template.md && grep -c "skills/code-comments/SKILL.md" skills/engineer-review/references/patterns-template.md && grep -c "^## Do not reinvent$" skills/engineer-review/references/patterns-template.md`
Expected: `1`, `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add skills/engineer-review/references/patterns-template.md
git commit -m "Point project-patterns template Comments policy at code-comments skill"
```

---

### Task 7: Update `engineer-review`'s top-level Fix policy

**Files:**
- Modify: `skills/engineer-review/SKILL.md:52-56` (Fix policy section only)

**Interfaces:**
- Consumes: `skills/engineer-review/references/auto-fix-eligibility.md` (Task 2).

- [ ] **Step 1: Replace the Fix policy section**

In `skills/engineer-review/SKILL.md`, change:

```markdown
## Fix policy

- Apply immediately: unambiguous **P0/P1** (bugs, dead code, obsolete historical comments, clear pattern violations, reinvented helpers).
- **P2** → Residual notes only.
- Clarify first: behavior/API/product/design/security tradeoffs, risky deletions, anything without clear evidence.
```

to:

```markdown
## Fix policy

- Apply immediately: unambiguous **P0/P1** that also passes [`references/auto-fix-eligibility.md`](references/auto-fix-eligibility.md) (bugs, dead code, obsolete historical comments, clear pattern violations, reinvented helpers).
- **P2** → Residual notes only.
- Clarify first: behavior/API/product/design/security tradeoffs, risky deletions, spec/diff traceability mismatches, anything without clear evidence or that fails the eligibility test.
```

- [ ] **Step 2: Verify the reference landed**

Run: `grep -c "auto-fix-eligibility.md" skills/engineer-review/SKILL.md`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add skills/engineer-review/SKILL.md
git commit -m "Reference auto-fix eligibility test in engineer-review Fix policy"
```

---

### Task 8: Document `code-comments` and the eligibility test in README

**Files:**
- Modify: `README.md` (Skills table + one Usage sentence)

**Interfaces:**
- Consumes: skill path `skills/code-comments/`, reference path `skills/engineer-review/references/auto-fix-eligibility.md`.

- [ ] **Step 1: Add a row to the Skills table**

In `README.md`, change:

```markdown
| [`tech-spec`](skills/tech-spec/) | Developer technical action plan — Blocker/Decision/Assumption question protocol, English-only file |
```

to:

```markdown
| [`tech-spec`](skills/tech-spec/) | Developer technical action plan — Blocker/Decision/Assumption question protocol, English-only file |
| [`code-comments`](skills/code-comments/) | Keep/remove taxonomy for comments — shared by developers and `csp-review-deadcode` |
```

- [ ] **Step 2: Add a sentence describing the eligibility test**

In `README.md`, change:

```markdown
4. Orchestrator runs phases; applies **P0/P1** unambiguous fixes; lists clarifications separately

**Manual review:** `/csp-engineer-review`
```

to:

```markdown
4. Orchestrator runs phases; applies **P0/P1** unambiguous fixes; lists clarifications separately

Comment cleanup and apply-vs-clarify decisions across all review phases now follow a strict [auto-fix eligibility test](skills/engineer-review/references/auto-fix-eligibility.md): a finding is only auto-applied if it's deterministic, has a single correct answer, loses no information, and has zero blast radius on data or user-facing behavior — otherwise it's always `clarify`, regardless of severity.

**Manual review:** `/csp-engineer-review`
```

- [ ] **Step 3: Verify all additions landed**

Run: `grep -c "code-comments" README.md && grep -c "auto-fix-eligibility" README.md`
Expected: `1`, `1`

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "Document code-comments skill and auto-fix eligibility test in README"
```

---

## Self-Review

**1. Spec coverage:** Every element of design spec §5, §7, and the in-scope part of §8 (`docs/superpowers/specs/2026-07-24-quality-pipeline-design.md`) is covered: the Keep/Remove taxonomy verbatim (Task 1), the 4-condition eligibility test verbatim including the worked-examples table (Task 2), `csp-review-deadcode` adopting the taxonomy and gating applies on the test (Task 3), the traceability check in the `patterns` phase (Tasks 4, 5), and severity no longer being sufficient on its own for auto-apply everywhere it's stated (Tasks 3, 4, 7). The §8 bullet about DB skills being available to `logic`/`architecture` phases is explicitly out of scope for this plan — it depends on the DB skill-map rows from design §4, which is sub-project 2's responsibility, not this one.

**2. Placeholder scan:** No `TBD`/`TODO`/"implement later" text anywhere in the plan's file contents (the `TODO`/`FIXME` mentions are legitimate content describing what `code-comments` says to keep, not placeholders in this plan itself).

**3. Type/name consistency:** `code-comments` and `auto-fix-eligibility.md` are spelled identically everywhere they're referenced across Tasks 1–8. The four condition names (Deterministic check, Single correct answer, No information loss, Zero blast radius) and the `Keep`/`Remove` taxonomy wording are copied verbatim between the canonical files (Tasks 1, 2) and every place that could have restated them instead of linking (Tasks 3, 4, 5, 6, 7) — none do; they all reference by path. Every `grep` verification count in this plan was computed against real scratch-file drafts before being written down.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-24-comments-autofix.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
