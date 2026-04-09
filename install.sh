#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO=""
MODE="symlink"
INSTALL_ARGS=()
BOOTSTRAP_ONLY=0
RESET_CACHE=""

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy"; INSTALL_ARGS+=("--copy") ;;
    --symlink) MODE="symlink"; INSTALL_ARGS+=("--symlink") ;;
    --claude-only|--codex-only|--force) INSTALL_ARGS+=("$arg") ;;
    --reset-cache) RESET_CACHE="--reset-cache" ;;
    --bootstrap-only) BOOTSTRAP_ONLY=1 ;;
    --help)
      cat <<'USAGE'
Usage: ./install.sh [target-repo] [--symlink|--copy] [--claude-only|--codex-only] [--bootstrap-only] [--force] [--reset-cache]

Examples:
  ./install.sh ~/Code/github.com/olivoil/obsidian
  ./install.sh ~/Code/github.com/olivoil/obsidian --copy --force
  ./install.sh ~/Code/github.com/olivoil/obsidian --reset-cache
  ./install.sh ~/Code/github.com/olivoil/obsidian --force --reset-cache
  ./install.sh ~/Code/github.com/olivoil/obsidian --bootstrap-only
USAGE
      exit 0
      ;;
    *)
      if [[ "$arg" == --* ]]; then
        echo "Unknown option: $arg" >&2
        exit 1
      fi
      TARGET_REPO="$arg"
      ;;
  esac
done

if [[ -z "$TARGET_REPO" ]]; then
  echo "Error: target repo is required." >&2
  echo "Run ./install.sh --help for usage." >&2
  exit 1
fi

if [[ "$BOOTSTRAP_ONLY" -eq 0 ]]; then
  "$SCRIPT_DIR/scripts/install-into-repo.sh" "$TARGET_REPO" "${INSTALL_ARGS[@]}"
fi
"$SCRIPT_DIR/scripts/bootstrap-cache.sh" "$TARGET_REPO" "$RESET_CACHE"

echo
echo "Installed obsidian-skills into: $TARGET_REPO"
echo "Codex skills:  $TARGET_REPO/.agents/skills"
echo "Claude skills: $TARGET_REPO/.claude/skills"
echo "Shared cache:  $TARGET_REPO/.cache/om"
