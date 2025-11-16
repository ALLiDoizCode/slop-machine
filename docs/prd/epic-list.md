# Epic List

## Epic 1: Nillion Core + Ethereum Optimism Foundation (Week 1-6)

**Goal:** Establish foundational project infrastructure (monorepo, CI/CD, core services) while delivering the first fully functional Nillion-powered micropayment system on Ethereum Optimism. Validate all 3 core Nillion features (voucher pre-signing, Private Storage backup, MPC settlements) achieving <100ms p95 latency and 1000+ pkt/sec throughput.

**Value Delivered:** Complete end-to-end payment flow on one blockchain (Optimism) with Nillion privacy guarantees. External Nillion developers can integrate SDK and process real micropayments on testnet. Proves economic viability ($0.20/session cost target) and performance targets before multi-chain expansion.

---

## Epic 2: Bitcoin Lightning Network Integration (Week 7-9)

**Goal:** Extend Nillion voucher architecture to Bitcoin Lightning Network, demonstrating compatibility with UTXO-based chains and HTLC payment primitives. Enable developers to accept micropayments on Bitcoin while maintaining Nillion MPC privacy throughout the payment flow.

**Value Delivered:** Second payment rail (Bitcoin) expands addressable market to Bitcoin-native developers and demonstrates Nillion voucher portability beyond EVM chains. Independent test suite validates Epic 2 works in isolation without Epic 1 dependencies, proving modular architecture.

---

## Epic 3: Solana State Channel Integration (Week 10-12)

**Goal:** Implement Nillion-powered micropayments on Solana using state channels, leveraging Solana's high-performance runtime for potential throughput optimization. Deploy state channel program to Solana devnet with full lifecycle testing and monetary threshold settlements.

**Value Delivered:** Third payment rail (Solana) completes multi-chain vision and targets Solana's agent/DeFi ecosystem. All 3 major blockchain ecosystems (EVM, UTXO, Solana runtime) now support Nillion-signed micropayments, demonstrating maximum interoperability.

---

## Epic 4: Cross-Chain Payment Routing (Week 13-16)

**Goal:** Enable payments to flow seamlessly across all 3 chains (ETH ↔ BTC ↔ SOL) using ILP-inspired routing with Nillion MPC-signed atomic swaps. Implement route discovery, exchange rate oracles, and rollback handling for failed cross-chain transactions.

**Value Delivered:** Developers can accept payments on any chain regardless of user's funding source (user funded on Bitcoin can pay Ethereum-based API). Nillion MPC signatures secure atomic swaps, providing privacy-preserving cross-chain settlement with amounts confidential throughout the swap process.

---

## Epic 5: Unified SDK & Developer Experience (Week 17-18)

**Goal:** Abstract all chain-specific complexity behind a single SDK API where developers specify `chains: ['optimism', 'lightning', 'solana']` and routing happens automatically. Deliver comprehensive documentation, monitoring dashboard with unified multi-chain view, and validate <4 hour integration time with external developers.

**Value Delivered:** Production-ready developer experience matching "Stripe for micropayments" vision. External Nillion developers successfully integrate in <4 hours each (3 developers tested), documentation complete with tutorials for each chain and cross-chain examples. MVP ready for production hardening phase.

---
