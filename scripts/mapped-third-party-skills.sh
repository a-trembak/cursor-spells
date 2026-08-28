#!/usr/bin/env bash
# Parse skills/engineer-review/references/skill-map.md and install curated
# (Tier-1 / already-mapped) third-party skills via `npx skills add`.
#
# Source of truth is skill-map.md — do not hardcode owner/repo@skill ids here.
# Never vendor third-party skill bodies into cursor-spells.
# Failures are non-fatal (skill_missing style) so kit install still succeeds.
#
# Not for agents mid-review: only `csp install` / `csp update` / install-to-project.sh.

# When sourced, BASH_SOURCE is this file. When executed, same.
_MTP_SELF="${BASH_SOURCE[0]:-$0}"
MTP_KIT_ROOT="${KIT_ROOT:-$(cd "$(dirname "$_MTP_SELF")/.." && pwd)}"
MTP_SKILL_MAP="${MTP_SKILL_MAP:-$MTP_KIT_ROOT/skills/engineer-review/references/skill-map.md}"

mtp_extract_ids() {
  grep -oE '[A-Za-z0-9._-]+/[A-Za-z0-9._-]+@[A-Za-z0-9._-]+' | sort -u || true
}

# Recommended installs: first bash fence in skill-map.md.
mtp_recommended_ids() {
  awk '
    /^```bash$/ {on=1; next}
    on && /^```$/ {exit}
    on {print}
  ' "$MTP_SKILL_MAP" | mtp_extract_ids
}

# Always-on + current-stack Database skill routing. Stops at Conditional.
mtp_db_default_ids() {
  awk '
    /^## Database skill routing$/ {on=1}
    /^### Conditional/ {on=0}
    on {print}
  ' "$MTP_SKILL_MAP" | mtp_extract_ids
}

# Conditional Postgres / Flyway / Prisma rows — manual unless detected.
mtp_conditional_ids() {
  awk '
    /^### Conditional/ {on=1}
    on && /^## / {exit}
    on {print}
  ' "$MTP_SKILL_MAP" | mtp_extract_ids
}

mtp_project_has_signal() {
  local project="$1"
  local pattern="$2"
  local f d
  [[ -n "$project" && -d "$project" ]] || return 1
  for f in \
    "$project/package.json" \
    "$project/pom.xml" \
    "$project/build.gradle" \
    "$project/build.gradle.kts" \
    "$project/docker-compose.yml" \
    "$project/docker-compose.yaml"
  do
    [[ -f "$f" ]] || continue
    grep -Eiq "$pattern" "$f" && return 0
  done
  for f in "$project"/docker-compose*.yml "$project"/docker-compose*.yaml; do
    [[ -f "$f" ]] || continue
    grep -Eiq "$pattern" "$f" && return 0
  done
  # Shallow scan of common backend dirs (do not walk the whole tree).
  for d in "$project" "$project/src" "$project/app" "$project/backend"; do
    [[ -d "$d" ]] || continue
    if grep -Eilq "$pattern" "$d"/*.xml "$d"/*.gradle "$d"/*.kts "$d"/*.yml "$d"/*.yaml 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

mtp_detect_conditional_ids() {
  local project="${1:-}"
  local section
  [[ -n "$project" && -d "$project" ]] || return 0
  section="$(awk '
    /^### Conditional/ {on=1}
    on && /^## / {exit}
    on {print}
  ' "$MTP_SKILL_MAP")"
  if mtp_project_has_signal "$project" 'postgres|postgresql|"pg"'; then
    printf '%s\n' "$section" | grep -Ei 'postgres|postgresql|supabase' | mtp_extract_ids
  fi
  if mtp_project_has_signal "$project" 'flyway'; then
    printf '%s\n' "$section" | grep -Ei 'flyway' | mtp_extract_ids
  fi
  if [[ -f "$project/prisma/schema.prisma" ]] || mtp_project_has_signal "$project" 'prisma'; then
    printf '%s\n' "$section" | grep -Ei 'prisma' | mtp_extract_ids
  fi
  return 0
}

# Default install set: recommended bash ∪ Database always-on/current-stack
# ∪ detected conditional ids for this consumer project.
mtp_install_ids() {
  local project="${1:-}"
  {
    mtp_recommended_ids
    mtp_db_default_ids
    if [[ -n "$project" ]]; then
      mtp_detect_conditional_ids "$project"
    fi
  } | sort -u
}

mtp_npx_add() {
  local id="$1"
  local extra=(--yes --agent cursor --global)
  # Close stdin so a prompt cannot hang an unattended install.
  # Bound runtime so a stuck npx cannot brick kit install.
  if command -v timeout >/dev/null 2>&1; then
    timeout 60 npx --yes skills add "$id" "${extra[@]}" </dev/null
  else
    npx --yes skills add "$id" "${extra[@]}" </dev/null
  fi
}

# Human-launched installer only. Never called from engineer-review / software-developer.
mtp_install_curated() {
  local project="${1:-}"
  local id
  local failed=()

  if [[ "${CSP_SKIP_THIRD_PARTY_SKILLS:-}" == "1" || "${SKIP_THIRD_PARTY_SKILLS:-0}" == "1" ]]; then
    echo "skip third-party skills (--skip-third-party-skills or CSP_SKIP_THIRD_PARTY_SKILLS=1)"
    return 0
  fi

  if ! command -v npx >/dev/null 2>&1; then
    echo "warning: npx not found; skipping third-party skill install (skill_missing: all curated ids)" >&2
    return 0
  fi

  if [[ ! -f "$MTP_SKILL_MAP" ]]; then
    echo "warning: skill-map missing at $MTP_SKILL_MAP; skipping third-party skill install" >&2
    return 0
  fi

  echo "third-party skills from $MTP_SKILL_MAP"
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    echo "third-party skill: npx skills add $id"
    if mtp_npx_add "$id"; then
      echo "ok: $id"
    else
      echo "skill_missing: $id (npx failed)"
      failed+=("$id")
    fi
  done < <(mtp_install_ids "$project")

  if [[ ${#failed[@]} -gt 0 ]]; then
    echo "warning: third-party skill install failed for: ${failed[*]}" >&2
    echo "skill_missing: ${failed[*]}"
  fi
  return 0
}
