#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_REPO=""
MODE="symlink"
INSTALL_CLAUDE=1
INSTALL_CODEX=1
FORCE=0
MANIFEST_PATH=""

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
MANIFEST_PATH="$TARGET_REPO/.cache/om/install-state/skills.json"

if [[ ! -d "$TARGET_REPO" ]]; then
  echo "Target repo does not exist: $TARGET_REPO" >&2
  exit 1
fi

manifest_key_for_dest() {
  local dest="$1"
  printf '%s\n' "${dest#$TARGET_REPO/}"
}

current_tree_hash() {
  python3 "$REPO_ROOT/scripts/install-state.py" hash-tree "$1"
}

manifest_entry_json() {
  local manifest_key="$1"
  python3 "$REPO_ROOT/scripts/install-state.py" get-entry "$MANIFEST_PATH" "$manifest_key"
}

manifest_installed_hash() {
  local manifest_key="$1"
  local entry_json
  entry_json="$(manifest_entry_json "$manifest_key")"
  if [[ -z "$entry_json" ]]; then
    printf '\n'
    return
  fi

  ENTRY_JSON="$entry_json" python3 - <<'PY'
import json
import os

entry = json.loads(os.environ["ENTRY_JSON"])
print(entry.get("installed_hash", ""))
PY
}

record_copy_install() {
  local manifest_key="$1"
  local src="$2"
  local installed_hash="$3"
  python3 "$REPO_ROOT/scripts/install-state.py" set-entry \
    "$MANIFEST_PATH" "$manifest_key" copy "$src" "$installed_hash"
}

replace_with_copy() {
  local src="$1"
  local dest="$2"
  local parent_dir
  local tmp_dest

  parent_dir="$(dirname "$dest")"
  mkdir -p "$parent_dir"
  tmp_dest="$(mktemp -d "$parent_dir/.install.XXXXXX")"
  rm -rf "$tmp_dest"
  cp -a "$src" "$tmp_dest"
  rm -rf "$dest"
  mv "$tmp_dest" "$dest"
}

replace_with_symlink() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  ln -s "$src" "$dest"
}

install_one() {
  local src="$1"
  local dest="$2"
  local skill_name="$3"
  local manifest_key
  local installed_hash
  local recorded_hash
  local source_hash

  mkdir -p "$(dirname "$dest")"
  manifest_key="$(manifest_key_for_dest "$dest")"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    if [[ "$FORCE" -eq 0 || "$MODE" == "symlink" ]]; then
      echo "already installed: $dest -> $src"
      return
    fi
  fi

  if [[ "$MODE" == "copy" && -d "$dest" && ! -L "$dest" ]]; then
    if [[ "$FORCE" -eq 0 ]]; then
      source_hash="$(current_tree_hash "$src")"
      installed_hash="$(current_tree_hash "$dest")"
      recorded_hash="$(manifest_installed_hash "$manifest_key")"

      if [[ -z "$recorded_hash" ]]; then
        if [[ "$installed_hash" == "$source_hash" ]]; then
          record_copy_install "$manifest_key" "$src" "$installed_hash"
          echo "tracking existing clean install: $dest"
        else
          echo "skipping local changes detected (no manifest; use --force to replace): $dest"
        fi
        return
      fi

      if [[ "$installed_hash" != "$recorded_hash" ]]; then
        echo "skipping local changes detected: $dest"
        return
      fi

      if [[ "$installed_hash" == "$source_hash" ]]; then
        echo "already installed: $dest"
        return
      fi
    fi
  elif [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" -eq 0 ]]; then
      echo "skipping existing path (use --force to replace): $dest"
      return
    fi
  fi

  case "$MODE" in
    symlink)
      replace_with_symlink "$src" "$dest"
      ;;
    copy)
      replace_with_copy "$src" "$dest"
      record_copy_install "$manifest_key" "$src" "$(current_tree_hash "$dest")"
      ;;
    *) echo "Unsupported mode: $MODE" >&2; exit 1 ;;
  esac
  echo "installed: $dest"
}

[[ "$INSTALL_CODEX" -eq 1 ]] && mkdir -p "$TARGET_REPO/.agents/skills"
[[ "$INSTALL_CLAUDE" -eq 1 ]] && mkdir -p "$TARGET_REPO/.claude/skills"

for skill_dir in "$REPO_ROOT"/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  [[ "$INSTALL_CODEX" -eq 1 ]] && install_one "$skill_dir" "$TARGET_REPO/.agents/skills/$skill_name" "$skill_name"
  [[ "$INSTALL_CLAUDE" -eq 1 ]] && install_one "$skill_dir" "$TARGET_REPO/.claude/skills/$skill_name" "$skill_name"
done
