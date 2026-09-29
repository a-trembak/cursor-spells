# Product name options (working title pending)

The GitHub repository is still named `cursor-spells` until a human renames it.
**Do not use “Cursor”, “Claude”, “Codex”, “OpenAI”, or “Anthropic” in the product title** (third-party marks).

Author attribution stays: **Andrey Trembak** (`a-trembak`).  
CLI `csp` may remain as a **legacy short command** with a new expansion once a name is chosen.

## Proposed names

| # | Name | Why it fits | Possible `csp` expansion (optional) |
|---|------|-------------|-------------------------------------|
| 1 | **Spellpath** | A path of spells (skills) through quality gates | Charm Spell Pipeline / Craft Spell Path |
| 2 | **Runeflow** | Runes as skills flowing through a pipeline | Craft Spell Pipeline |
| 3 | **Hexrail** | A rail of hexes/stages; strong, short brand | Hexrail Spell Pipeline |
| 4 | **Sigilworks** | Workshop of sigils (skills) and gates | Craft Sigil Pipeline |
| 5 | **Loregate** | Gates that enforce project lore/standards | Craft Spell Pipeline |
| 6 | **Charmline** | Charms lined into an ordered delivery line | Charm Spell Pipeline |
| 7 | **Arcanaforge** | Forging arcane tooling into reliable runs | Craft Spell Pipeline |
| 8 | **Weavewell** | A well of woven spells/skills | Craft Spell Pipeline |

## Placeholder in docs until chosen

Until the human picks one, installers and legal index may say **“the kit (working title)”** while the git remote may still be `cursor-spells`.

## Human rename step (GitHub)

Agents cannot rename this repository (API returns 403). After choosing a name `<new-name>`:

```bash
gh repo rename <new-name> --repo a-trembak/cursor-spells
```

Then update README title, `docs/legal/*` product strings, NOTICE display block, and any package/path marketing copy to match. Do **not** claim the remote rename succeeded until a human runs that command.
