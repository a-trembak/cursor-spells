# Contract schema — `.cursor/spells-local-verify.yaml`

Normative field documentation for schema **version 1**. See also the design spec `docs/superpowers/specs/2026-09-21-local-verify-design.md`.

## Top level

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `version` | yes | — | Must be `1` |
| `enabled` | yes | — | When `false`, skill skips with reason `disabled` |
| `blocking` | no | `false` | When `true`, health/`secrets_missing` fail stops until HITL `fix` / `skip_verify` / `retry` |
| `timeout_sec` | no | implementation default (recommend `180`) | Max seconds to wait for health after starting a service |
| `secrets` | no | — | Optional secrets presence check (paths only) |
| `services` | yes when enabled | — | List of services to health-check / start |

## `secrets`

| Field | Required | Description |
|-------|----------|-------------|
| `mode` | yes if `secrets` present | `skip_if_missing` — missing file does not hard-fail; `required` — missing file → `secrets_missing` |
| `files` | yes if `secrets` present | Array of **relative paths** to files that must exist (or may be skipped). **Never** put secret values in this file or in chat |

## `services[]`

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Stable identifier for reports and logs |
| `kind` | yes | `compose` \| `npm` \| `node` \| `custom` \| `noop` |
| `cwd` | yes | Working directory relative to the repository root |
| `up` | yes unless `noop` | Exact argv array executed when health is not already green (example: `["docker", "compose", "up", "-d", "api"]`) |
| `health` | yes unless `noop` | Health probe (see below) |

### `kind`

| Value | Runtime probe | Notes |
|-------|---------------|-------|
| `compose` | Docker available | `up` usually invokes `docker` / `docker compose` |
| `npm` | Node / npm available | `up` is still the exact argv from the contract — **not** inferred from `package.json` |
| `node` | Node available | Same invent-forbid as `npm` |
| `custom` | None beyond what `up` needs | Agent runs argv only |
| `noop` | None | Skip start; reason `stack_noop` when the whole stack is noop |

### `health`

One of:

| `type` | Fields | Pass when |
|--------|--------|-----------|
| `http` | `url` | HTTP GET (or HEAD) to `url` returns success (2xx) within timeout |
| `tcp` | `host`, `port` | TCP connect succeeds |
| `command` | `argv` (string array) | Command exits 0 |

Example:

```yaml
health:
  type: http
  url: "http://127.0.0.1:8080/health"
```

## Invent forbid (normative)

The executor may **classify** missing contract, disabled flag, missing Docker/Node for declared kinds, or noop. It must **not**:

- Read `package.json` `scripts` to choose an `up` command
- Parse Compose files to invent service names or `up` argv
- Guess ports or health URLs not present in the contract
