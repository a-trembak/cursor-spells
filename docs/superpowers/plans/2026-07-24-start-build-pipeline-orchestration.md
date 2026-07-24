# Start-Build Gate & Pipeline Orchestration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `start-build` gate that auto-runs `implementation-critic` before any plan execution starts (mirroring the existing post-plan `finish-plan` gate), turn `/start-task` into the full pipeline orchestrator (AC → tech-spec → plan → pre-build critique → execution → finish-plan → engineer-review), and fix a real gap: `install-to-project.sh` never wired the `tech-spec`, `implementation-critic`, or `code-comments` sub-projects into a consumer install at all.

**Architecture:** `start-build` is a skill+command+rule+hook quadruple that exactly mirrors the already-shipped `finish-plan` gate's shape (skill does the enforced work, rule is a glob-triggered backup, hook nudges if the marker is stuck) — the only structural difference is that `start-build`'s critique step runs automatically (no permission needed to start, since `implementation-critic` is read-only), gating only on the *outcome* (`Verdict`). `/start-task` is rewritten as a thin orchestrator that invokes each existing stage in order and never invents an answer at any of the pipeline's already-established HITL gates.

**Tech Stack:** Markdown-based Cursor skill/agent/command/rule definitions + POSIX shell hook scripts — same format as the four sub-projects already shipped on this branch.

## Global Constraints

- `start-build` never asks permission to *start* the critique (it's read-only) — it only stops if the critique's `Verdict` is `blocked` or `clear pending accept`.
- `/start-task` never invents an answer at any HITL gate (tech-spec entry question, Blocker/Decision questions, `approve-spec`/`revise`/`skip`, blocked critique, `finish-plan`'s `skip`/`approve`/`done`, review clarifications) — it only removes the need to manually re-invoke each stage's command.
- The pre-build gate marker (`.cursor/build-gate.pending`) lives in the **consumer project**, never in the kit, exactly like the existing `.cursor/review-gate.pending`.
- Do not modify `skills/tech-spec/`, `agents/tech-spec.md`, `skills/implementation-critic/`, `agents/implementation-critic.md`, `skills/finish-plan/`, or `commands/finish-plan.md` — all already shipped and reviewed; `/start-task` and `start-build` only *invoke* them, they don't change their contracts.
- `install-to-project.sh`'s existing default behavior (hooks + rule on by default with a project path, `--no-hooks`/`--no-rule` to skip) is preserved — this plan only adds more items to what gets installed, it doesn't change the flags' semantics.
- Frequent, small commits — one per task.
- All `grep`-based verification-count expectations in this plan were computed by writing each task's exact draft content to a scratch file and running the real `grep -c` command against it before finalizing the numbers.

---

## File Structure

- `skills/start-build/SKILL.md` (new) — the pre-build critique gate, mirrors `skills/finish-plan/SKILL.md`'s shape
- `commands/start-build.md` (new) — `/start-build [plan-path]` manual entry point
- `rules/before-build-critique-gate.mdc` (new) — glob-triggered backup, mirrors `rules/after-plan-review-gate.mdc`
- `hooks/pre-build-gate.sh` (new) — stop-hook nudge if `.cursor/build-gate.pending` is still present, mirrors `hooks/post-plan-review-gate.sh`
- `hooks/hooks.json` (modified) — registers the new hook alongside the existing one
- `commands/start-task.md` (modified, full replacement) — becomes the pipeline orchestrator
- `scripts/install-to-project.sh` (modified, full replacement) — wires every sub-project's skill/agent/command into `install_user_bits`, and the new hook + rule into `install_project_bits`
- `bin/cursor-spells` (modified, targeted edit) — usage hint mentions the new commands
- `README.md` (modified) — Skills table row + rewritten "Start a task" usage section + new "Pre-build critique gate" section

Each new file has one responsibility, mirroring an existing, already-proven artifact one-to-one (`start-build` ↔ `finish-plan`) rather than inventing a new mechanism.

---

### Task 1: Create the `start-build` skill

**Files:**
- Create: `skills/start-build/SKILL.md`

**Interfaces:**
- Produces: the skill name `start-build`, the marker path `.cursor/build-gate.pending`, and the "auto-run critique, gate only on Verdict" behavior that Tasks 2, 3, and 4 all depend on.

- [ ] **Step 1: Write the skill file**

```markdown
---
name: start-build
description: >-
  Use when an implementation plan is approved and about to be executed
  task-by-task (subagent-driven-development or executing-plans), before Task
  1 is dispatched. Auto-runs the implementation-critic gate so a human
  doesn't have to remember to critique the plan first.
---

# Start Build

Reliable handoff from an approved plan into execution. Auto-runs `implementation-critic` so build never starts on an uncritiqued plan — prefer this over hoping a global rule fires.

## When to Use

- An implementation plan exists (from `writing-plans`) and is about to be executed
- Before dispatching Task 1 via `subagent-driven-development` or `executing-plans`
- Not for re-running critique on a plan already `clear` for this exact revision (skip straight to execution)

## Steps (mandatory order)

1. **Write marker** in the **current project** (not the kit):

   ```bash
   mkdir -p .cursor
   printf '%s\n' "<plan-path>" > .cursor/build-gate.pending
   ```

2. **Auto-run the critique** — no HITL needed to start it, `implementation-critic` is read-only:
   - Invoke skill `implementation-critic` (or `/critique-plan <plan-path>`) against the plan.
3. **On `Verdict: clear`:**
   - Delete `.cursor/build-gate.pending`.
   - Proceed directly to execution: dispatch `subagent-driven-development` (default) unless the user already specified `executing-plans` for a separate session.
4. **On `Verdict: blocked` or `clear pending accept`:**
   - Keep the marker.
   - **Stop** and show the critic's report. Wait for the user to revise the plan (re-run this skill after) or reply `accept F<id>` for open findings.
5. Do **not** dispatch Task 1 until `Verdict` is `clear` (with any accept-risk items explicitly accepted).

## Notes

- Re-running after a plan revision produces a fresh critique — the marker keeps the gate honest across turns.
- Manual `/critique-plan` still works standalone for an ad-hoc look; this skill is the enforced pre-build path.
```

- [ ] **Step 2: Verify structure**

Run: `grep -c "^name: start-build$" skills/start-build/SKILL.md && grep -c "build-gate.pending" skills/start-build/SKILL.md && grep -c "implementation-critic" skills/start-build/SKILL.md && grep -c "Verdict: clear" skills/start-build/SKILL.md && grep -c "subagent-driven-development" skills/start-build/SKILL.md`
Expected: `1`, `2`, `4`, `1`, `3`

- [ ] **Step 3: Commit**

```bash
git add skills/start-build/SKILL.md
git commit -m "Add start-build skill: pre-build critique gate"
```

---

### Task 2: Create the `/start-build` command

**Files:**
- Create: `commands/start-build.md`

**Interfaces:**
- Consumes: skill name `start-build` from Task 1.

- [ ] **Step 1: Write the command file**

```markdown
---
description: Run the pre-build critique gate, then start executing an approved implementation plan
argument-hint: "[path/to/plan.md]"
---

# /start-build

Run skill `start-build`:

1. Write `.cursor/build-gate.pending` with the plan path.
2. Auto-run `implementation-critic` against the plan (no permission needed — read-only).
3. If `Verdict: clear`, delete the marker and dispatch `subagent-driven-development` to execute the plan.
4. If `Verdict` is `blocked` or `clear pending accept`, stop and show findings; wait for a plan revision or `accept F<id>` replies.

## Arguments

- Optional plan path. If omitted, use the most recently modified file under `docs/**/plans/` and confirm it with the user before proceeding.

## Notes

- This command never edits the plan itself — only `implementation-critic`'s own report output, unchanged.
- Do not start Task 1 while `Verdict: blocked`.
```

- [ ] **Step 2: Verify structure**

Run: `grep -c "start-build" commands/start-build.md && grep -c "build-gate.pending" commands/start-build.md && grep -c "implementation-critic" commands/start-build.md`
Expected: `2`, `1`, `2`

- [ ] **Step 3: Commit**

```bash
git add commands/start-build.md
git commit -m "Add /start-build command"
```

---

### Task 3: Create the before-build rule backup

**Files:**
- Create: `rules/before-build-critique-gate.mdc`

**Interfaces:**
- Consumes: skill name `start-build` and marker path from Task 1.

- [ ] **Step 1: Write the rule file**

```markdown
---
description: Before executing a plan task-by-task, auto-run the implementation-critic gate
alwaysApply: false
globs:
  - docs/**/plans/**/*.md
  - docs/superpowers/plans/**/*.md
  - **/plans/**/*.md
---

# Before-build critique gate

> Install this rule **per consumer project** (`.cursor/rules/`), not as a user-global always-on rule.
> Reliable path: skill/command `start-build` (always writes the marker and auto-runs the critique).

Before you **dispatch Task 1** of an implementation plan (via `subagent-driven-development` or `executing-plans`):

1. Prefer invoking skill **`start-build`** (writes marker + auto-runs `implementation-critic`, no permission needed to start it).
2. If you cannot load that skill, still:
   - Create `.cursor/build-gate.pending` (one line: the plan path)
   - Run `implementation-critic` / `/critique-plan` against the plan
   - **Stop** if `Verdict` is `blocked` or `clear pending accept` — do not dispatch Task 1

3. Do **not** dispatch Task 1 until `Verdict` is `clear` (all accept-risk items explicitly accepted).
4. On a clean `Verdict: clear`: delete `.cursor/build-gate.pending` and proceed to execution automatically — no separate permission needed for this transition.

Does not apply to pure Q&A, docs-only answers, or when the user already launched `/start-build` or `/critique-plan` manually and is now explicitly asking to proceed.
```

- [ ] **Step 2: Verify structure**

Run: `grep -c "^# Before-build critique gate$" rules/before-build-critique-gate.mdc && grep -c "start-build" rules/before-build-critique-gate.mdc && grep -c "build-gate.pending" rules/before-build-critique-gate.mdc`
Expected: `1`, `3`, `2`

- [ ] **Step 3: Commit**

```bash
git add rules/before-build-critique-gate.mdc
git commit -m "Add before-build-critique-gate rule as backup enforcement"
```

---

### Task 4: Create the pre-build stop hook

**Files:**
- Create: `hooks/pre-build-gate.sh`

**Interfaces:**
- Consumes: marker path `.cursor/build-gate.pending` from Task 1.
- Produces: the hook command path `.cursor/hooks/pre-build-gate.sh` that Task 5 registers in `hooks.json`.

- [ ] **Step 1: Write the hook script**

```bash
#!/usr/bin/env bash
# Reminds the agent about the pre-build critique gate if it's still pending.
# Does NOT auto-dispatch Task 1 (preserves the critique gate).
# Install: copy/symlink this file + hooks.json into the consumer project's .cursor/

set -euo pipefail

input="$(cat || true)"

# Prefer workspace root from hook payload when present; else cwd
root="$(pwd)"
if command -v jq >/dev/null 2>&1; then
  w="$(printf '%s' "$input" | jq -r '.workspace_roots[0] // .cwd // empty' 2>/dev/null || true)"
  if [[ -n "${w:-}" && -d "$w" ]]; then
    root="$w"
  fi
fi

marker="$root/.cursor/build-gate.pending"

if [[ -f "$marker" ]]; then
  status=""
  if command -v jq >/dev/null 2>&1; then
    status="$(printf '%s' "$input" | jq -r '.status // empty' 2>/dev/null || true)"
  else
    status="$(printf '%s' "$input" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  fi

  if [[ "$status" == "aborted" || "$status" == "error" ]]; then
    printf '%s\n' '{}'
    exit 0
  fi

  plan_path="$(cat "$marker" 2>/dev/null || true)"
  printf '%s\n' "{\"followup_message\":\"Build-gate marker still present (.cursor/build-gate.pending, plan: ${plan_path}). implementation-critic found blocking findings or accept-risk items pending. Resolve them (revise the plan or reply accept F<id>) before dispatching Task 1.\"}"
  exit 0
fi

printf '%s\n' '{}'
exit 0
```

- [ ] **Step 2: Verify syntax and structure**

Run: `bash -n hooks/pre-build-gate.sh && echo "syntax OK" && grep -c "build-gate.pending" hooks/pre-build-gate.sh && grep -c "followup_message" hooks/pre-build-gate.sh`
Expected: `syntax OK`, `2`, `1`

- [ ] **Step 3: Make executable and commit**

```bash
chmod +x hooks/pre-build-gate.sh
git add hooks/pre-build-gate.sh
git commit -m "Add pre-build-gate hook for stuck build-gate marker"
```

---

### Task 5: Register the new hook in `hooks.json`

**Files:**
- Modify: `hooks/hooks.json` (full replacement)

**Interfaces:**
- Consumes: hook command path from Task 4.

- [ ] **Step 1: Replace the file content**

```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": ".cursor/hooks/post-plan-review-gate.sh",
        "loop_limit": 3
      },
      {
        "command": ".cursor/hooks/pre-build-gate.sh",
        "loop_limit": 3
      }
    ]
  }
}
```

- [ ] **Step 2: Verify valid JSON and both hooks present**

Run: `python3 -c "import json; json.load(open('hooks/hooks.json')); print('valid JSON')" && grep -c "pre-build-gate.sh" hooks/hooks.json && grep -c "post-plan-review-gate.sh" hooks/hooks.json`
Expected: `valid JSON`, `1`, `1`

- [ ] **Step 3: Commit**

```bash
git add hooks/hooks.json
git commit -m "Register pre-build-gate hook alongside post-plan-review-gate"
```

---

### Task 6: Rewrite `/start-task` as the pipeline orchestrator

**Files:**
- Modify: `commands/start-task.md` (full replacement)

**Interfaces:**
- Consumes: `tech-spec` (already shipped), `writing-plans` (external superpowers skill), `start-build` (Task 1), `subagent-driven-development` (external superpowers skill), `finish-plan` (already shipped), `engineer-reviewer` (already shipped).

- [ ] **Step 1: Replace the file content**

```markdown
---
description: Orchestrate the full pipeline from Acceptance Criteria to a reviewed PR — bootstrap, tech spec, plan, pre-build critique, execution, and post-plan review, stopping only at established human-in-the-loop gates
argument-hint: "[ac-source]"
---

# /start-task

Entry point for the whole pipeline. Chains every stage automatically except the established human-in-the-loop (HITL) gates — it does not skip or soften any of them.

## Arguments

- Optional AC source: a ticket id, a Jira/tracker URL, a file path, or inline text. If omitted, ask for it.

## Pipeline (in order)

1. **Bootstrap** (automatic):
   - Read `.cursor/project-patterns.md` in the current project if present (create it via the `engineer-review` patterns flow on first use of this kit in a project, if entirely absent).
   - Detect the project's stack mechanically (same signals as `skill-map.md`'s stack-detection table: `package.json`, `pom.xml`, `docker-compose`, dependency names) — no reasoning call, a table lookup.
2. **Tech spec** — invoke skill `tech-spec` (agent `tech-spec`) with the AC source, the patterns file path (if found), and the detected stack label:
   - **HITL:** the entry question (`human` / `agent`).
   - **HITL:** any Blocker/Decision-tier questions the draft surfaces, per `references/question-discipline.md`.
   - **HITL:** `approve-spec` / `revise` / `skip <reason>`.
3. **Plan** (automatic once the spec's `Status` is `approved` or explicitly `skip`ped): invoke `writing-plans` with the tech spec as input to produce the implementation plan. Do not ask which execution strategy yet — that's decided in step 5.
4. **Pre-build critique** (automatic start, HITL only if blocked): invoke skill `start-build` on the new plan.
   - **HITL:** only if `implementation-critic`'s `Verdict` is `blocked` or `clear pending accept` — wait for a plan revision or `accept F<id>` replies.
5. **Execution** (automatic once `Verdict: clear`): dispatch `subagent-driven-development` by default (fresh implementer + task reviewer per task, continuous execution) — do not ask "which approach?" in this orchestrated flow. If the user has already indicated they want a separate session, honor `executing-plans` instead.
6. **Finish plan** (automatic invocation of the existing HITL gate): once all tasks are complete, invoke skill `finish-plan`:
   - **HITL:** `skip` / `approve` / `done` before `engineer-review` starts.
7. **Engineer review** (automatic once the HITL gate clears): run `engineer-reviewer` (or `multi-repo-supervisor` for 2+ changed repos).
   - **HITL:** only for `Needs clarification` items the review surfaces.

## Notes

- This command never invents an answer at any HITL gate above — it always stops and waits for the human's reply at exactly those points, and only those points.
- If AC do not exist yet, stop and say so — writing AC themselves is out of scope for this kit.
- A Jira/tracker URL is accepted as the AC source verbatim (recorded as a reference in the tech spec's "AC references" section) — this kit does not fetch ticket contents via an API; paste the relevant description/AC text alongside the link if the tech-spec agent needs more than the link itself.
```

- [ ] **Step 2: Verify all 7 pipeline steps and HITL markers are present**

Run: `grep -c "^## Pipeline" commands/start-task.md && grep -c "^[0-9]\. \*\*" commands/start-task.md && grep -c "HITL" commands/start-task.md && grep -c "start-build" commands/start-task.md`
Expected: `1`, `7`, `11`, `1`

- [ ] **Step 3: Commit**

```bash
git add commands/start-task.md
git commit -m "Rewrite /start-task as the full pipeline orchestrator"
```

---

### Task 7: Fix `install-to-project.sh` to wire every sub-project and the new gate

**Files:**
- Modify: `scripts/install-to-project.sh` (full replacement)

**Interfaces:**
- Consumes: every skill/command/agent path from the four already-shipped sub-projects plus Tasks 1, 2, 3, 4 of this plan.

- [ ] **Step 1: Replace the file content**

```bash
#!/usr/bin/env bash
# Install cursor-spells into Cursor (~/.cursor) and optionally a consumer project.
# Prefer: bin/cursor-spells install <project>
#
# Usage:
#   ./scripts/install-to-project.sh /path/to/consumer-repo
#   ./scripts/install-to-project.sh . --humanizer
#   ./scripts/install-to-project.sh --user-only
#
# Default with a project path: symlink skills/commands/agents into ~/.cursor,
# copy hooks + rules + patterns check into the project.

set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT=""
USER_SKILLS=0
USER_ONLY=0
WITH_HOOKS=0
WITH_RULE=0
WITH_HUMANIZER=0
COPY_MODE=0

usage() {
  cat <<'EOF'
Install cursor-spells engineer-review workflow.

Usage:
  install-to-project.sh <project-path> [flags]
  install-to-project.sh --user-only [flags]

Flags:
  --user-only      Only install into ~/.cursor
  --user-skills    (noop alias; user bits always install with a project)
  --humanizer      Also install english-humanizer
  --copy           Copy into ~/.cursor instead of symlink
  --hooks          Include hooks (default with project path)
  --rule           Include rule (default with project path)
  --no-hooks       Skip hooks even for project install
  --no-rule        Skip rule even for project install
  -h, --help       Show help

Keep one clone of cursor-spells; run this against each app. Do not vendor the
kit inside every repository.
EOF
  exit "${1:-0}"
}

SKIP_HOOKS=0
SKIP_RULE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --user-only|--global) USER_ONLY=1; USER_SKILLS=1; shift ;;
    --user-skills) USER_SKILLS=1; shift ;;
    --hooks) WITH_HOOKS=1; shift ;;
    --rule) WITH_RULE=1; shift ;;
    --no-hooks) SKIP_HOOKS=1; shift ;;
    --no-rule) SKIP_RULE=1; shift ;;
    --humanizer) WITH_HUMANIZER=1; shift ;;
    --copy) COPY_MODE=1; shift ;;
    --*)
      echo "Unknown flag: $1" >&2
      usage 1
      ;;
    *)
      if [[ -n "$PROJECT" ]]; then
        echo "Unexpected argument: $1" >&2
        usage 1
      fi
      PROJECT="$1"
      shift
      ;;
  esac
done

if [[ "$USER_ONLY" -eq 0 && -z "$PROJECT" ]]; then
  echo "Provide a consumer project path, or --user-only" >&2
  usage 1
fi

if [[ -n "$PROJECT" ]]; then
  if [[ ! -d "$PROJECT" ]]; then
    echo "Project path does not exist: $PROJECT" >&2
    exit 1
  fi
  PROJECT="$(cd "$PROJECT" && pwd)"
fi

link_or_copy() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "skip (exists): $dest"
    return 0
  fi
  if [[ "$COPY_MODE" -eq 1 ]]; then
    cp -R "$src" "$dest"
    echo "copied: $dest"
  else
    ln -s "$src" "$dest"
    echo "linked: $dest -> $src"
  fi
}

install_user_bits() {
  mkdir -p "$HOME/.cursor/skills" "$HOME/.cursor/commands" "$HOME/.cursor/agents"
  link_or_copy "$KIT_ROOT/skills/engineer-review" "$HOME/.cursor/skills/engineer-review"
  link_or_copy "$KIT_ROOT/skills/finish-plan" "$HOME/.cursor/skills/finish-plan"
  link_or_copy "$KIT_ROOT/skills/start-build" "$HOME/.cursor/skills/start-build"
  link_or_copy "$KIT_ROOT/skills/tech-spec" "$HOME/.cursor/skills/tech-spec"
  link_or_copy "$KIT_ROOT/skills/implementation-critic" "$HOME/.cursor/skills/implementation-critic"
  link_or_copy "$KIT_ROOT/skills/code-comments" "$HOME/.cursor/skills/code-comments"
  link_or_copy "$KIT_ROOT/commands/engineer-review.md" "$HOME/.cursor/commands/engineer-review.md"
  link_or_copy "$KIT_ROOT/commands/finish-plan.md" "$HOME/.cursor/commands/finish-plan.md"
  link_or_copy "$KIT_ROOT/commands/multi-review.md" "$HOME/.cursor/commands/multi-review.md"
  link_or_copy "$KIT_ROOT/commands/start-task.md" "$HOME/.cursor/commands/start-task.md"
  link_or_copy "$KIT_ROOT/commands/write-tech-spec.md" "$HOME/.cursor/commands/write-tech-spec.md"
  link_or_copy "$KIT_ROOT/commands/critique-plan.md" "$HOME/.cursor/commands/critique-plan.md"
  link_or_copy "$KIT_ROOT/commands/start-build.md" "$HOME/.cursor/commands/start-build.md"
  link_or_copy "$KIT_ROOT/agents/engineer-reviewer.md" "$HOME/.cursor/agents/engineer-reviewer.md"
  link_or_copy "$KIT_ROOT/agents/multi-repo-supervisor.md" "$HOME/.cursor/agents/multi-repo-supervisor.md"
  link_or_copy "$KIT_ROOT/agents/tech-spec.md" "$HOME/.cursor/agents/tech-spec.md"
  link_or_copy "$KIT_ROOT/agents/implementation-critic.md" "$HOME/.cursor/agents/implementation-critic.md"
  local f
  for f in "$KIT_ROOT"/agents/review-*.md; do
    link_or_copy "$f" "$HOME/.cursor/agents/$(basename "$f")"
  done
  if [[ "$WITH_HUMANIZER" -eq 1 ]]; then
    link_or_copy "$KIT_ROOT/skills/english-humanizer" "$HOME/.cursor/skills/english-humanizer"
  fi
}

install_project_bits() {
  mkdir -p "$PROJECT/.cursor/hooks" "$PROJECT/.cursor/rules" "$PROJECT/.cursor"
  if [[ "$WITH_HOOKS" -eq 1 ]]; then
    if [[ ! -f "$PROJECT/.cursor/hooks.json" ]]; then
      cp "$KIT_ROOT/hooks/hooks.json" "$PROJECT/.cursor/hooks.json"
      echo "copied: $PROJECT/.cursor/hooks.json"
    else
      echo "skip (exists): $PROJECT/.cursor/hooks.json (merge stop hooks manually if needed)"
    fi
    cp "$KIT_ROOT/hooks/post-plan-review-gate.sh" "$PROJECT/.cursor/hooks/post-plan-review-gate.sh"
    chmod +x "$PROJECT/.cursor/hooks/post-plan-review-gate.sh"
    echo "copied: $PROJECT/.cursor/hooks/post-plan-review-gate.sh"
    cp "$KIT_ROOT/hooks/pre-build-gate.sh" "$PROJECT/.cursor/hooks/pre-build-gate.sh"
    chmod +x "$PROJECT/.cursor/hooks/pre-build-gate.sh"
    echo "copied: $PROJECT/.cursor/hooks/pre-build-gate.sh"
  fi
  if [[ "$WITH_RULE" -eq 1 ]]; then
    # Project-scoped rules (safe). Do NOT alwaysApply at user-global level.
    cp "$KIT_ROOT/rules/after-plan-review-gate.mdc" "$PROJECT/.cursor/rules/after-plan-review-gate.mdc"
    echo "copied: $PROJECT/.cursor/rules/after-plan-review-gate.mdc"
    cp "$KIT_ROOT/rules/before-build-critique-gate.mdc" "$PROJECT/.cursor/rules/before-build-critique-gate.mdc"
    echo "copied: $PROJECT/.cursor/rules/before-build-critique-gate.mdc"
  fi
  # Optional CI helper
  mkdir -p "$PROJECT/scripts"
  if [[ ! -f "$PROJECT/scripts/check-project-patterns.sh" ]]; then
    cp "$KIT_ROOT/scripts/check-project-patterns.sh" "$PROJECT/scripts/check-project-patterns.sh"
    chmod +x "$PROJECT/scripts/check-project-patterns.sh"
    echo "copied: $PROJECT/scripts/check-project-patterns.sh"
  fi
}

echo "kit: $KIT_ROOT"
if [[ "$USER_SKILLS" -eq 1 || "$USER_ONLY" -eq 1 || -n "$PROJECT" ]]; then
  # Always install user skills/agents when targeting a project (needed for /commands)
  install_user_bits
fi
if [[ "$USER_ONLY" -eq 0 && -n "$PROJECT" ]]; then
  # Default project install includes hooks + rules for HITL reliability
  if [[ "$SKIP_HOOKS" -eq 0 ]]; then WITH_HOOKS=1; else WITH_HOOKS=0; fi
  if [[ "$SKIP_RULE" -eq 0 ]]; then WITH_RULE=1; else WITH_RULE=0; fi
  install_project_bits
fi

echo "done."
if [[ -n "$PROJECT" ]]; then
  echo "project: $PROJECT"
  echo "next: open the project in Cursor → /start-task to run the whole pipeline, /finish-plan after plans, /start-build before executing a plan manually, /engineer-review anytime"
fi
echo "tip: npx skills add vercel-labs/agent-skills@vercel-react-best-practices"
```

- [ ] **Step 2: Verify syntax and full wiring**

Run: `bash -n scripts/install-to-project.sh && echo "syntax OK" && grep -c "skills/tech-spec" scripts/install-to-project.sh && grep -c "skills/implementation-critic" scripts/install-to-project.sh && grep -c "skills/code-comments" scripts/install-to-project.sh && grep -c "skills/start-build" scripts/install-to-project.sh && grep -c "commands/start-task.md" scripts/install-to-project.sh && grep -c "commands/write-tech-spec.md" scripts/install-to-project.sh && grep -c "commands/critique-plan.md" scripts/install-to-project.sh && grep -c "commands/start-build.md" scripts/install-to-project.sh && grep -c "agents/tech-spec.md" scripts/install-to-project.sh && grep -c "agents/implementation-critic.md" scripts/install-to-project.sh && grep -c "pre-build-gate.sh" scripts/install-to-project.sh && grep -c "before-build-critique-gate.mdc" scripts/install-to-project.sh`
Expected: `syntax OK`, `1`, `1`, `1`, `1`, `1`, `1`, `1`, `1`, `1`, `1`, `3`, `2`

- [ ] **Step 3: Commit**

```bash
git add scripts/install-to-project.sh
git commit -m "Fix install-to-project.sh to wire all four sub-projects plus start-build gate"
```

---

### Task 8: Update `bin/cursor-spells` usage hint

**Files:**
- Modify: `bin/cursor-spells:51` (usage hint line only)

**Interfaces:**
- Consumes: command names from Task 2 and Task 6.

- [ ] **Step 1: Replace the usage hint line**

In `bin/cursor-spells`, change:

```markdown
Slash commands after install: /finish-plan  /engineer-review
```

to:

```markdown
Slash commands after install: /start-task  /finish-plan  /start-build  /engineer-review
```

- [ ] **Step 2: Verify the edit landed**

Run: `grep -c "start-task\|start-build" bin/cursor-spells`
Expected: `1` (both new commands appear on the same single line)

- [ ] **Step 3: Commit**

```bash
git add bin/cursor-spells
git commit -m "Add start-task and start-build to cursor-spells usage hint"
```

---

### Task 9: Document the orchestrated pipeline and pre-build gate in README

**Files:**
- Modify: `README.md` (Skills table row + replace "Start a task" section + add "Pre-build critique gate" section)

**Interfaces:**
- Consumes: skill path `skills/start-build/`, commands `/start-task` and `/start-build` from Tasks 1, 2, 6.

- [ ] **Step 1: Add a row to the Skills table**

In `README.md`, change:

```markdown
| [`code-comments`](skills/code-comments/) | Keep/remove taxonomy for comments — shared by developers and `review-deadcode` |
```

to:

```markdown
| [`code-comments`](skills/code-comments/) | Keep/remove taxonomy for comments — shared by developers and `review-deadcode` |
| [`start-build`](skills/start-build/) | Pre-build gate — auto-runs `implementation-critic` before Task 1, HITL only if findings block |
```

- [ ] **Step 2: Replace the "Start a task / write a tech spec" usage section**

In `README.md`, change:

```markdown
### Start a task / write a tech spec

- `/start-task [ac-source]` — bootstraps context (project patterns, stack) and hands off to `/write-tech-spec`.
- `/write-tech-spec [ac-source]` — drafts (or structures a human-written) developer technical action plan from agreed Acceptance Criteria: services/tables/contracts/rollout, not a PRD. Asks one question at a time for anything uncertain (Blocker/Decision), never invents a business fact.
- Does not hand off to `writing-plans` until the spec's `Status` is `approved` or explicitly `skip`ped.
```

to:

```markdown
### Start a task (full pipeline)

`/start-task [ac-source]` orchestrates the whole pipeline end-to-end, stopping only at the human-in-the-loop (HITL) gates that already exist — it never skips or softens any of them:

1. Bootstraps context (project patterns, stack) — automatic
2. Runs `tech-spec` — **HITL** at the entry question, any Blocker/Decision question, and `approve-spec`/`revise`/`skip`
3. Generates the implementation plan via `writing-plans` — automatic once the spec is approved
4. Runs the pre-build critique gate (`/start-build`, below) — automatic start, **HITL** only if findings block
5. Executes the plan via `subagent-driven-development` — automatic, no "which approach?" prompt in this flow
6. `/finish-plan` — **HITL** `skip`/`approve`/`done`
7. `engineer-review` — **HITL** only for clarifications it raises

A Jira/tracker URL works as the AC source, recorded as a reference — this kit does not fetch ticket contents via an API.

Prefer `/write-tech-spec [ac-source]` directly if you only want the tech spec, without triggering the rest of the pipeline.

### Pre-build critique gate

`/start-build [path]` (or the `start-build` skill, auto-invoked by `/start-task`) always runs `implementation-critic` before Task 1 of a plan is dispatched — no permission needed to start the critique itself, since it's read-only. If `Verdict` comes back `blocked` or `clear pending accept`, it stops and waits for a plan revision or `accept F<id>` replies before execution begins.
```

- [ ] **Step 3: Verify all additions landed**

Run: `grep -c "start-build" README.md && grep -c "^### Start a task (full pipeline)$" README.md && grep -c "^### Pre-build critique gate$" README.md`
Expected: `5`, `1`, `1`

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "Document orchestrated pipeline and pre-build critique gate in README"
```

---

## Self-Review

**1. Spec coverage:** Every point confirmed with the user is covered: `start-build` auto-runs the critique without asking permission to start (only gates on `Verdict`), mirrors `finish-plan`'s skill+rule+hook shape exactly (Tasks 1, 3, 4, 5), `/start-task` chains all seven pipeline stages with HITL preserved at exactly the pre-existing gates and nowhere else (Task 6), and the previously-undiscovered gap — `install-to-project.sh` never wiring `tech-spec`/`implementation-critic`/`code-comments` into a consumer install — is fixed (Task 7), since none of the orchestration in Task 6 would actually be installable without it.

**2. Placeholder scan:** No `TBD`/`TODO`/"implement later" text anywhere in the plan's file contents. Every step contains the literal file content to write, not a description of it.

**3. Type/name consistency:** `start-build` and `.cursor/build-gate.pending` are spelled identically across Tasks 1–7. The already-shipped `tech-spec`, `implementation-critic`, `code-comments`, `finish-plan`, and `engineer-reviewer` names are referenced only by their real, existing paths (verified against the already-committed files, none of which this plan modifies) — no paraphrased variants. All `grep` verification counts in this plan were computed against real scratch-file drafts before being written down.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-24-start-build-pipeline-orchestration.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
