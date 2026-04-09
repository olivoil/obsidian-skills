# Installer Update and Cache Reset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `install.sh` update installed skills safely, keep cache/mapping state untouched by default, add an explicit `--reset-cache` path, and eliminate backup clutter that appears as duplicate skills.

**Architecture:** Keep the existing shell-based installer entrypoints, but split semantics clearly: `--force` only affects installed skills, while cache reseeding requires a separate `--reset-cache` flag. Add one small Python helper to manage manifest state and stable directory hashing for copied skill installs so non-force updates can distinguish untouched installs from locally modified ones.

**Tech Stack:** Bash, Python 3, Markdown docs, shell test scripts, existing template-based cache bootstrap

---

## File Structure

### Files to modify
- `install.sh` — top-level CLI parsing and flag forwarding
- `scripts/install-into-repo.sh` — skill install/update logic for symlink and copy modes
- `scripts/bootstrap-cache.sh` — cache seeding/reset semantics
- `scripts/migrate-state.sh` — legacy `.claude/...` migration overwrite rules
- `INSTALL.md` — user-facing installer behavior docs
- `tests/smoke-install.sh` — keep baseline install coverage aligned with new semantics

### Files to create
- `scripts/install-state.py` — stable tree hashing + manifest read/write helper for copied skill installs
- `tests/install-update.sh` — copy/symlink update semantics, force overwrite semantics, no-backup assertions
- `tests/cache-reset.sh` — default cache preservation vs explicit `--reset-cache` behavior

### Runtime state created by the installer
- `<target>/.cache/om/install-state/skills.json` — hidden manifest storing copied-skill install baselines

---

### Task 1: Separate skill force from cache reset semantics

**Files:**
- Modify: `install.sh`
- Modify: `scripts/bootstrap-cache.sh`
- Modify: `scripts/migrate-state.sh`
- Test: `tests/cache-reset.sh`

- [ ] **Step 1: Write the failing cache reset test**

Create `tests/cache-reset.sh` with scenarios that prove the current bug and lock the new behavior:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
bash tests/cache-reset.sh
```

Expected: FAIL because current `--force` still reseeds cache files and `--reset-cache` does not exist.

- [ ] **Step 3: Update `install.sh` flag parsing minimally**

Add a second explicit flag channel instead of reusing `FORCE` for cache operations.

Use this shape:

```bash
RESET_CACHE=""

case "$arg" in
  --force)
    INSTALL_ARGS+=("--force")
    ;;
  --reset-cache)
    RESET_CACHE="--reset-cache"
    ;;
esac

if [[ "$BOOTSTRAP_ONLY" -eq 0 ]]; then
  "$SCRIPT_DIR/scripts/install-into-repo.sh" "$TARGET_REPO" "${INSTALL_ARGS[@]}"
fi
"$SCRIPT_DIR/scripts/bootstrap-cache.sh" "$TARGET_REPO" "$RESET_CACHE"
```

Also update `--help` text/examples to include `--reset-cache` and to stop implying that `--force` resets cache.

- [ ] **Step 4: Update cache bootstrap/migration semantics minimally**

Change `scripts/bootstrap-cache.sh` and `scripts/migrate-state.sh` so they interpret only `--reset-cache` as permission to overwrite existing cache state.

Use this branch shape in both scripts:

```bash
RESET_CACHE="${2:-}"

if [[ -e "$dest" && "$RESET_CACHE" != "--reset-cache" ]]; then
  echo "keeping existing: $dest"
  continue
fi

if [[ -e "$dest" && "$RESET_CACHE" == "--reset-cache" ]]; then
  rm -rf "$dest"
fi
```

Do not create `.bak.*` files for cache resets. Reset means replace in place.

- [ ] **Step 5: Run test to verify it passes**

Run:

```bash
bash tests/cache-reset.sh
```

Expected: PASS with `cache reset semantics passed`.

- [ ] **Step 6: Run smoke test to verify no regression**

Run:

```bash
bash tests/smoke-install.sh
```

Expected: PASS with `smoke install passed`.

- [ ] **Step 7: Commit**

```bash
git add install.sh scripts/bootstrap-cache.sh scripts/migrate-state.sh tests/cache-reset.sh tests/smoke-install.sh
git commit -m "fix: separate cache reset from force install"
```

---

### Task 2: Add manifest helper for copied-skill baseline tracking

**Files:**
- Create: `scripts/install-state.py`
- Test: `tests/install-update.sh`

- [ ] **Step 1: Write the failing manifest-aware update test**

Create `tests/install-update.sh` with a copy-mode scenario that proves three states:
1. copied install with recorded baseline and no local edits updates cleanly
2. copied install with local edits is skipped without `--force`
3. copied install is overwritten with `--force`

Use a structure like:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARGET="$TMPDIR/vault"
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

echo "install update semantics passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
bash tests/install-update.sh
```

Expected: FAIL because there is no manifest helper yet and non-force copy updates are still simple skip/replace logic.

- [ ] **Step 3: Create the Python helper with stable, explicit commands**

Create `scripts/install-state.py` with concrete subcommands:

```python
#!/usr/bin/env python3
import argparse, hashlib, json, os
from pathlib import Path


def hash_tree(path: Path) -> str:
    h = hashlib.sha256()
    for child in sorted(p for p in path.rglob('*')):
        rel = child.relative_to(path).as_posix()
        h.update(rel.encode() + b'\0')
        if child.is_symlink():
            h.update(b'S')
            h.update(os.readlink(child).encode() + b'\0')
        elif child.is_file():
            h.update(b'F')
            h.update(child.read_bytes())
        else:
            h.update(b'D')
    return h.hexdigest()
```

Required commands:
- `hash-tree <path>` → prints hash
- `get-entry <manifest> <skill-name>` → prints JSON or blank
- `set-entry <manifest> <skill-name> <mode> <source> <hash>` → upserts entry

Manifest shape:

```json
{
  "skills": {
    "intervals-time-entry": {
      "mode": "copy",
      "source": "/abs/path/to/repo/skills/intervals-time-entry",
      "installed_hash": "..."
    }
  }
}
```

- [ ] **Step 4: Run helper smoke checks directly**

Run:

```bash
python3 scripts/install-state.py hash-tree skills/intervals-time-entry
python3 scripts/install-state.py set-entry /tmp/skills.json intervals-time-entry copy /tmp/src deadbeef
python3 scripts/install-state.py get-entry /tmp/skills.json intervals-time-entry
```

Expected: a hash on the first command and JSON including `deadbeef` on the third.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-state.py tests/install-update.sh
git commit -m "feat: add installer state manifest helper"
```

---

### Task 3: Implement non-force safe updates and force overwrite for skills

**Files:**
- Modify: `scripts/install-into-repo.sh`
- Modify: `tests/install-update.sh`
- Test: `tests/install-update.sh`

- [ ] **Step 1: Write/extend the failing assertions for symlink and no-backup behavior**

Extend `tests/install-update.sh` to assert:
- non-force symlink install leaves correct symlink alone
- `--force` replaces wrong symlink/directory in place
- no `.bak.*` files are created anywhere under `.agents/skills` or `.claude/skills`

Concrete assertions:

```bash
find "$TARGET/.agents/skills" -name '*.bak.*' | grep -q . && exit 1
find "$TARGET/.claude/skills" -name '*.bak.*' | grep -q . && exit 1
```

Use inverted logic in the final test (`! find ... | grep -q .`).

- [ ] **Step 2: Run test to verify it still fails**

Run:

```bash
bash tests/install-update.sh
```

Expected: FAIL until `scripts/install-into-repo.sh` honors the manifest and removes backup behavior.

- [ ] **Step 3: Replace backup-based install logic with explicit update paths**

Refactor `scripts/install-into-repo.sh` around three cases:

1. **correct symlink already installed** → keep
2. **copy mode install** → consult manifest
3. **forced replace** → remove destination and replace in place

Use helper functions with clear responsibilities:

```bash
manifest_path="$TARGET_REPO/.cache/om/install-state/skills.json"

current_tree_hash() {
  python3 "$REPO_ROOT/scripts/install-state.py" hash-tree "$1"
}

record_copy_install() {
  python3 "$REPO_ROOT/scripts/install-state.py" set-entry \
    "$manifest_path" "$1" copy "$2" "$3"
}
```

For copied installs without `--force`, use this decision tree:

```bash
recorded_hash="$(python3 ... get-entry ... )"
installed_hash="$(current_tree_hash "$dest")"
source_hash="$(current_tree_hash "$src")"

if [[ -z "$recorded_hash" ]]; then
  if [[ "$installed_hash" == "$source_hash" ]]; then
    record_copy_install "$skill_name" "$src" "$installed_hash"
    echo "tracking existing clean install: $dest"
  else
    echo "skipping locally divergent install (no manifest; use --force to replace): $dest"
    return
  fi
elif [[ "$installed_hash" != "$recorded_hash" ]]; then
  echo "skipping local changes detected: $dest"
  return
fi
```

For force or safe update replacement, stage into a temp dir and swap into place:

```bash
tmp_dest="$(mktemp -d "$(dirname "$dest")/.install.XXXXXX")"
rm -rf "$tmp_dest"
cp -R "$src" "$tmp_dest"
rm -rf "$dest"
mv "$tmp_dest" "$dest"
```

After replacement, compute the new installed hash and record it.

For forced symlink replacement:

```bash
rm -rf "$dest"
ln -s "$src" "$dest"
```

Do not create backups anywhere.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
bash tests/install-update.sh
```

Expected: PASS with `install update semantics passed`.

- [ ] **Step 5: Run the full installer test suite**

Run:

```bash
bash tests/smoke-install.sh && bash tests/cache-reset.sh && bash tests/install-update.sh
```

Expected: all three scripts pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/install-into-repo.sh tests/install-update.sh
git commit -m "fix: update installed skills without backup clutter"
```

---

### Task 4: Update docs and polish test coverage

**Files:**
- Modify: `INSTALL.md`
- Modify: `install.sh`
- Modify: `tests/smoke-install.sh`
- Test: `tests/smoke-install.sh`

- [ ] **Step 1: Write the failing doc/help expectations**

Add assertions to `tests/smoke-install.sh` or a lightweight grep check command in this task so the text contract is explicit:

```bash
grep -q -- '--reset-cache' install.sh
grep -q 'overwrites installed skills only' INSTALL.md
```

- [ ] **Step 2: Run the doc/help check to verify it fails if not yet done**

Run:

```bash
grep -q 'reset-cache' install.sh && grep -q 'overwrites installed skills only' INSTALL.md
```

Expected: PASS only after help/docs are updated.

- [ ] **Step 3: Update docs/help text concretely**

Required help examples in `install.sh`:

```text
./install.sh ~/Code/github.com/olivoil/obsidian --force
./install.sh ~/Code/github.com/olivoil/obsidian --reset-cache
./install.sh ~/Code/github.com/olivoil/obsidian --force --reset-cache
```

Required `INSTALL.md` behavior notes:
- `--force` overwrites installed skills only
- `--reset-cache` explicitly reseeds cache/mapping files
- default installs preserve learned mappings
- no backup skill directories are created during updates

- [ ] **Step 4: Run all verification again**

Run:

```bash
bash tests/smoke-install.sh
bash tests/cache-reset.sh
bash tests/install-update.sh
```

Expected: all pass cleanly with no manual cleanup required afterward.

- [ ] **Step 5: Final verification diff review**

Run:

```bash
git diff --stat HEAD~3..HEAD
find . -path '*/.bak.*' -o -name '*.bak.*'
```

Expected: only intended installer/test/doc files changed, and no backup files created in the repo.

- [ ] **Step 6: Commit**

```bash
git add install.sh INSTALL.md tests/smoke-install.sh
git commit -m "docs: clarify installer force and cache reset behavior"
```

---

## Final Verification Checklist

Before handing off or publishing, run:

```bash
bash tests/smoke-install.sh
bash tests/cache-reset.sh
bash tests/install-update.sh
```

Then verify the working tree:

```bash
git status -sb
```

Expected: clean working tree, three passing test scripts, and no `.bak.*` artifacts in installed skill paths.

## Notes for the implementing agent

- Use @test-driven-development for each behavior change: write or extend the shell test first, watch it fail, then implement the smallest change.
- Use @verification-before-completion before any claim that installer behavior is fixed.
- Do not expand scope into a general installer rewrite; keep this focused on the agreed semantics.
- Prefer straightforward Bash + one small Python helper over introducing external dependencies such as `jq`.
