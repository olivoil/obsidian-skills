# skills

Personal cross-agent skills for recurring work. The repo is organized by use case, but skills intentionally install with flat names.

Current groups:

- [`skills/obsidian`](./skills/obsidian/README.md) — workflows for maintaining my personal Obsidian vault.
- [`skills/engineering`](./skills/engineering/README.md) — recurring engineering workflows such as PR review and security incident response.

## Install

Use Vercel's Skills CLI from the repo where you want to install skills:

```bash
npx skills add olivoil/skills
```

The CLI is interactive and lets you choose which skills and agents to install. To install from a local checkout while developing:

```bash
npx skills add ~/Code/github.com/olivoil/skills
```

For group-specific recommendations, see:

- [Obsidian skills](./skills/obsidian/README.md)
- [Engineering skills](./skills/engineering/README.md)

## Updating

From a repo with installed skills:

```bash
npx skills update
```

## Notes

This repo is public. Some skills encode my workflow and assumptions, especially the Obsidian ones, but the patterns may still be useful to adapt.
