# CI/CD Workflows

**GitHub Actions for automated testing and deployment**

## Overview

This directory contains GitHub Actions workflows for:
- Automated testing on pull requests and commits
- Linting and code quality checks
- Future: Deployment to AO testnet/mainnet
- Future: npm package publishing (CLI)

## Active Workflows

### `ci.yaml` ✅ Implemented (Story 1.2)

**Purpose**: Automated testing and code quality checks

**Triggers**:
- Every `push` to any branch
- Every `pull_request` to any branch

**Workflow Steps**:
1. **Checkout code** - Uses `actions/checkout@v4`
2. **Setup Node.js 18** - Uses `actions/setup-node@v4` with npm caching
3. **Setup Lua 5.3** - Uses `leafo/gh-actions-lua@v10`
4. **Install dependencies** - Runs `npm install` (workspace-aware)
5. **Install aolite** - Installs aolite globally for Lua testing
6. **Lint TypeScript code** - Runs `npm run lint --workspace=cli` (ESLint)
7. **Check code formatting** - Runs `npm run format:check --workspace=cli` (Prettier)
8. **Run aolite tests** - Executes all `*.test.lua` files in `/tests` directory
   - Currently passes if no tests exist (tests added in Story 1.3+)
   - Will automatically run tests once they are added

**Build Failure Conditions**:
- ESLint errors in CLI TypeScript code
- Prettier formatting violations in CLI TypeScript code
- Any failing aolite tests (once tests are added)

**How to View Results**:
1. Navigate to the "Actions" tab in GitHub repository
2. Click on the workflow run for your commit/PR
3. Expand each step to view detailed logs
4. Check the CI badge status in the README.md

**How to Troubleshoot Failed Builds**:
- **Linting failures**: Run `npm run lint:fix --workspace=cli` locally
- **Formatting failures**: Run `npm run format --workspace=cli` locally
- **Test failures**: Run `aolite test tests/**/*.test.lua` locally to reproduce

**Note on aolite Tests**:
The workflow is prepared to execute aolite tests from the `/tests` directory. Once Story 1.3 (aolite Testing Framework Integration) is complete, tests will automatically run in CI without any workflow changes.

## Planned Future Workflows

### `npm-publish.yaml`
Triggered on version tags (`v*`):
- Builds CLI package
- Runs full test suite
- Publishes to npm registry
- Creates GitHub release

### `apm-publish.yaml`
Manual workflow for SDK distribution:
- Validates SDK Lua code
- Runs integration tests
- Publishes to apm registry

## Architecture Reference

For deployment architecture, see:
- [Deployment Architecture](../../docs/architecture/deployment-architecture.md)
- [Tech Stack](../../docs/architecture/tech-stack.md#technology-stack-table)

## License

MIT
