# Final fix report

## 2026-07-22 - multi-repo discovery override and finish-plan probe

- Made explicit `/multi-review <path...>` / `explicit_paths` the first-precedence repo set. Graphify and parent `.cursor/multi-repo.json` no longer replace or expand explicit paths; graphify may only inform cross-repo impact among the chosen repos.
- Split discovery into non-mutating probe versus mutating persist. `finish-plan` routing now probes only, while parent `.cursor/multi-repo.json` persists only for confirmed multi-repo runs without graphify, or explicit `/multi-review --refresh`.
- Clarified routing outcomes: 0 changed repos stops with a message, 1 changed repo uses `engineer-reviewer`, and 2+ changed repos uses `multi-repo-supervisor`.
- Aligned active README, command, supervisor, protocol, finish-plan, design spec, plan, and dogfood docs with the same v1 constraints: cross-repo remains clarify-only and Jira/Linear ticket discovery remains deferred to v1.1.
