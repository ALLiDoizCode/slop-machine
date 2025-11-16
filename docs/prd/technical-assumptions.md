# Technical Assumptions

## Repository Structure

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

## Service Architecture

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

## Testing Requirements

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

## Additional Technical Assumptions and Requests

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
