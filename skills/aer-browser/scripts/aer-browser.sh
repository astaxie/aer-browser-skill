#!/bin/bash
# Locate the native AER CLI without changing PATH, app bundles, or browser data.
set -euo pipefail

skill_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
fail() { printf 'aer-browser: %s\n' "$1" >&2; exit 1; }

canonical_file() {
  local file=$1 link count=0
  while [ -L "$file" ]; do
    count=$((count + 1))
    [ "$count" -le 40 ] || return 1
    link=$(/usr/bin/readlink "$file") || return 1
    case "$link" in
      /*) file=$link ;;
      *) file="$(dirname -- "$file")/$link" ;;
    esac
  done
  [ -f "$file" ] && [ -x "$file" ] || return 1
  printf '%s/%s\n' "$(CDPATH= cd -- "$(dirname -- "$file")" && pwd -P)" "$(basename -- "$file")"
}

validate_cli() {
  local candidate contents
  candidate=$(canonical_file "$1") || return 1
  contents=$(dirname -- "$(dirname -- "$candidate")")
  [ "$(basename -- "$candidate")" = aer-browser ] || return 1
  [ -f "$contents/Resources/skills/aer-browser/SKILL.md" ] || return 1
  printf '%s\n' "$candidate"
}

cli=''
if [ -n "${AER_BROWSER_APP:-}" ]; then
  case "$AER_BROWSER_APP" in /*) ;; *) fail 'AER_BROWSER_APP must be an absolute AER.app path.' ;; esac
  cli=$(validate_cli "$AER_BROWSER_APP/Contents/MacOS/aer-browser") ||
    fail 'AER_BROWSER_APP does not contain a usable native CLI and bundled guide. See references/install.md.'
elif [ -f "$skill_dir/local-app-path" ]; then
  app_path=$(cat "$skill_dir/local-app-path")
  case "$app_path" in /*) ;; *) fail 'The saved app path is invalid; reinstall this skill with --app.' ;; esac
  cli=$(validate_cli "$app_path/Contents/MacOS/aer-browser") ||
    fail 'The configured AER app moved or is unavailable. Reinstall with --app; no other app was selected.'
else
  on_path=$(command -v aer-browser || true)
  if [ -n "$on_path" ]; then cli=$(validate_cli "$on_path") || cli=''; fi
  if [ -z "$cli" ]; then
    candidates=()
    for app_path in /Applications/AER.app "$HOME/Applications/AER.app"; do
      if candidate=$(validate_cli "$app_path/Contents/MacOS/aer-browser"); then
        if [ "${candidates[0]:-}" != "$candidate" ]; then candidates+=("$candidate"); fi
      fi
    done
    case "${#candidates[@]}" in
      0) fail 'AER was not found. Set AER_BROWSER_APP to its absolute .app path or read references/install.md.' ;;
      1) cli=${candidates[0]} ;;
      *) fail 'Multiple AER apps were found. Select one with AER_BROWSER_APP or install-codex.sh --app.' ;;
    esac
  fi
fi

if [ "${1:-}" = --resolve ]; then
  [ "$#" -eq 1 ] || fail '--resolve takes no additional arguments.'
  printf '%s\n' "$cli"
elif [ "${1:-}" = skill ]; then
  "$cli" "$@"
  printf '\n[aer-browser:skill] end of guide\n'
else
  exec "$cli" "$@"
fi
