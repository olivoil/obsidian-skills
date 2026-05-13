#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$(npx skills add "$REPO_ROOT" --list 2>&1)"

printf '%s' "$OUTPUT" | grep -q 'Found 19 skills'
printf '%s' "$OUTPUT" | grep -q 'setup-obsidian-skills'
printf '%s' "$OUTPUT" | grep -q 'pr-review'
printf '%s' "$OUTPUT" | grep -q 'security-incident-response'
printf '%s' "$OUTPUT" | grep -q 'refine-daily-note'

echo "skills cli discovery passed"
