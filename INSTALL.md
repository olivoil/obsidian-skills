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

### Replace existing installed skills and cache seeds

```bash
./install.sh ~/Code/github.com/olivoil/obsidian --force
```

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
