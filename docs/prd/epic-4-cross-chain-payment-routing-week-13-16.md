# Epic 4: Cross-Chain Payment Routing (Week 13-16)

**Expanded Goal:**

Enable seamless cross-chain payments across all 3 blockchain ecosystems (Ethereum ↔ Bitcoin ↔ Solana) using ILP-inspired routing with Nillion MPC-signed atomic swaps. Implement intelligent route discovery algorithm, integrate real-time exchange rate oracles (Chainlink for ETH, Pyth for SOL), and provide robust rollback handling for failed cross-chain transactions. This epic delivers the interoperability vision where users funded on any chain can pay merchants accepting any other chain, with Nillion MPC signatures securing atomic swaps and maintaining privacy-preserving settlements throughout the swap process.

---

## Story 4.1: Cross-Chain Routing Algorithm Design

**As a** developer building cross-chain payment routing,
**I want** a route discovery algorithm finding optimal payment paths across chains,
**so that** I can automatically route payments from source chain to destination chain with minimal fees and latency.

### Acceptance Criteria

1. **Graph Representation:** Model 3 chains as nodes (ETH, BTC, SOL) with edges representing swap pairs, edge weights = fees + latency
2. **Dijkstra's Shortest Path:** Implement algorithm finding minimum-cost route from source to destination (e.g., BTC → ETH may route direct or via BTC → SOL → ETH if cheaper)
3. **Route Evaluation:** For each source-destination pair, calculate: total fees (swap fees + settlement costs), estimated latency, liquidity availability
4. **Direct vs Multi-Hop:** Support both direct swaps (BTC → ETH) and multi-hop routing (BTC → SOL → ETH) based on cost optimization
5. **Liquidity Awareness:** Query available liquidity on each swap pair before routing, fail fast if insufficient liquidity detected
6. **Route Caching:** Cache optimal routes for 5 minutes (reduce computation), invalidate when liquidity changes significantly
7. **Fallback Routes:** If primary route fails, automatically attempt alternate route (e.g., if BTC → ETH fails, try BTC → SOL → ETH)
8. **Documentation:** Algorithm design document explains routing logic, includes worked examples for all 9 possible source-destination combinations

---

## Story 4.2: Ethereum ↔ Bitcoin Atomic Swap (BTC/ETH Pair)

**As a** user with Bitcoin balance wanting to pay Ethereum-based merchant,
**I want** atomic swap between Bitcoin and Ethereum with Nillion MPC signatures,
**so that** I can convert BTC to ETH trustlessly with privacy-preserving swap amounts.

### Acceptance Criteria

1. **HTLC on Bitcoin:** Create Hash Time-Locked Contract on Bitcoin testnet with Nillion MPC-signed hash lock
2. **HTLC on Ethereum:** Create corresponding HTLC on Optimism testnet with same hash, swap ratio based on oracle price
3. **Atomic Execution:** Bitcoin HTLC unlocks only when Ethereum HTLC settles successfully (atomicity guaranteed)
4. **Nillion Signature Integration:** Swap parameters (amounts, hash) signed by Nillion Private Compute for privacy
5. **Timeout Handling:** Bitcoin HTLC expires in 24 hours, Ethereum HTLC expires in 12 hours (prevents deadlock)
6. **Swap Completion:** Measure end-to-end latency from swap initiation to both HTLCs settled, target <500ms
7. **Rollback Test:** Simulate timeout scenario, verify funds return to sender on both chains with Nillion-signed refunds
8. **On-Chain Verification:** Both swap transactions visible on Bitcoin testnet explorer (mempool.space) and Optimism explorer (optimistic.etherscan.io)

---

## Story 4.3: Bitcoin ↔ Solana Atomic Swap (BTC/SOL Pair)

**As a** user with Bitcoin balance wanting to pay Solana-based merchant,
**I want** atomic swap between Bitcoin and Solana with Nillion MPC signatures,
**so that** I can convert BTC to SOL trustlessly with privacy-preserving swap amounts.

### Acceptance Criteria

1. **HTLC on Bitcoin:** Create Hash Time-Locked Contract on Bitcoin testnet with Nillion MPC-signed hash lock (reuse Epic 4.2 Bitcoin HTLC)
2. **Escrow on Solana:** Deploy escrow program on Solana devnet (HTLCs less common on Solana, use escrow + hash reveal pattern)
3. **Atomic Execution:** Bitcoin HTLC unlocks only when Solana escrow releases funds to recipient (atomicity via hash preimage reveal)
4. **Nillion Signature Integration:** Escrow parameters (amounts, hash) signed by Nillion Private Compute for privacy
5. **Timeout Handling:** Bitcoin HTLC expires in 24 hours, Solana escrow expires in 12 hours (prevents deadlock)
6. **Swap Completion:** Measure end-to-end latency from swap initiation to both settlements, target <500ms
7. **Rollback Test:** Simulate timeout scenario, verify funds return to sender on both chains with Nillion-signed refunds
8. **On-Chain Verification:** Swap transactions visible on Bitcoin explorer and Solana Explorer (solscan.io)

---

## Story 4.4: Ethereum ↔ Solana Atomic Swap (ETH/SOL Pair)

**As a** user with Ethereum balance wanting to pay Solana-based merchant,
**I want** atomic swap between Ethereum and Solana with Nillion MPC signatures,
**so that** I can convert ETH to SOL trustlessly with privacy-preserving swap amounts.

### Acceptance Criteria

1. **HTLC on Ethereum:** Create Hash Time-Locked Contract on Optimism testnet with Nillion MPC-signed hash lock (reuse Epic 4.2 Ethereum HTLC)
2. **Escrow on Solana:** Deploy escrow program on Solana devnet (reuse Epic 4.3 Solana escrow)
3. **Atomic Execution:** Ethereum HTLC unlocks only when Solana escrow releases funds to recipient (atomicity via hash preimage reveal)
4. **Nillion Signature Integration:** Both HTLC and escrow parameters signed by Nillion Private Compute for privacy
5. **Timeout Handling:** Ethereum HTLC expires in 24 hours, Solana escrow expires in 12 hours (prevents deadlock)
6. **Swap Completion:** Measure end-to-end latency from swap initiation to both settlements, target <500ms
7. **Rollback Test:** Simulate timeout scenario, verify funds return to sender on both chains with Nillion-signed refunds
8. **On-Chain Verification:** Swap transactions visible on Optimism explorer and Solana Explorer

---

## Story 4.5: Exchange Rate Oracle Integration

**As a** cross-chain routing system,
**I want** real-time exchange rate data from decentralized oracles,
**so that** I can calculate accurate swap ratios for BTC/ETH/SOL conversions.

### Acceptance Criteria

1. **Chainlink Integration:** Connect to Chainlink Price Feeds for BTC/USD, ETH/USD, SOL/USD on Ethereum testnet
2. **Pyth Integration:** Connect to Pyth Network for SOL/USD, BTC/USD, ETH/USD on Solana devnet (redundancy + Solana native)
3. **Price Aggregation:** Calculate cross-rates (BTC/ETH, BTC/SOL, ETH/SOL) by combining USD pairs with precision handling
4. **Staleness Detection:** Reject oracle prices older than 5 minutes, fallback to secondary oracle if primary stale
5. **Price Validation:** Sanity check oracle prices against expected ranges (e.g., reject if BTC/ETH < 10 or > 50), prevent flash crash exploitation
6. **Slippage Protection:** Apply 1% slippage buffer to swap ratios (protect against price movement during swap execution)
7. **Oracle Health Monitoring:** Dashboard displays oracle status (Chainlink round ID, Pyth confidence interval, last update timestamp)
8. **Fallback Strategy:** If both oracles unavailable, reject cross-chain swaps (fail-safe, prevent incorrect swap ratios)

---

## Story 4.6: Cross-Chain Settlement Verification

**As a** cross-chain payment system,
**I want** automated verification that atomic swaps completed correctly on both chains,
**so that** I can confirm funds transferred to recipient and sender's funds locked/released appropriately.

### Acceptance Criteria

1. **Dual-Chain Monitoring:** Listen for events on both source and destination chains (e.g., Bitcoin HTLC locked + Ethereum HTLC settled)
2. **Settlement State Machine:** Track swap states: `Initiated`, `SourceLocked`, `DestinationSettled`, `Completed`, `RolledBack`
3. **Hash Preimage Verification:** Confirm hash preimage revealed on destination chain matches hash lock on source chain (proves atomicity)
4. **Nillion Signature Verification:** Verify Nillion MPC signatures on both sides of swap (validates privacy-preserving execution)
5. **Completion Notification:** Emit `crossChainSwapCompleted` event with source chain, destination chain, amount, total latency, Nillion verification status
6. **Rollback Detection:** Detect timeout scenarios, emit `crossChainSwapRolledBack` event, verify refund transactions on both chains
7. **Audit Log:** Store all cross-chain swap attempts in PostgreSQL with full transaction details for debugging and compliance
8. **Error Handling:** Handle edge cases (network partitions, one chain confirms but other times out, partial failures)

---

## Story 4.7: Cross-Chain Routing Dashboard

**As a** developer debugging cross-chain payment issues,
**I want** cross-chain routing metrics added to monitoring dashboard,
**so that** I can visualize swap status, oracle prices, route paths, and failure reasons.

### Acceptance Criteria

1. **Swap Status View:** Real-time table showing active cross-chain swaps with source chain, destination chain, status (Initiated/Locked/Settled/Completed), time elapsed
2. **Oracle Price Display:** Live ticker showing BTC/USD, ETH/USD, SOL/USD from Chainlink and Pyth with last update timestamp
3. **Route Visualization:** Graph visualization showing 3 chains as nodes, edges showing available swap pairs with current liquidity and fees
4. **Swap History Timeline:** Timeline view showing completed swaps, rollbacks, success rate per swap pair
5. **Latency Breakdown:** For each completed swap, show latency breakdown (source lock, oracle query, destination settle, total)
6. **Failure Analysis:** Log view showing failed swaps with specific error codes (ORACLE_STALE, INSUFFICIENT_LIQUIDITY, TIMEOUT, NILLION_SIGNATURE_FAILED)
7. **Cross-Chain Balance:** Display user balances across all 3 chains in unified view with USD equivalent values
8. **Responsive Design:** Cross-chain metrics integrated into existing dashboard without requiring horizontal scroll

---

## Story 4.8: Cross-Chain Performance Benchmarking

**As a** technical lead validating Epic 4 success,
**I want** cross-chain swap performance benchmarks,
**so that** I can prove <500ms end-to-end latency for all 3 swap pairs (BTC↔ETH, BTC↔SOL, ETH↔SOL).

### Acceptance Criteria

1. **Benchmark Script:** Automated test executing 10 swaps for each of the 3 pairs (30 total swaps) on testnets
2. **Latency Measurement:** Record timestamps at each stage (swap initiate, source lock, oracle query, destination settle, completion)
3. **Performance Report:** Output p50, p95, p99 latency for each swap pair, identify slowest step in each path
4. **Throughput Test:** Execute 100 swaps in parallel (limited by testnet rate limits), measure successful completion rate
5. **Pass/Fail Criteria:** All 3 swap pairs achieve p95 latency <500ms = PASS (Epic 4 performance target met)
6. **Cost Analysis:** Calculate total fees for cross-chain swap (source chain settlement + swap fees + destination chain settlement)
7. **Comparison:** Benchmark direct swaps vs multi-hop routing (e.g., BTC → ETH direct vs BTC → SOL → ETH), identify when multi-hop beneficial
8. **CI Integration:** GitHub Actions runs cross-chain benchmark weekly (not on every PR due to testnet dependency), alerts on regression

---

## Story 4.9: Epic 4 Decision Gate Validation

**As a** project stakeholder deciding whether to proceed to Epic 5,
**I want** Epic 4 success criteria validation report,
**so that** I can make informed decision about unified SDK development based on cross-chain routing results.

### Acceptance Criteria

1. **Criterion 1 - BTC ↔ ETH Swaps:** Document successful bidirectional swaps with Nillion MPC-signed HTLCs, transaction IDs on both chains
2. **Criterion 2 - BTC ↔ SOL Swaps:** Document successful bidirectional swaps with Nillion MPC-signed escrow, transaction IDs on both chains
3. **Criterion 3 - ETH ↔ SOL Swaps:** Document successful bidirectional swaps with Nillion MPC coordination, transaction IDs on both chains
4. **Criterion 4 - Route Discovery:** Demonstrate routing algorithm finds optimal path for all source-destination pairs, handles liquidity constraints
5. **Criterion 5 - Exchange Rate Oracle:** Verify Chainlink and Pyth integration working, accurate swap ratios, staleness detection functional
6. **Criterion 6 - Cross-Chain Latency:** Benchmark report shows <500ms end-to-end latency for all 3 swap pairs at p95
7. **Criterion 7 - Rollback Handling:** Demonstrate timeout scenarios tested, funds return to sender with Nillion-signed refunds on both chains
8. **Criterion 8 - Privacy Preservation:** Verify Nillion MPC signatures on all cross-chain primitives, swap amounts confidential on-chain
9. **GO Decision (All 8 Criteria Met):** Proceed to Epic 5 (Unified SDK & Developer Experience)
10. **PARTIAL GO (6-7 Criteria Met):** Identify failed criteria, assess impact on unified SDK, consider proceeding with limited cross-chain support
11. **LIMITED GO (3-5 Criteria Met):** Ship without cross-chain routing (3 independent chains only), defer Epic 4 to Phase 2, proceed to Epic 5 with simplified scope
12. **NO-GO (0-2 Criteria Met):** Cross-chain infeasible, pivot to 2-chain MVP (Ethereum + Lightning only), skip Solana and Epic 5

---
