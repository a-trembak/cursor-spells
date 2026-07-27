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

# Legacy alias: older installs used build-gate.pending for blocked critique
plan_marker="$root/.cursor/plan-gate.pending"
critique_marker="$root/.cursor/critique-gate.pending"
legacy_marker="$root/.cursor/build-gate.pending"

marker=""
kind=""
if [[ -f "$plan_marker" ]]; then
  marker="$plan_marker"
  kind="plan-gate"
elif [[ -f "$critique_marker" ]]; then
  marker="$critique_marker"
  kind="critique-gate"
elif [[ -f "$legacy_marker" ]]; then
  marker="$legacy_marker"
  kind="build-gate (legacy critique)"
fi

if [[ -n "$marker" ]]; then
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
  if [[ "$kind" == "plan-gate" ]]; then
    message="Plan-gate marker still present (.cursor/plan-gate.pending, plan: ${plan_path}). Wait for approve-plan or revise before running the critic or dispatching Task 1."
  else
    message="Critique-gate marker still present (${marker#"$root"/}, plan: ${plan_path}). implementation-critic has blocking findings or accept-risk items pending. Resolve them (revise the plan via /approve-plan, or reply accept F<id>) before dispatching Task 1."
  fi
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
