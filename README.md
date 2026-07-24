# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## How to install on a project

**Do not clone this repo into every app.** Keep **one** checkout of `cursor-spells`, then run the CLI against each project.

```bash
# 1) Clone the kit once (anywhere stable)
git clone https://github.com/a-trembak/cursor-spells.git ~/cursor-spells

# 2) Install into a project (+ link skills/commands/agents into ~/.cursor)
~/cursor-spells/bin/csp install /path/to/your-app

# From inside the app:
csp install .                 # if bin/ is on PATH
csp install . --humanizer
csp install --user-only
```

Optional PATH helper:

```bash
echo 'export PATH="$HOME/cursor-spells/bin:$PATH"' >> ~/.bashrc   # or ~/.zshrc
csp install ~/code/my-app
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
bin/         CLI (`csp install …` — short alias of cursor-spells)
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
| [`implementation-critic`](skills/implementation-critic/) | Pre-code plan audit — complexity/YAGNI lens + risk/migration lens, must-fix/should-fix/accept-risk |
| [`tech-spec`](skills/tech-spec/) | Developer technical action plan — Blocker/Decision/Assumption question protocol, English-only file |
| [`code-comments`](skills/code-comments/) | Keep/remove taxonomy for comments — shared by developers and `review-deadcode` |
| [`start-build`](skills/start-build/) | Pre-build gate — auto-runs `implementation-critic` before Task 1, HITL only if findings block |

## Agents

| Agent | Role |
|-------|------|
| `engineer-reviewer` | Orchestrator — dispatches phase agents, merges Fixed / Clarify |
| `review-lint` | Runs real project tooling (eslint/tsc/checkstyle/…) — catches mechanical rule violations heuristic phases miss |
| `review-logic` | Correctness + stack best practices |
| `review-patterns` | Project patterns MD (create/enforce) |
| `review-deadcode` | Dead code, redundancy, comment cleanup |
| `review-architecture` | Architecture gaps |
| `review-performance` | Performance |
| `review-security` | Security (conditional) |
| `review-figma-markup` | Markup vs Figma (needs node URLs) |
| `multi-repo-supervisor` | Supervises engineer-review across 2+ changed repositories |
| `review-cross-repo` | Reports cross-repo contract drift as clarification-only findings |
| `implementation-critic` | Audits a plan before code — complexity (Pass A) + risk (Pass B) lenses, read-only |
| `tech-spec` | Drafts/structures the technical action plan pre-plan — asks one question at a time, never invents business facts |

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

Database migrations and schema changes are automatically routed to matching DB skills (MySQL, MongoDB, and conditional Postgres/Flyway/Prisma rows) via [`skill-map.md`](skills/engineer-review/references/skill-map.md)'s Database skill routing section. If a stack isn't covered by the map at all, the kit follows a two-tier skill resolution protocol: curated skills are used directly, anything else is presented to you for an explicit decision — never auto-installed.

## Usage

### English humanizer

- `@english-humanizer` / ask to humanize a PR comment or problem description

### Finish plan → HITL → engineer review

1. When a plan is done: `/finish-plan`
2. Answer `skip` / `approve` / `done`
3. On frontend, paste Figma node URLs or `no figma`
4. Orchestrator runs phases; applies **P0/P1** unambiguous fixes; lists clarifications separately

Comment cleanup and apply-vs-clarify decisions across all review phases now follow a strict [auto-fix eligibility test](skills/engineer-review/references/auto-fix-eligibility.md): a finding is only auto-applied if it's deterministic, has a single correct answer, loses no information, and has zero blast radius on data or user-facing behavior — otherwise it's always `clarify`, regardless of severity.

**Manual review:** `/engineer-review`

### Start a task (full pipeline)

`/start-task [ac-source]` orchestrates the whole pipeline end-to-end, stopping only at the human-in-the-loop (HITL) gates that already exist — it never skips or softens any of them:

1. Bootstraps context (project patterns, stack) — automatic
2. Runs `tech-spec` — **HITL** at the entry question, any Blocker/Decision question, and `approve-spec`/`revise`/`skip`
3. Generates the implementation plan via `writing-plans` — automatic once the spec's `Status` is `approved` or explicitly `skip`ped
4. Runs the pre-build critique gate (`/start-build`, below) — automatic start, **HITL** only if findings block
5. Executes the plan via `subagent-driven-development` — automatic, no "which approach?" prompt in this flow
6. `/finish-plan` — **HITL** `skip`/`approve`/`done`
7. `engineer-review` — **HITL** only for clarifications it raises

A Jira/tracker URL works as the AC source, recorded as a reference — this kit does not fetch ticket contents via an API.

Prefer `/write-tech-spec [ac-source]` directly if you only want the tech spec, without triggering the rest of the pipeline.

### Pre-build critique gate

`/start-build [path]` (or the `start-build` skill, auto-invoked by `/start-task`) always runs `implementation-critic` before Task 1 of a plan is dispatched — no permission needed to start the critique itself, since it's read-only. If `Verdict` comes back `blocked` or `clear pending accept`, it stops and waits for a plan revision or `accept F<id>` replies before execution begins.

### Critique a plan before coding

`/critique-plan [path]` audits an implementation plan for unnecessary complexity, abstraction violations, missing risk coverage, and scope drift — before a developer starts implementing it. If the report's `Verdict` is not `clear`, revise the plan or reply `accept F<id>` for a specific finding, then re-run.

For work spanning multiple sibling repos, see [Multi-repo review](#multi-repo-review).

### Multi-repo review

Use multi-repo review when a task changes **2+ sibling repositories**. If routing finds no changed repos, it stops with a message; if it finds one changed repo, the normal single-repo `engineer-reviewer` path runs unchanged.

- Explicit `/multi-review` paths are the repo set for that run. Without explicit paths, discovery prefers graphify at the workspace parent, then existing parent `.cursor/multi-repo.json`, then a sibling scan.
- `finish-plan` routing uses a non-mutating probe; parent `.cursor/multi-repo.json` is written only for a confirmed multi-repo run without graphify, or when `/multi-review --refresh` explicitly asks for it. It is never written inside a single leaf repo.
- Commands:
  - `/multi-review [path ...] [--refresh]` runs the multi-repo routing manually. Explicit paths override discovery for that run.
  - `/finish-plan` auto-routes after HITL approval: single-repo tasks use `engineer-reviewer`; multi-repo tasks use `multi-repo-supervisor`.
- Cross-repo contract drift is clarify-only in v1 (`C_CR*`); it is not auto-applied or listed under Fixed now.
- Jira/Linear ticket-driven discovery is deferred to v1.1. v1 routing uses explicit `/multi-review` paths, graphify, parent `.cursor/multi-repo.json`, or sibling scan.

Design: [`docs/superpowers/specs/2026-07-22-multi-repo-supervisor-design.md`](docs/superpowers/specs/2026-07-22-multi-repo-supervisor-design.md)

**First run** writes `.cursor/project-patterns.md` in the consumer repo.

**Patterns CI (optional):** `scripts/check-project-patterns.sh --strict`  
Workflow template: [`scripts/templates/project-patterns.yml`](scripts/templates/project-patterns.yml)

**Dogfood checklist:** [`docs/superpowers/dogfood/engineer-review-checklist.md`](docs/superpowers/dogfood/engineer-review-checklist.md)

Design: [`docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md`](docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md)

## License

MIT — steal freely, please sound human.
