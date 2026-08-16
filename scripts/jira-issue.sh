#!/usr/bin/env bash
# Jira key / site / issue-type helpers (sourceable library).
# Usage: source scripts/jira-issue.sh

jira_extract_key() {
  local input="$1" key=""
  if [[ "$input" =~ ([A-Za-z][A-Za-z0-9]+-[0-9]+) ]]; then
    key="${BASH_REMATCH[1]}"
    printf '%s' "${key^^}"
    return 0
  fi
  return 1
}

jira_extract_site() {
  local input="$1"
  if [[ "$input" =~ https?://([A-Za-z0-9.-]+\.atlassian\.net) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

jira_looks_like_issue() {
  local input="$1"
  [[ "$input" == *atlassian.net* ]] || [[ "$input" =~ ^[A-Za-z][A-Za-z0-9]+-[0-9]+$ ]]
}

jira_classify_type() {
  local raw="${1:-}" name
  name="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  case "$name" in
    bug|defect|fault|incident|problem|error)
      printf 'bug'
      ;;
    story|task|feature|"new feature"|epic|improvement|"change request")
      printf 'feature'
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}
