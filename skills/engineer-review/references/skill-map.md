# Skill map

Canonical stack → skill routing for **`software-developer`** (while writing code) and **`engineer-review`** phases (while reviewing). Same table, two consumers.

Recommended installs (consumer machine / project). Do not vendor skill bodies into cursor-spells.

```bash
npx skills add vercel-labs/agent-skills@vercel-react-best-practices
npx skills add vercel-labs/agent-skills@vercel-react-native-skills
npx skills add github/awesome-copilot@java-springboot
npx skills add affaan-m/everything-claude-code@security-review
npx skills add addyosmani/agent-skills@performance-optimization
npx skills add getsentry/warden@architecture-review
npx skills add abpai/skills@dead-code-eliminator
# simplify phase primary (compound-engineering Cursor plugin):
# ce-simplify-code under ~/.cursor/plugins/.../skills/ce-simplify-code
# preferred when graphify-out/ exists (optional install):
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

## Stack detection → lint/typecheck commands (for `review-lint`)

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
| patterns | `.cursor/project-patterns.md`; prefer `graphify` when `graphify-out/` or CLI available ([graphify-protocol.md](graphify-protocol.md)) |
| deadcode | `dead-code-eliminator` + patterns "Do-not-reinvent"; prefer graphify callers when available |
| simplify | **Primary:** compound-engineering `ce-simplify-code` (read SKILL + `references/personas/{code-reuse,code-quality,efficiency}-reviewer.md` verbatim), then **always** [simplify-checklist.md](simplify-checklist.md) **Kit extensions**. **Fallback** if skill missing: Lens A–C + Kit extensions + note `skill_missing: ce-simplify-code`. Prefer graphify callers when available |
| architecture | `architecture-review` (Sentry Warden) + patterns; prefer graphify call/impact queries when available; add the matching row from Database skill routing above whenever the diff includes a migration |
| performance | `performance-optimization`; also Vercel skill on `react-web` / `react-native`; prefer graphify impact neighborhood when available |
| security | `security-review` — only if diff touches auth, sessions, crypto, PII, SQL/NoSQL, network, file upload, secrets, SSRF/XSS sinks |
| figma | Cursor Figma skills / MCP (`figma-design-to-code`, `figma-use`) — only after user provides node URLs; on `react-web` also `ce-test-browser` (rendered UI vs Figma) |
| learn | [review-learn-protocol.md](review-learn-protocol.md) + kit [learned-misses.md](learned-misses.md) + consumer `.cursor/review-learnings.md` — no third-party skill |
| cross-repo | workspace `graphify-out/`; prefer `graphify-labs/graphify@graphify` when available (optional install) |

Note: do not create `multi-repo.json` when graphify answers successfully. Graphify is never required — absent/unqueryable keeps the git-diff + chunk path.

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
