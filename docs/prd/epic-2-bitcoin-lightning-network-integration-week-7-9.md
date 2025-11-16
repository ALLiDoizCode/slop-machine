# Epic 2: Bitcoin Lightning Network Integration (Week 7-9)

**Expanded Goal:**

Extend the Nillion voucher architecture to Bitcoin Lightning Network, demonstrating compatibility with UTXO-based payment channels and HTLC (Hash Time-Locked Contract) primitives. Enable developers to accept Nillion MPC-signed micropayments on Bitcoin while maintaining <100ms p95 latency and 1,000+ pkt/sec throughput. Prove that Nillion vouchers are blockchain-agnostic and can secure payments on both account-based (Ethereum) and UTXO-based (Bitcoin) systems. This epic validates architectural portability and expands addressable market to Bitcoin-native developers.

---

## Story 2.1: Lightning Network Node Deployment

**As a** developer building Bitcoin Lightning integration,
**I want** a Lightning Network node (LND or CLN) running on Bitcoin testnet,
**so that** I can open Lightning channels, route HTLCs, and settle payments to Bitcoin L1.

### Acceptance Criteria

1. Evaluate both LND (Lightning Network Daemon) and CLN (Core Lightning) via feature comparison matrix and performance benchmarks
2. Deploy selected Lightning implementation (LND or CLN) as Docker container on Bitcoin testnet with persistent storage for channel database
3. Node synced to Bitcoin testnet with confirmed connection to 5+ peers (validates network connectivity)
4. REST API (LND) or JSON-RPC API (CLN) accessible from payment server, authenticated via macaroon or token
5. Test channel operations via CLI: `lncli openchannel`, `lncli sendpayment`, `lncli closechannel` all complete successfully
6. Monitoring exposed: node metrics (peer count, channel count, balance) accessible via API for dashboard integration
7. Backup configuration: Lightning channel state backed up to local filesystem every 10 minutes (disaster recovery)
8. Documentation: README includes Lightning node setup instructions, fund testnet wallet via faucet, verify sync status

---

## Story 2.2: Lightning Payment Channel Manager

**As a** payment system integrating Lightning,
**I want** a Lightning-specific payment channel manager wrapping LND/CLN APIs,
**so that** I can open, fund, route payments, and close Lightning channels with consistent interface matching Connext integration.

### Acceptance Criteria

1. `LightningChannelManager` class implements interface matching `PaymentChannelManager` from Epic 1 for consistency
2. `openChannel(peerPubkey: string, amount: satoshis)` opens Lightning channel, waits for 3 confirmations on Bitcoin testnet
3. `fundChannel(channelId: string, amount: satoshis)` adds additional funds to existing channel via cooperative transaction
4. `routePayment(invoice: string, amount: satoshis)` routes HTLC payment through Lightning Network with automatic route discovery
5. `closeChannel(channelId: string, force: boolean)` closes channel cooperatively (default) or force-closes if peer unresponsive
6. Channel state monitoring: emit events for `channelOpened`, `htlcForwarded`, `channelClosed`, `balanceLow` (80% depleted)
7. Error handling: detect insufficient inbound liquidity, routing failures, HTLC timeout scenarios with specific error codes
8. Integration tests: full channel lifecycle (open → route 100 HTLCs → close) validated on Bitcoin testnet with transaction IDs logged

---

## Story 2.3: Nillion Voucher Integration with Lightning HTLCs

**As a** payment system developer,
**I want** Nillion pre-signed vouchers attached to Lightning HTLC payments,
**so that** every Lightning micropayment carries Nillion MPC signature for privacy-preserving verification.

### Acceptance Criteria

1. Extend `PaymentPacket` Protocol Buffer schema with Lightning-specific fields: `htlc_hash`, `htlc_expiry`, `lightning_invoice`
2. During handshake, pre-sign 100 Nillion vouchers specifically for Lightning session (same voucher format, different session context)
3. Client SDK attaches Nillion voucher to HTLC payment metadata via Lightning invoice custom TLV records (Type-Length-Value)
4. Server extracts Nillion voucher from received HTLC payment metadata, verifies MPC signature before settling HTLC
5. HTLC compatibility validation: confirm Nillion MPC signatures (Ed25519) compatible with Lightning BOLT specifications
6. Voucher binding: each voucher cryptographically bound to specific HTLC via hash lock (prevents voucher reuse across different HTLCs)
7. Performance validation: voucher attachment adds <1ms overhead to HTLC creation (measured via benchmark)
8. Edge case handling: if HTLC times out before settlement, voucher marked as unused and returned to pool for reuse

---

## Story 2.4: Lightning-Specific Monitoring Dashboard

**As a** developer debugging Lightning payment issues,
**I want** Lightning-specific metrics added to monitoring dashboard,
**so that** I can visualize channel balance, routing fees, HTLC status alongside Nillion voucher metrics.

### Acceptance Criteria

1. **Channel Balance Graph:** Real-time chart showing local/remote balance for all open Lightning channels, updates every 10 seconds
2. **Routing Fee Tracker:** Display cumulative routing fees paid for outbound HTLCs, breakdown by channel
3. **HTLC Status View:** Table showing in-flight HTLCs with hash, expiry countdown, Nillion voucher ID attached, settlement status
4. **Lightning Node Health:** Node sync status, peer count, total channel capacity displayed in dashboard header
5. **Nillion+Lightning Integration Metrics:** Combined view showing vouchers consumed per Lightning payment, average HTLC latency with Nillion signature verification
6. **Settlement Timeline:** Lightning settlements (to Bitcoin L1) shown on same timeline as Ethereum settlements from Epic 1
7. Responsive design: Lightning metrics fit into existing dashboard layout without horizontal scroll
8. Dark mode: Lightning-specific charts use consistent color scheme with Epic 1 dashboard components

---

## Story 2.5: Lightning Performance Benchmarking

**As a** technical lead validating Epic 2 success,
**I want** Lightning-specific performance benchmarks,
**so that** I can prove <100ms payment confirmation and 1,000 pkt/sec throughput on Lightning Network.

### Acceptance Criteria

1. Lightning load test script routes 1,000 HTLC payments/second through Lightning channel with Nillion vouchers attached
2. Latency measurement: record time from HTLC creation to settlement confirmation, target <100ms p95 latency
3. Throughput validation: sustain 1,000 HTLC payments/second for 60 seconds (60,000 total payments) without channel capacity exhaustion
4. Comparison benchmark: measure Lightning performance with vs without Nillion voucher attachment (quantify overhead)
5. Benchmark report outputs: p50/p95/p99 latency percentiles, total routing fees paid, Nillion signing overhead percentage
6. Pass/fail criteria: p95 latency <100ms AND sustained 1,000+ pkt/sec throughput = PASS (Epic 2 performance target met)
7. Resource monitoring: Lightning node CPU usage, memory footprint, channel database size during load test
8. CI integration: GitHub Actions runs Lightning benchmark on Epic 2 PRs, validates performance doesn't regress

---

## Story 2.6: Monetary Threshold Settlements to Bitcoin L1

**As a** Lightning payment system operator,
**I want** automatic settlement from Lightning channels to Bitcoin L1 triggered by monetary thresholds,
**so that** I can batch Lightning payments economically using same threshold architecture as Ethereum.

### Acceptance Criteria

1. Extend `SettlementTrigger` from Epic 1 to support Lightning channels with same thresholds: $10, $100, $1000, $10000
2. When Lightning channel balance reaches threshold (e.g., $1000 accumulated), trigger cooperative channel close to Bitcoin testnet
3. Settlement signed by Nillion Private Compute: batch of Lightning payments collapsed to single Bitcoin transaction with MPC signature
4. Bitcoin settlement transaction visible on blockchain explorer (mempool.space or similar) with transaction ID logged
5. Settlement cost tracking: measure actual Bitcoin L1 transaction fees, validate <$0.50 target for testnet (lower than Ethereum L2)
6. Notification: emit `lightningSettlementCompleted` event with amount settled, Bitcoin txid, Nillion signing latency
7. Low-balance warnings: emit `balanceWarning` at 80% of threshold (e.g., $800 accumulated toward $1000 threshold)
8. Retry logic: if Bitcoin network congested (mempool full), retry settlement with higher fee after 10 minutes, max 3 retries

---

## Story 2.7: Epic 2 Independent Test Suite

**As a** developer ensuring Epic 2 modularity,
**I want** comprehensive test suite validating Lightning integration works in isolation,
**so that** I can prove Epic 2 succeeds without depending on Epic 1 Ethereum components.

### Acceptance Criteria

1. Test suite runs Lightning integration tests (`pnpm test:epic-2`) without importing any Epic 1 Ethereum/Connext code
2. Unit tests: Lightning channel manager, HTLC routing, Nillion voucher attachment/extraction, settlement triggers (80%+ coverage)
3. Integration tests: Lightning node interaction, channel lifecycle (open → route → close), Nillion signature verification in HTLC context
4. End-to-end test: complete payment flow from client SDK → Lightning HTLC → Nillion verification → Bitcoin L1 settlement (all on testnet)
5. Mock dependencies: Ethereum components mocked/stubbed, tests validate Lightning works standalone
6. CI pipeline: Epic 2 tests run in separate GitHub Actions job, passes independently of Epic 1 test status
7. Performance regression tests: Lightning benchmark thresholds enforced (p95 <100ms, 1000 pkt/sec), build fails if violated
8. Test documentation: README explains how to run Epic 2 tests in isolation, setup Lightning testnet node for local testing

---

## Story 2.8: Epic 2 Decision Gate Validation

**As a** project stakeholder deciding whether to proceed to Epic 3,
**I want** Epic 2 success criteria validation report,
**so that** I can make informed decision about Solana integration based on Lightning results.

### Acceptance Criteria

1. **Criterion 1 - Lightning Channel Lifecycle:** Document full lifecycle working: open → fund → route HTLCs → close on Bitcoin testnet with transaction IDs
2. **Criterion 2 - Nillion Voucher Integration:** Verify 100 vouchers pre-signed, successfully attached to Lightning payments, HTLC compatibility confirmed
3. **Criterion 3 - HTLC Compatibility:** Test evidence shows Nillion MPC signatures verified within Lightning HTLC contracts without errors
4. **Criterion 4 - Performance Target:** Benchmark report shows <100ms payment confirmation, 1,000 pkt/sec sustained throughput on Lightning
5. **Criterion 5 - Monetary Settlements:** Screenshot of Bitcoin blockchain explorer showing threshold-based settlements ($100, $1000) to Bitcoin L1
6. **Criterion 6 - Independent Testing:** Epic 2 test suite passes in isolation (GitHub Actions log showing Epic 2 tests green, Epic 1 disabled)
7. **GO Decision (All 6 Criteria Met):** Proceed to Epic 3 (Solana State Channels)
8. **PARTIAL GO (4-5 Criteria Met):** Fix issues identified, allocate 1-week extension, re-validate before Epic 3
9. **NO-GO (0-3 Criteria Met):** Defer Lightning to post-MVP, proceed directly to Epic 3 (Solana), revisit Lightning in Phase 2

---
