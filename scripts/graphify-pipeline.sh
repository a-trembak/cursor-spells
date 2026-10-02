#!/usr/bin/env bash
# Graphify helpers for cursor-spells pipeline stages (detect, query, refresh).
# Read-only graph use during review; refresh after verified code changes on implement paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  graphify-pipeline.sh detect --root <repo>
  graphify-pipeline.sh query --root <repo> --question "<text>"
  graphify-pipeline.sh impact-hint --root <repo> --paths "<comma-separated paths>"
  graphify-pipeline.sh refresh --root <repo> [--force]

Exit codes: 0 success / skip; 1 refresh or query failed when graphify was expected to run.

Machine-oriented stdout (key=value or short text). Agents should not paste full graph.json.
EOF
  exit "${1:-0}"
}

resolve_artifacts_root() {
  local repo="$1"
  repo="$(cd "$repo" && pwd)"
  if [[ -f "$repo/graphify-out/graph.json" || -f "$repo/graphify-out/GRAPH_REPORT.md" ]]; then
    echo "$repo"
    return 0
  fi
  local parent
  parent="$(cd "$repo/.." && pwd)"
  if [[ -f "$parent/graphify-out/graph.json" || -f "$parent/graphify-out/GRAPH_REPORT.md" ]]; then
    echo "$parent"
    return 0
  fi
  return 1
}

cli_available() {
  command -v graphify >/dev/null 2>&1
}

truncate_output() {
  local max="${GRAPHIFY_PIPELINE_MAX_LINES:-60}"
  awk -v m="$max" 'NR<=m { print } NR==m+1 { print "... (truncated)"; exit }'
}

cmd_detect() {
  local root="${1:?}"
  root="$(cd "$root" && pwd)"
  if ! artifacts_root="$(resolve_artifacts_root "$root")"; then
    echo "state=absent"
    return 0
  fi
  echo "artifacts_root=$artifacts_root"
  if ! cli_available; then
    echo "state=unqueryable"
    echo "reason=cli_missing"
    return 0
  fi
  echo "state=used"
}

cmd_query() {
  local root="${1:?}"
  local question="${2:?}"
  local artifacts_root
  if ! artifacts_root="$(resolve_artifacts_root "$root")"; then
    echo "state=absent"
    return 0
  fi
  if ! cli_available; then
    echo "state=unqueryable"
    return 0
  fi
  echo "state=used"
  (cd "$artifacts_root" && graphify query "$question") | truncate_output
}

cmd_impact_hint() {
  local root="${1:?}"
  local paths="${2:?}"
  cmd_query "$root" "modules impacted by: $paths"
}

cmd_refresh() {
  local root="${1:?}"
  local force="${2:-0}"
  root="$(cd "$root" && pwd)"
  if ! resolve_artifacts_root "$root" >/dev/null; then
    echo "graphify_refresh=skipped"
    echo "reason=absent"
    return 0
  fi
  if ! cli_available; then
    echo "graphify_refresh=skipped"
    echo "reason=cli_missing"
    return 0
  fi
  local -a update_args=(update "$root")
  if [[ "$force" == "1" ]]; then
    update_args+=(--force)
  fi
  if graphify "${update_args[@]}" 2>&1 | truncate_output; then
    echo "graphify_refresh=ok"
    return 0
  fi
  echo "graphify_refresh=failed"
  return 1
}

main() {
  local cmd="${1:-}"
  shift || usage 1
  case "$cmd" in
    detect)
      local root="."
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --root) root="${2:?}"; shift 2 ;;
          -h|--help) usage 0 ;;
          *) echo "Unknown arg: $1" >&2; usage 1 ;;
        esac
      done
      cmd_detect "$root"
      ;;
    query)
      local root="." question=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --root) root="${2:?}"; shift 2 ;;
          --question) question="${2:?}"; shift 2 ;;
          -h|--help) usage 0 ;;
          *) echo "Unknown arg: $1" >&2; usage 1 ;;
        esac
      done
      [[ -n "$question" ]] || { echo "--question required" >&2; usage 1; }
      cmd_query "$root" "$question"
      ;;
    impact-hint)
      local root="." paths=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --root) root="${2:?}"; shift 2 ;;
          --paths) paths="${2:?}"; shift 2 ;;
          -h|--help) usage 0 ;;
          *) echo "Unknown arg: $1" >&2; usage 1 ;;
        esac
      done
      [[ -n "$paths" ]] || { echo "--paths required" >&2; usage 1; }
      cmd_impact_hint "$root" "$paths"
      ;;
    refresh)
      local root="." force=0
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --root) root="${2:?}"; shift 2 ;;
          --force) force=1; shift ;;
          -h|--help) usage 0 ;;
          *) echo "Unknown arg: $1" >&2; usage 1 ;;
        esac
      done
      cmd_refresh "$root" "$force"
      ;;
    -h|--help|help) usage 0 ;;
    *) echo "Unknown command: $cmd" >&2; usage 1 ;;
  esac
}

main "$@"
