#!/usr/bin/env bash
# Teach-review helpers (sourceable library).
# Usage: source scripts/teach-review.sh

tr__home() {
  printf '%s' "${TR_HOME:-$HOME}"
}

tr_strip_jsonc() {
  sed -E '/^[[:space:]]*\/\//d'
}

tr_land_from_file() {
  local f="$1" json="" land=""
  if [[ ! -f "$f" ]]; then
    printf ''
    return 0
  fi
  json="$(tr_strip_jsonc < "$f")"
  land="$(printf '%s\n' "$json" | sed -nE 's/.*"land"[[:space:]]*:[[:space:]]*"(auto_push|draft_merge)".*/\1/p' | head -n 1)"
  if [[ -n "$land" ]]; then
    printf '%s' "$land"
    return 0
  fi
  if printf '%s\n' "$json" | grep -Eq '"land"[[:space:]]*:'; then
    printf 'invalid'
    return 0
  fi
  printf ''
}

tr_resolve_land() {
  local project_root="${1%/}" home dest land
  home="$(tr__home)"
  dest="$project_root/.cursor/cursor-spells-learn.json"
  land="$(tr_land_from_file "$dest")"
  if [[ "$land" == "auto_push" || "$land" == "draft_merge" ]]; then
    printf '%s' "$land"
    return 0
  fi
  if [[ "$land" == "invalid" ]]; then
    echo "teach-review: invalid land in $dest — using draft_merge" >&2
    printf '%s' "draft_merge"
    return 0
  fi
  dest="$home/.cursor/cursor-spells-learn.json"
  land="$(tr_land_from_file "$dest")"
  if [[ "$land" == "auto_push" || "$land" == "draft_merge" ]]; then
    printf '%s' "$land"
    return 0
  fi
  if [[ "$land" == "invalid" ]]; then
    echo "teach-review: invalid land in $dest — using draft_merge" >&2
  fi
  printf '%s' "draft_merge"
}

tr_kit_path() {
  local project_root="${1%/}" home f
  home="$(tr__home)"
  f="$project_root/.cursor/cursor-spells-kit-path"
  if [[ -f "$f" ]]; then
    tr -d '\n' < "$f"
    return 0
  fi
  f="$home/.cursor/cursor-spells-kit-path"
  if [[ -f "$f" ]]; then
    tr -d '\n' < "$f"
    return 0
  fi
  printf ''
}

tr_is_kit_checkout() {
  local path="${1%/}"
  [[ -d "$path/.git" || -f "$path/.git" ]] || return 1
  git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  [[ -e "$path/skills/engineer-review" && -f "$path/agents/csp-engineer-reviewer.md" ]]
}

tr_kit_is_dirty() {
  local kit="$1" out
  out="$(git -C "$kit" status --porcelain 2>/dev/null || true)"
  [[ -n "$out" ]]
}

tr_learn_branch_base() {
  local miss_class="$1" day="${2:-}"
  if [[ -z "$day" ]]; then
    day="$(date +%Y%m%d)"
  fi
  printf 'learn/%s-%s' "$miss_class" "$day"
}

tr_unique_learn_branch() {
  local kit="$1" base="$2" name="$2" n=2
  while git -C "$kit" show-ref --verify --quiet "refs/heads/$name" \
     || git -C "$kit" show-ref --verify --quiet "refs/remotes/origin/$name"; do
    name="${base}-${n}"
    n=$((n + 1))
  done
  printf '%s' "$name"
}

tr_install_learn_config() {
  local dest="$1" template="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  cp "$template" "$dest"
}

tr_land_opens_pr() {
  [[ "$1" == "draft_merge" ]]
}
