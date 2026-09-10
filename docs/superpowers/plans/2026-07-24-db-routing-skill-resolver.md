# DB Routing & Skill Resolver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add explicit, stack-conditioned database skill routing (MySQL + MongoDB current stack, Postgres/Flyway/Prisma conditional) and a two-tier, human-gated skill resolution protocol to `skill-map.md`, then wire the `logic` and `architecture` review phases and the orchestrator to use both.

**Architecture:** All new routing/resolution logic lives in the single existing `skill-map.md` reference file (the canonical place every phase agent already reads for skill routing) plus targeted one-line additions to three agent files that consume it. No new skill or agent files — this is the last of four sub-projects reinforcing the existing `engineer-review` orchestrator, not a rewrite.

**Tech Stack:** Markdown-based Cursor skill/agent/command definitions (this is a prompt-engineering kit, not compiled software) — same format as the three sub-projects already shipped on this branch.

## Global Constraints

- Never vendor third-party skill bodies into the kit — every DB skill is referenced by `owner/repo@skill` id and install command only.
- Tier 1 (curated `skill-map.md` lookup) costs no reasoning call — it is a mechanical table match on file/dependency signals, same mechanism as the existing stack-detection table.
- Tier 2 (a stack/task not covered by the map) is always human-gated — the agent never installs, searches for, and silently adopts, or edits `skill-map.md` on its own initiative. It may present candidates found via a cheap/fast-model subagent search, but the human's explicit choice is what gets recorded.
- DB skills become available to the `logic` and `architecture` phases only when the diff includes a migration (mechanical detection: `**/db/migration/**`, `*.sql`, ORM schema/entity files, or DDL/backfill language) — this is additive to their existing stack-skill loading, not a replacement.
- Frequent, small commits — one per task.
- All `grep`-based verification-count expectations in this plan were computed by writing each task's exact draft content to a scratch file and running the real `grep -c` command against it before finalizing the numbers.

---

## File Structure

- `skills/engineer-review/references/skill-map.md` (modified, full replacement) — adds "Database skill routing", "Skill resolution protocol", and "Discovered" sections; updates the "Phase → skills" table's `logic`/`architecture` rows
- `agents/csp-review-logic.md` (modified, targeted edit) — Setup step 1 now also loads the matching DB skill row when relevant, and defers to the Skill resolution protocol for uncovered stacks
- `agents/csp-review-architecture.md` (modified, targeted edit) — Skills line now also loads the matching DB skill row when relevant
- `agents/csp-engineer-reviewer.md` (modified, targeted edit) — new Hard rule: never install/invent a skill for an uncovered stack, follow the Skill resolution protocol
- `README.md` (modified, targeted edit) — one paragraph describing DB routing and the skill resolution protocol

Every change is additive to an existing file; no new files are created in this sub-project (all the new logic belongs in `skill-map.md`, the file every phase agent already treats as the single source of truth for skill routing).

---

### Task 1: Add Database skill routing and Skill resolution protocol to `skill-map.md`

**Files:**
- Modify: `skills/engineer-review/references/skill-map.md` (full replacement)

**Interfaces:**
- Produces: the "Database skill routing" section (Always-on/MySQL/MongoDB/Conditional tables + routing trigger), the "Skill resolution protocol" section (Tier 1/Tier 2 rules), and the "Discovered" section that Tasks 2, 3, and 4 all reference by name.

- [ ] **Step 1: Replace the file content**

```markdown
# Skill map

Recommended installs (consumer machine / project). Do not vendor skill bodies into cursor-spells.

```bash
npx skills add vercel-labs/agent-skills@vercel-react-best-practices
npx skills add vercel-labs/agent-skills@vercel-react-native-skills
npx skills add github/awesome-copilot@java-springboot
npx skills add affaan-m/everything-claude-code@security-review
npx skills add addyosmani/agent-skills@performance-optimization
npx skills add getsentry/warden@architecture-review
npx skills add abpai/skills@dead-code-eliminator
# optional patterns graph:
npx skills add graphify-labs/graphify@graphify
```

## Stack detection → skills

| Signal | Stack label | Skills for logic / perf |
|--------|-------------|-------------------------|
| `package.json` with `react-native` / `expo` | `react-native` | `vercel-react-native-skills`; Callstack RN BP if installed |
| `package.json` with `react` / `next` / `react-dom` | `react-web` | `vercel-react-best-practices` |
| `tsconfig.json` + TS sources without React | `typescript` | `vercel-react-best-practices` only if UI; else general TS review without Vercel UI rules |
| `pom.xml` / `build.gradle*` / `*.java` + Spring deps | `java-spring` | `java-springboot` |
| Mixed monorepo | detect per changed path | pick skill per package touched by the diff |

## Database skill routing

Migrations and schema work are a named weak spot for AI-generated code (blast radius on production data), so DB skills are explicit, stack-conditioned rows here — not left to general judgement. Detection is mechanical: a diff touching `**/db/migration/**`, `*.sql`, ORM schema/entity files, or containing DDL/backfill language triggers the matching row below, the same way stack detection above works. These skills are available to the `logic` and `architecture` phases whenever the diff includes a migration (see Phase → skills below), not only during development.

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

## Stack detection → lint/typecheck commands (for `csp-review-lint`)

Prefer the project's own `package.json` script over calling the binary directly.

| Stack | Preferred | Fallback |
|-------|-----------|----------|
| `react-web` / `react-native` / `typescript` | `npm run lint` / `pnpm lint` / `yarn lint` (add `--fix` in apply mode) | `npx eslint <changed files> [--fix]`; `npx tsc --noEmit` if `tsconfig.json` exists |
| `java-spring` (Java) | `./gradlew checkstyleMain` / `mvn checkstyle:check` | skip with `no_lint_config` if neither is configured |
| `java-spring` (Kotlin) | `./gradlew ktlintCheck` (`ktlintFormat` in apply mode) | skip with `no_lint_config` if not configured |

Always scope the run to changed files / the current chunk, never the whole repo.

## Phase → skills

| Phase | Skill(s) |
|-------|----------|
| lint | project's own lint/typecheck/build tooling (see table above) — no third-party skill needed |
| logic | stack skill from table above; add the matching row from Database skill routing above whenever the diff includes a migration |
| patterns | `.cursor/project-patterns.md`; optional `graphify` |
| deadcode | `dead-code-eliminator` + patterns "Do-not-reinvent" |
| architecture | `architecture-review` (Sentry Warden) + patterns; add the matching row from Database skill routing above whenever the diff includes a migration |
| performance | `performance-optimization`; also Vercel skill on `react-web` / `react-native` |
| security | `security-review` — only if diff touches auth, sessions, crypto, PII, SQL/NoSQL, network, file upload, secrets, SSRF/XSS sinks |
| figma | Cursor Figma skills / MCP (`figma-design-to-code`, `figma-use`) — only after user provides node URLs |
| cross-repo | workspace `graphify-out/`; optional `graphify-labs/graphify@graphify` |

Note: do not create `multi-repo.json` when graphify answers successfully.

## Skill resolution protocol

Two trust tiers, no silent middle ground, for when a stack or task type isn't covered by this map at all:

- **Tier 1 — Curated.** Everything already listed in this file is pre-verified. Used directly, no network call, no question — this is a mechanical table lookup, not a reasoning call.
- **Tier 2 — Edge case.** A stack or task type not covered by this map. The agent **never installs or edits this map on its own**. It may search skills.sh for candidates purely to present them (dispatch this search as a scoped subagent on a cheap/fast model — e.g. `composer-2.5-fast`, `cursor-grok-4.5-high-fast` — so the primary session never reads raw search output, only a compact candidate list), then stops and asks the human:

  > No verified skill for `<stack/task>`. Candidates found: `owner/repo@skill` (installs, audit status), … Install one, provide your own, or continue without (built-in checklist)?

  Whatever the human picks, **the human's decision** is what gets added to the `## Discovered` section below for future runs. The agent does not add third-party entries to this map on its own initiative.

This is a different situation from a mapped skill that simply isn't installed in the current environment — see "If a skill is not installed" below for that case.

## Discovered

Tier-2 additions the human has explicitly approved, so future runs treat them as Tier 1 without re-asking. Empty until the first human-approved addition.

| Stack/task | Skill | Approved by / date |
|------------|-------|---------------------|

## If a skill is not installed

Proceed with built-in checklist in the phase agent. Note in Coverage: `skill_missing: <id>`. Do not block the whole review.
```

- [ ] **Step 2: Verify the new sections**

Run: `grep -c "^## Database skill routing$" skills/engineer-review/references/skill-map.md && grep -c "^## Skill resolution protocol$" skills/engineer-review/references/skill-map.md && grep -c "^## Discovered$" skills/engineer-review/references/skill-map.md && grep -c "Tier.1" skills/engineer-review/references/skill-map.md && grep -c "Tier.2" skills/engineer-review/references/skill-map.md && grep -c "whenever the diff includes a migration" skills/engineer-review/references/skill-map.md`
Expected: `1`, `1`, `1`, `2`, `2`, `3` (the migration-trigger phrase appears in the Database skill routing intro, the `logic` row, and the `architecture` row)

- [ ] **Step 3: Commit**

```bash
git add skills/engineer-review/references/skill-map.md
git commit -m "Add Database skill routing and Skill resolution protocol to skill-map"
```

---

### Task 2: Wire `csp-review-logic` to DB routing and the resolution protocol

**Files:**
- Modify: `agents/csp-review-logic.md:12` (Setup step 1 only)

**Interfaces:**
- Consumes: `skill-map.md`'s Database skill routing and Skill resolution protocol sections (Task 1).

- [ ] **Step 1: Replace Setup step 1**

In `agents/csp-review-logic.md`, change:

```markdown
1. Load the stack skill from engineer-review `skill-map.md` (Vercel React BP, RN, or Java Spring). If missing, use a solid built-in checklist and set `notes` with `skill_missing`.
```

to:

```markdown
1. Load the stack skill from engineer-review `skill-map.md` (Vercel React BP, RN, or Java Spring). If the diff includes a migration (matches `skill-map.md`'s Database skill routing trigger), also load the matching DB skill row. If a mapped skill is missing, use a solid built-in checklist and set `notes` with `skill_missing`. If the stack itself isn't covered by the map at all, follow `skill-map.md`'s Skill resolution protocol — do not install or invent a skill yourself.
```

- [ ] **Step 2: Verify the edit landed**

Run: `grep -c "Database skill routing trigger" agents/csp-review-logic.md && grep -c "Skill resolution protocol" agents/csp-review-logic.md`
Expected: `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add agents/csp-review-logic.md
git commit -m "Wire review-logic to DB skill routing and skill resolution protocol"
```

---

### Task 3: Wire `csp-review-architecture` to DB routing

**Files:**
- Modify: `agents/csp-review-architecture.md:19` (Skills line only)

**Interfaces:**
- Consumes: `skill-map.md`'s Database skill routing section (Task 1).

- [ ] **Step 1: Replace the Skills line**

In `agents/csp-review-architecture.md`, change:

```markdown
Use `architecture-review` (Sentry Warden) if installed; patterns file; optional graphify queries for “what calls what”.
```

to:

```markdown
Use `architecture-review` (Sentry Warden) if installed; patterns file; optional graphify queries for “what calls what”. If the diff includes a migration, also load the matching DB skill row from `skill-map.md`'s Database skill routing.
```

- [ ] **Step 2: Verify the edit landed**

Run: `grep -c "Database skill routing" agents/csp-review-architecture.md`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add agents/csp-review-architecture.md
git commit -m "Wire review-architecture to DB skill routing"
```

---

### Task 4: Add a Hard rule to the orchestrator against inventing skills

**Files:**
- Modify: `agents/csp-engineer-reviewer.md:52` (Hard rules section only)

**Interfaces:**
- Consumes: `skill-map.md`'s Skill resolution protocol section (Task 1).

- [ ] **Step 1: Add the new Hard rule**

In `agents/csp-engineer-reviewer.md`, change:

```markdown
- Never let a heuristic phase hand-edit code to satisfy a lint rule — mechanical style/lint findings belong to `csp-review-lint` and its tool's own auto-fixer.
```

to:

```markdown
- Never let a heuristic phase hand-edit code to satisfy a lint rule — mechanical style/lint findings belong to `csp-review-lint` and its tool's own auto-fixer.
- Never install a third-party skill for a stack/task not covered by `skill-map.md`, or invent one that doesn't exist, on the orchestrator's own initiative — follow its Skill resolution protocol instead (Tier 1: direct lookup; Tier 2: candidate search via a cheap-model subagent is allowed, but adoption is always human-gated).
```

- [ ] **Step 2: Verify the edit landed**

Run: `grep -c "Skill resolution protocol" agents/csp-engineer-reviewer.md`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add agents/csp-engineer-reviewer.md
git commit -m "Add orchestrator hard rule against inventing skills for uncovered stacks"
```

---

### Task 5: Document DB routing and the skill resolution protocol in README

**Files:**
- Modify: `README.md` (one paragraph, after the "Recommended third-party skills" code block)

**Interfaces:**
- Consumes: `skill-map.md`'s Database skill routing and Skill resolution protocol section names (Task 1).

- [ ] **Step 1: Add the paragraph**

In `README.md`, change:

```markdown
# optional:
npx skills add graphify-labs/graphify@graphify
```

## Usage
```

to:

```markdown
# optional:
npx skills add graphify-labs/graphify@graphify
```

Database migrations and schema changes are automatically routed to matching DB skills (MySQL, MongoDB, and conditional Postgres/Flyway/Prisma rows) via [`skill-map.md`](skills/engineer-review/references/skill-map.md)'s Database skill routing section. If a stack isn't covered by the map at all, the kit follows a two-tier skill resolution protocol: curated skills are used directly, anything else is presented to you for an explicit decision — never auto-installed.

## Usage
```

- [ ] **Step 2: Verify the addition landed**

Run: `grep -c "Database skill routing" README.md && grep -c "skill resolution protocol" README.md`
Expected: `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document DB skill routing and skill resolution protocol in README"
```

---

## Self-Review

**1. Spec coverage:** Every element of design spec §4 (Database skill routing: always-on skills, MySQL/MongoDB rows, Postgres/Flyway/Prisma conditional rows, mechanical routing trigger) and §9 (`skill-resolver`: two-tier trust, cost control via cheap-model Tier 2 dispatch, human-gated Discovered additions) is present, all living in `skill-map.md` as the design's own "New/changed artifacts" list specifies (it names only `skill-map.md` additions for this scope — no separate skill-resolver file — so this plan does not create one). The §8 bullet "DB skills from §4 are available to `logic`/`architecture` phases whenever the diff includes a migration" (explicitly deferred out of the `comments-autofix` sub-project) is implemented in Tasks 2 and 3.

**2. Placeholder scan:** No `TBD`/`TODO`/"implement later" text anywhere in the plan's file contents. The `## Discovered` section's empty state is an intentional, documented "empty until first use" table, not an unfinished placeholder.

**3. Type/name consistency:** "Database skill routing", "Skill resolution protocol", and "Discovered" are spelled identically as section headings (Task 1) and as the exact phrases Tasks 2, 3, and 4 reference by name — no paraphrased variants. All `grep` verification counts in this plan were computed against real scratch-file drafts before being written down.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-24-db-routing-skill-resolver.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
