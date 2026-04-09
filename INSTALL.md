# Install obsidian-skills

These skills are intended to be installed into a consumer repo such as:

```text
~/Code/github.com/olivoil/obsidian
```

## Recommended install: local checkout + symlinks

From this repo checkout:

```bash
./install.sh ~/Code/github.com/olivoil/obsidian
```

The target repo argument is mandatory. `install.sh` will refuse to run without an explicit install directory so it cannot accidentally install into the current working directory.

That will:

- symlink every skill into `TARGET/.agents/skills/` for Codex
- symlink every skill into `TARGET/.claude/skills/` for Claude Code
- create and seed `TARGET/.cache/om/intervals-cache/`
- migrate old state from `TARGET/.claude/intervals-cache/` and `TARGET/.claude/time-entries.db` if present

## Alternative install modes

### Copy instead of symlink

```bash
./install.sh ~/Code/github.com/olivoil/obsidian --copy
```

### Bootstrap cache only

```bash
./install.sh ~/Code/github.com/olivoil/obsidian --bootstrap-only
```

### Overwrite installed skills only

```bash
./install.sh ~/Code/github.com/olivoil/obsidian --force
```

`--force` overwrites installed skills only. It does **not** reset `.cache/om/intervals-cache/*.md`.

### Reset cache/mapping files explicitly

```bash
./install.sh ~/Code/github.com/olivoil/obsidian --reset-cache
```

Use `--reset-cache` only when you explicitly want to reseed the cache-backed mapping files from this repo's templates.

### Overwrite skills and reset cache explicitly

```bash
./install.sh ~/Code/github.com/olivoil/obsidian --force --reset-cache
```

## Update behavior for existing installs

- default installs preserve learned mappings and existing cache state
- default installs update already-installed copied skills only when they have no detected local changes
- `--force` overwrites installed skills in place without creating backup skill directories
- backup skill directories are no longer created during updates, so Claude/Codex won't see duplicate-looking skills

## Optional: install with `npx skills`

If you prefer the Skills CLI for installation, install the skill folders into the consumer repo and then still run bootstrap:

```bash
# Example only — adapt to your preferred skills CLI flow
cd ~/Code/github.com/olivoil/obsidian
npx skills add ~/Code/github.com/olivoil/obsidian-skills -a codex -a claude-code
bash ~/Code/github.com/olivoil/obsidian-skills/install.sh . --bootstrap-only
```

Use the direct `install.sh` path if you want the least moving parts.

## Migration from the old Claude-only setup

If your vault already has:

```text
.claude/intervals-cache/
.claude/time-entries.db
```

then `install.sh` will migrate those files into:

```text
.cache/om/intervals-cache/
.cache/om/time-entries.db
```

The old files are left in place so you can compare during testing.

## Suggested test workflow

1. Create a worktree of the vault repo.
2. Run `./install.sh <worktree-path>` from this repo.
3. Test in Codex and Claude Code against the same worktree.
4. Verify both agents read and update the same `.cache/om` files.
5. Once satisfied, install into the main vault branch.
