#!/usr/bin/env bash
# Reminds the agent about the pre-build critique gate if it's still pending.
# Does NOT auto-dispatch Task 1 (preserves the critique gate).
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

marker="$root/.cursor/build-gate.pending"

if [[ -f "$marker" ]]; then
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

  plan_path="$(cat "$marker" 2>/dev/null || true)"
  message="Build-gate marker still present (.cursor/build-gate.pending, plan: ${plan_path}). implementation-critic found blocking findings or accept-risk items pending. Resolve them (revise the plan or reply accept F<id>) before dispatching Task 1."
  if command -v jq >/dev/null 2>&1; then
    printf '{"followup_message":%s}\n' "$(printf '%s' "$message" | jq -Rs .)"
  else
    safe_message="$(printf '%s' "$message" | tr -d '"\\' | tr '\n' ' ')"
    printf '%s\n' "{\"followup_message\":\"${safe_message}\"}"
  fi
  exit 0
fi

printf '%s\n' '{}'
exit 0
