# Quality pipeline: AC → Tech Spec → Plan → Critic → Developer → Review

## Problem

`cursor-spells` today is strong **after** a plan is executed (`finish-plan` → HITL → `engineer-reviewer` / `multi-repo-supervisor`), but has no structured support **before** code is written. Quality currently depends on whatever the plan-writing session happened to capture. The goal is to shift quality left: catch ambiguity, over-engineering, and architectural risk **before** the developer agent writes a single line, so `engineer-review` becomes a safety net instead of the primary quality gate.

## Goals

- An explicit, auditable chain from Acceptance Criteria to a reviewed PR, with a human-in-the-loop (HITL) gate at every stage that carries irreversible risk.
- An agent that **never invents business requirements**. Technical defaults are allowed only when explicitly logged and confirmed.
- A developer agent that automatically pulls the right skills for the detected stack (including database work), without silently installing unvetted third-party code.
- A sharper, cheaper auto-fix boundary in review: only apply fixes that are provably the single correct answer.

## Non-goals (v1)

- Auto-fixing traceability drift between spec and diff (always `clarify`).
- Auto-installing skills discovered dynamically, without a human decision.
- New mandatory review phases beyond what's described here (a11y/i18n stay a future backlog item).
- Business-requirement inference of any kind, at any stage.

## Pipeline overview

```
AC (testable, from product/human)
  → [HITL: human | agent-assisted] Tech Spec (separate file, English)
  → [HITL approve-spec]
  writing-plans → Implementation Plan
  → [HITL approve-plan]
  → implementation-critic (Pass A + Pass B)   # automatic after approve-plan
  → [HITL if Must-fix or Accept-risk]
  software-developer (skill-resolver + DB routing + code-comments)
  → verify-done (project lint/test/typecheck)
  → finish-plan → engineer-review (reinforced)
  → [HITL] update-docs (skip | docs/ MD | docs repo | Confluence)
  → PR / done
```

**Full canvas** (interactive HTML + Mermaid: every HITL gate, critic verdict branch, marker state, review routing, standalone entry points): [`pipeline-flow.html`](../pipeline-flow.html) · [`pipeline-flow.md`](../pipeline-flow.md).

Every stage transition that carries irreversible risk (spec approval, plan approval, Must-fix findings, accepted risk) stops for a human decision. Mechanical stages (stack detection, static skill lookup, starting the critic after plan approval) never do.

---

## 1. Technical Spec

### What it is

A **developer's technical action plan** — not a PRD, not user-story prose. It states, precisely, what changes in the system to satisfy already-agreed Acceptance Criteria: which services/modules are touched, what tables/APIs/contracts appear or change, how entities link, in what order changes land, and how to roll back.

Example of the expected level of detail: "In the `installation` service, create a `templates` table. Link to organization via a new `organization_templates` table storing `(template_id, organization_id)` pairs."

It is **not** the implementation plan (task-by-task breakdown for an agent) — that remains `writing-plans`' job, consuming this spec as input.

### Format

- **Separate file**, English only, regardless of the team's working language.
- Suggested path: `docs/superpowers/specs/YYYY-MM-DD-<topic>-tech-spec.md` (adjust to existing project conventions if the consumer project already has one).

### HITL entry question

Prefer Cursor `AskQuestion` interactive buttons via skill `hitl-choice` when available; typed tokens remain the contract:

> Tech spec: write it yourself, or have the agent draft it?
> - `human` — you provide the file; the agent only structures/asks about gaps
> - `agent` — the agent drives the interview and writes the draft

### Agent-assisted mode: rules of truth

Three explicit tiers, checked before writing anything into the spec:

| Tier | When | Action |
|------|------|--------|
| **Blocker** | No happy path / unclear data ownership / security / breaking change | Stop and ask. Spec cannot be finalized. |
| **Decision** | ≥2 valid technical options with materially different impact | Present as options (A/B/C) with a recommendation; wait for the human's choice |
| **Assumption** | Local technical default with no business impact (naming within existing conventions, index choice, etc.) | Write it into the spec's `Assumptions` section: the claim, why, and how to revoke it |

Question discipline (reusing the `brainstorming` skill's mechanics, see §6): **one question per message**, multiple-choice preferred (via `hitl-choice` / `AskQuestion` when available), and when presenting a Decision-tier fork, propose 2-3 concrete options with trade-offs rather than open-ended prompts.

### Template

1. AC references (which criteria this closes)
2. Changes by layer (service → storage → API → jobs → …)
3. Data model / contracts (tables, fields, FKs, events)
4. Rollout sequence (so the system never sits half-migrated)
5. Compatibility / migration / rollback
6. Rejected alternatives (one line each — input for the critic)
7. Open questions / Assumptions

### Gate

Plan-writing does not start until the spec is `approved` (or the human explicitly says `skip`, with the reason logged).

### Clean final form (no revision archaeology)

Specs and plans are **decision artifacts**, not diaries. After critique, discussion, or human `revise`, rewrite the file as if the current decisions were always the decisions. Put "what changed this turn" in chat (for the human's verify step), never as Changelog / What-changed / Before–After draft tables inside the file. Forbidden in the body: "fixed", "changed to", "was previously", "after critique F\<id\>", strikethrough of old draft wording. **Rejected alternatives** stays allowed as one-line *current* rationale ("option X — rejected because Y"), not as strike-through of a prior paragraph. Full policy: skill `clean-decision-docs`; project rule `clean-decision-docs.mdc` (globs on `docs/**/specs|plans`).

---

## 2. Implementation Critic

A separate agent that reviews the **plan** (and the tech spec it's based on) before any code is written. It never writes plans or code — only audits.

### When it runs

Not inside `/start-build`. Pipeline order:

1. `writing-plans` produces the plan
2. **HITL `approve-plan`** — human reads the plan (`skills/approve-plan`)
3. **Automatic** `implementation-critic` right after `approve-plan` (no HITL to start the critic)
4. **HITL** only if `Verdict` is `blocked` or `clear pending accept`
5. On `Verdict: clear` → `/start-build` → `software-developer`

Ad-hoc: `/critique-plan` still works outside the pipeline.

### Skills (two complementary lenses, not a single tool)

| Pass | Skill | Catches |
|------|-------|---------|
| **A — Design** | `mblode/agent-skills@plan-reviewer` | Unnecessary complexity, YAGNI violations, simpler alternatives, premature/wrong abstractions, whether the plan delivers a minimal working slice |
| **B — Risk** | `envoydev/agents-stack@project-verify-plan` | Named vs. missing failure modes for the stack, scope match against AC, boundary/edge/safety cases, migration & rollback safety, fit with the *existing* architecture |

One pass alone is not enough: a plan can be simple (passes A) but silently unsafe on migration (fails B), or safe but over-engineered (fails A). Both lenses run on every critic invocation. If a skill is not installed, fall back to its checklist inline and note `skill_missing` — never block the whole critic run for a missing skill.

### Output contract

| Severity | Meaning | Gate |
|----------|---------|------|
| **Must-fix** | Unnecessary complexity with a clearly simpler alternative; violates an existing abstraction; unnamed safety/migration risk; scope drift vs. AC | Developer **cannot start** until resolved or explicitly `accept`ed by a human |
| **Should-fix** | Weak test plan, poor task granularity, missing non-critical edge case | Visible to the human at the HITL gate, does not block |
| **Accept-risk** | A deliberate trade-off | Requires an explicit human `accept` per finding id before the developer proceeds |

Each finding cites its source: the plan/spec line it targets and the repo evidence (pattern file, existing code) it's based on — never a finding without a same-turn quote of what it's judging.

### Scope

Read-only on the plan/spec. Does not edit the plan itself in v1 — the plan author or the human applies changes; the critic re-runs on request.

---

## 3. Software Developer

### Entry conditions (all required)

1. Tech spec is `approved`.
2. Implementation plan exists (from `writing-plans`, based on the spec).
3. Implementation critic has no open Must-fix findings (or all are explicitly `accept`ed).

### Behavior

Writes code strictly to the tech spec + plan. If the plan/spec conflicts with what's actually in the repo, it stops and asks — it does not "fix it along the way" by silently deviating from the spec.

**Before any implementation:** create a feature branch in every git repository the plan/spec intends to change (one repo or several). Same branch name across the set; never land Task 1 commits on `main`/`master`/default. Protocol: `skills/software-developer/references/branch-setup.md`.

### Skill routing

1. **Stack detection** — mechanical, via existing signals (`package.json`, `pom.xml`, `docker-compose`, migration paths, dependency names). Zero LLM reasoning cost; this is a table lookup against `skill-map.md`, the same pattern already used for `logic`/`performance` phase routing.
2. **Always-on for this run:**
   - the matched stack skill(s) (React / RN / Spring / …)
   - `mattpocock/skills@tdd` when the task has observable behavior to test
   - `code-comments` (this kit's own skill, see §5)
3. **Database-aware routing** (new — see §4).
4. **Conditional** (only if the plan/spec touches that surface): perf/security/architecture skills.
5. Before handoff: `obra/superpowers@verification-before-completion` — actually run the project's own lint/test/typecheck, don't assert "done" without evidence.
6. **Web UI vs design** (`react-web` only, when the task changes user-visible UI): use Figma MCP/skills when node URLs exist; after the slice is runnable, follow `ce-test-browser` and compare the rendered UI to those nodes. Missing skill/browser/URLs → note and continue — do not invent pixel diffs.

A missing mapped skill never blocks the run; the developer proceeds on its built-in checklist and reports `skill_missing`.

### What the developer never does

- Expands scope beyond the plan's tasks.
- Makes "while I'm here" improvements outside scope.
- Silently changes the data model described in the tech spec.
- Implements on `main` / `master` / the default branch, or creates branches in repos the plan does not touch.

---

## 4. Database skill routing

Migrations and schema work are a named weak spot for AI-generated code (blast radius on production data), so DB skills are explicit, stack-conditioned rows in `skill-map.md`, not left to general judgement.

### Always on any DB change

- `wshobson/agents@database-migration` — zero-downtime patterns, rollback, expand/contract
- `affaan-m/everything-claude-code@database-migrations` — production discipline: schema and data migrations never mixed, migrations immutable once deployed, forward-only in production

### Current stack: MySQL + MongoDB

| Stack | Skills |
|-------|--------|
| MySQL | `planetscale/database-skills@mysql` (schema/InnoDB, PK/index choices, measurable safe changes), `affaan-m/everything-claude-code@mysql-patterns` (large-table migrations, locks, pagination, pools), `github/awesome-copilot@sql-code-review` |
| MongoDB | `mongodb/agent-skills@mongodb-query-optimizer`, `mongodb/agent-skills@mongodb-connection` (official), `hoodini/ai-agents-skills@mongodb` (schema/collection modeling) |
| Mongoose (if present in repo) | `mongoose-mongodb` skill |

### Conditional — kept in the map for future projects, not installed by default

| Stack | Skills |
|-------|--------|
| Postgres (if a future project uses it) | `wshobson/agents@postgresql-table-design`, `supabase/agent-skills@supabase-postgres-best-practices`, `postgresql-code-review` / `sql-optimization-patterns` |
| Flyway/Spring | Spring Flyway migration skill |
| Prisma | `prisma/skills@prisma-cli` + matching dialect skill |

### Routing trigger

A diff/spec touching `**/db/migration/**`, `*.sql`, ORM schema/entity files, or containing DDL/backfill language triggers the matching row automatically — detected mechanically, same mechanism as stack detection above. The same DB skills also apply during `engineer-review`'s `logic`/`architecture` phases when the diff includes a migration, not only during development.

---

## 5. Comments policy (`code-comments` skill)

Addresses a concrete current gap: `review-deadcode` today only says "keep comments for non-obvious intent" — too vague to consistently apply or auto-fix.

Shared by the developer (prevention) and `engineer-review`'s deadcode phase (enforcement).

| Keep | Remove / never write |
|------|-----------------------|
| `TODO` / `FIXME` (**never delete**, ideally with an owner/ticket ref) | AI narrative ("Helper function that…", "Import dependencies") |
| Why / invariant / non-obvious constraint / security or perf trade-off | Changelog-style ("previously used X, now Y") |
| Non-obvious call-site parameter labels (`/* enabled= */ true`) when refactoring for clarity isn't feasible | Commented-out code |
| Public API documentation | Comments that just restate the type/parameter name |

Preference order: rename/simplify the code over adding a comment to compensate for unclear naming.

`review-deadcode`'s severity table is replaced by the auto-fix eligibility test in §7 for the "which of these get auto-applied" decision — the table above only decides *what's junk*, not what's safe to silently remove.

---

## 6. Cross-cutting discipline: `using-superpowers` + `brainstorming`

Two existing skills, different roles, both folded into every stage above rather than becoming their own pipeline stage:

- **`using-superpowers`** is not a process — it's the enforcement rule "check whether a designated protocol/skill exists for this step before acting, even if the step looks simple." Every agent in this pipeline (`tech-spec`, `implementation-critic`, `software-developer`, `engineer-reviewer`, `skill-resolver`) carries this as a standing self-check before producing output: *did I actually apply my checklist, or did I skip it because this looked obvious?*
- **`brainstorming`**'s question-loop mechanics (one question per message, multiple-choice preferred, 2-3 options with trade-offs before presenting a design) are reused as the reference implementation for the Tech Spec's Decision-tier interview (§1) — not brainstorming itself as a stage, since the tech spec's artifact is intentionally narrower (an engineering action plan, not a product/UX design doc).

---

## 7. Auto-fix eligibility test

Replaces "P0/P1 = apply" as a feel-based severity judgement with a hard test, applied uniformly across `engineer-review`, the comments policy, and traceability checks.

**Auto-fix is allowed only when all four hold:**

1. **Deterministic check** — backed by a tool result or an explicit, quoted spec value, not the agent's opinion.
2. **Single correct answer** — no reasonable alternative interpretation exists (`2+2=5` → `2+2=4`: there's no "maybe they meant 5").
3. **No information loss** — the fix doesn't remove anything that could carry intent (dynamic usage, a future contract).
4. **Zero blast radius on data or user-facing behavior** — it's syntax/junk/a proven mistake, not business logic.

If any condition fails: `clarify`, never a silent apply — regardless of how "obvious" it looks.

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

Traceability drift (spec vs. diff mismatch, §8) is `clarify`-only by construction — it structurally fails condition 2, not because it's out of v1 scope.

---

## 8. `engineer-review` reinforcement

Applied on top of the existing orchestrator (`skills/engineer-review/`), not a rewrite:

- `review-deadcode` adopts the comments taxonomy from §5 verbatim, and the auto-fix decision for every finding in every phase uses the §7 test instead of a severity guess.
- New lightweight check in the `patterns` phase: when a tech spec / AC trace exists for the diff, verify the diff matches the declared services/tables/seams. A mismatch is always `clarify` (§7's traceability row), never silently accepted or auto-fixed.
- DB skills from §4 are available to `logic`/`architecture` phases whenever the diff includes a migration, mirroring the developer's routing.
- Each phase agent's self-check before emitting a verdict: did it actually load and apply its mapped skill/checklist for this finding, per §6.

## 9. `skill-resolver`: stack-to-skill matching, cost-aware and human-gated

### Two trust tiers, no silent middle ground

- **Tier 1 — Curated.** Everything already listed in `skill-map.md` (including all skills named in §3/§4/§5) is pre-verified by us. Used directly, no network call, no question.
- **Tier 2 — Edge case.** A stack or task type not covered by the map. The agent **never installs or edits the map on its own**. It may search skills.sh for candidates purely to present them, then stops and asks the human:

  > No verified skill for `<stack/task>`. Candidates found: `owner/repo@skill` (installs, audit status), … Install one, provide your own, or continue without (built-in checklist)?

  Whatever the human picks, **the human's decision** is what gets added to `skill-map.md` for future runs. The agent does not add third-party entries to the curated map on its own initiative.

### Cost control

- **Tier 1 lookup costs ~0 tokens** — it's a mechanical table match on file/dependency signals (same mechanism as existing stack detection in `skill-map.md`), not a reasoning call.
- **Tier 2 search is dispatched to a cheap/fast model as a scoped subagent** (e.g. `composer-2.5-fast`, `cursor-grok-4.5-high-fast`) that only returns a short structured candidate list. The primary (expensive) session never reads raw search API output — only the subagent's compact summary, before asking the human.

### Why this removes most of the third-party-skill risk

Because no unvetted code is ever pulled in without a human decision in the loop, this design sidesteps typosquatting, prompt injection via a skill body, and supply-chain drift as automated risks — the only thing automated is *finding candidates to show a human*, never installing or trusting them.

---

## New/changed artifacts

- `agents/tech-spec.md` (new) — drives §1
- `agents/implementation-critic.md` (new) — drives §2
- `skills/approve-plan/SKILL.md` + `commands/approve-plan.md` — HITL approve-plan, then auto critic, then `start-build` on clear
- `skills/start-build/SKILL.md` — thin execution handoff (requires `.cursor/plan-critique.clear`; does not run the critic)
- `agents/software-developer.md` + `skills/software-developer/SKILL.md` (new) — drives §3 (branch setup in target repo(s), skill-map routing, code-comments, verify-before-handoff; on `react-web` also Figma + `ce-test-browser`)
- `skills/software-developer/references/branch-setup.md` — resolve target repos from plan/spec, shared feature branch name, create/checkout before Task 1
- `commands/start-task.md`, `commands/write-tech-spec.md`, `commands/critique-plan.md` (new)
- `skills/update-docs/SKILL.md` + `commands/update-docs.md` — post-review HITL for product-docs destination (`docs_md` / `docs_repo` / `confluence` / `skip`) + dual-audience writing guide
- `skills/code-comments/SKILL.md` (new) — drives §5, shared by developer + `review-deadcode`
- `skills/engineer-review/references/skill-map.md` — add DB rows (§4) and a `## Discovered` section for Tier-2 human-approved additions (§9)
- `agents/review-deadcode.md` — adopt §5 taxonomy + §7 test
- `skills/engineer-review/references/phase-protocol.md` — reference §7 as the apply/clarify decision rule (replacing the current severity-only heuristic for edge cases), add the traceability check note from §8

## Open questions

None blocking — all Decision-tier forks in this design were resolved during the brainstorming session (critic skill choice: B; tech spec format: separate English file; DB stack: MySQL + MongoDB with Postgres kept conditional; skill-resolver: human-gated Tier 2, cheap-model search).
