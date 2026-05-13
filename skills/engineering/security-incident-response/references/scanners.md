# Scanner Reference

Use scanners as evidence helpers. Do not treat scanner output as a substitute for understanding the incident and tracing exposure.

## Universal dependency scanners

```bash
# OSV across a directory tree
osv-scanner scan source --recursive /path/to/repo
osv-scanner scan --lockfile package-lock.json
osv-scanner scan --lockfile pnpm-lock.yaml
osv-scanner scan --lockfile poetry.lock

# Trivy filesystem scan
trivy fs --scanners vuln,secret,misconfig /path/to/repo

# Grype filesystem scan
grype dir:/path/to/repo
```

## JavaScript / TypeScript

```bash
npm audit --json
npm audit --omit dev --json
pnpm audit --json
yarn npm audit --json
corepack pnpm audit --json
```

Safer install if dependencies must be materialized:

```bash
npm ci --ignore-scripts
pnpm install --ignore-scripts --frozen-lockfile
yarn install --immutable --mode=skip-builds
```

Static checks for lifecycle scripts:

```bash
rg '"(preinstall|install|postinstall|prepare)"' package.json package-lock.json pnpm-lock.yaml yarn.lock
```

## Python

```bash
pip-audit -r requirements.txt
pip-audit -P package==version
pip-audit --path .venv  # only if the venv is trusted
uv pip compile --help >/dev/null 2>&1 || true
```

## Ruby

```bash
bundle audit check --update
```

## Go

```bash
govulncheck ./...
```

## Rust

```bash
cargo audit
```

## GitHub Actions

### zizmor

```bash
zizmor .github/workflows --format plain
zizmor .github/workflows --format json > /tmp/zizmor.json
```

zizmor is a static analyzer for GitHub Actions security issues and can emit SARIF for code scanning.

### Snyk Labs GitHub Actions Scanner

The Snyk Labs scanner was released from Snyk Security Labs research and is not a supported Snyk product. It is useful for detecting pwn-request and expression-injection patterns.

```bash
git clone https://github.com/snyk-labs/github-actions-scanner /tmp/github-actions-scanner
cd /tmp/github-actions-scanner
npm ci
npm run start -- list-rules
npm run start -- scan-repo --path /path/to/repo -f json --output /tmp/gha-scan.json
```

Useful rules to look for include:

- `PWN_REQUEST` — `pull_request_target` plus checkout/execution of PR-controlled code
- `CMD_EXEC` — attacker-controlled `${{ }}` expression inserted into shell execution
- `CODE_INJECT` — attacker-controlled values inserted into `actions/github-script`

## Secrets and indicators

```bash
gitleaks detect --source /path/to/repo --redact
rg -n 'NPM_TOKEN|PYPI_TOKEN|GH_TOKEN|GITHUB_TOKEN|ACTIONS_ID_TOKEN|id-token: write|contents: write' /path/to/repo/.github /path/to/repo
```

## GitHub metadata

```bash
gh repo view --json nameWithOwner,defaultBranchRef,isPrivate
gh api repos/{owner}/{repo}/actions/permissions
gh api repos/{owner}/{repo}/dependabot/alerts --paginate
```
