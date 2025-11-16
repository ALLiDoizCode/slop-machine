# Contributing to Nillion Micropayment Protocol

First off, thank you for considering contributing to the Nillion micropayment protocol! 🎉

This document provides guidelines and instructions for contributing to this project.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Epic Development](#epic-development)
- [Documentation](#documentation)
- [Questions and Support](#questions-and-support)

---

## Code of Conduct

This project adheres to a code of professional conduct. By participating, you agree to:

- Be respectful and inclusive
- Focus on technical merit and constructive feedback
- Assume good intent
- Accept differing viewpoints professionally

---

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Node.js 18+** installed
- **pnpm 8+** package manager
- **Docker** and Docker Compose
- **Git** for version control
- Code editor with TypeScript support (VS Code recommended)

### Initial Setup

1. **Fork the repository** on GitHub

2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/nillion-micropayment-protocol.git
   cd nillion-micropayment-protocol
   ```

3. **Add upstream remote:**
   ```bash
   git remote add upstream https://github.com/your-org/nillion-micropayment-protocol.git
   ```

4. **Run automated setup:**
   ```bash
   ./scripts/dev-setup.sh
   ```

5. **Configure environment:**
   ```bash
   # Edit .env and add your API keys
   # INFURA_PROJECT_ID (get free at https://infura.io/)
   # ALCHEMY_API_KEY (get free at https://alchemy.com/)
   ```

6. **Verify setup:**
   ```bash
   pnpm run test        # All tests should pass
   pnpm run typecheck   # No TypeScript errors
   pnpm run lint        # No linting errors
   ```

---

## Development Workflow

### Creating a Feature Branch

```bash
# Update your local main
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feat/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### Branch Naming Conventions

| Type | Prefix | Example |
|------|--------|---------|
| New feature | `feat/` | `feat/payment-batching` |
| Bug fix | `fix/` | `fix/voucher-expiry-bug` |
| Epic work | `epic-N-` | `epic-2-bitcoin-lightning` |
| Documentation | `docs/` | `docs/api-examples` |
| Performance | `perf/` | `perf/redis-optimization` |
| Refactor | `refactor/` | `refactor/channel-manager` |
| Tests | `test/` | `test/payment-flow-coverage` |

### Making Changes

1. **Make your changes** in small, logical commits
2. **Write tests** for new functionality
3. **Update documentation** if needed
4. **Run checks locally:**
   ```bash
   pnpm run typecheck  # TypeScript validation
   pnpm run lint       # Code quality
   pnpm run test       # Test suite
   pnpm run format     # Auto-format code
   ```

### Keeping Your Branch Updated

```bash
# Fetch latest changes
git fetch upstream

# Rebase your branch
git rebase upstream/main

# Force push to your fork (if already pushed)
git push origin feat/your-feature-name --force-with-lease
```

---

## Coding Standards

### TypeScript

- ✅ **Strict mode enabled** - No `any` types without explicit justification
- ✅ **Explicit return types** on all public functions
- ✅ **No unused variables** - Enable `noUnusedLocals` and `noUnusedParameters`
- ✅ **Prefer `const`** over `let`, avoid `var` entirely
- ✅ **Use `interface`** for object shapes, `type` for unions/intersections

**Example:**

```typescript
// ✅ GOOD
export function processPayment(amount: bigint): Promise<PaymentResult> {
  const voucher = selectUnusedVoucher();
  return verifyAndExecute(voucher, amount);
}

// ❌ BAD
export function processPayment(amount: any) {  // No 'any'!
  let voucher = selectUnusedVoucher();  // Use 'const'
  return verifyAndExecute(voucher, amount);  // No return type!
}
```

### Financial Values

- ✅ **Always use `bigint`** for monetary amounts (never `number`)
- ✅ **Serialize bigint as string** in JSON: `amount.toString()`
- ✅ **Comment units** explicitly: `// Amount in wei`, `// Amount in satoshi`

**Example:**

```typescript
// ✅ GOOD
const amountWei: bigint = 1000000000000000000n; // 1 ETH in wei

// ❌ BAD
const amount: number = 1.0; // Loses precision!
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| **Variables** | camelCase | `voucherPool` |
| **Functions** | camelCase | `processPayment()` |
| **Classes** | PascalCase | `ChannelManager` |
| **Interfaces** | PascalCase | `IChannelRepository` |
| **Types** | PascalCase | `PaymentResult` |
| **Enums** | PascalCase | `ChannelStatus` |
| **Constants** | UPPER_SNAKE_CASE | `MAX_VOUCHER_COUNT` |
| **Files** | kebab-case | `payment-processor.ts` |
| **React Components** | PascalCase | `MetricCard.tsx` |
| **React Hooks** | camelCase with `use` | `useChannels.ts` |

### Import Order

```typescript
// 1. External dependencies
import { Fastify } from 'fastify';
import { z } from 'zod';

// 2. Internal packages (workspace)
import { PaymentChannel } from '@nillion/shared/types';
import { StreamMessage } from '@nillion/protocol';

// 3. Relative imports (same package)
import { ChannelRepository } from './channel-repository';
import { logger } from '../shared/logger';
```

### Error Handling

- ✅ **Use structured error objects** (not string throws)
- ✅ **Include error codes** for client handling
- ✅ **Log errors with context** (request ID, user ID, channel ID)
- ✅ **Never swallow errors** (always log or rethrow)

**Example:**

```typescript
// ✅ GOOD
class VoucherExpiredError extends Error {
  constructor(public voucherId: string) {
    super(`Voucher ${voucherId} has expired`);
    this.name = 'VoucherExpiredError';
  }
}

throw new VoucherExpiredError(voucher.id);

// ❌ BAD
throw 'voucher expired'; // String throw!
```

---

## Testing Requirements

### Test Coverage

- ✅ **80%+ coverage** required for new code
- ✅ **100% coverage** for critical paths (payment processing, MPC signing)
- ✅ **All exported functions** must have tests
- ✅ **Integration tests** for database operations (use Testcontainers)

### Writing Tests

```typescript
// packages/server-sdk/tests/payment-processor.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { PaymentProcessor } from '../src/payment-processor';

describe('PaymentProcessor', () => {
  describe('processPayment', () => {
    it('should successfully process payment with valid voucher', async () => {
      // Arrange
      const processor = new PaymentProcessor(/* deps */);
      const payment = { amount: 1000n, voucherId: 'voucher_123' };

      // Act
      const result = await processor.processPayment(payment);

      // Assert
      expect(result.status).toBe('COMPLETED');
      expect(result.latencyMs).toBeLessThan(100);
    });

    it('should reject payment with expired voucher', async () => {
      // Arrange
      const processor = new PaymentProcessor(/* deps */);
      const expiredPayment = { amount: 1000n, voucherId: 'expired_voucher' };

      // Act & Assert
      await expect(
        processor.processPayment(expiredPayment)
      ).rejects.toThrow('Voucher expired');
    });
  });
});
```

### Running Tests

```bash
# All tests
pnpm run test

# Specific package
pnpm run test --filter=client-sdk

# Watch mode
pnpm run test:watch

# With coverage
pnpm run test -- --coverage

# Epic-specific tests (for Epic branches)
pnpm run test -- --filter=ethereum
pnpm run test -- --filter=bitcoin
pnpm run test -- --filter=solana
```

### Test Organization

```
tests/
├── unit/           # Pure logic tests (no external dependencies)
├── integration/    # Tests with real DB/Redis (Testcontainers)
└── e2e/            # Manual end-to-end flows (documented, not automated)
```

---

## Commit Message Guidelines

We follow **Conventional Commits** specification:

### Format

```
<type>(<scope>): <short summary>

<optional body>

<optional footer>
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(payment): add batch payment support` |
| `fix` | Bug fix | `fix(voucher): handle expiry edge case` |
| `docs` | Documentation only | `docs(api): add WebSocket examples` |
| `style` | Code style (formatting, no logic change) | `style(server): fix ESLint warnings` |
| `refactor` | Code refactoring | `refactor(channel): extract settlement logic` |
| `perf` | Performance improvement | `perf(redis): optimize voucher cache` |
| `test` | Adding or updating tests | `test(payment): add edge case coverage` |
| `chore` | Build/tooling changes | `chore(deps): update Fastify to 4.27` |
| `ci` | CI/CD changes | `ci(github): add Epic test matrix` |

### Scopes

Use package or feature names:
- `client-sdk`, `server-sdk`, `protocol`, `shared`
- `dashboard`, `server`, `demo`
- `ethereum`, `bitcoin`, `solana`
- `nillion`, `payment`, `channel`, `settlement`, `swap`

### Examples

```bash
# Good commits
git commit -m "feat(payment): add voucher expiry validation"
git commit -m "fix(nillion): handle MPC timeout gracefully"
git commit -m "docs(contributing): add commit message examples"
git commit -m "test(channel): add integration tests for edge cases"

# Bad commits
git commit -m "fix bug"           # Too vague
git commit -m "WIP"               # Work in progress (squash before PR)
git commit -m "asdf"              # Non-descriptive
```

### Breaking Changes

If your commit introduces a breaking change, add `BREAKING CHANGE:` to the footer:

```
feat(protocol)!: change voucher message format

BREAKING CHANGE: VoucherMessage now uses bytes instead of string for signature.
Clients must update to protocol v2.0.0.
```

---

## Pull Request Process

### Before Creating PR

1. ✅ **All tests pass** (`pnpm run test`)
2. ✅ **No TypeScript errors** (`pnpm run typecheck`)
3. ✅ **No linting errors** (`pnpm run lint`)
4. ✅ **Code is formatted** (`pnpm run format`)
5. ✅ **Branch is up-to-date** with main
6. ✅ **Commits are clean** (squash WIP commits)

### Creating the PR

1. **Push your branch:**
   ```bash
   git push origin feat/your-feature-name
   ```

2. **Create PR on GitHub** with this template:

   ```markdown
   ## Description
   Brief description of what this PR does and why.

   ## Type of Change
   - [ ] Bug fix (non-breaking change fixing an issue)
   - [ ] New feature (non-breaking change adding functionality)
   - [ ] Breaking change (fix or feature causing existing functionality to change)
   - [ ] Documentation update

   ## Related Issues
   Fixes #123
   Related to #456

   ## Testing
   - [ ] Unit tests added/updated
   - [ ] Integration tests added/updated
   - [ ] Manual testing completed
   - [ ] Performance benchmarks run (if applicable)

   ## Checklist
   - [ ] Code follows project coding standards
   - [ ] TypeScript strict mode passes
   - [ ] All tests pass
   - [ ] Documentation updated
   - [ ] No breaking changes (or documented in CHANGELOG)

   ## Screenshots (if UI changes)
   <add screenshots here>
   ```

3. **Request review** from relevant team members

### PR Review Process

1. **CI must pass** - All GitHub Actions workflows must succeed
2. **Code review** - At least 1 approval required
3. **Address feedback** - Make requested changes
4. **Squash commits** if needed (keep history clean)
5. **Merge** when approved and CI passes

### Auto-Merge Criteria

PRs will auto-merge if:
- ✅ All CI checks pass
- ✅ At least 1 approval
- ✅ No merge conflicts
- ✅ Dependabot PRs (patch/minor only)

---

## Epic Development

### Epic Branch Strategy

Each Epic (from the PRD) has its own long-lived branch:

```
main
├── epic-1-ethereum          # Weeks 1-6
├── epic-2-bitcoin           # Weeks 7-9
├── epic-3-solana            # Weeks 10-12
├── epic-4-cross-chain       # Weeks 13-16
└── epic-5-sdk               # Weeks 17-18
```

### Working on Epics

1. **Create feature branch from Epic branch:**
   ```bash
   git checkout epic-1-ethereum
   git pull upstream epic-1-ethereum
   git checkout -b feat/connext-integration
   ```

2. **Develop and test:**
   - Work on your feature
   - Push to your fork
   - Create PR targeting **Epic branch** (not main!)

3. **Epic-specific testing:**
   ```bash
   # Tests automatically run for Epic branches
   git push origin feat/connext-integration
   # → Triggers epic-test-matrix.yml workflow
   ```

4. **Epic completion:**
   - When Epic complete, create PR: `epic-1-ethereum` → `main`
   - Requires comprehensive testing and stakeholder approval

### Epic Testing Matrix

Each Epic branch triggers chain-specific tests:

| Epic | Branch | Tests Enabled |
|------|--------|---------------|
| Epic 1 | `epic-1-ethereum` | Ethereum only |
| Epic 2 | `epic-2-bitcoin` | Bitcoin only |
| Epic 3 | `epic-3-solana` | Solana only |
| Epic 4 | `epic-4-cross-chain` | All chains + swaps |

**See:** `.github/workflows/epic-test-matrix.yml`

---

## Coding Standards

### Critical Rules (Never Violate)

1. **Type Sharing:** Define types in `packages/shared`, import everywhere
   ```typescript
   // ✅ GOOD
   import { PaymentChannel } from '@nillion/shared/types';

   // ❌ BAD
   interface PaymentChannel { /* duplicate definition */ }
   ```

2. **API Calls:** Use service layer, never direct fetch
   ```typescript
   // ✅ GOOD
   const channels = await apiClient.getChannels();

   // ❌ BAD
   const res = await fetch('/api/channels');
   ```

3. **Environment Variables:** Access via config objects only
   ```typescript
   // ✅ GOOD
   import { config } from './config/env';
   const apiKey = config.INFURA_PROJECT_ID;

   // ❌ BAD
   const apiKey = process.env.INFURA_PROJECT_ID;
   ```

4. **Error Handling:** Use standard error handler
   ```typescript
   // ✅ GOOD
   throw new VoucherExpiredError(voucherId);

   // ❌ BAD
   throw new Error('expired'); // Non-specific
   ```

5. **State Updates:** Never mutate Zustand state directly
   ```typescript
   // ✅ GOOD
   useDashboardStore.getState().updateMetrics({ latency: 50 });

   // ❌ BAD
   useDashboardStore.getState().performanceMetrics.latency = 50;
   ```

6. **Database Transactions:** All payment/channel updates in transactions
   ```typescript
   // ✅ GOOD
   await db.transaction().execute(async (trx) => {
     await trx.insertInto('payments').values(payment).execute();
     await trx.updateTable('channels').set({ nonce }).execute();
   });

   // ❌ BAD - race condition possible!
   await db.insertInto('payments').values(payment).execute();
   await db.updateTable('channels').set({ nonce }).execute();
   ```

### Frontend-Specific Standards

- ✅ **Use shadcn/ui components** - Don't reinvent common components
- ✅ **Tailwind for styling** - No CSS-in-JS (Emotion, Styled Components)
- ✅ **Server Components by default** - Use `'use client'` only when needed
- ✅ **Accessibility** - All interactive elements keyboard accessible
- ✅ **Responsive design** - Test mobile, tablet, desktop

### Backend-Specific Standards

- ✅ **Repository pattern** - Separate data access from business logic
- ✅ **Structured logging** - Use Pino logger, never console.log
- ✅ **Input validation** - Zod schemas for all API inputs
- ✅ **Async/await** - No callbacks, use Promises
- ✅ **Error middleware** - Let Fastify error handler catch exceptions

---

## Testing Requirements

### Coverage Thresholds

| Package/App | Minimum Coverage |
|-------------|-----------------|
| `client-sdk` | 80% |
| `server-sdk` | 80% |
| `nillion-adapter` | 80% |
| `shared` | 90% |
| `server` (business logic) | 85% |
| `dashboard` (components) | 70% |

### Test Types Required

For each new feature, provide:

1. **Unit tests** - Test pure functions and classes in isolation
2. **Integration tests** - Test with real PostgreSQL + Redis (Testcontainers)
3. **Manual E2E flows** - Document in `tests/e2e/` if applicable

### Writing Good Tests

**Arrange-Act-Assert pattern:**

```typescript
describe('Feature', () => {
  it('should do something specific', () => {
    // Arrange: Set up test data
    const input = { amount: 1000n };

    // Act: Execute the code under test
    const result = doSomething(input);

    // Assert: Verify expected outcome
    expect(result).toBe(expected);
  });
});
```

**Test naming:**
- Describe behavior, not implementation
- Use `should` language: "should reject expired vouchers"
- Be specific: "should update channel nonce after payment"

---

## Documentation

### When to Update Documentation

Update docs when you:
- Add new API endpoints (update OpenAPI spec)
- Change Protocol Buffer schemas (update .proto + comments)
- Modify architecture (update `docs/architecture.md`)
- Add configuration options (update `.env.example`)
- Fix bugs (update troubleshooting section)

### Documentation Standards

- ✅ **Code comments:** Explain WHY, not WHAT
  ```typescript
  // ✅ GOOD
  // Pre-sign vouchers during handshake to avoid MPC latency on hot path
  const vouchers = await nillion.preSignVouchers(100);

  // ❌ BAD
  // Get 100 vouchers
  const vouchers = await nillion.preSignVouchers(100);
  ```

- ✅ **JSDoc for public APIs:**
  ```typescript
  /**
   * Process a micropayment using a pre-signed Nillion voucher.
   *
   * @param channelId - Payment channel UUID
   * @param amount - Payment amount in smallest unit (wei/satoshi/lamport)
   * @param voucherId - Pre-selected voucher from pool
   * @returns Payment result with updated balances
   * @throws VoucherExpiredError if voucher past 1-hour TTL
   * @throws InsufficientBalanceError if amount exceeds channel balance
   */
  export async function processPayment(
    channelId: string,
    amount: bigint,
    voucherId: string
  ): Promise<PaymentResult> {
    // Implementation
  }
  ```

- ✅ **README updates:** Keep examples up-to-date with code changes
- ✅ **Architecture docs:** Update diagrams if component boundaries change

---

## Pull Request Process

### PR Checklist

Before submitting, verify:

- [ ] Branch is up-to-date with target branch
- [ ] All tests pass locally
- [ ] TypeScript compiles with no errors
- [ ] Linting passes with no warnings
- [ ] Code is formatted (Prettier)
- [ ] New code has tests (80%+ coverage)
- [ ] Documentation updated (if applicable)
- [ ] No console.log statements (use logger)
- [ ] No commented-out code
- [ ] No TODO comments (create GitHub issues instead)
- [ ] Performance impact considered (benchmark if critical path)

### Review Guidelines

**As a PR author:**
- Respond to feedback within 24-48 hours
- Ask questions if feedback unclear
- Update PR with requested changes
- Mark resolved conversations

**As a reviewer:**
- Review within 48 hours if possible
- Be constructive and specific
- Approve if meets standards (minor issues OK)
- Request changes for critical issues only
- Test locally for complex changes

### Merge Strategies

- **Squash and merge:** Default for feature branches (clean history)
- **Merge commit:** For Epic → main merges (preserve Epic history)
- **Rebase:** Never (causes issues with collaborative branches)

---

## Common Tasks

### Adding a New Package

1. Create directory: `packages/your-package/`
2. Add package.json (see existing packages for template)
3. Add to `pnpm-workspace.yaml` (if not matching `packages/*` pattern)
4. Add to `turbo.json` tasks if needed
5. Document in README.md

### Adding a New Dependency

```bash
# Add to specific package
pnpm add <package> --filter=client-sdk

# Add to root (DevOps tools)
pnpm add -D <package> -w

# Add to all packages (rare)
pnpm add <package> -r
```

### Updating Database Schema

1. Create migration: `pnpm run migrate:create description`
2. Edit generated SQL file in `migrations/`
3. Test migration: `pnpm run migrate`
4. Test rollback: `pnpm run migrate:rollback`
5. Update Kysely types (re-run codegen if using)
6. Update architecture doc if schema fundamentally changed

### Adding Protocol Buffer Message

1. Edit relevant `.proto` file in `packages/protocol/proto/`
2. Regenerate types: `pnpm run proto:generate`
3. Update `stream.proto` to include new message in `StreamMessage` oneof
4. Add TypeScript wrapper in `packages/protocol/src/` if needed
5. Update API documentation

---

## Performance Considerations

### Before Optimizing

- ✅ **Measure first** - Use benchmarks to identify bottlenecks
- ✅ **Profile** - Use Node.js profiler for CPU, memory leaks
- ✅ **Focus on critical path** - Payment processing latency (<100ms target)

### Performance Rules

- ✅ **No synchronous operations** on critical path (use async)
- ✅ **Cache aggressively** - Redis for vouchers, TanStack Query for API
- ✅ **Async database writes** - Don't block payment responses
- ✅ **Batch where possible** - Settlements, database inserts
- ✅ **Index database queries** - Check `EXPLAIN ANALYZE` plans

### Running Benchmarks

```bash
# Run performance benchmarks
pnpm run benchmark

# Validate targets (<100ms, 1000 pkt/sec)
node scripts/validate-benchmarks.js
```

---

## Security Guidelines

### Sensitive Data

- ❌ **Never commit:**
  - Private keys
  - API keys
  - Passwords
  - .env files (only .env.example)
  - Wallet files

- ✅ **Always:**
  - Use environment variables
  - Add sensitive patterns to .gitignore
  - Redact secrets in logs (Pino redaction)
  - Use GitHub Secrets for CI/CD

### Security Review Required

These changes require security review:
- Authentication/authorization logic
- Cryptographic operations
- Payment verification logic
- Database access patterns
- External API integrations

---

## Release Process

### Versioning

We follow **Semantic Versioning (semver)**:
- `MAJOR.MINOR.PATCH`
- `1.0.0` → `1.0.1` (patch: bug fixes)
- `1.0.0` → `1.1.0` (minor: new features, backward compatible)
- `1.0.0` → `2.0.0` (major: breaking changes)

### Release Checklist

- [ ] All Epic tests pass
- [ ] Performance benchmarks meet targets
- [ ] Security audit completed (for major releases)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in all affected packages
- [ ] Git tag created: `git tag v1.0.0`

---

## Questions and Support

### Getting Help

- 📖 **Documentation:** [docs/](docs/)
- 💬 **Discussions:** GitHub Discussions tab
- 🐛 **Bug Reports:** GitHub Issues
- 💡 **Feature Requests:** GitHub Issues (use template)

### Asking Good Questions

When asking for help:
- ✅ Include error messages (full stack trace)
- ✅ Describe what you tried
- ✅ Share relevant code snippets
- ✅ Specify your environment (OS, Node version, package versions)
- ✅ Link to relevant docs you've already read

**Example:**

```
**Problem:** Getting "Voucher expired" error in tests

**What I tried:**
1. Set mock voucher expiry to +1 hour
2. Checked system time matches test time
3. Verified timezone handling

**Error:**
VoucherExpiredError: Voucher nillion_abc123 has expired
  at processPayment (payment-processor.ts:45)

**Environment:**
- Node.js 18.19.0
- macOS 14.3
- Package: @nillion/server-sdk@1.0.0

**Relevant code:**
[code snippet]
```

---

## Recognition

Contributors are recognized in:
- Git commit history (your commits stay attributed)
- Release notes (CHANGELOG.md)
- README.md (major contributions)

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Additional Resources

- 🏗️ [Architecture Guide](docs/architecture.md) - System design and decisions
- 📋 [Architecture Checklist](docs/architecture/architecture-checklist.md) - Validation checklist
- 📝 [Product Requirements](docs/prd/index.md) - PRD with epics
- 🎨 [Frontend Spec](docs/front-end-spec.md) - UI/UX guidelines
- 🔗 [WebSocket Protocol](packages/protocol/proto/stream.proto) - Binary protocol spec

---

**Thank you for contributing to the future of micropayments! 🚀**
