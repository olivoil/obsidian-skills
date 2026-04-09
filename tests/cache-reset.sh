#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARGET="$TMPDIR/vault"

mkdir -p "$TARGET/.cache/om/intervals-cache"

cat > "$TARGET/.cache/om/intervals-cache/project-mappings.md" <<'EOF_MAP'
CUSTOM PROJECT MAP
EOF_MAP

cat > "$TARGET/.cache/om/intervals-cache/github-mappings.md" <<'EOF_MAP'
CUSTOM GITHUB MAP
EOF_MAP

"$REPO_ROOT/install.sh" "$TARGET" --bootstrap-only --force

grep -q 'CUSTOM PROJECT MAP' "$TARGET/.cache/om/intervals-cache/project-mappings.md"
grep -q 'CUSTOM GITHUB MAP' "$TARGET/.cache/om/intervals-cache/github-mappings.md"

"$REPO_ROOT/install.sh" "$TARGET" --bootstrap-only --reset-cache

grep -q '# Project Mappings' "$TARGET/.cache/om/intervals-cache/project-mappings.md"
grep -q '# GitHub Repository Mappings' "$TARGET/.cache/om/intervals-cache/github-mappings.md"

echo "cache reset semantics passed"
