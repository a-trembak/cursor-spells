# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## Layout

```
skills/      Agent skills (SKILL.md)
commands/    Cursor slash commands
rules/       Persistent rules (install per project)
hooks/       Cursor hooks (templates for consumer projects)
agents/      Custom agent configs
scripts/     Install + CI helpers
docs/        Design specs, plans, dogfood checklists
```

## Skills

| Skill | What it does |
|-------|----------------|
| [`english-humanizer`](skills/english-humanizer/) | Strip AI tells from English bug reports, colleague messages, and PR comments |
| [`finish-plan`](skills/finish-plan/) | Reliable plan→HITL handoff (writes review-gate marker, then asks) |
| [`engineer-review`](skills/engineer-review/) | Multi-phase review orchestrator (stack-aware subagents, P0–P2, chunking) |

## Agents

| Agent | Role |
|-------|------|
| `engineer-reviewer` | Orchestrator — dispatches phase agents, merges Fixed / Clarify |
| `review-logic` | Correctness + stack best practices |
| `review-patterns` | Project patterns MD (create/enforce) |
| `review-deadcode` | Dead code, redundancy, comment cleanup |
| `review-architecture` | Architecture gaps |
| `review-performance` | Performance |
| `review-security` | Security (conditional) |
| `review-figma-markup` | Markup vs Figma (needs node URLs) |

## Install

### One-shot (recommended)

```bash
chmod +x scripts/*.sh
./scripts/install-to-project.sh /path/to/your-app
# links skills/commands/agents into ~/.cursor
# copies hooks + project-scoped rule + patterns check script into the app
```

Flags: `--user-only`, `--hooks`, `--rule`, `--humanizer`, `--copy` (instead of symlink).

### Manual symlinks

```bash
ln -s "$(pwd)/skills/engineer-review" ~/.cursor/skills/engineer-review
ln -s "$(pwd)/skills/finish-plan" ~/.cursor/skills/finish-plan
mkdir -p ~/.cursor/commands ~/.cursor/agents
ln -s "$(pwd)/commands/engineer-review.md" ~/.cursor/commands/engineer-review.md
ln -s "$(pwd)/commands/finish-plan.md" ~/.cursor/commands/finish-plan.md
ln -s "$(pwd)/agents/engineer-reviewer.md" ~/.cursor/agents/engineer-reviewer.md
ln -s "$(pwd)/agents"/review-*.md ~/.cursor/agents/
```

**Rule:** copy into the **consumer** project (`.cursor/rules/`), not user-global `alwaysApply`. The kit rule uses `alwaysApply: false` + plan globs; `finish-plan` is the reliable gate.

**Hooks:** must live in the consumer `.cursor/hooks.json` (see install script).

### Recommended third-party skills

```bash
npx skills add vercel-labs/agent-skills@vercel-react-best-practices
npx skills add vercel-labs/agent-skills@vercel-react-native-skills
npx skills add github/awesome-copilot@java-springboot
npx skills add affaan-m/everything-claude-code@security-review
npx skills add addyosmani/agent-skills@performance-optimization
npx skills add getsentry/warden@architecture-review
npx skills add abpai/skills@dead-code-eliminator
# optional:
npx skills add graphify-labs/graphify@graphify
```

## Usage

### English humanizer

- `@english-humanizer` / ask to humanize a PR comment or problem description

### Finish plan → HITL → engineer review

1. When a plan is done: `/finish-plan` (or skill `finish-plan`)
2. Answer `skip` / `approve` / `done`
3. On frontend, paste Figma node URLs or `no figma`
4. Orchestrator runs phases; applies **P0/P1** unambiguous fixes; lists clarifications separately
5. Large diffs (>40 files or >2500 LOC) are **chunked** by package/dir

**Manual review:** `/engineer-review` (skips HITL)

**First run** writes `.cursor/project-patterns.md` in the consumer repo.

**Patterns CI (optional):** `scripts/check-project-patterns.sh --strict`  
Workflow template: [`scripts/templates/project-patterns.yml`](scripts/templates/project-patterns.yml)

**Dogfood checklist:** [`docs/superpowers/dogfood/engineer-review-checklist.md`](docs/superpowers/dogfood/engineer-review-checklist.md)

Design: [`docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md`](docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md)

## License

MIT — steal freely, please sound human.
