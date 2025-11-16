# Next Steps

## UX Expert Prompt

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

## Architect Prompt

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
