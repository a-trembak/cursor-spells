#!/usr/bin/env bash
# Install cursor-spells into a consumer project's .cursor/ (default),
# or into ~/.cursor with --user-only.
# Prefer: bin/cursor-spells install <project>
#
# Usage:
#   ./scripts/install-to-project.sh /path/to/consumer-repo
#   ./scripts/install-to-project.sh . --humanizer
#   ./scripts/install-to-project.sh --user-only
#
# Default with a project path: symlink skills/commands/agents into
# <project>/.cursor/, and copy hooks + rule + patterns check there too.

set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT=""
USER_SKILLS=0
USER_ONLY=0
WITH_HOOKS=0
WITH_RULE=0
WITH_HUMANIZER=0
COPY_MODE=0

usage() {
  cat <<'EOF'
Install cursor-spells engineer-review workflow.

Usage:
  install-to-project.sh [project-path] [flags]
  install-to-project.sh --user-only [flags]

Default project path is the current directory (.).

Flags:
  --user-only      Only install into ~/.cursor (global; no project files)
  --user-skills    (noop alias; kept for compatibility)
  --humanizer      Also install english-humanizer
  --copy           Copy into the Cursor dest instead of symlink
  --hooks          Include hooks (default with project path)
  --rule           Include rule (default with project path)
  --no-hooks       Skip hooks even for project install
  --no-rule        Skip rule even for project install
  -h, --help       Show help

Keep one clone of cursor-spells; run this against each app. Do not vendor the
kit inside every repository.
EOF
  exit "${1:-0}"
}

SKIP_HOOKS=0
SKIP_RULE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --user-only|--global) USER_ONLY=1; USER_SKILLS=1; shift ;;
    --user-skills) USER_SKILLS=1; shift ;;
    --hooks) WITH_HOOKS=1; shift ;;
    --rule) WITH_RULE=1; shift ;;
    --no-hooks) SKIP_HOOKS=1; shift ;;
    --no-rule) SKIP_RULE=1; shift ;;
    --humanizer) WITH_HUMANIZER=1; shift ;;
    --copy) COPY_MODE=1; shift ;;
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

# Project install defaults to the directory where the command is run.
if [[ "$USER_ONLY" -eq 0 && -z "$PROJECT" ]]; then
  PROJECT="."
fi

if [[ -n "$PROJECT" ]]; then
  if [[ ! -d "$PROJECT" ]]; then
    echo "Project path does not exist: $PROJECT" >&2
    exit 1
  fi
  PROJECT="$(cd "$PROJECT" && pwd)"
fi

link_or_copy() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "skip (exists): $dest"
    return 0
  fi
  if [[ "$COPY_MODE" -eq 1 ]]; then
    cp -R "$src" "$dest"
    echo "copied: $dest"
  else
    ln -s "$src" "$dest"
    echo "linked: $dest -> $src"
  fi
}

# Install skills/commands/agents under DEST_CURSOR (…/.cursor).
install_cursor_bits() {
  local dest_cursor="$1"
  mkdir -p "$dest_cursor/skills" "$dest_cursor/commands" "$dest_cursor/agents"
  link_or_copy "$KIT_ROOT/skills/engineer-review" "$dest_cursor/skills/engineer-review"
  link_or_copy "$KIT_ROOT/skills/finish-plan" "$dest_cursor/skills/finish-plan"
  link_or_copy "$KIT_ROOT/commands/engineer-review.md" "$dest_cursor/commands/engineer-review.md"
  link_or_copy "$KIT_ROOT/commands/finish-plan.md" "$dest_cursor/commands/finish-plan.md"
  link_or_copy "$KIT_ROOT/commands/multi-review.md" "$dest_cursor/commands/multi-review.md"
  link_or_copy "$KIT_ROOT/agents/engineer-reviewer.md" "$dest_cursor/agents/engineer-reviewer.md"
  link_or_copy "$KIT_ROOT/agents/multi-repo-supervisor.md" "$dest_cursor/agents/multi-repo-supervisor.md"
  local f
  for f in "$KIT_ROOT"/agents/review-*.md; do
    link_or_copy "$f" "$dest_cursor/agents/$(basename "$f")"
  done
  if [[ "$WITH_HUMANIZER" -eq 1 ]]; then
    link_or_copy "$KIT_ROOT/skills/english-humanizer" "$dest_cursor/skills/english-humanizer"
  fi
}

install_project_bits() {
  local dest_cursor="$PROJECT/.cursor"
  mkdir -p "$dest_cursor/hooks" "$dest_cursor/rules" "$dest_cursor/scripts"
  if [[ "$WITH_HOOKS" -eq 1 ]]; then
    if [[ ! -f "$dest_cursor/hooks.json" ]]; then
      cp "$KIT_ROOT/hooks/hooks.json" "$dest_cursor/hooks.json"
      echo "copied: $dest_cursor/hooks.json"
    else
      echo "skip (exists): $dest_cursor/hooks.json (merge stop hook manually if needed)"
    fi
    cp "$KIT_ROOT/hooks/post-plan-review-gate.sh" "$dest_cursor/hooks/post-plan-review-gate.sh"
    chmod +x "$dest_cursor/hooks/post-plan-review-gate.sh"
    echo "copied: $dest_cursor/hooks/post-plan-review-gate.sh"
  fi
  if [[ "$WITH_RULE" -eq 1 ]]; then
    # Project-scoped rule (safe). Do NOT alwaysApply at user-global level.
    cp "$KIT_ROOT/rules/after-plan-review-gate.mdc" "$dest_cursor/rules/after-plan-review-gate.mdc"
    echo "copied: $dest_cursor/rules/after-plan-review-gate.mdc"
  fi
  # Optional CI helper — keep under .cursor so project root stays clean
  if [[ ! -f "$dest_cursor/scripts/check-project-patterns.sh" ]]; then
    cp "$KIT_ROOT/scripts/check-project-patterns.sh" "$dest_cursor/scripts/check-project-patterns.sh"
    chmod +x "$dest_cursor/scripts/check-project-patterns.sh"
    echo "copied: $dest_cursor/scripts/check-project-patterns.sh"
  fi
}

echo "kit: $KIT_ROOT"
if [[ "$USER_ONLY" -eq 1 ]]; then
  install_cursor_bits "$HOME/.cursor"
elif [[ -n "$PROJECT" ]]; then
  # Default: everything for this app lives under <project>/.cursor/
  if [[ "$SKIP_HOOKS" -eq 0 ]]; then WITH_HOOKS=1; else WITH_HOOKS=0; fi
  if [[ "$SKIP_RULE" -eq 0 ]]; then WITH_RULE=1; else WITH_RULE=0; fi
  install_cursor_bits "$PROJECT/.cursor"
  install_project_bits
fi

echo "done."
if [[ -n "$PROJECT" && "$USER_ONLY" -eq 0 ]]; then
  echo "project: $PROJECT"
  echo "cursor:  $PROJECT/.cursor"
  echo "next: open the project in Cursor → /finish-plan after plans, /engineer-review anytime"
elif [[ "$USER_ONLY" -eq 1 ]]; then
  echo "cursor:  $HOME/.cursor (user-global)"
fi
echo "tip: npx skills add vercel-labs/agent-skills@vercel-react-best-practices"
