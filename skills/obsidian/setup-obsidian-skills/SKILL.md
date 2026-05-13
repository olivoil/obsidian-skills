---
name: setup-obsidian-skills
description: Use when setting up the Obsidian skills in a vault repo for the first time, repairing missing `.cache/om` runtime files, or migrating old `.claude` cache state.
---

# Setup Obsidian Skills

Initialize the repo-local runtime files that the Obsidian skills share across agents.

This is a setup skill for a consumer Obsidian vault repo, not for this skills source repo. It is safe to re-run: by default it creates only missing files and preserves learned mappings.

## Process

1. Confirm the current working directory is the target vault repo.
   - Look for vault-like folders such as `Daily Notes/`, `Weekly Notes/`, `Meetings/`, `Projects/`, `Persons/`, or `Topics/`.
   - If the current directory appears to be the skills source repo instead of the vault, stop and ask the user to run from the vault repo.
2. Inspect runtime state:
   - `.cache/om/intervals-cache/`
   - `.cache/om/time-entries.db`
   - old Claude-only state: `.claude/intervals-cache/` and `.claude/time-entries.db`
3. Tell the user what is present and what will be created or migrated.
4. Run the bootstrap script from this skill folder. Resolve `scripts/bootstrap-cache.sh` relative to the installed `setup-obsidian-skills` skill directory, not relative to the vault repo:

   ```bash
   bash /path/to/setup-obsidian-skills/scripts/bootstrap-cache.sh "$PWD"
   ```

5. If the user explicitly asks to reset templates, warn that this overwrites cache-backed mapping files, then run:

   ```bash
   bash /path/to/setup-obsidian-skills/scripts/bootstrap-cache.sh "$PWD" --reset-cache
   ```

6. Report the resulting files and remind the user that live mappings belong in `.cache/om`, not in the skills repo.

## Runtime files

The bootstrap creates or preserves:

```text
.cache/om/
├── intervals-cache/
│   ├── project-mappings.md
│   ├── github-mappings.md
│   ├── outlook-mappings.md
│   ├── slack-mappings.md
│   ├── people-context.md
│   ├── freshbooks-mappings.md
│   └── worktype-mappings.md
└── time-entries.db
```

## Rules

- Never overwrite existing `.cache/om/intervals-cache/*.md` files unless the user explicitly asked for reset behavior.
- Migrate old `.claude` cache files only when the destination is missing, unless reset was explicitly requested.
- Do not commit `.cache/om` runtime files to the skills source repo.
