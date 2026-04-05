#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_REPO=""
MODE="symlink"
INSTALL_CLAUDE=1
INSTALL_CODEX=1
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --symlink) MODE="symlink" ;;
    --claude-only) INSTALL_CODEX=0 ;;
    --codex-only) INSTALL_CLAUDE=0 ;;
    --force) FORCE=1 ;;
    *)
      if [[ "$arg" == --* ]]; then
        echo "Unknown option: $arg" >&2
        exit 1
      fi
      if [[ -z "$TARGET_REPO" ]]; then
        TARGET_REPO="$arg"
      else
        echo "Unexpected extra argument: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

TARGET_REPO="${TARGET_REPO:-$PWD}"

if [[ ! -d "$TARGET_REPO" ]]; then
  echo "Target repo does not exist: $TARGET_REPO" >&2
  exit 1
fi

backup_existing() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    mv "$path" "$path.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

install_one() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    echo "already installed: $dest -> $src"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      backup_existing "$dest"
    else
      echo "skipping existing path (use --force to replace): $dest"
      return
    fi
  fi

  case "$MODE" in
    symlink) ln -s "$src" "$dest" ;;
    copy) cp -R "$src" "$dest" ;;
    *) echo "Unsupported mode: $MODE" >&2; exit 1 ;;
  esac
  echo "installed: $dest"
}

[[ "$INSTALL_CODEX" -eq 1 ]] && mkdir -p "$TARGET_REPO/.agents/skills"
[[ "$INSTALL_CLAUDE" -eq 1 ]] && mkdir -p "$TARGET_REPO/.claude/skills"

for skill_dir in "$REPO_ROOT"/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  [[ "$INSTALL_CODEX" -eq 1 ]] && install_one "$skill_dir" "$TARGET_REPO/.agents/skills/$skill_name"
  [[ "$INSTALL_CLAUDE" -eq 1 ]] && install_one "$skill_dir" "$TARGET_REPO/.claude/skills/$skill_name"
done
