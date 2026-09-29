#!/usr/bin/env bash
# Pipeline chat language preference for consumer projects.
# Usage:
#   csp-pipeline-language.sh get --root <project>
#   csp-pipeline-language.sh set --root <project> --lang <code>
#   csp-pipeline-language.sh validate <code>
#   csp-pipeline-language.sh normalize <code>
#   csp-pipeline-language.sh is-banned <code>
#
# Marker file: <project>/.cursor/csp-pipeline-language (one line).
# Default when unset/empty: en
# Russian (ru / russian / русский / …) is always rejected — sanctions policy.
set -euo pipefail

csp_pl__usage() {
  cat <<'EOF' >&2
Usage:
  csp-pipeline-language.sh get --root <project>
  csp-pipeline-language.sh set --root <project> --lang <code>
  csp-pipeline-language.sh validate <code>
  csp-pipeline-language.sh normalize <code>
  csp-pipeline-language.sh is-banned <code>
EOF
}

# Lowercase trim; map common aliases.
csp_pl__normalize() {
  local raw="${1:-}"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  case "$raw" in
    "" ) printf '%s\n' "en"; return 0 ;;
    english|en-us|en-gb|en_us|en_gb) printf '%s\n' "en"; return 0 ;;
    ukrainian|ua|uk-ua|uk_ua) printf '%s\n' "uk"; return 0 ;;
    german|de-de|de_de) printf '%s\n' "de"; return 0 ;;
    french|fr-fr|fr_fr) printf '%s\n' "fr"; return 0 ;;
    spanish|es-es|es_es|es-mx|es_mx) printf '%s\n' "es"; return 0 ;;
    portuguese|pt-pt|pt_pt|pt-br|pt_br) printf '%s\n' "pt"; return 0 ;;
    polish|pl-pl|pl_pl) printf '%s\n' "pl"; return 0 ;;
    italian|it-it|it_it) printf '%s\n' "it"; return 0 ;;
    dutch|nl-nl|nl_nl) printf '%s\n' "nl"; return 0 ;;
    swedish|sv-se|sv_se) printf '%s\n' "sv"; return 0 ;;
    norwegian|no-no|no_no|nb|nn) printf '%s\n' "no"; return 0 ;;
    danish|da-dk|da_dk) printf '%s\n' "da"; return 0 ;;
    finnish|fi-fi|fi_fi) printf '%s\n' "fi"; return 0 ;;
    czech|cs-cz|cs_cz) printf '%s\n' "cs"; return 0 ;;
    slovak|sk-sk|sk_sk) printf '%s\n' "sk"; return 0 ;;
    hungarian|hu-hu|hu_hu) printf '%s\n' "hu"; return 0 ;;
    romanian|ro-ro|ro_ro) printf '%s\n' "ro"; return 0 ;;
    bulgarian|bg-bg|bg_bg) printf '%s\n' "bg"; return 0 ;;
    croatian|hr-hr|hr_hr) printf '%s\n' "hr"; return 0 ;;
    serbian|sr-rs|sr_rs) printf '%s\n' "sr"; return 0 ;;
    turkish|tr-tr|tr_tr) printf '%s\n' "tr"; return 0 ;;
    greek|el-gr|el_gr) printf '%s\n' "el"; return 0 ;;
    hebrew|he-il|he_il|iw) printf '%s\n' "he"; return 0 ;;
    arabic|ar-sa|ar_sa|ar-ae|ar_ae) printf '%s\n' "ar"; return 0 ;;
    japanese|ja-jp|ja_jp) printf '%s\n' "ja"; return 0 ;;
    korean|ko-kr|ko_kr) printf '%s\n' "ko"; return 0 ;;
    chinese|zh-cn|zh_cn|zh-tw|zh_tw|zh-hans|zh-hant) printf '%s\n' "zh"; return 0 ;;
    vietnamese|vi-vn|vi_vn) printf '%s\n' "vi"; return 0 ;;
    thai|th-th|th_th) printf '%s\n' "th"; return 0 ;;
    indonesian|id-id|id_id) printf '%s\n' "id"; return 0 ;;
    malay|ms-my|ms_my) printf '%s\n' "ms"; return 0 ;;
    hindi|hi-in|hi_in) printf '%s\n' "hi"; return 0 ;;
    russian|ru-ru|ru_ru) printf '%s\n' "ru"; return 0 ;;
  esac
  # Cyrillic / mixed aliases for Russian (sanctions ban) — match without relying on locale
  if printf '%s' "$raw" | grep -Eiq -- '^(русский|русскій|русскийязык|russkiy|russkij)$'; then
    printf '%s\n' "ru"
    return 0
  fi
  # other:<tag> → keep as other:<normalized-tag>
  if [[ "$raw" =~ ^other:(.+)$ ]]; then
    local tag="${BASH_REMATCH[1]}"
    tag="$(printf '%s' "$tag" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9_-]//g')"
    if [[ -z "$tag" || "$tag" == "ru" || "$tag" == "russian" ]]; then
      printf '%s\n' "ru"
      return 0
    fi
    printf 'other:%s\n' "$tag"
    return 0
  fi
  # Strip region: xx-YY → xx (but keep other:)
  if [[ "$raw" =~ ^([a-z]{2,3})([-_][a-z0-9]+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  printf '%s\n' "$raw"
}

csp_pl__is_banned() {
  local code
  code="$(csp_pl__normalize "$1")"
  case "$code" in
    ru|ru-*|russian)
      return 0
      ;;
    other:ru|other:russian)
      return 0
      ;;
  esac
  # Any code whose primary subtag is ru
  if [[ "$code" =~ ^ru([-_]|$) ]]; then
    return 0
  fi
  return 1
}

# Documented open set: common ISO-ish codes + other:<tag>. Empty → en.
csp_pl__is_allowed_shape() {
  local code="$1"
  [[ "$code" =~ ^[a-z]{2,3}$ ]] && return 0
  [[ "$code" =~ ^other:[a-z0-9][a-z0-9_-]{0,31}$ ]] && return 0
  return 1
}

csp_pl__validate() {
  local code
  code="$(csp_pl__normalize "$1")"
  if csp_pl__is_banned "$code"; then
    echo "csp-pipeline-language: Russian (ru) is forbidden by sanctions policy of this project/kit" >&2
    return 1
  fi
  if ! csp_pl__is_allowed_shape "$code"; then
    echo "csp-pipeline-language: invalid language code: $1 (normalized: $code)" >&2
    return 1
  fi
  printf '%s\n' "$code"
  return 0
}

csp_pl__marker_path() {
  local root="$1"
  printf '%s\n' "$root/.cursor/csp-pipeline-language"
}

csp_pl__get() {
  local root="$1"
  local path content code
  path="$(csp_pl__marker_path "$root")"
  if [[ ! -f "$path" ]]; then
    printf '%s\n' "en"
    return 0
  fi
  content="$(head -n 1 "$path" 2>/dev/null || true)"
  content="$(printf '%s' "$content" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [[ -z "$content" ]]; then
    printf '%s\n' "en"
    return 0
  fi
  # Absolute lockout: banned on-disk values (e.g. hand-edited ru) coerce to en.
  if csp_pl__is_banned "$content"; then
    echo "csp-pipeline-language: Russian is impossible in this pipeline (sanctions-based language policy); recommending Russian only outside this pipeline; resetting marker to en" >&2
    mkdir -p "$root/.cursor"
    printf '%s\n' "en" > "$path"
    printf '%s\n' "en"
    return 0
  fi
  if ! code="$(csp_pl__validate "$content")"; then
    return 1
  fi
  printf '%s\n' "$code"
}

csp_pl__set() {
  local root="$1"
  local lang="$2"
  local code path
  code="$(csp_pl__validate "$lang")" || return 1
  mkdir -p "$root/.cursor"
  path="$(csp_pl__marker_path "$root")"
  printf '%s\n' "$code" > "$path"
  printf '%s\n' "$code"
}

# --- main ---
if [[ $# -lt 1 ]]; then
  csp_pl__usage
  exit 2
fi

cmd="$1"
shift

ROOT=""
LANG_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --lang)
      LANG_ARG="${2:-}"
      shift 2
      ;;
    -*)
      echo "csp-pipeline-language: unknown flag: $1" >&2
      csp_pl__usage
      exit 2
      ;;
    *)
      # positional for validate / normalize / is-banned
      if [[ -z "$LANG_ARG" ]]; then
        LANG_ARG="$1"
      fi
      shift
      ;;
  esac
done

case "$cmd" in
  get)
    if [[ -z "$ROOT" ]]; then
      echo "csp-pipeline-language: get requires --root" >&2
      exit 2
    fi
    csp_pl__get "$ROOT"
    ;;
  set)
    if [[ -z "$ROOT" || -z "$LANG_ARG" ]]; then
      echo "csp-pipeline-language: set requires --root and --lang" >&2
      exit 2
    fi
    csp_pl__set "$ROOT" "$LANG_ARG"
    ;;
  validate)
    if [[ -z "$LANG_ARG" ]]; then
      echo "csp-pipeline-language: validate requires a code" >&2
      exit 2
    fi
    csp_pl__validate "$LANG_ARG" >/dev/null
    ;;
  normalize)
    if [[ -z "$LANG_ARG" ]]; then
      echo "csp-pipeline-language: normalize requires a code" >&2
      exit 2
    fi
    csp_pl__normalize "$LANG_ARG"
    ;;
  is-banned)
    if [[ -z "$LANG_ARG" ]]; then
      echo "csp-pipeline-language: is-banned requires a code" >&2
      exit 2
    fi
    if csp_pl__is_banned "$LANG_ARG"; then
      echo "banned"
      exit 0
    fi
    echo "allowed"
    exit 1
    ;;
  *)
    echo "csp-pipeline-language: unknown command: $cmd" >&2
    csp_pl__usage
    exit 2
    ;;
esac
