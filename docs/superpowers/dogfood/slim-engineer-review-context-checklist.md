# Slim engineer-review orchestrator context — dogfood

Manual checklist after changing orchestrator load routing. Do not require CI to execute agents.

## Setup

From kit root:

```bash
bash scripts/tests/engineer-review-context-budget-test.sh
bash scripts/tests/clarify-question-evidence-test.sh
bash scripts/tests/figma-markup-checklist-test.sh
bash scripts/tests/teach-review-contract-test.sh
bash scripts/tests/mapped-third-party-skills-test.sh
bash scripts/tests/propose-commit-test.sh
bash scripts/tests/plain-language-chat-test.sh
bash scripts/tests/code-comments-test.sh
bash scripts/tests/developer-reviewer-handoff-test.sh
bash scripts/harness-bench.sh
```

## Checks

1. `skills/engineer-review/SKILL.md` **Context budget** lists Always-on / Phase-only / Merge-only with concrete files.
2. `agents/csp-engineer-reviewer.md` is a short pointer; spine steps live only in the skill.
3. Abort on catastrophic budget does not require loading `feedback-format.md` / humanizers.
4. Merge/report loads feedback pack; phases still open full checklists when triggers fire (logic, architecture, figma Always load).
5. `skill-map.md` still has Database skill routing ids for installer; orch uses `skill-map-orch.md`.
6. Checklist bodies under `references/` are present (not deleted to fake a size win).
7. Record after sizes: skill / agent / refs / total skill tree vs baseline.

## Pass

All listed scripts exit 0 and harness-bench exits 0.
