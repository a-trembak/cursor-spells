# Code via coding agents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the harness parent chat always dispatch `software-developer` or `bug-fixer` for product code changes, via an always-on Cursor rule installed like `plain-language-chat`.

**Architecture:** Mirror the `plain-language-chat` pattern: kit-owned `rules/code-via-coding-agents.mdc` with `alwaysApply: true`, a short pointer in `AGENTS.md`, installer copies into user-global and project `.cursor/rules/`, and a bash contract test that asserts files, key phrases, and install drops. No pipeline skill rewrites.

**Tech Stack:** Markdown Cursor rules (`.mdc`), bash installer + contract tests, kit `AGENTS.md` / `README.md`.

**Spec:** `docs/superpowers/specs/2026-09-04-code-via-coding-agents-design.md`

## Global Constraints

- Route features / plan tasks / review-gate `fixes` / `--fast` through nested Task `software-developer` (wait for return).
- Route ticket bugs / `/start-issue-task` through nested Task `bug-fixer` (wait for return).
- Parent must not invent product diffs; on ambiguity ask once.
- Kit self-edits and engineer-review phase auto-fix stay allowed as in the spec.
- Do not rename agents or rewrite `/start-task` / `/start-issue-task` pipelines.
- User-facing chat still follows `plain-language-chat` (full words).

## File map

| Path | Responsibility |
|------|----------------|
| `scripts/tests/code-via-coding-agents-test.sh` | Contract: rule/AGENTS/installer/README + fake install drops |
| `rules/code-via-coding-agents.mdc` | Always-on parent dispatch rule |
| `AGENTS.md` | Short section for agents reading the kit root |
| `scripts/install-to-project.sh` | Copy the new rule next to `plain-language-chat` |
| `README.md` | Document user-global + project rule rows |

---

### Task 1: Contract test (RED)

**Files:**
- Create: `scripts/tests/code-via-coding-agents-test.sh`
- Test: `scripts/tests/code-via-coding-agents-test.sh`

**Interfaces:**
- Consumes: existing `scripts/install-to-project.sh` flags `--user-only` and `--skip-third-party-skills`; pattern from `scripts/tests/plain-language-chat-test.sh`
- Produces: executable contract script that exits non-zero until Task 2 lands

- [ ] **Step 1: Write the failing contract test**

Create `scripts/tests/code-via-coding-agents-test.sh`:

```bash
#!/usr/bin/env bash
# Contract: parent chat must dispatch software-developer / bug-fixer for product code.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_file() {
  local path="$1"
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "FAIL missing file: $path" >&2
    fail=1
  else
    echo "OK   file $path"
  fi
}

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_file "rules/code-via-coding-agents.mdc"
assert_file "AGENTS.md"

assert_grep rule_always_apply "rules/code-via-coding-agents.mdc" "alwaysApply: true"
assert_grep rule_software_developer "rules/code-via-coding-agents.mdc" "software-developer"
assert_grep rule_bug_fixer "rules/code-via-coding-agents.mdc" "bug-fixer"
assert_grep rule_no_parent_product "rules/code-via-coding-agents.mdc" "protocol bug|never write|must not"
assert_grep agents_section "AGENTS.md" "software-developer"
assert_grep agents_bug_fixer "AGENTS.md" "bug-fixer"
assert_grep installer_project_rules "scripts/install-to-project.sh" "code-via-coding-agents[.]mdc"
assert_grep installer_user_rules "scripts/install-to-project.sh" "[.]cursor/rules/code-via-coding-agents"
assert_grep readme_user_rule "README.md" "code-via-coding-agents[.]mdc"

# Installer must drop the always-on rule into user-global and project rules.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAKE_HOME="$TMP/home"
PROJECT="$TMP/app"
mkdir -p "$FAKE_HOME" "$PROJECT"
git -C "$PROJECT" init -q

HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" --user-only --skip-third-party-skills >/dev/null
if [[ -f "$FAKE_HOME/.cursor/rules/code-via-coding-agents.mdc" ]]; then
  echo "OK   user-global rule installed"
else
  echo "FAIL user-global rule missing at $FAKE_HOME/.cursor/rules/code-via-coding-agents.mdc" >&2
  fail=1
fi

HOME="$FAKE_HOME" "$ROOT/scripts/install-to-project.sh" "$PROJECT" --skip-third-party-skills >/dev/null
if [[ -f "$PROJECT/.cursor/rules/code-via-coding-agents.mdc" ]]; then
  echo "OK   project rule installed"
else
  echo "FAIL project rule missing at $PROJECT/.cursor/rules/code-via-coding-agents.mdc" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
```

- [ ] **Step 2: Make the test executable and run it (expect FAIL)**

```bash
chmod +x scripts/tests/code-via-coding-agents-test.sh
./scripts/tests/code-via-coding-agents-test.sh
```

Expected: FAIL with `missing file: rules/code-via-coding-agents.mdc` (and further failures if it continues — `set -e` is off for assert helpers; script should exit 1 with `SOME TESTS FAILED`).

- [ ] **Step 3: Commit the RED test**

```bash
git add scripts/tests/code-via-coding-agents-test.sh
git commit -m "test: contract for code-via-coding-agents dispatch rule"
```

---

### Task 2: Rule, AGENTS, installer, README (GREEN)

**Files:**
- Create: `rules/code-via-coding-agents.mdc`
- Modify: `AGENTS.md`
- Modify: `scripts/install-to-project.sh` (user copy block ~268 and project rules loop ~304)
- Modify: `README.md` (user-global rules table ~66; project rules table ~85)
- Test: `scripts/tests/code-via-coding-agents-test.sh`

**Interfaces:**
- Consumes: Task 1 contract expectations (file names and grep patterns above)
- Produces: installable always-on rule; `csp install` / `csp update` refresh both homes

- [ ] **Step 1: Add `rules/code-via-coding-agents.mdc`**

```markdown
---
description: Parent harness chat must dispatch software-developer or bug-fixer for product code — never patch product trees inline
alwaysApply: true
---

# Code via coding agents

In this harness, the **parent / orchestrator chat** must not write or patch **product** code itself.

1. Features, accepted plan tasks, review-gate `fixes`, and `/start-task --fast` → load and dispatch nested Task **`software-developer`**, then **wait** for it to return.
2. Ticket bugs and `/start-issue-task` → load and dispatch nested Task **`bug-fixer`** (skill `bug-fix`), then **wait** for it to return.
3. If write vs fix is ambiguous → ask once; do not invent product diffs in the parent.
4. Violating “I will just patch it here for speed” in the parent is a **protocol bug**.

Allowed in the parent: orchestration, reading, review reports, kit docs/skills/rules edits when changing this kit, pipeline gate markers, and meta tooling.

Engineer-review **phase** auto-fix under the kit protocol is unchanged and is not parent ad-hoc product patching.

Pipeline commands that already dispatch these agents stay as they are; this rule closes ad-hoc chat coding.
```

- [ ] **Step 2: Extend `AGENTS.md`**

Keep the existing chat section. Append:

```markdown
## Product code in this harness

Never write or patch product code in the parent chat. Dispatch nested Task `software-developer` for features, plan tasks, review-gate fixes, and `/start-task --fast`. Dispatch nested Task `bug-fixer` for ticket bugs and `/start-issue-task`. Wait for the Task to return. If the path is unclear, ask once. Always-on rule: `code-via-coding-agents`.
```

- [ ] **Step 3: Wire the installer**

In `install_user_bits`, after copying `plain-language-chat.mdc`, also copy the new rule:

```bash
  cp "$KIT_ROOT/rules/plain-language-chat.mdc" "$HOME/.cursor/rules/plain-language-chat.mdc"
  echo "copied: $HOME/.cursor/rules/plain-language-chat.mdc"
  cp "$KIT_ROOT/rules/code-via-coding-agents.mdc" "$HOME/.cursor/rules/code-via-coding-agents.mdc"
  echo "copied: $HOME/.cursor/rules/code-via-coding-agents.mdc"
```

In `install_project_bits`, add the filename to the rules loop:

```bash
  for rule in after-plan-review-gate.mdc before-build-critique-gate.mdc clean-decision-docs.mdc hitl-askquestion.mdc plain-language-chat.mdc code-via-coding-agents.mdc; do
```

- [ ] **Step 4: Document in `README.md`**

Add a user-global row after the `plain-language-chat` user rule row:

```markdown
| `~/.cursor/rules/code-via-coding-agents.mdc` | Copied / refreshed — parent chat must dispatch `software-developer` / `bug-fixer` for product code |
```

Add a project row after the project `plain-language-chat` rule row:

```markdown
| `<project>/.cursor/rules/code-via-coding-agents.mdc` | Copied / refreshed — parent chat must dispatch coding agents for product code |
```

- [ ] **Step 5: Run the contract test (expect PASS)**

```bash
./scripts/tests/code-via-coding-agents-test.sh
```

Expected: `ALL PASS` (every `OK` line, including user-global and project install drops).

- [ ] **Step 6: Commit**

```bash
git add rules/code-via-coding-agents.mdc AGENTS.md scripts/install-to-project.sh README.md
git commit -m "feat: always-on rule to dispatch coding agents from parent chat"
```

---

## Plan self-review

| Spec requirement | Task |
|------------------|------|
| `rules/code-via-coding-agents.mdc` always-on | Task 2 Step 1 |
| `AGENTS.md` short section | Task 2 Step 2 |
| Installer user + project copy | Task 2 Step 3 |
| Contract test | Task 1 + Task 2 Step 5 |
| README rows | Task 2 Step 4 |
| Routing option 3 (developer vs bug-fixer) | Rule + AGENTS text |
| No pipeline rewrites | Explicitly omitted |

Placeholder scan: none. Names match across tasks (`code-via-coding-agents.mdc`, `software-developer`, `bug-fixer`).
