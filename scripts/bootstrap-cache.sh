#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_REPO="${1:-$PWD}"
FORCE="${2:-}"

CACHE_DIR="$TARGET_REPO/.cache/om"
INTERVALS_DIR="$CACHE_DIR/intervals-cache"
TEMPLATE_DIR="$REPO_ROOT/templates/cache/om/intervals-cache"
mkdir -p "$INTERVALS_DIR"

if [[ -d "$TARGET_REPO/.claude/intervals-cache" || -f "$TARGET_REPO/.claude/time-entries.db" ]]; then
  "$REPO_ROOT/scripts/migrate-state.sh" "$TARGET_REPO" "$FORCE"
fi

for template in "$TEMPLATE_DIR"/*.md; do
  [[ -f "$template" ]] || continue
  dest="$INTERVALS_DIR/$(basename "$template")"
  if [[ -e "$dest" && "$FORCE" != "--force" ]]; then
    echo "seed exists: $dest"
    continue
  fi
  if [[ -e "$dest" && "$FORCE" == "--force" ]]; then
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
  fi
  cp "$template" "$dest"
  echo "seeded: $dest"
done

if [[ ! -e "$CACHE_DIR/time-entries.db" ]]; then
  : > "$CACHE_DIR/time-entries.db"
  echo "created: $CACHE_DIR/time-entries.db"
fi
