#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARGET="$TMPDIR/vault-copy"
TARGET_SYMLINK="$TMPDIR/vault-symlink"

mkdir -p "$TARGET"

"$REPO_ROOT/install.sh" "$TARGET" --copy

MANIFEST="$TARGET/.cache/om/install-state/skills.json"
[[ -f "$MANIFEST" ]]

SKILL="$TARGET/.agents/skills/intervals-time-entry/SKILL.md"
echo '# local edit' >> "$SKILL"

set +e
OUTPUT=$("$REPO_ROOT/install.sh" "$TARGET" --copy 2>&1)
STATUS=$?
set -e

[[ $STATUS -eq 0 ]]
printf '%s' "$OUTPUT" | grep -q 'local changes detected'
grep -q '# local edit' "$SKILL"

"$REPO_ROOT/install.sh" "$TARGET" --copy --force
! grep -q '# local edit' "$SKILL"

! find "$TARGET/.agents/skills" -name '*.bak.*' | grep -q .
! find "$TARGET/.claude/skills" -name '*.bak.*' | grep -q .

mkdir -p "$TARGET_SYMLINK"

"$REPO_ROOT/install.sh" "$TARGET_SYMLINK"

SYMLINK_PATH="$TARGET_SYMLINK/.agents/skills/intervals-time-entry"
EXPECTED_SOURCE="$REPO_ROOT/skills/intervals-time-entry"

[[ -L "$SYMLINK_PATH" ]]
[[ "$(readlink "$SYMLINK_PATH")" == "$EXPECTED_SOURCE" ]]

"$REPO_ROOT/install.sh" "$TARGET_SYMLINK"
[[ "$(readlink "$SYMLINK_PATH")" == "$EXPECTED_SOURCE" ]]

rm -f "$SYMLINK_PATH"
ln -s /tmp/wrong-skill "$SYMLINK_PATH"

set +e
SYMLINK_OUTPUT=$("$REPO_ROOT/install.sh" "$TARGET_SYMLINK" 2>&1)
SYMLINK_STATUS=$?
set -e

[[ $SYMLINK_STATUS -eq 0 ]]
printf '%s' "$SYMLINK_OUTPUT" | grep -q 'skipping existing path'
[[ "$(readlink "$SYMLINK_PATH")" == "/tmp/wrong-skill" ]]

"$REPO_ROOT/install.sh" "$TARGET_SYMLINK" --force
[[ "$(readlink "$SYMLINK_PATH")" == "$EXPECTED_SOURCE" ]]

! find "$TARGET_SYMLINK/.agents/skills" -name '*.bak.*' | grep -q .
! find "$TARGET_SYMLINK/.claude/skills" -name '*.bak.*' | grep -q .

echo "install update semantics passed"
