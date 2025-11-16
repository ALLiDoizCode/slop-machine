# Epic 1: Nillion Core + Ethereum Optimism Foundation

**Expanded Goal:**

Establish foundational project infrastructure including monorepo setup, GitHub Actions CI/CD pipeline, and core development tooling, while simultaneously delivering the first fully functional Nillion-powered micropayment system on Ethereum Optimism. Validate all 3 critical Nillion features (voucher pre-signing via Private Compute, crash recovery via Private Storage backup, and privacy-preserving settlements via MPC signing) achieving <100ms p95 latency and 1000+ pkt/sec throughput. This epic serves as both project foundation and proof-of-concept for Nillion partnership viability.

---

## Story 1.0: Nillion SDK Validation Spike

**As a** technical lead planning Nillion integration,
**I want** validation of Nillion SDK TypeScript support and capabilities,
**so that** I can design appropriate integration strategy (direct SDK vs API bridge) before implementing voucher architecture.

### Acceptance Criteria

1. **Nillion SDK Research:** Contact Nillion partnership team, review documentation, confirm TypeScript/JavaScript SDK availability for Private Compute and Private Storage
2. **API Capabilities Validation:** Verify SDK supports: voucher pre-signing (batch MPC operations), Storage backup/retrieval (distributed shares), settlement signing (MPC batch signatures)
3. **Performance Benchmarking:** If SDK available, run simple benchmark measuring: MPC signing latency (target ~100ms per operation), Storage retrieval latency (target 200-500ms), SDK initialization time
4. **Integration Decision:** Document decision: **Option A - Direct SDK Integration** (if TypeScript SDK available) OR **Option B - REST API Bridge** (if SDK unavailable or non-JavaScript language)
5. **API Bridge Design:** If Option B chosen, design REST API bridge layer architecture: authentication strategy, endpoint design (/vouchers/presign, /storage/backup, /settlements/sign), error handling, retry logic
6. **Timeline Impact Assessment:** If API bridge required, document 2-3 week additional timeline impact for Epic 1 (adjust decision gate expectations)
7. **Spike Report:** 1-page summary with decision, rationale, integration approach, timeline impact shared with stakeholders
8. **Completion Deadline:** Week 1 Day 3 (allows pivot early if API bridge needed)

---

## Story 1.1: Project Foundation & Monorepo Setup

**As a** developer joining the project,
**I want** a fully configured monorepo with TypeScript, testing infrastructure, and CI/CD pipeline,
**so that** I can immediately start building features without spending days on tooling setup.

### Acceptance Criteria

1. Monorepo initialized with Turborepo or Nx containing 5 package workspaces (`/packages/client-sdk`, `/packages/server-sdk`, `/packages/protocol`, `/packages/nillion-adapter`, `/apps/demo`)
2. TypeScript strict mode configured across all packages with shared `tsconfig.json` base extending to package-specific configs
3. Jest testing framework configured with coverage reporting (80%+ target), supports both unit and integration tests
4. GitHub Actions CI/CD pipeline runs on every push: lint → type-check → test → build across all packages in parallel
5. pnpm workspace configuration enables cross-package dependencies (e.g., server-sdk depends on protocol package)
6. README.md includes quickstart guide: clone → `pnpm install` → `pnpm dev` → see demo app running
7. Development scripts available: `pnpm test`, `pnpm build`, `pnpm lint`, `pnpm type-check` work from monorepo root
8. ESLint and Prettier configured with shared rules, auto-format on commit via husky git hooks

---

## Story 1.2: Protocol Buffer Schema Definition

**As a** developer building the payment system,
**I want** Protocol Buffer schemas defining all payment message types,
**so that** client and server can communicate with compact binary serialization and type-safe message contracts.

### Acceptance Criteria

1. Protocol Buffer v3 schema file (`packages/protocol/proto/payment.proto`) defines: `HandshakeRequest`, `HandshakeResponse`, `PaymentPacket`, `SettlementRequest`, `SettlementResponse` messages
2. `PaymentPacket` message includes fields: `voucher_id`, `nonce`, `amount`, `timestamp`, `nillion_signature` (bytes), `metadata` (JSON)
3. `NillionVoucher` message defined with fields: `voucher_id`, `session_id`, `amount_limit`, `expiry_timestamp`, `mpc_signature` (bytes)
4. Code generation produces TypeScript types in `packages/protocol/src/generated/` via `protoc` compiler with `ts-proto` plugin
5. Generated TypeScript types exported from `packages/protocol/index.ts` for consumption by client-sdk and server-sdk packages
6. Binary serialization/deserialization achieves <1.3% overhead compared to raw JSON (validated via benchmark test)
7. Schema versioning strategy documented: breaking changes require new major version, backward-compatible changes increment minor version
8. Example usage documented showing encode/decode of `PaymentPacket` in both client and server contexts

---

## Story 1.3: Nillion Private Compute Mock Adapter

**As a** developer building payment features,
**I want** a mock Nillion Private Compute adapter for local development,
**so that** I can develop and test voucher pre-signing logic without requiring live Nillion API access.

### Acceptance Criteria

1. `NillionComputeAdapter` interface defined with methods: `preSignVouchers(count: number, sessionId: string)`, `signSettlement(batch: Settlement)`
2. `MockNillionCompute` implementation simulates 100ms latency per voucher pre-signing operation matching research findings
3. Mock generates valid-looking Ed25519 signatures (actual crypto, but using test keys not Nillion MPC)
4. `RealNillionCompute` implementation stub created with TODO comments indicating Nillion SDK integration points
5. Configuration flag `NILLION_MODE=mock|real` switches between implementations, mock enabled by default for local dev
6. Mock adapter tracks call history for testing: verify `preSignVouchers` called exactly once during handshake
7. Error simulation mode: mock can be configured to fail intermittently (tests retry logic)
8. Mock performance matches real Nillion: 100 vouchers × 100ms = 10 seconds total pre-signing time

---

## Story 1.4: Nillion Private Storage Mock Adapter

**As a** developer implementing crash recovery,
**I want** a mock Nillion Private Storage adapter,
**so that** I can test voucher backup/restore logic without live Nillion Storage API access.

### Acceptance Criteria

1. `NillionStorageAdapter` interface defined with methods: `storeVouchers(vouchers: Voucher[])`, `retrieveVouchers(sessionId: string)`, `deleteVouchers(sessionId: string)`
2. `MockNillionStorage` implementation uses in-memory Map for storage, simulates 200-500ms retrieval latency
3. Mock persists data across test runs using local filesystem JSON file (`.nillion-mock-storage/`) to simulate distributed storage
4. `RealNillionStorage` implementation stub created with TODO comments for Nillion Storage SDK integration
5. Configuration flag `NILLION_STORAGE_MODE=mock|real` switches implementations, mock default for local dev
6. Mock simulates distributed shares concept: stored vouchers split into 3 JSON files representing different "nodes"
7. Mock can simulate storage failures (test error handling): network timeout, insufficient nodes available, quota exceeded
8. Backup operation completes in <5 seconds for 100 vouchers (validates NFR requirement)

---

## Story 1.5: In-Memory Voucher Pool with Redis Backup

**As a** payment server processing streaming payments,
**I want** an in-memory voucher pool with <0.01ms access time,
**so that** I can pop pre-signed Nillion vouchers during hot path without blocking payment flow.

### Acceptance Criteria

1. `VoucherPool` class implemented with in-memory array storing pre-signed Nillion vouchers per session
2. `pop()` method retrieves next voucher from pool with O(1) complexity, measured <0.01ms via benchmark test
3. `getRemaining()` method returns count of unused vouchers, triggers warning log at 20% threshold (20 remaining)
4. `refill()` method calls Nillion adapter to pre-sign additional vouchers when pool depletes to 10% (background operation)
5. Redis integration: pool state synced to Redis on every 10 voucher consumption for crash recovery
6. Memory footprint validation: 100 vouchers × 200 bytes = 20 KB per session (measured via process.memoryUsage())
7. Thread-safe pop operation: concurrent requests don't retrieve same voucher (use atomic decrement pattern)
8. Pool expiry handling: vouchers with expired TTL (>1 hour old) automatically discarded on pop attempt

---

## Story 1.6: WebSocket Server with Binary Framing

**As a** developer building the payment transport layer,
**I want** a WebSocket server supporting binary Protocol Buffer messages,
**so that** I can stream payments with 1,000+ pkt/sec throughput and minimal serialization overhead.

### Acceptance Criteria

1. Fastify server created with `@fastify/websocket` plugin, listens on port 3000 (configurable via env var)
2. WebSocket connection handler implements handshake phase: client sends `HandshakeRequest`, server responds with `HandshakeResponse` containing 100 Nillion vouchers
3. Binary message framing: all messages serialized via Protocol Buffers, received as ArrayBuffer and deserialized to typed objects
4. Heartbeat mechanism: server sends ping every 30 seconds, disconnects client if no pong received within 10 seconds
5. Connection state management: track session ID, associated voucher pool, payment channel reference per WebSocket connection
6. Throughput validation: sustain 1,000 messages/sec for 60 seconds without backpressure (tested via load script)
7. Graceful shutdown: server waits for in-flight messages to complete before closing on SIGTERM signal
8. Error handling: malformed Protocol Buffer messages logged and connection closed with error code 4000 (protocol violation)

---

## Story 1.7: Connext Vector Payment Channel Integration

**As a** payment system developer,
**I want** Connext Vector payment channel integration on Optimism testnet,
**so that** I can open, update, and settle payment channels with off-chain state updates and on-chain finality.

### Acceptance Criteria

1. Connext Vector node deployed to Optimism Sepolia testnet, running as Docker container locally for development
2. `PaymentChannelManager` class wraps Connext SDK with methods: `openChannel(amount: string)`, `updateChannel(payment: Payment)`, `closeChannel(channelId: string)`
3. Channel open operation completes with <$5 transaction fee on Optimism L2 (validated by checking actual gas cost)
4. Off-chain state updates: 1,000+ channel updates executed without on-chain transactions (proves state channel working)
5. Channel close operation triggers on-chain settlement with batch verification of all off-chain payments
6. Circular rebalancing implemented: when channel balance low, trigger atomic swap to rebalance instead of close/reopen
7. Channel monitoring: emit events for `channelOpened`, `channelUpdated`, `channelClosed`, `balanceLow` (80% depleted)
8. Error handling: detect and handle challenge period violations, insufficient balance, channel already closed scenarios

---

## Story 1.8: Payment Verification with Nillion Signature Validation

**As a** payment server receiving streaming payments,
**I want** cryptographic verification of Nillion MPC signatures on every payment packet,
**so that** I can confirm payment authenticity before delivering API response.

### Acceptance Criteria

1. `PaymentVerifier` class implements `verify(packet: PaymentPacket): boolean` using Nillion public key to validate MPC signature
2. Signature verification achieves <0.02ms latency (measured via benchmark, validates latency budget)
3. Verification checks: signature matches packet contents, voucher not expired (TTL <1 hour), voucher not already used (replay protection)
4. Nonce validation: each voucher can only be used once, duplicate nonce causes verification failure
5. Amount validation: payment amount ≤ voucher amount_limit, overpayment attempts rejected
6. Verification failure modes logged with specific error codes: INVALID_SIGNATURE (4001), EXPIRED_VOUCHER (4002), REPLAY_ATTACK (4003), AMOUNT_EXCEEDED (4004)
7. Performance under load: verification sustains 1,000 verifications/sec without CPU bottleneck (target <5% CPU usage per NFR)
8. Mock Nillion signatures validated correctly in test mode, real Nillion signatures validated in production mode

---

## Story 1.9: Monetary Threshold Settlement Trigger

**As a** payment system operator,
**I want** automatic settlement triggered when accumulated balance reaches monetary thresholds,
**so that** I can batch payments economically without arbitrary packet count limits.

### Acceptance Criteria

1. `SettlementTrigger` class monitors accumulated balance per payment channel, supports configurable thresholds: $10, $100, $1000, $10000
2. When balance reaches threshold (e.g., $100.00), automatically invoke Nillion Private Compute to sign settlement batch
3. Settlement batch includes: channel ID, total amount, payment count, timestamp, Nillion MPC signature
4. On-chain settlement transaction submitted to Optimism testnet with Nillion-signed batch, achieves <$0.50 gas cost via circular rebalancing
5. Settlement amounts confidential: on-chain observers cannot determine batch amount from transaction data (Nillion privacy property)
6. Notification emitted on settlement completion: `settlementCompleted` event with amount, transaction hash, Nillion signing latency
7. Low-balance warnings: emit `balanceWarning` event at 80% of threshold (e.g., $80 accumulated toward $100 threshold)
8. Retry logic: if Nillion signing fails, retry 3 times with exponential backoff, fallback to client signing if Nillion unavailable after 3 attempts

---

## Story 1.10: Crash Recovery via Nillion Private Storage

**As a** payment system ensuring fault tolerance,
**I want** automatic session restoration from Nillion Private Storage after server crash,
**so that** in-progress payment sessions resume without voucher loss or user disruption.

### Acceptance Criteria

1. On server startup, check for orphaned sessions in Nillion Private Storage (sessions with active vouchers but no running WebSocket connection)
2. Retrieve vouchers from Nillion Storage via `retrieveVouchers(sessionId)` in <10 seconds (validates NFR requirement)
3. Restore voucher pool to in-memory state, resume WebSocket connection at last checkpoint (payment count, balance)
4. Client reconnection flow: client detects disconnect, reconnects with session ID, server responds with "session restored" message
5. Zero voucher loss validation: crash simulation test (kill server process mid-payment) followed by restart shows all 100 vouchers accounted for
6. Performance test: crash recovery completes in <10 seconds from client reconnect to first successful payment after restore
7. Cleanup logic: delete vouchers from Nillion Storage after successful session completion (channel closed, no pending payments)
8. Monitoring: log crash recovery events with metrics (recovery duration, vouchers restored, payments resumed)

---

## Story 1.11: Client SDK with Nillion Voucher Management

**As a** developer integrating micropayments into my application,
**I want** a JavaScript/TypeScript client SDK that handles Nillion voucher management automatically,
**so that** I can accept payments with <15 lines of code without understanding MPC cryptography.

### Acceptance Criteria

1. `@nillion/micropayments` package published to npm (or private registry for testing), installable via `npm install @nillion/micropayments`
2. Client SDK API: `new MicropaymentClient({ serverUrl, chains: ['optimism'], nillion: { enabled: true } })` initializes connection
3. Payment sending: `await client.sendPayment({ amount: '0.01', metadata: { apiCall: 'generate-text' } })` attaches Nillion voucher automatically
4. Voucher handshake: SDK requests 100 Nillion vouchers from server during initial connection, stores in-memory for hot path
5. Automatic refill: when client detects 20% vouchers remaining (20 left), request new batch from server in background
6. TypeScript types: full autocomplete support for all SDK methods, payment objects, configuration options
7. Error handling: clear error messages like "Nillion signing in progress, please wait..." instead of cryptographic stack traces
8. Example documentation: README includes "Hello World" example completing first payment in <15 lines of code

---

## Story 1.12: Basic Monitoring Dashboard

**As a** developer debugging payment issues,
**I want** a web dashboard showing Nillion-specific metrics in real-time,
**so that** I can visualize voucher consumption, MPC signing latency, and settlement events.

### Acceptance Criteria

1. Next.js dashboard app (`/apps/dashboard`) deployed locally at http://localhost:3001, connects to WebSocket server metrics endpoint
2. **Nillion Voucher Depletion Graph:** Line chart showing remaining vouchers per session over time, updates every 5 seconds
3. **MPC Signing Latency Tracking:** Histogram showing Nillion signing latency for handshake (voucher generation) and settlements, p50/p95/p99 percentiles displayed
4. **Nillion Storage Events:** Log view showing backup success, recovery events with timestamps and session IDs
5. **Transaction Success/Failure Counts:** Real-time counter showing successful payments, failed verifications with Nillion-specific error codes (INVALID_SIGNATURE, EXPIRED_VOUCHER, etc.)
6. **Settlement Timeline:** Visual timeline showing when monetary thresholds triggered settlements, amount settled, Nillion signing duration
7. Responsive design: works on desktop (1920×1080 primary), tablet secondary, mobile tertiary per UI goals
8. Dark mode support: toggle between light/dark theme matching developer tool preferences

---

## Story 1.13: Performance Benchmarking Under Load

**As a** technical lead validating PoC success,
**I want** automated performance benchmarks measuring latency and throughput,
**so that** I can prove <100ms p95 latency and 1,000+ pkt/sec targets are met.

### Acceptance Criteria

1. Load testing script (`/packages/server-sdk/benchmarks/load-test.ts`) uses WebSocket client to simulate 1,000 pkt/sec sustained load
2. Latency measurement: record timestamp at client send, receive server response, calculate round-trip time for each packet
3. Benchmark report outputs p50, p95, p99 latency percentiles plus min/max values after 60-second test run
4. Throughput validation: confirm 60,000 total packets sent/received in 60-second window (1,000 pkt/sec average)
5. Resource monitoring: capture server CPU usage, memory footprint, voucher pool access time during load test
6. Pass/fail criteria: p95 latency <100ms AND sustained 1,000+ pkt/sec throughput = PASS (logs "✅ Epic 1 Performance Target MET")
7. Geographic latency simulation: artificially inject 15-50ms network delay to simulate US-US, US-EU latency variance
8. Benchmark CI integration: GitHub Actions runs benchmark on every PR to main branch, fails build if performance regresses >10%

---

## Story 1.14: External Developer Integration Testing

**As a** product manager validating developer experience,
**I want** external Nillion developers to attempt SDK integration with time tracking,
**so that** I can validate <4 hour integration time goal before declaring Epic 1 success.

### Acceptance Criteria

1. Recruit 3 external Nillion developers (from Nillion Discord, not project contributors) for integration testing
2. Provide developers with: SDK npm package, documentation README, Optimism testnet faucet access, server endpoint URL
3. Track time from `npm install @nillion/micropayments` to first successful Nillion-signed payment received
4. Success criteria: 2 out of 3 developers complete integration in <4 hours (target from MVP goals)
5. Feedback collection: structured survey asking about pain points, unclear documentation, Nillion-specific confusion
6. Documentation improvements: incorporate feedback into README, add FAQ section addressing common issues discovered
7. Friction log: record every point where developer got stuck (missing error message, unclear config, Nillion jargon)
8. Final validation: after doc improvements, recruit 1 additional developer for confirmation test (should complete in <3 hours)

---

## Story 1.15: Epic 1 Decision Gate Validation

**As a** project stakeholder deciding GO/NO-GO on Nillion partnership,
**I want** comprehensive Epic 1 success criteria validation report,
**so that** I can make informed decision whether to proceed to Epic 2 based on objective data.

### Acceptance Criteria

1. **Criterion 1 - Nillion Integration Complete:** Document all 3 Nillion features working (voucher pre-signing ✅, Storage backup ✅, MPC settlements ✅) with test evidence
2. **Criterion 2 - Performance Target Met:** Benchmark report shows <100ms p95 latency for 1,000 pkt/sec sustained over 60 seconds using Nillion vouchers
3. **Criterion 3 - Privacy Validation:** Verification test confirms Nillion MPC signatures on every packet + settlement amounts confidential on-chain (blockchain explorer screenshot)
4. **Criterion 4 - Crash Recovery Works:** Crash simulation test video showing Nillion Storage successfully restores session after server kill in <10 sec recovery time
5. **Criterion 5 - Ethereum Optimism Complete:** Full channel lifecycle documented: open → stream 1000 pkts → settle → close with transaction hashes on Optimism Sepolia
6. **Criterion 6 - Developer Experience Validated:** 2 out of 3 external Nillion developers completed integration in <4 hours (survey results attached)
7. **Criterion 7 - Economic Viability Proven:** Cost calculation shows Nillion costs <$0.20 per session (100 vouchers × $0.001 + settlement $0.10) at hypothetical pricing
8. **GO Decision:** If all 7 criteria met, document GO recommendation for Epic 2 (Bitcoin Lightning). If 0-4 criteria met, document NO-GO recommendation with pivot options

---
