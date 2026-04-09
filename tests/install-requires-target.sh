#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/run"
pushd "$TMPDIR/run" >/dev/null

set +e
OUTPUT=$("$REPO_ROOT/install.sh" 2>&1)
STATUS=$?
set -e

popd >/dev/null

[[ $STATUS -ne 0 ]]
printf '%s' "$OUTPUT" | grep -q 'target repo is required'
! [[ -e "$TMPDIR/run/.agents" ]]
! [[ -e "$TMPDIR/run/.claude" ]]
! [[ -e "$TMPDIR/run/.cache" ]]

echo "install target requirement passed"
