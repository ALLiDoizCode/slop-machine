# BIMP Protocol Specification
## Bidirectional Interledger Micropayment Protocol

**Version:** 1.0.0-draft
**Status:** Proposal
**Date:** November 17, 2025

---

## Abstract

BIMP (Bidirectional Interledger Micropayment Protocol) is a lightweight protocol for streaming micropayments over HTTP/WebSocket connections. It enables machine-to-machine (M2M) communication with integrated payment flows, supporting bidirectional payments and ledger-agnostic settlement through payment channels.

BIMP combines:
- **x402** for initial handshake and channel establishment (HTTP 402 semantics)
- **Signed state commitments** for streaming payments (WebSocket)
- **Payment channels** for efficient, unilateral settlement (Lightning, state channels, etc.)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture](#architecture)
3. [Protocol Layers](#protocol-layers)
4. [Connection Lifecycle](#connection-lifecycle)
5. [Packet Format](#packet-format)
6. [Payment Channels](#payment-channels)
7. [x402 Handshake](#x402-handshake)
8. [Security](#security)
9. [Implementation Guide](#implementation-guide)
10. [References](#references)

---

## 1. Introduction

### 1.1 Motivation

Existing micropayment protocols are either:
- **Too complex** (ILP/STREAM with multi-hop routing)
- **Ledger-specific** (Lightning for Bitcoin only, Raiden for Ethereum only)
- **Not designed for M2M** (Web Monetization for browsers)

BIMP provides a pragmatic solution optimized for M2M use cases.

### 1.2 Design Goals

1. **Simplicity** - 90% simpler than ILP/STREAM
2. **Ledger Agnostic** - Works with any blockchain or payment system
3. **HTTP 402 Native** - Built around standard HTTP semantics
4. **Bidirectional** - Both parties can stream payments
5. **Efficient** - Minimal overhead, off-chain until settlement
6. **Secure** - Cryptographically signed state commitments
7. **Unilateral Settlement** - Payee controls settlement timing

### 1.3 Key Features

✅ **Per-packet payments** - Payment metadata in every message
✅ **Signed state commitments** - Unilateral claim rights
✅ **Payment channel abstraction** - Pluggable settlement backends
✅ **HTTP 402 handshake** - Standard web semantics for channel setup
✅ **WebSocket streaming** - Low-latency persistent connections
✅ **Bidirectional flows** - Simultaneous two-way payments

---

## 2. Architecture

### 2.1 Three-Phase Model

```
┌──────────────────────────────────────────────┐
│  Phase 1: x402 Handshake                     │
│  - HTTP 402 discovery                        │
│  - x402 payment for channel setup            │
│  - Payment channel created on-chain          │
│  - Channel credentials returned              │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  Phase 2: WebSocket Connection               │
│  - Client upgrades with channel credentials  │
│  - BIMP session established                  │
│  - Bidirectional communication begins        │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  Phase 3: Streaming Payments                 │
│  - PAYMENT packets with signed states        │
│  - Unilateral settlement when threshold met  │
│  - Continue until channel closes             │
└──────────────────────────────────────────────┘
```

### 2.2 Protocol Stack

```
┌─────────────────────────────────────┐
│     Application Layer               │
│   (M2M application logic)           │
└─────────────────────────────────────┘
               ↕
┌─────────────────────────────────────┐
│     BIMP Protocol Layer             │
│  (Payment + Data streaming)         │
└─────────────────────────────────────┘
               ↕
┌─────────────────────────────────────┐
│     Transport Layer                 │
│   (WebSocket or HTTP/2)             │
└─────────────────────────────────────┘
               ↕
┌─────────────────────────────────────┐
│     Settlement Layer                │
│  (Lightning, State Channels, x402)  │
└─────────────────────────────────────┘
```

---

## 3. Protocol Layers

### 3.1 Handshake Layer (x402)

**Purpose:** Establish payment channel and exchange credentials

**Transport:** HTTP/HTTPS
**Status Code:** 402 Payment Required
**Payment Method:** x402

### 3.2 Streaming Layer (BIMP)

**Purpose:** Stream payments and application data

**Transport:** WebSocket (WSS)
**Encoding:** JSON
**Packet Types:** PAYMENT, DATA, CONTROL

### 3.3 Settlement Layer (Pluggable)

**Purpose:** Finalize payments on-chain or off-chain

**Supported Backends:**
- Lightning Network (HTLC-based)
- Ethereum State Channels (Raiden, Perun, Nitro)
- Direct blockchain settlement (x402, EVM, Solana)
- Custom adapters

---

## 4. Connection Lifecycle

### 4.1 Discovery (HTTP 402)

**Client Request:**
```http
GET /api/resource HTTP/1.1
Host: server.example.com
```

**Server Response:**
```http
HTTP/1.1 402 Payment Required
Content-Type: application/json

{
  "protocol": "BIMP/1.0",
  "handshake": {
    "type": "x402",
    "setupFee": "10000",
    "network": "base",
    "asset": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
  },
  "channel": {
    "minCapacity": "100000",
    "maxCapacity": "10000000",
    "duration": 86400,
    "type": "state-channel",
    "contractAddress": "0xChannel..."
  },
  "streaming": {
    "rate": "100",
    "rateUnit": "wei/message",
    "settlementThreshold": "10000"
  }
}
```

### 4.2 Channel Setup (x402 Payment)

**Client sends x402 payment:**
```http
POST /api/resource/channel-setup HTTP/1.1
Host: server.example.com
X-PAYMENT: eyJ4NDAyVmVyc2lvbiI6IjEuMCIs...
Content-Type: application/json

{
  "channelCapacity": "1000000",
  "clientAddress": "0x742d35Cc..."
}
```

**Server creates channel and responds:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "channel": {
    "channelId": "0xch_abc123",
    "streamEndpoint": "wss://server.example.com/stream/0xch_abc123",
    "streamToken": "eyJhbGciOiJIUzI1NiIs...",
    "tokenExpiresIn": 300,
    "capacity": "1000000",
    "expiresAt": "2025-11-18T12:00:00Z"
  }
}
```

### 4.3 WebSocket Upgrade

**Client connects:**
```javascript
const ws = new WebSocket(
  'wss://server.example.com/stream/0xch_abc123',
  { headers: { Authorization: `Bearer ${streamToken}` } }
)
```

**Client sends CONNECT packet:**
```json
{
  "type": "CONNECT",
  "version": "BIMP/1.0",
  "channel": {
    "channelId": "0xch_abc123",
    "channelType": "state-channel",
    "clientAddress": "0x742d35Cc..."
  },
  "limits": {
    "sendMax": "1000000",
    "receiveMax": "500000"
  }
}
```

**Server responds with CONNECTED:**
```json
{
  "type": "CONNECTED",
  "sessionId": "0xch_abc123",
  "channel": {
    "verified": true,
    "balance": "1000000"
  },
  "limits": {
    "sendMax": "1000000",
    "receiveMax": "2000000"
  }
}
```

### 4.4 Streaming

**Client sends PAYMENT packets:**
```json
{
  "type": "PAYMENT",
  "seq": 1,
  "timestamp": 1700234567890,
  "payment": {
    "channelId": "0xch_abc123",
    "channelType": "state-channel",
    "stateNumber": 1,
    "totalClaimable": "100",
    "stateSignature": "0x1234abcd..."
  },
  "data": { "request": "temperature" }
}
```

**Server responds with data (optionally with payment):**
```json
{
  "type": "PAYMENT",
  "seq": 1,
  "timestamp": 1700234568000,
  "payment": {
    "channelId": "0xch_abc123",
    "counterpartyClaimable": "50",
    "counterpartySignature": "0x5678efgh..."
  },
  "data": { "temperature": 23.5 }
}
```

### 4.5 Settlement

**Server settles when threshold reached:**
```javascript
// Server decides to settle (no client permission needed)
await channelContract.settle(
  channelId,
  { stateNumber: 100, totalClaimable: "10000", ... },
  clientSignature
)
```

### 4.6 Closure

**Either party can close:**
```json
{
  "type": "CONTROL",
  "control": {
    "action": "CLOSE",
    "reason": "completed",
    "finalTotalSent": "98000",
    "finalTotalReceived": "45000"
  }
}
```

---

## 5. Packet Format

### 5.1 Base Packet Structure

```typescript
interface BIMPPacket {
  type: 'CONNECT' | 'CONNECTED' | 'PAYMENT' | 'DATA' | 'CONTROL'
  seq?: number
  timestamp?: number
}
```

### 5.2 CONNECT Packet

```typescript
interface ConnectPacket extends BIMPPacket {
  type: 'CONNECT'
  version: string              // "BIMP/1.0"
  channel: {
    channelId: string
    channelType: string        // "lightning" | "state-channel" | "raiden"
    clientAddress: string
  }
  limits: {
    sendMax: string
    receiveMax: string
  }
}
```

### 5.3 PAYMENT Packet

```typescript
interface PaymentPacket extends BIMPPacket {
  type: 'PAYMENT'
  seq: number
  timestamp: number
  payment: {
    // Channel information
    channelId: string
    channelType: string

    // State commitment (enables unilateral settlement)
    stateNumber: number
    totalClaimable: string
    stateSignature: string

    // Bidirectional (optional)
    counterpartyClaimable?: string
    counterpartySignature?: string

    // Lightning-specific (optional)
    paymentHash?: string
    preimage?: string
  }
  data?: any                    // Application payload
}
```

### 5.4 DATA Packet

```typescript
interface DataPacket extends BIMPPacket {
  type: 'DATA'
  seq: number
  timestamp: number
  data: any
}
```

### 5.5 CONTROL Packet

```typescript
interface ControlPacket extends BIMPPacket {
  type: 'CONTROL'
  control: {
    action: 'SETTLE' | 'SETTLED' | 'LIMIT_UPDATE' | 'CLOSE' | 'ERROR'
    payload: any
  }
}
```

---

## 6. Payment Channels

### 6.1 Channel Types

BIMP supports multiple payment channel backends:

#### 6.1.1 State Channels (Ethereum)

```solidity
contract BIMPChannel {
  struct Channel {
    address client;
    address server;
    uint256 capacity;
    uint256 clientBalance;
    uint256 serverBalance;
    uint256 lastStateNumber;
    bool isOpen;
  }

  function settle(
    bytes32 channelId,
    uint256 stateNumber,
    uint256 claimAmount,
    bytes memory signature
  ) external;
}
```

#### 6.1.2 Lightning Network

Uses HTLCs (Hash Time-Locked Contracts) for conditional payments.

```javascript
{
  "channelType": "lightning",
  "paymentHash": "abc123...",
  "htlcExpiry": 1700234600
}
```

#### 6.1.3 Direct Settlement (x402)

Falls back to direct blockchain transactions via x402.

```javascript
{
  "channelType": "x402-direct",
  "network": "base",
  "asset": "0x833589..."
}
```

### 6.2 Signed State Commitments

Each PAYMENT packet contains a **signed state commitment** that gives the recipient **unilateral claim rights**.

**What gets signed:**
```javascript
const stateCommitment = {
  channelId: "0xch_abc123",
  stateNumber: 1,
  totalClaimable: "100",
  recipient: "0x8a791d3a...",
  nonce: "unique-nonce",
  timestamp: 1700234567890
}

// EIP-712 typed signature
const signature = await signer._signTypedData(domain, types, stateCommitment)
```

**Key property:** Later state numbers **supersede** earlier ones (monotonic).

### 6.3 Unilateral Settlement

**Server can settle anytime without client permission:**

```javascript
async function settleChannel(session) {
  const { channelId, stateNumber, totalClaimable, signature } = session.latestState

  // Submit to blockchain
  const tx = await channelContract.settle(
    channelId,
    { stateNumber, totalClaimable, recipient: serverAddress },
    signature
  )

  await tx.wait()

  console.log(`Settled ${totalClaimable} from channel ${channelId}`)
}
```

### 6.4 Bidirectional Channels

Both parties sign state commitments:

```json
{
  "type": "PAYMENT",
  "payment": {
    "channelId": "0xch_abc",
    "stateNumber": 5,

    "serverClaimable": "1000",
    "clientSignature": "0x...",

    "clientClaimable": "300",
    "serverSignature": "0x..."
  }
}
```

Either party can settle their claim independently.

---

## 7. x402 Handshake

### 7.1 Purpose

x402 is used for the **initial handshake** to:
1. Prevent spam (costs money to request channel)
2. Cover channel setup costs
3. Establish trust before streaming

### 7.2 Setup Fee Structure

```json
{
  "handshake": {
    "type": "x402",
    "setupFee": "10000",        // One-time fee to create channel
    "scheme": "exact",
    "network": "base",
    "asset": "0x833589..."
  },
  "channel": {
    "minCapacity": "100000",    // Minimum channel deposit
    "maxCapacity": "10000000"
  }
}
```

**Total cost to establish channel:**
- x402 setup fee: 10,000 wei (one-time)
- Channel deposit: 100,000+ wei (refundable)

### 7.3 Channel Creation Flow

```javascript
// Server receives x402 payment
const payment = await x402Handler.verifyPayment(req.headers['x-payment'])

// Create channel on-chain
const channel = await channelFactory.createChannel(
  clientAddress,
  serverAddress,
  capacity,
  duration
)

// Return credentials
res.json({
  channel: {
    channelId: channel.id,
    streamEndpoint: `wss://server.com/stream/${channel.id}`,
    streamToken: generateToken(channel.id)
  }
})
```

---

## 8. Security

### 8.1 Threat Model

**Assumptions:**
- TLS/WSS provides transport security
- Settlement layer (blockchain/Lightning) is secure
- Both parties have secure key management

**Threats:**
1. Payment fraud (invalid signatures)
2. Replay attacks (old states resubmitted)
3. Settlement failure (false settlement claims)
4. DoS attacks (spam packets)
5. Griefing (offline/uncooperative parties)

### 8.2 Mitigations

**Payment Fraud:**
- ✅ Verify all signatures before accepting payment
- ✅ Use EIP-712 typed signatures for clarity

**Replay Attacks:**
- ✅ Monotonic state numbers (must increase)
- ✅ Nonces in state commitments
- ✅ On-chain verification prevents old state submission

**Settlement Failure:**
- ✅ Verify settlement proofs on-chain
- ✅ Don't trust client claims, verify transactions

**DoS Attacks:**
- ✅ x402 setup fee prevents spam channel requests
- ✅ Rate limiting on connections and packets
- ✅ Require minimum payment per packet

**Griefing:**
- ✅ Unilateral settlement (no cooperation needed)
- ✅ Channel expiry (automatic closure after timeout)
- ✅ Watchtower services (for Lightning)

### 8.3 Best Practices

1. **Always use WSS** (WebSocket Secure)
2. **Verify signatures** on every PAYMENT packet
3. **Enforce monotonic state numbers**
4. **Validate settlement proofs on-chain**
5. **Rate limit** connections and payment frequency
6. **Monitor balances** and enforce limits
7. **Log all payments** for auditing

---

## 9. Implementation Guide

### 9.1 Server Implementation

```javascript
import express from 'express'
import { WebSocketServer } from 'ws'
import { ethers } from 'ethers'

class BIMPServer {
  constructor(config) {
    this.x402 = new X402Handler(config.x402)
    this.channelFactory = new ethers.Contract(
      config.channelFactoryAddress,
      ChannelFactoryABI,
      config.wallet
    )
    this.sessions = new Map()
  }

  // HTTP 402 discovery
  handleDiscovery(req, res) {
    res.status(402).json({
      protocol: "BIMP/1.0",
      handshake: { /* x402 requirements */ },
      channel: { /* channel parameters */ },
      streaming: { /* BIMP details */ }
    })
  }

  // x402 channel setup
  async handleChannelSetup(req, res) {
    const payment = await this.x402.verifyPayment(req.headers['x-payment'])
    if (!payment.valid) {
      return res.status(402).json({ error: 'Invalid payment' })
    }

    const channel = await this.createChannel(req.body)

    res.status(200).json({
      success: true,
      channel: {
        channelId: channel.id,
        streamEndpoint: `wss://${req.hostname}/stream/${channel.id}`,
        streamToken: this.generateToken(channel.id)
      }
    })
  }

  // WebSocket connection
  async handleWebSocket(ws, request) {
    const token = this.extractToken(request)
    const session = await this.verifyToken(token)

    if (!session) {
      ws.close(4001, 'Invalid token')
      return
    }

    // Verify channel on-chain
    const channel = await this.channelFactory.getChannel(session.channelId)
    if (!channel.isOpen) {
      ws.close(4002, 'Channel not open')
      return
    }

    // Establish BIMP session
    const bimpSession = {
      channelId: session.channelId,
      stateNumber: 0,
      totalClaimable: 0n,
      latestState: null
    }

    this.sessions.set(session.channelId, bimpSession)
    ws.on('message', (data) => this.handlePacket(bimpSession, ws, data))
  }

  async handlePacket(session, ws, rawData) {
    const packet = JSON.parse(rawData)

    switch (packet.type) {
      case 'CONNECT':
        this.handleConnect(session, ws, packet)
        break
      case 'PAYMENT':
        await this.handlePayment(session, ws, packet)
        break
      case 'CONTROL':
        this.handleControl(session, ws, packet)
        break
    }
  }

  async handlePayment(session, ws, packet) {
    const { stateNumber, totalClaimable, stateSignature } = packet.payment

    // Verify signature
    const isValid = await this.verifyStateSignature(
      session.channelId,
      stateNumber,
      totalClaimable,
      stateSignature,
      session.clientAddress
    )

    if (!isValid) {
      ws.close(4010, 'Invalid signature')
      return
    }

    // Store state (can settle anytime!)
    session.latestState = {
      stateNumber,
      totalClaimable,
      signature: stateSignature
    }

    // Process request
    const response = await this.processRequest(packet.data)

    // Send response
    ws.send(JSON.stringify({
      type: 'PAYMENT',
      seq: stateNumber,
      payment: { /* optional counter-payment */ },
      data: response
    }))

    // Settle if threshold reached
    if (BigInt(totalClaimable) >= this.settlementThreshold) {
      await this.settleChannel(session)
    }
  }

  async settleChannel(session) {
    const tx = await this.channelFactory.settle(
      session.channelId,
      {
        stateNumber: session.latestState.stateNumber,
        totalClaimable: session.latestState.totalClaimable,
        recipient: this.serverAddress
      },
      session.latestState.signature
    )

    await tx.wait()
  }
}

// Usage
const server = new BIMPServer({
  x402: { /* config */ },
  channelFactoryAddress: '0x...',
  wallet: ethersWallet
})

const app = express()
app.get('/api/resource', (req, res) => server.handleDiscovery(req, res))
app.post('/api/resource/channel-setup', (req, res) => server.handleChannelSetup(req, res))

const wss = new WebSocketServer({ server: app })
wss.on('connection', (ws, req) => server.handleWebSocket(ws, req))

app.listen(8080)
```

### 9.2 Client Implementation

```javascript
class BIMPClient {
  async connect(resourceUrl) {
    // 1. Discovery
    const discovery = await fetch(resourceUrl)
    const requirements = await discovery.json()

    // 2. Pay setup fee via x402
    const payment = await this.createX402Payment(requirements.handshake)

    const setupResponse = await fetch(
      `${resourceUrl}/channel-setup`,
      {
        method: 'POST',
        headers: {
          'X-PAYMENT': payment.header,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          channelCapacity: '1000000',
          clientAddress: this.wallet.address
        })
      }
    )

    const channelInfo = await setupResponse.json()

    // 3. Deposit to channel
    await this.depositToChannel(channelInfo.channel)

    // 4. Connect to WebSocket
    const ws = new WebSocket(channelInfo.channel.streamEndpoint, {
      headers: { Authorization: `Bearer ${channelInfo.channel.streamToken}` }
    })

    await new Promise((resolve) => ws.once('open', resolve))

    // 5. Send CONNECT
    ws.send(JSON.stringify({
      type: 'CONNECT',
      version: 'BIMP/1.0',
      channel: {
        channelId: channelInfo.channel.channelId,
        channelType: 'state-channel',
        clientAddress: this.wallet.address
      },
      limits: {
        sendMax: '1000000',
        receiveMax: '500000'
      }
    }))

    return ws
  }

  async sendPayment(ws, amount, data) {
    this.stateNumber++
    this.totalPaid += amount

    const stateCommitment = {
      channelId: this.channelId,
      stateNumber: this.stateNumber,
      totalClaimable: this.totalPaid,
      recipient: this.serverAddress,
      nonce: this.generateNonce(),
      timestamp: Date.now()
    }

    const signature = await this.signStateCommitment(stateCommitment)

    ws.send(JSON.stringify({
      type: 'PAYMENT',
      seq: this.stateNumber,
      timestamp: Date.now(),
      payment: {
        channelId: this.channelId,
        channelType: 'state-channel',
        stateNumber: this.stateNumber,
        totalClaimable: this.totalPaid.toString(),
        stateSignature: signature
      },
      data: data
    }))
  }
}

// Usage
const client = new BIMPClient({
  wallet: ethersWallet,
  x402Config: { /* ... */ }
})

const ws = await client.connect('https://server.com/api/resource')

for (let i = 0; i < 1000; i++) {
  await client.sendPayment(ws, 100, { request: 'temperature' })
  await sleep(100)
}
```

---

## 10. References

### 10.1 Related Protocols

- **x402** - HTTP 402 payment protocol (github.com/coinbase/x402)
- **ILP/STREAM** - Interledger Protocol (interledger.org)
- **Lightning Network** - Bitcoin L2 (github.com/lightning/bolts)
- **L402** - Lightning HTTP 402 (github.com/lightninglabs/L402)
- **Raiden Network** - Ethereum payment channels (raiden.network)

### 10.2 Specifications

- **HTTP/1.1 Status Code 402** - RFC 7231 Section 6.5.2
- **EIP-712** - Typed structured data hashing and signing
- **WebSocket Protocol** - RFC 6455
- **JSON Encoding** - RFC 8259

### 10.3 BIMP Versioning

**Current Version:** BIMP/1.0

**Version String Format:** `BIMP/MAJOR.MINOR`

**Backwards Compatibility:**
- MINOR version changes are backwards compatible
- MAJOR version changes may break compatibility

---

## Appendix A: Packet Examples

### A.1 Complete Session Example

```
// 1. HTTP 402 Discovery
GET /api/sensor-data
→ 402 Payment Required (with BIMP/1.0 requirements)

// 2. x402 Channel Setup
POST /api/sensor-data/channel-setup
X-PAYMENT: <x402 payment>
→ 200 OK (channelId, streamEndpoint, token)

// 3. Channel Deposit
client.deposit(channelId, 1000000 wei)

// 4. WebSocket Upgrade
ws = new WebSocket(streamEndpoint, { Authorization: Bearer <token> })

// 5. CONNECT
→ { type: "CONNECT", channel: {...}, limits: {...} }
← { type: "CONNECTED", sessionId: "...", channel: {...} }

// 6. Stream Payments
→ { type: "PAYMENT", payment: { stateNumber: 1, totalClaimable: "100", sig: "..." }, data: {...} }
← { type: "PAYMENT", payment: { counterpartyClaimable: "50", sig: "..." }, data: {...} }

→ { type: "PAYMENT", payment: { stateNumber: 2, totalClaimable: "200", sig: "..." }, data: {...} }
← { type: "PAYMENT", payment: { counterpartyClaimable: "100", sig: "..." }, data: {...} }

... (repeat 998 more times) ...

// 7. Settlement (server decides)
server.settle(channelId, stateNumber: 1000, totalClaimable: "100000", signature)

// 8. Close
→ { type: "CONTROL", control: { action: "CLOSE" } }
← { type: "CONTROL", control: { action: "CLOSE" } }
```

---

## Appendix B: Smart Contract Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBIMPChannel {
  struct Channel {
    address client;
    address server;
    uint256 capacity;
    uint256 clientBalance;
    uint256 serverBalance;
    uint256 lastStateNumber;
    uint256 expiresAt;
    bool isOpen;
    bool isBidirectional;
  }

  function createChannel(
    address client,
    address server,
    uint256 capacity,
    uint256 duration,
    bool bidirectional
  ) external returns (bytes32 channelId);

  function deposit(bytes32 channelId) external payable;

  function settle(
    bytes32 channelId,
    uint256 stateNumber,
    uint256 claimAmount,
    address recipient,
    uint256 timestamp,
    bytes memory signature
  ) external;

  function closeChannel(bytes32 channelId) external;

  function getChannel(bytes32 channelId) external view returns (Channel memory);

  function getBalance(bytes32 channelId) external view returns (uint256, uint256);
}
```

---

## Appendix C: Settlement Adapter Interface

```typescript
interface IBIMPSettlementAdapter {
  readonly type: string  // "lightning" | "state-channel" | "x402"

  settle(params: {
    channelId: string
    stateNumber: number
    claimAmount: string
    signature: string
  }): Promise<SettlementProof>

  verify(proof: SettlementProof): Promise<boolean>

  getStatus(proof: SettlementProof): Promise<'pending' | 'confirmed' | 'failed'>
}
```

---

## Document History

**Version 1.0.0-draft (2025-11-17)**
- Initial specification
- Core protocol definition
- x402 handshake integration
- Payment channel abstraction
- Reference implementations

---

**Protocol Identifier:** `BIMP/1.0`
**MIME Type:** `application/bimp+json`
**WebSocket Subprotocol:** `bimp.v1`

---

**Authors:**
- Jonathan Green
- Claude (Anthropic)

**License:** MIT (proposed)

**Status:** Draft specification, open for community feedback

**Repository:** TBD

---

*BIMP - Bidirectional Interledger Micropayment Protocol*
*Making micropayments simple for machines.*

