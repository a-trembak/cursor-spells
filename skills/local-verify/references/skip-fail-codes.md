# Skip / fail reason codes

Used in chat reports and in `.cursor/gates/local-verify/<slug>` (`status` + `reason`).

| Code | Typical `status` | When |
|------|------------------|------|
| `no_contract` | `skip` | No `.cursor/spells-local-verify.yaml` (or unreadable) at the consumer / repo root |
| `disabled` | `skip` | Contract exists with `enabled: false` |
| `stack_noop` | `skip` | Contract declares noop stack (`kind: noop` / no startable services) |
| `runtime_unavailable` | `skip` (or `fail` if blocking policy requires) | Declared `kind` needs Docker or Node and that runtime is missing |
| `secrets_missing` | `fail` or `skip` | `secrets.mode: required` and a listed path is absent |
| `fail` | `fail` | One or more services failed health after `up` and wait |
| `pass` | `pass` | All required services healthy (health-first or after `up`) |

## Blocking

- `blocking: false` (default): `fail` / `secrets_missing` are reported; pipeline still continues to `create-pr`.
- `blocking: true`: on fail, stop and ask HITL preset **Local verify blocking fail** (`fix` / `skip_verify` / `retry`).

## Gate file shape

```
<plan-path-or-runs-branch>
status=<pass|fail|skip>
reason=<code>
```
