# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## Layout

```
skills/      Agent skills (SKILL.md)
commands/    Cursor slash commands
rules/       Persistent rules
hooks/       Cursor hooks (templates for consumer projects)
agents/      Custom agent configs
docs/        Design specs and plans
```

## Skills

| Skill | What it does |
|-------|----------------|
| [`english-humanizer`](skills/english-humanizer/) | Strip AI tells from English bug reports, colleague messages, and PR comments |
| [`engineer-review`](skills/engineer-review/) | Multi-phase review orchestrator (HITL after plans, stack-aware subagents) |

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

## Install (symlink into Cursor)

From this repo:

```bash
# Skills
ln -s "$(pwd)/skills/english-humanizer" ~/.cursor/skills/english-humanizer
ln -s "$(pwd)/skills/engineer-review" ~/.cursor/skills/engineer-review

# Slash commands
mkdir -p ~/.cursor/commands
ln -s "$(pwd)/commands/engineer-review.md" ~/.cursor/commands/engineer-review.md

# Agents (user-level)
mkdir -p ~/.cursor/agents
ln -s "$(pwd)/agents/engineer-reviewer.md" ~/.cursor/agents/engineer-reviewer.md
ln -s "$(pwd)/agents"/review-*.md ~/.cursor/agents/

# Rules (optional user-level, or copy into each project .cursor/rules/)
mkdir -p ~/.cursor/rules
ln -s "$(pwd)/rules/after-plan-review-gate.mdc" ~/.cursor/rules/after-plan-review-gate.mdc
```

Or copy instead of symlink if you prefer.

### Per-project hook (optional)

Hooks that should run inside a consumer repo must live at **that** project's `.cursor/hooks.json` (cloud agents only read project hooks).

```bash
# from a consumer project root
mkdir -p .cursor/hooks
cp /path/to/cursor-spells/hooks/hooks.json .cursor/hooks.json
cp /path/to/cursor-spells/hooks/post-plan-review-gate.sh .cursor/hooks/
chmod +x .cursor/hooks/post-plan-review-gate.sh
```

The stop hook only **reminds** about HITL when `.cursor/review-gate.pending` exists — it never auto-starts review.

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

### Engineer review

**Manual:** `/engineer-review`

**After a plan:** agent stops and asks whether you want your own review first (`skip` / `approve` / `done`). Only then runs `engineer-reviewer`.

**First run in a project** writes `.cursor/project-patterns.md` so later reviews reuse naming/structure conventions instead of rediscovering them.

**Output:**

1. **Fixed now** — unambiguous fixes already applied  
2. **Needs clarification** — questions; reply `C1: A` etc. to continue

Design: [`docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md`](docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md)

## License

MIT — steal freely, please sound human.
