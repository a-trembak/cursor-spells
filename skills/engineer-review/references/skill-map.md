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

## Phase → skills

| Phase | Skill(s) |
|-------|----------|
| logic | stack skill from table above |
| patterns | `.cursor/project-patterns.md`; optional `graphify` |
| deadcode | `dead-code-eliminator` + patterns “Do-not-reinvent” |
| architecture | `architecture-review` (Sentry Warden) + patterns |
| performance | `performance-optimization`; also Vercel skill on `react-web` / `react-native` |
| security | `security-review` — only if diff touches auth, sessions, crypto, PII, SQL/NoSQL, network, file upload, secrets, SSRF/XSS sinks |
| figma | Cursor Figma skills / MCP (`figma-design-to-code`, `figma-use`) — only after user provides node URLs |
| cross-repo | workspace `graphify-out/`; optional `graphify-labs/graphify@graphify` |

Note: do not create `multi-repo.json` when graphify answers successfully.

## If a skill is not installed

Proceed with built-in checklist in the phase agent. Note in Coverage: `skill_missing: <id>`. Do not block the whole review.
