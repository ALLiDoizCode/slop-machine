# BIMP Protocol Implementation - Architecture Document

**Version:** 1.0.0
**Date:** November 18, 2025
**Status:** Draft
**Architect:** Winston (BMAD Architect Agent)

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [High Level Architecture](#2-high-level-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Data Models](#4-data-models)
5. [Components](#5-components)
6. [External APIs](#6-external-apis)
7. [Core Workflows](#7-core-workflows)
8. [REST API Specification](#8-rest-api-specification)
9. [Database Schema](#9-database-schema)
10. [Source Tree](#10-source-tree)
11. [Infrastructure and Deployment](#11-infrastructure-and-deployment)
12. [Error Handling Strategy](#12-error-handling-strategy)
13. [Coding Standards](#13-coding-standards)
14. [Testing Strategy](#14-testing-strategy)
15. [Security](#15-security)
16. [Next Steps](#16-next-steps)

---

## 1. Introduction

This document outlines the overall project architecture for **BIMP Protocol Implementation**, including backend systems, smart contracts, and SDK development. Its primary goal is to serve as the guiding architectural blueprint for AI-driven development, ensuring consistency and adherence to chosen patterns and technologies.

**Relationship to Frontend Architecture:**
This project is **backend-focused** with no significant user interface requirements. The deliverables include:
- Reference implementation (Node.js peer for consumers and providers)
- Smart contract deployment to Ethereum L2 testnets
- Multi-language SDKs (TypeScript, Python, Go, Rust)
- Demo applications (programmatic, not UI-based)

Future dashboard/monitoring UIs would require a separate Frontend Architecture Document.

### Starter Template

**Decision:** Use **Turborepo** for monorepo orchestration

**Rationale:**
- Best for monorepos with TypeScript-heavy workloads
- Built-in caching and task orchestration
- Perfect for coordinated SDK development across multiple packages
- Excellent CI/CD integration with remote caching support

For smart contracts, we use **Hardhat** (as specified in PRD) with TypeScript initialization.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-18 | 1.0.0 | Initial architecture document | Winston (Architect) |

---

## 2. High Level Architecture

### Technical Summary

The BIMP Protocol implementation follows a **multi-package monorepo architecture** coordinating reference implementations, smart contracts, and language-specific SDKs. The core architecture employs **peer-to-peer event-driven WebSocket streaming** with **provider-initiated trust-minimized payment channels** - providers create channels on behalf of consumers after receiving x402 payment, with consumers verifying channel parameters on-chain before streaming begins.

The system uses a **two-layer economic security model**: x402 micropayments protect discovery endpoints from spam ($0.001-0.05), while blockchain payment channels enable high-throughput streaming with unilateral settlement. The protocol is designed as a **library/SDK distribution model** - a reference Node.js implementation provides canonical peer behavior (both consumer and provider roles), while language-specific SDKs (TypeScript, Python, Go, Rust) enable broad ecosystem adoption.

Smart contracts deployed on Ethereum L2s (Base, Optimism) handle settlement, implementing **EIP-712 signed state commitments** with unilateral settlement guarantees. This trust-minimized architecture balances Web3 principles (on-chain verification, cryptographic proofs) with developer experience (PRD G2: 30-minute integration).

### High Level Overview

**Architectural Style:**
**Peer-to-Peer Protocol Library** with **Provider-Managed Channel Creation**

- **Core:** Protocol library implementing BIMP peer behavior (consumer and provider roles)
- **Distribution:** Language-specific SDKs wrapping core protocol
- **Settlement:** Blockchain smart contracts for trustless payment finality
- **Anti-Spam:** x402 micropayments gate discovery and channel creation
- **Orchestration:** Monorepo (Turborepo) with coordinated releases

**Repository Structure:**
**Monorepo (Turborepo-based)** enabling:
- Atomic version bumps across SDKs
- Coordinated integration testing between packages
- Simplified protocol specification updates
- Unified demo application maintenance

**Primary Interaction Flow (Provider-Creates, Consumer-Verifies):**

1. **Discovery (HTTP 402 + x402 Anti-Spam):** Consumer requests resource → Provider responds 402 with x402 challenge + channel requirements → Consumer pays discovery fee ($0.001-0.05)

2. **Channel Creation (Provider-Managed, On-Chain):** Provider creates channel via `channelFactory.createChannel(consumer, provider, capacity)` → x402 fee covers provider's gas cost + operational margin

3. **Consumer Verification (Trust-Minimized):** Consumer MUST verify channel on-chain before connecting → Validates correct consumer address, provider address, sufficient capacity → Prevents malicious providers from creating incorrect channels

4. **Session Establishment:** After verification, consumer upgrades to WebSocket → CONNECT/CONNECTED handshake establishes BIMP session

5. **Streaming (WebSocket, Bidirectional):** Bidirectional PAYMENT packets with signed EIP-712 state commitments → DATA packets carry application payloads

6. **Settlement (Unilateral, Either Peer):** Either peer can submit latest signed state to smart contract for unilateral settlement

### Architectural and Design Patterns

**Core Patterns:**

- **Provider-Managed Channel Creation (Trust-Minimized)** - x402 fee compensates provider for gas and operational overhead, creating sustainable business model. Consumer verifies on-chain before streaming.

- **Two-Layer Economic Security** - x402 micropayments protect discovery, blockchain channels enable streaming. Provider earns margin on x402 fees (fee $0.05 - gas $0.01 = $0.04 profit per channel).

- **Adapter Pattern (Settlement Backends)** - Pluggable `IBIMPSettlementAdapter` interface enabling multiple blockchain backends (State Channels, Lightning, direct settlement) without protocol changes.

- **State Machine Pattern (Connection Lifecycle)** - Explicit state transitions: `INIT → DISCOVERING → PAYING_X402 → AWAITING_CHANNEL → VERIFYING_CHANNEL → CONNECTING → CONNECTED → STREAMING → SETTLING → CLOSED`

- **Circuit Breaker Pattern (Blockchain RPC + x402 Facilitator)** - Protects against external dependency failures. Opens circuit after 5 consecutive failures, 60s timeout.

- **Defense in Depth** - TLS transport + EIP-712 signature verification + on-chain settlement + x402 payment verification

- **Blockchain as Source of Truth** - All channel verification queries blockchain state, not provider claims

---

## 3. Tech Stack

### Cloud Infrastructure

**Provider:** Not applicable for Phase 1 (testnet-only reference implementation)

**Key Services:**
- **Blockchain RPC:** Alchemy (primary), Infura (fallback)
- **Networks:** Base Sepolia (testnet), Optimism Sepolia (testnet)
- **CI/CD:** GitHub Actions
- **Package Registries:** npm, PyPI, crates.io, Go modules

### Technology Stack Table

| **Category** | **Technology** | **Version** | **Purpose** | **Rationale** |
|--------------|----------------|-------------|-------------|---------------|
| **Monorepo** | Turborepo | 1.11.x | Monorepo orchestration | Fast builds, task caching, perfect for multi-SDK coordination |
| **Package Manager** | pnpm | 8.x | Node.js package management | Efficient disk usage, faster than npm, workspace support |
| **Runtime** | Node.js | 20.11.0 LTS | JavaScript runtime | PRD requirement, LTS stability, excellent ecosystem |
| **Language (Primary)** | TypeScript | 5.3.3 | Primary development language | PRD requirement, strong typing, excellent tooling |
| **Backend Framework** | Express.js | 4.18.2 | HTTP server for discovery | PRD requirement, minimal, widely understood |
| **WebSocket Library** | ws | 8.14.2 | WebSocket streaming | PRD requirement, low-level control, performant |
| **Blockchain SDK** | ethers.js | 6.9.0 | Ethereum interaction | PRD requirement, channel creation, signature verification |
| **x402 SDK** | @coinbase/x402 | latest | x402 payment protocol | Discovery fee payment, spam protection |
| **Testing Framework** | Vitest | 1.0.x | Unit + integration tests | PRD requirement, fast, Vite-powered, Jest-compatible |
| **Linting** | ESLint + Prettier | 8.x + 3.x | Code quality | PRD requirement, consistent style |
| **Build Tool** | tsup | 8.x | TypeScript bundling | Fast esbuild-based bundler for SDKs |
| **Smart Contract Language** | Solidity | 0.8.24 | Smart contract development | PRD requirement, latest stable, audit-friendly |
| **Smart Contract Framework** | Hardhat | 2.19.x | Contract dev/test/deploy | PRD requirement, TypeScript support, excellent tooling |
| **Logging** | pino | 8.x | Structured logging | Fast, JSON structured logs, production-ready |
| **Container** | Docker | 24.x | Containerization | Reproducible builds, deployment |

**Python SDK:** Python 3.11+, Poetry 1.7.x, web3.py 6.x, pytest 7.x
**Go SDK:** Go 1.21+, go-ethereum 1.13.x, gorilla/websocket 1.5.x
**Rust SDK:** Rust 1.75+, ethers-rs 2.0.x, tokio-tungstenite 0.20.x, tokio 1.35.x

---

## 4. Data Models

### Model 1: Channel

**Purpose:** Represents a bidirectional payment channel between consumer and provider peers.

**Key Attributes:**
- `channelId`: bytes32 - Unique identifier
- `consumer`: address - Consumer peer's Ethereum address
- `provider`: address - Provider peer's Ethereum address
- `capacity`: uint256 - Total channel capacity in wei
- `consumerBalance`: uint256 - Consumer's current claimable balance
- `providerBalance`: uint256 - Provider's current claimable balance
- `lastStateNumber`: uint64 - Monotonically increasing state counter
- `settlementThreshold`: uint256 - Auto-settlement trigger amount
- `createdAt`: uint256 - Block timestamp of channel creation
- `expiresAt`: uint256 - Expiry timestamp
- `isActive`: boolean - Channel active status
- `isBidirectional`: boolean - True if both peers can receive payments

**Relationships:**
- Consumer → Channel (1:N)
- Provider → Channel (1:N)
- Channel → PaymentState (1:N)
- Channel → Session (1:1)

### Model 2: PaymentState

**Purpose:** Represents a signed state commitment within a payment channel.

**Key Attributes:**
- `channelId`: bytes32
- `stateNumber`: uint64
- `consumerClaimable`: uint256
- `providerClaimable`: uint256
- `signature`: bytes - EIP-712 signature (65 bytes)
- `signer`: address
- `timestamp`: uint256
- `nonce`: bytes32
- `isFinal`: boolean

### Model 3: Session

**Purpose:** Represents an active WebSocket streaming session.

**Key Attributes:**
- `sessionId`: string (UUID v4)
- `channelId`: bytes32
- `consumerAddress`: address
- `providerAddress`: address
- `bearerToken`: string (JWT)
- `connectedAt`: Date
- `state`: enum (CONNECTING, CONNECTED, STREAMING, CLOSING, CLOSED)
- `lastConsumerState`: PaymentState
- `lastProviderState`: PaymentState

### Model 4: DiscoverySession

**Purpose:** Tracks discovery phase before channel creation.

**Key Attributes:**
- `discoveryId`: string (UUID)
- `x402PaymentProof`: string
- `x402Amount`: uint256
- `channelId`: bytes32 | null
- `status`: enum (PAID, CHANNEL_CREATED, EXPIRED, FAILED)
- `expiresAt`: Date (5 minutes after payment)

---

## 5. Components

### Component 1: BIMPPeer (Core Protocol Engine)

**Responsibility:** Core protocol implementation supporting both consumer and provider roles.

**Key Interfaces:**
- `connect(providerUrl, options)` - Initiate connection as consumer
- `listen(port, options)` - Start listening as provider
- `sendPayment(amount, data)` - Send payment packet
- `onPayment(callback)` - Register payment received handler
- `settle()` - Trigger channel settlement

**Dependencies:** ws, ethers.js, @coinbase/x402
**Technology:** TypeScript 5.3.3, Node.js 20.11.0 LTS, Event-driven architecture

### Component 2: ChannelManager

**Responsibility:** Manages payment channel lifecycle.

**Key Interfaces:**
- `createChannel(consumer, capacity)` - Provider creates channel on-chain
- `getChannel(channelId)` - Retrieve channel state from blockchain
- `verifyChannel(channelId, expectedParams)` - Consumer verifies channel parameters
- `settleChannel(channelId, finalState, signature)` - Submit settlement transaction

**Dependencies:** ethers.js, pino, SettlementAdapter

### Component 3: StateManager

**Responsibility:** Manages off-chain payment state.

**Key Interfaces:**
- `createState(channelId, amount)` - Create new payment state
- `updateState(channelId, newState)` - Update to new state (validates monotonicity)
- `getLatestState(channelId)` - Retrieve current state
- `validateState(state, signature)` - Validate state signature and monotonicity

### Component 4: SignatureService

**Responsibility:** Handles EIP-712 signature creation and verification.

**Key Interfaces:**
- `signState(state, privateKey)` - Sign payment state with EIP-712
- `verifySignature(state, signature, expectedSigner)` - Verify signature validity

### Component 5: DiscoveryService (Provider-Side)

**Responsibility:** Handles HTTP 402 discovery endpoint for providers.

**Key Interfaces:**
- `handleDiscoveryRequest(req, res)` - HTTP handler for discovery requests
- `validateX402Payment(proof)` - Verify x402 payment with facilitator
- `issueWebSocketCredentials(channelId)` - Generate Bearer token for WebSocket

### Component 6: StreamingService

**Responsibility:** Manages WebSocket connections and packet routing.

**Key Interfaces:**
- `handleConnection(ws, channelId, bearerToken)` - Accept WebSocket connection
- `sendPacket(sessionId, packet)` - Send BIMP packet to peer
- `closeSession(sessionId, reason)` - Gracefully close session

### Component 7: SettlementAdapter (Interface)

**Responsibility:** Pluggable interface for different settlement backends.

**Key Interfaces:**
- `createChannel(params)` - Create channel on settlement backend
- `verifyChannel(channelId)` - Verify channel exists
- `settleChannel(channelId, finalState)` - Settle channel

### Component 8: WalletManager (Provider Hot Wallet)

**Responsibility:** Secure management of provider's hot wallet for channel creation.

**Key Interfaces:**
- `getAddress()` - Get wallet address
- `signTransaction(tx)` - Sign transaction
- `getNonce()` - Get next nonce (handles concurrency)

---

## 6. External APIs

### x402 Facilitator

**Purpose:** Process discovery fee micropayments and verify payment proofs.

**Base URL:** `https://facilitator.x402.org`

**Key Endpoints:**
- `POST /v1/payments` - Consumer submits x402 payment
- `GET /v1/payments/:id/verify` - Provider verifies payment

**Rate Limits:** 100 requests/minute (payment submission), 1000 requests/minute (verification)

**Integration:** Circuit breaker after 5 failures, 60s timeout, 3 retries with exponential backoff

### Alchemy RPC (Primary)

**Purpose:** Blockchain RPC provider for Base Sepolia and Optimism Sepolia.

**Base URLs:**
- Base Sepolia: `https://base-sepolia.g.alchemy.com/v2/{API_KEY}`
- Optimism Sepolia: `https://opt-sepolia.g.alchemy.com/v2/{API_KEY}`

**Rate Limits:** Free tier: 300 compute units/second (~100 requests/second)

**Fallback:** Automatic failover to Infura on Alchemy unavailability

### Infura RPC (Fallback)

**Purpose:** Backup blockchain RPC provider.

**Base URLs:**
- Base Sepolia: `https://base-sepolia.infura.io/v3/{API_KEY}`
- Optimism Sepolia: `https://optimism-sepolia.infura.io/v3/{API_KEY}`

**Circuit Breaker:** Switch to Infura after 5 consecutive Alchemy failures, reset after 60s

### Block Explorers

- Base Sepolia: `https://sepolia.basescan.org`
- Optimism Sepolia: `https://sepolia-optimism.etherscan.io`

**Use:** Contract verification, transaction inspection, debugging (not in critical path)

---

## 7. Core Workflows

### Workflow 1: Complete Channel Setup Flow

**Flow:** Discovery → x402 Payment → Channel Creation → Consumer Verification → WebSocket Connection → Streaming

**Critical Paths:**
- Discovery to payment: <1 second
- Payment verification: <500ms
- Channel creation: 2-15 seconds (blockchain confirmation)
- Consumer verification: <200ms (RPC call)
- WebSocket connection: <100ms

### Workflow 2: Bidirectional Payment Streaming

**Use Case:** AI Agent ↔ AI Agent simultaneous two-way payments

**State Tracking:** Each peer maintains separate signed states, net settlement calculated at close

### Workflow 3: Settlement Threshold Triggered

**Trigger:** Provider's claimable balance reaches settlement threshold (default: 10,000 wei)

**Action:** Automatic settlement transaction submitted to blockchain

### Workflow 4: Error Handling - Channel Creation Failure

**Error Types:** Insufficient gas, nonce conflict, network timeout, out of funds

**Recovery:** Automatic retry (max 3 attempts), exponential backoff, refund discovery fee on permanent failure

### Workflow 5: Consumer Verification Detects Malicious Provider

**Security:** Consumer verifies channel parameters on-chain, aborts connection if mismatch detected

**Protection:** Consumer loses only x402 fee ($0.05), not channel funds

---

## 8. REST API Specification

**OpenAPI 3.0 Specification** for provider discovery endpoints.

**Key Endpoints:**

1. **`GET /api/{resource}`** → 402 Payment Required
   - Returns x402 challenge + channel requirements
   - No authentication required

2. **`POST /api/{resource}/setup`** → Create channel
   - Requires `X-PAYMENT` header with x402 proof
   - Returns channelId, WebSocket endpoint, Bearer token

3. **`POST /api/{resource}/dispute`** → Report channel mismatch
   - Consumer-initiated dispute for incorrect channel parameters

4. **`GET /health`** → Health check
   - Returns service status, blockchain connectivity, x402 availability

**Response Format:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error Format:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "context": { ... }
  }
}
```

---

## 9. Database Schema

**Phase 1:** In-memory storage (Map/Set data structures)

**Rationale:**
- Testnet demos are short-lived (minutes to hours)
- Blockchain is source of truth for channels
- Simplifies Docker deployment (no database container)
- Sufficient for protocol validation

**Data Structures:**
- `discoverySessions`: Map<discoveryId, DiscoverySession> (5min TTL)
- `activeSessions`: Map<sessionId, Session> (cleanup on WebSocket close)
- `channelCache`: Map<channelId, Channel> (60s TTL, refreshed from blockchain)
- `paymentStates`: Map<channelId, PaymentState[]> (until channel settled)

**Phase 2+ (Production):** PostgreSQL schema for persistent channel state, session recovery, historical analytics, audit trail

---

## 10. Source Tree

```
bimp-protocol/                          # Monorepo root
├── apps/                               # Deployable applications
│   ├── reference-provider/             # Provider implementation
│   └── reference-consumer/             # Consumer implementation
├── packages/                           # Shared packages
│   ├── protocol-core/                  # Core BIMP protocol
│   ├── sdk-typescript/                 # TypeScript SDK (npm)
│   ├── sdk-python/                     # Python SDK (PyPI)
│   ├── sdk-go/                         # Go SDK (Go modules)
│   ├── sdk-rust/                       # Rust SDK (Cargo)
│   └── contracts/                      # Smart contracts
├── demos/                              # Demo applications
│   ├── iot-marketplace/                # IoT sensor data marketplace
│   ├── ai-agent-trading/               # AI agent service trading
│   └── api-monetization/               # API monetization demo
├── docs/                               # Documentation
│   ├── architecture.md                 # This document
│   ├── prd.md                          # Product requirements
│   └── protocol-spec.md                # BIMP protocol specification
├── scripts/                            # Monorepo scripts
├── tools/                              # Development tools
├── package.json                        # Root package.json
├── pnpm-workspace.yaml                 # pnpm workspace config
├── turbo.json                          # Turborepo configuration
└── tsconfig.json                       # Root TypeScript config
```

**Package Naming:** `@bimp/protocol-core`, `@bimp/sdk-typescript`, `@bimp/contracts`

---

## 11. Infrastructure and Deployment

**Strategy:** Docker + Docker Compose for Phase 1

**CI/CD:** GitHub Actions

**Environments:**
- **Local:** Docker Compose (development)
- **Base Sepolia Testnet:** Self-hosted or cloud VM
- **Optimism Sepolia Testnet:** Self-hosted or cloud VM
- **Mainnet:** Future, post-audit (Kubernetes cluster)

**Deployment Flow:** Local → Base Sepolia → Optimism Sepolia → Mainnet (manual approval gates)

**Rollback Strategy:**
- **Applications:** Redeploy previous Docker image (~5 minutes)
- **Smart Contracts:** Deploy new version forward (immutable, cannot rollback)

**Monitoring (Phase 1):**
- Logging: Pino JSON logs to stdout
- Health checks: `/health` endpoint
- Metrics: Manual log inspection

**Monitoring (Future):**
- Prometheus + Grafana for metrics
- Elasticsearch + Kibana for logs
- OpenTelemetry for tracing

---

## 12. Error Handling Strategy

**Error Model:** Exception-based with structured error types

**Error Hierarchy:**
```typescript
BIMPError (base)
├── DiscoveryError
├── PaymentVerificationError
├── BlockchainError
├── ChannelError
├── SignatureError
├── ProtocolError
└── StateValidationError
```

**Patterns:**

1. **Retry with Exponential Backoff** - 3 retries, 1s/2s/4s delays for transient failures
2. **Circuit Breaker** - Opens after 5 consecutive failures, 60s timeout
3. **Timeout on All Async Operations** - Prevents hanging operations
4. **Structured JSON Logging** - Pino with correlation IDs
5. **Idempotency** - Track processed x402 payment IDs to prevent duplicate channels

**Logging Standards:**
- **Levels:** trace, debug, info, warn, error, fatal
- **Format:** JSON structured logs
- **Context:** Correlation ID, channelId, operation name
- **Never log:** Secrets, private keys, signatures, JWTs

**Error Translation:**
- HTTP Layer: Map to status codes (400, 402, 500)
- WebSocket Layer: Close codes (4010-4099 client errors, 4500-4599 server errors)
- User-facing messages: Translate error codes to actionable messages

---

## 13. Coding Standards

**⚠️ MANDATORY for AI Developers**

**Core Standards:**
- **Languages:** TypeScript 5.3.3 strict mode, Node.js 20.11.0 LTS
- **Style:** ESLint + Prettier (ZERO warnings in CI)
- **Testing:** Vitest, 90%+ coverage for protocol-core and contracts
- **Imports:** Organize in 3 groups (external, @bimp/*, relative)

**Critical Rules (MUST FOLLOW):**

1. **No `console.log` in Production Code** - Use `logger` instead
2. **All API Responses Use Standard Format** - Consistent structure
3. **Never Direct Database Queries Outside Repositories** - Repository pattern
4. **All Blockchain Interactions Use Retry Logic** - Wrap in `withRetry()`
5. **All User Inputs Must Be Validated** - Validate at API boundary
6. **Secrets Must NEVER Be Hardcoded** - Environment variables only
7. **BigInt for All Blockchain Amounts** - JavaScript number loses precision
8. **Async Functions Must Handle Errors** - Try-catch or explicit error handling
9. **No Mutable Exports** - Encapsulate in classes
10. **EIP-712 Signatures Only for Payment States** - Never raw ECDSA

**Naming Conventions:**
- Files: kebab-case (`channel-manager.ts`)
- Classes: PascalCase (`ChannelManager`)
- Functions: camelCase (`createChannel`)
- Constants: UPPER_SNAKE_CASE (`DEFAULT_GAS_LIMIT`)

**Documentation:**
- JSDoc for all public APIs
- Inline comments only for complex logic (explain WHY, not WHAT)

---

## 14. Testing Strategy

**Test Pyramid:**
- **Unit Tests:** 60% (Vitest, ≥90% coverage)
- **Integration Tests:** 30% (Hardhat Network)
- **E2E Tests:** 10% (Docker Compose)

**Test Types:**

1. **Unit Tests** - Individual function testing, mock all external dependencies
2. **Integration Tests** - Component boundary testing, Hardhat Network for blockchain
3. **Smart Contract Tests** - Hardhat + Chai, ≥95% coverage, security test patterns
4. **E2E Tests** - Full protocol flow, Docker Compose environment

**AI Agent Requirements:**
- Generate unit tests for all public methods
- Cover edge cases: null, undefined, empty arrays, boundary values
- Test error conditions: invalid inputs throw expected errors
- Mock external dependencies: Never call real blockchain in unit tests
- Follow AAA pattern: Arrange, Act, Assert

**Test Data Management:**
- Factory pattern for test data generation
- Fixtures for smart contract tests
- Faker.js for random test data

**CI Integration:**
- Run all tests on every PR
- Enforce coverage thresholds (90% protocol-core, 95% contracts)
- Upload coverage to Codecov
- Total CI time: <10 minutes

---

## 15. Security

**Security Principles:**
1. **Defense in Depth** - Multiple security layers
2. **Fail-Secure** - Errors default to rejecting transactions
3. **Least Privilege** - Minimum required permissions
4. **Zero Trust** - Verify all inputs
5. **Cryptographic Integrity** - EIP-712 signatures

**Key Security Measures:**

**Input Validation:**
- Zod schemas for all API inputs
- Whitelist approach (not blacklist)
- Validate at API boundary before business logic

**Authentication & Authorization:**
- JWT Bearer tokens (5min expiry)
- Token verification on every WebSocket message
- Never trust client-provided identifiers

**Secrets Management:**
- Development: `.env` files (git-ignored)
- Production: AWS Secrets Manager / HashiCorp Vault (future)
- Validate required secrets on startup
- NEVER log secrets or include in error messages

**API Security:**
- Rate limiting (express-rate-limit)
- CORS policy (whitelist origins)
- Security headers (helmet)
- HTTPS enforcement in production
- TLS 1.3+ only

**Data Protection:**
- Encryption in transit: TLS 1.3+
- No PII storage (Ethereum addresses are public)
- Sanitize logs (partially redact IPs, limit user agent)

**Smart Contract Security:**
- Reentrancy protection (OpenZeppelin ReentrancyGuard)
- Checks-Effects-Interactions pattern
- Slither static analysis
- Professional audit before mainnet
- Gas limit checks on loops
- Access control on all functions
- Signature verification for all state changes

**Dependency Security:**
- npm audit on every CI run
- Dependabot for automated updates
- Auto-merge security patches
- Monthly dependency review

**Critical Requirements:**
- ✅ NEVER log secrets, signatures, or private keys
- ✅ NEVER hardcode secrets
- ✅ ALWAYS validate inputs
- ✅ ALWAYS use HTTPS in production
- ✅ ALWAYS verify signatures before processing payments
- ✅ ALWAYS use EIP-712 for payment states

---

## 16. Next Steps

This architecture document is now complete and ready for implementation.

### Immediate Next Steps

1. **Setup Monorepo**
   - Initialize Turborepo project
   - Configure pnpm workspaces
   - Setup package structure

2. **Deploy Smart Contracts**
   - Implement ChannelFactory.sol
   - Deploy to Base Sepolia
   - Deploy to Optimism Sepolia
   - Verify contracts on block explorers

3. **Implement Protocol Core**
   - Build core components (ChannelManager, StateManager, SignatureService)
   - Implement EIP-712 signature handling
   - Create unit tests (≥90% coverage)

4. **Build Reference Implementation**
   - Implement reference provider (apps/reference-provider)
   - Implement reference consumer (apps/reference-consumer)
   - Integration tests with Hardhat Network

5. **Develop SDKs**
   - TypeScript SDK (wraps protocol-core)
   - Python SDK (native reimplementation)
   - Go SDK (native reimplementation)
   - Rust SDK (native reimplementation)

6. **Create Demo Applications**
   - IoT marketplace demo
   - AI agent trading demo
   - API monetization demo

7. **Testing & Security**
   - Comprehensive test coverage
   - Security testing (penetration, fuzzing)
   - Professional smart contract audit

8. **Documentation & RFC**
   - API documentation
   - User guides (provider, consumer)
   - RFC specification for IETF/W3C submission

### Developer Handoff Prompts

**For Development Agents:**

```
You are implementing the BIMP Protocol based on the architecture document at
docs/architecture.md. This document is your DEFINITIVE guide.

MANDATORY REQUIREMENTS:
1. Read docs/architecture/coding-standards.md before writing ANY code
2. Follow the component architecture in Section 5 exactly
3. Use the tech stack defined in Section 3 (no substitutions)
4. Implement error handling per Section 12
5. Write tests per Section 14 (90%+ coverage)
6. Follow security requirements in Section 15

START WITH:
- Protocol-core package (packages/protocol-core)
- Implement ChannelManager, StateManager, SignatureService
- Write comprehensive unit tests

REFERENCE:
- PRD: docs/prd.md
- Protocol Spec: docs/protocol-spec.md
- Architecture: docs/architecture.md
```

**For Smart Contract Development:**

```
Implement the ChannelFactory smart contract per architecture Section 5.

REQUIREMENTS:
- Solidity 0.8.24
- Follow security patterns in Section 15
- Implement: createChannel, settleChannel, getChannel, closeChannel
- Use OpenZeppelin: ReentrancyGuard, ECDSA, EIP712
- Write comprehensive tests (≥95% coverage)
- Run Slither static analysis

DEPLOY TO:
1. Base Sepolia testnet
2. Optimism Sepolia testnet

VERIFY:
- Contracts on Basescan and Optimistic Etherscan
- Gas costs within budget (<100k gas for createChannel)
```

---

**Document Approval:**

- [x] Architect: Winston
- [ ] Technical Lead: Jonathan Green
- [ ] Product Owner
- [ ] Security Lead

---

**End of Architecture Document v1.0.0**
