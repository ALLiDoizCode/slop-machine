# Product Requirements Document: BIMP Protocol Implementation

**Version:** 1.0.0
**Status:** Draft
**Date:** November 17, 2025
**Product Owner:** Sarah (BMad PO Agent)
**Technical Lead:** Jonathan Green

---

## Executive Summary

This PRD defines the requirements for implementing the **BIMP (Bidirectional Interledger Micropayment Protocol)** - a lightweight protocol for streaming micropayments over HTTP/WebSocket connections designed for machine-to-machine (M2M) communication.

The implementation will deliver:
1. Reference implementation (Node.js server + client)
2. Smart contract deployment to testnets (Base, Optimism)
3. Multi-language SDKs (TypeScript, Python, Go, Rust)
4. RFC specification for standardization (IETF/W3C submission)
5. Demo applications showcasing real-world use cases

**Market Opportunity:** The M2M payment space is underserved with existing solutions either too complex (ILP/STREAM), ledger-specific (Lightning/Raiden), or not designed for M2M use cases. BIMP fills this gap with 90% less complexity while maintaining production-grade capabilities.

---

## Table of Contents

1. [Goals & Objectives](#1-goals--objectives)
2. [User Personas](#2-user-personas)
3. [Requirements](#3-requirements)
4. [Implementation Phases](#4-implementation-phases)
5. [Technical Specifications](#5-technical-specifications)
6. [Success Metrics](#6-success-metrics)
7. [Timeline & Milestones](#7-timeline--milestones)
8. [Dependencies & Risks](#8-dependencies--risks)
9. [Open Questions](#9-open-questions)

---

## 1. Goals & Objectives

### 1.1 Primary Goals

**G1: Protocol Standardization**
Establish BIMP as a recognized standard for M2M micropayments through formal RFC submission to IETF or W3C.

**G2: Developer Adoption**
Enable developers to integrate BIMP into their applications within 30 minutes using comprehensive SDKs and documentation.

**G3: Production Readiness**
Deliver production-quality reference implementation with full test coverage, security audits, and performance benchmarks.

**G4: Ecosystem Growth**
Demonstrate BIMP viability through working demo applications across IoT, AI agents, and API monetization use cases.

**G5: Multi-Chain Support**
Support multiple blockchain ecosystems (Ethereum L2s, Lightning Network) through pluggable settlement adapters.

### 1.2 Success Criteria

- ✅ RFC draft submitted to IETF/W3C with community feedback addressed
- ✅ Reference implementation deployed to npm with >90% test coverage
- ✅ Smart contracts deployed and verified on Base and Optimism testnets
- ✅ 4 production-ready SDKs published (TypeScript, Python, Go, Rust)
- ✅ 3 working demo applications demonstrating different use cases
- ✅ Performance: <100ms latency for payment verification, >1000 msg/sec throughput
- ✅ Security: Zero critical vulnerabilities in smart contracts (audited)

### 1.3 Non-Goals (Out of Scope)

❌ Multi-hop routing (direct peer-to-peer only for v1.0)
❌ Mobile SDKs (iOS/Android) - future versions
❌ GUI wallet applications - focus on programmatic access
❌ Mainnet deployment - testnet only until security audits complete
❌ Cross-chain atomic swaps - future enhancement

---

## 2. User Personas

### Persona 1: Backend Developer (Primary)

**Name:** Alex the API Developer
**Role:** Senior Backend Engineer
**Goals:**
- Add micropayment monetization to existing REST API
- Minimal integration effort (<1 day)
- Support multiple payment methods without vendor lock-in

**Pain Points:**
- Existing payment solutions require complex account management
- High transaction fees make micropayments uneconomical
- Vendor-specific APIs create lock-in

**How BIMP Helps:**
- x402 handshake integrates with existing HTTP 402 pattern
- Payment channel abstraction works with any blockchain
- Simple SDK reduces integration to hours, not weeks

### Persona 2: IoT Developer (Secondary)

**Name:** Maya the IoT Engineer
**Role:** Embedded Systems Developer
**Goals:**
- Enable IoT devices to sell sensor data
- Low power consumption for battery-powered devices
- Reliable payments despite intermittent connectivity

**Pain Points:**
- Traditional payment APIs too heavyweight for embedded devices
- Need offline-capable payment mechanisms
- Can't afford per-transaction blockchain fees

**How BIMP Helps:**
- Lightweight protocol suitable for resource-constrained devices
- Payment channels enable offline operation with periodic settlement
- Batched settlements reduce blockchain costs by 99%

### Persona 3: AI Agent Developer (Tertiary)

**Name:** Raj the AI Researcher
**Role:** ML Engineer / AI Agent Developer
**Goals:**
- Build autonomous AI agents that can pay for services
- Enable agent-to-agent marketplaces
- Bidirectional payments (agents buy and sell)

**Pain Points:**
- Existing payment systems require human authorization
- Need programmatic, autonomous payment capabilities
- Bidirectional flows not well-supported

**How BIMP Helps:**
- Fully programmatic (no UI required)
- Native bidirectional payment support
- Signed state commitments enable trustless agent interactions

### Persona 4: Protocol Researcher (Tertiary)

**Name:** Dr. Chen the Standards Expert
**Role:** Protocol Architect
**Goals:**
- Evaluate BIMP for production deployment
- Understand security properties and trade-offs
- Contribute to protocol standardization

**Pain Points:**
- Need comprehensive specification documentation
- Require formal security analysis
- Want to participate in standards process

**How BIMP Helps:**
- Complete RFC-quality specification
- Formal threat model and security analysis
- Open standardization process through IETF/W3C

---

## 3. Requirements

### 3.1 Functional Requirements

#### FR1: Protocol Implementation

**FR1.1: HTTP 402 Handshake**
The system SHALL implement x402-based channel establishment using HTTP 402 status codes.

**Acceptance Criteria:**
- Server responds with 402 Payment Required containing channel requirements
- Client can pay setup fee via x402 protocol
- Server creates payment channel on-chain after payment verification
- Channel credentials returned to client (channelId, streamEndpoint, token)

**FR1.2: WebSocket Streaming**
The system SHALL support bidirectional payment streaming over WebSocket connections.

**Acceptance Criteria:**
- Client can upgrade HTTP connection to WebSocket using Bearer token
- CONNECT/CONNECTED handshake establishes BIMP session
- PAYMENT packets contain signed state commitments
- DATA packets support application payloads without payments
- CONTROL packets manage connection lifecycle

**FR1.3: Payment Channel Management**
The system SHALL support multiple payment channel backends through adapter interface.

**Acceptance Criteria:**
- Settlement adapters for: State Channels (Ethereum), Lightning Network, x402 direct
- Signed state commitments enable unilateral settlement
- Monotonic state numbers prevent replay attacks
- Bidirectional channels support simultaneous two-way payments

**FR1.4: State Signature Verification**
The system SHALL verify cryptographic signatures on all payment packets.

**Acceptance Criteria:**
- EIP-712 typed signature verification
- Invalid signatures rejected with error code 4010
- State number monotonicity enforced
- Signature recovery identifies payer address

#### FR2: Smart Contract Suite

**FR2.1: Channel Factory Contract**
The system SHALL provide smart contract for creating payment channels.

**Acceptance Criteria:**
- `createChannel()` function creates new bidirectional channels
- `deposit()` function allows parties to fund channels
- `settle()` function enables unilateral settlement with signed state
- `closeChannel()` function refunds remaining balances after expiry
- Events emitted for all state changes

**FR2.2: Security Properties**
Smart contracts SHALL enforce security guarantees.

**Acceptance Criteria:**
- Signature verification on settlement prevents fraud
- State number monotonicity prevents replay attacks
- Channel expiry prevents indefinite capital lockup
- Reentrancy protection on all payable functions
- Gas optimization for cost-effective settlement

#### FR3: SDK Requirements

**FR3.1: TypeScript SDK**
Provide npm package with full TypeScript support.

**Acceptance Criteria:**
- BIMPClient class for client operations
- BIMPServer class for server operations
- Settlement adapter implementations (x402, state-channel)
- Full TypeScript type definitions
- Promise-based async API
- 100% JSDoc coverage

**FR3.2: Python SDK**
Provide PyPI package with full Python support.

**Acceptance Criteria:**
- BIMPClient and BIMPServer classes
- Type hints (PEP 484)
- Async/await support via asyncio
- Settlement adapters for all backends
- Sphinx documentation

**FR3.3: Go SDK**
Provide Go module with idiomatic Go API.

**Acceptance Criteria:**
- bimp.Client and bimp.Server types
- Context support for cancellation
- Interface-based settlement adapters
- Go module with semantic versioning
- GoDoc documentation

**FR3.4: Rust SDK**
Provide Cargo package with safe Rust API.

**Acceptance Criteria:**
- BimpClient and BimpServer structs
- Async/await support via tokio
- Trait-based settlement adapters
- No unsafe code in public API
- Rustdoc documentation

#### FR4: RFC Specification

**FR4.1: IETF/W3C Submission**
Produce RFC-quality specification for standards track.

**Acceptance Criteria:**
- RFC format following IETF style guide
- Abstract, Introduction, Specification, Security Considerations, IANA Considerations
- Packet format definitions in ABNF notation
- Complete wire format specification
- Interoperability requirements
- Reference implementation citations

#### FR5: Demo Applications

**FR5.1: IoT Sensor Data Marketplace**
Demonstrate BIMP for IoT use case.

**Acceptance Criteria:**
- Simulated IoT sensor publishes temperature data
- Client pays per data point via BIMP
- <100ms latency per request
- Runs continuously for 24 hours without errors
- README with setup instructions

**FR5.2: AI Agent Service Trading**
Demonstrate bidirectional payments between agents.

**Acceptance Criteria:**
- Two AI agents buy/sell services from each other
- Bidirectional payment flows visible in logs
- Net settlement calculation shown
- Demonstrates autonomous operation
- README with architecture explanation

**FR5.3: API Monetization**
Demonstrate BIMP for API access control.

**Acceptance Criteria:**
- REST API protected with BIMP payments
- x402 handshake for channel setup
- Rate limiting based on payment amount
- Swagger/OpenAPI documentation
- Postman collection included

### 3.2 Non-Functional Requirements

#### NFR1: Performance

**NFR1.1: Latency**
- Signature verification: <50ms (p95)
- WebSocket message round-trip: <100ms (p95)
- Channel creation (on-chain): <15 seconds (Base L2)

**NFR1.2: Throughput**
- Single connection: >1000 messages/second
- Single server: >10,000 concurrent connections
- Payment verification: >5000 signatures/second

**NFR1.3: Resource Usage**
- Memory per connection: <1MB
- CPU per connection: <5%
- Bandwidth overhead: <10% of application data

#### NFR2: Security

**NFR2.1: Smart Contract Security**
- Zero critical vulnerabilities (audited)
- Reentrancy protection verified
- Gas limit checks on all loops
- Access control enforced

**NFR2.2: Protocol Security**
- TLS 1.3+ required for all connections
- Signature verification on all payments
- Rate limiting prevents DoS
- Replay attack protection via nonces

#### NFR3: Reliability

**NFR3.1: Availability**
- Reference implementation: 99.9% uptime
- Graceful degradation under load
- Automatic reconnection with exponential backoff
- Circuit breaker for unhealthy backends

**NFR3.2: Data Integrity**
- Message delivery guarantees documented
- Idempotent operations where possible
- Audit logs for all state changes
- Transaction atomicity for settlements

#### NFR4: Usability

**NFR4.1: Developer Experience**
- "Hello World" example in <30 lines of code
- Integration time: <4 hours for basic use case
- Error messages include resolution steps
- Debug logging at multiple levels

**NFR4.2: Documentation**
- Getting Started guide (<10 minutes)
- API reference (100% coverage)
- Architecture deep-dive
- Security best practices
- Troubleshooting guide

#### NFR5: Maintainability

**NFR5.1: Code Quality**
- Test coverage: >90% for all SDKs
- Linting: Zero warnings
- Static analysis: Zero high/critical issues
- Dependency updates: Monthly cadence

**NFR5.2: Monitoring**
- Prometheus metrics for all operations
- Structured logging (JSON)
- OpenTelemetry tracing support
- Health check endpoints

---

## 4. Implementation Phases

### Phase 1: Core Protocol & Reference Implementation (Weeks 1-4)

**Deliverables:**
- Node.js reference implementation (client + server)
- Payment channel smart contracts
- x402 handshake integration
- WebSocket streaming implementation
- Unit tests (>90% coverage)
- Integration tests

**Dependencies:**
- ethers.js for blockchain interaction
- ws library for WebSocket
- x402 SDK for handshake

**Exit Criteria:**
- All unit tests passing
- Integration tests demonstrate complete flow
- Performance benchmarks meet targets
- Security scan shows zero critical issues

### Phase 2: Smart Contract Deployment (Weeks 2-3)

**Deliverables:**
- Smart contracts deployed to Base testnet
- Smart contracts deployed to Optimism testnet
- Contract verification on block explorers
- Deployment scripts and documentation
- Gas cost analysis

**Dependencies:**
- Phase 1 smart contracts
- Testnet ETH for gas
- Hardhat deployment scripts

**Exit Criteria:**
- Contracts verified on Basescan/Optimistic Etherscan
- Deployment documentation complete
- Gas costs within acceptable range (<$0.01 per operation)

### Phase 3: SDK Development (Weeks 4-8)

**Deliverables:**
- TypeScript SDK (npm package)
- Python SDK (PyPI package)
- Go SDK (Go module)
- Rust SDK (Cargo package)
- SDK documentation and examples
- Language-specific integration tests

**Dependencies:**
- Phase 1 reference implementation
- Phase 2 deployed contracts

**Exit Criteria:**
- All SDKs published to package registries
- Documentation includes "Hello World" for each language
- Integration tests pass for each SDK
- API consistency across languages verified

### Phase 4: RFC Specification (Weeks 6-10)

**Deliverables:**
- RFC draft in IETF format
- Packet format specification (ABNF)
- Security considerations section
- IANA considerations section
- Interoperability test suite

**Dependencies:**
- Phase 1 reference implementation
- Community feedback on protocol design

**Exit Criteria:**
- RFC submitted to IETF or W3C working group
- At least 2 independent implementations
- Interoperability tests pass between implementations

### Phase 5: Demo Applications (Weeks 8-12)

**Deliverables:**
- IoT sensor data marketplace demo
- AI agent service trading demo
- API monetization demo
- Demo documentation and tutorials
- Video walkthroughs

**Dependencies:**
- Phase 3 SDKs
- Phase 2 deployed contracts

**Exit Criteria:**
- All demos run successfully on testnet
- Documentation enables replication
- Demos presented at conference/meetup

---

## 5. Technical Specifications

### 5.1 Technology Stack

**Backend (Node.js Reference Implementation):**
- Runtime: Node.js 20 LTS
- Language: TypeScript 5.3
- Web Framework: Express.js 4.18
- WebSocket: ws 8.14
- Blockchain: ethers.js 6.9
- Testing: Vitest
- Linting: ESLint + Prettier

**Smart Contracts:**
- Language: Solidity 0.8.24
- Framework: Hardhat
- Testing: Hardhat + Chai
- Gas Reporter: hardhat-gas-reporter
- Verification: @nomiclabs/hardhat-etherscan

**SDKs:**
- TypeScript: TypeScript 5.3, esbuild for bundling
- Python: Python 3.11+, Poetry for dependency management
- Go: Go 1.21+, Go modules
- Rust: Rust 1.75+, Cargo

**Infrastructure:**
- Networks: Base Sepolia testnet, Optimism Sepolia testnet
- RPC: Alchemy or Infura
- Deployment: Docker containers
- CI/CD: GitHub Actions

### 5.2 Architecture Patterns

**Client-Server Pattern:**
- HTTP 402 for handshake (stateless)
- WebSocket for streaming (stateful)
- Event-driven packet handling

**Adapter Pattern:**
- Pluggable settlement backends
- Common interface: `IBIMPSettlementAdapter`
- Implementations: x402, Lightning, StateChannel

**State Machine:**
- Connection states: INIT → CONNECTING → CONNECTED → STREAMING → SETTLING → CLOSED
- Transition validation ensures protocol correctness

**Security Patterns:**
- Defense in depth (transport + signature + on-chain)
- Fail-secure defaults
- Rate limiting at multiple layers

### 5.3 API Design

**Reference Implementation:**

```typescript
// Server API
const server = new BIMPServer({
  port: 8080,
  x402: {
    facilitatorUrl: 'https://facilitator.x402.org',
    network: 'base-sepolia',
    asset: '0x...'
  },
  channel: {
    factoryAddress: '0x...',
    wallet: ethers.Wallet
  },
  streaming: {
    settlementThreshold: '10000'
  }
})

await server.start()

// Client API
const client = new BIMPClient({
  wallet: ethers.Wallet,
  x402Config: { ... }
})

const session = await client.connect('https://server.com/api/resource')

await session.sendPayment(100, { request: 'data' })
const response = await session.waitForResponse()

await session.close()
```

### 5.4 Data Models

**Channel Model:**
```typescript
interface Channel {
  id: string
  client: string
  server: string
  capacity: bigint
  clientBalance: bigint
  serverBalance: bigint
  lastStateNumber: number
  expiresAt: Date
  isOpen: boolean
  isBidirectional: boolean
}
```

**Payment State:**
```typescript
interface PaymentState {
  channelId: string
  stateNumber: number
  totalClaimable: bigint
  signature: string
  timestamp: Date
}
```

**Session:**
```typescript
interface BIMPSession {
  sessionId: string
  channelId: string
  state: ConnectionState
  latestClientState: PaymentState | null
  latestServerState: PaymentState | null
  limits: {
    sendMax: bigint
    receiveMax: bigint
  }
}
```

---

## 6. Success Metrics

### 6.1 Leading Indicators (During Development)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Test Coverage | >90% | Code coverage reports |
| Build Success Rate | >95% | CI/CD pipeline |
| Code Review Turnaround | <24 hours | GitHub metrics |
| Documentation Completeness | 100% API coverage | Doc generator |
| Security Scan Results | Zero critical | Automated scans |

### 6.2 Lagging Indicators (Post-Launch)

| Metric | Target | Measurement |
|--------|--------|-------------|
| SDK Downloads | 1000+ in first month | npm/PyPI/crates.io stats |
| GitHub Stars | 100+ | GitHub metrics |
| Demo App Usage | 50+ test transactions | On-chain analytics |
| RFC Community Feedback | 10+ substantive comments | IETF/W3C forums |
| Integration Time | <4 hours average | Developer surveys |

### 6.3 Performance Benchmarks

| Operation | Target | Actual | Status |
|-----------|--------|--------|--------|
| Signature Verification | <50ms (p95) | TBD | Pending |
| WebSocket Round-Trip | <100ms (p95) | TBD | Pending |
| Throughput (msg/sec) | >1000 | TBD | Pending |
| Channel Creation | <15s (Base) | TBD | Pending |
| Memory per Connection | <1MB | TBD | Pending |

### 6.4 Quality Metrics

| Category | Metric | Target |
|----------|--------|--------|
| Reliability | Uptime | >99.9% |
| Reliability | Error Rate | <0.1% |
| Security | Critical Vulns | 0 |
| Security | Audit Score | >90 |
| Usability | Time to Hello World | <30 min |
| Usability | Documentation Score | >4.5/5 |

---

## 7. Timeline & Milestones

### 7.1 High-Level Timeline (12 weeks)

```
Week 1-4:  Phase 1 - Core Protocol
Week 2-3:  Phase 2 - Smart Contracts
Week 4-8:  Phase 3 - SDK Development
Week 6-10: Phase 4 - RFC Specification
Week 8-12: Phase 5 - Demo Applications
Week 12:   Final Testing & Documentation
```

### 7.2 Detailed Milestones

**Milestone 1: Protocol Foundation (Week 4)**
- ✅ Reference implementation complete
- ✅ Smart contracts deployed to testnet
- ✅ Integration tests passing
- ✅ Performance benchmarks baseline
- **Review Gate:** Code review + security scan

**Milestone 2: SDK Alpha Release (Week 6)**
- ✅ TypeScript SDK published
- ✅ Python SDK published
- ✅ Documentation sites live
- ✅ Example apps functional
- **Review Gate:** Developer preview feedback

**Milestone 3: Multi-Language Support (Week 8)**
- ✅ Go SDK published
- ✅ Rust SDK published
- ✅ API consistency verified
- ✅ Integration tests complete
- **Review Gate:** Cross-platform testing

**Milestone 4: Standards Submission (Week 10)**
- ✅ RFC draft submitted
- ✅ Interoperability tests defined
- ✅ Security analysis complete
- ✅ Community feedback process started
- **Review Gate:** Standards committee review

**Milestone 5: Production Ready (Week 12)**
- ✅ All demos functional
- ✅ Documentation complete
- ✅ Video tutorials published
- ✅ Performance targets met
- ✅ Security audit passed
- **Review Gate:** Production readiness checklist

### 7.3 Dependencies & Critical Path

**Critical Path:**
```
Week 1-4: Reference Implementation (CRITICAL)
  ↓
Week 2-3: Smart Contracts (CRITICAL)
  ↓
Week 4-6: TypeScript SDK (CRITICAL)
  ↓
Week 8-12: Demo Applications (CRITICAL)
```

**Parallel Tracks:**
- Go/Rust SDK development (Weeks 6-8) - parallel to Python SDK
- RFC writing (Weeks 6-10) - parallel to SDK development
- Documentation (ongoing) - parallel to all development

---

## 8. Dependencies & Risks

### 8.1 External Dependencies

**Technology Dependencies:**
- **ethers.js** - Blockchain interaction library
  - Risk: Breaking changes in v7.x
  - Mitigation: Pin to v6.x, monitor changelog
- **x402 Protocol** - Handshake layer
  - Risk: Protocol changes or instability
  - Mitigation: Vendor x402 code if needed
- **Base/Optimism Testnets** - Smart contract deployment
  - Risk: Testnet instability or resets
  - Mitigation: Support multiple testnets, local dev network

**Service Dependencies:**
- **Alchemy/Infura** - RPC providers
  - Risk: Rate limiting or downtime
  - Mitigation: Multiple provider fallback
- **GitHub** - CI/CD and hosting
  - Risk: Service outages
  - Mitigation: Local development environment

### 8.2 Risk Register

| Risk | Probability | Impact | Mitigation Strategy | Owner |
|------|-------------|--------|---------------------|-------|
| Smart contract vulnerability discovered | Medium | Critical | Professional audit, bug bounty, testnet only | Tech Lead |
| x402 protocol changes break integration | Low | High | Version pin, abstraction layer | Dev Team |
| Performance targets not met | Medium | High | Early benchmarking, profiling, optimization sprint | Tech Lead |
| RFC rejected by standards body | Low | Medium | Community engagement, reference implementations | Product Owner |
| Developer adoption lower than expected | Medium | Medium | Marketing, tutorials, hackathons | Product Owner |
| Security audit reveals critical issues | Medium | Critical | Fix before mainnet, delay launch if needed | Tech Lead |
| Testnet instability blocks development | Low | Medium | Local network for development | Dev Team |
| SDK API inconsistencies across languages | Medium | Medium | API design review, consistency checklist | Tech Lead |

### 8.3 Assumptions

**Technical Assumptions:**
- WebSocket connection stability adequate for production use
- EIP-712 signatures remain standard for typed data signing
- Payment channel concept understood by target developers
- JSON encoding overhead acceptable for performance targets

**Business Assumptions:**
- Market demand exists for M2M micropayment solutions
- Developers willing to adopt new protocol
- Testnet sufficient for initial validation
- Open-source model attracts contributors

**Resource Assumptions:**
- Development team available full-time for 12 weeks
- Testnet ETH available for deployment and testing
- RPC provider free tier sufficient for testing
- Security audit budget available if needed

---

## 9. Open Questions

**Technical Questions:**

**Q1: Should we support HTTP/2 in addition to HTTP/1.1 for handshake?**
- **Impact:** Performance improvement for multiple parallel handshakes
- **Decision Needed By:** Week 2
- **Stakeholders:** Tech Lead, Backend Developers
- **Recommendation:** Start with HTTP/1.1, add HTTP/2 in v1.1

**Q2: What is the optimal default settlement threshold?**
- **Impact:** Balance between gas costs and settlement frequency
- **Decision Needed By:** Week 3
- **Stakeholders:** Product Owner, Blockchain Engineers
- **Recommendation:** Make configurable, default to 10,000 base units

**Q3: Should Lightning Network support be in Phase 1 or Phase 2?**
- **Impact:** Timeline and complexity
- **Decision Needed By:** Week 1
- **Stakeholders:** Product Owner, Tech Lead
- **Recommendation:** Phase 1 adapter interface, Phase 2 Lightning implementation

**Business Questions:**

**Q4: Should we target IETF or W3C for RFC submission?**
- **Impact:** Standards track and community engagement
- **Decision Needed By:** Week 5
- **Stakeholders:** Product Owner, Protocol Researcher
- **Recommendation:** IETF for transport protocol, W3C for web APIs

**Q5: What license should smart contracts use?**
- **Impact:** Adoption and derivatives
- **Decision Needed By:** Week 2
- **Stakeholders:** Legal, Product Owner
- **Recommendation:** MIT license for maximum permissiveness

**Q6: Should we charge for SDK access or keep fully open source?**
- **Impact:** Business model and adoption
- **Decision Needed By:** Week 4
- **Stakeholders:** Product Owner, Management
- **Recommendation:** Fully open source to maximize adoption

---

## Appendices

### Appendix A: Glossary

- **BIMP** - Bidirectional Interledger Micropayment Protocol
- **x402** - HTTP 402 payment protocol for handshake layer
- **Payment Channel** - Off-chain scaling solution for high-frequency payments
- **State Commitment** - Signed message authorizing recipient to claim funds
- **Unilateral Settlement** - Ability to close channel without counterparty cooperation
- **Settlement Adapter** - Pluggable interface for different payment backends
- **EIP-712** - Ethereum standard for typed structured data hashing and signing
- **HTLC** - Hash Time-Locked Contract used in Lightning Network

### Appendix B: References

**Protocol Specifications:**
- BIMP Protocol Specification v1.0 (this repository)
- x402 Protocol: https://github.com/coinbase/x402
- Lightning Network BOLTs: https://github.com/lightning/bolts
- Interledger Protocol: https://interledger.org

**Standards:**
- RFC 7231 - HTTP Status Code 402
- RFC 6455 - WebSocket Protocol
- EIP-712 - Typed structured data hashing and signing

**Research:**
- Payment Channel Survey Paper (2016)
- State Channels: A Practical Guide (2019)
- Micropayments for Decentralized Currencies (2017)

### Appendix C: Acceptance Criteria Checklist

This checklist must be completed before considering the project "done":

**Phase 1: Core Protocol**
- [ ] Reference implementation builds without errors
- [ ] All unit tests passing (>90% coverage)
- [ ] Integration tests demonstrate complete flow
- [ ] Performance benchmarks meet targets
- [ ] Security scan shows zero critical issues
- [ ] Code review completed and approved

**Phase 2: Smart Contracts**
- [ ] Contracts deployed to Base Sepolia
- [ ] Contracts deployed to Optimism Sepolia
- [ ] Contracts verified on block explorers
- [ ] Gas costs within acceptable range
- [ ] Deployment documentation complete

**Phase 3: SDKs**
- [ ] TypeScript SDK published to npm
- [ ] Python SDK published to PyPI
- [ ] Go SDK published as Go module
- [ ] Rust SDK published to crates.io
- [ ] All SDKs have "Hello World" examples
- [ ] API consistency verified across languages
- [ ] SDK documentation complete

**Phase 4: RFC**
- [ ] RFC draft in IETF format
- [ ] Packet formats specified in ABNF
- [ ] Security considerations complete
- [ ] Submitted to IETF or W3C
- [ ] Community feedback process initiated

**Phase 5: Demos**
- [ ] IoT demo functional
- [ ] AI agent demo functional
- [ ] API monetization demo functional
- [ ] All demos documented with READMEs
- [ ] Video walkthroughs published

**Final Acceptance:**
- [ ] All acceptance criteria met
- [ ] Documentation complete and reviewed
- [ ] Performance targets achieved
- [ ] Security audit passed (if required)
- [ ] Stakeholder sign-off obtained

---

**Document Status:** Draft
**Next Review Date:** TBD
**Approval Required From:**
- [ ] Product Owner (Sarah)
- [ ] Technical Lead (Jonathan Green)
- [ ] Security Lead
- [ ] Engineering Manager

---

*This PRD is a living document and will be updated as requirements evolve and implementation progresses.*

