# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## Install & update

**Do not clone this repo into every app.** Keep **one** checkout of `cursor-spells`, then point each project at it.

### First-time install

```bash
# 1) Clone the kit once
git clone https://github.com/a-trembak/cursor-spells.git ~/cursor-spells

# 2) Optional: put `csp` on PATH
echo 'export PATH="$HOME/cursor-spells/bin:$PATH"' >> ~/.bashrc   # or ~/.zshrc
source ~/.bashrc

# 3) Install into a project (path optional when already inside the repo / multi-repo)
csp install /path/to/your-app
cd /path/to/your-app && csp install          # same — path defaults to this repo
cd /path/to/multi-repo-workspace && csp update
```

Useful flags: `--humanizer` (also link `english-humanizer`), `--user-only` (only `~/.cursor`, no project files), `--copy` (copy instead of symlink).

**Why `--user-only` agents may not show in Cursor**

`--user-only` only creates links under `~/.cursor/agents/` (user-global). They are **not** a separate “Custom Agents” product mode — they are **subagents** (`@engineer-reviewer`, `@pr-reviewer`, …). After install: **Reload Window**. Cursor **CLI** completions often list only `<project>/.cursor/agents/` — for agents that always appear in the open project, run `csp install` / `csp update` **without** `--user-only` (that also mirrors agents into the project).

Check: `ls -la ~/.cursor/agents` and (after full install) `ls -la .cursor/agents`.

### Update (kit + links)

```bash
csp update /path/to/your-app   # git pull the kit, then re-sync ~/.cursor + project files
cd /path/to/your-app && csp update   # path optional — current repo / workspace
csp install --user-only        # ~/.cursor only (also: csp update --user-only)
csp status                     # kit path, commit, what is linked
```

**Default project when path is omitted**

1. Git toplevel of the current directory (works inside a leaf repo of a multi-repo)
2. Else cwd if it has `.cursor/multi-repo.json` or `graphify-out/`
3. Else cwd if it contains 2+ immediate child git repos (workspace parent)
4. Else error — pass a path or `--user-only`

Installing into the `cursor-spells` kit checkout itself is refused.
With **symlink** mode (default), `git pull` in the kit already refreshes skill/command/agent *contents*; `csp update` still matters to **add new** skills/commands/agents and to **refresh** project hooks/rules. With `--copy`, `csp update` is required to refresh copied bodies.

### What install creates

Two places: **Cursor user dir** (`~/.cursor`) and **the project**.

#### A) `~/.cursor/` (always on `install` / `update`)

| Path | Action |
|------|--------|
| `~/.cursor/skills/<name>` | Symlink → `<kit>/skills/<name>` for every skill in the kit (`english-humanizer` only with `--humanizer` or if already present) |
| `~/.cursor/commands/<file>.md` | Symlink → `<kit>/commands/…` (all slash commands) |
| `~/.cursor/agents/<file>.md` | Symlink → `<kit>/agents/…` (all agents, including `review-*`) |
| `~/.cursor/cursor-spells-kit-path` | Text file with absolute path to this kit checkout |

Directories `skills/`, `commands/`, `agents/` are created if missing. Existing **foreign** files/symlinks are never overwritten.

#### B) `<project>/` (path argument, or auto-detected cwd repo / multi-repo workspace)

| Path | Action |
|------|--------|
| `<project>/.cursor/skills|commands|agents/` | Same kit entries as in `~/.cursor` (so this project’s Cursor UI/CLI sees them) |
| `<project>/.cursor/hooks/post-plan-review-gate.sh` | Copied from kit (refreshed on every install/update) |
| `<project>/.cursor/hooks/pre-build-gate.sh` | Copied from kit (refreshed on every install/update) |
| `<project>/.cursor/hooks.json` | Created if missing; **refreshed on `update`** |
| `<project>/.cursor/rules/after-plan-review-gate.mdc` | Copied / refreshed |
| `<project>/.cursor/rules/before-build-critique-gate.mdc` | Copied / refreshed |
| `<project>/.cursor/cursor-spells-kit-path` | Absolute path to the kit |
| `<project>/scripts/check-project-patterns.sh` | Optional CI helper — created once, refreshed on `update` |

Also ensures `<project>/.cursor/`, `.cursor/hooks/`, `.cursor/rules/`, and `scripts/` exist.

Runtime markers the agents write later (not created by install): e.g. `.cursor/plan-gate.pending`, `.cursor/critique-gate.pending`, `.cursor/plan-critique.clear`, `.cursor/review-gate.pending`, `.cursor/project-patterns.md`.

### What update does (step by step)

1. `git pull --ff-only` inside the kit checkout (skips if no upstream).
2. Re-walks every kit `skills/*`, `commands/*.md`, `agents/*.md` and links/copies any **new** entries into `~/.cursor` (relinks owned symlinks).
3. If a project is targeted (explicit path or auto-detected cwd): refreshes hook scripts, rules, `hooks.json`, and the patterns helper as in the table above.

```
~/cursor-spells/          ← one clone (source of truth)
        │
        │  csp install / update
        ▼
~/.cursor/skills|commands|agents/   ← symlinks into the kit
your-app/.cursor/hooks|rules/       ← copies of gate hooks & rules
```

## Layout

```
bin/         CLI (`csp` → install / update / status)
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
| [`start-build`](skills/start-build/) | Thin build handoff — requires critique-clear plan, then `software-developer` (no critic here) |
| [`approve-plan`](skills/approve-plan/) | HITL approve/revise the plan, then auto-run `implementation-critic`; on clear → `start-build` |
| [`pr-review`](skills/pr-review/) | PR-entry wrapper around engineer-review — snippets + file links + humanizer prose; default report-only |
| [`software-developer`](skills/software-developer/) | Implements a cleared plan — feature branch(es) in target repo(s), skill-map routing, code-comments, verify-before-handoff; web UI vs Figma via `ce-test-browser` |

## Agents

| Agent | Role |
|-------|------|
| `software-developer` | Feature branch(es) then code to tech spec + plan after critic clear — routes skills, verifies; web → browser vs Figma |
| `engineer-reviewer` | Orchestrator — dispatches phase agents, merges Fixed / Clarify |
| `pr-reviewer` | Same phases as engineer-reviewer; PR feedback with code snippets, clickable links, humanized prose |
| `review-lint` | Runs real project tooling (eslint/tsc/checkstyle/…) — catches mechanical rule violations heuristic phases miss |
| `review-logic` | Correctness + stack best practices |
| `review-patterns` | Project patterns MD (create/enforce) |
| `review-deadcode` | Dead code, redundancy, comment cleanup |
| `review-architecture` | Architecture gaps |
| `review-performance` | Performance |
| `review-security` | Security (conditional) |
| `review-figma-markup` | Markup vs Figma (needs node URLs); on web also `ce-test-browser` |
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
npx skills add everyinc/compound-engineering-plugin@ce-test-browser
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
**PR review:** `/pr-review [url|number|branch] [apply] [no-figma]` — same phase pipeline on a pull-request diff; findings include code snippets + file/GitHub links and are passed through `english-humanizer`; report-only unless `apply`.

### Start a task (full pipeline)

`/start-task [ac-source]` orchestrates the whole pipeline end-to-end, stopping only at the human-in-the-loop (HITL) gates that already exist — it never skips or softens any of them:

1. Bootstraps context (project patterns, stack) — automatic
2. Runs `tech-spec` — **HITL** at the entry question, any Blocker/Decision question, and `approve-spec`/`revise`/`skip`
3. Generates the implementation plan via `writing-plans` — automatic once the spec's `Status` is `approved` or explicitly `skip`ped
4. `/approve-plan` — **HITL** `approve-plan`/`revise`, then **automatic** `implementation-critic`; **HITL** only if findings block; on `Verdict: clear` → `start-build`
5. Executes via `software-developer` (branch setup in target repo(s) → skill-map routing → `subagent-driven-development`) — automatic, no "which approach?" prompt in this flow
6. `/finish-plan` — **HITL** `skip`/`approve`/`done`
7. `engineer-review` — **HITL** only for clarifications it raises

A Jira/tracker URL works as the AC source, recorded as a reference — this kit does not fetch ticket contents via an API.

Prefer `/write-tech-spec [ac-source]` directly if you only want the tech spec, without triggering the rest of the pipeline.

### Approve plan → critic → build

`/approve-plan [path]` is the plan gate: the human reads the plan (`approve-plan` / `revise`), then `implementation-critic` runs **automatically** (no HITL to start it). On `Verdict: clear` it writes `.cursor/plan-critique.clear` and invokes `/start-build`. On `blocked` / `clear pending accept`, it stops for a revision or `accept F<id>`.

`/start-build [path]` no longer runs the critic — it only starts `software-developer` when `.cursor/plan-critique.clear` matches the plan.

### Critique a plan before coding

`/critique-plan [path]` audits an implementation plan ad-hoc (complexity, risk, scope drift). Prefer `/approve-plan` in the pipeline so plan HITL is not skipped. If the report's `Verdict` is not `clear`, revise the plan or reply `accept F<id>` for a specific finding, then re-run.

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
