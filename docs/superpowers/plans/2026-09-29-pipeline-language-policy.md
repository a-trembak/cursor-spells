# Pipeline language preference + Russian prohibition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let humans choose the pipeline chat language at start, keep kit docs English-only, and hard-ban Russian as a sanctions-based kit policy.

**Architecture:** Persist preference in `.cursor/csp-pipeline-language` (sibling to `.cursor/csp-skill-profile`). Ask via `hitl-choice` at the earliest bootstrap of `/csp-start-task` and `/csp-start-issue-task`. Always-on rule + policy doc forbid Russian; helper script validates codes; `plain-language-chat` becomes language-agnostic clarity with optional per-language expansion tables.

**Tech Stack:** Markdown skills/rules/commands, bash helper + contract tests, installer rule sync.

**Base branch:** `cursor/pipeline-docs-skill-load-a044` (English pipeline docs already landed). Working branch: `cursor/pipeline-language-policy-a044`. Pull request base: `main` (stacks on docs English work until that merges).

## Global Constraints

- Kit surfaces (README, pipeline-flow, canvas docs): English only.
- Default language when unset: `en`.
- Russian (`ru` / Russian / русский): never allowed in selection or agent communication — sanctions policy of this project/kit (no invented statute numbers).
- Do not ban all Cyrillic (Ukrainian remains allowed when selected).
- No `/csp-start-*` dogfood on this repo; edit kit files directly.

---

## File map

| Path | Responsibility |
|------|----------------|
| `.cursor/csp-pipeline-language` (consumer marker) | One-line ISO-ish code; default `en` |
| `scripts/csp-pipeline-language.sh` | get / set / validate / reject `ru` |
| `rules/pipeline-language-no-russian.mdc` | Always-on sanctions ban |
| `docs/superpowers/pipeline-language.md` | Policy + catalog + persistence |
| `skills/hitl-choice/references/presets.md` | Preset **Pipeline language** |
| `commands/csp-start-task.md`, `commands/csp-start-issue-task.md` | Ask + persist at bootstrap |
| `skills/plain-language-chat/SKILL.md` (+ optional `references/`) | Selectable language clarity |
| `rules/plain-language-chat.mdc`, `AGENTS.md` | Point at preference + ban |
| `scripts/validate-review-report.sh` | Safe Russian-marker reject (not all Cyrillic) |
| `scripts/install-to-project.sh` | Install new rule + helper |
| `README.md`, `docs/superpowers/pipeline-flow.md` | Brief English docs |
| `scripts/tests/pipeline-language-test.sh` | Contract tests |

---

### Task 1: Helper + ban rule + policy doc

**Files:**
- Create: `scripts/csp-pipeline-language.sh`
- Create: `rules/pipeline-language-no-russian.mdc`
- Create: `docs/superpowers/pipeline-language.md`
- Create: `scripts/tests/pipeline-language-test.sh` (failing then green)

- [ ] Write failing contract tests (default `en`, reject `ru`, accept `uk`/`de`/`other:sw`, parse file)
- [ ] Implement helper (get/set/validate)
- [ ] Add always-on rule + policy doc
- [ ] Run tests; commit

### Task 2: HITL preset + pipeline entry wiring

**Files:**
- Modify: `skills/hitl-choice/references/presets.md`, `skills/hitl-choice/SKILL.md`
- Modify: `commands/csp-start-task.md`, `commands/csp-start-issue-task.md`
- Modify: installer + README + pipeline-flow

- [ ] Add **Pipeline language** preset (closed-set codes + `other`; never `ru`)
- [ ] Bootstrap: ask when unset (or offer keep/change when set); persist via helper
- [ ] Document in README / pipeline-flow / install rule list
- [ ] Commit

### Task 3: Redesign plain-language-chat + validators

**Files:**
- Modify: `skills/plain-language-chat/SKILL.md`, `rules/plain-language-chat.mdc`, `AGENTS.md`
- Optional: `skills/plain-language-chat/references/uk.md`
- Modify: `scripts/validate-review-report.sh`, `skills/engineer-review/references/forbidden-formats.md`
- Modify: `scripts/tests/plain-language-chat-test.sh`

- [ ] Language-agnostic clarity; read preference; Ukrainian table when `uk`
- [ ] Human writes Russian → refuse; continue in English or selected non-Russian language
- [ ] Validator: reject Russian-only letters / Russian digest headings; keep Ukrainian `Блокери` as banned-digest example only
- [ ] Tests green; commit; push; open draft pull request
