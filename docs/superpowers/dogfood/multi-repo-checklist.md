# Multi-repo review dogfood checklist

Manual checklist for `/multi-review` and `/finish-plan` multi-repo routing. Do not require CI to execute agents.

| Step | Expect |
|------|--------|
| Single repo only | `engineer-reviewer`, no supervisor |
| Two sibling repos with changes | supervisor + parallel reviews |
| Graphify present | no `multi-repo.json` created |
| Graphify absent | parent `multi-repo.json` created |
| Cross-repo endpoint drift | `C_CR*` clarify only, not Fixed |

## Notes

- `multi-repo.json` belongs in the workspace parent `.cursor/` directory only.
- Jira/Linear ticket discovery is deferred to v1.1; do not use ticket lookup for v1 dogfood.
