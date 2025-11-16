# Tech Stack

This table is the **single source of truth** for all technology decisions. All development must use these exact versions. Any deviation requires architecture review and update to this document.

## Technology Stack Table

| Category | Technology | Version | Purpose | Rationale |
|----------|-----------|---------|---------|-----------|
| **Frontend Language** | TypeScript | 5.3+ | Type-safe frontend development | Strict mode enforced; catches 80% of runtime errors at compile time; shared types with backend via `packages/shared` |
| **Frontend Framework** | Next.js | 14.2+ | React-based dashboard application | App Router for RSC (reduced client bundle), edge runtime support, Vercel optimization, built-in API routes for BFF pattern |
| **UI Component Library** | shadcn/ui | 0.8+ | Accessible UI primitives | Radix UI underneath (WAI-ARIA compliant), copy-paste customization (no node_modules lock-in), TypeScript-first, minimal bundle impact |
| **State Management** | Zustand | 4.5+ | Lightweight global state | 1KB vs Redux 20KB, perfect for dashboard real-time metrics, built-in DevTools, TypeScript inference, no boilerplate |
| **Backend Language** | TypeScript | 5.3+ | Type-safe backend development | Same language as frontend (shared types), Node.js 18+ WebCrypto API support required for Nillion integration |
| **Backend Framework** | Fastify | 4.26+ | High-performance HTTP + WebSocket server | 2× faster than Express, native TypeScript support, schema-based validation (for protobuf), WebSocket plugin for binary framing |
| **API Style** | WebSocket (Binary Protocol Buffers) + REST | Custom + OpenAPI 3.0 | Real-time payments + query API | WebSocket for <100ms bidirectional streaming, REST for dashboard queries/analytics (cacheable at edge) |
| **Database** | PostgreSQL | 15.6+ | Relational data persistence | ACID guarantees for payment channel state, JSON columns for flexible voucher metadata, battle-tested for financial systems |
| **Time-Series Extension** | TimescaleDB | 2.14+ | Metrics and performance data | Hypertables for latency/throughput time-series, automatic partitioning, 10-100× compression vs raw PostgreSQL |
| **Cache** | Redis | 7.2+ | In-memory voucher pool | <1ms lookup required for 1000 pkt/sec target, Pub/Sub for multi-instance coordination (production), persistence for crash recovery |
| **File Storage** | N/A (Nillion Private Storage) | - | Encrypted voucher backup | Nillion Private Storage replaces traditional S3/blob storage; distributed MPC shares prevent single-point compromise |
| **Authentication** | Wallet Connection (wagmi + RainbowKit) | wagmi 2.5+, RainbowKit 2.0+ | Ethereum wallet authentication | Web3 native auth (no passwords), supports MetaMask/WalletConnect/Coinbase, auto-detects networks, TypeScript SDK |
| **Frontend Testing** | Vitest + React Testing Library | Vitest 1.3+, RTL 14.2+ | Component and integration testing | 10× faster than Jest (ESM native), compatible with Jest API, React Testing Library for accessible testing patterns |
| **Backend Testing** | Vitest + Testcontainers | Vitest 1.3+, Testcontainers 10.6+ | Unit and integration testing | Same test runner as frontend (shared config), Testcontainers for PostgreSQL/Redis in CI, no mocking databases |
| **E2E Testing** | Manual (MVP), Playwright (Production) | Playwright 1.42+ (future) | End-to-end user flows | Manual testing sufficient for PoC (<4 hour integration target), Playwright deferred to Week 19-22 production hardening |
| **Build Tool** | Turborepo | 1.12+ | Monorepo task orchestration | Intelligent caching (6-10× faster CI), parallel builds across packages, remote cache support for team collaboration |
| **Bundler** | Next.js (Turbopack) + tsup | Turbopack (built-in), tsup 8.0+ | Application and package bundling | Next.js uses Turbopack (Rust-based, 700× faster than Webpack), tsup for library packages (esbuild-based, outputs ESM+CJS) |
| **Package Manager** | pnpm | 8.15+ | Dependency management | 3× faster than npm, disk space efficient (content-addressed store), strict workspace protocol, lockfile prevents phantom deps |
| **IaC Tool** | Railway CLI + Docker Compose | Railway CLI 3.x, Docker Compose 2.24+ | Infrastructure provisioning | Railway CLI for MVP deployment, Docker Compose for local multi-service dev environment, migrate to Terraform (Prod) |
| **CI/CD** | GitHub Actions | N/A | Automated testing and deployment | Free for public repos, Turborepo remote cache integration, parallel matrix builds for 3 chains, Vercel/Railway deploy actions |
| **Monitoring** | Vercel Analytics + Railway Metrics (MVP), Datadog (Prod) | Datadog 7.x (future) | Performance and error tracking | Vercel built-in for frontend vitals, Railway metrics for backend, Datadog for production APM + distributed tracing |
| **Logging** | Pino | 8.19+ | Structured JSON logging | 5× faster than Winston, JSON output for log aggregation, built-in log levels, redaction for sensitive data (private keys) |
| **CSS Framework** | Tailwind CSS | 3.4+ | Utility-first styling | Purges unused CSS (10KB final bundle), JIT compiler, consistent with shadcn/ui, responsive prefixes, dark mode built-in |
| **CSS-in-JS** | N/A (Tailwind only) | - | Avoid runtime CSS cost | Tailwind handles 95% of needs; no Emotion/Styled Components (add 10-20KB + runtime cost) |
| **Linting** | ESLint + TypeScript ESLint | ESLint 8.57+, TS-ESLint 7.0+ | Code quality enforcement | Catch bugs before runtime, enforce coding standards, accessibility linting (jsx-a11y), shared config in packages/config |
| **Formatting** | Prettier | 3.2+ | Consistent code formatting | Auto-format on save, shared config, integrates with ESLint, prevents style debates |
| **Protobuf Compiler** | protobuf-ts | 2.9+ | Protocol Buffer TypeScript generation | Generates type-safe TypeScript from .proto files, runtime encoding/decoding, supports proto3 features, integrates with tsup |
| **Blockchain - Ethereum** | ethers.js | 6.11+ | Ethereum contract interaction | Industry standard, v6 adds native TypeScript, Connext Vector SDK dependency, supports Optimism L2 |
| **Blockchain - Bitcoin** | LND (via @radar/lnrpc) | LND 0.17+, lnrpc 0.3+ | Lightning Network integration | Official LND gRPC client, TypeScript bindings, supports channel management + payment routing, testnet compatible |
| **Blockchain - Solana** | @solana/web3.js | 1.91+ | Solana RPC and transactions | Official Solana SDK, supports state channels (experimental), anchor program integration, devnet compatible |
| **Nillion SDK** | @nillion/client-js (assumed) | TBD | Nillion Private Compute/Storage | **CRITICAL BLOCKER**: Requires partnership and SDK access; fallback to mock adapter for local dev if unavailable |
| **WebSocket Library** | ws (via Fastify plugin) | 8.16+ | Binary WebSocket server | Native Node.js implementation, integrates with Fastify, supports binary frames (protobuf), backpressure handling |
| **Validation** | Zod | 3.22+ | Runtime type validation | TypeScript-first schema validation, integrates with tRPC/Fastify, validates protobuf decoded objects, error messages |
| **Date/Time** | date-fns | 3.3+ | Date manipulation | Tree-shakeable (vs moment.js 200KB), TypeScript support, no global locale pollution, FP style |
| **Charting** | Recharts | 2.12+ | Dashboard data visualization | React-first, composable charts (line/area/bar), responsive, accessible (ARIA labels), smaller than Chart.js |
| **ORM/Query Builder** | Kysely | 0.27+ | Type-safe SQL query builder | End-to-end type safety (schema → queries → results), no magic (raw SQL visible), PostgreSQL dialect, TimescaleDB compatible |
| **Migration Tool** | node-pg-migrate | 6.2+ | Database schema versioning | JavaScript-based migrations, rollback support, works with Kysely, Railway CLI integration |
| **HTTP Client** | native fetch (Node 18+) | Built-in | HTTP requests to Infura/Alchemy | Node 18+ includes fetch; no axios needed (saves 30KB), matches browser API, supports AbortController |

---
