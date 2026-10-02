# Engineer-review graphify hook

Review stages use graphify **read-only**. Full orchestrator steps remain in:

`skills/engineer-review/references/graphify-protocol.md`

This skill adds only the cross-pipeline rule:

- **Assume** implement agents ran `graphify-pipeline.sh refresh` after verify when artifacts exist.
- If review detects stale structure (removed symbols still in graph, missing new files), note `graphify: possibly_stale` in Coverage and ask the human to run refresh locally — do **not** run `refresh` inside review.
