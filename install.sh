#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="$PWD"
MODE="symlink"
INSTALL_ARGS=()
BOOTSTRAP_ONLY=0
FORCE=""

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy"; INSTALL_ARGS+=("--copy") ;;
    --symlink) MODE="symlink"; INSTALL_ARGS+=("--symlink") ;;
    --claude-only|--codex-only|--force) INSTALL_ARGS+=("$arg"); [[ "$arg" == "--force" ]] && FORCE="--force" ;;
    --bootstrap-only) BOOTSTRAP_ONLY=1 ;;
    --help)
      cat <<'USAGE'
Usage: ./install.sh [target-repo] [--symlink|--copy] [--claude-only|--codex-only] [--bootstrap-only] [--force]

Examples:
  ./install.sh ~/Code/github.com/olivoil/obsidian
  ./install.sh ~/Code/github.com/olivoil/obsidian --copy --force
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

if [[ "$BOOTSTRAP_ONLY" -eq 0 ]]; then
  "$SCRIPT_DIR/scripts/install-into-repo.sh" "$TARGET_REPO" "${INSTALL_ARGS[@]}"
fi
"$SCRIPT_DIR/scripts/bootstrap-cache.sh" "$TARGET_REPO" "$FORCE"

echo
echo "Installed obsidian-skills into: $TARGET_REPO"
echo "Codex skills:  $TARGET_REPO/.agents/skills"
echo "Claude skills: $TARGET_REPO/.claude/skills"
echo "Shared cache:  $TARGET_REPO/.cache/om"
