#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/obsidian/setup-obsidian-skills"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARGET="$TMPDIR/vault"

mkdir -p "$TARGET/.claude/intervals-cache"
cat > "$TARGET/.claude/intervals-cache/project-mappings.md" <<'MAP'
# migrated project mappings
MAP
cat > "$TARGET/.claude/intervals-cache/github-mappings.md" <<'MAP'
# migrated github mappings
MAP
printf 'sqlite-placeholder' > "$TARGET/.claude/time-entries.db"

bash "$SKILL_DIR/scripts/bootstrap-cache.sh" "$TARGET"

[[ -f "$TARGET/.cache/om/intervals-cache/project-mappings.md" ]]
grep -q 'migrated project mappings' "$TARGET/.cache/om/intervals-cache/project-mappings.md"
[[ -f "$TARGET/.cache/om/intervals-cache/github-mappings.md" ]]
grep -q 'migrated github mappings' "$TARGET/.cache/om/intervals-cache/github-mappings.md"
[[ -f "$TARGET/.cache/om/time-entries.db" ]]
grep -q 'sqlite-placeholder' "$TARGET/.cache/om/time-entries.db"

[[ -f "$TARGET/.cache/om/intervals-cache/freshbooks-mappings.md" ]]
[[ -f "$TARGET/.cache/om/intervals-cache/outlook-mappings.md" ]]
[[ -f "$TARGET/.cache/om/intervals-cache/worktype-mappings.md" ]]

cat > "$TARGET/.cache/om/intervals-cache/project-mappings.md" <<'CUSTOM'
CUSTOM PROJECT MAP
CUSTOM
bash "$SKILL_DIR/scripts/bootstrap-cache.sh" "$TARGET"
grep -q 'CUSTOM PROJECT MAP' "$TARGET/.cache/om/intervals-cache/project-mappings.md"

bash "$SKILL_DIR/scripts/bootstrap-cache.sh" "$TARGET" --reset-cache
grep -q '# Project Mappings' "$TARGET/.cache/om/intervals-cache/project-mappings.md"

bash -n "$SKILL_DIR/scripts/bootstrap-cache.sh" "$SKILL_DIR/scripts/migrate-state.sh"

echo "setup obsidian skills passed"
