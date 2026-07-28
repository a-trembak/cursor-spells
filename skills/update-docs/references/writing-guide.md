# Product documentation writing guide

Produce documentation a **product user** can follow and an **engineer** can trust. One file, two clear voices — never a dump of the PR or the tech spec.

## Style resolution (mandatory before draft)

Resolve **house style** before writing body text. Precedence (highest first):

1. **Human-provided custom style** for this run — pasted guide, link, or “write user docs like X / engineer docs like Y”.
2. **Destination house style** — existing pages, style guide, CONTRIBUTING, `docs/style*`, Confluence space templates / sibling pages in the same parent.
3. **Project custom style files** in the consumer app (e.g. `.cursor/docs-style.md`, `docs/writing-guide.md`) when they explicitly cover user and/or engineer audiences.
4. **Kit default** below — only when nothing above applies.

For **`docs_repo` and `confluence`**, steps 1–2 are required: sample at least 1–2 nearby pages (same folder / same Confluence parent) and name the matched patterns in a one-line chat note before drafting (headings shape, tone, audience split, callout macros, language). Do **not** force the kit dual-audience skeleton onto a house template that already separates user vs engineer docs differently (e.g. separate “User guide” vs “Runbook” trees, or Confluence labels).

When custom style exists **only for one audience** (user *or* engineer), follow that style for that audience and fall back to destination siblings / kit default for the other.

Match: heading levels, section order, callouts/admonitions, screenshot conventions, terminology, formality, and language. Do not invent a new house voice.

## Audience split (default shape)

Use this skeleton **only when style resolution landed on kit default** (no stronger house/custom template):

```markdown
# <Capability in user language>

## For users
What changed / what you can do now. Short how-to. Screens / steps if UI.
No service names, table names, or ticket ids unless the user sees them in the product.

## For engineers
Where it lives (services, APIs, events, flags). Contracts and edge cases.
How to verify. Rollback / compatibility notes when relevant.
Links to the tech spec / plan / PR — not a paste of them.
```

If the change is engineer-only (internal ops, no user-visible behavior), keep **For engineers** and replace **For users** with one line: "No user-facing change." Do not invent user copy.

If the change is purely user-facing with no new contracts, keep **For users** and a short **For engineers** pointer (paths, flag names) so support and on-call still find the source of truth.

If the house style keeps user and engineer material on **separate pages**, write/update the matching page(s) instead of merging both audiences into one file.

## Voice

| Do | Don't |
|----|-------|
| Lead with the outcome | Open with "This document aims to…" / "In today's landscape…" |
| Concrete steps a person can do | Abstract capability lists with no action |
| Short sentences; one idea each | Nested clauses and throat-clearing |
| Name the product surface the user sees | Leak internal module names into the user section |
| Link to specs/PRs for depth | Paste the whole tech spec into product docs |
| State limits and edge cases honestly | Marketing adjectives (seamless, robust, unlock, leverage) |

Reuse skill **`english-humanizer`** patterns for the engineer section: direct, neutral, concrete. User section may be slightly warmer but still plain — no hype.

## Content rules

1. **Ground in what shipped.** Derive claims from the diff, plan, tech spec, and review outcome — never invent capabilities.
2. **One capability per page** when possible. Large launches may be a short hub page + linked pages.
3. **Current truth only.** No "previously / now / after the refactor" archaeology (same spirit as `clean-decision-docs`).
4. **Verification is part of the doc.** Engineer section must say how to confirm the change (command, UI path, or log signal).
5. **Images optional.** Prefer a clear step list over a collage of screenshots. If you attach screenshots, caption them with the step they illustrate.
6. **Language.** Match the destination's existing language when updating an existing page. New pages in this kit's pipeline default to **English** unless the human asked otherwise in the HITL follow-up.

## Destination-specific notes

### `docs/` markdown (current repo)

- Prefer `docs/<area>/<slug>.md` or the project's existing docs layout if one is obvious.
- Update an index / README TOC only when the project already maintains one.
- Do not place product docs under `docs/superpowers/` (that tree is kit/process, not product).

### Separate documentation repository

- After HITL `docs_repo`, wait for the human to name the repo path or clone URL (and optional branch / folder).
- Check out or open that repo, follow **its** contribution conventions (folder layout, PR required, etc.).
- **Style:** run Style resolution — read sibling docs + any style guide in that repo; ask once if the human has a custom user and/or engineer style to prefer over what you found.
- Open or update a PR there when the human expects it; otherwise leave a committed branch and report the path.

### Confluence

- After HITL `confluence`, wait for space key + parent page (or full page URL) if not already known.
- Prefer Atlassian MCP / Confluence tools when authenticated; otherwise draft the Markdown body in chat (and optionally a local `docs/` staging file) for the human to paste.
- **Style:** run Style resolution — sample the parent and 1–2 sibling pages (macros, panels, heading rhythm, audience); ask once for a custom user and/or engineer style if they want to override the space.
- Never invent space permissions or overwrite unrelated pages. Update the named page or create a child under the named parent.

## Quality bar (self-check before handoff)

- [ ] Style resolution ran; house/custom style beats kit default when present (especially for `docs_repo` / `confluence`).
- [ ] A new teammate who never saw the PR can follow the user-facing part without asking chat.
- [ ] An on-call engineer can find the seam and verify from the engineer-facing part alone.
- [ ] No AI filler, no pasted tech-spec sections, no duplicate changelog archaeology.
- [ ] Destination matches the HITL choice; links resolve or are clearly placeholders the human must fill.
