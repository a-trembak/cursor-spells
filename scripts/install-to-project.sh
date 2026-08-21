#!/usr/bin/env bash
# Install / update cursor-spells into ~/.cursor and optionally a consumer project.
# Prefer: bin/csp install <project>   |   bin/csp update <project>
#
# Default: symlink kit skills/commands/agents into ~/.cursor;
#          copy always-on plain-language-chat rule into ~/.cursor/rules;
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
  install-to-project.sh [project-path] [flags]
  install-to-project.sh --user-only [flags]
  install-to-project.sh --update [project-path] [flags]

With no project-path: uses the current repo / multi-repo workspace (cwd).

Flags:
  --update         Refresh mode (same as `csp update`): re-link kit bits, refresh project hooks/rules
  --user-only      Only ~/.cursor (no project files); still copies the plain-language-chat rule
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

# Resolve default project when path omitted: current git repo or multi-repo workspace.
resolve_default_project() {
  local cwd root count d
  cwd="$(pwd)"

  # 1) Inside a git work tree → that repo's toplevel (leaf repo in a multi-repo is fine)
  if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$root"
    return 0
  fi

  # 2) Multi-repo / workspace parent markers at cwd
  if [[ -f "$cwd/.cursor/multi-repo.json" || -d "$cwd/graphify-out" ]]; then
    printf '%s\n' "$cwd"
    return 0
  fi

  # 3) Cwd looks like a workspace parent: 2+ immediate child git repos
  count=0
  for d in "$cwd"/*/; do
    [[ -d "$d" ]] || continue
    if git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      count=$((count + 1))
    fi
  done
  if [[ "$count" -ge 2 ]]; then
    printf '%s\n' "$cwd"
    return 0
  fi

  return 1
}

if [[ "$USER_ONLY" -eq 0 && -z "$PROJECT" ]]; then
  if PROJECT="$(resolve_default_project)"; then
    echo "project (auto): $PROJECT"
  else
    echo "No project path given, and cwd is not a git repo or multi-repo workspace." >&2
    echo "Run from inside a repo/workspace, pass a path, or use --user-only." >&2
    usage 1
  fi
fi

if [[ -n "$PROJECT" ]]; then
  if [[ ! -d "$PROJECT" ]]; then
    echo "Project path does not exist: $PROJECT" >&2
    exit 1
  fi
  PROJECT="$(cd "$PROJECT" && pwd)"
  if [[ "$PROJECT" == "$KIT_ROOT" ]]; then
    echo "Refusing to install project bits into the cursor-spells kit itself ($KIT_ROOT)." >&2
    echo "cd into your app or multi-repo workspace, or pass its path. Use --user-only for ~/.cursor only." >&2
    exit 1
  fi
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
    [[ -n "${PROJECT:-}" && ( -e "$PROJECT/.cursor/skills/english-humanizer" || -L "$PROJECT/.cursor/skills/english-humanizer" ) ]] && return 0
    return 1
  fi
  return 0
}

# Link/copy every kit skill, command, and agent into a Cursor root
# ($1 = ~/.cursor or <project>/.cursor).
sync_kit_entries_into() {
  local cursor_root="$1"
  mkdir -p "$cursor_root/skills" "$cursor_root/commands" "$cursor_root/agents"

  local src name
  for src in "$KIT_ROOT"/skills/*; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    want_skill "$name" || continue
    link_or_copy "$src" "$cursor_root/skills/$name"
  done

  for src in "$KIT_ROOT"/commands/*.md; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    link_or_copy "$src" "$cursor_root/commands/$name"
  done

  for src in "$KIT_ROOT"/agents/*.md; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    link_or_copy "$src" "$cursor_root/agents/$name"
  done

  printf '%s\n' "$KIT_ROOT" > "$cursor_root/cursor-spells-kit-path"
  echo "wrote: $cursor_root/cursor-spells-kit-path"
}

install_user_bits() {
  # shellcheck source=teach-review.sh
  source "$KIT_ROOT/scripts/teach-review.sh"
  tr_install_learn_config "$HOME/.cursor/cursor-spells-learn.json" \
    "$KIT_ROOT/skills/teach-review/references/cursor-spells-learn.json"
  echo "learn-config: $HOME/.cursor/cursor-spells-learn.json"
  sync_kit_entries_into "$HOME/.cursor"
  # Always-on chat language. Pipeline gate rules stay project-only.
  mkdir -p "$HOME/.cursor/rules"
  cp "$KIT_ROOT/rules/plain-language-chat.mdc" "$HOME/.cursor/rules/plain-language-chat.mdc"
  echo "copied: $HOME/.cursor/rules/plain-language-chat.mdc"
}

install_project_bits() {
  mkdir -p "$PROJECT/.cursor/hooks" "$PROJECT/.cursor/rules" "$PROJECT/.cursor"
  # shellcheck source=teach-review.sh
  source "$KIT_ROOT/scripts/teach-review.sh"
  tr_install_learn_config "$PROJECT/.cursor/cursor-spells-learn.json" \
    "$KIT_ROOT/skills/teach-review/references/cursor-spells-learn.json"
  echo "learn-config: $PROJECT/.cursor/cursor-spells-learn.json"

  # Mirror skills/commands/agents into the project so Cursor UI/CLI reliably lists them.
  # User-global ~/.cursor alone is easy to miss (and Cursor CLI only completes project agents).
  sync_kit_entries_into "$PROJECT/.cursor"

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
  for rule in after-plan-review-gate.mdc before-build-critique-gate.mdc clean-decision-docs.mdc hitl-askquestion.mdc plain-language-chat.mdc; do
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
  # Snippet helper for review evidence backfill (always refresh — small script)
  cp "$KIT_ROOT/scripts/extract-review-snippet.sh" "$PROJECT/scripts/extract-review-snippet.sh"
  chmod +x "$PROJECT/scripts/extract-review-snippet.sh"
  echo "copied: $PROJECT/scripts/extract-review-snippet.sh"
  # Report validator — reject Verdict/Blockers digests missing evidence
  cp "$KIT_ROOT/scripts/validate-review-report.sh" "$PROJECT/scripts/validate-review-report.sh"
  chmod +x "$PROJECT/scripts/validate-review-report.sh"
  echo "copied: $PROJECT/scripts/validate-review-report.sh"
  cp "$KIT_ROOT/scripts/pipeline-gates.sh" "$PROJECT/scripts/pipeline-gates.sh"
  chmod +x "$PROJECT/scripts/pipeline-gates.sh"
  echo "copied: $PROJECT/scripts/pipeline-gates.sh"
  cp "$KIT_ROOT/scripts/jira-issue.sh" "$PROJECT/scripts/jira-issue.sh"
  chmod +x "$PROJECT/scripts/jira-issue.sh"
  echo "copied: $PROJECT/scripts/jira-issue.sh"
}

echo "kit: $KIT_ROOT"
echo "mode: $MODE"

install_user_bits

if [[ "$USER_ONLY" -eq 0 && -n "$PROJECT" ]]; then
  install_project_bits
fi

echo "done."
if [[ -n "$PROJECT" && "$USER_ONLY" -eq 0 ]]; then
  echo "project: $PROJECT"
  echo "agents also in: $PROJECT/.cursor/agents/  (visible in this project’s Cursor UI/CLI)"
elif [[ "$USER_ONLY" -eq 1 ]]; then
  echo
  echo "NOTE: --user-only only links into ~/.cursor/agents|commands|skills."
  echo "  • In Cursor IDE: reload the window, then @engineer-reviewer / @pr-reviewer (subagents)."
  echo "  • Cursor CLI completions often list only <project>/.cursor/agents — run \`csp install\` from your app (no --user-only) for project-visible agents."
  echo "  • Check: ls -la ~/.cursor/agents"
fi
echo "next: open the project in Cursor → /start-task  /approve-plan  /pr-review  /engineer-review"
echo "tip: npx skills add vercel-labs/agent-skills@vercel-react-best-practices"
