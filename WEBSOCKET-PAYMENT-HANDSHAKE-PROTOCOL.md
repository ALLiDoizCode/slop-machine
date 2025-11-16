# WebSocket Session Establishment & Handshake Protocol for Payment-Enabled Streaming

**Design Date**: November 15, 2025
**Version**: 1.0
**Target Throughput**: 1000+ packets/second
**Target Latency**: <100ms per packet batch
**Use Case**: Web-native interledger micropayment protocol

---

## Executive Summary

This document specifies a complete WebSocket handshake protocol for establishing payment-enabled streaming sessions. The protocol negotiates payment terms, exchanges payment channel information, verifies funding, sets settlement thresholds, authenticates parties, and handles failures.

### Key Design Decisions

1. **Backward Compatible**: Graceful degradation to non-payment WebSocket if either party doesn't support payments
2. **Multi-Chain Support**: Negotiate which blockchain(s) to use during handshake
3. **Batched Signatures**: 100ms or 100-packet batching to achieve throughput targets
4. **State Synchronization**: Explicit acknowledgment mechanism with nonce-based ordering
5. **Security**: Challenge-response authentication, TLS 1.3 mandatory, signature verification

### Performance Targets

| Metric | Target | Achievable |
|--------|--------|------------|
| Handshake Latency | <500ms | Yes (3-5 RTT) |
| Throughput | 1000 pkt/sec | Yes (with batching) |
| Settlement Overhead | <1% of traffic | Yes (hourly settlement) |
| Payment Success Rate | >95% | Yes (with fallbacks) |

---

## 1. Protocol Overview

### 1.1 Protocol Stack

```
┌────────────────────────────────────────┐
│  Application Layer (Data + Payments)  │
├────────────────────────────────────────┤
│  Payment Protocol (This Spec)          │
├────────────────────────────────────────┤
│  WebSocket (RFC 6455)                  │
├────────────────────────────────────────┤
│  HTTP/2 or HTTP/3 (Upgrade)            │
├────────────────────────────────────────┤
│  TLS 1.3 (Mandatory)                   │
├────────────────────────────────────────┤
│  TCP or QUIC                           │
└────────────────────────────────────────┘
```

### 1.2 Session Lifecycle State Machine

```
                    ┌─────────┐
                    │  INIT   │
                    └────┬────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  NEGOTIATING │◄──┐
                  └──────┬───────┘   │
                         │           │
                         ▼           │
                  ┌──────────────┐   │
                  │  VERIFYING   │───┘ (retry)
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  ACTIVE      │◄──┐
                  └──────┬───────┘   │ (rebalance)
                         │           │
                    ┌────┼────┬──────┘
                    │    │    │
                    ▼    ▼    ▼
              ┌──────┐┌────┐┌─────────┐
              │SETTLE││CLOSE││DEPLETED │
              └──────┘└────┘└─────────┘
                    │    │       │
                    └────┼───────┘
                         ▼
                    ┌─────────┐
                    │ CLOSED  │
                    └─────────┘
```

### 1.3 Message Flow Overview

```
Client                                              Server
  │                                                    │
  ├──────── HTTP Upgrade Request ────────────────────►│
  │         (Sec-WebSocket-Extensions: payment)       │
  │                                                    │
  │◄──────── HTTP 101 Switching Protocols ───────────┤
  │         (Payment extension accepted)              │
  │                                                    │
  ├══════════ WebSocket Connection Open ═════════════┤
  │                                                    │
  ├──────── PAYMENT_HELLO ───────────────────────────►│
  │         (capabilities, supported chains)          │
  │                                                    │
  │◄──────── PAYMENT_HELLO_ACK ───────────────────────┤
  │         (selected chain, terms)                   │
  │                                                    │
  ├──────── CHANNEL_INFO ─────────────────────────────►│
  │         (channel address, capacity, proof)        │
  │                                                    │
  │◄──────── CHANNEL_INFO_ACK ────────────────────────┤
  │         (channel verified, server channel)        │
  │                                                    │
  ├──────── AUTH_CHALLENGE_RESPONSE ─────────────────►│
  │         (signed challenge)                        │
  │                                                    │
  │◄──────── SESSION_READY ───────────────────────────┤
  │         (session_id, settlement_params)           │
  │                                                    │
  ├══════════ ACTIVE SESSION ═════════════════════════┤
  │                                                    │
  ├──────── DATA + PAYMENT_COMMIT ───────────────────►│
  │         (batched, every 100ms or 100 pkts)        │
  │                                                    │
  │◄──────── PAYMENT_ACK ─────────────────────────────┤
  │         (nonce, new balance)                      │
  │                                                    │
  │        ... streaming continues ...                │
  │                                                    │
  ├──────── SETTLEMENT_REQUEST ──────────────────────►│
  │         (triggered by threshold)                  │
  │                                                    │
  │◄──────── SETTLEMENT_ACK ──────────────────────────┤
  │         (blockchain tx submitted)                 │
  │                                                    │
  ├══════════ SESSION CLOSE ══════════════════════════┤
```

---

## 2. Handshake Protocol Specification

### 2.1 Phase 1: HTTP Upgrade & Capability Negotiation

#### 2.1.1 Client: HTTP Upgrade Request

**HTTP Headers:**
```http
GET /stream HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Sec-WebSocket-Extensions: payment; version=1.0
Sec-WebSocket-Protocol: payment-stream-v1
```

**Extension Parameters** (in `Sec-WebSocket-Extensions`):
- `version`: Protocol version (semver format, e.g., "1.0")
- `chains`: Comma-separated list of supported chains (e.g., "ethereum,bitcoin,solana")
- `max_rate`: Maximum payment rate client willing to pay (e.g., "0.001 USD/packet")

**Full Example:**
```http
Sec-WebSocket-Extensions: payment; version=1.0; chains=ethereum,bitcoin; max_rate=0.001
```

#### 2.1.2 Server: HTTP 101 Response

**If payment supported:**
```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Sec-WebSocket-Extensions: payment; version=1.0; chain=ethereum
Sec-WebSocket-Protocol: payment-stream-v1
```

**If payment NOT supported (graceful degradation):**
```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```
(No `Sec-WebSocket-Extensions: payment`, client falls back to non-payment mode)

**Extension Response Parameters:**
- `version`: Agreed protocol version (MUST match client request or downgrade)
- `chain`: Selected blockchain (MUST be from client's supported list)
- `min_rate`: Minimum payment rate server requires (e.g., "0.0005 USD/packet")

### 2.2 Phase 2: Payment Capability Exchange

#### 2.2.1 Client → Server: PAYMENT_HELLO

**Message Format (JSON):**
```json
{
  "type": "PAYMENT_HELLO",
  "version": "1.0",
  "timestamp": 1700000000000,
  "client_id": "client-uuid-v4",
  "capabilities": {
    "supported_chains": [
      {
        "chain": "ethereum",
        "networks": ["mainnet", "optimism", "arbitrum"],
        "channel_types": ["raiden", "connext"],
        "max_channel_value": "10000.00 USD"
      },
      {
        "chain": "bitcoin",
        "networks": ["mainnet", "liquid"],
        "channel_types": ["lightning"],
        "max_channel_value": "5000.00 USD"
      }
    ],
    "settlement_methods": ["on_chain", "submarine_swap", "circular_rebalancing"],
    "signature_schemes": ["ecdsa_secp256k1", "schnorr"],
    "batching_support": true,
    "max_batch_size": 100,
    "max_batch_interval_ms": 100
  },
  "preferences": {
    "preferred_chain": "ethereum",
    "preferred_network": "optimism",
    "max_payment_rate": "0.001 USD/packet",
    "settlement_threshold_time_sec": 3600,
    "settlement_threshold_value": "1000.00 USD",
    "settlement_threshold_packets": 100000
  }
}
```

**Field Descriptions:**
- `version`: Protocol version (semantic versioning)
- `client_id`: Unique client identifier (UUID v4, persistent across sessions)
- `capabilities`: Hard capabilities (what client CAN support)
- `preferences`: Soft preferences (what client WANTS, negotiable)

#### 2.2.2 Server → Client: PAYMENT_HELLO_ACK

**Message Format (JSON):**
```json
{
  "type": "PAYMENT_HELLO_ACK",
  "version": "1.0",
  "timestamp": 1700000001000,
  "server_id": "server-uuid-v4",
  "selected_config": {
    "chain": "ethereum",
    "network": "optimism",
    "channel_type": "connext",
    "signature_scheme": "ecdsa_secp256k1"
  },
  "payment_terms": {
    "rate_per_packet": "0.0008 USD",
    "rate_currency": "USD",
    "accepted_tokens": [
      {
        "symbol": "USDC",
        "contract": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        "decimals": 6
      },
      {
        "symbol": "DAI",
        "contract": "0x6b175474e89094c44da98b954eedeac495271d0f",
        "decimals": 18
      }
    ]
  },
  "settlement_config": {
    "threshold_time_sec": 3600,
    "threshold_value": "1000.00 USD",
    "threshold_packets": 100000,
    "threshold_logic": "OR",
    "emergency_balance_threshold_pct": 10,
    "settlement_methods": ["submarine_swap", "on_chain"]
  },
  "batching_config": {
    "enabled": true,
    "batch_interval_ms": 100,
    "batch_count": 100,
    "adaptive_batching": true
  },
  "auth_challenge": {
    "challenge": "0x1a2b3c4d5e6f...",
    "challenge_expiry": 1700000061000
  }
}
```

**Negotiation Logic:**
- Server MUST select from client's `supported_chains`
- Server MUST support at least one of client's `settlement_methods`
- Payment rate MUST be between client's `max_payment_rate` and server's minimum
- If no mutually acceptable terms: Server sends `PAYMENT_HELLO_NACK` and closes connection

**Error Response: PAYMENT_HELLO_NACK**
```json
{
  "type": "PAYMENT_HELLO_NACK",
  "error_code": "INCOMPATIBLE_CHAINS",
  "error_message": "No mutually supported blockchain networks",
  "supported_chains": ["ethereum-mainnet"],
  "retry_after_sec": 0
}
```

**Error Codes:**
- `INCOMPATIBLE_CHAINS`: No common blockchain support
- `RATE_TOO_HIGH`: Client's max rate below server minimum
- `RATE_TOO_LOW`: Client's offered rate too low
- `UNSUPPORTED_CHANNEL_TYPE`: Channel type mismatch
- `SERVER_OVERLOADED`: Retry later

### 2.3 Phase 3: Channel Information Exchange & Verification

#### 2.3.1 Client → Server: CHANNEL_INFO

**Message Format (JSON):**
```json
{
  "type": "CHANNEL_INFO",
  "timestamp": 1700000002000,
  "channel": {
    "channel_id": "0xabc123...",
    "chain": "ethereum",
    "network": "optimism",
    "channel_type": "connext",
    "participants": [
      {
        "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
        "role": "client",
        "public_key": "0x04abc123..."
      },
      {
        "address": "0x9876...",
        "role": "router",
        "public_key": "0x04def456..."
      }
    ],
    "capacity": {
      "total": "10000.00",
      "client_balance": "5000.00",
      "counterparty_balance": "5000.00",
      "currency": "USDC"
    },
    "state": {
      "nonce": 42,
      "last_update_timestamp": 1699999000000,
      "commitment_hash": "0xabc123..."
    },
    "funding_tx": {
      "tx_hash": "0x123abc...",
      "block_number": 1234567,
      "confirmations": 12
    }
  },
  "proof": {
    "type": "channel_state_signature",
    "signature": "0x1a2b3c...",
    "signed_by": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
    "signed_data_hash": "0xdef456..."
  }
}
```

**Verification Requirements (Server MUST check):**
1. **Channel exists on-chain**: Query blockchain for channel address
2. **Sufficient balance**: `client_balance >= threshold` (e.g., $100 minimum)
3. **Valid participants**: Client address matches authenticated public key
4. **Recent state**: `last_update_timestamp` within 24 hours
5. **Signature valid**: Verify proof signature against client's public key
6. **Funding confirmed**: `confirmations >= 6` (or network-specific threshold)

#### 2.3.2 Server → Client: CHANNEL_INFO_ACK

**Success Response:**
```json
{
  "type": "CHANNEL_INFO_ACK",
  "timestamp": 1700000003000,
  "verification_status": "VERIFIED",
  "server_channel": {
    "channel_id": "0xdef456...",
    "address": "0x9876...",
    "public_key": "0x04def456...",
    "capacity": {
      "total": "20000.00",
      "server_balance": "18000.00",
      "client_balance": "2000.00",
      "currency": "USDC"
    },
    "nonce": 100
  },
  "liquidity_check": {
    "sufficient_for_session": true,
    "estimated_session_cost": "500.00 USD",
    "buffer_available": "4500.00 USD"
  }
}
```

**Failure Response:**
```json
{
  "type": "CHANNEL_INFO_NACK",
  "error_code": "INSUFFICIENT_BALANCE",
  "error_message": "Client channel balance ($50) below minimum threshold ($100)",
  "required_minimum": "100.00 USD",
  "current_balance": "50.00 USD",
  "retry_after_funding": true
}
```

**Error Codes:**
- `CHANNEL_NOT_FOUND`: Channel doesn't exist on-chain
- `INSUFFICIENT_BALANCE`: Balance below threshold
- `INVALID_STATE`: Channel state invalid or stale
- `SIGNATURE_INVALID`: Proof signature verification failed
- `COUNTERPARTY_MISMATCH`: Channel counterparty doesn't match server
- `FUNDING_UNCONFIRMED`: Not enough confirmations

### 2.4 Phase 4: Authentication & Challenge-Response

#### 2.4.1 Client → Server: AUTH_CHALLENGE_RESPONSE

**Purpose**: Prove control of payment channel keys without exposing private keys.

**Message Format (JSON):**
```json
{
  "type": "AUTH_CHALLENGE_RESPONSE",
  "timestamp": 1700000004000,
  "challenge": "0x1a2b3c4d5e6f...",
  "response": {
    "signature": "0x9a8b7c6d...",
    "public_key": "0x04abc123...",
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
    "signature_scheme": "ecdsa_secp256k1"
  },
  "nonce_commitment": {
    "initial_nonce": 43,
    "commitment_hash": "0xfedcba..."
  }
}
```

**Verification (Server):**
```javascript
// Pseudocode
function verifyAuthChallenge(message, server_challenge) {
  // 1. Check challenge matches
  if (message.challenge !== server_challenge) {
    throw new Error("Challenge mismatch");
  }

  // 2. Check challenge not expired
  if (Date.now() > challenge_expiry) {
    throw new Error("Challenge expired");
  }

  // 3. Verify signature
  const messageHash = keccak256(message.challenge);
  const recoveredAddress = ecrecover(messageHash, message.response.signature);

  if (recoveredAddress !== message.response.address) {
    throw new Error("Signature verification failed");
  }

  // 4. Check address matches channel participant
  if (recoveredAddress !== client_channel.participants[0].address) {
    throw new Error("Address doesn't match channel participant");
  }

  return true;
}
```

#### 2.4.2 Server → Client: SESSION_READY

**Success Response:**
```json
{
  "type": "SESSION_READY",
  "timestamp": 1700000005000,
  "session_id": "session-uuid-v4",
  "session_params": {
    "initial_nonce": 43,
    "settlement_thresholds": {
      "time_sec": 3600,
      "value_usd": 1000.00,
      "packet_count": 100000,
      "emergency_balance_pct": 10,
      "trigger_logic": "OR"
    },
    "batching": {
      "enabled": true,
      "interval_ms": 100,
      "count": 100,
      "adaptive": true
    },
    "payment_rate": "0.0008 USD/packet",
    "currency": "USDC",
    "heartbeat_interval_ms": 30000
  },
  "server_auth": {
    "signature": "0x5a4b3c2d...",
    "public_key": "0x04def456...",
    "address": "0x9876..."
  }
}
```

**State Transition**: Both parties move to **ACTIVE** state.

---

## 3. Active Session Protocol

### 3.1 Payment-Coupled Data Transmission

#### 3.1.1 Batched Payment Commitment

**Client → Server: DATA + PAYMENT_COMMIT**

**Message Format (Binary WebSocket Frame):**
```
┌─────────────────────────────────────────────────────┐
│ WebSocket Frame Header (2-14 bytes)                 │
├─────────────────────────────────────────────────────┤
│ Payment Header (48 bytes, fixed)                    │
│  ├─ message_type (1 byte): 0x01 = PAYMENT_COMMIT   │
│  ├─ nonce (8 bytes, uint64)                        │
│  ├─ batch_size (2 bytes, uint16)                   │
│  ├─ cumulative_value (8 bytes, uint64, in wei)     │
│  ├─ timestamp (8 bytes, uint64, unix ms)           │
│  ├─ signature_offset (4 bytes, uint32)             │
│  ├─ signature_length (2 bytes, uint16)             │
│  └─ reserved (15 bytes, zero-padded)               │
├─────────────────────────────────────────────────────┤
│ Application Data (variable length)                  │
│  └─ Payload (e.g., video chunk, API response)      │
├─────────────────────────────────────────────────────┤
│ Signature (65 bytes for ECDSA, or specified length)│
│  └─ ECDSA signature over (nonce || batch_size ||   │
│     cumulative_value || timestamp || data_hash)    │
└─────────────────────────────────────────────────────┘
```

**JSON Alternative (for debugging/readability):**
```json
{
  "type": "PAYMENT_COMMIT",
  "nonce": 43,
  "batch": {
    "size": 100,
    "cumulative_value": "0.08 USD",
    "cumulative_value_wei": "80000",
    "packets": [
      {"seq": 1, "value": "0.0008", "timestamp": 1700000006000},
      {"seq": 2, "value": "0.0008", "timestamp": 1700000006010},
      // ... 98 more packets
    ]
  },
  "channel_state": {
    "new_balance_client": "4999.92 USD",
    "new_balance_server": "5000.08 USD"
  },
  "signature": {
    "r": "0x1a2b3c...",
    "s": "0x4d5e6f...",
    "v": 27
  },
  "data": "<application payload, base64 encoded or separate binary frame>"
}
```

#### 3.1.2 Payment Acknowledgment

**Server → Client: PAYMENT_ACK**

**Message Format (JSON):**
```json
{
  "type": "PAYMENT_ACK",
  "nonce": 43,
  "status": "ACCEPTED",
  "timestamp": 1700000006100,
  "channel_state": {
    "nonce": 43,
    "client_balance": "4999.92 USD",
    "server_balance": "5000.08 USD",
    "commitment_hash": "0xabc123..."
  },
  "server_signature": {
    "r": "0x9a8b7c...",
    "s": "0x6d5e4f...",
    "v": 28
  },
  "next_nonce": 44,
  "packets_acknowledged": 100
}
```

**Acknowledgment Logic:**
1. **Verify signature**: Check client signature against committed data
2. **Verify nonce**: Ensure nonce = expected_nonce (no gaps, no replay)
3. **Verify balance math**: `new_balance = old_balance - batch_value`
4. **Update state**: Persist new channel state with signature
5. **Send ACK**: Confirm acceptance, provide server signature

**Failure Response: PAYMENT_NACK**
```json
{
  "type": "PAYMENT_NACK",
  "nonce": 43,
  "error_code": "SIGNATURE_INVALID",
  "error_message": "Signature verification failed for batch nonce 43",
  "expected_nonce": 43,
  "received_nonce": 43,
  "current_balance": "5000.00 USD",
  "retry_allowed": true
}
```

**Error Codes:**
- `SIGNATURE_INVALID`: Cryptographic signature check failed
- `NONCE_MISMATCH`: Nonce out of sequence (gap or replay)
- `INSUFFICIENT_BALANCE`: Payment exceeds client channel balance
- `BATCH_TOO_LARGE`: Batch size exceeds negotiated limit
- `RATE_LIMIT_EXCEEDED`: Too many packets/second

### 3.2 State Synchronization Mechanism

#### 3.2.1 Nonce-Based Ordering

**Nonce Progression:**
```
Session Start: nonce = 0 (or initial_nonce from SESSION_READY)
Batch 1: nonce = 1 (100 packets, $0.08)
Batch 2: nonce = 2 (100 packets, $0.08)
Batch 3: nonce = 3 (50 packets, $0.04)
...
Settlement triggered: nonce = 1000 (cumulative value = $800)
Post-settlement: nonce = 1001 (reset or continue)
```

**Nonce Rules:**
1. **Strictly increasing**: `new_nonce = old_nonce + 1` (no gaps)
2. **No replay**: Server MUST reject duplicate nonces
3. **Monotonic**: Nonce never decreases
4. **Persistent**: Survive reconnections (stored in channel state)

#### 3.2.2 Reconnection & State Recovery

**Scenario**: WebSocket connection drops mid-session

**Client Reconnection Flow:**
```
1. Client reconnects (new WebSocket connection)
2. Client sends RECONNECT message with last known nonce
3. Server checks:
   - If nonce matches: Resume from next nonce
   - If client nonce < server nonce: Client behind, sync needed
   - If client nonce > server nonce: Server behind (impossible if properly implemented)
4. Server sends SYNC message with current state
5. Session resumes
```

**RECONNECT Message:**
```json
{
  "type": "RECONNECT",
  "session_id": "session-uuid-v4",
  "last_known_nonce": 42,
  "last_known_balance": "4999.92 USD",
  "timestamp": 1700000100000
}
```

**SYNC Response:**
```json
{
  "type": "SYNC",
  "current_nonce": 43,
  "current_balance_client": "4999.84 USD",
  "current_balance_server": "5000.16 USD",
  "missing_batches": [
    {
      "nonce": 43,
      "value": "0.08 USD",
      "packets": 100,
      "timestamp": 1700000050000
    }
  ],
  "resume_from_nonce": 44
}
```

#### 3.2.3 State Conflict Resolution

**Conflict Scenarios:**

**1. Client and Server disagree on nonce:**
```
Client believes: nonce = 42, balance = $5000
Server believes: nonce = 44, balance = $4999.84

Resolution:
  - Higher nonce wins (server state is authoritative)
  - Client MUST accept server state
  - If client can't verify server signatures: Initiate settlement dispute
```

**2. Network partition during payment:**
```
Client sent: PAYMENT_COMMIT (nonce=43)
Server received: (network dropped)
Client assumes: Payment succeeded
Server assumes: Payment never happened

Resolution:
  - Client MUST wait for PAYMENT_ACK before considering payment final
  - If no ACK within timeout (e.g., 5 seconds): Retry with same nonce
  - Server MUST be idempotent: Duplicate nonce = same response
```

**3. Byzantine fault (malicious actor):**
```
Client sends: PAYMENT_COMMIT with invalid signature
Server detects: Signature verification failure

Resolution:
  - Server sends PAYMENT_NACK with error
  - Increment fraud_counter for client
  - If fraud_counter > threshold (e.g., 3): Close session, blacklist
```

### 3.3 Settlement Trigger Mechanisms

#### 3.3.1 Threshold-Based Settlement

**Multi-Condition Trigger (OR logic):**
```javascript
function shouldTriggerSettlement(state) {
  return (
    (Date.now() - state.last_settlement_time) >= config.threshold_time_ms ||
    state.cumulative_value_since_last_settlement >= config.threshold_value ||
    state.packets_since_last_settlement >= config.threshold_packets ||
    state.client_balance_pct < config.emergency_balance_threshold
  );
}
```

**Example Configuration:**
```yaml
settlement_thresholds:
  time_ms: 3600000  # 1 hour
  value_usd: 1000.00
  packet_count: 100000
  emergency_balance_pct: 10  # Trigger if balance < 10% of capacity
  trigger_logic: OR  # Any condition triggers settlement
```

**Trigger Scenarios:**

| Scenario | Time Since Last | Value Accumulated | Packets Sent | Balance Remaining | Triggered? |
|----------|----------------|-------------------|--------------|-------------------|------------|
| Normal 1 | 59 min | $800 | 95000 | 60% | No |
| Normal 2 | 61 min | $500 | 50000 | 50% | **Yes (time)** |
| High-value | 10 min | $1100 | 10000 | 80% | **Yes (value)** |
| High-volume | 5 min | $200 | 110000 | 70% | **Yes (packets)** |
| Emergency | 2 min | $50 | 5000 | 8% | **Yes (balance)** |

#### 3.3.2 Settlement Initiation

**Either Party Can Initiate:**

**Client → Server: SETTLEMENT_REQUEST**
```json
{
  "type": "SETTLEMENT_REQUEST",
  "timestamp": 1700003600000,
  "current_nonce": 1000,
  "trigger_reason": "THRESHOLD_TIME",
  "settlement_details": {
    "cumulative_value": "800.00 USD",
    "packets_settled": 100000,
    "time_since_last_settlement_sec": 3601,
    "final_balance_client": "4200.00 USD",
    "final_balance_server": "5800.00 USD"
  },
  "settlement_method": "submarine_swap",
  "settlement_signature": {
    "r": "0x1a2b3c...",
    "s": "0x4d5e6f...",
    "v": 27
  }
}
```

**Server → Client: SETTLEMENT_ACK**
```json
{
  "type": "SETTLEMENT_ACK",
  "timestamp": 1700003600500,
  "status": "ACCEPTED",
  "settlement_id": "settlement-uuid-v4",
  "settlement_method": "submarine_swap",
  "blockchain_tx": {
    "tx_hash": "0xabc123...",
    "chain": "ethereum",
    "network": "optimism",
    "block_number": 1234600,
    "status": "pending"
  },
  "estimated_finality_sec": 60,
  "server_signature": {
    "r": "0x9a8b7c...",
    "s": "0x6d5e4f...",
    "v": 28
  }
}
```

**Settlement Methods (Preference Order):**
1. **Circular rebalancing** (fastest, cheapest, <1 sec)
2. **Submarine swap** (medium speed, medium cost, 10-60 min)
3. **On-chain settlement** (slowest, most expensive, last resort)

#### 3.3.3 Post-Settlement State

**After Settlement:**
```json
{
  "type": "SETTLEMENT_COMPLETE",
  "settlement_id": "settlement-uuid-v4",
  "status": "CONFIRMED",
  "blockchain_tx": {
    "tx_hash": "0xabc123...",
    "confirmations": 12,
    "finalized": true
  },
  "new_channel_state": {
    "nonce": 1001,
    "client_balance": "4200.00 USD",
    "server_balance": "5800.00 USD",
    "cumulative_settled": "800.00 USD",
    "settlement_count": 1
  },
  "session_status": "ACTIVE",
  "resume_payment": true
}
```

**Session Continues**: Payments resume with `nonce = 1001`.

---

## 4. Error Handling & Recovery

### 4.1 Connection Failures

#### 4.1.1 Temporary Network Interruption

**Scenario**: WiFi drops for 5 seconds, reconnects

**Recovery Flow:**
```
1. Client detects WebSocket close event
2. Client waits brief period (100ms) for auto-reconnect
3. Client initiates reconnection with RECONNECT message
4. Server sends SYNC with current state
5. Client verifies signatures on SYNC
6. Session resumes from next nonce
```

**Timeout Logic:**
```javascript
const RECONNECT_TIMEOUT_MS = 30000; // 30 seconds

if (Date.now() - last_message_time > RECONNECT_TIMEOUT_MS) {
  // Connection lost, initiate settlement
  sendSettlementRequest({ reason: "CONNECTION_TIMEOUT" });
  closeSession();
}
```

#### 4.1.2 Permanent Disconnection

**Scenario**: Client browser crashes, doesn't reconnect

**Server-Side Recovery:**
```
1. Server waits for RECONNECT_TIMEOUT_MS (30 seconds)
2. No reconnection detected
3. Server initiates unilateral settlement:
   - Uses last signed state from client
   - Submits blockchain transaction
   - Marks session as CLOSED
4. Client eventually reconnects (new session)
5. Client queries blockchain for settlement result
6. Client verifies settlement was fair (correct balance)
```

**Dispute Window**: Client has 24 hours (configurable) to challenge settlement.

### 4.2 Channel Depletion

#### 4.2.1 Client Channel Exhausted

**Scenario**: Client balance drops below emergency threshold (10%)

**Automatic Handling:**
```json
{
  "type": "CHANNEL_DEPLETED",
  "timestamp": 1700004000000,
  "remaining_balance": "50.00 USD",
  "threshold": "100.00 USD",
  "action": "REBALANCING",
  "rebalancing_method": "submarine_swap",
  "estimated_time_sec": 600
}
```

**Rebalancing Flow:**
1. **Pause payments**: Queue incoming packets, don't process
2. **Initiate rebalancing**: Submarine swap from on-chain funds
3. **Monitor rebalancing**: Poll blockchain for tx confirmation
4. **Resume payments**: Once channel refunded, continue session

**User Experience:**
```
Browser displays: "Refilling payment channel... (estimated 10 minutes)"
Buffering indicator shown
Once refilled: "Payment channel refilled. Resuming stream..."
```

#### 4.2.2 Server Channel Exhausted

**Scenario**: Server inbound capacity depleted (all payments to server)

**Server Response:**
```json
{
  "type": "SERVER_CHANNEL_DEPLETED",
  "error_code": "INSUFFICIENT_INBOUND_CAPACITY",
  "error_message": "Server payment channel full. Settlement required.",
  "action": "FORCE_SETTLEMENT",
  "settlement_initiated": true,
  "estimated_settlement_time_sec": 300
}
```

**Recovery:**
1. Server force-triggers settlement
2. Server rebalances channel (circular or submarine swap)
3. New session may be required (or resume after rebalancing)

### 4.3 Payment Failures

#### 4.3.1 Signature Verification Failure

**Scenario**: Client sends invalid signature

**Server Response:**
```json
{
  "type": "PAYMENT_NACK",
  "nonce": 43,
  "error_code": "SIGNATURE_INVALID",
  "error_message": "ECDSA signature verification failed",
  "expected_signer": "0x742d35Cc...",
  "recovered_signer": "0x0000000...",
  "retry_allowed": true,
  "fraud_counter": 1
}
```

**Client Action:**
1. **Re-sign**: Retry signature with same nonce
2. **If persistent**: Check key management (Nillion Private Compute issue?)
3. **After 3 failures**: Session closed, manual intervention required

#### 4.3.2 Nonce Out of Sequence

**Scenario**: Client sends `nonce=45` but server expects `nonce=44`

**Server Response:**
```json
{
  "type": "PAYMENT_NACK",
  "error_code": "NONCE_MISMATCH",
  "expected_nonce": 44,
  "received_nonce": 45,
  "error_message": "Nonce gap detected. Sync required.",
  "sync_required": true
}
```

**Recovery:**
```
1. Server sends SYNC message with current state
2. Client verifies server state signatures
3. Client accepts server state (if valid)
4. Client resumes with correct nonce
```

#### 4.3.3 Blockchain Settlement Failure

**Scenario**: On-chain settlement transaction reverts

**Server → Client: SETTLEMENT_FAILED**
```json
{
  "type": "SETTLEMENT_FAILED",
  "settlement_id": "settlement-uuid-v4",
  "error_code": "TX_REVERTED",
  "error_message": "Settlement transaction reverted: insufficient gas",
  "blockchain_tx": {
    "tx_hash": "0xabc123...",
    "status": "reverted",
    "revert_reason": "Gas estimation failed"
  },
  "fallback_action": "RETRY_WITH_HIGHER_GAS",
  "retry_eta_sec": 120
}
```

**Fallback Strategy:**
1. **Retry with higher gas**: Increase gas limit by 20%
2. **Try alternative settlement method**: Switch from on-chain to submarine swap
3. **If all methods fail**: Force close channel, manual dispute resolution

### 4.4 Byzantine Faults & Malicious Actors

#### 4.4.1 Replay Attack Detection

**Attack**: Client resends old PAYMENT_COMMIT with previously used nonce

**Detection:**
```javascript
function detectReplayAttack(message) {
  if (message.nonce <= state.last_processed_nonce) {
    return {
      attack_detected: true,
      attack_type: "NONCE_REPLAY",
      severity: "HIGH"
    };
  }
  return { attack_detected: false };
}
```

**Response:**
```json
{
  "type": "SECURITY_ALERT",
  "alert_type": "REPLAY_ATTACK_DETECTED",
  "severity": "HIGH",
  "action": "SESSION_TERMINATED",
  "ban_duration_sec": 86400,
  "reason": "Attempted replay attack with nonce 42 (already processed)"
}
```

#### 4.4.2 Double-Spend Attempt

**Attack**: Client signs two different states with same nonce

**Detection:**
```javascript
function detectDoubleSpend(message) {
  const stored = state.nonce_history[message.nonce];
  if (stored && stored.commitment_hash !== message.commitment_hash) {
    return {
      attack_detected: true,
      attack_type: "DOUBLE_SPEND",
      evidence: {
        original_commitment: stored.commitment_hash,
        duplicate_commitment: message.commitment_hash
      }
    };
  }
  return { attack_detected: false };
}
```

**Response:**
1. **Immediate session termination**
2. **Submit fraud proof to blockchain** (if supported by channel type)
3. **Slash client deposit** (economic penalty)
4. **Permanent ban** from service

#### 4.4.3 Man-in-the-Middle (MITM)

**Prevention:**
1. **TLS 1.3 Mandatory**: All WebSocket connections over secure transport
2. **Certificate Pinning** (optional): Client validates server certificate
3. **End-to-End Signatures**: Payment signatures verified cryptographically
4. **Challenge-Response Auth**: Prevents session hijacking

**Detection:**
```
If (signature_valid BUT commitment_data_tampered) THEN
  MITM_detected (TLS compromised or proxy tampering)
  TERMINATE_session
  ALERT_user
END
```

---

## 5. Security Analysis

### 5.1 Threat Model

#### 5.1.1 Threat Actors

| Actor | Capability | Motivation | Likelihood |
|-------|-----------|------------|------------|
| **Malicious Client** | Can craft arbitrary WebSocket messages | Free streaming, DoS | Medium |
| **Malicious Server** | Can refuse payments, forge state | Steal funds | Low (reputation risk) |
| **Network Attacker** | MITM, replay, tamper | Disrupt service, steal | Low (TLS prevents) |
| **Compromised Keys** | If client keys leaked | Steal funds | Very Low (Nillion) |
| **Smart Contract Bug** | If channel contract has vulnerability | Exploit funds | Very Low (audited) |

#### 5.1.2 Attack Vectors & Mitigations

**Attack 1: Payment Without Service**
- **Attack**: Client pays but server doesn't deliver data
- **Mitigation**: Atomic data+payment coupling (client only signs after receiving data)
- **Residual Risk**: Low (server reputation loss)

**Attack 2: Service Without Payment**
- **Attack**: Client receives data without valid payment
- **Mitigation**: Server validates signature BEFORE sending data
- **Residual Risk**: Very Low (cryptographic enforcement)

**Attack 3: Channel Balance Manipulation**
- **Attack**: Client claims higher balance than reality
- **Mitigation**: Server independently verifies on-chain balance
- **Residual Risk**: None (blockchain is source of truth)

**Attack 4: Signature Forgery**
- **Attack**: Forge client signature to steal funds
- **Mitigation**: ECDSA cryptographic security (secp256k1)
- **Residual Risk**: None (computationally infeasible)

**Attack 5: Nonce Replay/Reordering**
- **Attack**: Replay old payment commits or reorder
- **Mitigation**: Strict nonce ordering, duplicate detection
- **Residual Risk**: Very Low (protocol enforcement)

**Attack 6: Settlement Race Condition**
- **Attack**: Submit old channel state during settlement
- **Mitigation**: Challenge period (24 hours), watchtower monitoring
- **Residual Risk**: Low (requires client offline during challenge)

**Attack 7: DoS via Invalid Payments**
- **Attack**: Flood server with invalid payment commits
- **Mitigation**: Rate limiting, signature verification before heavy processing, fraud counter
- **Residual Risk**: Low (rate limits + banning)

### 5.2 Cryptographic Guarantees

#### 5.2.1 Signature Scheme: ECDSA (secp256k1)

**Security Properties:**
- **Unforgeability**: Cannot create valid signature without private key
- **Non-repudiation**: Signer cannot deny signing valid message
- **Message Integrity**: Any tampering invalidates signature

**Signed Message Format:**
```
signed_data = keccak256(
  nonce ||
  batch_size ||
  cumulative_value ||
  timestamp ||
  keccak256(application_data)
)

signature = ecdsa_sign(private_key, signed_data)
```

**Verification:**
```javascript
function verifyPaymentSignature(message) {
  const signed_data = keccak256(
    message.nonce,
    message.batch.size,
    message.batch.cumulative_value,
    message.timestamp,
    keccak256(message.data)
  );

  const recovered_address = ecrecover(
    signed_data,
    message.signature.v,
    message.signature.r,
    message.signature.s
  );

  return recovered_address === client_channel_address;
}
```

#### 5.2.2 Key Management (Nillion Private Compute)

**Assumptions:**
1. **Key Confidentiality**: Nillion Private Storage never exposes private keys
2. **Compute Integrity**: Nillion Private Compute executes signing correctly
3. **Access Control**: Only authenticated client can trigger signing operations

**Security Model:**
- **Threat**: Nillion node compromise
- **Mitigation**: Multi-party computation (MPC) distributes key shares
- **Residual Risk**: Requires collusion of >threshold Nillion nodes

**Key Rotation:**
```
1. Generate new key pair (Nillion Private Compute)
2. Update channel with new public key (on-chain tx)
3. Wait for confirmation (6 blocks)
4. Rotate to new key for signing
5. Revoke old key
```

### 5.3 Privacy Considerations

#### 5.3.1 Data Leakage Analysis

**What's Public (On-Chain):**
- Channel addresses (client & server)
- Total channel capacity
- Settlement transactions (amount, timestamp)
- Public keys

**What's Private (Off-Chain):**
- Individual packet payments
- Data content
- Payment frequency
- Session duration (unless inferred from settlements)

**What Nillion Sees:**
- Signing requests (frequency, but not amounts if encrypted)
- Public keys
- Channel addresses

**What Nillion Does NOT See:**
- Private keys (stored as MPC shares)
- Application data content
- Payment amounts (if encrypted in signing request)

#### 5.3.2 Metadata Privacy

**Observable by Network Attackers:**
- WebSocket connection (client IP → server IP)
- Message frequency (packet rate)
- Message sizes (approximate data throughput)

**Mitigations:**
- **VPN/Tor**: Hide client IP
- **Traffic Padding**: Add dummy packets to obscure real traffic
- **Constant-Rate Transmission**: Send packets at fixed interval regardless of actual data

**Trade-off**: Privacy vs. Performance (padding reduces throughput)

### 5.4 Dispute Resolution

#### 5.4.1 Challenge Period Mechanism

**Dispute Window**: 24 hours (configurable, chain-dependent)

**Scenario: Unilateral Settlement**
```
1. Server submits settlement tx with state at nonce 1000
2. Blockchain starts 24-hour challenge period
3. Client has 24 hours to submit newer state (if it exists)
4. If client submits state at nonce 1005: Client's state wins
5. If no challenge: Server's state finalizes after 24 hours
```

**Penalty for Fraud:**
- Party submitting old state loses **entire channel balance**
- Funds transferred to honest party
- Economic disincentive against fraudulent settlement

#### 5.4.2 Watchtower Services

**Purpose**: Monitor blockchain for fraudulent settlement attempts while client offline

**Operation:**
```
1. Client registers channel with watchtower
2. Client sends latest channel state to watchtower (encrypted)
3. Watchtower monitors blockchain for settlement txs
4. If fraud detected: Watchtower submits challenge with newer state
5. Client pays watchtower fee for service
```

**Fee Structure:**
- Subscription: $5/month per channel
- Pay-per-challenge: 10% of recovered funds
- Free tier: Community watchtowers (altruistic)

#### 5.4.3 Evidence Preservation

**Client Obligations:**
- Store all signed channel states (until settlement finalized)
- Backup to multiple locations (local + cloud)
- Maintain audit trail of payments

**Server Obligations:**
- Store all received payment commits
- Maintain nonce history (for replay detection)
- Log all state transitions with timestamps

**Data Retention**: Minimum 30 days post-settlement

---

## 6. Performance Analysis

### 6.1 Latency Budget Breakdown

**End-to-End Latency (for 1 batch of 100 packets):**

| Component | Latency (ms) | Notes |
|-----------|-------------|-------|
| **Client: Batch accumulation** | 50 (avg) | 0-100ms range |
| **Client: Create payment commit** | 1 | Local computation |
| **Client: Nillion signing** | 5 | Optimistic (based on batching) |
| **Network: Client → Server** | 20 | US East - West Coast |
| **Server: Signature verification** | 1 | ECDSA verify |
| **Server: State update** | 1 | Database write |
| **Server: Data processing** | 10 | Application logic |
| **Network: Server → Client (ACK)** | 20 | Return path |
| **TOTAL** | **108 ms** | Per-batch latency |

**Per-Packet Latency (amortized):**
- Batch of 100 packets in 108ms = **1.08 ms/packet**
- Well within <100ms target

**Handshake Latency:**
| Phase | Latency (ms) | RTTs |
|-------|-------------|------|
| HTTP Upgrade | 50 | 1 |
| PAYMENT_HELLO + ACK | 50 | 1 |
| CHANNEL_INFO + ACK | 100 | 1 (+ on-chain verification) |
| AUTH_CHALLENGE + SESSION_READY | 50 | 1 |
| **TOTAL** | **250 ms** | **4 RTTs** |

### 6.2 Throughput Analysis

**Theoretical Maximum:**

**Without Batching:**
- Nillion signing: 100 ops/sec (assumed, based on typical MPC performance)
- **Bottleneck**: 100 packets/sec (10x below target)

**With Batching (100 packets/batch):**
- Nillion signing: 100 ops/sec
- Effective throughput: 100 batches/sec × 100 packets/batch = **10,000 packets/sec**
- **Well above target**: 10x margin

**Network Constraints:**
- WebSocket message rate: ~10,000 msg/sec (typical)
- Not a bottleneck for this use case

**Signature Verification (Server):**
- ECDSA verification: ~10,000 ops/sec (optimized)
- Not a bottleneck

**Actual Bottleneck**: Application data processing (depends on use case)

### 6.3 Batching Strategies

#### 6.3.1 Fixed-Interval Batching

**Configuration:**
```yaml
batch_interval_ms: 100
max_batch_size: 100
```

**Behavior:**
```
Every 100ms:
  IF batch not empty THEN
    sign_and_send_batch()
    reset_batch()
  END
END
```

**Pros:**
- Predictable latency (max 100ms)
- Simple implementation

**Cons:**
- May send partial batches (inefficient if low traffic)
- Fixed overhead regardless of traffic

#### 6.3.2 Count-Based Batching

**Configuration:**
```yaml
batch_size: 100
```

**Behavior:**
```
On each packet:
  add_to_batch(packet)
  IF batch.size >= 100 THEN
    sign_and_send_batch()
    reset_batch()
  END
END
```

**Pros:**
- Maximum signing efficiency
- No wasted batches

**Cons:**
- Unpredictable latency (could wait forever if low traffic)

#### 6.3.3 Adaptive Batching (Recommended)

**Configuration:**
```yaml
batch_interval_ms: 100
batch_size: 100
batch_value_usd: 0.10
```

**Behavior:**
```
On each packet:
  add_to_batch(packet)

  IF (batch.size >= 100) OR
     (batch.age_ms >= 100) OR
     (batch.value >= 0.10) THEN
    sign_and_send_batch()
    reset_batch()
  END
END
```

**Pros:**
- Best of both worlds
- Responsive to traffic patterns
- Bounded latency

**Cons:**
- Slightly more complex

**Performance:**
- Low traffic: 100ms batches (time-triggered)
- High traffic: Full 100-packet batches (count-triggered)
- High-value: Immediate (value-triggered)

### 6.4 Cost Analysis

#### 6.4.1 Nillion Costs (Estimated)

**Assumptions:**
- Nillion pricing: $0.001 per signature operation
- Batching: 100 packets/batch
- Traffic: 1000 packets/sec

**Calculations:**
```
Signatures per second: 1000 pkt/sec ÷ 100 pkt/batch = 10 sig/sec
Signatures per hour: 10 sig/sec × 3600 sec = 36,000 sig/hr
Nillion cost per hour: 36,000 × $0.001 = $36/hr
Nillion cost per day: $36/hr × 24 hr = $864/day
Nillion cost per month: $864/day × 30 days = $25,920/month
```

**Per-Packet Cost:**
```
Nillion cost per packet: $0.001/signature ÷ 100 packets/batch = $0.00001/packet
```

**Optimization: Increase Batch Size**
```
If batch size = 1000 packets (instead of 100):
  Signatures per second: 1 sig/sec
  Nillion cost per hour: $3.60/hr
  Nillion cost per month: $2,592/month (10x savings)

Trade-off: Max latency increases from 100ms to 1000ms
```

#### 6.4.2 Blockchain Settlement Costs

**Assumptions:**
- Settlement frequency: Every 1 hour (based on threshold)
- Settlement method: Submarine swap (Liquid Network)
- Average settlement value: $1000

**Costs:**
```
Submarine swap fee: 0.1% of value = $1.00
On-chain tx fee (Liquid): $0.50
Total per settlement: $1.50

Settlements per day: 24
Daily settlement cost: 24 × $1.50 = $36/day
Monthly settlement cost: $36/day × 30 = $1,080/month
```

**Alternative: Circular Rebalancing**
```
Circular rebalancing fee: 0.01% of value = $0.10
Cost per settlement: $0.10
Monthly cost: 24 settlements/day × 30 days × $0.10 = $72/month
Savings: 15x cheaper than submarine swaps
```

#### 6.4.3 Total Cost Breakdown

**Monthly Costs (1000 pkt/sec, 24/7 operation):**

| Component | Cost/Month | Percentage |
|-----------|-----------|------------|
| Nillion signatures | $25,920 | 96.0% |
| Settlement (circular) | $72 | 0.3% |
| Settlement (submarine swap fallback 5%) | $54 | 0.2% |
| WebSocket hosting | $100 | 0.4% |
| Monitoring & infrastructure | $100 | 0.4% |
| **TOTAL** | **$27,246** | **100%** |

**Per-Packet Cost:**
```
Total packets per month: 1000 pkt/sec × 86400 sec/day × 30 days = 2.592B packets
Cost per packet: $27,246 / 2.592B = $0.0000105/packet
```

**Revenue Requirement:**
```
If payment rate = $0.0008/packet:
  Revenue per month: 2.592B × $0.0008 = $2,073,600
  Profit margin: ($2,073,600 - $27,246) / $2,073,600 = 98.7%
```

**Nillion is the bottleneck cost** (96% of total). Optimization critical.

---

## 7. Implementation Reference

### 7.1 Client Pseudocode

```javascript
class PaymentEnabledWebSocketClient {
  constructor(serverUrl, nillionClient, channelManager) {
    this.serverUrl = serverUrl;
    this.nillion = nillionClient;
    this.channelManager = channelManager;
    this.ws = null;
    this.state = "INIT";
    this.session = null;
    this.batchBuffer = [];
    this.batchTimer = null;
  }

  async connect() {
    // Phase 1: HTTP Upgrade
    this.ws = new WebSocket(this.serverUrl, {
      headers: {
        "Sec-WebSocket-Extensions": "payment; version=1.0; chains=ethereum,bitcoin",
        "Sec-WebSocket-Protocol": "payment-stream-v1"
      }
    });

    this.ws.on("open", () => this.handleOpen());
    this.ws.on("message", (msg) => this.handleMessage(msg));
    this.ws.on("close", () => this.handleClose());
    this.ws.on("error", (err) => this.handleError(err));
  }

  async handleOpen() {
    // Phase 2: Send PAYMENT_HELLO
    const hello = {
      type: "PAYMENT_HELLO",
      version: "1.0",
      client_id: this.clientId,
      capabilities: this.getCapabilities(),
      preferences: this.getPreferences()
    };

    this.send(hello);
    this.state = "NEGOTIATING";
  }

  async handleMessage(message) {
    const msg = JSON.parse(message);

    switch(msg.type) {
      case "PAYMENT_HELLO_ACK":
        await this.handleHelloAck(msg);
        break;
      case "CHANNEL_INFO_ACK":
        await this.handleChannelInfoAck(msg);
        break;
      case "SESSION_READY":
        await this.handleSessionReady(msg);
        break;
      case "PAYMENT_ACK":
        await this.handlePaymentAck(msg);
        break;
      case "PAYMENT_NACK":
        await this.handlePaymentNack(msg);
        break;
      case "SETTLEMENT_ACK":
        await this.handleSettlementAck(msg);
        break;
      // ... other message types
    }
  }

  async handleHelloAck(msg) {
    // Phase 3: Send CHANNEL_INFO
    const channelInfo = {
      type: "CHANNEL_INFO",
      channel: await this.channelManager.getChannelInfo(),
      proof: await this.channelManager.generateProof()
    };

    this.send(channelInfo);
    this.state = "VERIFYING";
  }

  async handleChannelInfoAck(msg) {
    // Phase 4: Respond to auth challenge
    const challenge = msg.auth_challenge.challenge;
    const signature = await this.nillion.signChallenge(challenge);

    const authResponse = {
      type: "AUTH_CHALLENGE_RESPONSE",
      challenge: challenge,
      response: {
        signature: signature,
        public_key: await this.nillion.getPublicKey(),
        address: this.channelManager.getAddress()
      },
      nonce_commitment: {
        initial_nonce: msg.server_channel.nonce + 1
      }
    };

    this.send(authResponse);
  }

  async handleSessionReady(msg) {
    // Session established!
    this.session = msg;
    this.state = "ACTIVE";

    // Start batching timer
    this.startBatchTimer();

    // Emit "ready" event for application
    this.emit("ready");
  }

  async sendData(data) {
    if (this.state !== "ACTIVE") {
      throw new Error("Session not active");
    }

    // Add to batch
    this.batchBuffer.push({
      data: data,
      value: this.session.session_params.payment_rate,
      timestamp: Date.now()
    });

    // Check if batch ready
    if (this.shouldSendBatch()) {
      await this.sendBatch();
    }
  }

  shouldSendBatch() {
    const config = this.session.session_params.batching;
    const batch = this.batchBuffer;

    return (
      batch.length >= config.count ||
      (Date.now() - batch[0].timestamp) >= config.interval_ms ||
      this.getBatchValue() >= 0.10 // value threshold
    );
  }

  async sendBatch() {
    if (this.batchBuffer.length === 0) return;

    const batch = this.batchBuffer;
    this.batchBuffer = [];

    // Compute cumulative value
    const cumulativeValue = batch.reduce((sum, pkt) => sum + pkt.value, 0);

    // Create payment commit
    const paymentCommit = {
      type: "PAYMENT_COMMIT",
      nonce: this.session.current_nonce,
      batch: {
        size: batch.length,
        cumulative_value: cumulativeValue,
        packets: batch
      },
      channel_state: {
        new_balance_client: this.channelManager.getBalance() - cumulativeValue
      }
    };

    // Sign with Nillion Private Compute
    const signature = await this.nillion.signPaymentCommit(paymentCommit);
    paymentCommit.signature = signature;

    // Send
    this.send(paymentCommit);

    // Increment nonce
    this.session.current_nonce++;

    // Wait for ACK (with timeout)
    await this.waitForPaymentAck(paymentCommit.nonce, 5000);
  }

  async handlePaymentAck(msg) {
    // Verify server signature
    const valid = await this.verifyServerSignature(msg);
    if (!valid) {
      throw new Error("Invalid server signature on PAYMENT_ACK");
    }

    // Update local state
    this.channelManager.updateBalance(msg.channel_state.client_balance);

    // Check settlement thresholds
    if (this.shouldTriggerSettlement()) {
      await this.requestSettlement();
    }
  }

  startBatchTimer() {
    this.batchTimer = setInterval(() => {
      if (this.batchBuffer.length > 0) {
        this.sendBatch();
      }
    }, this.session.session_params.batching.interval_ms);
  }

  // ... more methods
}
```

### 7.2 Server Pseudocode

```javascript
class PaymentEnabledWebSocketServer {
  constructor(channelManager, blockchainVerifier) {
    this.channelManager = channelManager;
    this.blockchainVerifier = blockchainVerifier;
    this.activeSessions = new Map();
  }

  handleConnection(ws, request) {
    // Check for payment extension in headers
    const extensions = request.headers["sec-websocket-extensions"];
    const supportsPayment = extensions && extensions.includes("payment");

    if (!supportsPayment) {
      // Graceful degradation: non-payment WebSocket
      this.handleNonPaymentConnection(ws);
      return;
    }

    // Payment-enabled connection
    const session = this.createSession(ws);
    this.activeSessions.set(session.id, session);

    ws.on("message", (msg) => this.handleMessage(session, msg));
    ws.on("close", () => this.handleClose(session));
  }

  async handleMessage(session, message) {
    const msg = JSON.parse(message);

    switch(msg.type) {
      case "PAYMENT_HELLO":
        await this.handlePaymentHello(session, msg);
        break;
      case "CHANNEL_INFO":
        await this.handleChannelInfo(session, msg);
        break;
      case "AUTH_CHALLENGE_RESPONSE":
        await this.handleAuthResponse(session, msg);
        break;
      case "PAYMENT_COMMIT":
        await this.handlePaymentCommit(session, msg);
        break;
      case "SETTLEMENT_REQUEST":
        await this.handleSettlementRequest(session, msg);
        break;
      // ... other message types
    }
  }

  async handlePaymentHello(session, msg) {
    // Negotiate payment terms
    const selectedChain = this.selectChain(msg.capabilities.supported_chains);
    const paymentRate = this.negotiateRate(msg.preferences.max_payment_rate);

    const helloAck = {
      type: "PAYMENT_HELLO_ACK",
      version: "1.0",
      server_id: this.serverId,
      selected_config: {
        chain: selectedChain,
        network: "optimism",
        channel_type: "connext"
      },
      payment_terms: {
        rate_per_packet: paymentRate,
        accepted_tokens: this.getAcceptedTokens()
      },
      settlement_config: this.getSettlementConfig(),
      batching_config: this.getBatchingConfig(),
      auth_challenge: {
        challenge: this.generateChallenge(),
        challenge_expiry: Date.now() + 60000
      }
    };

    session.send(helloAck);
    session.auth_challenge = helloAck.auth_challenge;
    session.state = "VERIFYING";
  }

  async handleChannelInfo(session, msg) {
    // Verify channel on-chain
    const channelValid = await this.blockchainVerifier.verifyChannel(
      msg.channel.channel_id,
      msg.channel.chain,
      msg.channel.network
    );

    if (!channelValid) {
      session.send({
        type: "CHANNEL_INFO_NACK",
        error_code: "CHANNEL_NOT_FOUND"
      });
      return;
    }

    // Verify balance
    const balance = await this.blockchainVerifier.getChannelBalance(
      msg.channel.channel_id
    );

    if (balance.client_balance < 100) { // Minimum threshold
      session.send({
        type: "CHANNEL_INFO_NACK",
        error_code: "INSUFFICIENT_BALANCE",
        required_minimum: "100.00 USD",
        current_balance: balance.client_balance
      });
      return;
    }

    // Verify signature
    const signatureValid = await this.verifyChannelProof(msg.proof);
    if (!signatureValid) {
      session.send({
        type: "CHANNEL_INFO_NACK",
        error_code: "SIGNATURE_INVALID"
      });
      return;
    }

    // All checks passed
    session.clientChannel = msg.channel;
    session.send({
      type: "CHANNEL_INFO_ACK",
      verification_status: "VERIFIED",
      server_channel: await this.channelManager.getServerChannel(),
      liquidity_check: { sufficient_for_session: true }
    });
  }

  async handleAuthResponse(session, msg) {
    // Verify challenge response
    const challengeValid = await this.verifyChallenge(
      msg.challenge,
      msg.response,
      session.auth_challenge
    );

    if (!challengeValid) {
      session.send({
        type: "AUTH_FAILED",
        error_code: "CHALLENGE_VERIFICATION_FAILED"
      });
      session.close();
      return;
    }

    // Session ready!
    session.state = "ACTIVE";
    session.current_nonce = msg.nonce_commitment.initial_nonce;

    session.send({
      type: "SESSION_READY",
      session_id: session.id,
      session_params: this.getSessionParams(),
      server_auth: await this.signSessionReady(session)
    });
  }

  async handlePaymentCommit(session, msg) {
    // Verify nonce
    if (msg.nonce !== session.current_nonce) {
      session.send({
        type: "PAYMENT_NACK",
        error_code: "NONCE_MISMATCH",
        expected_nonce: session.current_nonce,
        received_nonce: msg.nonce
      });
      return;
    }

    // Verify signature
    const signatureValid = await this.verifyPaymentSignature(
      msg,
      session.clientChannel.participants[0].public_key
    );

    if (!signatureValid) {
      session.fraud_counter = (session.fraud_counter || 0) + 1;

      session.send({
        type: "PAYMENT_NACK",
        error_code: "SIGNATURE_INVALID",
        fraud_counter: session.fraud_counter
      });

      if (session.fraud_counter >= 3) {
        session.close(); // Ban malicious client
      }
      return;
    }

    // Update channel state
    await this.channelManager.updateChannelState(
      session.clientChannel.channel_id,
      msg.nonce,
      msg.channel_state
    );

    // Send acknowledgment
    const ack = {
      type: "PAYMENT_ACK",
      nonce: msg.nonce,
      status: "ACCEPTED",
      timestamp: Date.now(),
      channel_state: msg.channel_state,
      server_signature: await this.signChannelState(msg.channel_state),
      next_nonce: msg.nonce + 1,
      packets_acknowledged: msg.batch.size
    };

    session.send(ack);
    session.current_nonce++;

    // Process application data (send response, stream video chunk, etc.)
    await this.processApplicationData(session, msg.batch.packets);
  }

  async verifyPaymentSignature(paymentCommit, clientPublicKey) {
    const signedData = this.computeSignedData(paymentCommit);
    const recoveredKey = ecrecover(signedData, paymentCommit.signature);
    return recoveredKey === clientPublicKey;
  }

  // ... more methods
}
```

---

## 8. Deployment & Operations

### 8.1 Monitoring & Metrics

**Key Metrics to Track:**

**Handshake Metrics:**
- Handshake success rate (%)
- Handshake latency (p50, p95, p99)
- CHANNEL_INFO verification failures (by error type)
- AUTH_CHALLENGE failures

**Payment Metrics:**
- Payment commits per second
- Payment success rate (%)
- Payment ACK latency
- Signature verification failures
- Nonce mismatch rate

**Settlement Metrics:**
- Settlements per day
- Settlement methods used (circular, swap, on-chain)
- Settlement success rate
- Settlement latency (time to blockchain confirmation)
- Settlement costs

**Channel Metrics:**
- Active channels
- Average channel balance
- Channel depletion events
- Rebalancing frequency
- Channel closure reasons

**Error Metrics:**
- PAYMENT_NACK rate (by error code)
- Fraud attempts detected
- Session terminations (by reason)

**Example Dashboard (Prometheus + Grafana):**
```yaml
metrics:
  - payment_commits_total (counter)
  - payment_acks_total (counter)
  - payment_nacks_total (counter, labeled by error_code)
  - payment_latency_seconds (histogram)
  - handshake_latency_seconds (histogram)
  - settlement_cost_usd (gauge)
  - active_sessions (gauge)
  - channel_balance_usd (gauge, labeled by channel_id)
  - fraud_attempts_total (counter)
```

### 8.2 Rate Limiting & Abuse Prevention

**Rate Limits:**

```yaml
rate_limits:
  # Connection limits
  connections_per_ip_per_minute: 10
  handshakes_per_ip_per_hour: 100

  # Payment limits
  payment_commits_per_session_per_second: 20
  max_batch_size: 1000
  max_cumulative_value_per_batch: 1000.00 USD

  # Settlement limits
  settlements_per_channel_per_hour: 10

  # Error limits
  payment_nacks_before_ban: 10
  fraud_attempts_before_permanent_ban: 3
```

**Abuse Detection:**

```javascript
class AbuseDetector {
  detectAbuse(session) {
    const signals = {
      high_nack_rate: session.nack_count / session.total_commits > 0.2,
      rapid_reconnections: session.reconnect_count > 5,
      suspicious_payment_pattern: this.detectSuspiciousPattern(session),
      channel_balance_mismatch: this.detectBalanceMismatch(session),
      signature_failures: session.signature_failures > 3
    };

    const abuse_score = Object.values(signals).filter(x => x).length;

    if (abuse_score >= 3) {
      this.banClient(session.client_id, "Abuse detected");
    }
  }

  detectSuspiciousPattern(session) {
    // Detect patterns like:
    // - Always maximum batch size (trying to maximize before fraud)
    // - Rapid balance depletion followed by immediate settlement
    // - Repeated reconnections with different channel IDs
  }
}
```

### 8.3 Disaster Recovery

**Failure Scenarios:**

**1. Server Crash (State Loss):**
```
Recovery:
  1. Server restarts
  2. Load channel states from database
  3. Clients reconnect (RECONNECT message)
  4. Server sends SYNC with last known state
  5. Session resumes

Requirement: Database replication (multi-region)
```

**2. Database Failure:**
```
Recovery:
  1. Failover to replica database
  2. Verify data consistency
  3. Resume operations

Worst case: Last 1-5 minutes of state lost
Mitigation: Write-ahead log (WAL) for critical state
```

**3. Nillion Service Outage:**
```
Immediate Impact: Cannot sign new payment commits
Fallback:
  1. Queue packets locally (up to 5 minutes buffer)
  2. Monitor Nillion service status
  3. If restored quickly: Resume signing, send queued batches
  4. If prolonged outage (>5 min): Initiate settlement, close sessions

Prevention: Nillion SLA monitoring, multi-provider strategy
```

**4. Blockchain Network Congestion:**
```
Impact: Settlement transactions delayed
Response:
  1. Continue off-chain payments (don't stop session)
  2. Increase gas price for settlement tx (up to 2x normal)
  3. Try alternative settlement method (submarine swap → circular)
  4. If critical: Use faster blockchain (e.g., Liquid instead of Bitcoin)

User Experience: Show "Settlement delayed due to network congestion" message
```

**5. Payment Channel Dispute:**
```
Scenario: Client claims server submitted old state during settlement
Response:
  1. Server provides evidence (all signed states)
  2. Client submits challenge with newer state
  3. Blockchain adjudicates (higher nonce wins)
  4. Losing party penalized

Prevention:
  - Always keep signed states (client & server)
  - Use watchtower services
  - Monitor challenge periods
```

---

## 9. Future Enhancements

### 9.1 Multi-Chain Support (Roadmap)

**Phase 1: Single Chain (MVP)**
- Support Ethereum L2 (Optimism or Arbitrum)
- Lightning Network (Bitcoin)

**Phase 2: Cross-Chain**
- Atomic cross-chain swaps during session
- Route payments through cheapest chain
- Automatic chain selection based on liquidity/fees

**Phase 3: Universal**
- Support all major chains (Solana, Polygon, etc.)
- Interledger Protocol (ILP) integration
- Cross-chain payment routing

### 9.2 Advanced Features

**1. Pre-Signed Vouchers:**
- Client pre-signs 1000 payment vouchers
- Server redeems vouchers without per-packet signature
- Trade-off: Security (bounded exposure) vs. Performance (0ms signing)

**2. Probabilistic Micropayments:**
- Lottery-style payments (inspired by Orchid)
- Client sends "lottery ticket" each packet
- Server wins payment with probability p
- Expected value = packet_value
- Reduces signing overhead 100x

**3. Payment Streaming Modes:**
- **Pull**: Client pays per packet received (current design)
- **Push**: Server pays client for data sent (reverse payments)
- **Bidirectional**: Both parties pay simultaneously

**4. Smart Contract Integration:**
- On-chain payment channel contracts
- Dispute resolution via smart contract
- Automated settlement based on on-chain events

### 9.3 Optimizations

**1. Nillion Optimization:**
- Batch signature requests (1 Nillion call for 10 batches)
- Pre-compute signatures during idle time
- Signature caching for repeated data patterns

**2. Protocol Compression:**
- Binary protocol instead of JSON (50% size reduction)
- Header compression (HPACK-style)
- Data deduplication

**3. Edge Deployment:**
- Deploy payment verification at CDN edge
- Reduce latency (client → edge: 10ms vs. client → origin: 50ms)
- Horizontal scaling

---

## 10. Conclusion

### 10.1 Summary

This WebSocket handshake protocol specification provides a complete solution for payment-enabled streaming with the following characteristics:

**Capabilities:**
- 1000+ packets/second throughput (achieved via batching)
- <100ms per-packet latency (amortized)
- Multi-chain support (negotiated during handshake)
- Flexible settlement (time, value, packet-count thresholds)
- Robust error handling and recovery
- Backward compatible (graceful degradation)

**Security:**
- TLS 1.3 mandatory
- Challenge-response authentication
- ECDSA signature verification
- Nonce-based replay prevention
- Fraud detection and penalties

**Limitations:**
- Nillion signing cost is 96% of total cost ($26k/month for 1000 pkt/sec)
- Requires payment channel setup (upfront complexity)
- Settlement finality depends on blockchain (10min-1hr)

### 10.2 Recommendations

**For Proof-of-Concept:**
1. Start with single chain (Ethereum Optimism + Connext)
2. Use fixed batching (100 packets or 100ms)
3. Simple settlement (1-hour time threshold)
4. Focus on core handshake + payment flow
5. Skip advanced features (multi-chain, probabilistic payments)

**For Production:**
1. Optimize Nillion costs:
   - Increase batch size (100 → 1000 packets)
   - Investigate pre-signed vouchers
   - Consider hybrid approach (Nillion for settlement only, client-side for packets)
2. Implement all fallback mechanisms (circular → submarine → on-chain)
3. Deploy comprehensive monitoring
4. Add watchtower services for settlement security
5. Conduct security audit before mainnet launch

### 10.3 Next Steps

1. **Validate with Nillion Team**: Confirm signing performance assumptions
2. **Build PoC**: Implement handshake protocol (client + server)
3. **Benchmark**: Measure actual throughput and latency
4. **Iterate**: Refine based on PoC learnings
5. **Security Audit**: Before production deployment

---

## Appendix A: Message Format Reference

### A.1 All Message Types

| Message Type | Direction | Phase | Description |
|-------------|-----------|-------|-------------|
| `PAYMENT_HELLO` | Client → Server | Handshake | Capability negotiation |
| `PAYMENT_HELLO_ACK` | Server → Client | Handshake | Terms agreement |
| `PAYMENT_HELLO_NACK` | Server → Client | Handshake | Negotiation failed |
| `CHANNEL_INFO` | Client → Server | Handshake | Channel details + proof |
| `CHANNEL_INFO_ACK` | Server → Client | Handshake | Channel verified |
| `CHANNEL_INFO_NACK` | Server → Client | Handshake | Channel verification failed |
| `AUTH_CHALLENGE_RESPONSE` | Client → Server | Handshake | Prove key ownership |
| `SESSION_READY` | Server → Client | Handshake | Session established |
| `PAYMENT_COMMIT` | Client → Server | Active | Batched payment + data |
| `PAYMENT_ACK` | Server → Client | Active | Payment accepted |
| `PAYMENT_NACK` | Server → Client | Active | Payment rejected |
| `SETTLEMENT_REQUEST` | Either direction | Settlement | Request settlement |
| `SETTLEMENT_ACK` | Either direction | Settlement | Settlement accepted |
| `SETTLEMENT_COMPLETE` | Server → Client | Settlement | Settlement finalized |
| `RECONNECT` | Client → Server | Recovery | Resume after disconnect |
| `SYNC` | Server → Client | Recovery | State synchronization |
| `HEARTBEAT` | Both directions | Maintenance | Keep-alive |
| `CLOSE` | Either direction | Teardown | Graceful session close |

### A.2 Error Code Reference

| Error Code | Severity | Retry? | Description |
|-----------|----------|--------|-------------|
| `INCOMPATIBLE_CHAINS` | High | No | No common blockchain support |
| `RATE_TOO_HIGH` | Medium | Yes | Adjust rate and retry |
| `CHANNEL_NOT_FOUND` | High | No | Channel doesn't exist on-chain |
| `INSUFFICIENT_BALANCE` | High | Yes | Fund channel and retry |
| `SIGNATURE_INVALID` | Critical | Yes (3x) | Cryptographic verification failed |
| `NONCE_MISMATCH` | Medium | Yes | State sync needed |
| `NONCE_REPLAY` | Critical | No | Security violation (ban) |
| `DOUBLE_SPEND` | Critical | No | Fraud attempt (ban + slash) |
| `CHANNEL_DEPLETED` | Medium | Auto | Rebalancing triggered |
| `SERVER_OVERLOADED` | Low | Yes | Exponential backoff |

---

**Protocol Version**: 1.0
**Document Status**: Final Draft
**Last Updated**: November 15, 2025
**Authors**: Payment Protocol Research Team
