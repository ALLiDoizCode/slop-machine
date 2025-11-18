# 2. High Level Architecture

## Technical Summary

The BIMP Protocol implementation follows a **multi-package monorepo architecture** coordinating reference implementations, smart contracts, and language-specific SDKs. The core architecture employs **peer-to-peer event-driven WebSocket streaming** with **provider-initiated trust-minimized payment channels** - providers create channels on behalf of consumers after receiving x402 payment, with consumers verifying channel parameters on-chain before streaming begins.

The system uses a **two-layer economic security model**: x402 micropayments protect discovery endpoints from spam ($0.001-0.05), while blockchain payment channels enable high-throughput streaming with unilateral settlement. The protocol is designed as a **library/SDK distribution model** - a reference Node.js implementation provides canonical peer behavior (both consumer and provider roles), while language-specific SDKs (TypeScript, Python, Go, Rust) enable broad ecosystem adoption.

Smart contracts deployed on Ethereum L2s (Base, Optimism) handle settlement, implementing **EIP-712 signed state commitments** with unilateral settlement guarantees. This trust-minimized architecture balances Web3 principles (on-chain verification, cryptographic proofs) with developer experience (PRD G2: 30-minute integration).

## High Level Overview

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

## Architectural and Design Patterns

**Core Patterns:**

- **Provider-Managed Channel Creation (Trust-Minimized)** - x402 fee compensates provider for gas and operational overhead, creating sustainable business model. Consumer verifies on-chain before streaming.

- **Two-Layer Economic Security** - x402 micropayments protect discovery, blockchain channels enable streaming. Provider earns margin on x402 fees (fee $0.05 - gas $0.01 = $0.04 profit per channel).

- **Adapter Pattern (Settlement Backends)** - Pluggable `IBIMPSettlementAdapter` interface enabling multiple blockchain backends (State Channels, Lightning, direct settlement) without protocol changes.

- **State Machine Pattern (Connection Lifecycle)** - Explicit state transitions: `INIT → DISCOVERING → PAYING_X402 → AWAITING_CHANNEL → VERIFYING_CHANNEL → CONNECTING → CONNECTED → STREAMING → SETTLING → CLOSED`

- **Circuit Breaker Pattern (Blockchain RPC + x402 Facilitator)** - Protects against external dependency failures. Opens circuit after 5 consecutive failures, 60s timeout.

- **Defense in Depth** - TLS transport + EIP-712 signature verification + on-chain settlement + x402 payment verification

- **Blockchain as Source of Truth** - All channel verification queries blockchain state, not provider claims

---
