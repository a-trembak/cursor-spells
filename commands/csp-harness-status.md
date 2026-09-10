---
description: Show kit harness health inventory and last bench summary. Orientation only — does not advance gates.
argument-hint: ""
---

# /csp-harness-status

Read-only harness orientation for the cursor-spells kit (inventory, wiring, context proxies, optional last bench).

## Steps

1. Kit root = current workspace when it contains `scripts/harness-health.py`; otherwise resolve via `.cursor/cursor-spells-kit-path` / `$KIT`.
2. Run:

```bash
python3 scripts/harness-health.py
```

3. Print the script output to the human. Adapt wording with skill `plain-language-chat` (script text is an English skeleton). Optional `--json` only if the human asked for machine output.
4. Do **not** write or clear any gate. Do **not** start a full bench unless the human explicitly asked — point them at `bash scripts/harness-bench.sh` instead.

## Notes

- Same contract as skill `harness-status`.
- Cursor’s live context ring is separate from kit file-size proxies; see the skill for how to read both.
