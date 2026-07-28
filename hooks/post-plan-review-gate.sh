#!/usr/bin/env bash
# Reminds the agent about HITL review gate after plan completion.
# Does NOT auto-start engineer-review (preserves human-in-the-loop).
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

marker="$root/.cursor/review-gate.pending"

if [[ -f "$marker" ]]; then
  # Only nudge when status is completed (best-effort parse without requiring jq)
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

  # Important: followup_message auto-continues the agent. If we only say "ask
  # HITL", the agent re-asks forever and ignores a prior user skip/approve/done
  # that arrived while the stop-hook loop was running. Prefer honoring an
  # existing answer; only re-ask when none is in the chat yet.
  printf '%s\n' '{"followup_message":"Plan-complete marker still present (.cursor/review-gate.pending). If the user already replied skip, approve, or done anywhere in this chat after the gate was asked, delete .cursor/review-gate.pending immediately and continue skill finish-plan (start engineer-reviewer or multi-repo-supervisor). Do not re-ask. Only ask HITL via skill hitl-choice (AskQuestion when available; else typed skip / approve / done) if they have not answered yet."}'
  exit 0
fi

printf '%s\n' '{}'
exit 0
