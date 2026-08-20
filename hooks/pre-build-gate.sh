#!/usr/bin/env bash
# Reminds the agent if plan approval or critique is still pending before build.
# Does NOT auto-dispatch Task 1.
# Install: copy/symlink this file + hooks.json into the consumer project's .cursor/

set -euo pipefail

input="$(cat || true)"

# Prefer workspace root from hook payload when present; else cwd
root="$(pwd)"
if command -v jq >/dev/null 2>&1; then
  w="$(printf '%s' "$input" | jq -r '.workspace_roots[0] // .cwd // empty' 2>/dev/null || true)"
  if [[ -n "${w:-}" && -d "$w" ]]; then
    root="$w"
  fi
fi

emit_followup() {
  local message="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '{"followup_message":%s}\n' "$(printf '%s' "$message" | jq -Rs .)"
  else
    local safe_message
    safe_message="$(printf '%s' "$message" | tr -d '"\\' | tr '\n' ' ')"
    printf '%s\n' "{\"followup_message\":\"${safe_message}\"}"
  fi
}

status=""
if command -v jq >/dev/null 2>&1; then
  status="$(printf '%s' "$input" | jq -r '.status // empty' 2>/dev/null || true)"
else
  status="$(printf '%s' "$input" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi

if [[ "$status" == "aborted" || "$status" == "error" ]]; then
  printf '%s\n' '{}'
  exit 0
fi

pg_lib="$root/scripts/pipeline-gates.sh"
if [[ ! -f "$pg_lib" ]]; then
  hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ "$hook_dir" == */.cursor/hooks ]]; then
    pg_lib="$(cd "$hook_dir/../.." && pwd)/scripts/pipeline-gates.sh"
  else
    pg_lib="$(cd "$hook_dir/.." && pwd)/scripts/pipeline-gates.sh"
  fi
fi

if [[ ! -f "$pg_lib" ]]; then
  emit_followup "pipeline-gates helper missing at $root/scripts/pipeline-gates.sh. Run csp update to refresh kit scripts."
  exit 0
fi

# shellcheck source=/dev/null
source "$pg_lib"

pg_migrate_legacy "$root" plan-gate
pg_migrate_legacy "$root" critique-gate

plan_path=""
if [[ -n "${CURSOR_PLAN_PATH:-}" ]]; then
  plan_path="$(printf '%s\n' "$CURSOR_PLAN_PATH" | head -n 1 | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
fi
if [[ -z "$plan_path" ]] && command -v jq >/dev/null 2>&1; then
  plan_path="$(printf '%s' "$input" | jq -r '.plan_path // .plan // empty' 2>/dev/null || true)"
fi

if [[ -n "$plan_path" ]]; then
  for kind in plan-gate critique-gate; do
    slug="$(pg_slug_for_plan "$root" "$plan_path" "$kind")"
    gate_file="$(pg_gate_path "$root" "$kind" "$slug")"
    if [[ -f "$gate_file" ]]; then
      rel_gate="${gate_file#"$root"/}"
      if [[ "$kind" == "plan-gate" ]]; then
        message="Plan-gate marker still present (${rel_gate}, plan: ${plan_path}). Wait for approve-plan or revise before running the critic or dispatching Task 1."
      else
        message="Critique-gate marker still present (${rel_gate}, plan: ${plan_path}). implementation-critic has blocking findings or accept-risk items pending. Resolve them (revise the plan via /approve-plan, or reply accept F<id>) before dispatching Task 1."
      fi
      emit_followup "$message"
      exit 0
    fi
  done
fi
# Unknown plan path: stay silent. followup_message auto-continues every chat
# in this workspace. Listing foreign slugs is unresolvable there (do not
# delete) and loops until hooks.json loop_limit. Skills still gate this plan.

printf '%s\n' '{}'
exit 0
