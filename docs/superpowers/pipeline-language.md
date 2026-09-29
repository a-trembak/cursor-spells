# Pipeline language preference

Controls **how the agent talks to the human** during a pipeline run (status updates, Decision options, Blocker wording, review chat). Kit documentation, canvas copy, and foreign-facing README text stay **English**.

## Persistence

| Item | Value |
|------|--------|
| Marker file | `.cursor/csp-pipeline-language` (project root, one line) |
| Sibling pattern | Same style as `.cursor/csp-skill-profile` |
| Default when unset or empty | `en` |
| Helper | `scripts/csp-pipeline-language.sh` (`get` / `set` / `validate`) |

Example:

```text
uk
```

## When it is chosen

At bootstrap of `/csp-start-task` (full and `--fast`) and `/csp-start-issue-task`, before tech-spec / fix-plan work:

1. Read the marker via the helper (default `en`).
2. Ask via skill `hitl-choice` preset **Pipeline language** (AskQuestion required).
3. On a chosen token, `set` the marker. On `other`, accept a typed ISO-ish code or `other:<tag>`, then validate.
4. For the rest of the run, user-facing chat uses that language (skill `plain-language-chat`).

If the human already confirmed a language earlier in the same chat turn (canonical token present), do not re-ask.

## Catalog (open set)

Practical allowed shapes:

- Two- or three-letter ISO-ish codes: `en`, `uk`, `de`, `fr`, `es`, `pt`, `pl`, `it`, `nl`, `sv`, `no`, `da`, `fi`, `cs`, `sk`, `hu`, `ro`, `bg`, `hr`, `sr`, `tr`, `el`, `he`, `ar`, `ja`, `ko`, `zh`, `vi`, `th`, `id`, `ms`, `hi`, …
- `other:<tag>` for languages not listed in the closed-set picker (tag: letters, digits, `_`, `-`).

The closed-set HITL preset lists common options plus `other`. The helper accepts any allowed shape above.

## Russian prohibition (sanctions policy)

**Sanctions policy of this project/kit:** the Russian language must never be used in agent communication or pipeline language settings.

- Rejected codes: `ru`, `ru-*`, aliases `russian` / `русский`, and `other:ru` / `other:russian`.
- Always-on rule: `rules/pipeline-language-no-russian.mdc` (installed into consumer projects).
- If the human writes in Russian: refuse to continue in Russian; reply in English or the selected non-Russian language; offer the Pipeline language picker.
- Do **not** treat all Cyrillic as Russian — Ukrainian (`uk`) and other allowed Cyrillic languages remain valid when selected.
- Validators may reject Russian-specific markers in agent digests (for example Russian-only letters `ы` / `э` / `ъ` in review prose outside code fences, or Russian digest headings). They must not ban Ukrainian `Блокери` detection as a forbidden compact-digest shape.

## Related

- Skill `plain-language-chat` — full words / full sentences in the **selected** language
- Skill `hitl-choice` preset **Pipeline language**
- Rule `pipeline-language-no-russian`
