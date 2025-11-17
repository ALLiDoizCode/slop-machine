# µStream Protocol Specification
## Lightweight Streaming Micropayments for M2M Communication

**Version:** 0.1.0-draft
**Status:** Design Proposal
**Date:** November 17, 2025

---

## Overview

µStream (MicroStream) is a lightweight protocol for streaming micropayments over HTTP/WebSocket connections. It combines payment metadata with application data in a simple, efficient format designed specifically for machine-to-machine (M2M) communication.

### Design Goals

1. **Simplicity** - 90% simpler than ILP/STREAM, 10x easier to implement
2. **Ledger Agnostic** - Works with any blockchain or payment system
3. **HTTP 402 Native** - Built around HTTP semantics
4. **Bidirectional** - Both parties can stream payments
5. **Efficient** - Minimal overhead, suitable for high-frequency micropayments
6. **Secure** - Cryptographically signed payments

### Key Differences from ILP/STREAM

| Feature | ILP/STREAM | µStream |
|---------|-----------|---------|
| **Routing** | Multi-hop connectors | Direct peer-to-peer only |
| **Encoding** | ASN.1 binary | JSON (human-readable) |
| **Complexity** | ~3000 LOC | ~300 LOC (estimated) |
| **Frame Types** | 10+ types | 3 types (Payment, Data, Control) |
| **Flow Control** | TCP-style AIMD | Simple threshold limits |
| **Settlement** | Conditional (hash preimage) | Direct signature verification |
| **Transport** | ILP-over-BTP-over-WS | Native WebSocket/HTTP |

---

## Protocol Layers

```
┌─────────────────────────────────────┐
│     Application Layer               │
│   (Your M2M application logic)      │
└─────────────────────────────────────┘
               ↕
┌─────────────────────────────────────┐
│     µStream Protocol Layer          │
│  (Payment + Data streaming)         │
└─────────────────────────────────────┘
               ↕
┌─────────────────────────────────────┐
│     Transport Layer                 │
│   (WebSocket or HTTP/2 SSE)         │
└─────────────────────────────────────┘
               ↕
┌─────────────────────────────────────┐
│     Settlement Layer (Pluggable)    │
│  (x402, Lightning, Raiden, etc.)    │
└─────────────────────────────────────┘
```

---

## Connection Lifecycle

### Phase 1: Discovery & Negotiation (HTTP 402)

**Client requests resource without payment:**

```http
GET /api/stream/sensor-data HTTP/1.1
Host: sensor.example.com
Accept: application/json
```

**Server responds with payment requirements:**

```http
HTTP/1.1 402 Payment Required
Content-Type: application/json
X-MicroStream-Version: 0.1
X-MicroStream-Upgrade: ws://sensor.example.com/stream/abc123

{
  "protocol": "microstream/0.1",
  "paymentMethods": [
    {
      "type": "x402",
      "network": "base",
      "asset": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
      "rate": "1000",
      "rateUnit": "wei/message",
      "settlementInterval": 10,
      "maxUnsettled": "10000"
    },
    {
      "type": "lightning",
      "node": "03abc...@lightning.example.com:9735",
      "rate": "100",
      "rateUnit": "sat/message",
      "settlementInterval": 100,
      "maxUnsettled": "10000"
    }
  ],
  "streamEndpoint": "wss://sensor.example.com/stream/abc123",
  "expiresAt": "2025-11-17T12:34:56Z"
}
```

**Key Fields:**
- `paymentMethods` - Array of accepted payment options (choose one)
- `type` - Payment settlement type (x402, lightning, ethereum, etc.)
- `rate` - Payment amount per message/event
- `settlementInterval` - Settle every N messages
- `maxUnsettled` - Maximum outstanding balance before settlement required
- `streamEndpoint` - WebSocket URL for streaming connection

### Phase 2: WebSocket Connection Establishment

**Client upgrades to WebSocket:**

```javascript
const ws = new WebSocket('wss://sensor.example.com/stream/abc123')

// Send connection initialization
ws.send(JSON.stringify({
  type: 'CONNECT',
  version: '0.1',
  paymentMethod: {
    type: 'x402',
    network: 'base',
    asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    payerAddress: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1'
  },
  receiveMax: '1000000',  // Max willing to receive (if bidirectional)
  sendMax: '1000000'      // Max willing to send
}))
```

**Server acknowledges:**

```json
{
  "type": "CONNECTED",
  "sessionId": "sess_abc123",
  "payeeAddress": "0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d",
  "receiveMax": "500000",
  "sendMax": "2000000",
  "requiresSettlement": false
}
```

**Connection is now established for bidirectional streaming.**

---

## Packet Format

### Core Packet Structure

All µStream packets are JSON messages over WebSocket:

```typescript
type MicroStreamPacket =
  | PaymentPacket
  | DataPacket
  | ControlPacket

interface BasePacket {
  type: 'PAYMENT' | 'DATA' | 'CONTROL'
  seq: number              // Sequence number (increments per packet)
  timestamp: number        // Unix timestamp milliseconds
}
```

### Packet Type 1: PAYMENT

Carries payment metadata and optional settlement proofs.

```typescript
interface PaymentPacket extends BasePacket {
  type: 'PAYMENT'
  payment: {
    amount: string           // Payment amount (string to avoid precision loss)
    asset: string            // Asset identifier (token address, "BTC", etc.)
    direction: 'SEND' | 'RECEIVE'
    totalSent?: string       // Cumulative total sent by sender
    totalReceived?: string   // Cumulative total received by sender
    signature: string        // Cryptographic signature of payment commitment
    settlementProof?: {      // Optional: Proof of on-chain settlement
      type: string           // 'x402' | 'lightning' | 'ethereum' | etc.
      txHash?: string        // Transaction hash
      paymentProof: string   // Settlement-specific proof data
    }
  }
  data?: any                 // Optional: Application data bundled with payment
}
```

**Example - Client pays server:**

```json
{
  "type": "PAYMENT",
  "seq": 42,
  "timestamp": 1700234567890,
  "payment": {
    "amount": "1000",
    "asset": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "direction": "SEND",
    "totalSent": "42000",
    "signature": "0x1234abcd...signature of (sessionId, seq, amount, totalSent)"
  },
  "data": {
    "request": "temperature",
    "location": "sensor-01"
  }
}
```

**Example - Server acknowledges and pays client back (bidirectional):**

```json
{
  "type": "PAYMENT",
  "seq": 43,
  "timestamp": 1700234568123,
  "payment": {
    "amount": "500",
    "asset": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "direction": "SEND",
    "totalSent": "15500",
    "signature": "0x5678efgh...signature"
  },
  "data": {
    "temperature": 23.5,
    "humidity": 45.2,
    "reward": "bonus for frequent customer"
  }
}
```

### Packet Type 2: DATA

Carries application data without payment (for messages that don't require payment).

```typescript
interface DataPacket extends BasePacket {
  type: 'DATA'
  data: any                  // Application-specific payload
}
```

**Example:**

```json
{
  "type": "DATA",
  "seq": 44,
  "timestamp": 1700234569000,
  "data": {
    "status": "processing",
    "progress": 0.5
  }
}
```

### Packet Type 3: CONTROL

Control flow and connection management.

```typescript
interface ControlPacket extends BasePacket {
  type: 'CONTROL'
  control: {
    action: 'CONNECT' | 'CONNECTED' | 'SETTLE' | 'SETTLED' | 'LIMIT_UPDATE' | 'CLOSE' | 'ERROR'
    payload: any
  }
}
```

**Control Actions:**

#### CONNECT / CONNECTED
Already shown in Phase 2 above.

#### SETTLE
Request immediate settlement (before reaching `settlementInterval`).

```json
{
  "type": "CONTROL",
  "seq": 50,
  "timestamp": 1700234570000,
  "control": {
    "action": "SETTLE",
    "payload": {
      "amount": "42000",
      "reason": "threshold reached"
    }
  }
}
```

#### SETTLED
Confirm settlement completed with on-chain proof.

```json
{
  "type": "CONTROL",
  "seq": 51,
  "timestamp": 1700234575000,
  "control": {
    "action": "SETTLED",
    "payload": {
      "amount": "42000",
      "settlementProof": {
        "type": "x402",
        "txHash": "0xabcdef1234567890...",
        "blockNumber": 12345678,
        "confirmations": 3
      }
    }
  }
}
```

#### LIMIT_UPDATE
Update send/receive limits during connection.

```json
{
  "type": "CONTROL",
  "seq": 52,
  "timestamp": 1700234580000,
  "control": {
    "action": "LIMIT_UPDATE",
    "payload": {
      "sendMax": "2000000",
      "receiveMax": "1500000"
    }
  }
}
```

#### CLOSE
Gracefully close connection.

```json
{
  "type": "CONTROL",
  "seq": 100,
  "timestamp": 1700234600000,
  "control": {
    "action": "CLOSE",
    "payload": {
      "reason": "completed",
      "finalTotalSent": "98000",
      "finalTotalReceived": "45000"
    }
  }
}
```

#### ERROR
Report error condition.

```json
{
  "type": "CONTROL",
  "seq": 55,
  "timestamp": 1700234590000,
  "control": {
    "action": "ERROR",
    "payload": {
      "code": "INSUFFICIENT_PAYMENT",
      "message": "Total unsettled amount exceeds maxUnsettled",
      "requiresSettlement": true
    }
  }
}
```

---

## Payment Flow & Settlement

### Streaming Payment Accumulation

**Payments accumulate off-chain (in-memory tracking):**

```
Message 1:  Client pays 1000 → Total unsettled: 1000
Message 2:  Client pays 1000 → Total unsettled: 2000
Message 3:  Client pays 1000 → Total unsettled: 3000
...
Message 10: Client pays 1000 → Total unsettled: 10000
```

**When settlement threshold reached (`settlementInterval` or `maxUnsettled`):**

```
Server: Sends CONTROL/SETTLE packet
Client: Executes on-chain settlement (x402, Lightning, etc.)
Client: Sends CONTROL/SETTLED with proof
Server: Verifies settlement, resets unsettled balance to 0
Streaming continues...
```

### Settlement Abstraction

µStream doesn't care HOW settlement happens. It just requires:

1. **Payment commitment signature** - Proves intent to pay
2. **Settlement proof** - Proves actual payment (when settling)

**Settlement adapters can be plugged in:**

#### x402 Settlement Adapter
```javascript
class X402SettlementAdapter {
  async settle(amount, recipient, asset, network) {
    // Use x402 protocol to settle on-chain
    const payment = await this.x402Client.pay({
      amount,
      recipient,
      asset,
      network
    })
    return {
      type: 'x402',
      txHash: payment.txHash,
      paymentProof: payment.signature
    }
  }

  async verify(settlementProof) {
    // Verify x402 settlement proof
    return await this.x402Client.verifySettlement(settlementProof)
  }
}
```

#### Lightning Settlement Adapter
```javascript
class LightningSettlementAdapter {
  async settle(amount, recipient) {
    const invoice = await this.lightningNode.createInvoice({
      amount,
      recipient
    })
    const payment = await this.lightningNode.payInvoice(invoice)
    return {
      type: 'lightning',
      paymentHash: payment.paymentHash,
      preimage: payment.preimage
    }
  }

  async verify(settlementProof) {
    // Verify preimage matches payment hash
    return sha256(settlementProof.preimage) === settlementProof.paymentHash
  }
}
```

#### Direct Ethereum Settlement Adapter
```javascript
class EthereumSettlementAdapter {
  async settle(amount, recipient, asset) {
    const tx = await this.wallet.sendTransaction({
      to: asset, // ERC20 contract
      data: encodeTransfer(recipient, amount)
    })
    await tx.wait(3) // Wait for confirmations
    return {
      type: 'ethereum',
      txHash: tx.hash,
      blockNumber: tx.blockNumber
    }
  }

  async verify(settlementProof) {
    const receipt = await this.provider.getTransactionReceipt(
      settlementProof.txHash
    )
    return receipt && receipt.confirmations >= 3
  }
}
```

### Bidirectional Settlement

**Both parties track separate balances:**

```
Client → Server balance:  50,000 unsettled
Server → Client balance:  20,000 unsettled
Net owed (Client → Server): 30,000
```

**Settlement can be net or gross:**

**Option A: Net Settlement** (more efficient)
- Calculate net owed: 50,000 - 20,000 = 30,000
- Only client settles 30,000 on-chain
- Both balances reset to 0

**Option B: Gross Settlement** (simpler accounting)
- Client settles 50,000 to server
- Server settles 20,000 to client
- Two separate on-chain transactions

---

## Cryptographic Signatures

### Signature Format

Each PAYMENT packet must include a signature proving the payment commitment.

**What to sign:**

```javascript
const message = {
  sessionId: 'sess_abc123',
  seq: 42,
  amount: '1000',
  totalSent: '42000',
  recipient: '0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d',
  timestamp: 1700234567890
}

const messageHash = keccak256(JSON.stringify(message))
const signature = await wallet.signMessage(messageHash)
```

**Verification:**

```javascript
const recoveredAddress = ethers.utils.verifyMessage(messageHash, signature)
assert(recoveredAddress === expectedPayerAddress)
```

### Signature Types by Settlement Method

| Settlement Method | Signature Type | Purpose |
|-------------------|----------------|---------|
| **x402 (EVM)** | EIP-712 typed data | On-chain verifiable |
| **Lightning** | BOLT-11 invoice signature | Lightning-native |
| **Bitcoin** | ECDSA (secp256k1) | Standard Bitcoin sig |
| **Solana** | Ed25519 | Solana-native |
| **Custom** | Any (protocol-defined) | Application-specific |

---

## Flow Control & Limits

### Simple Threshold Model

Unlike STREAM's complex flow control, µStream uses simple limits:

```javascript
interface ConnectionLimits {
  sendMax: string        // Max total I'm willing to send
  receiveMax: string     // Max total I'm willing to receive
  maxUnsettled: string   // Max unsettled before settlement required
}
```

**Rules:**

1. **Before sending PAYMENT packet:**
   ```javascript
   if (myTotalSent + amount > mySendMax) {
     throw new Error('Would exceed sendMax limit')
   }
   if (peerTotalReceived + amount > peerReceiveMax) {
     throw new Error('Peer receiveMax limit reached')
   }
   ```

2. **Before accepting PAYMENT packet:**
   ```javascript
   if (peerTotalSent + amount > peerSendMax) {
     throw new Error('Peer exceeded their sendMax')
   }
   if (myTotalReceived + amount > myReceiveMax) {
     sendControlPacket({ action: 'ERROR', code: 'RECEIVE_LIMIT' })
   }
   ```

3. **Settlement trigger:**
   ```javascript
   if (unsettledBalance >= maxUnsettled) {
     sendControlPacket({ action: 'SETTLE' })
   }
   ```

**No complex windowing, no congestion control, no AIMD.**

---

## Error Handling

### Error Codes

| Code | Description | Action |
|------|-------------|--------|
| `INSUFFICIENT_PAYMENT` | Payment amount too low | Increase payment or close |
| `EXCEED_SEND_LIMIT` | Sender exceeded sendMax | Stop sending or update limit |
| `EXCEED_RECEIVE_LIMIT` | Receiver hit receiveMax | Update limit or close |
| `SETTLEMENT_REQUIRED` | Must settle before continuing | Execute settlement |
| `SETTLEMENT_FAILED` | Settlement verification failed | Retry or close connection |
| `INVALID_SIGNATURE` | Payment signature invalid | Close connection (fraud) |
| `SEQUENCE_ERROR` | Packet sequence out of order | Resync or close |
| `UNKNOWN_SESSION` | Session ID not recognized | Reconnect with new session |

### Error Recovery

**Transient errors** (network issues, temporary limits):
- Client retries with backoff
- Connection remains open

**Fatal errors** (fraud, invalid signatures):
- Send CONTROL/CLOSE immediately
- Close WebSocket
- Report to monitoring

---

## Implementation Guide

### Minimal Server Implementation (Node.js)

```javascript
import WebSocket from 'ws'
import { ethers } from 'ethers'

class MicroStreamServer {
  constructor(config) {
    this.config = config
    this.sessions = new Map()
    this.settlementAdapter = config.settlementAdapter
  }

  start(port) {
    this.wss = new WebSocket.Server({ port })

    this.wss.on('connection', (ws, req) => {
      const sessionId = this.generateSessionId()
      const session = {
        id: sessionId,
        ws,
        state: 'INIT',
        totalReceived: 0n,
        totalSent: 0n,
        unsettledBalance: 0n,
        limits: {
          sendMax: BigInt(this.config.defaultSendMax),
          receiveMax: BigInt(this.config.defaultReceiveMax),
          maxUnsettled: BigInt(this.config.maxUnsettled)
        }
      }

      this.sessions.set(sessionId, session)

      ws.on('message', (data) => this.handleMessage(session, data))
      ws.on('close', () => this.handleClose(session))
    })
  }

  handleMessage(session, data) {
    const packet = JSON.parse(data)

    switch (packet.type) {
      case 'CONTROL':
        this.handleControl(session, packet)
        break
      case 'PAYMENT':
        this.handlePayment(session, packet)
        break
      case 'DATA':
        this.handleData(session, packet)
        break
    }
  }

  handleControl(session, packet) {
    const { action, payload } = packet.control

    switch (action) {
      case 'CONNECT':
        session.state = 'CONNECTED'
        session.payerAddress = payload.payerAddress
        session.limits.sendMax = BigInt(payload.sendMax || this.config.defaultSendMax)

        this.send(session, {
          type: 'CONTROL',
          seq: 0,
          timestamp: Date.now(),
          control: {
            action: 'CONNECTED',
            payload: {
              sessionId: session.id,
              payeeAddress: this.config.payeeAddress,
              receiveMax: session.limits.receiveMax.toString(),
              sendMax: session.limits.sendMax.toString()
            }
          }
        })
        break

      case 'SETTLE':
        // Client is initiating settlement
        // Wait for SETTLED packet with proof
        session.state = 'SETTLING'
        break

      case 'SETTLED':
        // Verify settlement proof
        this.verifySettlement(session, payload.settlementProof)
          .then(() => {
            session.unsettledBalance = 0n
            session.state = 'CONNECTED'
          })
          .catch((err) => {
            this.sendError(session, 'SETTLEMENT_FAILED', err.message)
          })
        break
    }
  }

  async handlePayment(session, packet) {
    const { amount, signature, totalSent } = packet.payment
    const amountBigInt = BigInt(amount)

    // Verify signature
    const valid = await this.verifySignature(session, packet)
    if (!valid) {
      this.sendError(session, 'INVALID_SIGNATURE', 'Payment signature invalid')
      return
    }

    // Check limits
    if (session.totalReceived + amountBigInt > session.limits.receiveMax) {
      this.sendError(session, 'EXCEED_RECEIVE_LIMIT', 'Receive limit exceeded')
      return
    }

    // Accept payment
    session.totalReceived += amountBigInt
    session.unsettledBalance += amountBigInt

    // Process application data
    const response = await this.handleApplicationData(packet.data)

    // Send response with optional payment
    this.sendPayment(session, {
      amount: '500', // Send 500 back as reward
      data: response
    })

    // Check if settlement needed
    if (session.unsettledBalance >= session.limits.maxUnsettled) {
      this.requestSettlement(session)
    }
  }

  async verifySignature(session, packet) {
    const message = {
      sessionId: session.id,
      seq: packet.seq,
      amount: packet.payment.amount,
      totalSent: packet.payment.totalSent,
      recipient: this.config.payeeAddress,
      timestamp: packet.timestamp
    }

    const messageHash = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(JSON.stringify(message))
    )

    const recoveredAddress = ethers.utils.verifyMessage(
      messageHash,
      packet.payment.signature
    )

    return recoveredAddress.toLowerCase() === session.payerAddress.toLowerCase()
  }

  sendPayment(session, { amount, data }) {
    session.totalSent += BigInt(amount)

    this.send(session, {
      type: 'PAYMENT',
      seq: session.seq++,
      timestamp: Date.now(),
      payment: {
        amount,
        asset: this.config.asset,
        direction: 'SEND',
        totalSent: session.totalSent.toString(),
        signature: this.signPayment(session, amount)
      },
      data
    })
  }

  requestSettlement(session) {
    this.send(session, {
      type: 'CONTROL',
      seq: session.seq++,
      timestamp: Date.now(),
      control: {
        action: 'SETTLE',
        payload: {
          amount: session.unsettledBalance.toString(),
          reason: 'threshold reached'
        }
      }
    })
  }

  send(session, packet) {
    session.ws.send(JSON.stringify(packet))
  }

  sendError(session, code, message) {
    this.send(session, {
      type: 'CONTROL',
      seq: session.seq++,
      timestamp: Date.now(),
      control: {
        action: 'ERROR',
        payload: { code, message }
      }
    })
  }
}

// Usage
const server = new MicroStreamServer({
  defaultSendMax: '1000000',
  defaultReceiveMax: '1000000',
  maxUnsettled: '10000',
  payeeAddress: '0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d',
  asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
  settlementAdapter: new X402SettlementAdapter()
})

server.start(8080)
```

### Minimal Client Implementation

```javascript
import WebSocket from 'ws'
import { ethers } from 'ethers'

class MicroStreamClient {
  constructor(config) {
    this.config = config
    this.wallet = new ethers.Wallet(config.privateKey)
    this.seq = 1
    this.totalSent = 0n
    this.totalReceived = 0n
  }

  async connect(streamEndpoint) {
    // 1. Discover via HTTP 402
    const discovery = await fetch(this.config.resourceUrl)
    if (discovery.status !== 402) {
      throw new Error('Expected 402 Payment Required')
    }
    const requirements = await discovery.json()

    // 2. Connect to WebSocket
    this.ws = new WebSocket(requirements.streamEndpoint)

    await new Promise((resolve) => {
      this.ws.once('open', resolve)
    })

    // 3. Send CONNECT
    this.send({
      type: 'CONTROL',
      seq: this.seq++,
      timestamp: Date.now(),
      control: {
        action: 'CONNECT',
        payload: {
          paymentMethod: requirements.paymentMethods[0],
          payerAddress: this.wallet.address,
          sendMax: '1000000',
          receiveMax: '500000'
        }
      }
    })

    // 4. Wait for CONNECTED
    return new Promise((resolve) => {
      this.ws.on('message', (data) => {
        const packet = JSON.parse(data)
        if (packet.type === 'CONTROL' && packet.control.action === 'CONNECTED') {
          this.sessionId = packet.control.payload.sessionId
          resolve()
        }
        this.handleMessage(packet)
      })
    })
  }

  async sendPayment(amount, data) {
    this.totalSent += BigInt(amount)

    const message = {
      sessionId: this.sessionId,
      seq: this.seq,
      amount,
      totalSent: this.totalSent.toString(),
      recipient: this.config.payeeAddress,
      timestamp: Date.now()
    }

    const messageHash = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(JSON.stringify(message))
    )
    const signature = await this.wallet.signMessage(messageHash)

    this.send({
      type: 'PAYMENT',
      seq: this.seq++,
      timestamp: Date.now(),
      payment: {
        amount,
        asset: this.config.asset,
        direction: 'SEND',
        totalSent: this.totalSent.toString(),
        signature
      },
      data
    })
  }

  handleMessage(packet) {
    switch (packet.type) {
      case 'PAYMENT':
        this.totalReceived += BigInt(packet.payment.amount)
        this.emit('payment', packet.payment)
        if (packet.data) {
          this.emit('data', packet.data)
        }
        break

      case 'CONTROL':
        if (packet.control.action === 'SETTLE') {
          this.executeSettlement(packet.control.payload)
        }
        break
    }
  }

  async executeSettlement(payload) {
    const settlementProof = await this.settlementAdapter.settle(
      payload.amount,
      this.config.payeeAddress,
      this.config.asset
    )

    this.send({
      type: 'CONTROL',
      seq: this.seq++,
      timestamp: Date.now(),
      control: {
        action: 'SETTLED',
        payload: { settlementProof }
      }
    })
  }

  send(packet) {
    this.ws.send(JSON.stringify(packet))
  }
}

// Usage
const client = new MicroStreamClient({
  resourceUrl: 'https://sensor.example.com/api/stream/sensor-data',
  privateKey: '0x...',
  payeeAddress: '0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d',
  asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
  settlementAdapter: new X402SettlementAdapter()
})

await client.connect()

// Stream payments
setInterval(() => {
  client.sendPayment('1000', { request: 'temperature' })
}, 100) // Every 100ms

client.on('data', (data) => {
  console.log('Received:', data)
})
```

---

## Comparison: µStream vs ILP/STREAM

### Complexity Reduction

| Metric | ILP/STREAM | µStream | Reduction |
|--------|-----------|---------|-----------|
| **Spec Pages** | ~50 pages | ~15 pages | 70% |
| **Packet Types** | 3 ILP + 10+ STREAM frames | 3 packet types | 75% |
| **Code (estimated)** | ~3000 LOC | ~300 LOC | 90% |
| **Dependencies** | ILP plugin, STREAM lib, crypto | WebSocket, crypto lib | 50% |
| **Learning Curve** | High (connectors, routing) | Low (HTTP + WebSocket) | 80% |

### Feature Comparison

| Feature | ILP/STREAM | µStream |
|---------|-----------|---------|
| Multi-hop routing | ✅ Yes | ❌ No (peer-to-peer) |
| Bidirectional payments | ✅ Yes | ✅ Yes |
| Payment + data bundling | ✅ Yes | ✅ Yes |
| Ledger abstraction | ✅ Yes | ✅ Yes (pluggable) |
| HTTP 402 integration | ❌ No (needs wrapper) | ✅ Native |
| WebSocket support | ✅ Yes (via BTP) | ✅ Native |
| Cryptographic security | ✅ AES-256-GCM | ✅ Signature-based |
| Flow control | ✅ Complex (TCP-style) | ✅ Simple (thresholds) |
| JSON encoding | ❌ No (binary ASN.1) | ✅ Yes (human-readable) |
| Implementation complexity | 🔴 High | 🟢 Low |

---

## Security Considerations

### Threat Model

**Assumptions:**
- TLS/WSS provides transport security
- Settlement layer is secure (blockchain, Lightning, etc.)
- Both parties have secure key management

**Threats:**

1. **Payment fraud** - Client sends invalid signatures
   - Mitigation: Verify all signatures before accepting payment

2. **Replay attacks** - Attacker replays old payment packets
   - Mitigation: Sequence numbers + timestamps, server tracks seen sequences

3. **Settlement failure** - Client claims settlement but doesn't actually pay
   - Mitigation: Verify settlement proofs on-chain before crediting

4. **DoS attacks** - Flood server with payment packets
   - Mitigation: Rate limiting, connection limits, require minimum payment

5. **Man-in-the-middle** - Attacker intercepts and modifies packets
   - Mitigation: Use WSS (WebSocket Secure), verify signatures

### Best Practices

1. **Always use WSS** (WebSocket Secure) with valid TLS certificates
2. **Verify signatures** on every PAYMENT packet
3. **Check sequence numbers** to detect replay attacks
4. **Validate settlement proofs** on-chain (don't trust client claims)
5. **Rate limit** connections and payment frequency
6. **Monitor balances** and enforce limits strictly
7. **Log all payments** for auditing and dispute resolution
8. **Use nonces** in signatures to prevent replay across sessions

---

## Extension Points

### Future Enhancements (Out of Scope for v0.1)

1. **Multi-hop routing** - Add connector support for cross-network payments
2. **Stream multiplexing** - Multiple logical streams per connection
3. **Congestion control** - Adaptive rate limiting based on network conditions
4. **Binary encoding** - Protobuf or CBOR for efficiency (optional)
5. **Receipt generation** - Cryptographic receipts for payment proof
6. **Payment channels** - Integrate with Lightning/Raiden for off-chain settlement
7. **Atomic swaps** - Cross-chain atomic settlement
8. **Privacy features** - Zero-knowledge proofs for payment privacy

### Extensibility Mechanisms

**Custom control actions:**
```json
{
  "type": "CONTROL",
  "control": {
    "action": "X-CUSTOM-ACTION",
    "payload": { /* application-specific */ }
  }
}
```

**Custom payment methods:**
```json
{
  "type": "x-custom-settlement",
  "settlementAdapter": "MyCustomAdapter"
}
```

**Application-specific data schemas:**
```json
{
  "type": "PAYMENT",
  "payment": { /* ... */ },
  "data": {
    "schema": "https://example.com/schemas/sensor-v1",
    "payload": { /* ... */ }
  }
}
```

---

## Appendix A: Full Example Session

### Complete Flow: Client Streams Sensor Data Payments

```
1. Client discovers endpoint (HTTP 402)
   GET /api/stream/sensor-data → 402 Payment Required

2. Client connects via WebSocket
   → CONTROL/CONNECT

3. Server acknowledges
   ← CONTROL/CONNECTED (sessionId: sess_abc)

4. Client sends payment #1 + request
   → PAYMENT (seq:1, amount:1000, data:{request:"temp"})

5. Server responds with data + reward payment
   ← PAYMENT (seq:2, amount:500, data:{temp:23.5, reward:true})

6. Client sends payment #2
   → PAYMENT (seq:3, amount:1000, data:{request:"temp"})

7. Server responds
   ← PAYMENT (seq:4, amount:500, data:{temp:23.6})

... (repeat 8 more times) ...

14. Server requests settlement (10k threshold reached)
    ← CONTROL/SETTLE (amount:10000)

15. Client executes on-chain settlement via x402
    [x402 transaction on Base network]

16. Client confirms settlement
    → CONTROL/SETTLED (txHash:0xabc..., proof:...)

17. Server verifies on-chain
    [Verifies transaction on Base]

18. Server acknowledges, resets balance
    ← CONTROL/LIMIT_UPDATE (unsettled reset to 0)

19. Streaming continues...
    → PAYMENT (seq:21, amount:1000, ...)

20. Client closes gracefully
    → CONTROL/CLOSE (finalTotal:50000)

21. Server acknowledges and closes
    ← CONTROL/CLOSE (finalTotal:25000)
    WebSocket connection closed.
```

---

## Appendix B: Settlement Adapter Interface

```typescript
/**
 * Settlement Adapter Interface
 *
 * Implement this interface to add support for new payment systems.
 */
interface ISettlementAdapter {
  /**
   * Settlement method identifier (e.g., 'x402', 'lightning', 'ethereum')
   */
  readonly type: string

  /**
   * Execute settlement and return proof
   */
  settle(params: SettlementParams): Promise<SettlementProof>

  /**
   * Verify settlement proof is valid
   */
  verify(proof: SettlementProof): Promise<boolean>

  /**
   * Get settlement status (pending, confirmed, failed)
   */
  getStatus(proof: SettlementProof): Promise<SettlementStatus>
}

interface SettlementParams {
  amount: string
  recipient: string
  asset: string
  network?: string
  metadata?: Record<string, any>
}

interface SettlementProof {
  type: string
  txHash?: string
  paymentHash?: string
  preimage?: string
  blockNumber?: number
  confirmations?: number
  timestamp: number
  paymentProof: string
}

enum SettlementStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  FAILED = 'failed'
}
```

---

## Conclusion

µStream provides **90% of ILP/STREAM's value with 10% of the complexity**:

✅ Streaming micropayments over WebSocket
✅ Bidirectional payment flows
✅ Payment + data bundling
✅ Ledger abstraction via pluggable adapters
✅ Native HTTP 402 integration
✅ Cryptographic payment proofs
✅ Simple implementation (~300 LOC)

**Trade-offs:**
- No multi-hop routing (peer-to-peer only)
- Simpler flow control (threshold-based)
- JSON encoding (slightly less efficient than binary)

For M2M micropayment use cases that don't require connector networks, µStream is the pragmatic choice.

---

**Next Steps:**
1. Implement reference server and client
2. Test with x402, Lightning, and Ethereum settlement adapters
3. Benchmark performance and overhead
4. Gather feedback from M2M developers
5. Iterate toward v1.0 specification

