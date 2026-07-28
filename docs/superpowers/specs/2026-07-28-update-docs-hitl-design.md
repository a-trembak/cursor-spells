# Product docs HITL after review

## Problem

After engineer-review the pipeline ended at "reviewed PR" with no structured place to update **product / internal documentation**. Teams often keep that material in a separate docs repo, Confluence, or `docs/` Markdown in the app repo — inventing the destination is worse than asking.

## Decision

Add skill **`update-docs`** (+ `/update-docs`) as stage 8 of `/start-task`, immediately after review:

1. Marker `.cursor/docs-gate.pending`
2. HITL via `hitl-choice` preset **Docs update destination**: `skip` | `docs_md` | `docs_repo` | `confluence`
3. Free-text follow-up for repo path/URL or Confluence space/parent when needed
4. Dual-audience draft (**For users** + **For engineers**) per `skills/update-docs/references/writing-guide.md`
5. Prose polish with bundled `english-humanizer`
6. Publish to the chosen sink; clear the marker

## Skill composition (why not only third-party)

| Skill | Fit |
|-------|-----|
| **`update-docs`** (this kit) | Owns destination HITL + product-doc shape |
| **`english-humanizer`** | Engineer-voice prose |
| **`ce-compound`** (optional) | Durable *solved-problem* pages in `docs/solutions/` — offer as a separate follow-up, not the product-docs path |
| **`ce-explain`** (optional) | Personal teaching HTML/MD — explicitly not repo/product docs |
| **`ce-promote`** (optional) | Launch/announcement copy — different artifact |

There was no third-party skill that both (a) asks where product docs live and (b) writes dual-audience product documentation. Closest teaching/quality skills are composed around `update-docs`, not used as a silent substitute for the HITL gate.

## Non-goals

- Auto-detecting Confluence vs docs-repo from heuristics
- Writing into `docs/superpowers/` as product docs
- Replacing tech-spec / plan / clean-decision-docs artifacts
