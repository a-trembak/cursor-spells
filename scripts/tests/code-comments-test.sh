#!/usr/bin/env bash
# Contract: service / backend comments must not cite the user interface
# (links, examples, screen/chart/widget/Figma). React / frontend UI sources
# may. Canonical taxonomy lives in code-comments; developer and bug-fix
# agents must mirror the stack split; deadcode and eligibility enforce it
# only on service / backend / non-UI paths.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fail=0

assert_file() {
  local path="$1"
  if [[ ! -f "$ROOT/$path" ]]; then
    echo "FAIL missing file: $path" >&2
    fail=1
  else
    echo "OK   file $path"
  fi
}

assert_grep() {
  local name="$1" path="$2" pattern="$3"
  if grep -E -q "$pattern" "$ROOT/$path"; then
    echo "OK   $name"
  else
    echo "FAIL $name: /$pattern/ not in $path" >&2
    fail=1
  fi
}

assert_file "skills/code-comments/SKILL.md"
assert_file "skills/software-developer/SKILL.md"
assert_file "agents/csp-software-developer.md"
assert_file "skills/bug-fix/SKILL.md"
assert_file "agents/csp-bug-fixer.md"
assert_file "agents/csp-review-deadcode.md"
assert_file "skills/engineer-review/references/auto-fix-eligibility.md"
assert_file "README.md"

# Taxonomy: service forbid + React allow + audience + invariant keep.
assert_grep taxonomy_remove_heading "skills/code-comments/SKILL.md" "^## Remove / never write$"
assert_grep taxonomy_chart "skills/code-comments/SKILL.md" "chart"
assert_grep taxonomy_presentation "skills/code-comments/SKILL.md" "screen|widget|Figma"
assert_grep taxonomy_backend "skills/code-comments/SKILL.md" "backend"
assert_grep taxonomy_invariant "skills/code-comments/SKILL.md" "invariant"
assert_grep taxonomy_keep_why "skills/code-comments/SKILL.md" "Why / invariant"
assert_grep taxonomy_service_forbid_links "skills/code-comments/SKILL.md" "user-interface link|user interface link|UI link"
assert_grep taxonomy_service_forbid_examples "skills/code-comments/SKILL.md" "user-interface example|user interface example|UI example"
assert_grep taxonomy_react_allow "skills/code-comments/SKILL.md" "React.*(allow|may)|frontend.*(allow|may)|may.*(screen|widget|Figma|user.interface)"
assert_grep taxonomy_audience_java "skills/code-comments/SKILL.md" "Java"
assert_grep taxonomy_audience_service_bi "skills/code-comments/SKILL.md" "Service BI"
assert_grep taxonomy_audience_manager "skills/code-comments/SKILL.md" "manager-developer"

# software-developer: services forbid presentation; React UI may reference it.
assert_grep dev_skill_backend "skills/software-developer/SKILL.md" "backend"
assert_grep dev_skill_chart_comment "skills/software-developer/SKILL.md" "chart"
assert_grep dev_skill_loads_comments "skills/software-developer/SKILL.md" "code-comments"
assert_grep dev_skill_service_forbid "skills/software-developer/SKILL.md" "service.*(forbid|must not)|backend.*(forbid|must not)|services forbid"
assert_grep dev_skill_react_allow "skills/software-developer/SKILL.md" "React.*(may|allow)|frontend.*(may|allow)"
assert_grep dev_agent_backend "agents/csp-software-developer.md" "backend"
assert_grep dev_agent_chart_comment "agents/csp-software-developer.md" "chart"
assert_grep dev_agent_loads_comments "agents/csp-software-developer.md" "code-comments"
assert_grep dev_agent_service_forbid "agents/csp-software-developer.md" "service.*(forbid|must not)|backend.*(forbid|must not)|services forbid"
assert_grep dev_agent_react_allow "agents/csp-software-developer.md" "React.*(may|allow)|frontend.*(may|allow)"

# bug-fix / bug-fixer: same stack-split mirror.
assert_grep bugfix_loads_comments "skills/bug-fix/SKILL.md" "code-comments"
assert_grep bugfix_service_forbid "skills/bug-fix/SKILL.md" "service.*(forbid|must not)|backend.*(forbid|must not)|services forbid"
assert_grep bugfix_react_allow "skills/bug-fix/SKILL.md" "React.*(may|allow)|frontend.*(may|allow)"
assert_grep bugfixer_loads_comments "agents/csp-bug-fixer.md" "code-comments"
assert_grep bugfixer_service_forbid "agents/csp-bug-fixer.md" "service.*(forbid|must not)|backend.*(forbid|must not)|services forbid"
assert_grep bugfixer_react_allow "agents/csp-bug-fixer.md" "React.*(may|allow)|frontend.*(may|allow)"

# Review: classify presentation comments as Remove only on service/backend/non-UI;
# do not flag React UI presentation nouns as this-policy violations.
assert_grep deadcode_taxonomy "agents/csp-review-deadcode.md" "skills/code-comments/SKILL.md"
assert_grep deadcode_presentation "agents/csp-review-deadcode.md" "chart|screen|widget|Figma"
assert_grep deadcode_service_scope "agents/csp-review-deadcode.md" "service|backend|non-UI|java-spring"
assert_grep deadcode_react_exclude "agents/csp-review-deadcode.md" "react-web|react-native|React UI|frontend UI"

# Eligibility Yes row scoped to service / backend comments (not frontend UI).
assert_grep eligibility_mixed_clarify "skills/engineer-review/references/auto-fix-eligibility.md" "chart"
assert_grep eligibility_service_scope "skills/engineer-review/references/auto-fix-eligibility.md" "service|backend"

# README: services-forbid / React-allow (not «including backend» alone).
assert_grep readme_code_comments "README.md" "code-comments"
assert_grep readme_service_forbid "README.md" "service.*(forbid|must not)|services forbid|forbid.*service"
assert_grep readme_react_allow "README.md" "React.*(allow|may)|frontend.*(allow|may)"

if [[ "$fail" -ne 0 ]]; then
  echo "SOME TESTS FAILED" >&2
  exit 1
fi
echo "ALL PASS"
