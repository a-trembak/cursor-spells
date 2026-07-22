# Phase protocol

Every phase subagent follows this contract. Orchestrator merges JSON only — not raw transcripts.

## Inputs (provided by orchestrator)

- `BASE_SHA`, `HEAD_SHA` (or explicit file list)
- `stack`: `react-web` | `react-native` | `typescript` | `java-spring` | `mixed` | `unknown`
- `patterns_path`: usually `.cursor/project-patterns.md`
- `clarifications`: map of prior answers (`C1` → text), may be empty
- `mode`: `find` (read-only findings) or `apply` (apply unambiguous fixes)

## Process

1. `git diff --stat $BASE_SHA..$HEAD_SHA` then focused file reads.
2. Load mapped skill for this phase if available (see skill-map.md).
3. Review **changed code** against checklist; use patterns file for local conventions.
4. Classify each issue:
   - `fixed` — applied in `apply` mode, or listed as ready-to-apply with patch already written
   - `clarify` — needs human
5. Return **only** the JSON summary below (plus optional short notes array). Cap notes at 8 bullets.

## Apply rules

- In `find` mode: never mutate the tree; put proposed unambiguous items under `fixed` with `"applied": false` and a one-line recipe, or leave them for orchestrator apply pass.
- Preferred kit default: orchestrator runs phases in `find` parallel, then one `apply` pass for items marked `unambiguous: true`.
- Never apply clarify-class items.

## JSON summary schema

```json
{
  "phase": "logic|patterns|deadcode|architecture|performance|security|figma",
  "status": "ok|partial|failed",
  "skipped": false,
  "skip_reason": null,
  "fixed": [
    {
      "path": "src/foo.ts",
      "summary": "Removed unused import",
      "unambiguous": true,
      "applied": true
    }
  ],
  "clarify": [
    {
      "id": "C1",
      "question": "Should X use existing helper Y?",
      "options": ["Use Y", "Keep new helper", "Need more context"],
      "path": "src/foo.ts"
    }
  ],
  "notes": ["optional short residual"]
}
```

## Skip conditions

- `security`: no sensitive surface in diff → `skipped: true`
- `figma`: not frontend, or no Figma URLs yet → `skipped: true` with reason `awaiting_figma_urls` or `not_frontend`
- `patterns` first run: may create patterns file; that is not a skip

## Orchestrator merge

- Concatenate all `fixed` where `applied: true` into **Fixed now**
- Concatenate all `clarify` into **Needs clarification** (stable ids `C1…` globally — orchestrator renumbers if needed)
- Coverage lists phases run/skipped
