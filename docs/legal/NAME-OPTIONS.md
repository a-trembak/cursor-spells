# Product name — Loregate (RESERVED working title)

**Status:** **Loregate** is the **RESERVED working title**. It is not yet the GitHub repository name, package path, or legal display mark everywhere — those stay `cursor-spells` until a human renames the remote and updates policy strings.

The GitHub repository is still named `cursor-spells`. **Do not run `gh repo rename`.** Agents must not rename the repository (API returns 403 anyway). After a human renames to something like `loregate`, update README title, `docs/legal/*` product strings, NOTICE display block, and marketing copy to match.

**Do not use “Cursor”, “Claude”, “Codex”, “OpenAI”, or “Anthropic” in the product title** (third-party marks).

Author attribution stays: **Andrey Trembak** (`a-trembak`).  
CLI `csp` may remain as a **legacy short command** with a new expansion (see Abbreviations below).

### Typo variant (not reserved)

**Lordgate** appeared once in chat and is almost certainly a typo for **Loregate**. It is **not** the reserved name unless the human confirms it later. Prefer **Loregate** everywhere until then.

## Brand meaning

| Piece | Meaning for this kit |
|-------|----------------------|
| **Lore** | Kit knowledge: plans, skills, checklists, policy, and project standards the pipeline teaches and enforces |
| **Gate** | Quality, policy, and review gates that must pass before merge |

**Tagline (suggestion):** From lore to merge through gates.

Pipeline shape the name fits: task → plan → build → review → pull request.

## Other options (rejected / deferred)

Kept for history only. Not the working title.

| # | Name | Why it was considered | Status |
|---|------|----------------------|--------|
| 1 | Spellpath | A path of spells (skills) through quality gates | Deferred |
| 2 | Runeflow | Runes as skills flowing through a pipeline | Deferred |
| 3 | Hexrail | A rail of hexes/stages; strong, short brand | Deferred |
| 4 | Sigilworks | Workshop of sigils (skills) and gates | Deferred |
| 5 | **Loregate** | Gates that enforce project lore/standards | **RESERVED working title** |
| 6 | Charmline | Charms lined into an ordered delivery line | Deferred |
| 7 | Arcanaforge | Forging arcane tooling into reliable runs | Deferred |
| 8 | Weavewell | A well of woven spells/skills | Deferred |

## Abbreviations / backronyms (play space)

Playful short codes and expansions to try in chat, docs, and CLI help. None of these rename GitHub. None include third-party host product marks.

### Short codes

| Code | Notes |
|------|--------|
| `LG` | Short for Loregate |
| `LGT` | Loregate; also nods at “looks good to…” review culture without claiming that phrase as the brand |
| `LRG` | Compact letters from Loregate |
| `Lore` | Informal short for the knowledge side |
| `Gate` | Informal short for the quality-gate side |

### CLI `csp` re-expansions (legacy command stays)

Replace the old “cursor-spells” sense of `csp` with Loregate-flavored shipping meanings:

| Expansion | Fits pipeline as… |
|-----------|-------------------|
| Craft Shipping Path | task → plan → build → review → pull request |
| Clear Spec Path | clarify, then ship through gates |
| Checked Stage Pipeline | each stage is a gate |
| Canonical Ship Path | one kit path from lore to merge |
| Complete Spec Pipeline | plan and acceptance before merge |
| Controlled Ship Practice | policy and review before land |

### Backronyms — LORE

| Expansion | Fit |
|-----------|-----|
| Library Of Review-ready Essentials | plans, skills, checklists |
| Lessons Organized for Reliable Execution | teach-review / learn loop |
| Linked Outcomes, Rules, and Examples | policy + dogfood lore |
| Living Orchestration of Release Essentials | end-to-end shipping kit |

### Backronyms — GATE

| Expansion | Fit |
|-----------|-----|
| Guardrails And Thorough Evaluation | engineer review / policy gates |
| Guided Acceptance Through Evidence | proof before merge |
| Greenlight After Task Evaluation | stage checks before land |
| Guaranteed Alignment Toward Excellence | quality bar before pull request |

### Backronyms — LOREGATE

| Expansion | Fit |
|-----------|-----|
| Lore Organized; Review Evaluates; Greenlight And Thorough Evidence | full path lore → gates → merge |
| Library Of Release Essentials; Guided Acceptance Through Evidence | knowledge plus merge gates |
| Linked Outcomes Reviewed; Evaluated Gates Assure Trusted Exit | task → plan → build → review → pull request |

## Placeholder in docs until GitHub rename

Installers and legal index may still say **“the kit”** or **Loregate (working title)** while the git remote remains `cursor-spells`. Do not claim the remote rename succeeded until a human runs it.

## Human rename step (GitHub)

Agents cannot rename this repository. After the human confirms the final spelling (default reserved: **loregate**):

```bash
gh repo rename loregate --repo a-trembak/cursor-spells
```

Then update README title, `docs/legal/*` product strings, NOTICE display block, and any package/path marketing copy to match.
