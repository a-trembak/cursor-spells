# Skill map — orchestrator excerpt

Stack detection (+ lint command table) for **`engineer-reviewer`**. Full map (Database skill routing, phase→skills, installer bash fence, Tier-2 protocol): [`skill-map.md`](skill-map.md). Phases and `csp install` load the full map; orchestrator does **not** paste Database/checklist bodies from the full map into its own context.

Recommended installs and Database skill ids stay in [`skill-map.md`](skill-map.md) (source of truth for `scripts/mapped-third-party-skills.sh`).

## Stack detection → skills

| Signal | Stack label | Skills for logic / perf |
|--------|-------------|-------------------------|
| `package.json` with `react-native` / `expo` | `react-native` | `vercel-react-native-skills`; Callstack RN BP if installed |
| `package.json` with `react` / `next` / `react-dom` | `react-web` | `vercel-react-best-practices` |
| `tsconfig.json` + TS sources without React | `typescript` | `vercel-react-best-practices` only if UI; else general TS review without Vercel UI rules |
| `pom.xml` / `build.gradle*` / `*.java` + Spring deps | `java-spring` | `java-springboot` |
| Mixed monorepo | detect per changed path | pick skill per package touched by the diff |

Pass the stack label into phase inputs. Phases load matching skills (and Database rows when the diff includes a migration) from the [full skill-map](skill-map.md#database-skill-routing).

## Stack detection → lint/typecheck commands (for `review-lint`)

Prefer the project's own `package.json` script over calling the binary directly.

| Stack | Preferred | Fallback |
|-------|-----------|----------|
| `react-web` / `react-native` / `typescript` | `npm run lint` / `pnpm lint` / `yarn lint` (add `--fix` in apply mode) | `npx eslint <changed files> [--fix]`; `npx tsc --noEmit` if `tsconfig.json` exists |
| `java-spring` (Java) | `./gradlew checkstyleMain` / `mvn checkstyle:check` | skip with `no_lint_config` if neither is configured |
| `java-spring` (Kotlin) | `./gradlew ktlintCheck` (`ktlintFormat` in apply mode) | skip with `no_lint_config` if not configured |

Always scope the run to changed files / the current chunk, never the whole repo.

## Skill resolution (orchestrator)

Never install a third-party skill for a stack/task not covered by [`skill-map.md`](skill-map.md), or invent one that doesn't exist, on the orchestrator's own initiative — follow that file's Skill resolution protocol (Tier 1: direct lookup; Tier 2: candidate search via a cheap-model subagent is allowed, but adoption is always human-gated). Missing mapped skill → phases proceed with built-in checklist; Coverage notes `skill_missing: <id>`.
