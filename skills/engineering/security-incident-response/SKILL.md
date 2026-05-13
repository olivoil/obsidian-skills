---
name: security-incident-response
description: Use when asked to assess a disclosed vulnerability, active supply-chain incident, suspicious package or GitHub Actions attack, scan projects for exposure, plan remediation, or advise on security incident handling.
---

# Security Incident Response

Investigate the incident, determine exposure, and produce a practical response plan. Be careful, evidence-driven, and explicit about uncertainty.

This skill covers incidents such as CVEs, framework advisories, npm/PyPI/RubyGems supply-chain attacks, compromised GitHub Actions, cache poisoning, leaked tokens, malicious packages, and vulnerable dependency ranges.

## Safety rules

- Do not execute untrusted project scripts, package lifecycle hooks, or downloaded PoCs.
- Prefer static inspection, lockfile parsing, and scanners that do not run project code.
- If installation is necessary, use safe modes such as `npm ci --ignore-scripts`, `pnpm install --ignore-scripts`, or equivalent.
- Do not publish exploitable details unnecessarily. Use private disclosure channels for third-party findings.
- Preserve evidence: URLs, advisory IDs, affected versions, command output, lockfile paths, and timestamps.
- Distinguish confirmed exposure from possible exposure and unknowns.

## Workflow

### 1. Clarify scope without blocking

Infer the target from the user request:

- Specific advisory/CVE/package/incident if named
- Current repo if no path is given
- Paths such as `~/Code` if requested
- GitHub org/repo if provided

If the incident is vague or current, research before concluding.

### 2. Research the incident

Use current sources. Prefer primary or authoritative sources:

- Vendor/framework security advisories and changelogs
- GitHub Security Advisories
- NVD/CVE records
- CISA KEV for exploited-in-the-wild status
- Package maintainer advisories and release notes
- GitHub Security Lab, Snyk Labs, Trail of Bits, StepSecurity, Socket, OpenSSF, JFrog, Chainguard, Wiz, and similar research when primary details are incomplete

Capture:

- Affected products/packages/actions
- Vulnerable version ranges or vulnerable workflow patterns
- Fixed versions or mitigations
- Exploit preconditions
- Known exploitation status
- Indicators of compromise if available
- Recommended response window

Explain the issue in plain language before scanning so the user understands what exposure means.

### 3. Inventory projects

For each requested project/repo, identify ecosystem and relevant files:

```bash
find {root} -maxdepth 3 \( -name package.json -o -name package-lock.json -o -name pnpm-lock.yaml -o -name yarn.lock -o -name pyproject.toml -o -name requirements*.txt -o -name poetry.lock -o -name uv.lock -o -name Pipfile.lock -o -name Gemfile.lock -o -name go.mod -o -name Cargo.lock -o -name composer.lock \)
find {root} -path '*/.github/workflows/*' -type f
find {root} \( -name action.yml -o -name action.yaml \)
```

Exclude dependency/vendor/build directories unless specifically needed:

```text
node_modules, vendor, .venv, venv, dist, build, target, .next, .turbo, .git
```

### 4. Use scanners when useful

Use tools that fit the incident and ecosystem. If a tool is not installed, say so and provide the install command; do not fail the assessment solely because one scanner is missing.

See `references/scanners.md` for commands.

Common tools:

- Dependencies: `osv-scanner`, `npm audit`, `pnpm audit`, `yarn npm audit`, `pip-audit`, `bundle audit`, `cargo audit`, `govulncheck`, `trivy fs`, `grype`
- GitHub Actions: `zizmor`, `snyk-labs/github-actions-scanner`
- Secrets/IoCs: `gitleaks`, `ripgrep`, package-manager lockfile inspection
- Repos/orgs: `gh` for metadata, workflow files, advisories, Dependabot alerts when available

For a GitHub Actions supply-chain incident, specifically run or recommend:

```bash
zizmor .github/workflows --format plain
# and, when deeper pwn-request/expression-injection scanning is needed:
git clone https://github.com/snyk-labs/github-actions-scanner /tmp/github-actions-scanner
cd /tmp/github-actions-scanner
npm ci
npm run start -- scan-repo --path /path/to/repo -f json --output /tmp/gha-scan.json
```

If command syntax differs in the installed version, run `--help` and adapt.

### 5. Manual checks for GitHub Actions incidents

Always inspect `.github/workflows/*.yml`, local actions, and scripts referenced by workflows. Check for:

- `pull_request_target` combined with checkout of fork-controlled code
- `workflow_run` that trusts artifacts or caches produced by untrusted workflows
- cache poisoning: privileged workflows restore caches writable by untrusted workflows
- broad `permissions:` or default write tokens
- secrets exposed to untrusted code paths
- unpinned third-party actions or tags that can move
- `actions/github-script` or `run:` blocks interpolating attacker-controlled `${{ }}` values
- issue/PR comment commands without author association checks
- self-hosted runners on untrusted PRs
- package publishing via OIDC/trusted publishing after restoring untrusted caches/artifacts
- AI/agent workflows that feed issue/PR text into a privileged agent with write tools

Only report an Actions finding as confirmed when you can trace: entry point → attacker control → execution/trust boundary → impact → fix.

### 6. Manual checks for package supply-chain incidents

Inspect:

- Direct and transitive dependency versions in lockfiles
- package manager overrides/resolutions
- package tarball integrity and registry host changes
- lifecycle scripts: `preinstall`, `install`, `postinstall`, `prepare`
- suspicious new binaries or network calls in lockfile-resolved packages when applicable
- CI publish workflows and tokens/OIDC trust boundaries
- local global package installs only if relevant to the incident

### 7. Classify each project

Use one of:

- `confirmed exposed` — affected version/pattern/IoC present
- `possibly exposed` — matching ecosystem or pattern but evidence incomplete
- `not exposed` — evidence shows unaffected version or pattern absent
- `unknown` — could not inspect enough

For each project include:

- Evidence: files, versions, workflow lines, scanner results
- Risk: impact and likelihood in this project's context
- Remediation: exact dependency updates, YAML changes, token rotation, cache invalidation, workflow disablement, or PR plan
- Verification: commands/tests/scanners to rerun
- Owner/urgency if known

### 8. Response planning

Prioritize:

1. Containment: disable risky workflow, revoke/rotate tokens, invalidate caches, block publishing, remove compromised package
2. Remediation: update dependencies/actions, pin SHAs, reduce permissions, split trusted/untrusted jobs
3. Verification: rerun scanners/tests, inspect logs, confirm fixed versions
4. Hardening: Dependabot/Renovate, branch protection, code owners, secret scanning, audit logging, workflow permission defaults
5. Disclosure: private report, maintainer contact, advisory, customer/user communication if needed

### 9. Output format

```markdown
# Security Incident Assessment: {incident}

## Executive Summary
- Status: confirmed exposed / possibly exposed / not exposed / unknown
- Highest urgency: critical/high/medium/low
- Immediate action: ...

## What Happened
Plain-language explanation with links to sources.

## Exposure Matrix
| Project | Status | Evidence | Immediate Action |
|---|---|---|---|

## Project Details
### {project}
- **Status**:
- **Evidence**:
- **Risk**:
- **Remediation**:
- **Verification**:

## Immediate Actions
- [ ] ...

## Hardening Follow-ups
- [ ] ...

## Sources
- ...
```

If creating PRs is requested, first present the plan per project and ask before modifying files.
