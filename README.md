# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, and other agent spells.

Spells you cast so the model sounds like a human engineer, not a LinkedIn influencer who just discovered the word *delve*.

## Layout

```
skills/      Agent skills (SKILL.md)
commands/    Cursor slash commands
rules/       Persistent rules
hooks/       Cursor hooks
agents/      Custom agent configs
```

## Skills

| Skill | What it does |
|-------|----------------|
| [`english-humanizer`](skills/english-humanizer/) | Strip AI tells from English bug reports, colleague messages, and PR comments |

## Install (symlink into Cursor)

From this repo:

```bash
# Skills
ln -s "$(pwd)/skills/english-humanizer" ~/.cursor/skills/english-humanizer

# Later: commands / rules the same way
# ln -s "$(pwd)/commands/foo.md" ~/.cursor/commands/foo.md
```

Or copy instead of symlink if you prefer.

## Usage

In Cursor chat:

- `@english-humanizer` / ask to humanize a PR comment or problem description
- More spells land here as they earn their keep

## License

MIT — steal freely, please sound human.
