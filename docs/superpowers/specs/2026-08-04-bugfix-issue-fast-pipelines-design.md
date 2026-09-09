# Bug-fix agent, issue/fast pipelines, create-pr, AskQuestion always-on

## Status

`approved` — implementation target for cursor-spells kit.

## Goal

Add a dedicated bug-fix path and a lean no-HITL path for small work, end every pipeline with a draft PR, and stop voluntary text-only HITL when Cursor exposes an interactive question tool.

## Decisions

| Decision | Choice |
|----------|--------|
| Shape | Separate agents/skills/commands (kit pattern) |
| Fast entry | `/csp-start-task --fast [ac-source]` |
| Issue entry | `/csp-start-issue-task [jira-key\|url]` |
| Jira | Atlassian MCP `getJiraIssue` primary; stop if unavailable |
| Issue HITL | Only critic `blocked` / `clear pending accept`, plus engineer-review clarify |
| Post-implement verify (fast + issue) | `csp-engineer-reviewer` without `finish-plan` HITL |
| Pipeline finale | Skill `create-pr` — draft PR via `gh` or `ce-commit-push-pr mode:pipeline` |
| Critic | Reuse `implementation-critic` + Pass C bug lenses |
| HITL UX | Always attempt AskQuestion (aliases) first; text only after fail/missing tool |

## Pipelines

### Full `/csp-start-task`

Unchanged HITL chain, then `create-pr` after `update-docs`:

bootstrap → tech-spec (HITL) → writing-plans → approve-plan + critic (HITL) → software-developer → finish-plan (HITL) → engineer-reviewer → update-docs (HITL) → **create-pr**

### `/csp-start-task --fast`

No tech-spec / plan / critic / finish-plan / update-docs:

bootstrap → short AC brief → feature branch + implement (`mode:fast`) → engineer-reviewer → **create-pr**

### `/csp-start-issue-task`

bootstrap → Jira MCP fetch → root-cause fix plan → auto critic (Pass A/B/C) → HITL only if not clear → bug-fixer → engineer-reviewer → **create-pr**

## Components

| Artifact | Role |
|----------|------|
| `agents/csp-bug-fixer.md` + `skills/bug-fix/` | Reproduce → root cause → minimal fix → regression test |
| `commands/csp-start-issue-task.md` | Issue orchestrator |
| `skills/create-pr/` | Commit/push/draft PR finale |
| `implementation-critic` Pass C | Root-cause vs symptom, regression, better alternative, tests catch bug |
| `skills/hitl-choice` + `rules/hitl-askquestion.mdc` | Mandatory interactive question tool for closed-set HITL |

## Bug-fixer skills

Always load when available (`skill_missing` otherwise): `systematic-debugging`, `ce-debug` (`mode:pipeline`), `verification-before-completion`, `code-comments`, skill-map stack/DB, `tdd` when installed. Branch setup reuses `software-developer/references/branch-setup.md` with `fix/<jira-key>-<topic>` preferred.

## AskQuestion contract

1. Every closed-set HITL gate goes through `hitl-choice`.
2. First action: call interactive question tool (`AskQuestion` → `AskUserQuestion` → `ask_question` → `ask_user` / `request_user_input`).
3. Forbidden: voluntary chat-only bullet list when the tool might exist.
4. On error/cancel: retry once; then typed-token text fallback and state that buttons failed.
5. Harnesses with no question tool: typed tokens after hard missing-tool / unknown-tool failure.

## Out of scope

Writing AC from scratch; auto-installing third-party skills; Jira comment/transition; patching Cursor when no question tool is exposed.
