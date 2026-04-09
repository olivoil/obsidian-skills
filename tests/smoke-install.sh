#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
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

"$REPO_ROOT/install.sh" "$TARGET"

# installs
[[ -L "$TARGET/.agents/skills/refine-daily-note" ]]
[[ -L "$TARGET/.claude/skills/refine-daily-note" ]]
[[ -L "$TARGET/.agents/skills/topic-pulse" ]]
[[ -L "$TARGET/.claude/skills/topic-pulse" ]]
[[ -L "$TARGET/.agents/skills/discover-vault-entities" ]]
[[ -L "$TARGET/.claude/skills/discover-vault-entities" ]]
[[ -L "$TARGET/.agents/skills/write-vault-section" ]]
[[ -L "$TARGET/.claude/skills/write-vault-section" ]]

# migration
[[ -f "$TARGET/.cache/om/intervals-cache/project-mappings.md" ]]
grep -q 'migrated project mappings' "$TARGET/.cache/om/intervals-cache/project-mappings.md"
[[ -f "$TARGET/.cache/om/intervals-cache/github-mappings.md" ]]
grep -q 'migrated github mappings' "$TARGET/.cache/om/intervals-cache/github-mappings.md"
[[ -f "$TARGET/.cache/om/time-entries.db" ]]
grep -q 'sqlite-placeholder' "$TARGET/.cache/om/time-entries.db"

# seeded defaults
[[ -f "$TARGET/.cache/om/intervals-cache/freshbooks-mappings.md" ]]
[[ -f "$TARGET/.cache/om/intervals-cache/outlook-mappings.md" ]]

# docs/help contract
grep -q -- '--reset-cache' "$REPO_ROOT/install.sh"
grep -q 'overwrites installed skills only' "$REPO_ROOT/INSTALL.md"

echo "smoke install passed"
