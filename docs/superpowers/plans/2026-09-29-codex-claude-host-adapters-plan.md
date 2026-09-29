# Codex and Claude Code host adapters — implementation plan

> **For agentic workers:** Execute task-by-task. Checkboxes track progress. Kit-only work (edit this repository directly; do **not** run `/csp-start-task` or nest `csp-software-developer` / `csp-bug-fixer` for kit changes).

**Goal:** Make the cursor-spells kit installable and runnable on **Claude Code** and **Codex** (plus existing Cursor) by adding host adapters for install layout, human-in-the-loop choice, subagent dispatch, and command registration — without pretending a bare skills/rules folder copy is enough for a full product shipping pipeline.

**Architecture:** Keep one kit source tree. Add a small **host runtime** layer that (1) detects which agent host is active, (2) installs portable bits into the correct home / project directories, and (3) routes Cursor-only tool calls through host adapters with explicit degrade paths. Skills and process spines stay shared markdown; host-specific glue lives under `hosts/` and is selected at install time and at skill protocol time.

**Tech stack:** Bash installer (`bin/csp`, `scripts/install-to-project.sh`), markdown skills / agents / commands / rules, contract tests under `scripts/tests/`, optional thin markdown “shim” skills for hosts that lack Cursor slash-command directories.

## Global constraints

- Hosts in scope: **Cursor**, **Claude Code**, **Codex**. **Not** Visual Studio Code.
- Agent Skills (`SKILL.md` + references) are the portable unit; Cursor-only product surfaces stay behind adapters or stay Cursor-only (see Non-goals).
- Auto-detect install for the three hosts is in scope and worth doing.
- A fully identical product shipping pipeline needs adapters (human-in-the-loop choice, subagent dispatch, slash-commands / hooks), not a bare folder copy.
- Rules remain process constants (skill-load investigation): do not put always-on author-process rules behind a profile skip list.
- Kit-no-pipeline-dogfood: never develop this kit repository with `/csp-start-*` on itself.
- Plan and foreign-facing docs stay **English**.
- No calendar-time estimates; scope is technical (files, contracts, acceptance checks).

## Assumptions (defaults when evidence is incomplete)

1. **Claude Code** personal skills live under `~/.claude/skills/<name>/SKILL.md`; project skills under `.claude/skills/`. Commands may live under `~/.claude/commands/` or as skill-backed `/name` entries. Agents under `~/.claude/agents/` / `.claude/agents/`. Always-on guidance is primarily `CLAUDE.md` / settings, not Cursor `.mdc` rules. Hooks use Claude’s `settings.json` / `hooks/hooks.json` schema (not Cursor `hooks.json` stop hooks). Interactive closed-set questions use tool `AskUserQuestion` in the **parent** session; nested Agent/subagent sessions generally cannot run that tool.
2. **Codex** always-on guidance is `AGENTS.md` (global `~/.codex/AGENTS.md`, project / nested `AGENTS.md`). Skills discover from `$HOME/.agents/skills` and repo `.agents/skills` (walk from cwd to repo root). Legacy `~/.codex/skills` may still appear in community docs; **prefer `$HOME/.agents/skills` + `.agents/skills`** and verify against current Codex docs during Phase 0. Custom `/csp-*` slash commands are **not** 1:1 with Cursor; invoke via `/skills`, `$skill-name`, or thin skill wrappers. Subagents exist but are a separate product surface from Cursor `Task`.
3. **Cursor** remains the reference host: `~/.cursor` + `<project>/.cursor` install layout in `scripts/install-to-project.sh` stays the default when host is Cursor or detection is ambiguous and the operator did not pass `--host`.
4. Model Context Protocol servers already configured for Jira / GitHub / etc. are out-of-band per host; adapters document required servers but do not vendor credentials.
5. Measured skill-load findings stand: progressive load levels and kit L1 checklists stay; this plan does not re-open model-IQ skill skipping.

---

## Capability matrix

Legend: **Native** = host product support the kit can call directly. **Adapter** = kit must supply a protocol / shim. **Degrade** = typed / CLI / chat fallback. **N/A (v1)** = explicit Cursor-only non-goal for first ship.

| Surface | Cursor (reference) | Claude Code | Codex |
|--------|--------------------|-------------|-------|
| Skills folders | Native: `~/.cursor/skills`, `<project>/.cursor/skills` | Native: `~/.claude/skills`, `.claude/skills` | Native: `$HOME/.agents/skills`, `.agents/skills` (verify `CODEX_HOME` / legacy paths in Phase 0) |
| Always-on process rules | Native: `.cursor/rules/*.mdc` (+ user copies of chat/coding-agent rules) | Adapter: map critical always-on text into `CLAUDE.md` snippets and/or Claude settings; `.mdc` not loaded | Adapter: map into `AGENTS.md` fragments (respect `project_doc_max_bytes`) |
| Slash commands | Native: `commands/csp-*.md` → `/csp-*` | Adapter: install as Claude commands and/or skills that expose `/csp-*` | Adapter: skill entry points (`/skills`, `$name`); no promise of identical `/csp-*` until proven |
| Model Context Protocol | Native | Native (project / plugin `.mcp.json`) | Native |
| Nested coding / review workers | Native: `Task` + `agents/*.md` | Native-ish: Agent / subagents + `agents/*.md` — **Adapter** for wait-for-return and “no Ask in nested worker” contract | Adapter: Codex subagents / thread switch (`/agent`) with wait-for-return protocol; verify parity in Phase 0 |
| Closed-set human-in-the-loop | Native: `AskQuestion` (+ aliases) via `hitl-choice` | Native: `AskUserQuestion` in parent — Adapter alias list; **Degrade** typed tokens; nested workers must not ask | **Degrade first**: typed tokens + approval prompts; probe for any question tool aliases in Phase 0 |
| Pull request open / draft / ready | Adapter today: `gh` (+ optional ManagePullRequest / `ce-commit-push-pr`) | Same `gh`-based path (skill `create-pr`) | Same `gh`-based path |
| Branch UI (`SetActiveBranch`) | Native Cursor IDE metadata | **Degrade**: `git checkout` only; no merge-base tab | **Degrade**: `git checkout` only |
| Canvas (pipeline-flow, Local Diff Review, PR Review Canvas) | Native Cursor plugins / HTML | **N/A (v1)** — link to HTML file in browser / chat diff | **N/A (v1)** |
| Stop / gate hooks | Native: `<project>/.cursor/hooks.json` + scripts | Adapter: translate gate scripts into Claude hook events where feasible; else document manual gate markers | Adapter / **Degrade**: marker files + skill checks only unless Codex hook surface is confirmed |
| Kit install CLI | `csp install` → `~/.cursor` | Extend to `~/.claude` (+ project `.claude`) | Extend to Codex homes (`.agents` / `~/.codex` guidance) |

### What can be shared vs cannot

| Share across hosts | Host-specific (cannot share as-is) |
|--------------------|-------------------------------------|
| `skills/**` bodies (process spines, checklists, presets) | Install destination roots and symlink policies |
| Most `agents/*.md` role prompts (after dispatch adapter) | Cursor `.mdc` rules files; Claude `settings.json` hooks; Codex `AGENTS.md` byte budget packaging |
| Gate marker paths under `.cursor/gates/` (keep path stable for harness) **or** document a host-neutral `.csp/gates/` later | Cursor stop-hook `hooks.json` schema |
| `scripts/*.sh` helpers, harness tests | `SetActiveBranch`, Canvas plugins, Cursor `Task` tool name |
| `hitl-choice` **token contract** and presets | Interactive question **tool name / payload shape** |
| `create-pr` `gh` spine | ManagePullRequest-only flows |

---

## File map (planned)

| Path | Responsibility |
|------|----------------|
| `hosts/README.md` | Host matrix summary + how to add a host |
| `hosts/detect.sh` | Detect `cursor` \| `claude-code` \| `codex` from env, cwd markers, binary presence |
| `hosts/cursor/install-layout.md` | Documents current `~/.cursor` behavior (source of truth for Cursor path) |
| `hosts/claude-code/install-layout.md` | Target dirs, command/agent/skill mapping, CLAUDE.md fragment rules |
| `hosts/codex/install-layout.md` | Target dirs, AGENTS.md fragment rules, skills roots |
| `hosts/claude-code/fragments/` | Small markdown snippets merged into Claude always-on guidance |
| `hosts/codex/fragments/` | Small markdown snippets merged into Codex `AGENTS.md` guidance |
| `scripts/host-detect.sh` | Thin wrapper calling `hosts/detect.sh` (testable) |
| `scripts/install-to-project.sh` | Gain `--host auto\|cursor\|claude-code\|codex` and per-host sync functions |
| `bin/cursor-spells` / `bin/csp` | Surface `--host`, `csp status --host`, help text for three hosts |
| `skills/hitl-choice/SKILL.md` | Extend tool resolution order with Claude / Codex aliases; keep typed fallback |
| `skills/host-runtime/SKILL.md` (new) | Canonical “how to dispatch nested work / wait / degrade” for all hosts |
| `skills/create-pr/SKILL.md` | Clarify `gh` as cross-host default; ManagePullRequest optional Cursor nicety |
| `skills/finish-plan/references/review-surface.md` | Host-aware branch surface (SetActiveBranch vs checkout + status) |
| `scripts/tests/host-detect-test.sh` | Contract tests for detection |
| `scripts/tests/host-install-layout-test.sh` | Temp-home install smoke for each host layout |
| `scripts/tests/hitl-choice-host-aliases-test.sh` | Grep/assert alias order documents Claude + Codex paths |
| `docs/superpowers/dogfood/host-adapters-checklist.md` | Manual smoke checklist per host |

---

## Adapter surfaces (modules / contracts)

Implement as **documented protocols** first (skills + install scripts). Extract shared bash helpers only when a second caller needs them.

### 1. `install-target`

**Produces:** resolved `{ host, user_root, project_root, skills_dir, commands_dir, agents_dir, always_on_files[], hooks_strategy }`

| Host | User root (default) | Project root | Skills | Commands | Agents | Always-on |
|------|---------------------|--------------|--------|----------|--------|-----------|
| `cursor` | `~/.cursor` | `<project>/.cursor` | `skills/` | `commands/` | `agents/` | `rules/*.mdc` copies |
| `claude-code` | `~/.claude` | `<project>/.claude` | `skills/` | `commands/` (and/or skill-as-command) | `agents/` | fragments → `CLAUDE.md` section or `~/.claude/CLAUDE.md` kit block |
| `codex` | `$HOME/.agents` (+ `~/.codex` for AGENTS) | `<project>/.agents` | `skills/` | N/A → skill wrappers | optional agents dir if confirmed | fragments → `~/.codex/AGENTS.md` kit block + optional project `AGENTS.md` include |

**Detection order (`auto`):**

1. Explicit `--host`
2. Env `CSP_HOST`
3. Strong markers: `CURSOR_AGENT` / Cursor-specific env; `CLAUDECODE` / `CLAUDE_CODE`; `CODEX_HOME` / `CODEX_*`
4. Binary heuristics: `cursor` agent session hints; `claude` CLI; `codex` CLI
5. Default: `cursor` (preserves today’s installer)

### 2. `hitl-choice` (human-in-the-loop choice)

Extend tool resolution (attempt order):

1. `AskQuestion` (Cursor)
2. `AskUserQuestion` (Claude Code / some Cursor aliases)
3. `ask_question` / `ask_user` / `request_user_input`
4. Any Phase-0-discovered Codex question tool (only if verified)
5. **Text fallback** with canonical tokens (unchanged contract)

**Hard rule (all hosts):** nested coding / review workers do **not** own closed-set gates. Parent orchestrator waits for return, then asks. Matches current `start-build` / nested Task rule.

### 3. `subagent-dispatch`

New skill `host-runtime` defines:

```text
dispatch(agent_id, prompt, mode) ->
  cursor: Task tool with agents/<id>.md
  claude-code: Agent / subagent with agents/<id>.md (parent waits)
  codex: subagent / thread API documented in hosts/codex (parent waits)
  missing: inline degrade only when skill explicitly allows (e.g. tiny fast path); else stop with skill_missing
```

Acceptance invariant: fire-and-forget dispatch remains a **pipeline bug** on every host.

### 4. `command-registry`

| Host | Strategy |
|------|----------|
| Cursor | Keep `commands/csp-*.md` symlinks |
| Claude Code | Symlink/copy the same markdown into Claude commands **or** generate thin skills named `csp-start-task` etc. that load the command body |
| Codex | Install skills whose `name:` matches pipeline entrypoints; document `$csp-start-task` / `/skills` invocation; optional later generator for Codex custom slash if product adds it |

### 5. `branch-pr`

| Need | Cursor | Claude / Codex |
|------|--------|----------------|
| Feature branch create/checkout | git (shared) | git (shared) |
| IDE merge-base tab | `SetActiveBranch` | Skip tool; print `repo → branch` + `git status` / `git diff --stat` |
| Draft pull request | `gh pr create --draft` (shared) | same |
| Local Diff Review / PR canvas | plugins | **N/A (v1)** — chat diff + browser HTML |

### 6. `hooks-bridge` (phase-gated)

Phase 1 may only **document** Cursor hooks vs Claude hooks vs Codex marker-only. Phase 3 implements Claude hook bridge for plan/build gates if event mapping is proven; otherwise keep skill-enforced markers (`.cursor/gates/...`) as the cross-host source of truth.

---

## Phased implementation

### Phase 0 — Evidence lock (docs + probes, no consumer behavior change)

**Files:**
- Create: `hosts/README.md`
- Create: `hosts/cursor/install-layout.md` (capture current installer behavior)
- Create: `hosts/claude-code/install-layout.md` (draft from public docs + TBD checklist)
- Create: `hosts/codex/install-layout.md` (draft from public docs + TBD checklist)
- Create: `docs/superpowers/dogfood/host-adapters-checklist.md` (manual probe steps)

**Steps:**
- [ ] Write the capability matrix into `hosts/README.md` (copy from this plan; keep one living matrix).
- [ ] On a machine with Claude Code: record exact user/project skill paths, whether symlinks to kit skills load, command discovery, `AskUserQuestion` availability in parent vs Agent, agents folder format.
- [ ] On a machine with Codex: record skills roots (`$HOME/.agents/skills` vs `~/.codex/skills`), whether symlinks are skipped (community reports vary), AGENTS.md merge + byte limits, subagent dispatch wait semantics, any interactive question tool.
- [ ] Update install-layout docs with **measured** paths; mark unverified rows `UNVERIFIED` rather than inventing APIs.

**Acceptance:**
- Every matrix cell is `Native`, `Adapter`, `Degrade`, `N/A (v1)`, or `UNVERIFIED` with a probe step.
- No installer behavior changes yet.
- Does not contradict skill-load specs without new measurements.

---

### Phase 1 — Host detect + install layouts (mechanical)

**Files:**
- Create: `hosts/detect.sh`, `scripts/host-detect.sh`
- Modify: `scripts/install-to-project.sh` (`--host`, per-host `sync_*`)
- Modify: `bin/cursor-spells` help/status
- Create: `scripts/tests/host-detect-test.sh`
- Create: `scripts/tests/host-install-layout-test.sh`

**Detection sketch:**

```bash
# hosts/detect.sh — stdout: cursor | claude-code | codex
csp_detect_host() {
  case "${CSP_HOST:-}${CSP_HOST_OVERRIDE:-}" in
    cursor|claude-code|codex) echo "$CSP_HOST"; return ;;
  esac
  # env markers, then binaries; default cursor
}
```

**Install sketch (Claude):**

```bash
sync_kit_entries_into_claude() {
  local root="$1" # ~/.claude or <project>/.claude
  mkdir -p "$root/skills" "$root/commands" "$root/agents"
  # link skills/* and agents/*; map commands/* similarly
  # write kit path marker; append/refresh managed CLAUDE.md kit block
}
```

**Install sketch (Codex):**

```bash
sync_kit_entries_into_codex() {
  mkdir -p "$HOME/.agents/skills" "$PROJECT/.agents/skills"
  # link skills; prefer copy if host skips symlinks (toggle --copy default per host if Phase 0 proves symlink skip)
  # refresh managed block in ~/.codex/AGENTS.md between markers:
  # <!-- cursor-spells:begin --> … <!-- cursor-spells:end -->
}
```

**Steps:**
- [ ] Implement detection + unit/contract tests with env fixtures.
- [ ] Refactor Cursor sync into a named function (behavior-preserving).
- [ ] Add Claude and Codex sync paths behind `--host`; `auto` uses detection.
- [ ] Temp `HOME` / temp project tests assert expected directories and markers exist.
- [ ] `csp status` prints detected host + linked roots.

**Acceptance:**
- `CSP_HOST=claude-code` + temp homes creates Claude layout without touching `~/.cursor` in the test sandbox.
- `CSP_HOST=codex` creates Codex skills + AGENTS managed block in the sandbox.
- Default / Cursor path still passes existing install-related expectations (no regression on Cursor symlink set).
- Kit install into the kit repo itself remains refused for project bits.

---

### Phase 2 — Runtime adapters (hitl + dispatch + review-surface)

**Files:**
- Create: `skills/host-runtime/SKILL.md`
- Modify: `skills/hitl-choice/SKILL.md` (+ optional `references/host-tools.md`)
- Modify: `rules/hitl-askquestion.mdc` (host-neutral wording: “session question tool”, list aliases)
- Modify: `skills/start-build/SKILL.md`, `skills/software-developer/SKILL.md`, `skills/trajectory-judge/SKILL.md`, `skills/engineer-review/SKILL.md` — point nested dispatch at `host-runtime`
- Modify: `skills/finish-plan/references/review-surface.md`, `skills/create-pr/SKILL.md`
- Create: `scripts/tests/hitl-choice-host-aliases-test.sh`
- Create: `scripts/tests/host-runtime-contract-test.sh`

**Steps:**
- [ ] Document dispatch + wait-for-return + nested-no-ask invariants in `host-runtime`.
- [ ] Extend `hitl-choice` alias list; keep presets lazy-load behavior from skill-load plan.
- [ ] Review-surface: if `SetActiveBranch` missing → checkout + report; never fail the gate solely for missing IDE metadata.
- [ ] `create-pr`: state `gh` as required cross-host path; Cursor ManagePullRequest optional.
- [ ] Contract tests: skill text must mention Claude `AskUserQuestion`, nested-no-ask, and fire-and-forget forbidden on all hosts.

**Acceptance:**
- Harness / trajectory wiring tests that grep `hitl-choice` / AskQuestion still pass (aliases additive).
- `host-runtime` names all three hosts and the degrade path.
- No canvas requirement on non-Cursor hosts for `finish-plan` to proceed.

---

### Phase 3 — Commands, always-on fragments, hooks bridge

**Files:**
- Create: `hosts/claude-code/fragments/*.md`, `hosts/codex/fragments/*.md`
- Modify: installer to refresh managed always-on blocks
- Modify or generate: Claude command install; Codex skill entry wrappers if commands do not map
- Optional: `hosts/claude-code/hooks-bridge.md` + scripts translating gate checks
- Update: `README.md` install section for multi-host
- Create: dogfood checklist execution notes

**Steps:**
- [ ] Ship minimal always-on fragments: `plain-language-chat` summary, `code-via-coding-agents`, `hitl` attempt-question-first, kit-no-pipeline-dogfood (kit clone only).
- [ ] Keep full Cursor `.mdc` installs on Cursor; do not delete them.
- [ ] Map top entry commands: `csp-start-task`, `csp-start-task --fast` equivalent, `csp-start-issue-task`, `csp-approve-plan`, `csp-finish-plan`, `csp-pr-review`, `csp-engineer-review`.
- [ ] Hooks: implement Claude bridge **only** if Phase 0 mapped events; else document marker-only enforcement and keep Cursor hooks as-is.

**Acceptance:**
- Fresh Claude install: operator can invoke start-task entrypoint without manually copying folders.
- Fresh Codex install: operator can invoke the same spine via documented skill trigger.
- Managed AGENTS/CLAUDE blocks are idempotent on `csp update` (markers prevent duplication).
- Cursor install path unchanged for existing consumers.

---

### Phase 4 — Pipeline parity slice (smoke, not full product twin)

**Scope:** Prove one vertical slice on each non-Cursor host:

1. Install kit for that host  
2. Run approve-plan **or** start-task `--fast` style thin path on a toy consumer repo  
3. Hit at least one `hitl-choice` gate (buttons or typed tokens)  
4. Nested implementer return → parent continues  
5. `propose-commit` + `create-pr` draft via `gh` (or stop with clear missing-`gh` error)

**Files:**
- Update: `docs/superpowers/dogfood/host-adapters-checklist.md` with pass/fail log template
- Optional: `evals/harness/host-adapters/` fixtures for marker/gate scripts only

**Acceptance:**
- Checklist completed once per host (or `BLOCKED` with exact missing product API).
- No claim of canvas / SetActiveBranch parity.
- Harness-bench quality on Cursor remains green (no Cursor regression).

---

## Non-goals (v1)

- Visual Studio Code host support.
- Pixel-identical Local Diff Review / PR Review / pipeline Canvas on Claude Code or Codex.
- `SetActiveBranch` emulator inside other IDEs.
- Fully identical stop-hook semantics on Codex if the product has no equivalent.
- Replacing `gh` with a new pull-request service abstraction.
- Auto model-capability skill skipping (rejected in skill-load investigation).
- Vendoring third-party skill bodies into the kit.
- Running `/csp-start-task` against this kit repository.
- Rewriting all Ukrainian internal chat preferences into host fragments (chat language rules stay as today; foreign-facing docs English).

---

## Test strategy

| Layer | What | Command / method |
|-------|------|------------------|
| Contract | Host detect fixtures | `bash scripts/tests/host-detect-test.sh` |
| Contract | Temp-home install layouts | `bash scripts/tests/host-install-layout-test.sh` |
| Contract | hitl + host-runtime wording | `bash scripts/tests/hitl-choice-host-aliases-test.sh`, `host-runtime-contract-test.sh` |
| Regression | Existing kit tests touched by skill edits | Relevant `scripts/tests/*` + `bash scripts/harness-bench.sh` when spines change |
| Manual smoke | Dogfood checklist on Claude Code and Codex | `docs/superpowers/dogfood/host-adapters-checklist.md` |
| Evidence | Phase 0 probe notes | Update `hosts/*/install-layout.md` with measured results |

Manual GUI recording is optional; CLI transcript paste into the dogfood checklist is enough for v1.

---

## Open questions / risks

1. **Codex symlink policy:** if Codex skips symlinked skills, default that host to `--copy` or hard-link refresh — decide in Phase 0.
2. **Codex interactive questions:** if no question tool exists, typed-token human-in-the-loop is the product UX; button parity stays Cursor/Claude.
3. **Claude nested AskUserQuestion:** confirmed unsupported in subagents — reinforces parent-owned gates; risk if authors “helpfully” ask inside Agent workers.
4. **AGENTS.md byte cap:** kit fragments must stay small; link out to skills instead of pasting spines.
5. **Gate path coupling:** keeping `.cursor/gates/` on non-Cursor hosts is slightly odd but maximizes harness reuse; alternatively introduce `.csp/gates/` later with a compatibility symlink — defer unless dogfood pain is high.
6. **Hook schema drift:** Claude hooks evolve independently of Cursor stop hooks; a naive JSON copy will fail — bridge is explicit translation or no-op.
7. **Command UX gap on Codex:** operators may not find `$skill` vs Cursor `/csp-*`; mitigate with README + `csp status` hints + optional always-on “entrypoints” section in AGENTS.md.
8. **Dual-install machines:** developers with Cursor + Claude + Codex need non-destructive multi-root installs; `csp install --host all` may be Phase 3 convenience (install to every detected root) — default remains single host per invocation.
9. **UNVERIFIED cells:** Phase 1 must not invent APIs; prefer degrade paths until Phase 0 clears them.

---

## Self-review (spec coverage)

| Deliverable request | Covered by |
|---------------------|------------|
| Capability matrix | § Capability matrix + `hosts/README.md` in Phase 0 |
| Adapter surfaces | § Adapter surfaces |
| Install/layout + detect | Phase 1 + Assumptions |
| Phased steps + acceptance | Phases 0–4 |
| Non-goals | § Non-goals |
| Test strategy | § Test strategy |
| Open questions / risks | § Open questions / risks |
| Reuse skill-load findings | Global constraints + Assumptions #5 |
| English plan under `docs/superpowers/plans/` | This file |

---

## Execution handoff

Plan complete for implementation. Preferred order: Phase 0 probes → Phase 1 installer → Phase 2 runtime skills → Phase 3 commands/fragments → Phase 4 dogfood smoke. Kit-only edits in the parent chat; no nested product coding agents for this repository.
