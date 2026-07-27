#!/usr/bin/env bash
# Install / update cursor-spells into ~/.cursor and optionally a consumer project.
# Prefer: bin/csp install <project>   |   bin/csp update <project>
#
# Default: symlink kit skills/commands/agents into ~/.cursor;
#          copy hooks + rules (+ optional patterns helper) into the project.

set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT=""
USER_ONLY=0
WITH_HUMANIZER=0
COPY_MODE=0
FORCE_REFRESH=0
MODE="install" # install | update

usage() {
  cat <<'EOF'
Install or update cursor-spells.

Usage:
  install-to-project.sh <project-path> [flags]
  install-to-project.sh --user-only [flags]
  install-to-project.sh --update [<project-path>] [flags]

Flags:
  --update         Refresh mode (same as `csp update`): re-link kit bits, refresh project hooks/rules
  --user-only      Only ~/.cursor (no project files)
  --humanizer      Also install english-humanizer (or keep it if already linked)
  --copy           Copy into ~/.cursor instead of symlink
  -h, --help       Show help

Keep one clone of cursor-spells; install/update per project. Do not vendor the
kit inside every repository.
EOF
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --update) MODE="update"; FORCE_REFRESH=1; shift ;;
    --user-only|--global) USER_ONLY=1; shift ;;
    --humanizer) WITH_HUMANIZER=1; shift ;;
    --copy) COPY_MODE=1; shift ;;
    --user-skills|--hooks|--rule|--no-hooks|--no-rule)
      # Accepted no-ops / legacy aliases (hooks+rules always install with a project)
      shift
      ;;
    --*)
      echo "Unknown flag: $1" >&2
      usage 1
      ;;
    *)
      if [[ -n "$PROJECT" ]]; then
        echo "Unexpected argument: $1" >&2
        usage 1
      fi
      PROJECT="$1"
      shift
      ;;
  esac
done

if [[ "$USER_ONLY" -eq 0 && -z "$PROJECT" && "$MODE" != "update" ]]; then
  echo "Provide a consumer project path, or --user-only" >&2
  usage 1
fi

# `csp update` with no path → refresh ~/.cursor only (kit pull happens in CLI)
if [[ "$MODE" == "update" && -z "$PROJECT" ]]; then
  USER_ONLY=1
fi

if [[ -n "$PROJECT" ]]; then
  if [[ ! -d "$PROJECT" ]]; then
    echo "Project path does not exist: $PROJECT" >&2
    exit 1
  fi
  PROJECT="$(cd "$PROJECT" && pwd)"
fi

is_our_link() {
  local dest="$1"
  local src="$2"
  [[ -L "$dest" ]] || return 1
  local target
  target="$(readlink "$dest")"
  [[ "$target" == "$src" ]] && return 0
  # Allow relative or older absolute links that still resolve into this kit
  local resolved
  resolved="$(cd "$(dirname "$dest")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")" || return 1
  [[ "$resolved" == "$src" ]] && return 0
  case "$target" in
    "$KIT_ROOT"/*) return 0 ;;
  esac
  return 1
}

link_or_copy() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [[ "$COPY_MODE" -eq 1 ]]; then
    if [[ -e "$dest" || -L "$dest" ]]; then
      if [[ "$FORCE_REFRESH" -eq 1 ]]; then
        rm -rf "$dest"
        cp -R "$src" "$dest"
        echo "refreshed (copy): $dest"
        return 0
      fi
      echo "skip (exists): $dest"
      return 0
    fi
    cp -R "$src" "$dest"
    echo "copied: $dest"
    return 0
  fi

  # Symlink mode
  if [[ -L "$dest" ]]; then
    if is_our_link "$dest" "$src"; then
      if [[ "$FORCE_REFRESH" -eq 1 ]]; then
        rm -f "$dest"
        ln -s "$src" "$dest"
        echo "relinked: $dest -> $src"
      else
        echo "ok (linked): $dest"
      fi
      return 0
    fi
    if [[ "$FORCE_REFRESH" -eq 1 ]]; then
      echo "skip (foreign symlink): $dest -> $(readlink "$dest")"
      return 0
    fi
    echo "skip (exists): $dest"
    return 0
  fi

  if [[ -e "$dest" ]]; then
    echo "skip (exists, not a symlink): $dest"
    return 0
  fi

  ln -s "$src" "$dest"
  echo "linked: $dest -> $src"
}

want_skill() {
  local name="$1"
  if [[ "$name" == "english-humanizer" ]]; then
    [[ "$WITH_HUMANIZER" -eq 1 ]] && return 0
    # Keep syncing humanizer on update if it was installed earlier
    [[ -e "$HOME/.cursor/skills/english-humanizer" || -L "$HOME/.cursor/skills/english-humanizer" ]] && return 0
    return 1
  fi
  return 0
}

install_user_bits() {
  mkdir -p "$HOME/.cursor/skills" "$HOME/.cursor/commands" "$HOME/.cursor/agents"

  local src name
  for src in "$KIT_ROOT"/skills/*; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    want_skill "$name" || continue
    link_or_copy "$src" "$HOME/.cursor/skills/$name"
  done

  for src in "$KIT_ROOT"/commands/*.md; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    link_or_copy "$src" "$HOME/.cursor/commands/$name"
  done

  for src in "$KIT_ROOT"/agents/*.md; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    link_or_copy "$src" "$HOME/.cursor/agents/$name"
  done

  # Remember kit root for `csp status` / troubleshooting
  printf '%s\n' "$KIT_ROOT" > "$HOME/.cursor/cursor-spells-kit-path"
  echo "wrote: $HOME/.cursor/cursor-spells-kit-path"
}

install_project_bits() {
  mkdir -p "$PROJECT/.cursor/hooks" "$PROJECT/.cursor/rules" "$PROJECT/.cursor"

  # Hook scripts — always refresh from kit (owned by cursor-spells)
  local hook
  for hook in post-plan-review-gate.sh pre-build-gate.sh; do
    cp "$KIT_ROOT/hooks/$hook" "$PROJECT/.cursor/hooks/$hook"
    chmod +x "$PROJECT/.cursor/hooks/$hook"
    echo "copied: $PROJECT/.cursor/hooks/$hook"
  done

  if [[ ! -f "$PROJECT/.cursor/hooks.json" ]]; then
    cp "$KIT_ROOT/hooks/hooks.json" "$PROJECT/.cursor/hooks.json"
    echo "copied: $PROJECT/.cursor/hooks.json"
  elif [[ "$FORCE_REFRESH" -eq 1 ]]; then
    cp "$KIT_ROOT/hooks/hooks.json" "$PROJECT/.cursor/hooks.json"
    echo "refreshed: $PROJECT/.cursor/hooks.json"
  else
    echo "skip (exists): $PROJECT/.cursor/hooks.json (re-run with update to refresh)"
  fi

  # Rules — always refresh from kit
  local rule
  for rule in after-plan-review-gate.mdc before-build-critique-gate.mdc; do
    cp "$KIT_ROOT/rules/$rule" "$PROJECT/.cursor/rules/$rule"
    echo "copied: $PROJECT/.cursor/rules/$rule"
  done

  # Optional CI helper — create once; refresh on update
  mkdir -p "$PROJECT/scripts"
  if [[ ! -f "$PROJECT/scripts/check-project-patterns.sh" || "$FORCE_REFRESH" -eq 1 ]]; then
    cp "$KIT_ROOT/scripts/check-project-patterns.sh" "$PROJECT/scripts/check-project-patterns.sh"
    chmod +x "$PROJECT/scripts/check-project-patterns.sh"
    echo "copied: $PROJECT/scripts/check-project-patterns.sh"
  else
    echo "skip (exists): $PROJECT/scripts/check-project-patterns.sh"
  fi

  printf '%s\n' "$KIT_ROOT" > "$PROJECT/.cursor/cursor-spells-kit-path"
  echo "wrote: $PROJECT/.cursor/cursor-spells-kit-path"
}

echo "kit: $KIT_ROOT"
echo "mode: $MODE"

install_user_bits

if [[ "$USER_ONLY" -eq 0 && -n "$PROJECT" ]]; then
  install_project_bits
fi

echo "done."
if [[ -n "$PROJECT" ]]; then
  echo "project: $PROJECT"
fi
echo "next: open the project in Cursor → /start-task  /approve-plan  /pr-review  /engineer-review"
echo "tip: npx skills add vercel-labs/agent-skills@vercel-react-best-practices"
