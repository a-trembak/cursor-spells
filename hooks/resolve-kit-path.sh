#!/usr/bin/env bash
# Resolve the cursor-spells kit checkout for project hooks.
# Pipeline helpers live in the kit; they are never vendored into consumer scripts/.
# Usage: source this file from a sibling hook, then:
#   pg_lib="$(csp_hook_pipeline_gates "$root")" || true

csp_hook_resolve_kit() {
  local root="${1:-}" kit=""
  if [[ -n "$root" && -f "$root/.cursor/cursor-spells-kit-path" ]]; then
    kit="$(tr -d '\r\n' < "$root/.cursor/cursor-spells-kit-path")"
  fi
  if [[ -z "$kit" && -f "${HOME}/.cursor/cursor-spells-kit-path" ]]; then
    kit="$(tr -d '\r\n' < "${HOME}/.cursor/cursor-spells-kit-path")"
  fi
  printf '%s' "$kit"
}

# Print absolute path to kit scripts/pipeline-gates.sh, or return 1.
# Does not fall back to a consumer project's scripts/ folder.
csp_hook_pipeline_gates() {
  local root="${1:-}" kit="" self_dir candidate
  kit="$(csp_hook_resolve_kit "$root")"
  if [[ -n "$kit" && -f "$kit/scripts/pipeline-gates.sh" ]]; then
    printf '%s' "$kit/scripts/pipeline-gates.sh"
    return 0
  fi
  # Kit dogfood only: this file lives in <kit>/hooks (not <project>/.cursor/hooks).
  self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ "$self_dir" == */.cursor/hooks ]]; then
    return 1
  fi
  candidate="$(cd "$self_dir/.." && pwd)/scripts/pipeline-gates.sh"
  if [[ -f "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi
  return 1
}
