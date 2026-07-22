# Engineer Review Orchestrator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a portable engineer-review kit (orchestrator agent, phase subagents, slash command, HITL gate rule/hook, slim skill + references) that any project can symlink from `cursor-spells`.

**Architecture:** Thin orchestrator dispatches focused subagents per review phase; project patterns cached in the consumer repo; HITL gate before auto-review after plan completion.

**Tech Stack:** Cursor agents (`.md`), slash commands, optional `stop` hook (bash + JSON), Agent Skills (`SKILL.md` + references).

## Global Constraints

- All user-facing agent/command prose may be English in prompts (agents operate in English); README install notes in English to match existing kit voice, unless updating Ukrainian docs (none required).
- No vendoring of third-party skill bodies; only skill IDs + install commands in `skill-map.md`.
- Orchestrator spine must stay slim: link to references, do not inline full checklists.
- Pattern artifacts are written to the **consumer** project path `.cursor/project-patterns.md`, never into this kit as a single global cache.
- Hook must never auto-start review; only remind about HITL.
- Branch naming for this work: `cursor/engineer-review-orchestrator-02a7`.

---

### Task 1: Skill spine + references

**Files:**
- Create: `skills/engineer-review/SKILL.md`
- Create: `skills/engineer-review/references/skill-map.md`
- Create: `skills/engineer-review/references/phase-protocol.md`
- Create: `skills/engineer-review/references/output-schema.md`
- Create: `skills/engineer-review/references/patterns-template.md`

**Interfaces:**
- Consumes: design at `docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md`
- Produces: discoverable skill `engineer-review`; reference paths used by all agents

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter: `name: engineer-review`, description starts with `Use when...` (HITL after plan, manual review, engineer-reviewer) — no workflow summary in description.

Body: overview, when to use, HITL gate, dispatch order pointing to references, fix policy, output pointer. Keep under ~120 lines.

- [ ] **Step 2: Write `skill-map.md`**

Table mapping stack detection signals → recommended `npx skills add` IDs:

| Detect | Skill ID |
|--------|----------|
| React/Next/TS frontend | `vercel-labs/agent-skills@vercel-react-best-practices` |
| React Native | `vercel-labs/agent-skills@vercel-react-native-skills` |
| Java/Spring | `github/awesome-copilot@java-springboot` |
| Security phase | `affaan-m/everything-claude-code@security-review` |
| Performance | `addyosmani/agent-skills@performance-optimization` |
| Architecture | `getsentry/warden@architecture-review` |
| Dead code | `abpai/skills@dead-code-eliminator` |
| Patterns optional | `graphify-labs/graphify@graphify` |

Include detection heuristics (package.json deps, `pom.xml`/`build.gradle`, `*.java`, etc.).

- [ ] **Step 3: Write `phase-protocol.md`**

Contract for every phase subagent:

- Inputs: BASE_SHA, HEAD_SHA, stack, patterns path, prior clarifications
- Process: read skill if mapped → review diff only → classify findings Fixed vs Clarify
- Apply: only unambiguous; return JSON summary schema
- Max output size for orchestrator merge

JSON summary shape:

```json
{
  "phase": "logic",
  "status": "ok",
  "fixed": [{"path": "a.ts", "summary": "..."}],
  "clarify": [{"id": "C1", "question": "...", "options": ["A", "B"]}],
  "skipped": false,
  "skip_reason": null,
  "notes": []
}
```

- [ ] **Step 4: Write `output-schema.md` and `patterns-template.md`**

Output schema matches design markdown sections. Patterns template sections: Naming, Folder structure, Components/Classes, Packages/imports, Code techniques, Do-not-reinvent (existing helpers), Comments policy.

- [ ] **Step 5: Commit**

```bash
git add skills/engineer-review docs/superpowers/specs/2026-07-22-engineer-review-orchestrator-design.md
git commit -m "docs: add engineer-review skill spine and design spec"
```

---

### Task 2: Orchestrator + phase agents

**Files:**
- Create: `agents/engineer-reviewer.md`
- Create: `agents/review-logic.md`
- Create: `agents/review-patterns.md`
- Create: `agents/review-deadcode.md`
- Create: `agents/review-architecture.md`
- Create: `agents/review-performance.md`
- Create: `agents/review-security.md`
- Create: `agents/review-figma-markup.md`
- Delete or ignore: `agents/.gitkeep` if empty placeholder conflicts

**Interfaces:**
- Consumes: `skills/engineer-review/references/*`
- Produces: Cursor custom agents invokable as `@engineer-reviewer` etc.

- [ ] **Step 1: Write `engineer-reviewer.md`**

YAML: `name: engineer-reviewer`, description includes proactive use after plan HITL approval and manual review.

Body: stack detect → ensure patterns file → HITL check if triggered post-plan → dispatch phases per protocol → merge → print Fixed / Clarify → wait for answers → re-dispatch.

- [ ] **Step 2: Write phase agent files**

Each file: focused checklist, which reference/skill to load, apply policy, return JSON summary. Figma agent must **ask for Figma node URLs first** and skip if none.

- [ ] **Step 3: Commit**

```bash
git add agents/
git commit -m "feat: add engineer-reviewer orchestrator and phase agents"
```

---

### Task 3: Slash command, rule, optional hook

**Files:**
- Create: `commands/engineer-review.md`
- Create: `rules/after-plan-review-gate.mdc`
- Create: `hooks/hooks.json`
- Create: `hooks/post-plan-review-gate.sh`
- Modify: `README.md` (document install + flow)

**Interfaces:**
- Consumes: agents + skill
- Produces: `/engineer-review`; always-on reminder rule; optional stop hook

- [ ] **Step 1: Write command**

`commands/engineer-review.md` invokes the engineer-review skill/orchestrator; accept optional base/head or default to branch diff vs main.

- [ ] **Step 2: Write rule**

`rules/after-plan-review-gate.mdc` with frontmatter `alwaysApply: true` (or globs if preferred): when finishing plan execution, stop and ask HITL; do not start engineer-reviewer until approve/skip/done.

- [ ] **Step 3: Write hook**

`hooks.json` registers `stop` → `post-plan-review-gate.sh`. Script reads stdin JSON; if `.cursor/review-gate.pending` exists in workspace, output `{"followup_message":"...HITL reminder..."}` and leave marker for user/agent to clear; else `{}`.

Make script executable (`chmod +x`).

- [ ] **Step 4: Update README**

Add Engineer Review section: what it is, install symlinks, recommended `npx skills add`, HITL flow, pattern cache location.

- [ ] **Step 5: Commit**

```bash
git add commands/ rules/ hooks/ README.md
git commit -m "feat: add engineer-review command, HITL rule, and stop hook"
```

---

### Task 4: Plan doc + sanity check

**Files:**
- Create: `docs/superpowers/plans/2026-07-22-engineer-review-orchestrator.md` (this file, already written)
- Verify: no TBD/placeholders in agents/skill

- [ ] **Step 1: Grep for TBD/TODO in new kit files**

```bash
rg -n 'TBD|TODO|implement later' agents commands hooks skills/engineer-review docs/superpowers || true
```

Expected: no hits in kit prompts (docs plans may contain the word in checklists only as `- [ ]`).

- [ ] **Step 2: Confirm file tree**

```bash
find agents commands hooks rules skills/engineer-review docs/superpowers -type f | sort
```

- [ ] **Step 3: Final commit if any fixups**

```bash
git add -A && git status
git commit -m "chore: finalize engineer-review kit layout" || true
```

---

## Self-review (plan vs spec)

| Spec requirement | Task |
|------------------|------|
| HITL after plan | Task 3 rule + hook; Task 1 skill; Task 2 orchestrator |
| Manual launch | Task 3 command |
| Stack skill routing | Task 1 skill-map; Task 2 logic/perf agents |
| Patterns MD / optional graphify | Task 1 template; Task 2 review-patterns |
| Dead code / redundancy / comments | Task 2 review-deadcode |
| Architecture / performance / security / figma | Task 2 agents |
| Subagent per phase | Task 2 |
| Fix now vs clarify | Task 1 protocol + output schema |
| 200k context slim spine | Task 1 SKILL slim + references |
| Portable kit | README + symlink install |
)
