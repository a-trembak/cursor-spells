# Engineer Review Orchestrator — Design

**Date:** 2026-07-22  
**Status:** Approved  
**Repo role:** Portable AI workflow kit (`cursor-spells`) added to each project

## Problem

After a plan is executed, review is either skipped, monolithic (burns context), or inconsistent across stacks (Java/Spring, React/TS, React Native). The user wants a reusable orchestrator that:

1. Gates on human-in-the-loop before automated review
2. Routes to stack-appropriate skills
3. Runs focused subagent phases
4. Applies unambiguous fixes immediately
5. Surfaces clarifying questions separately
6. Fits a ~200k context budget without losing effectiveness
7. Caches project patterns so later reviews do not re-discover them from scratch

## Goals

- Portable: live in this kit; consume from any project via symlink/copy
- Dual entry: automatic gate after plan completion + manual `/engineer-review`
- HITL: never start `engineer-reviewer` until user `skip` / `approve` / `done`
- Phase isolation: each checklist item is a subagent
- Output: **Fixed now** vs **Needs clarification**
- Pattern cache in the *target* project after first run

## Non-goals

- Replacing native Cursor Agent Review UI
- Installing third-party skills into every consumer project automatically (document recommended installs)
- Requiring graphify (MD-first; graphify optional)
- Blocking CI or forcing review on every agent stop unrelated to plan completion

## Architecture (Approach A)

Thin orchestrator + focused subagents.

```
cursor-spells/
├── agents/
│   ├── engineer-reviewer.md          # orchestrator only
│   ├── review-logic.md
│   ├── review-patterns.md
│   ├── review-deadcode.md
│   ├── review-architecture.md
│   ├── review-performance.md
│   ├── review-security.md
│   └── review-figma-markup.md
├── commands/
│   └── engineer-review.md
├── hooks/
│   ├── hooks.json                    # optional stop gate
│   └── post-plan-review-gate.sh
├── skills/
│   └── engineer-review/
│       ├── SKILL.md                  # slim spine
│       └── references/
│           ├── skill-map.md
│           ├── phase-protocol.md
│           ├── output-schema.md
│           └── patterns-template.md
└── rules/
    └── after-plan-review-gate.mdc    # remind implementers to stop at HITL
```

**Target project artifacts (created/updated by first review):**

- `.cursor/project-patterns.md` — naming, folders, packages, code style, component/class structure
- Optional: `graphify-out/` if the project opts into graphify

## Entry points

### Manual

User runs `/engineer-review` or invokes `@engineer-reviewer` / skill `engineer-review`.

### After plan (HITL gate)

When plan execution finishes (`ce-work`, `executing-plans`, `subagent-driven-development`, or equivalent), the agent **must stop** and ask:

> Plan done. Want to do your own review first?
> - `skip` — start engineer-reviewer now
> - `approve` / `done` — start after your review
> - or describe fixes first

Only after `skip` | `approve` | `done` does the orchestrator run.

Optional `stop` hook: if a marker file (e.g. `.cursor/review-gate.pending`) exists, emit `followup_message` reminding about the gate. The hook never auto-starts review (preserves HITL).

## Orchestrator spine (context budget)

Orchestrator keeps in context:

1. Diff range (base..head) or changed-file list
2. Detected stack + selected skill IDs from `skill-map.md`
3. Path to `.cursor/project-patterns.md` (create if missing)
4. Compact JSON summaries from each phase (not full subagent transcripts)
5. Aggregated Fixed / Clarification lists

Heavy skill bodies are loaded **only by the relevant subagent**, never by the orchestrator.

Target orchestrator prompt size: ~2–4k tokens + summaries.

## Phases (each = one subagent)

| Order | Agent | When | Primary skills (recommended) |
|------:|-------|------|------------------------------|
| 0 | (orchestrator) stack detect + patterns ensure | always | — |
| 1 | `review-lint` | always (deterministic tooling; skips if no lint config resolvable) | project's own eslint/tsc/checkstyle/ktlint |
| 2 | `review-logic` | always | stack skill (Vercel React BP / RN / Java Spring) |
| 3 | `review-patterns` | always | project-patterns.md; optional graphify |
| 4 | `review-deadcode` | always | dead-code-eliminator + local redundancy rules |
| 5 | `review-architecture` | always | architecture-review skill |
| 6 | `review-performance` | always | addyosmani performance + Vercel on frontend |
| 7 | `review-security` | if auth/data/network/secrets touch diff | security-review |
| 8 | `review-figma-markup` | frontend only, after user pastes Figma node URLs | figma-design-to-code / figma-use; on `react-web` also `ce-test-browser` |
| — | `review-lint` (verify pass) | once, after the coordinated apply step | same as above |

Phases may run **sequentially for mutating fixes** on the same files, or **parallel for read-only finding passes** then a single apply pass. Default: find in parallel where independent, apply unambiguous fixes in one orchestrated apply step to avoid write conflicts.

## Fix policy

- **Apply immediately:** clear bug, dead import, obsolete historical comment, naming that violates documented project pattern, obvious duplicate of existing helper with same semantics.
- **Needs clarification:** API contract changes, ambiguous product behavior, design intent without Figma, security tradeoffs, deleting code that might be reflection/DI entrypoints, any fix that could change user-visible behavior without a failing test or explicit plan requirement.

After the user answers clarification questions, the orchestrator re-dispatches the relevant subagent(s) with the answers and applies agreed fixes.

## Pattern cache

On first review in a project (or if `.cursor/project-patterns.md` missing):

1. `review-patterns` scans structure (folders, naming, packages, idioms)
2. Writes/updates `.cursor/project-patterns.md` from `patterns-template.md`
3. Later reviews read that file first; only update when drift is detected

Graphify: optional. If `graphify` is installed and user opts in, prefer `GRAPH_REPORT.md` / query for architecture questions; still keep a short MD patterns file for naming/style rules graphify may miss.

## Output format

```markdown
# Engineer Review

## Coverage
- stack: ...
- phases run / skipped (+ why)
- patterns: created | reused | updated

## Fixed now
- path: change summary

## Needs clarification
1. Question (context + options A/B/C)

## Residual notes
- non-blocking suggestions (optional, short)
```

## Portability / install

Document in README:

```bash
# from cursor-spells
ln -s "$(pwd)/skills/engineer-review" ~/.cursor/skills/engineer-review
ln -s "$(pwd)/agents"/*.md ~/.cursor/agents/   # or project .cursor/agents
ln -s "$(pwd)/commands/engineer-review.md" ~/.cursor/commands/engineer-review.md
# optional hooks: copy hooks/ into project .cursor/
```

Recommended consumer installs (not vendored here):

- `npx skills add vercel-labs/agent-skills@vercel-react-best-practices`
- `npx skills add vercel-labs/agent-skills@vercel-react-native-skills`
- `npx skills add github/awesome-copilot@java-springboot`
- `npx skills add affaan-m/everything-claude-code@security-review`
- `npx skills add addyosmani/agent-skills@performance-optimization`
- `npx skills add getsentry/warden@architecture-review`
- `npx skills add abpai/skills@dead-code-eliminator`

## Success criteria

- After plan, agent stops for HITL before review
- Manual `/engineer-review` works without a plan
- Each phase is a separate subagent
- Unambiguous fixes applied; questions listed separately
- First run creates project patterns MD
- Orchestrator stays slim; skills loaded per phase

## Improvements (2026-07-22 follow-up)

Shipped in the same kit iteration:

1. **`scripts/install-to-project.sh`** — one-shot install into `~/.cursor` + consumer project
2. **`finish-plan` skill/command** — reliable marker + HITL (does not depend on global alwaysApply)
3. **Severity `P0|P1|P2`** — auto-apply only unambiguous P0/P1; P2 → Residual
4. **Budget caps** — 40 files / 2500 LOC → chunk by package/dir
5. **`check-project-patterns.sh` + workflow template** — optional CI for missing patterns cache
6. **Early Figma ask** on frontend after HITL / at manual review start
7. **Rule scoped** — `alwaysApply: false` + plan globs; install per project only
8. **Dogfood checklist** — `docs/superpowers/dogfood/engineer-review-checklist.md`

## Improvements (2026-07-23 follow-up)

**Problem observed:** a real review run applied fixes via the heuristic phases but let a mechanical `eslint import/first` violation ("Import in body of module; reorder to top.") through unnoticed. Root cause: every phase in the kit was LLM judgment reading a diff — none of them actually *executed* the project's own linter/typechecker/build, so deterministic, mechanical rule violations depended on an LLM happening to notice them.

**Fix:** added a new phase agent, `review-lint`, instead of overloading `review-patterns` or `review-deadcode`:

- Deterministic tool execution (project's own `npm run lint` / `eslint` / `tsc --noEmit` / checkstyle / ktlint) is a different kind of check than LLM heuristic review and deserves its own phase, not a bolt-on to a judgment-based one.
- Runs **first**, before the heuristic phases — it has no dependency on `patterns` or a stack skill, and its findings are cheap to trust (a tool said so).
- Auto-fixable rule violations use the tool's own fixer (`eslint --fix`) as unambiguous `P1`; never a hand-written edit.
- The orchestrator re-runs `review-lint` once as a **verify pass** after the coordinated apply step, so a fix from another phase (e.g. `deadcode` removing code that leaves an import unused) cannot silently reintroduce a lint violation.
- Skips cleanly with `no_lint_config` / `tooling_unavailable` reasons (visible in Coverage) instead of failing the whole review when a stack has no configured linter.

See `agents/review-lint.md`, and the updated `phase-protocol.md` / `skill-map.md` / `output-schema.md` / `SKILL.md` in `skills/engineer-review/`.

