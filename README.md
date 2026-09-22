# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## Developing this kit (no pipeline dogfood)

When the workspace **is** this repository, do **not** run `/csp-start-task`, `/csp-start-issue-task`, or ask Pipeline route to ship kit changes — that recurses the pipeline onto itself. Edit kit files directly; use ordinary branches and draft pull requests. Rule: [`rules/kit-no-pipeline-dogfood.mdc`](rules/kit-no-pipeline-dogfood.mdc) (kit-only; not copied by `csp install`). Manual checklists under [`docs/superpowers/dogfood/`](docs/superpowers/dogfood/) remain the way to verify kit behavior.

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

Useful flags: `--humanizer` (also link `english-humanizer`), `--user-only` (only `~/.cursor`, no project files), `--copy` (copy instead of symlink), `--skip-third-party-skills` (do not run `npx skills add` for mapped third-party skills; same as `CSP_SKIP_THIRD_PARTY_SKILLS=1` on air-gapped machines).

**Why `--user-only` agents may not show in Cursor**

`--user-only` only creates links under `~/.cursor/agents/` (user-global). They are **not** a separate “Custom Agents” product mode — they are **subagents** (`@csp-engineer-reviewer`, `@csp-pr-reviewer`, …). After install: **Reload Window**. Cursor **CLI** completions often list only `<project>/.cursor/agents/` — for agents that always appear in the open project, run `csp install` / `csp update` **without** `--user-only` (that also mirrors agents into the project).

Check: `ls -la ~/.cursor/agents` and (after full install) `ls -la .cursor/agents`.

### Update (kit + links)

```bash
csp update /path/to/your-app   # git pull the kit, then re-sync ~/.cursor + project files
cd /path/to/your-app && csp update   # path optional — current repo / workspace
csp update                     # git pull + refresh ~/.cursor only (when cwd is not a project)
csp install --user-only        # ~/.cursor only (also: csp update --user-only)
csp status                     # kit path, commit, what is linked
```

**Default project when path is omitted**

1. Git toplevel of the current directory (works inside a leaf repo of a multi-repo)
2. Else cwd if it has `.cursor/multi-repo.json` or `graphify-out/`
3. Else cwd if it contains 2+ immediate child git repos (workspace parent)
4. Else: `csp update` refreshes `~/.cursor` only; `csp install` errors — pass a path or `--user-only`

Installing into the `cursor-spells` kit checkout itself is refused on `install`. On `update`, that case also falls back to refreshing `~/.cursor` only.
With **symlink** mode (default), `git pull` in the kit already refreshes skill/command/agent *contents*; `csp update` still matters to **add new** skills/commands/agents and to **refresh** project hooks/rules. With `--copy`, `csp update` is required to refresh copied bodies.

### What install creates

Two places: **Cursor user dir** (`~/.cursor`) and **the project**.

#### A) `~/.cursor/` (always on `install` / `update`)

| Path | Action |
|------|--------|
| `~/.cursor/skills/<name>` | Symlink → `<kit>/skills/<name>` for every skill in the kit (`english-humanizer` only with `--humanizer` or if already present) |
| `~/.cursor/commands/<file>.md` | Symlink → `<kit>/commands/…` (all slash commands) |
| `~/.cursor/agents/<file>.md` | Symlink → `<kit>/agents/…` (all agents, including `review-*`) |
| `~/.cursor/rules/plain-language-chat.mdc` | Copied / refreshed — always-on full-words chat (pipeline gate rules stay project-only) |
| `~/.cursor/rules/code-via-coding-agents.mdc` | Copied / refreshed — parent chat must dispatch `csp-software-developer` / `csp-bug-fixer` for product code |
| `~/.cursor/cursor-spells-kit-path` | Text file with absolute path to this kit checkout |
| `~/.cursor/cursor-spells-learn.json` | Created if missing — `land` (`draft_merge` default / `auto_push`); never overwritten on update |
| mapped third-party skills (`npx skills add`) | Curated ids from [`skill-map.md`](skills/engineer-review/references/skill-map.md); skip with `--skip-third-party-skills` / `CSP_SKIP_THIRD_PARTY_SKILLS=1`; `npx` failure is `skill_missing`, not a failed kit install |

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
| `<project>/.cursor/rules/clean-decision-docs.mdc` | Copied / refreshed — specs/plans stay final-form (no revision archaeology) |
| `<project>/.cursor/rules/hitl-askquestion.mdc` | Copied / refreshed — closed-set HITL must call AskQuestion first |
| `<project>/.cursor/rules/plain-language-chat.mdc` | Copied / refreshed — chat with the human uses full words, never abbreviations |
| `<project>/.cursor/rules/code-via-coding-agents.mdc` | Copied / refreshed — parent chat must dispatch coding agents for product code |
| `<project>/.cursor/cursor-spells-kit-path` | Absolute path to the kit |
| `<project>/.cursor/cursor-spells-learn.json` | Created if missing — same template; never overwritten on update. Project `land` wins over the user file |
| `<project>/scripts/check-project-patterns.sh` | Optional CI helper — created once, refreshed on `update` |
| `<project>/scripts/extract-review-snippet.sh` | Helper for review evidence backfill (always refreshed) |
| `<project>/scripts/validate-review-report.sh` | Rejects Verdict/Blockers digests missing File/Jump/snippet (always refreshed) |
| `<project>/scripts/pipeline-gates.sh` | Per-plan gate helper — always refreshed |
| `<project>/scripts/pipeline-status.sh` | Orientation resolver — always refreshed |
| `<project>/scripts/pipeline-run-log.sh` | Pipeline run journal helper — always refreshed; recommend gitignore `.cursor/gates/run-log/` |
| `<project>/scripts/jira-issue.sh` | Jira key / URL / type classifier — always refreshed |

Also ensures `<project>/.cursor/`, `.cursor/hooks/`, `.cursor/rules/`, and `scripts/` exist.

Runtime markers the agents write later (not created by install): `.cursor/gates/<kind>/<slug>` for `plan-gate`, `critique-gate`, `plan-critique-clear`, `review-gate`, `docs-gate` (legacy flat `.cursor/*.pending` / `plan-critique.clear` migrate-on-read), optional `.cursor/gates/run-log/` journals (gitignore recommended), plus `.cursor/project-patterns.md`. Stop hooks follow up only when the current plan path is known; they stay silent if the path is missing so a foreign slug cannot loop another chat.

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
evals/       Kit-only golden sets (trajectories, harness reports, code-quality) — not installed into apps
```

## Skills

| Skill | What it does |
|-------|----------------|
| [`hitl-choice`](skills/hitl-choice/) | HITL UX — AskQuestion (or alias) required first; typed tokens only after failed/missing tool |
| [`bug-fix`](skills/bug-fix/) | Root-cause bug fix — reproduce, minimal fix, regression test; used by `csp-bug-fixer` / `/csp-start-issue-task` |
| [`jira-fetch`](skills/jira-fetch/) | Fetch Jira issue text via Atlassian MCP; classify Bug vs Story for `/csp-start-task` routing |
| [`jira-transition`](skills/jira-transition/) | Move a fetched issue to In Progress (`/csp-start-task`) or Review (`create-pr` after every opened pull request is merged and continuous integration succeeded) |
| [`create-pr`](skills/create-pr/) | Push + **draft** GitHub PR (requires `commit-approved` when commits were needed), then HITL Pipeline finale (`keep_draft` / `ready` / Jira comment). Never merge; Review transition after merge and successful builds |
| [`trajectory-score`](skills/trajectory-score/) | Record a trajectory ledger and hard-score it at wired pipeline stops; session ledger for full/fast/issue paths |
| [`trajectory-judge`](skills/trajectory-judge/) | Nested-Task judge for invented business facts and decision-doc archaeology; writes actions then re-scores |
| [`harness-status`](skills/harness-status/) | Kit harness inventory + last bench summary; orientation only (does not advance gates) |
| [`code-quality-score`](skills/code-quality-score/) | Hard-score kit code-quality fixtures (files / substrings / tests); no language-model judge |
| [`english-humanizer`](skills/english-humanizer/) | Strip AI tells from English bug reports, colleague messages, and PR comments |
| [`plain-language-chat`](skills/plain-language-chat/) | User-facing chat uses full words — no abbreviations; always-on via rule `plain-language-chat` |
| [`finish-plan`](skills/finish-plan/) | Plan→HITL handoff: `review-surface` (`SetActiveBranch`) then review-gate; engineer-review still runs after |
| [`propose-commit`](skills/propose-commit/) | Post-review HITL — propose commit message + file list; `approve-commit` / `revise`; `git commit` only (never push); writes `commit-approved` gate |
| [`update-docs`](skills/update-docs/) | Post-review HITL — product docs destination (`docs/` / docs repo / Confluence) + dual-audience writing |
| [`engineer-review`](skills/engineer-review/) | Multi-phase review orchestrator — snippets + file links + humanizer prose; P0–P2, chunking |
| [`implementation-critic`](skills/implementation-critic/) | Pre-code plan audit — Pass A/B (+ Pass C for bug-fix plans), must-fix/should-fix/accept-risk |
| [`tech-spec`](skills/tech-spec/) | Developer technical action plan — human always full system-design path; agent chooses light\|full; Blocker/Decision/Assumption on light path |
| [`system-design`](skills/system-design/) | Anthropic-style system design draft for tech-spec full path (format human plan or draft-from-ac) |
| [`system-design-critic`](skills/system-design-critic/) | Read-only audit of system-design drafts inside auto-consensus |
| [`code-comments`](skills/code-comments/) | Keep/remove taxonomy for comments — shared by developers and `csp-review-deadcode`; services forbid user-interface citations; React / frontend UI may reference screens, charts, or Figma |
| [`clean-decision-docs`](skills/clean-decision-docs/) | Specs/plans stay final-form decisions — no "fixed/changed to" archaeology after critique or revise |
| [`start-build`](skills/start-build/) | Thin build handoff — requires critique-clear plan, then `csp-software-developer`, **waits**, then `finish-plan` → `csp-engineer-reviewer` (no critic here) |
| [`approve-plan`](skills/approve-plan/) | HITL approve/revise the plan, then auto-run `implementation-critic`; on clear → `start-build` |
| [`pr-review`](skills/pr-review/) | PR-entry wrapper around engineer-review — canvas orientation + snippets + file links + humanizer prose; default report-only |
| [`teach-review`](skills/teach-review/) | After a shareable review miss (`miss`): generalize into kit instructions, `learn/…` branch, land via `cursor-spells-learn.json`. Project-private misses use `project_secret` instead. |
| [`software-developer`](skills/software-developer/) | Implements a cleared plan (or `mode:fast` AC brief) — feature branch(es), skill-map routing, code-comments, verify-before-handoff; web UI vs Figma via `ce-test-browser` |

## Agents

| Agent | Role |
|-------|------|
| `csp-software-developer` | Feature branch(es) then code to tech spec + plan after critic clear (or `mode:fast`) — routes skills, verifies; web → browser vs Figma |
| `csp-bug-fixer` | Reproduce → root cause → regression test → minimal fix — used by `/csp-start-issue-task` |
| `csp-engineer-reviewer` | Orchestrator — phase agents; findings with snippets, clickable links, humanized What/Where/Why |
| `csp-pr-reviewer` | Same phases as engineer-reviewer; PR Review Canvas + Findings with snippets, clickable links, humanized prose |
| `csp-review-lint` | Runs real project tooling (eslint/tsc/checkstyle/…) — catches mechanical rule violations heuristic phases miss |
| `csp-review-logic` | Correctness + stack best practices |
| `csp-review-patterns` | Project patterns MD (create/enforce); frontend also compact-table / narrow-viewport gates (**V1–V4**) |
| `csp-review-deadcode` | Dead code, unused symbols, comment cleanup |
| `csp-review-simplify` | Cleanliness / reuse / local efficiency — primary `ce-simplify-code` + kit extensions |
| `csp-review-architecture` | Architecture gaps |
| `csp-review-performance` | Performance |
| `csp-review-security` | Security (conditional); always [security-hardening-checklist.md](skills/engineer-review/references/security-hardening-checklist.md) **S1–S10** when triggered; same checklist loaded by `csp-software-developer` / `csp-bug-fixer` on those surfaces |
| `csp-review-figma-markup` | Markup vs Figma (needs node URLs); always [figma-markup-checklist.md](skills/engineer-review/references/figma-markup-checklist.md) F1–F7; on web also `ce-test-browser` at tablet and phone, not only the desktop frame; [responsive-layout-checklist.md](skills/engineer-review/references/responsive-layout-checklist.md) V1–V4 |
| `csp-review-learn` | Load hints from kit seed + this project's private ledger; write `.cursor/review-learnings.md` only after `project_secret` |
| `csp-multi-repo-supervisor` | Supervises engineer-review across 2+ changed repositories |
| `csp-review-cross-repo` | Reports cross-repo contract drift as clarification-only findings |
| `csp-implementation-critic` | Audits a plan before code — Pass A/B (+ Pass C bug-fix), read-only |
| `csp-tech-spec` | Drafts technical action plan pre-plan — human plan → full path; agent light\|full; one question at a time, never invents business facts |
| `csp-system-design-designer` | Formats/drafts system-design for tech-spec full path |
| `csp-system-design-critic` | Critiques system-design drafts; no human asks mid-loop |

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
# simplify phase primary (Cursor compound-engineering plugin — not always via npx):
# ensure ce-simplify-code is available under ~/.cursor/plugins/.../ce-simplify-code
# preferred when present for review scoping / multi-repo (optional install):
npx skills add graphify-labs/graphify@graphify
# PR Review Canvas (Cursor plugin — not npx): install "PR Review Canvas" / pr-review-canvas
# so /csp-pr-review can emit a diff-orientation canvas (skip with no-canvas)
# Database: always-on + current MySQL/MongoDB stack (same ids as skill-map Database skill routing).
# Conditional Postgres/Flyway/Prisma stay manual unless the consumer project uses them.
npx skills add wshobson/agents@database-migration
npx skills add affaan-m/everything-claude-code@database-migrations
npx skills add planetscale/database-skills@mysql
npx skills add affaan-m/everything-claude-code@mysql-patterns
npx skills add github/awesome-copilot@sql-code-review
npx skills add mongodb/agent-skills@mongodb-query-optimizer
npx skills add mongodb/agent-skills@mongodb-connection
npx skills add hoodini/ai-agents-skills@mongodb
```


Database migrations and schema changes are automatically routed to matching DB skills (MySQL, MongoDB, and conditional Postgres/Flyway/Prisma rows) via [`skill-map.md`](skills/engineer-review/references/skill-map.md#database-skill-routing)'s Database skill routing section. `csp install` installs the always-on + current-stack ids from that map (skip with `--skip-third-party-skills`). Conditional Postgres/Flyway/Prisma rows stay manual unless the consumer project uses them. If a stack isn't covered by the map at all, the kit follows a two-tier skill resolution protocol: curated skills are used directly, anything else is presented to you for an explicit decision — never auto-installed mid-review.

When `graphify-out/` exists (or `graphify query` answers), engineer-review **prefers** graphify for impact scoping and call-graph questions to save tokens — see [`graphify-protocol.md`](skills/engineer-review/references/graphify-protocol.md). If graphify is not installed or has no build, review keeps the existing `git diff` + chunking path unchanged.

## Usage

### English humanizer

- `@english-humanizer` / ask to humanize a PR comment or problem description
- Humanizer does **not** expand abbreviations. Chat with you still goes through [`plain-language-chat`](skills/plain-language-chat/) (always-on rule after `csp update`)

### review-gate → HITL → engineer review

1. When coding from a plan is done: `/csp-finish-plan` (this is the **review-gate** HITL, not another planning step). First it applies [`review-surface`](skills/finish-plan/references/review-surface.md): check out the feature branch in each open folder and call `SetActiveBranch` so the pull request tab shows the diff. That is **not** a GitHub pull request and **not** the pipeline end. When the branch has **zero commits ahead of base**, the tab may be empty — the surface still shows **uncommitted** work in chat (`git status` / `git diff`).
2. Answer via interactive buttons when offered (`AskQuestion`), or type `skip` / `approve` / `done`. Type `fixes` to return to `csp-software-developer`, then the same gate. After `skip` / `approve` / `done`, **engineer-review** starts.
3. On frontend, use the Figma picker or paste node URLs / `no figma`
4. Orchestrator runs phases; applies **P0/P1** unambiguous fixes; lists clarifications separately

Comment cleanup and apply-vs-clarify decisions across all review phases now follow a strict [auto-fix eligibility test](skills/engineer-review/references/auto-fix-eligibility.md): a finding is only auto-applied if it's deterministic, has a single correct answer, loses no information, and has zero blast radius on data or user-facing behavior — otherwise it's always `clarify`, regardless of severity. User-facing findings **must** pass the hard [evidence gate](skills/engineer-review/references/evidence-gate.md) before emit: `path` + line range + real code fence + File/Lines/Jump links (GitHub `#L` on PR). [Forbidden](skills/engineer-review/references/forbidden-formats.md): Verdict/Blockers/Блокери digests without paths and snippets. Incomplete items are backfilled via `scripts/extract-review-snippet.sh` or dropped; draft reports must pass `scripts/validate-review-report.sh`. Shape: [feedback-format.md](skills/engineer-review/references/feedback-format.md).

**Manual review:** `/csp-engineer-review` — evidence-gated snippets + file links; validator before emit; `english-humanizer` then `plain-language-chat` on prose.  
**PR review:** `/csp-pr-review [url|number|branch] [apply] [no-figma] [no-canvas]` — same gate (plus required GitHub blob links); default PR Review Canvas for diff orientation (`no-canvas` to skip); never a Verdict/Блокери digest; report-only unless `apply`.

### Start a task (full pipeline)

**Canvas (layers, sequence, cycles):** interactive [`pipeline-flow.html`](docs/superpowers/pipeline-flow.html) · Mermaid source [`pipeline-flow.md`](docs/superpowers/pipeline-flow.md). Run `/csp-pipeline-status` (or `scripts/pipeline-status.sh`) for a where-am-I strip and a canvas link with `?route=&layer=&stage=` highlight. Optional consumer run-log journals (`scripts/pipeline-run-log.sh`, see dogfood [`pipeline-run-memory-checklist.md`](docs/superpowers/dogfood/pipeline-run-memory-checklist.md)) enrich the strip — not kit-global chat memory. After code the graph names the HITL **`review-gate`** (skill `finish-plan` / command `/csp-finish-plan` writes the marker). `fixes` returns to Build, not to `writing-plans`. Kit harness inventory: `/csp-harness-status` (or `python3 scripts/harness-health.py`) — orientation only.

`/csp-start-task [ac-source]` orchestrates the whole pipeline end-to-end, stopping only at the human-in-the-loop (HITL) gates that already exist — it never skips or softens any of them. Closed-set HITL asks **must** call Cursor **`AskQuestion`** (or alias) via skill [`hitl-choice`](skills/hitl-choice/) (rule `hitl-askquestion`); typed tokens only after the tool fails or is missing. When the AC source looks like a Jira ticket (`PROJ-123` or `*.atlassian.net` URL), it **fetches** via Atlassian MCP (`jira-fetch`), moves the ticket to **In Progress** (`jira-transition`), then **routes** (Bug → `/csp-start-issue-task`; unknown type → HITL **Pipeline route**; never auto-selects `--fast`). Ends with skill [`create-pr`](skills/create-pr/) (draft PR, then HITL **Pipeline finale**).

1. Bootstraps context (project patterns, stack) — automatic
2. Runs `tech-spec` — **HITL** at entry (`human` / `agent`), depth (`light` / `full` when agent), any Blocker/Decision question (light path), and `approve-spec`/`revise`/`skip`
3. Generates the implementation plan via `writing-plans` — automatic once the spec's `Status` is `approved` or explicitly `skip`ped
4. `/csp-approve-plan` — **HITL** `approve-plan`/`revise`, then **automatic** `implementation-critic`; **HITL** only if findings block; on `Verdict: clear` → `start-build`

On every `revise` of a spec or plan, agents follow [`clean-decision-docs`](skills/clean-decision-docs/): rewrite the file as current truth; put "what changed" in chat, not as changelog archaeology inside the document.
5. Executes via `csp-software-developer` (branch setup in target repo(s) → skill-map routing → `subagent-driven-development`) — automatic, no "which approach?" prompt in this flow
6. `review-gate` via `/csp-finish-plan` — surface the diff (`SetActiveBranch`) then **HITL** `skip`/`approve`/`done` (or `fixes` back to `csp-software-developer`). Pipeline continues.
7. `engineer-review` — **HITL** only for clarifications it raises
8. [`propose-commit`](skills/propose-commit/) — **HITL** `approve-commit` / `revise`; stages listed paths and `git commit` only (never push); writes `.cursor/gates/commit-approved/<slug>`
9. `/csp-update-docs` — **HITL** `skip` / `docs_md` / `docs_repo` / `confluence` (product docs destination; dual-audience write); residual **`propose-commit`** if docs left uncommitted files
10. `/create-pr` skill — **always draft first**, then HITL **Pipeline finale**: `keep_draft` / `ready` (`gh pr ready`), and `keep_draft_jira` / `ready_jira` when a Jira key is known (comment PR URL on the ticket). `ready` / `ready_jira` move the Jira issue to **Review** only after every opened pull request is merged and every continuous-integration build succeeded. Never merge.

Full `/csp-start-task` **does** fetch Jira when the prompt looks like a ticket. MCP failure → stop and paste the ticket (never a URL-only stub). Writing AC is still out of scope. Explicit `/csp-start-issue-task` always stays on the issue path even if the type is Story.

Prefer `/csp-write-tech-spec [ac-source]` directly if you only want the tech spec, without triggering the rest of the pipeline.

### Start a task (fast — no planning HITL)

`/csp-start-task --fast [ac-source]` for small work: bootstrap → fetch (if ticket-shaped) → short AC brief → `csp-software-developer` `mode:fast` → `csp-engineer-reviewer` (no review-gate HITL) → `propose-commit` → `create-pr` (Pipeline finale HITL). No tech-spec, plan approval, critic, or update-docs. **You** must pass `--fast`; the agent never chooses it. If the fetched type is Bug, HITL **Fast vs issue** asks `issue` vs `stay_fast`.

### Start an issue task (Jira bug fix)

`/csp-start-issue-task [jira-key|url]` fetches the issue via **Atlassian MCP** (skill `jira-fetch`; stops if MCP fails — paste text then), moves it to **In Progress**, writes a fix plan, auto-runs `implementation-critic` (Pass A/B/**C**), HITL only if critic is blocked/pending accept, then `csp-bug-fixer` → `csp-engineer-reviewer` → `propose-commit` → `create-pr` (Pipeline finale; Jira comment options when the key is known; `ready` / `ready_jira` move the ticket to **Review** only after every opened pull request is merged and every continuous-integration build succeeded). Always this path when invoked explicitly, even if the type is Story.

### Capture a production escape

`/csp-capture-escape [what slipped]` records a production miss without a full `engineer-review`. It asks **Capture-escape destination**: `miss` writes kit instructions via `teach-review`; `project_secret` writes this project's `.cursor/review-learnings.md` only (client names that must not enter the kit).

`/csp-teach-review [what slipped]` writes generalized **kit** instructions (not `.cursor/review-learnings.md`). After every settled engineer/PR review the orchestrator asks `miss` / `project_secret` / `no_miss`. Land config: `~/.cursor/cursor-spells-learn.json` and `<project>/.cursor/cursor-spells-learn.json` (created on `csp install` if missing).

Design: [`docs/superpowers/specs/2026-08-04-bugfix-issue-fast-pipelines-design.md`](docs/superpowers/specs/2026-08-04-bugfix-issue-fast-pipelines-design.md) · Jira fetch + router + PR finale: [`docs/superpowers/specs/2026-08-16-jira-ac-router-finale-design.md`](docs/superpowers/specs/2026-08-16-jira-ac-router-finale-design.md)

### Update product docs

`/csp-update-docs` asks where documentation should land, resolves style (existing house docs or a custom user/engineer guide — especially for a separate docs repo or Confluence), then writes prose (see [`skills/update-docs/references/writing-guide.md`](skills/update-docs/references/writing-guide.md)). Kit dual-audience default is only the fallback. Compose with:

- **`english-humanizer`** — strip AI filler from engineer sections (bundled)
- **`ce-compound`** (optional third-party) — durable solved-problem docs in `docs/solutions/`; not a substitute for product docs
- **`ce-explain`** (optional) — personal teaching artifacts; not a product-docs destination
- **`ce-promote`** (optional) — launch/announcement copy; separate from the docs body

```bash
npx skills add everyinc/compound-engineering-plugin@ce-compound
npx skills add everyinc/compound-engineering-plugin@ce-explain
```

### Approve plan → critic → build

`/csp-approve-plan [path]` is the plan gate: the human reads the plan (`approve-plan` / `revise` via `hitl-choice` (AskQuestion required)), then `implementation-critic` runs **automatically** (no HITL to start it). On `Verdict: clear` it writes `.cursor/gates/plan-critique-clear/<slug>` and invokes `/csp-start-build`. On `blocked` / `clear pending accept`, it stops for a revision or `accept F<id>`.

`/csp-start-build [path]` no longer runs the critic — it starts `csp-software-developer` when this plan's `.cursor/gates/plan-critique-clear/<slug>` matches the plan, **waits for that agent to return**, then invokes `finish-plan` (human-in-the-loop, then `csp-engineer-reviewer`). Other slugs' pending gates do not block.

### Critique a plan before coding

`/csp-critique-plan [path]` audits an implementation plan ad-hoc (complexity, risk, scope drift). Prefer `/csp-approve-plan` in the pipeline so plan HITL is not skipped. If the report's `Verdict` is not `clear`, revise the plan or reply `accept F<id>` for a specific finding, then re-run.

For work spanning multiple sibling repos, see [Multi-repo review](#multi-repo-review).

### Multi-repo review

Use multi-repo review when a task changes **2+ sibling repositories**. If routing finds no changed repos, it stops with a message; if it finds one changed repo, the normal single-repo `csp-engineer-reviewer` path runs unchanged.

- Explicit `/csp-multi-review` paths are the repo set for that run. Without explicit paths, discovery prefers graphify at the workspace parent, then existing parent `.cursor/multi-repo.json`, then a sibling scan.
- Single-repo and per-repo review also prefer graphify (when `graphify-out/` or the CLI can answer) to narrow deep-reads; without it, behavior is unchanged.
- `finish-plan` routing uses a non-mutating probe; parent `.cursor/multi-repo.json` is written only for a confirmed multi-repo run without graphify, or when `/csp-multi-review --refresh` explicitly asks for it. It is never written inside a single leaf repo.
- Commands:
  - `/csp-multi-review [path ...] [--refresh]` runs the multi-repo routing manually. Explicit paths override discovery for that run.
  - `/csp-finish-plan` auto-routes after HITL approval: single-repo tasks use `csp-engineer-reviewer`; multi-repo tasks use `csp-multi-repo-supervisor`.
- Cross-repo contract drift is clarify-only in v1 (`C_CR*`); it is not auto-applied or listed under Fixed now.
- Jira/Linear **ticket→repo** discovery is deferred to v1.1. v1 routing uses explicit `/csp-multi-review` paths, graphify, parent `.cursor/multi-repo.json`, or sibling scan. Jira **issue fetch** and **status transitions** (In Progress on start, Review when the PR is marked ready) for `/csp-start-task` / `/csp-start-issue-task` are in v1.

Design: [`docs/superpowers/specs/2026-07-22-multi-repo-supervisor-design.md`](docs/superpowers/specs/2026-07-22-multi-repo-supervisor-design.md)

**First run** writes `.cursor/project-patterns.md` in the consumer repo.

**Patterns CI (optional):** `scripts/check-project-patterns.sh --strict`  
Workflow template: [`scripts/templates/project-patterns.yml`](scripts/templates/project-patterns.yml)

**Dogfood checklist:** [`docs/superpowers/dogfood/engineer-review-checklist.md`](docs/superpowers/dogfood/engineer-review-checklist.md) · Jira fetch / router / PR finale: [`docs/superpowers/dogfood/jira-ac-router-finale-checklist.md`](docs/superpowers/dogfood/jira-ac-router-finale-checklist.md)

**Agent trajectory golden set:** kit-only contracts under [`evals/trajectories/`](evals/trajectories/) — what the agent must do, must not do, and where a human must appear. Validate with `python3 scripts/trajectory-cases.py validate`. Score a recorded run with `python3 scripts/trajectory-cases.py score --run <file>` (hard sensors only). Wired stops follow skill [`trajectory-score`](skills/trajectory-score/): fetch-fail scores `fetch-failure-stops`; `create-pr` scores `create-pr-draft-never-merge` (four-token) or `create-pr-draft-never-merge-no-jira` (two-token) after Pipeline finale is asked and before `gh pr ready`; remaining golden cases score at their natural stops; session ledgers score `full-happy-path` / `fast-skips-plan-layer` / `issue-happy-path` when a draft exists. Invented facts / archaeology go through skill [`trajectory-judge`](skills/trajectory-judge/) then re-score. Tests: `bash scripts/tests/trajectory-cases-test.sh`, `bash scripts/tests/trajectory-score-test.sh`, and `bash scripts/tests/trajectory-wiring-test.sh`. Not copied into consumer apps. Not a live agent runner. Overnight unsupervised loops and agent-to-agent teams without an orchestrator stay out of scope.

**Harness health / bench:** before changing skills or agents, run `bash scripts/harness-bench.sh` (all `scripts/tests/*.sh` plus trajectory validate + fixture score; writes `evals/harness/reports/<timestamp>.json` with `metrics.quality` pass rates, `metrics.speed` p50/p95/slowest, and `metrics.review_response_quality` (evidence/clarify/markdown sensors)). Inventory without a full bench: `python3 scripts/harness-health.py` or `/csp-harness-status` (orientation only; prints quality/speed when a bench report exists). See [`evals/harness/README.md`](evals/harness/README.md) and [`docs/superpowers/dogfood/harness-health-checklist.md`](docs/superpowers/dogfood/harness-health-checklist.md).


**Live pipeline metrics (consumer runs):** during real ticket pipelines, agents append quality/speed rows via `scripts/pipeline-metrics.py` (`mark-start` after ledger init, `append-score` at trajectory score stops, `append-review` after a validated engineer-review report). History: `.cursor/gates/pipeline-metrics/history.jsonl`. Inspect with `summary`; graph with `export --format csv`. Contract: `bash scripts/tests/pipeline-metrics-test.sh`. **Diagrams + plain-language names (Ukrainian):** [`docs/superpowers/pipeline-metrics-guide.md`](docs/superpowers/pipeline-metrics-guide.md).

**Code-quality evals:** kit-only hard sensors under [`evals/code-quality/`](evals/code-quality/) — expected files, forbidden paths, substrings, and shell tests. Validate with `python3 scripts/code-quality-cases.py validate`. Score golden fixtures with `python3 scripts/code-quality-cases.py score --runs-dir evals/code-quality/fixtures/pass`. Skill [`code-quality-score`](skills/code-quality-score/). Dogfood: [`docs/superpowers/dogfood/code-quality-evals-checklist.md`](docs/superpowers/dogfood/code-quality-evals-checklist.md).

Design: [`docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md`](docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md)

## License

MIT — steal freely, please sound human.
