#!/usr/bin/env bash
# Pipeline orientation resolver: derive where-am-I from gates + session ledger.
# Usage:
#   pipeline-status.sh [--root <dir>]
#   pipeline-status.sh --json [--root <dir>]
#   pipeline-status.sh --canvas-url [--root <dir>] [--kit-root <dir>]
set -euo pipefail

ps__script_dir() {
  local src="${BASH_SOURCE[0]}"
  cd "$(dirname "$src")" && pwd
}

PS_MODE="text"
PS_ROOT=""
PS_KIT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      PS_MODE="json"
      shift
      ;;
    --canvas-url)
      PS_MODE="canvas-url"
      shift
      ;;
    --root)
      PS_ROOT="${2:?--root requires a directory}"
      shift 2
      ;;
    --kit-root)
      PS_KIT_ROOT="${2:?--kit-root requires a directory}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: pipeline-status.sh [--root <dir>] [--kit-root <dir>]
       pipeline-status.sh --json [--root <dir>]
       pipeline-status.sh --canvas-url [--root <dir>] [--kit-root <dir>]
EOF
      exit 0
      ;;
    *)
      echo "pipeline-status: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$PS_ROOT" ]]; then
  PS_ROOT="$(pwd)"
fi
PS_ROOT="$(cd "$PS_ROOT" && pwd)"

if [[ -z "$PS_KIT_ROOT" ]]; then
  # Prefer sibling of this script (kit or installed copy under project scripts/)
  PS_KIT_ROOT="$(cd "$(ps__script_dir)/.." && pwd)"
fi

# shellcheck source=pipeline-gates.sh
source "$(ps__script_dir)/pipeline-gates.sh"

# --- Collect pending human gates (plan/critique/review/docs) ---
ps__collect_pending() {
  local kind slug plan_path
  for kind in plan-gate critique-gate review-gate docs-gate; do
    while IFS=$'\t' read -r slug plan_path; do
      [[ -n "${slug:-}" ]] || continue
      printf '%s\t%s\t%s\n' "$kind" "$slug" "$plan_path"
    done < <(pg_list_gates "$PS_ROOT" "$kind")
  done
}

# Precedence for current stage/layer when several pending: docs > review > critique > plan
ps__pick_pending_kind() {
  local line kind
  local has_docs=0 has_review=0 has_critique=0 has_plan=0
  while IFS=$'\t' read -r kind _ _; do
    [[ -n "${kind:-}" ]] || continue
    case "$kind" in
      docs-gate) has_docs=1 ;;
      review-gate) has_review=1 ;;
      critique-gate) has_critique=1 ;;
      plan-gate) has_plan=1 ;;
    esac
  done < <(ps__collect_pending)
  if [[ "$has_docs" -eq 1 ]]; then
    printf '%s' "docs-gate"
  elif [[ "$has_review" -eq 1 ]]; then
    printf '%s' "review-gate"
  elif [[ "$has_critique" -eq 1 ]]; then
    printf '%s' "critique-gate"
  elif [[ "$has_plan" -eq 1 ]]; then
    printf '%s' "plan-gate"
  else
    return 1
  fi
}

ps__find_ledger() {
  local dir="$PS_ROOT/.cursor/gates/trajectory-run"
  if [[ -f "$dir/session-full.json" ]]; then
    printf '%s' "$dir/session-full.json"
    return 0
  fi
  if [[ -f "$dir/session-fast.json" ]]; then
    printf '%s' "$dir/session-fast.json"
    return 0
  fi
  if [[ -f "$dir/session-issue.json" ]]; then
    printf '%s' "$dir/session-issue.json"
    return 0
  fi
  return 1
}

ps__route_from_ledger() {
  local path="$1" base
  base="$(basename "$path")"
  case "$base" in
    session-full.json) printf '%s' "full" ;;
    session-fast.json) printf '%s' "fast" ;;
    session-issue.json) printf '%s' "issue" ;;
    *) printf '%s' "unknown" ;;
  esac
}

ps__layer_for_stage() {
  local stage="$1"
  case "$stage" in
    idle|"")
      printf '%s' "idle"
      ;;
    jira-fetch|jira-transition-in-progress|jira-transition|pipeline-route-hitl|bootstrap|fetch)
      printf '%s' "fetch"
      ;;
    tech-spec|writing-plans|approve-plan|implementation-critic|plan-gate|critique-gate|clean-decision-docs|issue-fix-plan)
      printf '%s' "plan"
      ;;
    start-build|software-developer|bug-fixer|executing-plans)
      printf '%s' "build"
      ;;
    review-gate|engineer-review|engineer-reviewer|multi-repo-supervisor)
      printf '%s' "review"
      ;;
    update-docs|create-pr|docs-gate|pipeline-finale-hitl)
      printf '%s' "ship"
      ;;
    *)
      # Heuristic fallbacks for gate-shaped or unknown stage ids
      case "$stage" in
        *review*) printf '%s' "review" ;;
        *docs*|*pr*) printf '%s' "ship" ;;
        *plan*|*spec*|*critic*) printf '%s' "plan" ;;
        *build*|*developer*|*fixer*) printf '%s' "build" ;;
        *fetch*|*route*|*jira*) printf '%s' "fetch" ;;
        *) printf '%s' "idle" ;;
      esac
      ;;
  esac
}

ps__legal_returns_json() {
  local stage="$1"
  case "$stage" in
    review-gate)
      printf '%s' '[{"from":"review-gate","to":"Build/software-developer","how":"Answer fixes at the gate"}]'
      ;;
    critique-gate|implementation-critic)
      printf '%s' '[{"from":"critique","to":"Plan/rewrite or same critic ask","how":"Answer revise or accept F<id>"}]'
      ;;
    plan-gate|approve-plan)
      printf '%s' '[{"from":"approve-plan","to":"Plan","how":"Answer revise"}]'
      ;;
    tech-spec)
      printf '%s' '[{"from":"tech-spec","to":"Plan","how":"Answer revise"}]'
      ;;
    docs-gate|update-docs)
      printf '%s' '[{"from":"docs","to":"Docs","how":"Provide path/URL"}]'
      ;;
    engineer-review|engineer-reviewer)
      printf '%s' '[{"from":"engineer-review","to":"Review","how":"Answer clarify tokens"}]'
      ;;
    *)
      printf '%s' '[]'
      ;;
  esac
}

ps__json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()[:-1] if False else sys.argv[1]))' "$1"
}

ps__build_record() {
  local pending_kind="" stage layer route="unknown" ledger_path="" critique_clear="false"
  local stages_json="[]" pending_json="[]" legal_json="[]"
  local canvas_path="docs/superpowers/pipeline-flow.html"
  local canvas_hash="" canvas_query=""
  local line kind slug plan_path first_pending_plan=""

  if ledger_path="$(ps__find_ledger)"; then
    route="$(ps__route_from_ledger "$ledger_path")"
    stages_json="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(json.dumps(d.get("stages_entered") or []))' "$ledger_path")"
  else
    ledger_path=""
  fi

  # pending_gates array
  pending_json="$(
    {
      echo '['
      local first=1
      while IFS=$'\t' read -r kind slug plan_path; do
        [[ -n "${kind:-}" ]] || continue
        if [[ "$first" -eq 1 ]]; then
          first=0
        else
          printf ','
        fi
        printf '{"kind":%s,"slug":%s,"plan_path":%s}' \
          "$(ps__json_escape "$kind")" \
          "$(ps__json_escape "$slug")" \
          "$(ps__json_escape "$plan_path")"
        if [[ -z "$first_pending_plan" ]]; then
          first_pending_plan="$plan_path"
        fi
      done < <(ps__collect_pending)
      echo ']'
    }
  )"

  if pending_kind="$(ps__pick_pending_kind)"; then
    stage="$pending_kind"
  elif [[ -n "$ledger_path" ]]; then
    stage="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); s=d.get("stages_entered") or []; print(s[-1] if s else "idle")' "$ledger_path")"
  else
    stage="idle"
  fi
  [[ -n "$stage" ]] || stage="idle"
  layer="$(ps__layer_for_stage "$stage")"

  # critique_clear: any plan-critique-clear marker
  if [[ -d "$PS_ROOT/.cursor/gates/plan-critique-clear" ]] && \
     compgen -G "$PS_ROOT/.cursor/gates/plan-critique-clear/*" >/dev/null 2>&1; then
    critique_clear="true"
  else
    critique_clear="false"
  fi

  legal_json="$(ps__legal_returns_json "$stage")"

  canvas_query="route=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$route")"
  canvas_query+="&layer=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$layer")"
  canvas_query+="&stage=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$stage")"
  if [[ "$stage" != "idle" ]]; then
    canvas_hash="#$stage"
  fi

  local ledger_json="null"
  if [[ -n "$ledger_path" ]]; then
    # Prefer path relative to project root when under PS_ROOT
    local rel="$ledger_path"
    if [[ "$ledger_path" == "$PS_ROOT/"* ]]; then
      rel="${ledger_path#"$PS_ROOT"/}"
    fi
    ledger_json="$(ps__json_escape "$rel")"
  fi

  python3 - "$route" "$layer" "$stage" "$pending_json" "$critique_clear" "$ledger_json" "$stages_json" "$legal_json" "$canvas_path" "$canvas_hash" "$canvas_query" <<'PY'
import json, sys
route, layer, stage = sys.argv[1], sys.argv[2], sys.argv[3]
pending = json.loads(sys.argv[4])
critique_clear = sys.argv[5] == "true"
ledger_raw = sys.argv[6]
ledger_path = None if ledger_raw == "null" else json.loads(ledger_raw)
stages = json.loads(sys.argv[7])
legal = json.loads(sys.argv[8])
canvas_path, canvas_hash, canvas_query = sys.argv[9], sys.argv[10], sys.argv[11]
rec = {
  "route": route,
  "layer": layer,
  "stage": stage,
  "pending_gates": pending,
  "critique_clear": critique_clear,
  "ledger_path": ledger_path,
  "stages_entered": stages,
  "legal_returns": legal,
  "canvas": {
    "path": canvas_path,
    "hash": canvas_hash,
    "query": canvas_query,
  },
}
print(json.dumps(rec, ensure_ascii=False))
PY
}

ps__print_text() {
  local json="$1"
  python3 - "$json" <<'PY'
import json, sys
d = json.loads(sys.argv[1])
route = d.get("route") or "unknown"
layer = d.get("layer") or "idle"
stage = d.get("stage") or "idle"
legal = d.get("legal_returns") or []
if legal:
    legal_bits = []
    for item in legal:
        to = item.get("to") or ""
        how = item.get("how") or ""
        if how:
            legal_bits.append(f"{to} ({how})")
        else:
            legal_bits.append(to)
    legal_s = "; ".join(legal_bits)
else:
    legal_s = "none — happy path only"
canvas = d.get("canvas") or {}
path = canvas.get("path") or "docs/superpowers/pipeline-flow.html"
query = canvas.get("query") or ""
hash_ = canvas.get("hash") or ""
link = path
if query:
    link += "?" + query
link += hash_

# Machine/English skeleton — orchestrator adapts to the human's language.
print(f"Route: {route} · Layer: {layer} · Stage: {stage}")
# Next stages hint from legal + stage family (kept short)
next_map = {
  "review-gate": "engineer-review → update-docs → create-pr",
  "docs-gate": "create-pr",
  "critique-gate": "start-build → software-developer",
  "plan-gate": "implementation-critic → start-build",
  "software-developer": "review-gate → engineer-review",
  "start-build": "software-developer → review-gate",
  "tech-spec": "writing-plans → approve-plan",
  "writing-plans": "approve-plan → implementation-critic",
  "idle": "(none)",
}
nxt = next_map.get(stage, "(see pipeline-flow)")
print(f"Next: {nxt}")
print(f"Legal returns: {legal_s}")
print(f"Canvas: {link}")
PY
}

ps__print_canvas_url() {
  local json="$1" kit="$2"
  python3 - "$json" "$kit" <<'PY'
import json, sys, os
d = json.loads(sys.argv[1])
kit = sys.argv[2]
canvas = d.get("canvas") or {}
path = canvas.get("path") or "docs/superpowers/pipeline-flow.html"
query = canvas.get("query") or ""
hash_ = canvas.get("hash") or ""
full = os.path.join(kit, path)
if query:
    full += "?" + query
full += hash_
print(full)
PY
}

RECORD="$(ps__build_record)"

case "$PS_MODE" in
  json)
    printf '%s\n' "$RECORD"
    ;;
  canvas-url)
    ps__print_canvas_url "$RECORD" "$PS_KIT_ROOT"
    ;;
  text)
    ps__print_text "$RECORD"
    ;;
esac
