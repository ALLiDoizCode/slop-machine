# Epic 1: Foundation & Protocol Core

**Status:** Pending
**Priority:** Critical
**Dependencies:** None (Foundation Epic)
**Estimated Duration:** 4 weeks

---

## Epic Goal

Establish the foundational project infrastructure and implement the core BIMP protocol, including x402 handshake, WebSocket streaming, payment channel management, and signature verification. This epic delivers a working reference implementation capable of establishing channels, streaming payments bidirectionally, and settling on-chain.

**Value Delivery:** By the end of this epic, developers will have a functioning BIMP protocol implementation that can:
- Establish payment channels via x402 handshake
- Stream micropayments bidirectionally over WebSocket
- Verify cryptographic signatures for security
- Settle channels on-chain with smart contracts

---

## Stories

### Story 1.1: Project Setup & Monorepo Configuration

**As a** developer,
**I want** a properly configured Turborepo monorepo with TypeScript, linting, and testing,
**so that** I can develop consistently across all packages with automated quality checks.

**Acceptance Criteria:**
1. Turborepo initialized with workspace configuration in root
2. Root package.json with shared scripts (build, test, lint, typecheck)
3. TypeScript 5.3 configured with strict mode in root tsconfig.json
4. ESLint + Prettier configured with shared rules across packages
5. Vitest configured for unit testing with coverage reporting
6. packages/ directory structure created with protocol, contracts, shared subdirectories
7. .gitignore configured to exclude node_modules, dist, coverage
8. CI/CD pipeline (GitHub Actions) runs lint + typecheck + test on PR
9. README with setup instructions (npm install, npm run build, npm test)
10. All commands run successfully and produce zero errors/warnings

**Priority:** Critical
**Estimate:** 4 hours
**Dependencies:** None

---

### Story 1.2: Core Protocol Types & Interfaces

**As a** protocol implementer,
**I want** TypeScript type definitions for all BIMP protocol packets and interfaces,
**so that** I have type-safe development and clear protocol boundaries.

**Acceptance Criteria:**
1. `packages/protocol/src/types.ts` defines all BIMP packet types
2. Packet types include: CONNECT, CONNECTED, PAYMENT, DATA, CONTROL, ERROR
3. PaymentState interface defined with channelId, stateNumber, totalClaimable, signature
4. Channel interface defined with id, parties, balances, expiry
5. IBIMPSettlementAdapter interface defined for pluggable backends
6. All types exported from packages/protocol/src/index.ts
7. 100% JSDoc coverage on all exported types
8. Unit tests validate type definitions compile without errors

**Priority:** Critical
**Estimate:** 3 hours
**Dependencies:** Story 1.1

---

### Story 1.3: x402 Handshake Integration

**As a** BIMP client,
**I want** to establish a payment channel using the x402 HTTP 402 handshake,
**so that** I can set up a channel before streaming payments.

**Acceptance Criteria:**
1. Client sends HTTP GET request to protected resource
2. Server responds with 402 Payment Required status and x402 payment details
3. Client pays setup fee via x402 protocol (using x402 SDK)
4. Server verifies x402 payment receipt
5. Server creates payment channel on-chain (state channel contract)
6. Server returns channel credentials (channelId, streamEndpoint, bearerToken)
7. Client stores credentials for WebSocket upgrade
8. Full handshake flow completes in <30 seconds
9. Unit tests mock x402 SDK and verify handshake logic
10. Integration test uses testnet to verify end-to-end flow

**Priority:** High
**Estimate:** 6 hours
**Dependencies:** Story 1.2

---

### Story 1.4: WebSocket Connection & BIMP Session Establishment

**As a** BIMP client,
**I want** to upgrade my HTTP connection to WebSocket and establish a BIMP session,
**so that** I can stream payments bidirectionally.

**Acceptance Criteria:**
1. Client upgrades connection to WebSocket using bearer token from x402 handshake
2. Server validates bearer token and accepts WebSocket upgrade
3. Client sends CONNECT packet with channelId
4. Server validates channelId and responds with CONNECTED packet
5. CONNECTED packet includes session limits (sendMax, receiveMax)
6. Client and server enter STREAMING state after CONNECTED
7. Connection lifecycle tracked in state machine (INIT → CONNECTING → CONNECTED → STREAMING)
8. Invalid tokens rejected with 401 Unauthorized
9. Invalid channelId rejected with BIMP ERROR packet (error code 4000)
10. Unit tests verify state transitions and error handling

**Priority:** High
**Estimate:** 5 hours
**Dependencies:** Story 1.3

---

### Story 1.5: Payment Packet Signing & Verification

**As a** BIMP protocol participant,
**I want** to sign and verify payment state commitments using EIP-712,
**so that** payments are cryptographically secure and enforceable on-chain.

**Acceptance Criteria:**
1. Payment packet contains: channelId, stateNumber, totalClaimable, signature
2. Signature generated using EIP-712 typed data signing
3. State numbers are monotonically increasing (prevents replay attacks)
4. Signature verification recovers payer address
5. Invalid signatures rejected with error code 4010 (Invalid Signature)
6. Non-monotonic state numbers rejected with error code 4011 (Invalid State Number)
7. Signature verification completes in <50ms (p95)
8. Unit tests verify signature generation and verification logic
9. Integration tests verify signature compatibility with smart contracts

**Priority:** Critical
**Estimate:** 6 hours
**Dependencies:** Story 1.4

---

### Story 1.6: Bidirectional Payment Streaming

**As a** BIMP protocol participant,
**I want** to send and receive payment packets bidirectionally over the WebSocket connection,
**so that** both parties can stream value simultaneously.

**Acceptance Criteria:**
1. Client can send PAYMENT packets to server with signed state commitments
2. Server can send PAYMENT packets to client with signed state commitments
3. Both parties maintain separate balances (clientBalance, serverBalance)
4. Each PAYMENT packet updates the respective balance
5. DATA packets can be interleaved with PAYMENT packets for application payloads
6. Payment verification is asynchronous (doesn't block message handling)
7. Throughput: >1000 messages/second on single connection
8. Memory per connection: <1MB
9. Unit tests verify bidirectional payment logic
10. Integration tests demonstrate simultaneous two-way payments

**Priority:** High
**Estimate:** 6 hours
**Dependencies:** Story 1.5

---

### Story 1.7: Settlement Adapter Interface

**As a** protocol implementer,
**I want** a pluggable settlement adapter interface,
**so that** BIMP can support multiple payment backends (x402, state channels, Lightning).

**Acceptance Criteria:**
1. IBIMPSettlementAdapter interface defined with methods: createChannel, settle, closeChannel
2. x402SettlementAdapter implementation for direct x402 settlements
3. StateChannelAdapter implementation for Ethereum state channels
4. Adapter configuration in BIMPServer and BIMPClient constructors
5. Adapter selection based on server capabilities advertised in 402 response
6. Each adapter implementation has >90% test coverage
7. Unit tests mock adapter interface and verify protocol logic
8. Integration tests verify x402 adapter with x402 SDK

**Priority:** Medium
**Estimate:** 5 hours
**Dependencies:** Story 1.6

---

### Story 1.8: Channel Settlement & Closure

**As a** BIMP protocol participant,
**I want** to settle the final channel state on-chain and close the channel,
**so that** I can claim my funds and free up locked capital.

**Acceptance Criteria:**
1. Either party can initiate settlement by submitting signed state to smart contract
2. Smart contract verifies signature and state number
3. Smart contract transfers balances according to signed state
4. Channel marked as closed after successful settlement
5. Remaining funds refunded after channel expiry
6. Settlement transaction completes in <15 seconds on testnet
7. Gas costs <$0.01 per settlement (on Base L2)
8. Unit tests verify settlement logic with mocked blockchain
9. Integration tests settle channels on testnet and verify balances

**Priority:** High
**Estimate:** 6 hours
**Dependencies:** Story 1.7

---

## Epic Summary

**Total Stories:** 8
**Total Estimated Time:** 41 hours (~1 week with 1 developer, 4 weeks with parallel workstreams)
**Critical Path:** 1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6 → 1.7 → 1.8

**Success Criteria:**
- ✅ Working reference implementation with handshake, streaming, and settlement
- ✅ >90% test coverage
- ✅ Integration tests pass on testnet
- ✅ Performance benchmarks meet NFR requirements

**Next Epic:** Epic 2 - Smart Contract Suite & Testnet Deployment
