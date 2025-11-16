# Out of Scope for MVP

**The following features are explicitly excluded from the MVP (18-week timeline) and deferred to Phase 2 (post-MVP) or future releases:**

## Deferred to Phase 2 (Months 5-8)

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

## Explicitly Not Included (May Never Be Prioritized)

- ❌ **Custom MPC cryptography** - Only audited libraries and Nillion SDK used; no custom MPC implementation
- ❌ **Layer 1 Ethereum support** - Optimism L2 only for MVP; Ethereum L1 fees prohibitive for micropayments
- ❌ **Payment channel routing (Lightning-style)** - Direct peer-to-peer channels only; network-wide routing (Lightning Network's routing table) not applicable to use case
- ❌ **Privacy coin integration** - Ethereum/Bitcoin/Solana sufficient for MVP; privacy-focused chains (Monero, Zcash) not prioritized

## Conditional Features (Depend on Partnership/Budget)

- ⚠️ **Nillion Private Compute integration** - Conditional on Nillion partnership pricing <$0.001/operation; if pricing prohibitive, pivot to client-side signing (Option A) or abandon Nillion showcase
- ⚠️ **Cross-chain routing (Epic 4)** - Can be descoped if Week 16 decision gate fails; ship 3 independent chains without routing, defer Epic 4 to Phase 2
- ⚠️ **Solana integration (Epic 3)** - Can be descoped to 2-chain MVP (Ethereum + Lightning) if Week 12 decision gate fails or timeline slips

---
