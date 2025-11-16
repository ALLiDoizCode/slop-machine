# Requirements

## Functional Requirements

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

## Non-Functional Requirements

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
