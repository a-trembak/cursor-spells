#!/usr/bin/env bash
# Install cursor-spells into Cursor (~/.cursor) and optionally a consumer project.
# Prefer: bin/cursor-spells install <project>
#
# Usage:
#   ./scripts/install-to-project.sh /path/to/consumer-repo
#   ./scripts/install-to-project.sh . --humanizer
#   ./scripts/install-to-project.sh --user-only
#
# Default with a project path: symlink skills/commands/agents into ~/.cursor,
# copy hooks + rule + patterns check into the project.

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
  install-to-project.sh <project-path> [flags]
  install-to-project.sh --user-only [flags]

Flags:
  --user-only      Only install into ~/.cursor
  --user-skills    (noop alias; user bits always install with a project)
  --humanizer      Also install english-humanizer
  --copy           Copy into ~/.cursor instead of symlink
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

if [[ "$USER_ONLY" -eq 0 && -z "$PROJECT" ]]; then
  echo "Provide a consumer project path, or --user-only" >&2
  usage 1
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

install_user_bits() {
  mkdir -p "$HOME/.cursor/skills" "$HOME/.cursor/commands" "$HOME/.cursor/agents"
  link_or_copy "$KIT_ROOT/skills/engineer-review" "$HOME/.cursor/skills/engineer-review"
  link_or_copy "$KIT_ROOT/skills/finish-plan" "$HOME/.cursor/skills/finish-plan"
  # Short slash commands (preferred)
  link_or_copy "$KIT_ROOT/commands/review.md" "$HOME/.cursor/commands/review.md"
  link_or_copy "$KIT_ROOT/commands/done.md" "$HOME/.cursor/commands/done.md"
  # Long aliases
  link_or_copy "$KIT_ROOT/commands/engineer-review.md" "$HOME/.cursor/commands/engineer-review.md"
  link_or_copy "$KIT_ROOT/commands/finish-plan.md" "$HOME/.cursor/commands/finish-plan.md"
  link_or_copy "$KIT_ROOT/agents/engineer-reviewer.md" "$HOME/.cursor/agents/engineer-reviewer.md"
  local f
  for f in "$KIT_ROOT"/agents/review-*.md; do
    link_or_copy "$f" "$HOME/.cursor/agents/$(basename "$f")"
  done
  if [[ "$WITH_HUMANIZER" -eq 1 ]]; then
    link_or_copy "$KIT_ROOT/skills/english-humanizer" "$HOME/.cursor/skills/english-humanizer"
  fi
}

install_project_bits() {
  mkdir -p "$PROJECT/.cursor/hooks" "$PROJECT/.cursor/rules" "$PROJECT/.cursor"
  if [[ "$WITH_HOOKS" -eq 1 ]]; then
    if [[ ! -f "$PROJECT/.cursor/hooks.json" ]]; then
      cp "$KIT_ROOT/hooks/hooks.json" "$PROJECT/.cursor/hooks.json"
      echo "copied: $PROJECT/.cursor/hooks.json"
    else
      echo "skip (exists): $PROJECT/.cursor/hooks.json (merge stop hook manually if needed)"
    fi
    cp "$KIT_ROOT/hooks/post-plan-review-gate.sh" "$PROJECT/.cursor/hooks/post-plan-review-gate.sh"
    chmod +x "$PROJECT/.cursor/hooks/post-plan-review-gate.sh"
    echo "copied: $PROJECT/.cursor/hooks/post-plan-review-gate.sh"
  fi
  if [[ "$WITH_RULE" -eq 1 ]]; then
    # Project-scoped rule (safe). Do NOT alwaysApply at user-global level.
    cp "$KIT_ROOT/rules/after-plan-review-gate.mdc" "$PROJECT/.cursor/rules/after-plan-review-gate.mdc"
    echo "copied: $PROJECT/.cursor/rules/after-plan-review-gate.mdc"
  fi
  # Optional CI helper
  mkdir -p "$PROJECT/scripts"
  if [[ ! -f "$PROJECT/scripts/check-project-patterns.sh" ]]; then
    cp "$KIT_ROOT/scripts/check-project-patterns.sh" "$PROJECT/scripts/check-project-patterns.sh"
    chmod +x "$PROJECT/scripts/check-project-patterns.sh"
    echo "copied: $PROJECT/scripts/check-project-patterns.sh"
  fi
}

echo "kit: $KIT_ROOT"
if [[ "$USER_SKILLS" -eq 1 || "$USER_ONLY" -eq 1 || -n "$PROJECT" ]]; then
  # Always install user skills/agents when targeting a project (needed for /commands)
  install_user_bits
fi
if [[ "$USER_ONLY" -eq 0 && -n "$PROJECT" ]]; then
  # Default project install includes hooks + rule for HITL reliability
  if [[ "$SKIP_HOOKS" -eq 0 ]]; then WITH_HOOKS=1; else WITH_HOOKS=0; fi
  if [[ "$SKIP_RULE" -eq 0 ]]; then WITH_RULE=1; else WITH_RULE=0; fi
  install_project_bits
fi

echo "done."
if [[ -n "$PROJECT" ]]; then
  echo "project: $PROJECT"
  echo "next: open the project in Cursor → /done after plans, /review anytime"
fi
echo "tip: npx skills add vercel-labs/agent-skills@vercel-react-best-practices"
