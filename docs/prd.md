# Nillion-Powered Web-Native Micropayment Protocol Product Requirements Document (PRD)

**Project Status:** PRD Complete - Ready for Architecture & UX Design
**PRD Version:** 1.0
**Last Updated:** November 16, 2025
**Based on:** Project Brief v2.0 (500+ pages research foundation)

---

## Goals and Background Context

### Goals

Based on the Project Brief, here are the desired outcomes for this PRD:

- Deliver a working PoC of Nillion-powered pre-signed voucher architecture achieving <100ms p95 latency and 1000+ pkt/sec throughput
- Enable privacy-preserving high-frequency micropayments via Nillion MPC signatures without sacrificing real-time performance
- Validate economic viability of $12k/month cost structure (200× cheaper than naive per-packet MPC)
- Demonstrate crash-resilient agent payment systems using Nillion Private Storage for voucher backup/recovery
- Achieve developer integration time <4 hours from SDK install to working Nillion-signed payment demo
- Prove cross-chain interoperability across Ethereum L2, Bitcoin Lightning, and Solana using unified Nillion voucher architecture
- Secure Nillion partnership with favorable pricing (<$0.001/operation) to enable production viability

### Background Context

The micropayment problem has existed for 25+ years without viable solution. Traditional payment processors like Stripe impose 2.9% + $0.30 fees that make sub-$10 payments economically impossible (a $0.01 transaction would incur 3,100% overhead). Existing blockchain solutions suffer from slow finality (10min-24hr) or poor UX (Lightning Network requires node operation, lacks privacy with 70% deanonymization risk). Web Monetization showed the right developer experience but failed due to centralized dependencies (Coil shutdown 2023).

This PRD addresses the market gap by leveraging **Nillion's MPC technology to solve the "privacy vs performance" paradox**. The core innovation: pre-sign 100 vouchers via Nillion Private Compute during handshake (10 seconds, acceptable one-time cost), then serve them from memory during streaming (0.001ms, instant). Every packet gets Nillion MPC signatures with full privacy guarantees while achieving real-time performance. Nillion Private Storage provides crash recovery for autonomous agents, and monetary threshold-based settlements ($100, $1000) keep settlement costs economical while maintaining confidential on-chain amounts.

The PoC targets Nillion ecosystem developers building agent-to-agent payment systems and privacy-critical M2M applications where client-side key storage is unacceptable and MPC-signed payments are mission-critical.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|---------|
| 2025-11-16 | 1.0 | Initial PRD creation based on Project Brief v2.0 | John (PM Agent) |

---

## Requirements

### Functional Requirements

**FR1:** The system shall pre-sign 100 vouchers via Nillion Private Compute during WebSocket handshake in <30 seconds with each voucher cryptographically bound to session (nonce, amount limit, expiry).

**FR2:** The system shall store pre-signed Nillion vouchers in-memory with <0.01ms access time during streaming payment phase.

**FR3:** The system shall backup all pre-signed vouchers to Nillion Private Storage during handshake in <5 seconds for crash recovery.

**FR4:** The system shall retrieve and restore session state from Nillion Private Storage in <10 seconds after crash with zero voucher loss.

**FR5:** The system shall attach a Nillion MPC-signed voucher to each outbound payment packet during streaming phase.

**FR6:** The system shall verify Nillion MPC signatures on incoming payment packets with cryptographic validation.

**FR7:** The system shall trigger automated settlement via Nillion Private Compute when accumulated balance reaches configurable monetary thresholds ($10, $100, $1000, $10000).

**FR8:** The system shall sign settlement batches via Nillion Private Compute for privacy-preserving on-chain verification with settlement amounts confidential on blockchain.

**FR9:** The system shall integrate Connext Vector payment channels for Ethereum Optimism with full lifecycle support (open, fund, update, close).

**FR10:** The system shall sustain 1,000 packets/second for 60 seconds with Nillion-signed vouchers achieving <100ms p95 latency.

**FR11:** The system shall provide JavaScript/TypeScript SDK installable via `npm install @nillion/micropayments` with complete "Hello World" payment example in <15 lines of code.

**FR12:** The system shall provide monitoring dashboard displaying real-time Nillion voucher depletion, MPC signing latency, and Nillion Storage recovery events.

**FR13:** The system shall implement Bitcoin Lightning Network integration with Nillion voucher pre-signing during channel setup and HTLC compatibility.

**FR14:** The system shall implement Solana state channel integration with Nillion voucher pre-signing and program deployment to Solana devnet.

**FR15:** The system shall support cross-chain atomic swaps between all 3 chain pairs (BTC↔ETH, BTC↔SOL, ETH↔SOL) using Nillion MPC-signed swap primitives.

**FR16:** The system shall provide route discovery algorithm to find optimal payment path from any source chain to any destination chain.

**FR17:** The system shall integrate real-time exchange rate oracle (Chainlink for ETH, Pyth for SOL) for cross-chain swap pricing.

**FR18:** The system shall handle cross-chain swap rollback with Nillion-signed refunds if atomic swap fails.

**FR19:** The system shall provide unified SDK API abstracting all 3 chains with identical developer experience (`chains: ['optimism', 'lightning', 'solana']`).

**FR20:** The system shall auto-handle voucher pre-signing, Nillion Storage backup, and MPC settlements without requiring developer intervention beyond SDK configuration.

### Non-Functional Requirements

**NFR1:** The system shall achieve <100ms p95 latency for end-to-end payment confirmation in controlled environment (target: <50ms).

**NFR2:** The system shall achieve <200ms p99 latency including edge cases and geographic outliers.

**NFR3:** The system shall sustain 1,000+ packets/second throughput per WebSocket connection (target: 5,000+ pkt/sec).

**NFR4:** The system shall achieve >99% settlement success rate on-chain without manual intervention (target: 99.9%).

**NFR5:** The system shall maintain >99.9% payment channel uptime excluding scheduled maintenance (target: 99.99%).

**NFR6:** The system shall limit cost per session to <$0.20 using Nillion vouchers + settlement at hypothetical $0.001/operation pricing.

**NFR7:** The system shall complete developer integration from SDK install to working demo in <4 hours for external Nillion developers.

**NFR8:** The system shall provide TypeScript type definitions with full autocomplete support for all SDK methods.

**NFR9:** The system shall handle Nillion Private Compute signing failures with retry logic (3 attempts) and fallback to client signing if Nillion unavailable.

**NFR10:** The system shall hide Nillion MPC complexity from developers with clear error messages (e.g., "Nillion signing in progress..." instead of cryptographic jargon).

**NFR11:** The system shall achieve <500ms cross-chain payment latency including atomic swap and dual channel updates.

**NFR12:** The system shall operate exclusively on testnets (Optimism testnet, Bitcoin testnet, Solana devnet) until security audit completion.

**NFR13:** The system shall use only audited cryptographic libraries and Nillion MPC primitives with no custom cryptography implementation.

**NFR14:** The system shall provide comprehensive error handling with chain-specific failure messages avoiding blockchain jargon for developer clarity.

**NFR15:** The system shall support graceful WebSocket reconnection with session restoration from Nillion Private Storage.

---

## User Interface Design Goals

### Overall UX Vision

The user experience should feel like **"Stripe for micropayments"** — invisible to end users during streaming, transparent and informative for developers. The wallet extension should mimic MetaMask's familiarity (one-time install, persistent background process) while the monitoring dashboard should provide Stripe-quality observability into Nillion operations. Core principle: **hide Nillion MPC complexity, surface payment value and privacy benefits**.

Target users tolerate 10-second handshake delay (one-time per session) because they understand it enables privacy-preserving payments. Developers get real-time visibility into Nillion voucher consumption, MPC signing events, and settlement triggers without needing to understand underlying cryptography.

### Key Interaction Paradigms

- **Auto-streaming payments:** Once wallet funded and channel open, payments flow automatically during API consumption with no per-transaction user confirmation (learned from Web Monetization success pattern)
- **Threshold-based notifications:** Users receive alerts at meaningful monetary milestones ($800 accumulated = 80% of $1000 threshold approaching) rather than technical events
- **Dashboard-driven debugging:** Developers troubleshoot payment issues via web UI showing Nillion-specific metrics (voucher depletion graphs, MPC latency spikes, Storage recovery events) not CLI logs
- **Progressive disclosure:** SDK hides Nillion by default (`new NillionMicropaymentServer({ ratePerPacket: '0.01' })`), exposes advanced MPC config only for power users

### Core Screens and Views

**Developer-Facing:**
1. **Monitoring Dashboard** — Real-time graphs of Nillion voucher usage, MPC signing latency, payment success/failure rates, settlement events with monetary thresholds
2. **SDK Documentation Site** — Interactive examples, TypeScript API reference, Nillion-specific troubleshooting guides
3. **Channel Management UI** — View open channels across all 3 chains (ETH/BTC/SOL), balance per channel, settlement history
4. **Cross-Chain Routing Visualizer** — See payment path from source to destination chain with fees and latency per hop

**End-User Facing:**
1. **Wallet Extension Popup** — Current balance across all chains, running total of session spend, top-up prompt when low
2. **Payment History** — Log of all micropayments with merchant, amount, timestamp, chain used
3. **Channel Funding Flow** — Guided wizard to open and fund payment channels (one-time setup, target <30 seconds)
4. **Privacy Indicator** — Visual badge showing "Nillion MPC Privacy Active" when vouchers being used vs "Standard Privacy" fallback

### Accessibility

**WCAG AA compliance** for dashboard and wallet extension:
- Keyboard navigation for all dashboard interactions (developers may use screen readers)
- Color contrast ratios ≥4.5:1 for text, 3:1 for UI components
- Screen reader support for payment alerts and balance updates
- No reliance on color alone for status indication (voucher depletion uses icons + text + color)

**Rationale:** Developer tools increasingly expected to be accessible (GitHub, Stripe meet WCAG AA). End-user wallet should match MetaMask accessibility standards.

### Branding

**Developer-Facing (SDK/Dashboard):**
- Clean, technical aesthetic similar to Stripe Dashboard or Vercel Analytics
- Nillion brand colors for MPC-specific UI elements (voucher graphs, privacy indicators)
- Monospace fonts for code examples and transaction IDs
- Dark mode support (developer preference, reduce eye strain during debugging)

**End-User Facing (Wallet):**
- Familiar Web3 wallet paradigm (MetaMask-inspired for adoption)
- Privacy-first visual language (locks, shields for Nillion MPC features)
- Minimal cognitive load (large numbers for balance, clear call-to-action buttons)

**No existing style guide provided** — will need design system definition in UX Expert phase.

### Target Device and Platforms

**Web Responsive** for all developer-facing interfaces:
- Desktop primary (1920×1080, 1366×768 common developer resolutions)
- Tablet secondary (iPad for dashboard monitoring on the go)
- Mobile tertiary (phone access to dashboard metrics acceptable but not optimized)

**Browser Extension** for end-user wallet:
- Chrome, Firefox, Safari, Edge (95%+ browser coverage)
- Responsive to extension popup size constraints (340×600px typical)

**No mobile apps (iOS/Android) in MVP scope** — deferred to Phase 2 per Project Brief constraints.

---

## Technical Assumptions

### Repository Structure

**Monorepo** using Turborepo or Nx:

**Rationale:** The project requires tight coordination between client SDK, server SDK, shared Protocol Buffer definitions, and demonstration apps. Monorepo enables:
- Shared TypeScript types across packages (Nillion voucher interfaces, payment channel state)
- Atomic commits across SDK breaking changes
- Unified versioning for coherent releases
- Single CI/CD pipeline for all 3 chain integrations

**Structure:**
```
/packages/client-sdk        # Browser/Node.js TypeScript client
/packages/server-sdk        # Node.js server for payment verification
/packages/protocol          # Shared Protocol Buffer definitions
/packages/nillion-adapter   # Nillion Private Compute/Storage integration layer
/apps/demo                  # Example integration for developer testing
/apps/dashboard             # Monitoring UI (Next.js)
/docs                       # Developer documentation site
```

**Trade-off:** Monorepo adds tooling complexity (Turborepo config, workspace management) but justified by multi-package coordination needs and cross-chain Epic structure where all 3 integrations share core voucher logic.

### Service Architecture

**Hybrid: Monolithic Node.js server (MVP) → Microservices (Production)**

**MVP Architecture (Week 1-18):**
- Single Node.js service handling WebSocket gateway + payment channel manager + Nillion integration + settlement logic
- Stateful in-memory voucher storage with Redis backup
- PostgreSQL for payment channel state persistence
- TimescaleDB extension for metrics time-series

**Rationale for Monolith:** PoC requires rapid iteration; microservices overhead (service mesh, inter-service communication, distributed tracing) not justified for 1,000 pkt/sec target on single connection. Simpler deployment, easier debugging during Epic 1-5 development.

**Production Architecture (Week 19+):**
- **WebSocket Gateway** (edge-deployed, Cloudflare Workers or AWS Lambda@Edge for <50ms latency)
- **Payment Channel Manager** (stateful, centralized, manages Nillion voucher pools and channel lifecycle)
- **Settlement Service** (batch processor, low frequency, triggers Nillion MPC signing on monetary thresholds)
- **Monitoring Service** (separate for scaling, collects metrics from all services)

**Rationale for Microservices:** Production scale (10,000+ developers, 50,000 sessions) requires independent scaling; edge deployment for WebSocket gateway reduces latency 6-10× (15ms US-US vs 100ms single-region).

**Critical Decision:** Architect must design monolith with clean service boundaries (separate modules for WebSocket, Nillion, settlement) to enable microservices extraction post-MVP without rewrite.

### Testing Requirements

**Unit + Integration + Manual E2E Testing**

**Unit Testing (Jest, 80%+ coverage target):**
- All SDK public methods (client + server)
- Nillion voucher serialization/deserialization logic
- Payment verification cryptography (Nillion signature validation)
- Settlement threshold calculation logic
- Cross-chain routing path discovery algorithm

**Integration Testing (Testcontainers for dependencies):**
- Full payment flow: handshake → voucher generation → streaming → settlement
- Nillion Private Compute mocked integration (test voucher pre-signing without live Nillion API)
- Nillion Private Storage backup/recovery scenarios (crash simulation)
- Connext Vector channel lifecycle on local testnet
- WebSocket reconnection and session restoration

**Manual E2E Testing (Human-verified on testnets):**
- External developer integration (<4 hour target validation)
- Cross-chain atomic swaps across all 3 pairs (BTC↔ETH, BTC↔SOL, ETH↔SOL)
- Dashboard UI verification (Nillion metrics, graphs, alerts)
- Wallet extension install and channel funding UX
- Performance benchmarking under load (1,000 pkt/sec, latency measurement)

**Manual Testing Convenience Methods:**
- CLI commands for common test scenarios (`npm run test:payment-flow`, `npm run test:crash-recovery`)
- Test faucets for Optimism/Bitcoin/Solana testnet funding
- Mock Nillion SDK for local development without live API access
- WebSocket test client with configurable throughput and latency injection

**Rationale:** Full testing pyramid required for production deployment with mainnet funds at risk. Manual E2E necessary because cross-chain interactions involve external systems (Nillion API, blockchain testnets) that cannot be fully mocked. Convenience methods critical for external developer testing in Epic 5 validation.

**NO automated E2E in MVP scope** — Playwright/Cypress for wallet extension deferred to production hardening (Week 19-22) due to time constraints.

### Additional Technical Assumptions and Requests

**Languages & Frameworks:**
- **Primary:** TypeScript (strict mode, Node.js 18+ for WebCrypto API support)
- **Frontend Framework:** Next.js 14 for dashboard (App Router, React Server Components)
- **Wallet Extension:** Vanilla TypeScript with browser WebExtensions API (avoid framework overhead in extension bundle)
- **Backend:** Express or Fastify for HTTP/WebSocket server (Fastify preferred for performance)

**Nillion Integration (CRITICAL):**
- **Assumption:** Nillion SDK provides TypeScript/JavaScript bindings for Private Compute and Private Storage
- **IF NO SDK:** Architect must design REST API bridge layer to Nillion services with authentication
- **Voucher Format:** Architect defines binary format for Nillion-signed vouchers (Protocol Buffer schema for voucher_id, nonce, amount_limit, expiry, mpc_signature)
- **Fallback Strategy:** Client-side signing mode activates automatically if Nillion Private Compute unavailable (degrades privacy, maintains payments)

**Blockchain Integration:**
- **Ethereum L2:** Connext Vector SDK for state channels on Optimism testnet (ethers.js v6 for contract interaction)
- **Bitcoin Lightning:** LND (Lightning Network Daemon) via gRPC API or CLN (Core Lightning) via JSON-RPC (evaluate both in Epic 2 Week 1)
- **Solana:** Solana Web3.js + evaluate state channel libraries (Saber, Streamflow) or build custom program (decision gate at Epic 3 start)
- **Blockchain RPC:** Infura (Ethereum), Alchemy (Ethereum backup), public Bitcoin testnet nodes, Solana devnet RPC (avoid running own nodes in MVP)

**Serialization:**
- **Wire Format:** Protocol Buffers v3 (1.3% overhead, compact binary)
- **Alternative Considered:** FlatBuffers (zero-copy deserialization, but more complex schema evolution)
- **Rationale:** ProtoBuf mature, excellent TypeScript support, smaller bundle than FlatBuffers tooling

**Database:**
- **Primary:** PostgreSQL 15+ (JSON columns for flexible payment channel state, TimescaleDB extension for metrics)
- **Caching:** Redis 7+ (in-memory voucher pool, <1ms lookup for hot path)
- **Time-Series:** TimescaleDB hypertables for latency metrics, payment volume trends

**Hosting/Infrastructure (MVP):**
- **PoC:** Single-region cloud (Railway preferred for cost + DX, AWS/GCP acceptable)
- **Testnets:** Optimism Sepolia, Bitcoin testnet, Solana devnet
- **CI/CD:** GitHub Actions (test all 3 chain integrations in parallel, Epic 1-3 independent test suites)

**Security:**
- **Transport:** TLS 1.3 mandatory for all WebSocket connections (reject non-TLS in production config)
- **Key Management:** Nillion MPC handles all signing (no client-side private keys in browser localStorage)
- **Voucher Security:** In-memory hot storage (cleared on server restart) + Nillion Private Storage backup (distributed shares, no single-point compromise)
- **Payment Channel Security:** 24-hour challenge period for fraud proofs (standard Connext Vector configuration)
- **Audit:** External security audit required before mainnet (budgeted $15k-25k for Week 19-22)

**Dependencies & APIs:**
- **Nillion Private Compute API** (CRITICAL MVP BLOCKER — requires partnership and testnet access)
- **Nillion Private Storage API** (CRITICAL for crash recovery feature)
- **Chainlink Price Feeds** (ETH/USD for cross-chain oracle, Epic 4)
- **Pyth Network** (SOL/USD for Solana cross-chain oracle, Epic 4)
- **No custom MPC cryptography** — only audited libraries (libsodium for Ed25519, Nillion SDK for MPC)

**Build & Deployment:**
- **Package Manager:** pnpm (faster than npm, better monorepo support than yarn)
- **Build Tool:** Turborepo for monorepo orchestration, esbuild for fast TypeScript compilation
- **Docker:** Dockerfile for server deployment (single container in MVP, multi-container in production)
- **Environment Management:** dotenv for local, Railway/AWS Secrets Manager for production

**Performance Constraints:**
- **Latency Budget:** <100ms p95 end-to-end (15-50ms network, 0.02ms signing, 0.001ms voucher lookup, <50ms overhead budget)
- **Memory Footprint:** <50MB client SDK bundle, <500MB server process (excluding database)
- **CPU Usage:** <5% client CPU during streaming (background signing must not block UI)
- **Throughput:** 1,000 pkt/sec sustained (target 5,000 pkt/sec for headroom)

**Data Schema & Persistence (Architect Responsibility):**

Per PRD guidance, detailed data schema design is deferred to the Architect. The following areas require architectural design:

1. **PostgreSQL Schema:**
   - Payment channel state tables (channel ID, participants, balances, nonces, state transitions)
   - Settlement history (batch records, transaction IDs, amounts, timestamps)
   - Session management (active sessions, voucher associations, crash recovery checkpoints)
   - Indexes strategy (query performance for channel lookups, settlement history, session restoration)

2. **Redis Key Structure:**
   - Voucher pool keys (per-session in-memory cache, expiry TTLs)
   - Channel state cache (hot path lookups, invalidation strategy)
   - Rate limiting keys (API throttling, Nillion quota tracking)

3. **TimescaleDB Hypertables:**
   - Metrics time-series (latency measurements, throughput counters, MPC signing duration)
   - Payment volume tracking (transactions per second, USD volume, success/failure rates)
   - Dashboard aggregations (per-chain metrics, cross-chain swap analytics)
   - Retention policies (how long to retain fine-grained metrics vs aggregated rollups)

**Architect Deliverable:** Entity-Relationship Diagram (ERD), table schemas with columns/types/constraints, index strategy, Redis key naming conventions, TimescaleDB hypertable partitioning strategy.

**Discovered During Drafting:**
- **Cross-chain routing algorithm selection:** Dijkstra's shortest path for 3-node graph (BTC, ETH, SOL) with edge weights = fees + latency
- **Voucher expiry strategy:** 1-hour TTL per voucher (prevents replay attacks, forces periodic handshake for long sessions)
- **Settlement batch size:** Dynamic batching based on monetary threshold (Epic 4: $10/$100/$1000 tiers) NOT packet count (avoids arbitrary technical limits)
- **WebSocket heartbeat:** 30-second ping/pong to detect dead connections and trigger Nillion Storage recovery

---

## Epic List

### Epic 1: Nillion Core + Ethereum Optimism Foundation (Week 1-6)

**Goal:** Establish foundational project infrastructure (monorepo, CI/CD, core services) while delivering the first fully functional Nillion-powered micropayment system on Ethereum Optimism. Validate all 3 core Nillion features (voucher pre-signing, Private Storage backup, MPC settlements) achieving <100ms p95 latency and 1000+ pkt/sec throughput.

**Value Delivered:** Complete end-to-end payment flow on one blockchain (Optimism) with Nillion privacy guarantees. External Nillion developers can integrate SDK and process real micropayments on testnet. Proves economic viability ($0.20/session cost target) and performance targets before multi-chain expansion.

---

### Epic 2: Bitcoin Lightning Network Integration (Week 7-9)

**Goal:** Extend Nillion voucher architecture to Bitcoin Lightning Network, demonstrating compatibility with UTXO-based chains and HTLC payment primitives. Enable developers to accept micropayments on Bitcoin while maintaining Nillion MPC privacy throughout the payment flow.

**Value Delivered:** Second payment rail (Bitcoin) expands addressable market to Bitcoin-native developers and demonstrates Nillion voucher portability beyond EVM chains. Independent test suite validates Epic 2 works in isolation without Epic 1 dependencies, proving modular architecture.

---

### Epic 3: Solana State Channel Integration (Week 10-12)

**Goal:** Implement Nillion-powered micropayments on Solana using state channels, leveraging Solana's high-performance runtime for potential throughput optimization. Deploy state channel program to Solana devnet with full lifecycle testing and monetary threshold settlements.

**Value Delivered:** Third payment rail (Solana) completes multi-chain vision and targets Solana's agent/DeFi ecosystem. All 3 major blockchain ecosystems (EVM, UTXO, Solana runtime) now support Nillion-signed micropayments, demonstrating maximum interoperability.

---

### Epic 4: Cross-Chain Payment Routing (Week 13-16)

**Goal:** Enable payments to flow seamlessly across all 3 chains (ETH ↔ BTC ↔ SOL) using ILP-inspired routing with Nillion MPC-signed atomic swaps. Implement route discovery, exchange rate oracles, and rollback handling for failed cross-chain transactions.

**Value Delivered:** Developers can accept payments on any chain regardless of user's funding source (user funded on Bitcoin can pay Ethereum-based API). Nillion MPC signatures secure atomic swaps, providing privacy-preserving cross-chain settlement with amounts confidential throughout the swap process.

---

### Epic 5: Unified SDK & Developer Experience (Week 17-18)

**Goal:** Abstract all chain-specific complexity behind a single SDK API where developers specify `chains: ['optimism', 'lightning', 'solana']` and routing happens automatically. Deliver comprehensive documentation, monitoring dashboard with unified multi-chain view, and validate <4 hour integration time with external developers.

**Value Delivered:** Production-ready developer experience matching "Stripe for micropayments" vision. External Nillion developers successfully integrate in <4 hours each (3 developers tested), documentation complete with tutorials for each chain and cross-chain examples. MVP ready for production hardening phase.

---

## Epic 1: Nillion Core + Ethereum Optimism Foundation

**Expanded Goal:**

Establish foundational project infrastructure including monorepo setup, GitHub Actions CI/CD pipeline, and core development tooling, while simultaneously delivering the first fully functional Nillion-powered micropayment system on Ethereum Optimism. Validate all 3 critical Nillion features (voucher pre-signing via Private Compute, crash recovery via Private Storage backup, and privacy-preserving settlements via MPC signing) achieving <100ms p95 latency and 1000+ pkt/sec throughput. This epic serves as both project foundation and proof-of-concept for Nillion partnership viability.

---

### Story 1.0: Nillion SDK Validation Spike

**As a** technical lead planning Nillion integration,
**I want** validation of Nillion SDK TypeScript support and capabilities,
**so that** I can design appropriate integration strategy (direct SDK vs API bridge) before implementing voucher architecture.

#### Acceptance Criteria

1. **Nillion SDK Research:** Contact Nillion partnership team, review documentation, confirm TypeScript/JavaScript SDK availability for Private Compute and Private Storage
2. **API Capabilities Validation:** Verify SDK supports: voucher pre-signing (batch MPC operations), Storage backup/retrieval (distributed shares), settlement signing (MPC batch signatures)
3. **Performance Benchmarking:** If SDK available, run simple benchmark measuring: MPC signing latency (target ~100ms per operation), Storage retrieval latency (target 200-500ms), SDK initialization time
4. **Integration Decision:** Document decision: **Option A - Direct SDK Integration** (if TypeScript SDK available) OR **Option B - REST API Bridge** (if SDK unavailable or non-JavaScript language)
5. **API Bridge Design:** If Option B chosen, design REST API bridge layer architecture: authentication strategy, endpoint design (/vouchers/presign, /storage/backup, /settlements/sign), error handling, retry logic
6. **Timeline Impact Assessment:** If API bridge required, document 2-3 week additional timeline impact for Epic 1 (adjust decision gate expectations)
7. **Spike Report:** 1-page summary with decision, rationale, integration approach, timeline impact shared with stakeholders
8. **Completion Deadline:** Week 1 Day 3 (allows pivot early if API bridge needed)

---

### Story 1.1: Project Foundation & Monorepo Setup

**As a** developer joining the project,
**I want** a fully configured monorepo with TypeScript, testing infrastructure, and CI/CD pipeline,
**so that** I can immediately start building features without spending days on tooling setup.

#### Acceptance Criteria

1. Monorepo initialized with Turborepo or Nx containing 5 package workspaces (`/packages/client-sdk`, `/packages/server-sdk`, `/packages/protocol`, `/packages/nillion-adapter`, `/apps/demo`)
2. TypeScript strict mode configured across all packages with shared `tsconfig.json` base extending to package-specific configs
3. Jest testing framework configured with coverage reporting (80%+ target), supports both unit and integration tests
4. GitHub Actions CI/CD pipeline runs on every push: lint → type-check → test → build across all packages in parallel
5. pnpm workspace configuration enables cross-package dependencies (e.g., server-sdk depends on protocol package)
6. README.md includes quickstart guide: clone → `pnpm install` → `pnpm dev` → see demo app running
7. Development scripts available: `pnpm test`, `pnpm build`, `pnpm lint`, `pnpm type-check` work from monorepo root
8. ESLint and Prettier configured with shared rules, auto-format on commit via husky git hooks

---

### Story 1.2: Protocol Buffer Schema Definition

**As a** developer building the payment system,
**I want** Protocol Buffer schemas defining all payment message types,
**so that** client and server can communicate with compact binary serialization and type-safe message contracts.

#### Acceptance Criteria

1. Protocol Buffer v3 schema file (`packages/protocol/proto/payment.proto`) defines: `HandshakeRequest`, `HandshakeResponse`, `PaymentPacket`, `SettlementRequest`, `SettlementResponse` messages
2. `PaymentPacket` message includes fields: `voucher_id`, `nonce`, `amount`, `timestamp`, `nillion_signature` (bytes), `metadata` (JSON)
3. `NillionVoucher` message defined with fields: `voucher_id`, `session_id`, `amount_limit`, `expiry_timestamp`, `mpc_signature` (bytes)
4. Code generation produces TypeScript types in `packages/protocol/src/generated/` via `protoc` compiler with `ts-proto` plugin
5. Generated TypeScript types exported from `packages/protocol/index.ts` for consumption by client-sdk and server-sdk packages
6. Binary serialization/deserialization achieves <1.3% overhead compared to raw JSON (validated via benchmark test)
7. Schema versioning strategy documented: breaking changes require new major version, backward-compatible changes increment minor version
8. Example usage documented showing encode/decode of `PaymentPacket` in both client and server contexts

---

### Story 1.3: Nillion Private Compute Mock Adapter

**As a** developer building payment features,
**I want** a mock Nillion Private Compute adapter for local development,
**so that** I can develop and test voucher pre-signing logic without requiring live Nillion API access.

#### Acceptance Criteria

1. `NillionComputeAdapter` interface defined with methods: `preSignVouchers(count: number, sessionId: string)`, `signSettlement(batch: Settlement)`
2. `MockNillionCompute` implementation simulates 100ms latency per voucher pre-signing operation matching research findings
3. Mock generates valid-looking Ed25519 signatures (actual crypto, but using test keys not Nillion MPC)
4. `RealNillionCompute` implementation stub created with TODO comments indicating Nillion SDK integration points
5. Configuration flag `NILLION_MODE=mock|real` switches between implementations, mock enabled by default for local dev
6. Mock adapter tracks call history for testing: verify `preSignVouchers` called exactly once during handshake
7. Error simulation mode: mock can be configured to fail intermittently (tests retry logic)
8. Mock performance matches real Nillion: 100 vouchers × 100ms = 10 seconds total pre-signing time

---

### Story 1.4: Nillion Private Storage Mock Adapter

**As a** developer implementing crash recovery,
**I want** a mock Nillion Private Storage adapter,
**so that** I can test voucher backup/restore logic without live Nillion Storage API access.

#### Acceptance Criteria

1. `NillionStorageAdapter` interface defined with methods: `storeVouchers(vouchers: Voucher[])`, `retrieveVouchers(sessionId: string)`, `deleteVouchers(sessionId: string)`
2. `MockNillionStorage` implementation uses in-memory Map for storage, simulates 200-500ms retrieval latency
3. Mock persists data across test runs using local filesystem JSON file (`.nillion-mock-storage/`) to simulate distributed storage
4. `RealNillionStorage` implementation stub created with TODO comments for Nillion Storage SDK integration
5. Configuration flag `NILLION_STORAGE_MODE=mock|real` switches implementations, mock default for local dev
6. Mock simulates distributed shares concept: stored vouchers split into 3 JSON files representing different "nodes"
7. Mock can simulate storage failures (test error handling): network timeout, insufficient nodes available, quota exceeded
8. Backup operation completes in <5 seconds for 100 vouchers (validates NFR requirement)

---

### Story 1.5: In-Memory Voucher Pool with Redis Backup

**As a** payment server processing streaming payments,
**I want** an in-memory voucher pool with <0.01ms access time,
**so that** I can pop pre-signed Nillion vouchers during hot path without blocking payment flow.

#### Acceptance Criteria

1. `VoucherPool` class implemented with in-memory array storing pre-signed Nillion vouchers per session
2. `pop()` method retrieves next voucher from pool with O(1) complexity, measured <0.01ms via benchmark test
3. `getRemaining()` method returns count of unused vouchers, triggers warning log at 20% threshold (20 remaining)
4. `refill()` method calls Nillion adapter to pre-sign additional vouchers when pool depletes to 10% (background operation)
5. Redis integration: pool state synced to Redis on every 10 voucher consumption for crash recovery
6. Memory footprint validation: 100 vouchers × 200 bytes = 20 KB per session (measured via process.memoryUsage())
7. Thread-safe pop operation: concurrent requests don't retrieve same voucher (use atomic decrement pattern)
8. Pool expiry handling: vouchers with expired TTL (>1 hour old) automatically discarded on pop attempt

---

### Story 1.6: WebSocket Server with Binary Framing

**As a** developer building the payment transport layer,
**I want** a WebSocket server supporting binary Protocol Buffer messages,
**so that** I can stream payments with 1,000+ pkt/sec throughput and minimal serialization overhead.

#### Acceptance Criteria

1. Fastify server created with `@fastify/websocket` plugin, listens on port 3000 (configurable via env var)
2. WebSocket connection handler implements handshake phase: client sends `HandshakeRequest`, server responds with `HandshakeResponse` containing 100 Nillion vouchers
3. Binary message framing: all messages serialized via Protocol Buffers, received as ArrayBuffer and deserialized to typed objects
4. Heartbeat mechanism: server sends ping every 30 seconds, disconnects client if no pong received within 10 seconds
5. Connection state management: track session ID, associated voucher pool, payment channel reference per WebSocket connection
6. Throughput validation: sustain 1,000 messages/sec for 60 seconds without backpressure (tested via load script)
7. Graceful shutdown: server waits for in-flight messages to complete before closing on SIGTERM signal
8. Error handling: malformed Protocol Buffer messages logged and connection closed with error code 4000 (protocol violation)

---

### Story 1.7: Connext Vector Payment Channel Integration

**As a** payment system developer,
**I want** Connext Vector payment channel integration on Optimism testnet,
**so that** I can open, update, and settle payment channels with off-chain state updates and on-chain finality.

#### Acceptance Criteria

1. Connext Vector node deployed to Optimism Sepolia testnet, running as Docker container locally for development
2. `PaymentChannelManager` class wraps Connext SDK with methods: `openChannel(amount: string)`, `updateChannel(payment: Payment)`, `closeChannel(channelId: string)`
3. Channel open operation completes with <$5 transaction fee on Optimism L2 (validated by checking actual gas cost)
4. Off-chain state updates: 1,000+ channel updates executed without on-chain transactions (proves state channel working)
5. Channel close operation triggers on-chain settlement with batch verification of all off-chain payments
6. Circular rebalancing implemented: when channel balance low, trigger atomic swap to rebalance instead of close/reopen
7. Channel monitoring: emit events for `channelOpened`, `channelUpdated`, `channelClosed`, `balanceLow` (80% depleted)
8. Error handling: detect and handle challenge period violations, insufficient balance, channel already closed scenarios

---

### Story 1.8: Payment Verification with Nillion Signature Validation

**As a** payment server receiving streaming payments,
**I want** cryptographic verification of Nillion MPC signatures on every payment packet,
**so that** I can confirm payment authenticity before delivering API response.

#### Acceptance Criteria

1. `PaymentVerifier` class implements `verify(packet: PaymentPacket): boolean` using Nillion public key to validate MPC signature
2. Signature verification achieves <0.02ms latency (measured via benchmark, validates latency budget)
3. Verification checks: signature matches packet contents, voucher not expired (TTL <1 hour), voucher not already used (replay protection)
4. Nonce validation: each voucher can only be used once, duplicate nonce causes verification failure
5. Amount validation: payment amount ≤ voucher amount_limit, overpayment attempts rejected
6. Verification failure modes logged with specific error codes: INVALID_SIGNATURE (4001), EXPIRED_VOUCHER (4002), REPLAY_ATTACK (4003), AMOUNT_EXCEEDED (4004)
7. Performance under load: verification sustains 1,000 verifications/sec without CPU bottleneck (target <5% CPU usage per NFR)
8. Mock Nillion signatures validated correctly in test mode, real Nillion signatures validated in production mode

---

### Story 1.9: Monetary Threshold Settlement Trigger

**As a** payment system operator,
**I want** automatic settlement triggered when accumulated balance reaches monetary thresholds,
**so that** I can batch payments economically without arbitrary packet count limits.

#### Acceptance Criteria

1. `SettlementTrigger` class monitors accumulated balance per payment channel, supports configurable thresholds: $10, $100, $1000, $10000
2. When balance reaches threshold (e.g., $100.00), automatically invoke Nillion Private Compute to sign settlement batch
3. Settlement batch includes: channel ID, total amount, payment count, timestamp, Nillion MPC signature
4. On-chain settlement transaction submitted to Optimism testnet with Nillion-signed batch, achieves <$0.50 gas cost via circular rebalancing
5. Settlement amounts confidential: on-chain observers cannot determine batch amount from transaction data (Nillion privacy property)
6. Notification emitted on settlement completion: `settlementCompleted` event with amount, transaction hash, Nillion signing latency
7. Low-balance warnings: emit `balanceWarning` event at 80% of threshold (e.g., $80 accumulated toward $100 threshold)
8. Retry logic: if Nillion signing fails, retry 3 times with exponential backoff, fallback to client signing if Nillion unavailable after 3 attempts

---

### Story 1.10: Crash Recovery via Nillion Private Storage

**As a** payment system ensuring fault tolerance,
**I want** automatic session restoration from Nillion Private Storage after server crash,
**so that** in-progress payment sessions resume without voucher loss or user disruption.

#### Acceptance Criteria

1. On server startup, check for orphaned sessions in Nillion Private Storage (sessions with active vouchers but no running WebSocket connection)
2. Retrieve vouchers from Nillion Storage via `retrieveVouchers(sessionId)` in <10 seconds (validates NFR requirement)
3. Restore voucher pool to in-memory state, resume WebSocket connection at last checkpoint (payment count, balance)
4. Client reconnection flow: client detects disconnect, reconnects with session ID, server responds with "session restored" message
5. Zero voucher loss validation: crash simulation test (kill server process mid-payment) followed by restart shows all 100 vouchers accounted for
6. Performance test: crash recovery completes in <10 seconds from client reconnect to first successful payment after restore
7. Cleanup logic: delete vouchers from Nillion Storage after successful session completion (channel closed, no pending payments)
8. Monitoring: log crash recovery events with metrics (recovery duration, vouchers restored, payments resumed)

---

### Story 1.11: Client SDK with Nillion Voucher Management

**As a** developer integrating micropayments into my application,
**I want** a JavaScript/TypeScript client SDK that handles Nillion voucher management automatically,
**so that** I can accept payments with <15 lines of code without understanding MPC cryptography.

#### Acceptance Criteria

1. `@nillion/micropayments` package published to npm (or private registry for testing), installable via `npm install @nillion/micropayments`
2. Client SDK API: `new MicropaymentClient({ serverUrl, chains: ['optimism'], nillion: { enabled: true } })` initializes connection
3. Payment sending: `await client.sendPayment({ amount: '0.01', metadata: { apiCall: 'generate-text' } })` attaches Nillion voucher automatically
4. Voucher handshake: SDK requests 100 Nillion vouchers from server during initial connection, stores in-memory for hot path
5. Automatic refill: when client detects 20% vouchers remaining (20 left), request new batch from server in background
6. TypeScript types: full autocomplete support for all SDK methods, payment objects, configuration options
7. Error handling: clear error messages like "Nillion signing in progress, please wait..." instead of cryptographic stack traces
8. Example documentation: README includes "Hello World" example completing first payment in <15 lines of code

---

### Story 1.12: Basic Monitoring Dashboard

**As a** developer debugging payment issues,
**I want** a web dashboard showing Nillion-specific metrics in real-time,
**so that** I can visualize voucher consumption, MPC signing latency, and settlement events.

#### Acceptance Criteria

1. Next.js dashboard app (`/apps/dashboard`) deployed locally at http://localhost:3001, connects to WebSocket server metrics endpoint
2. **Nillion Voucher Depletion Graph:** Line chart showing remaining vouchers per session over time, updates every 5 seconds
3. **MPC Signing Latency Tracking:** Histogram showing Nillion signing latency for handshake (voucher generation) and settlements, p50/p95/p99 percentiles displayed
4. **Nillion Storage Events:** Log view showing backup success, recovery events with timestamps and session IDs
5. **Transaction Success/Failure Counts:** Real-time counter showing successful payments, failed verifications with Nillion-specific error codes (INVALID_SIGNATURE, EXPIRED_VOUCHER, etc.)
6. **Settlement Timeline:** Visual timeline showing when monetary thresholds triggered settlements, amount settled, Nillion signing duration
7. Responsive design: works on desktop (1920×1080 primary), tablet secondary, mobile tertiary per UI goals
8. Dark mode support: toggle between light/dark theme matching developer tool preferences

---

### Story 1.13: Performance Benchmarking Under Load

**As a** technical lead validating PoC success,
**I want** automated performance benchmarks measuring latency and throughput,
**so that** I can prove <100ms p95 latency and 1,000+ pkt/sec targets are met.

#### Acceptance Criteria

1. Load testing script (`/packages/server-sdk/benchmarks/load-test.ts`) uses WebSocket client to simulate 1,000 pkt/sec sustained load
2. Latency measurement: record timestamp at client send, receive server response, calculate round-trip time for each packet
3. Benchmark report outputs p50, p95, p99 latency percentiles plus min/max values after 60-second test run
4. Throughput validation: confirm 60,000 total packets sent/received in 60-second window (1,000 pkt/sec average)
5. Resource monitoring: capture server CPU usage, memory footprint, voucher pool access time during load test
6. Pass/fail criteria: p95 latency <100ms AND sustained 1,000+ pkt/sec throughput = PASS (logs "✅ Epic 1 Performance Target MET")
7. Geographic latency simulation: artificially inject 15-50ms network delay to simulate US-US, US-EU latency variance
8. Benchmark CI integration: GitHub Actions runs benchmark on every PR to main branch, fails build if performance regresses >10%

---

### Story 1.14: External Developer Integration Testing

**As a** product manager validating developer experience,
**I want** external Nillion developers to attempt SDK integration with time tracking,
**so that** I can validate <4 hour integration time goal before declaring Epic 1 success.

#### Acceptance Criteria

1. Recruit 3 external Nillion developers (from Nillion Discord, not project contributors) for integration testing
2. Provide developers with: SDK npm package, documentation README, Optimism testnet faucet access, server endpoint URL
3. Track time from `npm install @nillion/micropayments` to first successful Nillion-signed payment received
4. Success criteria: 2 out of 3 developers complete integration in <4 hours (target from MVP goals)
5. Feedback collection: structured survey asking about pain points, unclear documentation, Nillion-specific confusion
6. Documentation improvements: incorporate feedback into README, add FAQ section addressing common issues discovered
7. Friction log: record every point where developer got stuck (missing error message, unclear config, Nillion jargon)
8. Final validation: after doc improvements, recruit 1 additional developer for confirmation test (should complete in <3 hours)

---

### Story 1.15: Epic 1 Decision Gate Validation

**As a** project stakeholder deciding GO/NO-GO on Nillion partnership,
**I want** comprehensive Epic 1 success criteria validation report,
**so that** I can make informed decision whether to proceed to Epic 2 based on objective data.

#### Acceptance Criteria

1. **Criterion 1 - Nillion Integration Complete:** Document all 3 Nillion features working (voucher pre-signing ✅, Storage backup ✅, MPC settlements ✅) with test evidence
2. **Criterion 2 - Performance Target Met:** Benchmark report shows <100ms p95 latency for 1,000 pkt/sec sustained over 60 seconds using Nillion vouchers
3. **Criterion 3 - Privacy Validation:** Verification test confirms Nillion MPC signatures on every packet + settlement amounts confidential on-chain (blockchain explorer screenshot)
4. **Criterion 4 - Crash Recovery Works:** Crash simulation test video showing Nillion Storage successfully restores session after server kill in <10 sec recovery time
5. **Criterion 5 - Ethereum Optimism Complete:** Full channel lifecycle documented: open → stream 1000 pkts → settle → close with transaction hashes on Optimism Sepolia
6. **Criterion 6 - Developer Experience Validated:** 2 out of 3 external Nillion developers completed integration in <4 hours (survey results attached)
7. **Criterion 7 - Economic Viability Proven:** Cost calculation shows Nillion costs <$0.20 per session (100 vouchers × $0.001 + settlement $0.10) at hypothetical pricing
8. **GO Decision:** If all 7 criteria met, document GO recommendation for Epic 2 (Bitcoin Lightning). If 0-4 criteria met, document NO-GO recommendation with pivot options

---

## Epic 2: Bitcoin Lightning Network Integration (Week 7-9)

**Expanded Goal:**

Extend the Nillion voucher architecture to Bitcoin Lightning Network, demonstrating compatibility with UTXO-based payment channels and HTLC (Hash Time-Locked Contract) primitives. Enable developers to accept Nillion MPC-signed micropayments on Bitcoin while maintaining <100ms p95 latency and 1,000+ pkt/sec throughput. Prove that Nillion vouchers are blockchain-agnostic and can secure payments on both account-based (Ethereum) and UTXO-based (Bitcoin) systems. This epic validates architectural portability and expands addressable market to Bitcoin-native developers.

---

### Story 2.1: Lightning Network Node Deployment

**As a** developer building Bitcoin Lightning integration,
**I want** a Lightning Network node (LND or CLN) running on Bitcoin testnet,
**so that** I can open Lightning channels, route HTLCs, and settle payments to Bitcoin L1.

#### Acceptance Criteria

1. Evaluate both LND (Lightning Network Daemon) and CLN (Core Lightning) via feature comparison matrix and performance benchmarks
2. Deploy selected Lightning implementation (LND or CLN) as Docker container on Bitcoin testnet with persistent storage for channel database
3. Node synced to Bitcoin testnet with confirmed connection to 5+ peers (validates network connectivity)
4. REST API (LND) or JSON-RPC API (CLN) accessible from payment server, authenticated via macaroon or token
5. Test channel operations via CLI: `lncli openchannel`, `lncli sendpayment`, `lncli closechannel` all complete successfully
6. Monitoring exposed: node metrics (peer count, channel count, balance) accessible via API for dashboard integration
7. Backup configuration: Lightning channel state backed up to local filesystem every 10 minutes (disaster recovery)
8. Documentation: README includes Lightning node setup instructions, fund testnet wallet via faucet, verify sync status

---

### Story 2.2: Lightning Payment Channel Manager

**As a** payment system integrating Lightning,
**I want** a Lightning-specific payment channel manager wrapping LND/CLN APIs,
**so that** I can open, fund, route payments, and close Lightning channels with consistent interface matching Connext integration.

#### Acceptance Criteria

1. `LightningChannelManager` class implements interface matching `PaymentChannelManager` from Epic 1 for consistency
2. `openChannel(peerPubkey: string, amount: satoshis)` opens Lightning channel, waits for 3 confirmations on Bitcoin testnet
3. `fundChannel(channelId: string, amount: satoshis)` adds additional funds to existing channel via cooperative transaction
4. `routePayment(invoice: string, amount: satoshis)` routes HTLC payment through Lightning Network with automatic route discovery
5. `closeChannel(channelId: string, force: boolean)` closes channel cooperatively (default) or force-closes if peer unresponsive
6. Channel state monitoring: emit events for `channelOpened`, `htlcForwarded`, `channelClosed`, `balanceLow` (80% depleted)
7. Error handling: detect insufficient inbound liquidity, routing failures, HTLC timeout scenarios with specific error codes
8. Integration tests: full channel lifecycle (open → route 100 HTLCs → close) validated on Bitcoin testnet with transaction IDs logged

---

### Story 2.3: Nillion Voucher Integration with Lightning HTLCs

**As a** payment system developer,
**I want** Nillion pre-signed vouchers attached to Lightning HTLC payments,
**so that** every Lightning micropayment carries Nillion MPC signature for privacy-preserving verification.

#### Acceptance Criteria

1. Extend `PaymentPacket` Protocol Buffer schema with Lightning-specific fields: `htlc_hash`, `htlc_expiry`, `lightning_invoice`
2. During handshake, pre-sign 100 Nillion vouchers specifically for Lightning session (same voucher format, different session context)
3. Client SDK attaches Nillion voucher to HTLC payment metadata via Lightning invoice custom TLV records (Type-Length-Value)
4. Server extracts Nillion voucher from received HTLC payment metadata, verifies MPC signature before settling HTLC
5. HTLC compatibility validation: confirm Nillion MPC signatures (Ed25519) compatible with Lightning BOLT specifications
6. Voucher binding: each voucher cryptographically bound to specific HTLC via hash lock (prevents voucher reuse across different HTLCs)
7. Performance validation: voucher attachment adds <1ms overhead to HTLC creation (measured via benchmark)
8. Edge case handling: if HTLC times out before settlement, voucher marked as unused and returned to pool for reuse

---

### Story 2.4: Lightning-Specific Monitoring Dashboard

**As a** developer debugging Lightning payment issues,
**I want** Lightning-specific metrics added to monitoring dashboard,
**so that** I can visualize channel balance, routing fees, HTLC status alongside Nillion voucher metrics.

#### Acceptance Criteria

1. **Channel Balance Graph:** Real-time chart showing local/remote balance for all open Lightning channels, updates every 10 seconds
2. **Routing Fee Tracker:** Display cumulative routing fees paid for outbound HTLCs, breakdown by channel
3. **HTLC Status View:** Table showing in-flight HTLCs with hash, expiry countdown, Nillion voucher ID attached, settlement status
4. **Lightning Node Health:** Node sync status, peer count, total channel capacity displayed in dashboard header
5. **Nillion+Lightning Integration Metrics:** Combined view showing vouchers consumed per Lightning payment, average HTLC latency with Nillion signature verification
6. **Settlement Timeline:** Lightning settlements (to Bitcoin L1) shown on same timeline as Ethereum settlements from Epic 1
7. Responsive design: Lightning metrics fit into existing dashboard layout without horizontal scroll
8. Dark mode: Lightning-specific charts use consistent color scheme with Epic 1 dashboard components

---

### Story 2.5: Lightning Performance Benchmarking

**As a** technical lead validating Epic 2 success,
**I want** Lightning-specific performance benchmarks,
**so that** I can prove <100ms payment confirmation and 1,000 pkt/sec throughput on Lightning Network.

#### Acceptance Criteria

1. Lightning load test script routes 1,000 HTLC payments/second through Lightning channel with Nillion vouchers attached
2. Latency measurement: record time from HTLC creation to settlement confirmation, target <100ms p95 latency
3. Throughput validation: sustain 1,000 HTLC payments/second for 60 seconds (60,000 total payments) without channel capacity exhaustion
4. Comparison benchmark: measure Lightning performance with vs without Nillion voucher attachment (quantify overhead)
5. Benchmark report outputs: p50/p95/p99 latency percentiles, total routing fees paid, Nillion signing overhead percentage
6. Pass/fail criteria: p95 latency <100ms AND sustained 1,000+ pkt/sec throughput = PASS (Epic 2 performance target met)
7. Resource monitoring: Lightning node CPU usage, memory footprint, channel database size during load test
8. CI integration: GitHub Actions runs Lightning benchmark on Epic 2 PRs, validates performance doesn't regress

---

### Story 2.6: Monetary Threshold Settlements to Bitcoin L1

**As a** Lightning payment system operator,
**I want** automatic settlement from Lightning channels to Bitcoin L1 triggered by monetary thresholds,
**so that** I can batch Lightning payments economically using same threshold architecture as Ethereum.

#### Acceptance Criteria

1. Extend `SettlementTrigger` from Epic 1 to support Lightning channels with same thresholds: $10, $100, $1000, $10000
2. When Lightning channel balance reaches threshold (e.g., $1000 accumulated), trigger cooperative channel close to Bitcoin testnet
3. Settlement signed by Nillion Private Compute: batch of Lightning payments collapsed to single Bitcoin transaction with MPC signature
4. Bitcoin settlement transaction visible on blockchain explorer (mempool.space or similar) with transaction ID logged
5. Settlement cost tracking: measure actual Bitcoin L1 transaction fees, validate <$0.50 target for testnet (lower than Ethereum L2)
6. Notification: emit `lightningSettlementCompleted` event with amount settled, Bitcoin txid, Nillion signing latency
7. Low-balance warnings: emit `balanceWarning` at 80% of threshold (e.g., $800 accumulated toward $1000 threshold)
8. Retry logic: if Bitcoin network congested (mempool full), retry settlement with higher fee after 10 minutes, max 3 retries

---

### Story 2.7: Epic 2 Independent Test Suite

**As a** developer ensuring Epic 2 modularity,
**I want** comprehensive test suite validating Lightning integration works in isolation,
**so that** I can prove Epic 2 succeeds without depending on Epic 1 Ethereum components.

#### Acceptance Criteria

1. Test suite runs Lightning integration tests (`pnpm test:epic-2`) without importing any Epic 1 Ethereum/Connext code
2. Unit tests: Lightning channel manager, HTLC routing, Nillion voucher attachment/extraction, settlement triggers (80%+ coverage)
3. Integration tests: Lightning node interaction, channel lifecycle (open → route → close), Nillion signature verification in HTLC context
4. End-to-end test: complete payment flow from client SDK → Lightning HTLC → Nillion verification → Bitcoin L1 settlement (all on testnet)
5. Mock dependencies: Ethereum components mocked/stubbed, tests validate Lightning works standalone
6. CI pipeline: Epic 2 tests run in separate GitHub Actions job, passes independently of Epic 1 test status
7. Performance regression tests: Lightning benchmark thresholds enforced (p95 <100ms, 1000 pkt/sec), build fails if violated
8. Test documentation: README explains how to run Epic 2 tests in isolation, setup Lightning testnet node for local testing

---

### Story 2.8: Epic 2 Decision Gate Validation

**As a** project stakeholder deciding whether to proceed to Epic 3,
**I want** Epic 2 success criteria validation report,
**so that** I can make informed decision about Solana integration based on Lightning results.

#### Acceptance Criteria

1. **Criterion 1 - Lightning Channel Lifecycle:** Document full lifecycle working: open → fund → route HTLCs → close on Bitcoin testnet with transaction IDs
2. **Criterion 2 - Nillion Voucher Integration:** Verify 100 vouchers pre-signed, successfully attached to Lightning payments, HTLC compatibility confirmed
3. **Criterion 3 - HTLC Compatibility:** Test evidence shows Nillion MPC signatures verified within Lightning HTLC contracts without errors
4. **Criterion 4 - Performance Target:** Benchmark report shows <100ms payment confirmation, 1,000 pkt/sec sustained throughput on Lightning
5. **Criterion 5 - Monetary Settlements:** Screenshot of Bitcoin blockchain explorer showing threshold-based settlements ($100, $1000) to Bitcoin L1
6. **Criterion 6 - Independent Testing:** Epic 2 test suite passes in isolation (GitHub Actions log showing Epic 2 tests green, Epic 1 disabled)
7. **GO Decision (All 6 Criteria Met):** Proceed to Epic 3 (Solana State Channels)
8. **PARTIAL GO (4-5 Criteria Met):** Fix issues identified, allocate 1-week extension, re-validate before Epic 3
9. **NO-GO (0-3 Criteria Met):** Defer Lightning to post-MVP, proceed directly to Epic 3 (Solana), revisit Lightning in Phase 2

---

## Epic 3: Solana State Channel Integration (Week 10-12)

**Expanded Goal:**

Implement Nillion-powered micropayments on Solana blockchain using state channel architecture, leveraging Solana's high-performance runtime (400ms block time) for potential throughput optimization beyond Ethereum and Lightning. Deploy custom state channel program to Solana devnet with full lifecycle support (open, stream, settle, close) and validate Nillion voucher integration on Solana's account-based model. This epic completes the multi-chain vision by proving Nillion vouchers work across all 3 major blockchain paradigms: EVM (Ethereum), UTXO (Bitcoin), and Solana runtime.

---

### Story 3.1: Solana State Channel Library Evaluation

**As a** developer planning Solana integration,
**I want** evaluation of existing Solana state channel libraries,
**so that** I can decide whether to use existing solution or build custom program.

#### Acceptance Criteria

1. Evaluate existing Solana state channel libraries: Saber, Streamflow, or other available options via GitHub research and documentation review
2. Comparison matrix created with criteria: maturity, active maintenance, state channel feature completeness, Nillion voucher compatibility potential, documentation quality
3. Performance benchmarking: if library found, test throughput capability (target 1,000 txn/sec), latency measurement, Solana compute unit consumption
4. Integration complexity assessment: estimate effort to integrate existing library vs custom program development (time/complexity tradeoff)
5. Decision documented: **Use Library X** (if suitable found) OR **Build Custom Program** (if no suitable library)
6. Rationale documented: explain decision based on Epic 3 3-week timeline constraint, Nillion voucher integration requirements
7. If custom program chosen: design document outlines Solana program architecture (accounts structure, instructions, state transitions)
8. Risk assessment: identify risks for chosen approach (library abandonment risk vs custom program development risk)

---

### Story 3.2: Solana Program Development (Custom State Channel)

**As a** developer building Solana integration,
**I want** a custom Solana program implementing state channel primitives,
**so that** I can open, update, and settle payment channels on Solana with Nillion voucher support.

**Note:** This story executes ONLY if Story 3.1 decides "Build Custom Program"

#### Acceptance Criteria

1. Solana program written in Rust using Anchor framework for simplified account management and instruction parsing
2. Program defines 4 instructions: `InitializeChannel`, `UpdateChannel`, `SettleChannel`, `CloseChannel`
3. `InitializeChannel` creates PDA (Program Derived Address) for channel state, initializes balance, participants, nonce
4. `UpdateChannel` accepts off-chain state updates with Nillion voucher signature verification, increments nonce, updates balance
5. `SettleChannel` processes batch settlement when monetary threshold reached, verifies Nillion MPC-signed batch, commits on-chain
6. `CloseChannel` finalizes channel, distributes balances to participants, handles challenge period for fraud proofs
7. Program deployed to Solana devnet with program ID logged, verified via Solana Explorer
8. Integration tests: full program lifecycle tested using Solana test validator with 100+ state updates validated

---

### Story 3.3: Solana State Channel Manager

**As a** payment system integrating Solana,
**I want** Solana-specific channel manager wrapping Solana program interactions,
**so that** I can manage Solana channels with consistent interface matching Epic 1 (Connext) and Epic 2 (Lightning).

#### Acceptance Criteria

1. `SolanaChannelManager` class implements `PaymentChannelManager` interface for cross-chain consistency
2. `openChannel(counterparty: PublicKey, amount: lamports)` invokes `InitializeChannel` instruction, waits for Solana confirmation (400ms avg)
3. `updateChannel(channelId: string, payment: Payment)` sends off-chain state update with Nillion voucher to counterparty
4. `settleChannel(channelId: string)` invokes `SettleChannel` instruction when monetary threshold reached, Nillion batch signature included
5. `closeChannel(channelId: string)` invokes `CloseChannel` instruction, handles cooperative close or challenge period
6. Solana Web3.js integration: use `@solana/web3.js` for RPC communication with Solana devnet nodes
7. Error handling: detect insufficient SOL balance, compute budget exceeded, account not found, signature verification failed
8. Event emissions: `channelOpened`, `channelUpdated`, `channelSettled`, `channelClosed` matching Epic 1/2 patterns

---

### Story 3.4: Nillion Voucher Integration on Solana

**As a** payment system developer,
**I want** Nillion pre-signed vouchers integrated with Solana state channel updates,
**so that** every Solana micropayment carries Nillion MPC signature for privacy-preserving verification.

#### Acceptance Criteria

1. Extend `PaymentPacket` Protocol Buffer schema with Solana-specific fields: `solana_signature`, `pda_address`, `account_state_hash`
2. During handshake, pre-sign 100 Nillion vouchers for Solana session (same voucher architecture, Solana context)
3. Client SDK attaches Nillion voucher to Solana transaction memo field or custom instruction data
4. Solana program extracts Nillion voucher from transaction data, verifies Ed25519 MPC signature on-chain using Solana's ed25519 instruction
5. Voucher binding: each voucher cryptographically bound to specific Solana account state transition (prevents replay across different channels)
6. Solana compute unit optimization: Nillion signature verification consumes <10,000 compute units (stays within transaction limits)
7. Performance validation: voucher attachment adds <1ms overhead to Solana transaction preparation (measured via benchmark)
8. Edge case handling: if Solana transaction fails (e.g., compute budget exceeded), voucher marked unused and returned to pool

---

### Story 3.5: Solana-Specific Monitoring Dashboard

**As a** developer debugging Solana payment issues,
**I want** Solana-specific metrics added to monitoring dashboard,
**so that** I can visualize account state, SOL balance, compute unit usage alongside Nillion voucher metrics.

#### Acceptance Criteria

1. **Solana Account Balance Graph:** Real-time chart showing SOL balance for payment channel PDA, updates every 5 seconds
2. **Compute Unit Tracker:** Display compute units consumed per transaction, identify transactions approaching limit (1.4M units)
3. **Transaction Status View:** Table showing recent Solana transactions with signature, confirmation status, Nillion voucher ID attached
4. **Solana Network Health:** Solana devnet slot height, TPS (transactions per second), epoch progress displayed in dashboard header
5. **Nillion+Solana Integration Metrics:** Combined view showing vouchers consumed per Solana transaction, average confirmation latency with Nillion verification
6. **Settlement Timeline:** Solana settlements shown on unified timeline with Ethereum (Epic 1) and Lightning (Epic 2) settlements
7. Responsive design: Solana metrics integrated into existing dashboard grid without layout breakage
8. Dark mode: Solana-specific charts use consistent purple/teal color scheme (Solana brand colors)

---

### Story 3.6: Solana Performance Benchmarking

**As a** technical lead validating Epic 3 success,
**I want** Solana-specific performance benchmarks,
**so that** I can prove <100ms payment confirmation and 1,000 pkt/sec throughput on Solana devnet.

#### Acceptance Criteria

1. Solana load test script sends 1,000 state channel update transactions/second with Nillion vouchers attached
2. Latency measurement: record time from transaction send to confirmation receipt, target <100ms p95 latency (leveraging Solana's 400ms block time)
3. Throughput validation: sustain 1,000 transactions/second for 60 seconds (60,000 total transactions) without rate limiting
4. Comparison benchmark: measure Solana performance with vs without Nillion voucher verification (quantify on-chain overhead)
5. Benchmark report outputs: p50/p95/p99 latency percentiles, total SOL fees paid, Nillion verification compute unit cost
6. Pass/fail criteria: p95 latency <100ms AND sustained 1,000+ txn/sec throughput = PASS (Epic 3 performance target met)
7. Resource monitoring: Solana devnet RPC rate limits, local compute usage, program account rent costs during load test
8. CI integration: GitHub Actions runs Solana benchmark on Epic 3 PRs (uses Solana test validator for deterministic results)

---

### Story 3.7: Monetary Threshold Settlements to Solana L1

**As a** Solana payment system operator,
**I want** automatic settlement from state channels to Solana L1 triggered by monetary thresholds,
**so that** I can batch Solana payments economically using same threshold architecture as Ethereum and Lightning.

#### Acceptance Criteria

1. Extend `SettlementTrigger` to support Solana channels with same thresholds: $10, $100, $1000, $10000
2. When Solana channel balance reaches threshold (e.g., $1000 accumulated), trigger `SettleChannel` instruction with Nillion-signed batch
3. Settlement signed by Nillion Private Compute: batch of state updates collapsed to single Solana transaction with MPC signature
4. Solana settlement transaction visible on Solana Explorer (solscan.io or similar) with transaction signature logged
5. Settlement cost tracking: measure actual SOL transaction fees, validate <$0.50 target (Solana typically <$0.01, well under target)
6. Notification: emit `solanaSettlementCompleted` event with amount settled, Solana signature, Nillion signing latency
7. Low-balance warnings: emit `balanceWarning` at 80% of threshold (e.g., $800 accumulated toward $1000 threshold)
8. Retry logic: if Solana RPC unavailable or transaction drops, retry settlement with exponential backoff, max 3 retries

---

### Story 3.8: Epic 3 Independent Test Suite

**As a** developer ensuring Epic 3 modularity,
**I want** comprehensive test suite validating Solana integration works in isolation,
**so that** I can prove Epic 3 succeeds without depending on Epic 1 (Ethereum) or Epic 2 (Lightning) components.

#### Acceptance Criteria

1. Test suite runs Solana integration tests (`pnpm test:epic-3`) without importing Epic 1 (Ethereum) or Epic 2 (Lightning) code
2. Unit tests: Solana channel manager, program instruction building, Nillion voucher attachment/extraction, settlement triggers (80%+ coverage)
3. Integration tests: Solana program interaction using test validator, channel lifecycle (open → update → settle → close), Nillion signature verification in Solana context
4. End-to-end test: complete payment flow from client SDK → Solana transaction → Nillion verification → settlement on devnet
5. Mock dependencies: Ethereum/Lightning components mocked/stubbed, tests validate Solana works standalone
6. CI pipeline: Epic 3 tests run in separate GitHub Actions job with Solana CLI and test validator installed
7. Performance regression tests: Solana benchmark thresholds enforced (p95 <100ms, 1000 txn/sec), build fails if violated
8. Test documentation: README explains Solana test validator setup, airdrop SOL for testing, deploy program to local validator

---

### Story 3.9: Epic 3 Decision Gate Validation

**As a** project stakeholder deciding whether to proceed to Epic 4,
**I want** Epic 3 success criteria validation report,
**so that** I can make informed decision about cross-chain routing based on Solana results.

#### Acceptance Criteria

1. **Criterion 1 - Solana Channel Lifecycle:** Document full lifecycle working: open → stream → settle → close on Solana devnet with transaction signatures
2. **Criterion 2 - Nillion Voucher Integration:** Verify 100 vouchers pre-signed, successfully attached to Solana transactions, on-chain verification confirmed
3. **Criterion 3 - Performance Target:** Benchmark report shows <100ms payment confirmation, 1,000 txn/sec sustained throughput on Solana
4. **Criterion 4 - Program Deployment:** Solana program deployed to devnet, full lifecycle tested, program ID and Explorer link documented
5. **Criterion 5 - Monetary Settlements:** Screenshot of Solana Explorer showing threshold-based settlements ($100, $1000) to Solana L1
6. **Criterion 6 - Independent Testing:** Epic 3 test suite passes in isolation (GitHub Actions log showing Epic 3 tests green, Epic 1-2 disabled)
7. **GO Decision (All 6 Criteria Met):** Proceed to Epic 4 (Cross-Chain Payment Routing)
8. **PARTIAL GO (4-5 Criteria Met):** Fix issues identified, allocate 1-week extension, re-validate before Epic 4
9. **NO-GO (0-3 Criteria Met):** Defer Solana to post-MVP, proceed with Epic 5 using only Ethereum + Lightning (2-chain MVP), revisit Solana in Phase 2

---

## Epic 4: Cross-Chain Payment Routing (Week 13-16)

**Expanded Goal:**

Enable seamless cross-chain payments across all 3 blockchain ecosystems (Ethereum ↔ Bitcoin ↔ Solana) using ILP-inspired routing with Nillion MPC-signed atomic swaps. Implement intelligent route discovery algorithm, integrate real-time exchange rate oracles (Chainlink for ETH, Pyth for SOL), and provide robust rollback handling for failed cross-chain transactions. This epic delivers the interoperability vision where users funded on any chain can pay merchants accepting any other chain, with Nillion MPC signatures securing atomic swaps and maintaining privacy-preserving settlements throughout the swap process.

---

### Story 4.1: Cross-Chain Routing Algorithm Design

**As a** developer building cross-chain payment routing,
**I want** a route discovery algorithm finding optimal payment paths across chains,
**so that** I can automatically route payments from source chain to destination chain with minimal fees and latency.

#### Acceptance Criteria

1. **Graph Representation:** Model 3 chains as nodes (ETH, BTC, SOL) with edges representing swap pairs, edge weights = fees + latency
2. **Dijkstra's Shortest Path:** Implement algorithm finding minimum-cost route from source to destination (e.g., BTC → ETH may route direct or via BTC → SOL → ETH if cheaper)
3. **Route Evaluation:** For each source-destination pair, calculate: total fees (swap fees + settlement costs), estimated latency, liquidity availability
4. **Direct vs Multi-Hop:** Support both direct swaps (BTC → ETH) and multi-hop routing (BTC → SOL → ETH) based on cost optimization
5. **Liquidity Awareness:** Query available liquidity on each swap pair before routing, fail fast if insufficient liquidity detected
6. **Route Caching:** Cache optimal routes for 5 minutes (reduce computation), invalidate when liquidity changes significantly
7. **Fallback Routes:** If primary route fails, automatically attempt alternate route (e.g., if BTC → ETH fails, try BTC → SOL → ETH)
8. **Documentation:** Algorithm design document explains routing logic, includes worked examples for all 9 possible source-destination combinations

---

### Story 4.2: Ethereum ↔ Bitcoin Atomic Swap (BTC/ETH Pair)

**As a** user with Bitcoin balance wanting to pay Ethereum-based merchant,
**I want** atomic swap between Bitcoin and Ethereum with Nillion MPC signatures,
**so that** I can convert BTC to ETH trustlessly with privacy-preserving swap amounts.

#### Acceptance Criteria

1. **HTLC on Bitcoin:** Create Hash Time-Locked Contract on Bitcoin testnet with Nillion MPC-signed hash lock
2. **HTLC on Ethereum:** Create corresponding HTLC on Optimism testnet with same hash, swap ratio based on oracle price
3. **Atomic Execution:** Bitcoin HTLC unlocks only when Ethereum HTLC settles successfully (atomicity guaranteed)
4. **Nillion Signature Integration:** Swap parameters (amounts, hash) signed by Nillion Private Compute for privacy
5. **Timeout Handling:** Bitcoin HTLC expires in 24 hours, Ethereum HTLC expires in 12 hours (prevents deadlock)
6. **Swap Completion:** Measure end-to-end latency from swap initiation to both HTLCs settled, target <500ms
7. **Rollback Test:** Simulate timeout scenario, verify funds return to sender on both chains with Nillion-signed refunds
8. **On-Chain Verification:** Both swap transactions visible on Bitcoin testnet explorer (mempool.space) and Optimism explorer (optimistic.etherscan.io)

---

### Story 4.3: Bitcoin ↔ Solana Atomic Swap (BTC/SOL Pair)

**As a** user with Bitcoin balance wanting to pay Solana-based merchant,
**I want** atomic swap between Bitcoin and Solana with Nillion MPC signatures,
**so that** I can convert BTC to SOL trustlessly with privacy-preserving swap amounts.

#### Acceptance Criteria

1. **HTLC on Bitcoin:** Create Hash Time-Locked Contract on Bitcoin testnet with Nillion MPC-signed hash lock (reuse Epic 4.2 Bitcoin HTLC)
2. **Escrow on Solana:** Deploy escrow program on Solana devnet (HTLCs less common on Solana, use escrow + hash reveal pattern)
3. **Atomic Execution:** Bitcoin HTLC unlocks only when Solana escrow releases funds to recipient (atomicity via hash preimage reveal)
4. **Nillion Signature Integration:** Escrow parameters (amounts, hash) signed by Nillion Private Compute for privacy
5. **Timeout Handling:** Bitcoin HTLC expires in 24 hours, Solana escrow expires in 12 hours (prevents deadlock)
6. **Swap Completion:** Measure end-to-end latency from swap initiation to both settlements, target <500ms
7. **Rollback Test:** Simulate timeout scenario, verify funds return to sender on both chains with Nillion-signed refunds
8. **On-Chain Verification:** Swap transactions visible on Bitcoin explorer and Solana Explorer (solscan.io)

---

### Story 4.4: Ethereum ↔ Solana Atomic Swap (ETH/SOL Pair)

**As a** user with Ethereum balance wanting to pay Solana-based merchant,
**I want** atomic swap between Ethereum and Solana with Nillion MPC signatures,
**so that** I can convert ETH to SOL trustlessly with privacy-preserving swap amounts.

#### Acceptance Criteria

1. **HTLC on Ethereum:** Create Hash Time-Locked Contract on Optimism testnet with Nillion MPC-signed hash lock (reuse Epic 4.2 Ethereum HTLC)
2. **Escrow on Solana:** Deploy escrow program on Solana devnet (reuse Epic 4.3 Solana escrow)
3. **Atomic Execution:** Ethereum HTLC unlocks only when Solana escrow releases funds to recipient (atomicity via hash preimage reveal)
4. **Nillion Signature Integration:** Both HTLC and escrow parameters signed by Nillion Private Compute for privacy
5. **Timeout Handling:** Ethereum HTLC expires in 24 hours, Solana escrow expires in 12 hours (prevents deadlock)
6. **Swap Completion:** Measure end-to-end latency from swap initiation to both settlements, target <500ms
7. **Rollback Test:** Simulate timeout scenario, verify funds return to sender on both chains with Nillion-signed refunds
8. **On-Chain Verification:** Swap transactions visible on Optimism explorer and Solana Explorer

---

### Story 4.5: Exchange Rate Oracle Integration

**As a** cross-chain routing system,
**I want** real-time exchange rate data from decentralized oracles,
**so that** I can calculate accurate swap ratios for BTC/ETH/SOL conversions.

#### Acceptance Criteria

1. **Chainlink Integration:** Connect to Chainlink Price Feeds for BTC/USD, ETH/USD, SOL/USD on Ethereum testnet
2. **Pyth Integration:** Connect to Pyth Network for SOL/USD, BTC/USD, ETH/USD on Solana devnet (redundancy + Solana native)
3. **Price Aggregation:** Calculate cross-rates (BTC/ETH, BTC/SOL, ETH/SOL) by combining USD pairs with precision handling
4. **Staleness Detection:** Reject oracle prices older than 5 minutes, fallback to secondary oracle if primary stale
5. **Price Validation:** Sanity check oracle prices against expected ranges (e.g., reject if BTC/ETH < 10 or > 50), prevent flash crash exploitation
6. **Slippage Protection:** Apply 1% slippage buffer to swap ratios (protect against price movement during swap execution)
7. **Oracle Health Monitoring:** Dashboard displays oracle status (Chainlink round ID, Pyth confidence interval, last update timestamp)
8. **Fallback Strategy:** If both oracles unavailable, reject cross-chain swaps (fail-safe, prevent incorrect swap ratios)

---

### Story 4.6: Cross-Chain Settlement Verification

**As a** cross-chain payment system,
**I want** automated verification that atomic swaps completed correctly on both chains,
**so that** I can confirm funds transferred to recipient and sender's funds locked/released appropriately.

#### Acceptance Criteria

1. **Dual-Chain Monitoring:** Listen for events on both source and destination chains (e.g., Bitcoin HTLC locked + Ethereum HTLC settled)
2. **Settlement State Machine:** Track swap states: `Initiated`, `SourceLocked`, `DestinationSettled`, `Completed`, `RolledBack`
3. **Hash Preimage Verification:** Confirm hash preimage revealed on destination chain matches hash lock on source chain (proves atomicity)
4. **Nillion Signature Verification:** Verify Nillion MPC signatures on both sides of swap (validates privacy-preserving execution)
5. **Completion Notification:** Emit `crossChainSwapCompleted` event with source chain, destination chain, amount, total latency, Nillion verification status
6. **Rollback Detection:** Detect timeout scenarios, emit `crossChainSwapRolledBack` event, verify refund transactions on both chains
7. **Audit Log:** Store all cross-chain swap attempts in PostgreSQL with full transaction details for debugging and compliance
8. **Error Handling:** Handle edge cases (network partitions, one chain confirms but other times out, partial failures)

---

### Story 4.7: Cross-Chain Routing Dashboard

**As a** developer debugging cross-chain payment issues,
**I want** cross-chain routing metrics added to monitoring dashboard,
**so that** I can visualize swap status, oracle prices, route paths, and failure reasons.

#### Acceptance Criteria

1. **Swap Status View:** Real-time table showing active cross-chain swaps with source chain, destination chain, status (Initiated/Locked/Settled/Completed), time elapsed
2. **Oracle Price Display:** Live ticker showing BTC/USD, ETH/USD, SOL/USD from Chainlink and Pyth with last update timestamp
3. **Route Visualization:** Graph visualization showing 3 chains as nodes, edges showing available swap pairs with current liquidity and fees
4. **Swap History Timeline:** Timeline view showing completed swaps, rollbacks, success rate per swap pair
5. **Latency Breakdown:** For each completed swap, show latency breakdown (source lock, oracle query, destination settle, total)
6. **Failure Analysis:** Log view showing failed swaps with specific error codes (ORACLE_STALE, INSUFFICIENT_LIQUIDITY, TIMEOUT, NILLION_SIGNATURE_FAILED)
7. **Cross-Chain Balance:** Display user balances across all 3 chains in unified view with USD equivalent values
8. **Responsive Design:** Cross-chain metrics integrated into existing dashboard without requiring horizontal scroll

---

### Story 4.8: Cross-Chain Performance Benchmarking

**As a** technical lead validating Epic 4 success,
**I want** cross-chain swap performance benchmarks,
**so that** I can prove <500ms end-to-end latency for all 3 swap pairs (BTC↔ETH, BTC↔SOL, ETH↔SOL).

#### Acceptance Criteria

1. **Benchmark Script:** Automated test executing 10 swaps for each of the 3 pairs (30 total swaps) on testnets
2. **Latency Measurement:** Record timestamps at each stage (swap initiate, source lock, oracle query, destination settle, completion)
3. **Performance Report:** Output p50, p95, p99 latency for each swap pair, identify slowest step in each path
4. **Throughput Test:** Execute 100 swaps in parallel (limited by testnet rate limits), measure successful completion rate
5. **Pass/Fail Criteria:** All 3 swap pairs achieve p95 latency <500ms = PASS (Epic 4 performance target met)
6. **Cost Analysis:** Calculate total fees for cross-chain swap (source chain settlement + swap fees + destination chain settlement)
7. **Comparison:** Benchmark direct swaps vs multi-hop routing (e.g., BTC → ETH direct vs BTC → SOL → ETH), identify when multi-hop beneficial
8. **CI Integration:** GitHub Actions runs cross-chain benchmark weekly (not on every PR due to testnet dependency), alerts on regression

---

### Story 4.9: Epic 4 Decision Gate Validation

**As a** project stakeholder deciding whether to proceed to Epic 5,
**I want** Epic 4 success criteria validation report,
**so that** I can make informed decision about unified SDK development based on cross-chain routing results.

#### Acceptance Criteria

1. **Criterion 1 - BTC ↔ ETH Swaps:** Document successful bidirectional swaps with Nillion MPC-signed HTLCs, transaction IDs on both chains
2. **Criterion 2 - BTC ↔ SOL Swaps:** Document successful bidirectional swaps with Nillion MPC-signed escrow, transaction IDs on both chains
3. **Criterion 3 - ETH ↔ SOL Swaps:** Document successful bidirectional swaps with Nillion MPC coordination, transaction IDs on both chains
4. **Criterion 4 - Route Discovery:** Demonstrate routing algorithm finds optimal path for all source-destination pairs, handles liquidity constraints
5. **Criterion 5 - Exchange Rate Oracle:** Verify Chainlink and Pyth integration working, accurate swap ratios, staleness detection functional
6. **Criterion 6 - Cross-Chain Latency:** Benchmark report shows <500ms end-to-end latency for all 3 swap pairs at p95
7. **Criterion 7 - Rollback Handling:** Demonstrate timeout scenarios tested, funds return to sender with Nillion-signed refunds on both chains
8. **Criterion 8 - Privacy Preservation:** Verify Nillion MPC signatures on all cross-chain primitives, swap amounts confidential on-chain
9. **GO Decision (All 8 Criteria Met):** Proceed to Epic 5 (Unified SDK & Developer Experience)
10. **PARTIAL GO (6-7 Criteria Met):** Identify failed criteria, assess impact on unified SDK, consider proceeding with limited cross-chain support
11. **LIMITED GO (3-5 Criteria Met):** Ship without cross-chain routing (3 independent chains only), defer Epic 4 to Phase 2, proceed to Epic 5 with simplified scope
12. **NO-GO (0-2 Criteria Met):** Cross-chain infeasible, pivot to 2-chain MVP (Ethereum + Lightning only), skip Solana and Epic 5

---

## Epic 5: Unified SDK & Developer Experience (Week 17-18)

**Expanded Goal:**

Abstract all chain-specific complexity behind a unified SDK API where developers specify `chains: ['optimism', 'lightning', 'solana']` and payment routing, Nillion voucher management, and cross-chain swaps happen automatically. Deliver production-ready developer experience matching the "Stripe for micropayments" vision with comprehensive documentation covering all 3 chains, interactive tutorials, and monitoring dashboard providing unified multi-chain visibility. Validate <4 hour integration time goal with 3 external Nillion developers, proving the MVP is ready for production hardening and mainnet deployment.

---

### Story 5.1: Unified SDK API Design

**As a** developer integrating micropayments,
**I want** a single SDK API that works identically across all 3 chains,
**so that** I can switch payment rails or add multi-chain support without changing application code.

#### Acceptance Criteria

1. **Chain Abstraction Layer:** Design `PaymentClient` interface with methods agnostic to underlying chain: `sendPayment()`, `receivePayment()`, `getBalance()`, `settleChannel()`
2. **Configuration-Based Chain Selection:** Developer specifies chains in config: `new PaymentClient({ chains: ['optimism', 'lightning', 'solana'], nillion: { enabled: true } })`
3. **Automatic Chain Routing:** SDK automatically selects optimal chain based on: user's funded channels, merchant's accepted chains, current fees, latency targets
4. **Cross-Chain Transparency:** If user funded on Bitcoin but merchant accepts Ethereum, SDK automatically routes via cross-chain swap (Epic 4) without developer intervention
5. **Chain-Agnostic Payment Objects:** `Payment` type contains: `amount`, `currency`, `metadata`, internally SDK maps to chain-specific formats (satoshis vs wei vs lamports)
6. **Error Handling Abstraction:** Chain-specific errors mapped to unified error codes: `INSUFFICIENT_BALANCE`, `CHANNEL_UNAVAILABLE`, `SETTLEMENT_FAILED` (hides "insufficient gas" vs "insufficient SOL" differences)
7. **TypeScript Autocomplete:** Full type definitions for all SDK methods with JSDoc comments explaining cross-chain behavior
8. **API Design Document:** Technical spec documenting unified API, chain abstraction strategy, internal routing logic for architect review

---

### Story 5.2: Multi-Chain Balance Management

**As a** developer building payment-enabled applications,
**I want** unified balance view across all 3 chains,
**so that** I can display user's total payment capacity without querying each chain separately.

#### Acceptance Criteria

1. **Aggregated Balance API:** `client.getTotalBalance()` returns sum of balances across Ethereum, Lightning, Solana channels converted to USD
2. **Per-Chain Balance Breakdown:** `client.getBalanceByChain()` returns object: `{ optimism: '10.50', lightning: '5.00', solana: '3.25' }` (USD values)
3. **Real-Time Balance Updates:** SDK maintains WebSocket connections to all 3 payment servers, emits `balanceChanged` event when any chain balance updates
4. **Auto-Rebalancing Suggestions:** SDK analyzes balance distribution, recommends rebalancing if one chain >80% of total (e.g., "Move funds from Lightning to Ethereum for lower fees")
5. **Low Balance Warnings:** Emit `lowBalanceWarning` event when total balance <$10 across all chains, prompt user to fund any channel
6. **Currency Conversion:** Support balance display in multiple currencies (USD, EUR, BTC, ETH, SOL) using oracle exchange rates from Epic 4
7. **Balance Caching:** Cache balance queries for 5 seconds to reduce RPC calls, invalidate on payment events
8. **Integration Test:** Verify balance aggregation correct when user has funds on 2 chains, 0 on third chain

---

### Story 5.3: Unified Monitoring Dashboard (Multi-Chain View)

**As a** developer monitoring payment system across 3 chains,
**I want** a single dashboard showing unified metrics,
**so that** I can track payment health without switching between chain-specific views.

#### Acceptance Criteria

1. **Multi-Chain Payment Timeline:** Unified timeline view showing all payments across Ethereum, Lightning, Solana with chain badge (color-coded: blue=ETH, orange=BTC, purple=SOL)
2. **Aggregated Success Rate:** Display overall payment success rate across all chains plus breakdown per chain (identifies problematic chain)
3. **Cross-Chain Swap Tracking:** Dedicated section showing active cross-chain swaps in progress, completed swaps, rollbacks (Epic 4 metrics)
4. **Unified Nillion Metrics:** Total Nillion vouchers consumed across all chains, total MPC signing events, average Nillion latency per chain
5. **Balance Distribution Pie Chart:** Visual showing percentage of total liquidity on each chain, helps identify rebalancing needs
6. **Performance Comparison:** Side-by-side latency comparison (p95) for Ethereum vs Lightning vs Solana, identify fastest payment rail
7. **Consolidated Alerts:** Single alert panel showing warnings from all chains (low balance, Nillion signing failures, oracle staleness, settlement delays)
8. **Responsive Multi-Chain Layout:** Dashboard adapts to show 1-3 chain columns based on viewport width (mobile: stacked, desktop: side-by-side)

---

### Story 5.4: Comprehensive API Documentation

**As a** developer new to the micropayment protocol,
**I want** complete API documentation with examples for each chain,
**so that** I can understand how to integrate payments without extensive trial-and-error.

#### Acceptance Criteria

1. **API Reference Site:** Documentation site (Docusaurus or similar) deployed at https://docs.micropayments.dev with search functionality
2. **Getting Started Guide:** Step-by-step tutorial completing first payment in <15 minutes: install SDK → configure chains → send payment → verify receipt
3. **Chain-Specific Guides:** 3 separate guides for Ethereum, Lightning, Solana with chain-specific configuration, funding instructions, troubleshooting
4. **Cross-Chain Payment Tutorial:** Tutorial demonstrating Bitcoin user paying Ethereum merchant via automatic cross-chain routing (Epic 4 showcase)
5. **Nillion Integration Guide:** Dedicated section explaining Nillion voucher architecture, privacy benefits, MPC signing process (demystifies Nillion for developers)
6. **Code Examples Repository:** GitHub repo (`micropayments-examples`) with 5 example projects: basic payment, multi-chain, cross-chain, Nillion privacy demo, dashboard integration
7. **API Method Reference:** Auto-generated TypeScript API docs from JSDoc comments, every method documented with parameters, return types, examples, error codes
8. **Troubleshooting FAQ:** Common issues documented (channel opening fails, Nillion signing timeout, oracle price stale) with step-by-step fixes

---

### Story 5.5: External Developer Integration Testing (3 Developers)

**As a** product manager validating MVP readiness,
**I want** 3 external Nillion developers to integrate SDK and provide feedback,
**so that** I can validate <4 hour integration time goal and identify UX friction before production launch.

#### Acceptance Criteria

1. **Recruit 3 Developers:** Find developers from Nillion Discord community, not project contributors, varying experience levels (junior, mid, senior)
2. **Provide Test Environment:** Each developer receives: SDK package, API documentation, testnet faucet access (all 3 chains), payment server endpoint URLs, Nillion testnet credentials
3. **Track Integration Time:** Measure time from `npm install @nillion/micropayments` to first successful multi-chain payment (target <4 hours)
4. **Success Criteria:** 2 out of 3 developers complete integration in <4 hours with at least one payment on each chain (Ethereum, Lightning, Solana)
5. **Structured Feedback Survey:** Collect feedback via Google Form: clarity of docs, pain points encountered, Nillion-specific confusion, chain abstraction effectiveness
6. **Screen Recording:** Developers record integration session (Loom or similar), review recordings to identify friction points (missing docs, unclear errors, SDK bugs)
7. **Documentation Improvements:** Incorporate feedback into API docs, add FAQ entries for every issue encountered, clarify confusing sections
8. **Confirmation Test:** After improvements, recruit 1 additional developer for final validation (should complete in <3 hours with improved docs)
9. **Pre-Recruitment Strategy (Executed During Epic 1-4):** To avoid Epic 5 timeline delays, begin developer recruitment early:
   - **Week 2-3 (Epic 1):** Post in Nillion Discord #developers channel: "Seeking 3 Nillion developers for paid SDK integration testing (Week 17-18, ~4 hours each, compensated)"
   - **Week 6 (Epic 1 Complete):** Confirm 3 developer commitments, schedule testing sessions for Week 17-18 (specific dates/times)
   - **Week 10 (Epic 3 Mid-Point):** Send reminder to developers, provide preliminary SDK access for early exploration (optional)
   - **Week 16 (Epic 4 Complete):** Final confirmation with developers, send testing environment details (endpoints, faucets, credentials) 1 week before testing
   - **Contingency:** If <3 developers recruited by Week 12, expand recruitment to Ethereum/Solana developer communities with Nillion interest

---

### Story 5.6: SDK Error Handling & Developer Experience Polish

**As a** developer debugging payment integration issues,
**I want** clear, actionable error messages with resolution guidance,
**so that** I can fix problems quickly without needing to understand blockchain internals or Nillion MPC.

#### Acceptance Criteria

1. **Unified Error Codes:** Define error taxonomy covering all failure modes: `NILLION_*` (voucher depleted, MPC signing failed), `CHAIN_*` (insufficient balance, gas estimation failed), `ROUTING_*` (no route available, swap failed)
2. **Human-Readable Messages:** Each error includes plain English explanation, e.g., "Nillion signing in progress, please wait..." instead of "MPC preprocessing timeout at epoch 45"
3. **Resolution Guidance:** Errors include `resolution` field with actionable steps, e.g., `INSUFFICIENT_BALANCE`: "Add funds to your Ethereum channel using faucet: https://faucet.optimism.io"
4. **Chain Context in Errors:** Errors specify which chain caused failure, e.g., "Lightning channel unavailable (Bitcoin testnet), try Ethereum or Solana"
5. **Debug Mode:** SDK supports `debug: true` config option, logs detailed information (RPC calls, Nillion API requests, routing decisions) for troubleshooting
6. **Error Event Handling:** SDK emits `error` event with structured error objects, developers can attach listeners for custom error handling
7. **Error Documentation:** API docs include error catalog with all possible error codes, causes, resolutions, examples
8. **Developer Testing:** External developers from Story 5.5 confirm error messages were helpful during debugging (survey question)

---

### Story 5.7: Performance Optimization & Bundle Size

**As a** developer integrating SDK into web application,
**I want** minimal SDK bundle size and fast initialization,
**so that** micropayments don't significantly impact application load time or user experience.

#### Acceptance Criteria

1. **Bundle Size Target:** Client SDK bundle <50 KB gzipped (measured via webpack-bundle-analyzer)
2. **Tree-Shaking Support:** SDK designed for tree-shaking, developers importing only `sendPayment` don't include cross-chain routing code
3. **Lazy Loading:** Chain-specific code lazy-loaded on demand (if developer only uses Ethereum, Lightning/Solana code never downloaded)
4. **Initialization Performance:** SDK initialization <100ms (measured from `new PaymentClient()` to ready state)
5. **Memory Footprint:** Client SDK uses <10 MB memory during idle, <25 MB during active streaming (measured via Chrome DevTools)
6. **Network Efficiency:** Minimize RPC calls via aggressive caching (balance queries cached 5s, oracle prices cached 1min, voucher prefetching)
7. **Code Splitting:** Server SDK and client SDK separated (developers building backend-only don't include browser-specific code)
8. **Performance Documentation:** README includes bundle size badge, performance characteristics table, optimization tips for production

---

### Story 5.8: Epic 5 Validation & MVP Completion

**As a** project stakeholder deciding on production hardening,
**I want** comprehensive Epic 5 success criteria validation,
**so that** I can confirm MVP complete and ready for security audit and mainnet deployment.

#### Acceptance Criteria

1. **Criterion 1 - Chain Abstraction:** SDK successfully abstracts all 3 chains, developer can switch from `chains: ['optimism']` to `chains: ['lightning', 'solana']` with zero code changes
2. **Criterion 2 - Cross-Chain Abstraction:** Demonstrate user funded on Bitcoin can pay Ethereum merchant via automatic routing without developer intervention
3. **Criterion 3 - Unified Monitoring:** Dashboard displays payments, balances, metrics across all 3 chains in single view, chain-specific drill-down available
4. **Criterion 4 - Documentation Complete:** API docs include reference for every SDK method, tutorials for all 3 chains, cross-chain examples, troubleshooting FAQ
5. **Criterion 5 - External Developer Success:** 2 out of 3 external developers completed integration in <4 hours each, survey feedback positive (NPS >50)
6. **Criterion 6 - Error Handling:** Developers report clear, actionable error messages helped resolve issues quickly (survey validation)
7. **MVP COMPLETE Decision:** All 6 criteria met = MVP COMPLETE, proceed to production hardening (Week 19-22: security audit, edge deployment, monitoring)
8. **LIMITED MVP Decision:** 4-5 criteria met = Limited launch with known rough edges, iterate on DX post-launch based on early adopter feedback
9. **EXTENSION NEEDED Decision:** 0-3 criteria met = Allocate 1-week extension for critical fixes, re-validate before production hardening

---

## Out of Scope for MVP

**The following features are explicitly excluded from the MVP (18-week timeline) and deferred to Phase 2 (post-MVP) or future releases:**

### Deferred to Phase 2 (Months 5-8)

**Advanced Features:**
- ❌ **Client-side signing fallback (Option A)** - Nillion MPC is the primary architecture; non-MPC path deferred to Phase 2 for secondary use cases
- ❌ **Advanced ML-based rebalancing** - Simple monetary threshold triggers only in MVP; machine learning liquidity prediction deferred
- ❌ **Multi-hop cross-chain routing optimization** - Epic 4 supports multi-hop routing algorithmically, but complex optimization (liquidity discovery, multi-path routing) deferred
- ❌ **Advanced monetary threshold configuration** - Dynamic threshold adjustment based on gas prices and predictive settlement scheduling deferred
- ❌ **Voucher pool optimization** - Adaptive voucher pre-signing, voucher recycling, multi-session sharing, cross-chain portability deferred

**Infrastructure & Operations:**
- ❌ **Production edge deployment** - Single-region cloud (Railway/AWS/GCP) for PoC acceptable; Cloudflare Workers multi-region deployment deferred to production hardening (Week 19-22)
- ❌ **Watchtower services** - Manual monitoring acceptable for PoC; automated watchtower for malicious channel closure detection deferred
- ❌ **Fraud proof automation** - Basic challenge-response only in MVP; automated fraud detection and proof submission deferred

**Compliance & Security:**
- ❌ **Security audit** - Required before mainnet launch, not for testnet PoC; external audit budgeted for production hardening (Week 19-22, $15k-25k)
- ❌ **KYC/AML compliance** - Testnet only for MVP; regulatory compliance modules deferred to production phase
- ❌ **Mainnet deployment** - All MVP work on testnets (Optimism Sepolia, Bitcoin testnet, Solana devnet); mainnet requires security audit completion

**Platform Extensions:**
- ❌ **Mobile SDKs (iOS, Android)** - Web/Node.js only for MVP; native mobile SDKs deferred to Phase 2
- ❌ **Additional blockchain integrations** - MVP covers 3 chains (Ethereum L2, Bitcoin Lightning, Solana); additional chains (Cosmos, Polkadot) deferred to Year 1-2 roadmap
- ❌ **Browser extension-free flow** - Wallet browser extension required for MVP; extension-free Web Monetization-style integration deferred

### Explicitly Not Included (May Never Be Prioritized)

- ❌ **Custom MPC cryptography** - Only audited libraries and Nillion SDK used; no custom MPC implementation
- ❌ **Layer 1 Ethereum support** - Optimism L2 only for MVP; Ethereum L1 fees prohibitive for micropayments
- ❌ **Payment channel routing (Lightning-style)** - Direct peer-to-peer channels only; network-wide routing (Lightning Network's routing table) not applicable to use case
- ❌ **Privacy coin integration** - Ethereum/Bitcoin/Solana sufficient for MVP; privacy-focused chains (Monero, Zcash) not prioritized

### Conditional Features (Depend on Partnership/Budget)

- ⚠️ **Nillion Private Compute integration** - Conditional on Nillion partnership pricing <$0.001/operation; if pricing prohibitive, pivot to client-side signing (Option A) or abandon Nillion showcase
- ⚠️ **Cross-chain routing (Epic 4)** - Can be descoped if Week 16 decision gate fails; ship 3 independent chains without routing, defer Epic 4 to Phase 2
- ⚠️ **Solana integration (Epic 3)** - Can be descoped to 2-chain MVP (Ethereum + Lightning) if Week 12 decision gate fails or timeline slips

---

## Checklist Results Report

### Executive Summary

**Overall PRD Completeness:** 95% (post-fixes)

**MVP Scope Appropriateness:** **Just Right** - The 5-epic structure provides appropriate incremental value delivery with clear decision gates. Epic 1 is foundation + first payment rail (Ethereum), Epics 2-3 add blockchain diversity (Bitcoin, Solana), Epic 4 adds interoperability (cross-chain routing), Epic 5 delivers usability (unified SDK). Each epic can stand alone if subsequent epics descoped.

**Readiness for Architecture Phase:** **READY** - The PRD provides comprehensive technical guidance, clear requirements, well-structured epics with detailed stories, and explicit technical assumptions. Architect has sufficient direction to begin detailed design.

**Most Critical Gaps:**
1. **Project Brief referenced but not embedded** - Architect may not have access to the 500+ pages of research (mitigation: key findings extracted into PRD sections)
2. **Nillion SDK availability unknown** - PRD assumes TypeScript SDK exists, but this is unvalidated (mitigation: Story 1.0 creates mocks, fallback to API bridge documented)
3. **External developer recruitment strategy defined** - Story 5.5 now includes pre-recruitment timeline starting Week 2-3

---

### Category Analysis Table

| Category                         | Status  | Critical Issues |
| -------------------------------- | ------- | --------------- |
| 1. Problem Definition & Context  | **PASS** (95%) | None - Project Brief provides comprehensive problem statement, target users, success metrics |
| 2. MVP Scope Definition          | **PASS** (95%) | None - Out-of-scope section now added to PRD body |
| 3. User Experience Requirements  | **PASS** (88%) | Minor: User flows not fully documented (deferred to UX Expert per Next Steps) |
| 4. Functional Requirements       | **PASS** (95%) | None - FR1-FR20 comprehensive, testable, traced to epics |
| 5. Non-Functional Requirements   | **PASS** (93%) | None - NFR1-NFR15 cover performance, security, reliability, testability |
| 6. Epic & Story Structure        | **PASS** (98%) | None - 5 epics with 49 stories (added Story 1.0), each with detailed acceptance criteria |
| 7. Technical Guidance            | **PASS** (95%) | None - Story 1.0 spike validates Nillion SDK, API bridge fallback documented |
| 8. Cross-Functional Requirements | **PASS** (85%) | None - Data schema ownership clarified in Technical Assumptions |
| 9. Clarity & Communication       | **PASS** (90%) | Minor: Some blockchain jargon may confuse non-technical stakeholders |

**Overall Assessment:** PASS (95% average across all categories, up from 92% pre-fixes)

---

### Final Decision

**✅ READY FOR ARCHITECT & UX EXPERT**

The PRD and epics are comprehensive, properly structured, and ready for architectural design and UX design phases. The document provides:

- ✅ Clear problem definition and success metrics
- ✅ Well-scoped MVP with appropriate decision gates
- ✅ Comprehensive functional and non-functional requirements
- ✅ Excellent epic/story structure (49 stories with detailed acceptance criteria)
- ✅ Detailed technical guidance and constraints
- ✅ Identified risks with mitigation strategies
- ✅ Clear handoff to next phase (UX Expert and Architect prompts in Next Steps)
- ✅ All recommended fixes implemented

**Critical Gaps:** None blocking architecture or UX design phases

**Overall Assessment:** This PRD represents exceptional product management work with comprehensive research foundation (Project Brief 500+ pages), well-structured epic breakdown, clear technical direction, and all recommended fixes implemented. The Architect and UX Expert have everything needed to proceed with detailed design.

---

## Next Steps

### UX Expert Prompt

**Objective:** Create comprehensive user experience design for the Nillion-powered micropayment protocol based on this PRD.

**Context:** You are designing UX for a developer-focused payment SDK with 3 user-facing surfaces: (1) Developer monitoring dashboard, (2) End-user wallet extension, (3) Documentation website. The product must achieve "Stripe for micropayments" quality while hiding Nillion MPC complexity from users.

**Key Documents to Review:**
- This PRD (docs/prd.md) - All sections, especially "User Interface Design Goals"
- Project Brief (docs/brief.md) - Section "Proposed Solution" for technical context

**Your Deliverables:**

1. **User Journey Maps** (3 flows minimum):
   - Developer SDK Integration Flow: From `npm install` to first successful payment
   - End-User Wallet Funding Flow: From extension install to funded payment channel
   - Payment Streaming Flow: End-user browsing website, micropayments auto-deducting, balance updates
   - Cross-Chain Payment Flow: User funded on Bitcoin paying Ethereum merchant (automatic routing)

2. **Wireframes** (High-fidelity recommended):
   - **Developer Dashboard:** Home view (all 3 chains), per-chain drill-down, Nillion metrics panel, cross-chain swap status
   - **Wallet Extension:** Popup UI (balance display, payment history), funding flow (channel open wizard), settings (chain selection, thresholds)
   - **Documentation Site:** Homepage (getting started CTAs), API reference layout, tutorial page structure

3. **Information Architecture:**
   - Dashboard navigation structure (sidebar? tabs? multi-page?)
   - Documentation site taxonomy (by chain? by use case? by complexity level?)
   - Wallet extension menu hierarchy (1-level deep maximum for extension constraints)

4. **Interaction Design Specifications:**
   - Dashboard real-time updates (WebSocket events → UI updates, polling frequency)
   - Wallet extension payment approval UX (auto-approve vs manual review thresholds)
   - Error state designs (Nillion signing timeout, channel balance low, oracle stale)
   - Loading states (handshake in progress, voucher pre-signing, settlement pending)

5. **Visual Design Guidelines:**
   - Color palette (Nillion brand colors for MPC features, chain-specific colors: blue=ETH, orange=BTC, purple=SOL)
   - Typography system (monospace for code/transaction IDs, sans-serif for UI)
   - Icon set (Nillion logo, chain logos, status icons: success/warning/error/pending)
   - Dark mode specifications (developer preference, WCAG AA contrast ratios)

6. **Accessibility Audit Checklist:**
   - WCAG AA compliance verification (color contrast, keyboard navigation, screen reader support)
   - Dashboard-specific considerations (graphs must have text alternatives, alerts announced)
   - Wallet extension considerations (extension popups have limited screen reader support, mitigation strategies)

**Success Criteria:**
- Developer can understand dashboard UI in <30 seconds without training
- End-user wallet funding flow completable in <30 seconds (measured via prototype user testing)
- Documentation site navigation intuitive (find answer to "How to accept Bitcoin payments?" in <2 clicks)
- All designs meet WCAG AA standards (contrast, keyboard nav, screen reader)

**Timeline:** 2 weeks (Week 19-20, parallel with Architecture phase)

**Handoff Format:** Figma file (or equivalent) with:
- All screens linked in prototype mode
- Component library (buttons, inputs, cards, graphs)
- Design tokens (colors, typography, spacing)
- Developer handoff notes (dimensions, interactions, edge cases)

---

### Architect Prompt

**Objective:** Create detailed technical architecture for the Nillion-powered micropayment protocol based on this PRD, enabling development teams to implement Epic 1-5 with confidence.

**Context:** You are architecting a multi-chain micropayment system with complex cross-chain routing, Nillion MPC integration, and sub-100ms latency requirements. The architecture must support 3 blockchain ecosystems (Ethereum L2, Bitcoin Lightning, Solana) with independent testability and graceful degradation.

**Key Documents to Review:**
- This PRD (docs/prd.md) - All sections, especially "Technical Assumptions" and Epic 1-5 stories
- Project Brief (docs/brief.md) - Section "Technical Considerations" and "Risks & Open Questions"

**Your Deliverables:**

1. **System Architecture Diagram:**
   - Component diagram showing: Client SDK, WebSocket Server, Payment Channel Manager, Nillion Adapters, Blockchain Integrations, Database Layer
   - Data flow diagram: Handshake phase → Streaming phase → Settlement phase → Recovery phase
   - Multi-chain architecture: How Epic 1 (Ethereum), Epic 2 (Lightning), Epic 3 (Solana) components interact
   - Cross-chain routing architecture (Epic 4): Route discovery, atomic swap coordination, oracle integration

2. **Data Models & Schemas:**
   - **PostgreSQL Tables:** Payment channels (id, participants, balances, state, nonces), Settlements (batch_id, channel_id, amount, tx_hash, timestamp), Sessions (session_id, voucher_count, created_at, last_active)
   - **Redis Keys:** Voucher pools (`voucher:pool:{session_id}`), Channel cache (`channel:state:{channel_id}`), Rate limits (`ratelimit:{api_key}`)
   - **TimescaleDB Hypertables:** Metrics (`metrics_latency`, `metrics_throughput`, `metrics_mpc_signing`), partitioning strategy (by time, retention policies)
   - **Entity-Relationship Diagram:** Show relationships between channels, settlements, vouchers, sessions

3. **Protocol Buffer Schemas (Final Definitions):**
   - `HandshakeRequest` / `HandshakeResponse` (voucher negotiation)
   - `PaymentPacket` (Nillion voucher, amount, metadata, chain-specific fields)
   - `SettlementRequest` / `SettlementResponse` (batch settlements, Nillion signatures)
   - `NillionVoucher` (voucher_id, session_id, amount_limit, expiry, mpc_signature)
   - Versioning strategy (backward compatibility plan)

4. **API Design:**
   - **WebSocket API:** Binary Protocol Buffer messages, connection lifecycle (handshake → stream → settle → close)
   - **REST API (if Nillion SDK unavailable):** `/nillion/vouchers/presign`, `/nillion/storage/backup`, `/nillion/settlements/sign` endpoints
   - **Dashboard Metrics API:** `/metrics/realtime` (WebSocket), `/metrics/history` (REST)
   - Authentication strategy (API keys, macaroons for Lightning, wallet signatures)

5. **Nillion Integration Architecture:**
   - **If SDK Available:** Direct integration pattern, error handling, retry logic
   - **If SDK Unavailable (Story 1.0 outcome):** REST API bridge layer design, authentication, request/response mapping, latency impact analysis
   - **Fallback Strategy:** Client-side signing mode activation criteria (Nillion unavailable >5min), privacy degradation notification

6. **Cross-Chain Routing Algorithm (Epic 4):**
   - Dijkstra's shortest path implementation (3-node graph: BTC, ETH, SOL)
   - Edge weight calculation (fees + latency + liquidity availability)
   - Multi-hop routing logic (when is BTC → SOL → ETH cheaper than BTC → ETH direct?)
   - Atomic swap coordination (HTLC on Bitcoin/Ethereum, escrow on Solana, hash preimage reveal sequence)

7. **Performance Architecture:**
   - Latency budget breakdown: <100ms p95 target allocation (15-50ms network, 0.02ms signing, 0.001ms voucher lookup, <50ms overhead)
   - Throughput optimization: 1,000 pkt/sec per connection (WebSocket backpressure handling, binary framing efficiency)
   - Scalability plan: Monolith (MVP) → Microservices (production) evolution strategy

8. **Security Architecture:**
   - Threat model (payment channel griefing, voucher replay attacks, oracle manipulation, HTLC timeout exploitation)
   - Mitigation strategies (nonce validation, TTL enforcement, sanity checks, challenge periods)
   - Audit preparation checklist (what external auditor will review in Week 19-22)

9. **Testing Strategy:**
   - Unit test architecture (mocking strategy for Nillion, blockchain RPCs, WebSocket connections)
   - Integration test design (Testcontainers for PostgreSQL/Redis, test validators for blockchains)
   - Epic-specific test isolation (Epic 2-3 independent test suites, no Epic 1 dependencies)
   - Performance benchmark framework (load test scripts, latency measurement, CI integration)

10. **Deployment Architecture:**
    - **MVP (Single-Region):** Railway/AWS/GCP deployment diagram, Docker Compose for local dev
    - **Production (Multi-Region):** Edge deployment (Cloudflare Workers), database replication, failover strategy
    - CI/CD pipeline design (GitHub Actions jobs: lint → test → build → deploy per Epic)

**Critical Architecture Decisions Required:**

1. **Monorepo Tool Choice:** Turborepo vs Nx (recommend one with rationale)
2. **Nillion Integration:** SDK vs API bridge (depends on Story 1.0 spike outcome)
3. **Lightning Implementation:** LND vs CLN (Epic 2 - evaluate both, recommend one)
4. **Solana State Channels:** Existing library vs custom program (Epic 3 - depends on Story 3.1 evaluation)
5. **WebSocket Library:** Native ws vs fastify-websocket vs socket.io (performance vs features tradeoff)

**Success Criteria:**
- Development teams can implement Epic 1-5 stories without architectural ambiguity
- All NFR requirements traceable to architectural components (e.g., NFR1 <100ms latency → WebSocket binary framing + in-memory voucher pool)
- Security audit preparation complete (threat model, mitigation strategies documented)
- Performance targets achievable (latency budget validated, throughput scaling plan viable)

**Timeline:** 2-3 weeks (Week 19-21, parallel with UX Expert phase)

**Handoff Format:** Architecture document (Markdown) with:
- All diagrams (system architecture, data models, deployment)
- API specifications (OpenAPI for REST, schema docs for Protocol Buffers)
- Decision log (ADRs for each critical decision with rationale)
- Implementation guidance per Epic (Epic 1 → stories 1.0-1.15, Epic 2 → stories 2.1-2.8, etc.)

---

## Final PRD Output

**This PRD is now complete and ready for handoff.**

**PRD Completeness:** 95% (post-fixes)
**Status:** ✅ READY FOR ARCHITECT & UX EXPERT

**Next Actions:**
1. ✅ Share this PRD with UX Expert and Architect using prompts above
2. ✅ Schedule Week 1 Nillion SDK validation spike (Story 1.0)
3. ✅ Begin external developer recruitment for Epic 5 testing (Week 2-3)
4. ✅ Engage Nillion partnership team for pricing discussion (Week 1 PRIORITY per Project Brief)

---

**End of Product Requirements Document**
