#!/bin/bash
# Install only this skill. Does not install/launch AER or modify shell profiles.
set -euo pipefail
source_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
destination="${CODEX_HOME:-$HOME/.codex}/skills/aer-browser"
selected_app=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    --app|--dest)
      [ "$#" -ge 2 ] || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
      if [ "$1" = --app ]; then selected_app=$2; else destination=$2; fi
      shift 2 ;;
    --help)
      printf '%s\n' 'Usage: bash install-codex.sh [--app /absolute/AER.app] [--dest /absolute/skills/aer-browser]'
      exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done
case "$destination" in /*/aer-browser) ;; *) printf 'Destination must be absolute and end in /aer-browser.\n' >&2; exit 2 ;; esac
if [ -n "$selected_app" ]; then
  case "$selected_app" in /*) ;; *) printf 'App path must be absolute.\n' >&2; exit 2 ;; esac
  AER_BROWSER_APP="$selected_app" bash "$source_dir/scripts/aer-browser.sh" skill >/dev/null
fi
if [ -L "$destination" ]; then
  printf 'Destination is a symlink; choose a separate --dest rather than replacing it.\n' >&2; exit 1
fi
if [ -e "$destination" ] && { [ ! -d "$destination" ] ||
    ! /usr/bin/grep -qx 'name: aer-browser' "$destination/SKILL.md"; }; then
  printf 'Destination is not an existing aer-browser skill; refusing to replace it.\n' >&2; exit 1
fi
parent=$(dirname -- "$destination")
mkdir -p "$parent"
staging=$(mktemp -d "$parent/.aer-browser-install.XXXXXX")
backup=''
cleanup() {
  [ ! -d "$staging" ] || rm -rf -- "$staging"
  if [ -n "$backup" ] && [ ! -e "$destination" ] && [ -d "$backup" ]; then mv -- "$backup" "$destination"; fi
}
trap cleanup EXIT
cp -R "$source_dir/." "$staging/"
if [ -n "$selected_app" ]; then
  printf '%s\n' "$selected_app" > "$staging/local-app-path"
elif [ -f "$destination/local-app-path" ]; then
  cp "$destination/local-app-path" "$staging/local-app-path"
fi
chmod +x "$staging/scripts/"*.sh
if [ -e "$destination" ]; then
  # Keep backups outside the skills discovery directory (no duplicate skill).
  backup_root="$parent/../skill-backups"
  mkdir -p "$backup_root"
  backup=$(mktemp -d "$backup_root/aer-browser.XXXXXX")
  rmdir "$backup"
  mv -- "$destination" "$backup"
fi
mv -- "$staging" "$destination"
printf 'Installed: %s\n' "$destination"
[ -z "$backup" ] || printf 'Previous version: %s\n' "$backup"
printf '%s\n' 'The skill will be available on your next Codex turn. Invoke it with $aer-browser.'
