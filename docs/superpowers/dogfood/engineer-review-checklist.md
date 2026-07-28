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

3. Add a deliberate **mechanical lint smell** the project's own `eslint` config would catch on its own (e.g. an `import` statement placed after other statements in the module body, which trips `eslint import/first` — "Import in body of module; reorder to top."). This is a regression fixture: a real heuristic-phase miss that motivated adding `review-lint`.

```ts
export const feature = "enabled";

import { helper } from "./helper"; // eslint: import/first — placed after a statement
```

## Expected review behavior

| Step | Expect |
|------|--------|
| `/finish-plan` after fake plan | Creates `.cursor/review-gate.pending`, asks HITL |
| User `skip` | Starts engineer-reviewer; deletes marker |
| Frontend stack | Asks for Figma URLs or `no figma` early |
| First run | Creates `.cursor/project-patterns.md` |
| `lint` phase (runs first) | Runs the project's real `eslint`/`tsc`; flags `import/first` as `P1` unambiguous and auto-fixes it with `eslint --fix` — this must not depend on any heuristic phase noticing it |
| deadcode phase | Flags unused import + historical comment as `P1` unambiguous; unused export may clarify if unsure of public API |
| Lint verify pass | After the apply step, `review-lint` re-runs once; report shows no remaining lint findings |
| Fixed now | Lists applied P0/P1 fixes, including the `lint` phase's `import/first` fix |
| Needs clarification | Separate from Fixed now |
| `P2` nits | Residual only |
| Large synthetic diff (>40 files) | Coverage mentions chunking |
| Catastrophic diff (>200 files or >50k LOC) | Orchestrator aborts before phase spam; asks to narrow scope |
| No lint config in fixture repo | `lint` phase reports `skipped: true` / `no_lint_config` in Coverage instead of silently disappearing |

## Patterns CI helper

```bash
BASE_REF=HEAD~1 ./scripts/check-project-patterns.sh --strict
```

With src changes and no `.cursor/project-patterns.md` → exit 1 in strict mode.

## Hook reminder

With marker present, agent `stop` should receive followup reminding HITL (does not auto-start review).
