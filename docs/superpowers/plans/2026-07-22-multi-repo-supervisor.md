# Multi-Repo Review Supervisor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a multi-repo supervisor that fans out existing `engineer-reviewer` instances in parallel, runs a cross-repo contract-drift phase, auto-routes single-repo work unchanged, and discovers repos via graphify or an auto-generated parent `multi-repo.json`.

**Architecture:** Thin `multi-repo-supervisor` agent + `review-cross-repo` phase + `multi-repo-protocol.md` reference; `finish-plan` gains a routing check; `/multi-review` is the manual entry. Per-repo review logic stays in existing orchestrator.

**Tech Stack:** Cursor agents/commands/skills (markdown), optional graphify CLI, bash installer updates.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-22-multi-repo-supervisor-design.md` (locked decisions).
- `multi-repo.json` path: **workspace parent** `.cursor/multi-repo.json` only.
- Cross-repo findings: **always clarify** — never auto-apply.
- Ticket (Jira/Linear) discovery: **out of scope for this plan** (v1.1).
- Do not change behavior of single-repo `/engineer-review` or per-repo phase agents beyond what routing requires.
- Branch for this work: stay on `cursor/multi-repo-supervisor-spec-02a7` or continue from it after plan approval (same PR or follow-up implementation commits).

---

### Task 1: Multi-repo protocol reference

**Files:**
- Create: `skills/engineer-review/references/multi-repo-protocol.md`
- Modify: `skills/engineer-review/references/skill-map.md`
- Modify: `skills/engineer-review/SKILL.md` (short pointer to multi-repo when 2+ repos)

**Interfaces:**
- Consumes: locked design spec
- Produces: protocol that supervisor, finish-plan, and `/multi-review` all follow

- [ ] **Step 1: Write `multi-repo-protocol.md`**

Include exact sections:

1. **Routing algorithm** — how to detect changed repos; if count is 0 → stop with a message; if count is 1 → call `engineer-reviewer` and stop; else continue as supervisor.
2. **Discovery precedence** — explicit paths → graphify → parent `multi-repo.json` → sibling scan.
3. **Graphify queries** (exact command strings agents should run when available):
   ```bash
   # From workspace parent
   test -f graphify-out/GRAPH_REPORT.md || test -f graphify-out/graph.json
   graphify query "list repositories / top-level modules and their stacks"
   graphify query "modules impacted by: <comma-separated changed paths>"
   ```
4. **Fallback scan** — sibling dirs one level up; stack heuristics from the spec; write parent `.cursor/multi-repo.json` with the JSON shape from the spec (`generatedBy`, `generatedAt`, `repos[]`).
5. **Changed-repo detection** — for each listed repo path, run `git -C <path> status --porcelain` and/or `git -C <path> diff --name-only <base>..<head>`; collect those with any change.
6. **Supervisor inputs/outputs** — JSON envelopes:
   ```json
   {
     "repos": [
       {
         "path": "./api",
         "stack": "java-spring",
         "base": "<sha>",
         "head": "<sha>",
         "summary": { "...engineer-review phase merge...": true }
       }
     ],
     "cross_repo": {
       "phase": "cross-repo",
       "clarify": [
         {
           "id": "C_CR1",
           "severity": "P0",
           "question": "...",
           "options": ["A", "B"],
           "repos": ["api", "web"],
           "unambiguous": false
         }
       ],
       "fixed": [],
       "notes": []
     }
   }
   ```
7. **Merge rules** — renumber per-repo clarify ids to stay unique (`api:C1` or prefix `C1@api` in the unified markdown; keep internal ids in JSON); cross-repo ids always `C_CR*`; never put cross-repo items into `fixed`.
8. **Unified markdown template** — copy from the design “Unified output” section.

- [ ] **Step 2: Update `skill-map.md`**

Add a short “Multi-repo / graphify” row:

| Phase | Skill(s) |
|-------|----------|
| cross-repo | workspace `graphify-out/`; optional `graphify-labs/graphify@graphify` |

Note: do not create `multi-repo.json` when graphify answers successfully.

- [ ] **Step 3: Update `engineer-review/SKILL.md`**

Add a short “Multi-repo” subsection: if the caller is `multi-repo-supervisor` or discovery finds 2+ changed repos, defer to `multi-repo-protocol.md` / agent `multi-repo-supervisor`. Single-repo path unchanged.

- [ ] **Step 4: Commit**

```bash
git add skills/engineer-review
git commit -m "docs: add multi-repo protocol reference for supervisor"
```

---

### Task 2: Supervisor + cross-repo agents

**Files:**
- Create: `agents/multi-repo-supervisor.md`
- Create: `agents/review-cross-repo.md`

**Interfaces:**
- Consumes: `multi-repo-protocol.md`, existing `engineer-reviewer`
- Produces: Cursor agents `@multi-repo-supervisor`, `@review-cross-repo`

- [ ] **Step 1: Write `multi-repo-supervisor.md`**

Frontmatter:

```yaml
---
name: multi-repo-supervisor
description: >-
  Supervises engineer-review across 2+ changed repositories. Use when
  finish-plan or /multi-review detects multiple repos, or the user asks for
  multi-repo / cross-repo review.
---
```

Body must include:

1. Read `skills/engineer-review/references/multi-repo-protocol.md`.
2. Discover repos; if 0 changed → stop with a message; if 1 changed → hand off to `engineer-reviewer` and exit.
3. Single HITL listing all changed repos + stacks; wait for `skip`/`approve`/`done`.
4. If any frontend repo in the set, ask Figma once for the whole task.
5. Parallel Task dispatches: one `engineer-reviewer` per changed repo with path, stack, SHAs, figma clarifications.
6. After all return: dispatch `review-cross-repo` with repo paths + graphify report paths + per-repo summaries.
7. Merge and emit unified report; wait for answers; route `C*` to owning repo orchestrator and `C_CR*` to cross-repo (re-run clarify follow-up only — still no auto-apply for `C_CR*`).
8. Hard rules: never load full per-repo diffs into supervisor context; never auto-apply cross-repo items.

- [ ] **Step 2: Write `review-cross-repo.md`**

Frontmatter name `review-cross-repo`. Checklist: REST/API surface, shared types/DTOs, events/messages, shared package versions. Prefer each repo’s `graphify-out/GRAPH_REPORT.md`. Output JSON with `phase: "cross-repo"`, empty `fixed`, only `clarify` (+ notes). Explicit line: **Never apply fixes in this phase.**

- [ ] **Step 3: Commit**

```bash
git add agents/multi-repo-supervisor.md agents/review-cross-repo.md
git commit -m "feat: add multi-repo supervisor and cross-repo review agents"
```

---

### Task 3: Command, finish-plan routing, installer, README

**Files:**
- Create: `commands/multi-review.md`
- Modify: `skills/finish-plan/SKILL.md`
- Modify: `commands/finish-plan.md`
- Modify: `scripts/install-to-project.sh`
- Modify: `README.md`
- Modify: `docs/superpowers/dogfood/engineer-review-checklist.md` (add multi-repo section) OR create `docs/superpowers/dogfood/multi-repo-checklist.md`
- Modify: `docs/superpowers/specs/2026-07-22-multi-repo-supervisor-design.md` — set Status to `Approved`

**Interfaces:**
- Consumes: agents from Task 2
- Produces: `/multi-review`, routed `/finish-plan`, install links, docs

- [ ] **Step 1: Write `/multi-review`**

```markdown
---
description: Multi-repo engineer review (supervisor) for 2+ repositories
argument-hint: "[path ...] [--refresh]"
---

# /multi-review

1. Parse paths from args (if any) as explicit repo override; when present, those paths are the repo set.
2. Follow `multi-repo-protocol.md` discovery if no paths.
3. Invoke `multi-repo-supervisor`.
4. If discovery finds 0 changed repos, stop with a message; if it finds 1 changed repo, run `engineer-reviewer` instead.
```

`--refresh` forces regeneration of parent `multi-repo.json` when not using graphify and no explicit paths were supplied.

- [ ] **Step 2: Extend `finish-plan`**

After HITL approval (step 4), **before** starting review:

1. Run routing from `multi-repo-protocol.md` with its non-mutating probe (detect changed repos without writing `multi-repo.json`).
2. If ≥ 2 → invoke `multi-repo-supervisor` (HITL already answered — do not ask again; pass `hitl_already_approved: true`).
3. If 1 → existing `engineer-reviewer` path.
4. If 0 → stop with a no-changed-repos message.
5. Update the HITL prompt text to mention that multi-repo may be used when relevant:
   > `skip` — start review now (engineer-reviewer or multi-repo-supervisor)

Mirror the same routing note in `commands/finish-plan.md`.

- [ ] **Step 3: Update installer**

In `install_user_bits`, also link:

```bash
link_or_copy "$KIT_ROOT/commands/multi-review.md" "$HOME/.cursor/commands/multi-review.md"
link_or_copy "$KIT_ROOT/agents/multi-repo-supervisor.md" "$HOME/.cursor/agents/multi-repo-supervisor.md"
link_or_copy "$KIT_ROOT/agents/review-cross-repo.md" "$HOME/.cursor/agents/review-cross-repo.md"
```

Keep linking `review-*.md` glob (will pick up `review-cross-repo.md` automatically if glob stays `review-*.md` — verify; if glob already covers it, do not double-link).

- [ ] **Step 4: Update README**

Add a “Multi-repo review” subsection under Usage:

- When it engages (2+ repos)
- Discovery: explicit paths first; otherwise graphify preferred, then parent `.cursor/multi-repo.json`, then in-memory sibling scan
- Commands: `/multi-review`, `/finish-plan` auto-routes
- Link to the design spec
- Note v1.1 Jira/Linear ticket discovery

- [ ] **Step 5: Dogfood checklist**

Create `docs/superpowers/dogfood/multi-repo-checklist.md` with a table for:

| Step | Expect |
|------|--------|
| Single repo only | `engineer-reviewer`, no supervisor |
| No changed repos | stop with a no-changed-repos message |
| Two sibling repos with changes | supervisor + parallel reviews |
| Graphify present | no `multi-repo.json` created |
| `/multi-review path-a path-b` | explicit paths are the repo set |
| `finish-plan` with Graphify absent or unqueryable | sibling scan is in memory only until 2+ changed repos are confirmed |
| Confirmed multi-repo run with Graphify absent or unqueryable | parent `multi-repo.json` created or refreshed |
| Cross-repo endpoint drift | `C_CR*` clarify only, not Fixed |

- [ ] **Step 6: Mark spec Approved**

Change Status line in the design doc to `Approved`.

- [ ] **Step 7: Commit**

```bash
git add commands/multi-review.md commands/finish-plan.md skills/finish-plan \
  scripts/install-to-project.sh README.md docs/superpowers
git commit -m "feat: wire multi-review command, finish-plan routing, and docs"
```

---

### Task 4: Sanity verification

**Files:** none required beyond fixups

- [ ] **Step 1: Tree + grep**

```bash
find agents commands skills/engineer-review skills/finish-plan -type f | sort
rg -n 'multi-repo-supervisor|review-cross-repo|multi-repo-protocol|/multi-review' \
  agents commands skills README.md docs/superpowers
```

Expected: new agents/command/protocol present; finish-plan mentions routing.

- [ ] **Step 2: Installer dry-run**

```bash
TMP=$(mktemp -d)/app && mkdir -p "$TMP" && git -C "$(dirname "$TMP")" init -q 2>/dev/null || true
mkdir -p "$TMP" && git -C "$TMP" init -q
./bin/csp install "$TMP"
test -L "$HOME/.cursor/agents/multi-repo-supervisor.md"
test -L "$HOME/.cursor/commands/multi-review.md"
test -L "$HOME/.cursor/agents/review-cross-repo.md"
```

- [ ] **Step 3: No TBD in new kit files**

```bash
rg -n 'TBD|TODO|implement later' agents/multi-repo-supervisor.md \
  agents/review-cross-repo.md commands/multi-review.md \
  skills/engineer-review/references/multi-repo-protocol.md \
  skills/finish-plan/SKILL.md || true
```

Expected: no hits.

- [ ] **Step 4: Final commit if fixups**

```bash
git add -A && git status
git commit -m "chore: finalize multi-repo supervisor kit wiring" || true
git push -u origin HEAD
```

---

## Self-review (plan vs spec)

| Spec requirement | Task |
|------------------|------|
| Supervisor fan-out parallel | Task 2 |
| Cross-repo phase, clarify-only | Task 2 |
| Single HITL | Task 2 + Task 3 finish-plan |
| Auto-route 1 vs 2+ | Task 1 protocol + Task 3 finish-plan |
| Graphify discovery | Task 1 |
| Parent `multi-repo.json` fallback | Task 1 |
| `/multi-review` paths | Task 3 |
| Unified report | Task 1 + Task 2 |
| No single-repo behavior change | Task 1 routing + Task 3 |
| Jira/Linear out of v1 | Explicit in Global Constraints |
| Installer links new agents/commands | Task 3 |

## Deferred (do not implement in this plan)

- Jira MCP ticket → repos (v1.1, primary)
- Linear MCP ticket → repos (v1.1, secondary)
- Cross-repo auto-apply
