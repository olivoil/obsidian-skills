#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_REPO="${1:-$PWD}"
RESET_CACHE="${2:-}"

OLD_CLAUDE_DIR="$TARGET_REPO/.claude"
NEW_CACHE_DIR="$TARGET_REPO/.cache/om"
NEW_INTERVALS_DIR="$NEW_CACHE_DIR/intervals-cache"
mkdir -p "$NEW_INTERVALS_DIR"

copy_file() {
  local src="$1"
  local dest="$2"
  if [[ ! -e "$src" ]]; then
    return
  fi
  if [[ -e "$dest" && "$RESET_CACHE" != "--reset-cache" ]]; then
    echo "keeping existing: $dest"
    return
  fi
  if [[ -e "$dest" && "$RESET_CACHE" == "--reset-cache" ]]; then
    rm -rf "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  echo "migrated: $src -> $dest"
}

for name in project-mappings.md github-mappings.md outlook-mappings.md slack-mappings.md freshbooks-mappings.md people-context.md; do
  copy_file "$OLD_CLAUDE_DIR/intervals-cache/$name" "$NEW_INTERVALS_DIR/$name"
done
copy_file "$OLD_CLAUDE_DIR/time-entries.db" "$NEW_CACHE_DIR/time-entries.db"
