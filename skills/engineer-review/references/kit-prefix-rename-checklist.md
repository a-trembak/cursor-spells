# Kit prefix rename checklist (commands / agents vs skills)

Use when the **patterns** phase reviews a kit diff that renames or introduces a **shared prefix** on slash commands and/or agents (example: `csp-`), or that edits pipeline Mermaid / canvas labels beside those renames.

## When to run

Run when the diff touches **any** of:

- `commands/` (rename, new slash command, or bulk prefix)
- `agents/` (rename, new agent file, or frontmatter `name:`)
- `docs/superpowers/pipeline-flow.md` or `docs/superpowers/pipeline-flow.html`
- Harness / health scripts that open `skills/<name>/SKILL.md` (`scripts/harness-health.py`, related tests, dogfood harness checklists)

Skip pure consumer-app diffs with no kit command/agent/flow/harness paths.

## P1 — Prefixed agent ids in Mermaid and canvas

**Rule:** When slash commands and agents gain a shared prefix, Mermaid nodes and pipeline-canvas agent labels must use the **prefixed agent ids** that match `agents/<id>.md` (and agent frontmatter `name:`).

**Flag:**

- Agent boxes / edges in `pipeline-flow.md` still using the pre-prefix id after agents were renamed
- Canvas labels, `data-go`, `data-stage`, or overview text in `pipeline-flow.html` still using the old unprefixed agent id
- Prose that names the nested Task / phase agent without the new prefix while `agents/` already uses it

**Do not flag:** Skill folder names or skill YAML `name:` fields (those stay unprefixed — see P2).

## P2 — Skills stay unprefixed

**Rule:** Skill directories and skill frontmatter `name:` fields stay **unprefixed**. Do not invent `skills/<prefix>-…/` or rewrite `name: finish-plan` to `name: <prefix>-finish-plan`.

**Flag:**

- Renaming `skills/finish-plan/` → `skills/<prefix>-finish-plan/` (or any skill folder gaining the command/agent prefix)
- Changing skill YAML `name:` to include the shared command/agent prefix
- Harness, health, or bench paths rewritten to `skills/<prefix>-…/SKILL.md`

## P3 — Never write Skill with a slash-command path

**Rule:** Always distinguish **skill** `finish-plan` from **slash command** `/<prefix>-finish-plan` (or `/finish-plan` when unprefixed). Never write ``Skill `/…`` ``.

**Flag:**

- Phrases like ``Skill `/finish-plan` `` or ``Skill `/csp-finish-plan` ``
- Calling a skill by its slash-command spelling in prose that means the skill body under `skills/<name>/`

**Fix shape:** `skill \`finish-plan\` (slash command \`/csp-finish-plan\`)` — or the current command spelling for this kit.

## P4 — Harness opens unprefixed skill paths

**Rule:** Inventory / health / bench code that opens `skills/<name>/SKILL.md` must keep using **unprefixed** skill directory names.

**Flag:**

- New or edited probes that look for `skills/csp-tech-spec/SKILL.md` (or any prefixed skill dir) when the real folder is `skills/tech-spec/`
- Dogfood or contract tests that assert prefixed skill directory paths after a command/agent-only rename

## Evidence

Every finding needs `path`, `start_line`, `end_line`, `snippet`, and `context` per `phase-protocol.md`. Prefer `clarify` when the shared prefix is still being rolled out and only part of the tree moved; prefer `fixed` only when the mismatch is unambiguous against already-renamed `agents/` or `commands/`.
