# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## How to install on a project

**Do not clone this repo into every app.** Keep **one** checkout of `cursor-spells`, then run the CLI against each project.

```bash
# 1) Clone the kit once (anywhere stable)
git clone https://github.com/a-trembak/cursor-spells.git ~/cursor-spells

# 2) Install into a project (+ link skills/commands/agents into ~/.cursor)
~/cursor-spells/bin/cursor-spells install /path/to/your-app

# From inside the app:
~/cursor-spells/bin/cursor-spells install .

# Optional: also english-humanizer
~/cursor-spells/bin/cursor-spells install . --humanizer

# Only global Cursor bits (no project hooks/rule):
~/cursor-spells/bin/cursor-spells install --user-only
```

Optional PATH helper:

```bash
echo 'export PATH="$HOME/cursor-spells/bin:$PATH"' >> ~/.bashrc   # or ~/.zshrc
cursor-spells install ~/code/my-app
```

What gets installed:

| Target | What |
|--------|------|
| `~/.cursor/skills/`, `commands/`, `agents/` | Symlinks into the kit (updates follow `git pull` in the kit) |
| `<project>/.cursor/hooks.json` + `hooks/` | HITL stop-hook reminder |
| `<project>/.cursor/rules/after-plan-review-gate.mdc` | Plan→review gate (project-scoped) |
| `<project>/scripts/check-project-patterns.sh` | Optional patterns CI helper |

Use `--copy` if you cannot symlink (copies into `~/.cursor`; re-run after kit updates).

## Layout

```
bin/         CLI (`cursor-spells install …`)
skills/      Agent skills (SKILL.md)
commands/    Cursor slash commands
rules/       Persistent rules (install per project)
hooks/       Cursor hooks (templates for consumer projects)
agents/      Custom agent configs
scripts/     Install internals + CI helpers
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

## Recommended third-party skills

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

1. When a plan is done: `/finish-plan`
2. Answer `skip` / `approve` / `done`
3. On frontend, paste Figma node URLs or `no figma`
4. Orchestrator runs phases; applies **P0/P1** unambiguous fixes; lists clarifications separately

**Manual review:** `/engineer-review`

**First run** writes `.cursor/project-patterns.md` in the consumer repo.

**Patterns CI (optional):** `scripts/check-project-patterns.sh --strict`  
Workflow template: [`scripts/templates/project-patterns.yml`](scripts/templates/project-patterns.yml)

**Dogfood checklist:** [`docs/superpowers/dogfood/engineer-review-checklist.md`](docs/superpowers/dogfood/engineer-review-checklist.md)

Design: [`docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md`](docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md)

## License

MIT — steal freely, please sound human.
