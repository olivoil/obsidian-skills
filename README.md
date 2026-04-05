# obsidian-skills

Cross-agent skills for maintaining my personal Obsidian vault.

## Included skills

- `refine-daily-note`
- `weekly-rollup`
- `transcribe-meeting`
- `session-rollup`
- `intervals-time-entry`
- `intervals-to-freshbooks`
- `freshbooks-time-entry`

## Design goals

- Work in both Claude Code and Codex
- Share the same runtime state so you can switch agents freely
- Keep mutable mappings and SQLite state in the consumer repo under `.cache/om`
- Keep skill source, scripts, and templates in this dedicated repo instead of cluttering the vault repo

## Runtime state

These skills expect the consumer repo to hold shared state at:

```text
.cache/om/
├── intervals-cache/
│   ├── project-mappings.md
│   ├── github-mappings.md
│   ├── outlook-mappings.md
│   ├── slack-mappings.md
│   ├── people-context.md
│   └── freshbooks-mappings.md
└── time-entries.db
```

## Install

See [INSTALL.md](./INSTALL.md).
