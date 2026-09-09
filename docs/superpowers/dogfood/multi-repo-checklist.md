# Multi-repo review dogfood checklist

Manual checklist for `/csp-multi-review` and `/csp-finish-plan` multi-repo routing. Do not require CI to execute agents.

| Step | Expect |
|------|--------|
| Single repo only | `csp-engineer-reviewer`, no supervisor |
| No changed repos | stop with a no-changed-repos message |
| Two sibling repos with changes | supervisor + parallel reviews |
| Graphify present | no `multi-repo.json` created |
| `/csp-multi-review path-a path-b` | explicit paths are the repo set; graphify/config do not replace them |
| `finish-plan` with Graphify absent or unqueryable | sibling scan is in memory only until 2+ changed repos are confirmed |
| Confirmed multi-repo run with Graphify absent or unqueryable | parent `multi-repo.json` created or refreshed |
| Cross-repo endpoint drift | `C_CR*` clarify only, not Fixed |

## Notes

- `multi-repo.json` belongs in the workspace parent `.cursor/` directory only.
- Explicit path runs do not persist `multi-repo.json`; paths are a run-local override.
- Jira/Linear ticket discovery is deferred to v1.1; do not use ticket lookup for v1 dogfood.
