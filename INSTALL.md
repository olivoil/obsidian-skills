# Install skills

Install these skills with Vercel's Skills CLI from the consumer repo where you want to use them.

For my Obsidian vault:

```bash
cd ~/Code/github.com/olivoil/obsidian
npx skills add olivoil/obsidian-skills --skill '*' --agent codex claude-code
```

For local development from this checkout:

```bash
cd ~/Code/github.com/olivoil/obsidian
npx skills add ~/Code/github.com/olivoil/obsidian-skills --skill '*' --agent codex claude-code
```

The skills live in this repo under `skills/obsidian/`, but they intentionally install with flat names such as `refine-daily-note`, `weekly-rollup`, and `setup-obsidian-skills`.

## First-time vault setup

After installing, run the setup skill from the vault repo:

```text
$setup-obsidian-skills
```

The setup skill initializes shared runtime state at:

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

By default it preserves existing files and learned mappings. It only overwrites cache templates when you explicitly ask it to reset them.

## Migration from the old Claude-only setup

If your vault already has:

```text
.claude/intervals-cache/
.claude/time-entries.db
```

then `$setup-obsidian-skills` can migrate those files into `.cache/om/`.

The old files are left in place so you can compare during testing.

## Updating skills

From the vault repo:

```bash
npx skills update
```

or re-run the `add` command above.
