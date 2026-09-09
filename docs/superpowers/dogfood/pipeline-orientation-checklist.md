# Dogfood: pipeline orientation

Manual checks for the where-am-I strip and live canvas highlight.

## Preconditions

- Kit (or installed project) has `scripts/pipeline-status.sh`
- Browser can open `docs/superpowers/pipeline-flow.html` (or the printed absolute path)

## Steps

1. **Fake review-gate marker** in a scratch project root (or this kit):

   ```bash
   mkdir -p .cursor/gates/review-gate
   printf '%s\n' "docs/plans/dogfood-orientation.md" > .cursor/gates/review-gate/DOGFOOD
   ```

2. **Run resolver:**

   ```bash
   bash scripts/pipeline-status.sh --root .
   bash scripts/pipeline-status.sh --json --root .
   bash scripts/pipeline-status.sh --canvas-url --root . --kit-root .
   ```

   Expect: `layer=review`, `stage=review-gate`, non-empty strip, canvas URL containing `route=`, `layer=review`, `stage=review-gate`, and `#review-gate`.

3. **Open the printed canvas URL** in a browser.

   Expect: overview layers highlighted (`review` as here; earlier done); if hash is `#review-gate`, the detail view opens; query params remain so **Back to overview** still shows highlight.

4. **Clear the marker** and re-run:

   ```bash
   rm -f .cursor/gates/review-gate/DOGFOOD
   bash scripts/pipeline-status.sh --json --root .
   ```

   Expect: with no pending gates and no useful ledger stage, `stage`/`layer` report `idle` (or last ledger stage if a session file remains).

5. **Optional:** run `/csp-pipeline-status` in chat and confirm the orchestrator adapts the English skeleton per `plain-language-chat`.

## Pass criteria

- [ ] Strip + JSON match pending-gate precedence
- [ ] Canvas URL highlights correctly
- [ ] Clearing the marker removes the review-gate orientation
- [ ] No gate files were written by the status script itself
