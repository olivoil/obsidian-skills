# Engineering skills

General engineering workflow skills. These are not tied to Obsidian and are intended to grow into my own flavor of recurring engineering playbooks.

## Install

Use the interactive installer from the repo where you want the skills:

```bash
npx skills add olivoil/skills
```

To install only the engineering group:

```bash
npx skills add https://github.com/olivoil/skills/tree/main/skills/engineering
```

For local development from this checkout:

```bash
npx skills add ~/Code/github.com/olivoil/skills/skills/engineering
```

## Skills

### `pr-review`

Review GitHub pull requests or local branches with a project-agnostic, high-signal code review workflow.

Highlights:

- accepts PR URLs, PR numbers, branch names, current branch, or local pre-PR review mode
- adapts to projects by reading repo instructions and changed files
- supports subagent/parallel review when available, sequential review when not
- filters hard for high-confidence, actionable findings
- previews findings before posting
- can post confirmed inline GitHub review comments via `gh`

### `security-incident-response`

Research disclosed or ongoing security incidents, scan projects for exposure, and produce remediation and hardening plans.

Highlights:

- handles CVEs, package compromises, framework advisories, and GitHub Actions supply-chain incidents
- researches current authoritative sources before drawing conclusions
- inventories projects and classifies exposure per project
- uses safe/static scanning where possible
- includes references for OSV, Trivy, Grype, npm/pnpm/yarn audit, pip-audit, bundle-audit, govulncheck, cargo-audit, zizmor, Snyk Labs GitHub Actions Scanner, gitleaks, and `gh`
