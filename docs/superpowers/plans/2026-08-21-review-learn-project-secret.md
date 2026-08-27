# Review-learn project-secret routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route shareable misses to `teach-review` and write `.cursor/review-learnings.md` only when the human chooses `project_secret`.

**Architecture:** Closed-set tokens on the existing Teach-review miss gate plus a Capture-escape destination gate. `review-learn` `mode:capture` becomes opt-in. Contract grep tests lock the tokens and the “no auto-capture” rule.

**Tech Stack:** Markdown skills/agents/commands, bash contract tests.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-21-review-learn-project-secret-design.md`.
- Tokens: `miss`, `project_secret`, `no_miss` (last only on Teach-review miss).
- Do not delete existing consumer ledgers. Do not write both stores on one miss.
- `teach-review` land / worktree rules unchanged.
- Chat with the human: skill `plain-language-chat` (full words).

---

## File map

| File | Role |
|------|------|
| `scripts/tests/teach-review-contract-test.sh` | Tokens, no auto-capture, promote not on secret path |
| `scripts/tests/jira-ac-router-finale-test.sh` | Capture-escape destination + still mentions `mode: capture` |
| `skills/hitl-choice/SKILL.md` | Three-way Teach-review miss + Capture-escape destination |
| `skills/engineer-review/references/review-learn-protocol.md` | Capture only on `project_secret` |
| `agents/review-learn.md` | Same capture eligibility |
| `agents/engineer-reviewer.md`, `skills/engineer-review/SKILL.md` | Gate then branch; no auto-capture |
| `agents/pr-reviewer.md`, `skills/pr-review/SKILL.md` | Same |
| `commands/capture-escape.md` | Destination gate |
| `commands/teach-review.md`, `skills/teach-review/SKILL.md` | Kit-only; mention the other store |
| `skills/engineer-review/references/review-learnings-template.md` | Project-private purpose |
| README, pipeline-flow.md/html, dogfood, teach-review spec pointer | Docs |

---

### Task 1: Contract tests (TDD)

**Files:**
- Modify: `scripts/tests/teach-review-contract-test.sh`
- Modify: `scripts/tests/jira-ac-router-finale-test.sh`

- [ ] **Step 1: Add failing greps** to `teach-review-contract-test.sh` after the existing `token_no_miss` line:

```bash
assert_grep token_project_secret "skills/hitl-choice/SKILL.md" '`project_secret`'
assert_grep dest_heading "skills/hitl-choice/SKILL.md" "### Capture-escape destination"
assert_grep protocol_secret_only "skills/engineer-review/references/review-learn-protocol.md" "project_secret"
assert_grep protocol_no_auto "skills/engineer-review/references/review-learn-protocol.md" "Do not capture from a settled report without"
assert_grep er_secret "agents/engineer-reviewer.md" "project_secret"
assert_grep er_no_auto "agents/engineer-reviewer.md" "Do not auto-capture"
assert_grep er_skill_secret "skills/engineer-review/SKILL.md" "project_secret"
assert_grep pr_secret "agents/pr-reviewer.md" "project_secret"
assert_grep pr_skill_secret "skills/pr-review/SKILL.md" "project_secret"
assert_grep capture_dest "commands/capture-escape.md" "Capture-escape destination"
assert_grep capture_teach "commands/capture-escape.md" "teach-review"
assert_grep capture_secret "commands/capture-escape.md" "project_secret"
assert_grep template_private "skills/engineer-review/references/review-learnings-template.md" "must not enter the shared kit"
```

- [ ] **Step 2: Add failing greps** to `jira-ac-router-finale-test.sh` after `capture_source`:

```bash
assert_grep capture_dest "commands/capture-escape.md" "Capture-escape destination"
assert_grep capture_secret "commands/capture-escape.md" "project_secret"
assert_grep capture_teach "commands/capture-escape.md" "teach-review"
```

Keep existing `mode: capture` and `source: production-escape` asserts.

- [ ] **Step 3: Run tests — expect FAIL**

```bash
bash scripts/tests/teach-review-contract-test.sh
bash scripts/tests/jira-ac-router-finale-test.sh
```

- [ ] **Step 4: Commit tests**

```bash
git add scripts/tests/teach-review-contract-test.sh scripts/tests/jira-ac-router-finale-test.sh
git commit -m "test(review): require project_secret capture routing"
```

---

### Task 2: HITL + protocol + capture-escape + orchestrators + docs

Implement the spec verbatim in the file map. Then:

```bash
bash scripts/tests/teach-review-contract-test.sh
bash scripts/tests/jira-ac-router-finale-test.sh
```

Expected: ALL PASS.

Commit:

```bash
git commit -m "feat(review): keep local learnings only for project_secret"
```
