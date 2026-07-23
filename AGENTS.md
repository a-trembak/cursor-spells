# cursor-spells

Personal Cursor workflow kit — skills, slash commands, rules, hooks, and agents. See `README.md` for the product overview and end-user install instructions.

## Cursor Cloud specific instructions

This repo is a **pure Bash content kit**, not a running application. There is **no package manager, no build step, no dev server, and no automated test suite** (no `package.json`, lockfiles, `Makefile`, or CI test config). "Running" the product means executing the installer CLI and the hook/CI shell scripts directly.

- Everything is Bash + Markdown/JSON content. Required runtime tools (`bash`, `git`, coreutils) are preinstalled; `jq` and `node` are present but optional. `shellcheck` is **not** installed.
- No dependencies to install and nothing to build. The startup update script is effectively a no-op (only re-asserts executable bits).

### Lint / test / run

- **Lint** (closest available proxy, no `shellcheck`): syntax-check every script with `bash -n bin/csp bin/cursor-spells scripts/*.sh hooks/*.sh` and validate `jq . hooks/hooks.json`.
- **Run (CLI)**: `./bin/csp help`, `./bin/csp version`, and `./bin/csp install <project-path>` (or `./bin/csp install --user-only`). Flags documented in `bin/cursor-spells` and `scripts/install-to-project.sh`.
- **Test (functional, no framework)**: install into a throwaway project, e.g. `./bin/csp install /tmp/sandbox-project`, then verify symlinks land under `~/.cursor/{skills,commands,agents}` and hooks/rule/patterns files land under `<project>/.cursor/` and `<project>/scripts/`.

### Non-obvious gotchas

- `install-to-project.sh` **symlinks** kit content into `~/.cursor` by default, so edits in the repo are reflected live; `--copy` mode requires re-running install after kit changes. Re-running install is idempotent — existing targets print `skip (exists)` and are never overwritten (delete the target first to force a refresh).
- `scripts/check-project-patterns.sh` diffs against `BASE_REF` (default `origin/main`). When that ref is absent it falls back to an empty-tree range that yields **no** changed paths, so it reports "ok" and never fails. For local testing of the `--strict` failure path, pass an existing ref, e.g. `BASE_REF=HEAD~1 ./scripts/check-project-patterns.sh --strict`.
- `hooks/post-plan-review-gate.sh` reads a hook JSON payload from **stdin** and only emits a follow-up message when `<root>/.cursor/review-gate.pending` exists and status is not `aborted`/`error`. It uses `jq` if present, otherwise a `sed` fallback.
