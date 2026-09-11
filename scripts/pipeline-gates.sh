#!/usr/bin/env bash
# Per-plan pipeline gate helpers (sourceable library).
# Usage: source "$KIT/scripts/pipeline-gates.sh"

pg__root() {
  if [[ -n "${PG_ROOT:-}" ]]; then
    printf '%s' "${PG_ROOT%/}"
  else
    printf '%s' "${1%/}"
  fi
}

pg_normalize_plan_path() {
  local root plan_path norm
  root="$(pg__root "$1")"
  plan_path="$2"
  norm="$plan_path"

  if [[ "$norm" == "$root/"* ]]; then
    norm="${norm#"$root"/}"
  fi

  while [[ "$norm" == ./* ]]; do
    norm="${norm#./}"
  done

  while [[ "$norm" == *//* ]]; do
    norm="${norm//\/\//\/}"
  done

  norm="${norm%/}"
  printf '%s' "$norm"
}

pg__path_hash12() {
  local norm="$1" digest=""
  if command -v sha256sum >/dev/null 2>&1; then
    digest="$(printf '%s' "$norm" | sha256sum | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    digest="$(printf '%s' "$norm" | shasum -a 256 | awk '{print $1}')"
  else
    echo "pipeline-gates: sha256sum or shasum required" >&2
    return 1
  fi
  printf '%s' "${digest:0:12}"
}

pg__extract_ticket() {
  local norm="$1" basename="${norm##*/}" ticket=""

  if [[ "$basename" =~ ([A-Za-z][A-Za-z0-9]*-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
    printf '%s' "${ticket^^}"
    return 0
  fi

  if [[ "$norm" =~ ([A-Za-z][A-Za-z0-9]*-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
    printf '%s' "${ticket^^}"
    return 0
  fi

  return 1
}

pg__base_slug_for_plan() {
  local root="$1" plan_path="$2" norm ticket=""
  norm="$(pg_normalize_plan_path "$root" "$plan_path")"
  if ticket="$(pg__extract_ticket "$norm")"; then
    printf '%s' "$ticket"
  else
    pg__path_hash12 "$norm"
  fi
}

pg_gate_dir() {
  local root kind
  root="$(pg__root "$1")"
  kind="$2"
  printf '%s/.cursor/gates/%s' "$root" "$kind"
}

pg_gate_path() {
  local root kind slug
  root="$(pg__root "$1")"
  kind="$2"
  slug="$3"
  printf '%s/%s' "$(pg_gate_dir "$root" "$kind")" "$slug"
}

pg_legacy_path() {
  local root kind
  root="$(pg__root "$1")"
  kind="$2"
  case "$kind" in
    plan-gate) printf '%s/.cursor/plan-gate.pending' "$root" ;;
    critique-gate) printf '%s/.cursor/critique-gate.pending' "$root" ;;
    plan-critique-clear) printf '%s/.cursor/plan-critique.clear' "$root" ;;
    review-gate) printf '%s/.cursor/review-gate.pending' "$root" ;;
    docs-gate) printf '%s/.cursor/docs-gate.pending' "$root" ;;
    commit-approved) printf '%s/.cursor/commit-approved.pending' "$root" ;;
    *)
      echo "pipeline-gates: unknown kind: $kind" >&2
      return 1
      ;;
  esac
}

pg_slug_for_plan() {
  local root plan_path kind candidate norm gate_file existing_line1 existing_norm hash12
  root="$(pg__root "$1")"
  plan_path="$2"
  kind="${3:-}"

  if [[ -z "$kind" ]]; then
    pg__base_slug_for_plan "$root" "$plan_path"
    return
  fi

  norm="$(pg_normalize_plan_path "$root" "$plan_path")"
  candidate="$(pg__base_slug_for_plan "$root" "$plan_path")"

  if [[ "$candidate" =~ ^[0-9a-f]{12}$ ]]; then
    printf '%s' "$candidate"
    return
  fi

  gate_file="$(pg_gate_path "$root" "$kind" "$candidate")"
  if [[ -f "$gate_file" ]]; then
    existing_line1="$(head -n 1 "$gate_file" | tr -d '\r')"
    existing_norm="$(pg_normalize_plan_path "$root" "$existing_line1")"
    if [[ "$existing_norm" != "$norm" ]]; then
      hash12="$(pg__path_hash12 "$norm")"
      printf '%s-%s' "$candidate" "$hash12"
      return
    fi
  fi

  printf '%s' "$candidate"
}

pg__write_gate_file() {
  local root="$1" kind="$2" plan_path="$3" slug="$4"
  local norm base_slug gate_path gate_dir
  norm="$(pg_normalize_plan_path "$root" "$plan_path")"
  base_slug="$(pg__base_slug_for_plan "$root" "$plan_path")"
  gate_path="$(pg_gate_path "$root" "$kind" "$slug")"
  gate_dir="$(pg_gate_dir "$root" "$kind")"
  mkdir -p "$gate_dir"
  {
    printf '%s\n' "$norm"
    if [[ "$slug" == "$base_slug" && ! "$slug" =~ ^[0-9a-f]{12}$ ]]; then
      printf 'ticket: %s\n' "$base_slug"
    fi
  } >"$gate_path"
}

pg_migrate_legacy() {
  local root kind plan_path="${3:-}" legacy line1 norm_plan norm_legacy slug
  root="$(pg__root "$1")"
  kind="$2"
  legacy="$(pg_legacy_path "$root" "$kind")"

  if [[ ! -f "$legacy" ]]; then
    return 0
  fi

  line1="$(head -n 1 "$legacy" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ -z "$line1" ]]; then
    echo "warning: legacy gate $legacy has empty plan path; skipping migrate" >&2
    return 0
  fi

  if [[ -n "$plan_path" ]]; then
    norm_plan="$(pg_normalize_plan_path "$root" "$plan_path")"
    norm_legacy="$(pg_normalize_plan_path "$root" "$line1")"
    if [[ "$norm_plan" != "$norm_legacy" ]]; then
      return 0
    fi
  fi

  slug="$(pg_slug_for_plan "$root" "$line1" "$kind")"
  if [[ ! -f "$(pg_gate_path "$root" "$kind" "$slug")" ]]; then
    pg__write_gate_file "$root" "$kind" "$line1" "$slug"
  fi
  rm -f "$legacy"
  return 0
}

pg_write_gate() {
  local root kind plan_path slug
  root="$(pg__root "$1")"
  kind="$2"
  plan_path="$3"
  pg_migrate_legacy "$root" "$kind" "$plan_path"
  slug="$(pg_slug_for_plan "$root" "$plan_path" "$kind")"
  pg__write_gate_file "$root" "$kind" "$plan_path" "$slug"
}

pg__find_gate_for_plan() {
  local root="$1" kind="$2" plan_path="$3" norm dir f line1 existing_norm
  norm="$(pg_normalize_plan_path "$root" "$plan_path")"
  dir="$(pg_gate_dir "$root" "$kind")"

  if [[ ! -d "$dir" ]]; then
    return 1
  fi

  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    line1="$(head -n 1 "$f" | tr -d '\r')"
    existing_norm="$(pg_normalize_plan_path "$root" "$line1")"
    if [[ "$existing_norm" == "$norm" ]]; then
      printf '%s' "$f"
      return 0
    fi
  done

  return 1
}

pg_clear_gate() {
  local root kind plan_path gate_file
  root="$(pg__root "$1")"
  kind="$2"
  plan_path="$3"
  pg_migrate_legacy "$root" "$kind" "$plan_path"
  if gate_file="$(pg__find_gate_for_plan "$root" "$kind" "$plan_path")"; then
    rm -f "$gate_file"
  fi
  return 0
}

pg_list_gates() {
  local root kind dir f slug line1
  root="$(pg__root "$1")"
  kind="$2"
  pg_migrate_legacy "$root" "$kind"
  dir="$(pg_gate_dir "$root" "$kind")"

  if [[ ! -d "$dir" ]]; then
    return 0
  fi

  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    slug="${f##*/}"
    line1="$(head -n 1 "$f" | tr -d '\r')"
    printf '%s\t%s\n' "$slug" "$line1"
  done
}
