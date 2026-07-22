# Engineer-review dogfood fixture

Manual checklist to verify the kit behaves. Do not require CI to execute agents.

## Setup

1. From kit root:

```bash
chmod +x scripts/*.sh
./scripts/install-to-project.sh /tmp/er-dogfood --hooks --rule
# or create a tiny git repo and point the script at it
```

2. In the consumer repo, add a deliberate smell file, e.g. `src/smells.ts`:

```ts
import { readFileSync } from "fs"; // unused after edit — leave unused import

export function greet(name: string) {
  // previously returned Hello, now we return Hi (historical comment — should be removed)
  return `Hi, ${name}`;
}

export function unusedHelper() {
  return 1;
}
```

And a used import of `greet` from another file so only the unused import / historical comment / unused export are the targets.

## Expected review behavior

| Step | Expect |
|------|--------|
| `/done` after fake plan | Creates `.cursor/review-gate.pending`, asks HITL |
| User `skip` | Starts engineer-reviewer; deletes marker |
| Frontend stack | Asks for Figma URLs or `no figma` early |
| First run | Creates `.cursor/project-patterns.md` |
| deadcode phase | Flags unused import + historical comment as `P1` unambiguous; unused export may clarify if unsure of public API |
| Fixed now | Lists applied P0/P1 fixes |
| Needs clarification | Separate from Fixed now |
| `P2` nits | Residual only |
| Large synthetic diff (>40 files) | Coverage mentions chunking |

## Patterns CI helper

```bash
BASE_REF=HEAD~1 ./scripts/check-project-patterns.sh --strict
```

With src changes and no `.cursor/project-patterns.md` → exit 1 in strict mode.

## Hook reminder

With marker present, agent `stop` should receive followup reminding HITL (does not auto-start review).
