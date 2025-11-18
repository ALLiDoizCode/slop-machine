# 7. Core Workflows

## Workflow 1: Complete Channel Setup Flow

**Flow:** Discovery → x402 Payment → Channel Creation → Consumer Verification → WebSocket Connection → Streaming

**Critical Paths:**
- Discovery to payment: <1 second
- Payment verification: <500ms
- Channel creation: 2-15 seconds (blockchain confirmation)
- Consumer verification: <200ms (RPC call)
- WebSocket connection: <100ms

## Workflow 2: Bidirectional Payment Streaming

**Use Case:** AI Agent ↔ AI Agent simultaneous two-way payments

**State Tracking:** Each peer maintains separate signed states, net settlement calculated at close

## Workflow 3: Settlement Threshold Triggered

**Trigger:** Provider's claimable balance reaches settlement threshold (default: 10,000 wei)

**Action:** Automatic settlement transaction submitted to blockchain

## Workflow 4: Error Handling - Channel Creation Failure

**Error Types:** Insufficient gas, nonce conflict, network timeout, out of funds

**Recovery:** Automatic retry (max 3 attempts), exponential backoff, refund discovery fee on permanent failure

## Workflow 5: Consumer Verification Detects Malicious Provider

**Security:** Consumer verifies channel parameters on-chain, aborts connection if mismatch detected

**Protection:** Consumer loses only x402 fee ($0.05), not channel funds

---
