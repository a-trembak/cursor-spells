#!/usr/bin/env bash
# Hash kit legal docs for install policy acceptance.
# Usage: csp-policy-hash.sh [--kit-root <path>]
# Prints: <sha256> (64 hex) of sorted PRIVACY/TERMS/DISCLAIMER/NOTICE bodies.
set -euo pipefail

KIT_ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kit-root)
      KIT_ROOT="${2:-}"
      shift 2
      ;;
    *)
      echo "usage: csp-policy-hash.sh [--kit-root <path>]" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$KIT_ROOT" ]]; then
  KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

LEGAL="$KIT_ROOT/docs/legal"
for f in PRIVACY.md TERMS.md DISCLAIMER.md NOTICE.md; do
  if [[ ! -f "$LEGAL/$f" ]]; then
    echo "csp-policy-hash: missing $LEGAL/$f" >&2
    exit 1
  fi
done

# Stable hash across machines: concatenate files in fixed order.
if command -v sha256sum >/dev/null 2>&1; then
  cat "$LEGAL/PRIVACY.md" "$LEGAL/TERMS.md" "$LEGAL/DISCLAIMER.md" "$LEGAL/NOTICE.md" | sha256sum | awk '{print $1}'
elif command -v shasum >/dev/null 2>&1; then
  cat "$LEGAL/PRIVACY.md" "$LEGAL/TERMS.md" "$LEGAL/DISCLAIMER.md" "$LEGAL/NOTICE.md" | shasum -a 256 | awk '{print $1}'
else
  echo "csp-policy-hash: need sha256sum or shasum" >&2
  exit 1
fi
