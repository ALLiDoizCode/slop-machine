# µStream + x402 Integration Guide
## Combining Lightweight Streaming with HTTP 402 Micropayments

**Version:** 0.1.0-draft
**Date:** November 17, 2025

---

## Overview

This document describes how **µStream** (lightweight streaming micropayment protocol) and **x402** (HTTP 402 payment protocol) work together to provide a complete M2M payment solution.

### The Synergy

**x402** = Discrete per-request payments (HTTP semantics)
**µStream** = Continuous streaming payments (WebSocket semantics)

**Together** = Complete payment solution for all M2M scenarios

---

## Integration Architecture

### Three-Layer Model

```
┌─────────────────────────────────────────────────────────┐
│           Application Layer                             │
│  (Your M2M service: API, data streams, etc.)            │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│        Payment Protocol Layer                           │
│                                                         │
│  ┌──────────────────┐    ┌──────────────────┐         │
│  │   x402           │    │   µStream        │         │
│  │ (per-request)    │    │ (streaming)      │         │
│  │ HTTP 402         │    │ WebSocket        │         │
│  └──────────────────┘    └──────────────────┘         │
│           ↓                       ↓                     │
│           └───────────┬───────────┘                     │
│                       ↓                                 │
│         ┌──────────────────────────┐                   │
│         │   Shared Settlement       │                   │
│         │   (Blockchain/Lightning)  │                   │
│         └──────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

## Integration Pattern 1: x402 for Settlement

**Use Case:** µStream handles streaming payments, x402 handles on-chain settlement.

### Architecture

```
Client ←─ µStream WebSocket ─→ Server
   ↓                              ↓
Payment accumulates           Payment accumulates
(10,000 messages × 100 wei)   (tracks unsettled balance)
   ↓                              ↓
When threshold reached:       Server requests settlement
   ↓                              ↓
Client uses x402 protocol     Server verifies x402 payment
to settle 1M wei on-chain
   ↓                              ↓
Continue streaming...         Reset unsettled balance
```

### How It Works

**1. µStream Connection Established**

Client and server are streaming payments over WebSocket:

```json
// Client → Server (over µStream)
{
  "type": "PAYMENT",
  "seq": 1,
  "payment": {
    "amount": "100",
    "totalSent": "100",
    "signature": "0x..."
  },
  "data": { "request": "temperature" }
}
```

**2. Unsettled Balance Grows**

```
Message 1:    100 wei → Total unsettled: 100
Message 2:    100 wei → Total unsettled: 200
...
Message 10000: 100 wei → Total unsettled: 1,000,000 (1M wei)
```

**3. Server Triggers Settlement via µStream**

```json
// Server → Client (µStream CONTROL packet)
{
  "type": "CONTROL",
  "control": {
    "action": "SETTLE",
    "payload": {
      "amount": "1000000",
      "settlementMethod": "x402",
      "network": "base",
      "asset": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
    }
  }
}
```

**4. Client Executes x402 Settlement**

Client switches to x402 protocol to settle on-chain:

```javascript
// Client settlement handler
async function handleSettlement(settlementRequest) {
  const { amount, network, asset } = settlementRequest

  // Create x402 payment payload
  const x402Payment = {
    x402Version: "1.0",
    scheme: "exact",
    network: network,
    payload: {
      amount: amount,
      recipient: serverAddress,
      asset: asset,
      nonce: generateNonce(),
      expiry: Date.now() + 30000, // 30 seconds
      signature: await signX402Payment(...)
    }
  }

  // Send to x402 facilitator for settlement
  const settlement = await x402Facilitator.settle(x402Payment)

  return settlement
}
```

**5. Client Reports Settlement Back via µStream**

```json
// Client → Server (µStream CONTROL packet)
{
  "type": "CONTROL",
  "control": {
    "action": "SETTLED",
    "payload": {
      "settlementMethod": "x402",
      "settlementProof": {
        "type": "x402",
        "txHash": "0xabc123...",
        "networkId": "base",
        "blockNumber": 12345678,
        "x402Response": {
          "success": true,
          "txHash": "0xabc123...",
          "networkId": "base"
        }
      }
    }
  }
}
```

**6. Server Verifies Settlement**

```javascript
// Server verification
async function verifyX402Settlement(settlementProof) {
  const { txHash, networkId } = settlementProof.x402Response

  // Verify on-chain using x402 facilitator or direct chain query
  const tx = await ethersProvider.getTransaction(txHash)
  const receipt = await ethersProvider.getTransactionReceipt(txHash)

  // Verify transaction details
  assert(receipt.status === 1, 'Transaction failed')
  assert(receipt.to === expectedContractAddress, 'Wrong recipient')
  assert(receipt.confirmations >= 3, 'Insufficient confirmations')

  // Decode transfer event
  const transferEvent = receipt.logs.find(log =>
    log.topics[0] === transferEventSignature
  )
  const { to, amount } = decodeTransferEvent(transferEvent)

  assert(to === serverAddress, 'Wrong recipient')
  assert(amount === expectedAmount, 'Wrong amount')

  return true // Settlement verified
}
```

**7. µStream Continues**

After successful settlement verification:

```json
// Server → Client (acknowledgment)
{
  "type": "CONTROL",
  "control": {
    "action": "SETTLEMENT_VERIFIED",
    "payload": {
      "unsettledBalance": "0",
      "canContinue": true
    }
  }
}

// Client → Server (continue streaming)
{
  "type": "PAYMENT",
  "seq": 10001,
  "payment": {
    "amount": "100",
    "totalSent": "1000100",
    "signature": "0x..."
  },
  "data": { "request": "temperature" }
}
```

### Implementation: x402 Settlement Adapter for µStream

```javascript
import { X402Client } from '@x402/client'

class X402SettlementAdapter {
  constructor(config) {
    this.x402Client = new X402Client({
      facilitatorUrl: config.facilitatorUrl,
      wallet: config.wallet
    })
    this.network = config.network
    this.asset = config.asset
  }

  /**
   * Settle accumulated payments using x402
   */
  async settle(params) {
    const { amount, recipient } = params

    // Create x402 payment
    const payment = {
      x402Version: "1.0",
      scheme: "exact",
      network: this.network,
      payload: {
        amount: amount,
        recipient: recipient,
        asset: this.asset,
        nonce: this.generateNonce(),
        expiry: Date.now() + 30000,
        signature: await this.signPayment(amount, recipient)
      }
    }

    // Submit to facilitator
    const result = await this.x402Client.settle(payment)

    return {
      type: 'x402',
      txHash: result.txHash,
      networkId: result.networkId,
      blockNumber: result.blockNumber,
      confirmations: result.confirmations,
      timestamp: Date.now(),
      paymentProof: JSON.stringify(result)
    }
  }

  /**
   * Verify x402 settlement proof
   */
  async verify(proof) {
    const x402Response = JSON.parse(proof.paymentProof)

    // Query blockchain directly
    const receipt = await this.x402Client.provider.getTransactionReceipt(
      x402Response.txHash
    )

    return receipt && receipt.status === 1 && receipt.confirmations >= 3
  }

  /**
   * Get settlement status
   */
  async getStatus(proof) {
    const receipt = await this.x402Client.provider.getTransactionReceipt(
      proof.txHash
    )

    if (!receipt) return 'PENDING'
    if (receipt.confirmations < 3) return 'PENDING'
    if (receipt.status === 1) return 'CONFIRMED'
    return 'FAILED'
  }

  async signPayment(amount, recipient) {
    const message = {
      amount,
      recipient,
      asset: this.asset,
      network: this.network,
      nonce: Date.now()
    }
    return await this.x402Client.wallet.signMessage(
      JSON.stringify(message)
    )
  }

  generateNonce() {
    return `${Date.now()}-${Math.random().toString(36).substring(7)}`
  }
}

// Usage in µStream server
const microStreamServer = new MicroStreamServer({
  settlementAdapter: new X402SettlementAdapter({
    facilitatorUrl: 'https://facilitator.x402.org',
    wallet: ethersWallet,
    network: 'base',
    asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'
  }),
  maxUnsettled: '1000000', // Settle every 1M wei
  settlementInterval: 10000 // Or settle every 10k messages
})
```

---

## Integration Pattern 2: Protocol Selection via HTTP 402

**Use Case:** Server advertises both x402 and µStream, client chooses based on use case.

### Discovery Flow

**Client requests resource:**

```http
GET /api/sensor/data HTTP/1.1
Host: sensor.example.com
Accept: application/json
```

**Server responds with both protocols:**

```http
HTTP/1.1 402 Payment Required
Content-Type: application/json

{
  "error": "Payment Required",
  "paymentOptions": [
    {
      "protocol": "x402",
      "version": "1.0",
      "type": "per-request",
      "description": "Pay per API request",
      "rate": "1000",
      "rateUnit": "wei/request",
      "networks": ["base", "polygon", "optimism"],
      "usage": "Add X-PAYMENT header to each request"
    },
    {
      "protocol": "microstream",
      "version": "0.1",
      "type": "streaming",
      "description": "Stream payments over WebSocket",
      "rate": "100",
      "rateUnit": "wei/message",
      "settlementMethod": "x402",
      "settlementInterval": 100,
      "streamEndpoint": "wss://sensor.example.com/stream/abc123",
      "usage": "Upgrade to WebSocket for continuous streaming"
    }
  ]
}
```

### Client Decision Logic

```javascript
async function selectPaymentProtocol(paymentOptions, useCase) {
  // Use case: Single request
  if (useCase.type === 'single-request') {
    return paymentOptions.find(opt => opt.protocol === 'x402')
  }

  // Use case: Occasional requests (< 10/second)
  if (useCase.frequency < 10) {
    return paymentOptions.find(opt => opt.protocol === 'x402')
  }

  // Use case: High-frequency streaming (> 10/second)
  if (useCase.frequency >= 10) {
    return paymentOptions.find(opt => opt.protocol === 'microstream')
  }

  // Use case: Bidirectional payments needed
  if (useCase.bidirectional) {
    return paymentOptions.find(opt => opt.protocol === 'microstream')
  }

  // Use case: Real-time data stream
  if (useCase.realtime) {
    return paymentOptions.find(opt => opt.protocol === 'microstream')
  }

  // Default: x402 (simpler)
  return paymentOptions.find(opt => opt.protocol === 'x402')
}
```

---

## Integration Pattern 3: x402 for Discovery + µStream for Streaming

**Use Case:** Use x402 for initial authentication/discovery, upgrade to µStream for streaming.

### Flow

```
1. Client → Server: GET /api/stream (no payment)
2. Server → Client: 402 Payment Required (x402 challenge)
3. Client → Server: GET /api/stream (with X-PAYMENT header)
4. Server → Client: 200 OK + WebSocket upgrade token
5. Client → Server: WebSocket handshake with token
6. Server → Client: WebSocket connection established
7. Client ↔ Server: µStream packets (streaming payments)
```

### Detailed Implementation

**Step 1-3: Initial x402 Payment**

```http
GET /api/stream HTTP/1.1
Host: sensor.example.com
X-PAYMENT: eyJ4NDAyVmVyc2lvbiI6IjEuMCIsInNjaGVtZSI6ImV4YWN0Ii...
```

**Step 4: Server Issues Stream Token**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "streamToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "streamEndpoint": "wss://sensor.example.com/stream",
  "expiresIn": 300,
  "paymentMethod": {
    "protocol": "microstream",
    "settlementMethod": "x402",
    "rate": "100",
    "rateUnit": "wei/message"
  }
}
```

**Step 5-6: WebSocket Connection**

```javascript
// Client connects with token
const ws = new WebSocket(
  'wss://sensor.example.com/stream',
  { headers: { Authorization: `Bearer ${streamToken}` } }
)

// Server validates token and establishes µStream session
ws.on('connection', async (socket, request) => {
  const token = request.headers.authorization?.replace('Bearer ', '')

  const session = await validateStreamToken(token)
  if (!session) {
    socket.close(4001, 'Invalid token')
    return
  }

  // Token validated (paid via x402), now use µStream
  initializeMicroStream(socket, session)
})
```

**Step 7: µStream Streaming**

```javascript
// Client sends payments via µStream
ws.send(JSON.stringify({
  type: 'PAYMENT',
  payment: {
    amount: '100',
    signature: '0x...'
  },
  data: { request: 'temperature' }
}))

// When settlement needed, use x402
ws.on('message', async (data) => {
  const packet = JSON.parse(data)

  if (packet.type === 'CONTROL' && packet.control.action === 'SETTLE') {
    const settlement = await settleViaX402(packet.control.payload)

    ws.send(JSON.stringify({
      type: 'CONTROL',
      control: {
        action: 'SETTLED',
        payload: { settlementProof: settlement }
      }
    }))
  }
})
```

### Implementation: Hybrid Authentication

```javascript
class HybridPaymentServer {
  constructor(config) {
    this.x402Handler = new X402Handler(config.x402)
    this.microStreamServer = new MicroStreamServer(config.microstream)
    this.tokenService = new TokenService(config.jwtSecret)
  }

  /**
   * HTTP endpoint with x402 authentication
   */
  async handleHttpRequest(req, res) {
    // Check for x402 payment
    const xPayment = req.headers['x-payment']

    if (!xPayment) {
      // No payment, send 402 challenge
      return res.status(402).json({
        error: 'Payment Required',
        x402Challenge: this.x402Handler.createChallenge({
          resource: req.path,
          amount: '10000', // 10k wei for stream access
          validFor: 300 // 5 minutes
        })
      })
    }

    // Verify x402 payment
    const payment = await this.x402Handler.verifyPayment(xPayment)
    if (!payment.valid) {
      return res.status(402).json({
        error: 'Invalid payment',
        reason: payment.error
      })
    }

    // Payment verified, issue stream token
    const streamToken = this.tokenService.createToken({
      userId: payment.payer,
      resource: '/stream',
      expiresIn: 300,
      paidAmount: payment.amount
    })

    return res.status(200).json({
      streamToken,
      streamEndpoint: `wss://${req.hostname}/stream`,
      expiresIn: 300,
      protocol: 'microstream/0.1',
      settlementMethod: 'x402'
    })
  }

  /**
   * WebSocket endpoint with token validation
   */
  async handleWebSocketUpgrade(ws, request) {
    // Validate bearer token
    const token = this.extractToken(request)
    const session = await this.tokenService.verifyToken(token)

    if (!session) {
      ws.close(4001, 'Invalid or expired token')
      return
    }

    // Initialize µStream with x402 settlement
    const microStreamSession = {
      userId: session.userId,
      limits: {
        sendMax: '1000000',
        receiveMax: '500000',
        maxUnsettled: '100000'
      },
      settlementAdapter: new X402SettlementAdapter({
        // ... x402 config
      })
    }

    this.microStreamServer.handleConnection(ws, microStreamSession)
  }

  extractToken(request) {
    const auth = request.headers.authorization
    if (auth?.startsWith('Bearer ')) {
      return auth.substring(7)
    }
    return null
  }
}

// Usage
const server = new HybridPaymentServer({
  x402: {
    facilitatorUrl: 'https://facilitator.x402.org',
    network: 'base',
    asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'
  },
  microstream: {
    maxUnsettled: '100000',
    settlementInterval: 1000
  },
  jwtSecret: process.env.JWT_SECRET
})

// HTTP endpoint
app.get('/api/stream', (req, res) =>
  server.handleHttpRequest(req, res)
)

// WebSocket endpoint
wss.on('connection', (ws, req) =>
  server.handleWebSocketUpgrade(ws, req)
)
```

---

## Integration Pattern 4: Dual-Protocol Mode

**Use Case:** Support both protocols simultaneously for different use cases.

### Unified API

```javascript
class UnifiedPaymentAPI {
  constructor(config) {
    this.x402 = new X402Handler(config.x402)
    this.microstream = new MicroStreamServer(config.microstream)
  }

  /**
   * Handle request with automatic protocol detection
   */
  async handleRequest(req, res) {
    // Detect protocol from headers or upgrade request
    if (req.headers['upgrade'] === 'websocket') {
      return this.handleMicroStream(req, res)
    }

    if (req.headers['x-payment']) {
      return this.handleX402(req, res)
    }

    // No payment, offer both options
    return res.status(402).json({
      error: 'Payment Required',
      options: {
        x402: {
          description: 'Pay per request',
          rate: '1000 wei/request',
          usage: 'Add X-PAYMENT header'
        },
        microstream: {
          description: 'Stream payments',
          rate: '100 wei/message',
          usage: 'Upgrade to WebSocket'
        }
      }
    })
  }

  async handleX402(req, res) {
    const payment = await this.x402.verifyPayment(req.headers['x-payment'])

    if (!payment.valid) {
      return res.status(402).json({ error: 'Invalid payment' })
    }

    // Process single request
    const data = await this.processRequest(req)
    return res.status(200).json(data)
  }

  async handleMicroStream(req, res) {
    // Upgrade to WebSocket
    const ws = await this.upgradeToWebSocket(req, res)

    // Initialize µStream session
    this.microstream.handleConnection(ws, {
      settlementAdapter: new X402SettlementAdapter(/* config */)
    })
  }
}
```

---

## Use Case Decision Matrix

### When to Use Each Protocol

| Scenario | Protocol | Reason |
|----------|----------|--------|
| **Single API request** | x402 | Simple, stateless, HTTP-native |
| **Occasional requests (< 10/sec)** | x402 | Lower overhead, no connection state |
| **High-frequency (> 10/sec)** | µStream | Amortize connection cost, lower latency |
| **Real-time data stream** | µStream | WebSocket efficiency, continuous flow |
| **Bidirectional payments** | µStream | Native bidirectional support |
| **Request-response pattern** | x402 | Natural HTTP semantics |
| **Pub-sub pattern** | µStream | Persistent connection, event-driven |
| **One-time purchase** | x402 | No session needed |
| **Subscription service** | µStream | Long-lived connection, recurring payments |
| **Mixed usage** | Both | Start with x402, upgrade to µStream when needed |

### Decision Tree

```
┌─────────────────────────────────────┐
│  Need continuous data stream?       │
└─────────────────────────────────────┘
          │                    │
        YES                   NO
          │                    │
          ↓                    ↓
   ┌─────────────┐      ┌─────────────┐
   │  µStream    │      │ > 10 req/sec?│
   └─────────────┘      └─────────────┘
                              │      │
                            YES     NO
                              │      │
                              ↓      ↓
                        ┌──────────┐ ┌──────────┐
                        │ µStream  │ │  x402    │
                        └──────────┘ └──────────┘

┌─────────────────────────────────────┐
│  Need bidirectional payments?       │
└─────────────────────────────────────┘
          │                    │
        YES                   NO
          │                    │
          ↓                    ↓
   ┌─────────────┐      ┌─────────────┐
   │  µStream    │      │ Either works│
   └─────────────┘      │ (see above) │
                        └─────────────┘
```

---

## Cost-Benefit Analysis

### x402 (Per-Request)

**Costs:**
- On-chain gas per settlement: ~$0.001 - $0.01 (L2)
- HTTP overhead per request: ~500 bytes
- Stateless (no session management)

**Benefits:**
- Simple implementation
- No persistent connections
- Natural HTTP semantics
- Works with standard HTTP tooling

**Best for:** < 10 requests/second

### µStream (Streaming)

**Costs:**
- WebSocket connection overhead: ~1KB initial
- Session state management
- Periodic settlement: ~$0.001 - $0.01 per batch

**Benefits:**
- Lower per-message overhead: ~100-200 bytes
- Bidirectional payments
- Lower latency
- Batch settlement (amortize gas costs)

**Best for:** > 10 requests/second, continuous streams

### Cost Example

**Scenario:** 1000 API calls

**x402:**
```
1000 calls × 1000 wei = 1M wei total
Settlement: Every call or batched
Gas cost: 1-1000 transactions × $0.001 = $0.001 - $1.00
HTTP overhead: 1000 × 500 bytes = 500KB
```

**µStream:**
```
1000 messages × 100 wei = 100K wei total
Settlement: 1 batch × $0.001 = $0.001
WebSocket overhead: 1KB + (1000 × 150 bytes) = 151KB
Savings: $0.00 - $0.999 + 349KB bandwidth
```

**Conclusion:** µStream is 70-99% cheaper for high-frequency scenarios.

---

## Combined Reference Architecture

### Full Stack

```typescript
// Unified payment server supporting both protocols
class M2MPaymentServer {
  private x402: X402Handler
  private microstream: MicroStreamServer
  private http: HttpServer
  private wss: WebSocketServer

  constructor(config: ServerConfig) {
    // Initialize x402 handler
    this.x402 = new X402Handler({
      facilitatorUrl: config.facilitatorUrl,
      network: config.network,
      asset: config.asset,
      payeeAddress: config.payeeAddress
    })

    // Initialize µStream with x402 settlement
    this.microstream = new MicroStreamServer({
      settlementAdapter: new X402SettlementAdapter({
        x402Handler: this.x402
      }),
      maxUnsettled: config.maxUnsettled,
      settlementInterval: config.settlementInterval
    })

    // Setup HTTP + WebSocket servers
    this.setupServers(config.port)
  }

  setupServers(port: number) {
    this.http = createServer(this.handleHttp.bind(this))
    this.wss = new WebSocketServer({ server: this.http })
    this.wss.on('connection', this.handleWebSocket.bind(this))
    this.http.listen(port)
  }

  async handleHttp(req: Request, res: Response) {
    // Check for x402 payment
    const xPayment = req.headers['x-payment']

    if (!xPayment) {
      // Send 402 with both protocol options
      return res.status(402).json({
        error: 'Payment Required',
        protocols: {
          x402: this.x402.createChallenge(req),
          microstream: {
            endpoint: `wss://${req.hostname}/stream`,
            rate: '100 wei/message',
            settlementMethod: 'x402'
          }
        }
      })
    }

    // Handle x402 payment
    const payment = await this.x402.verifyPayment(xPayment)
    if (!payment.valid) {
      return res.status(402).json({ error: 'Invalid payment' })
    }

    // Process request
    const data = await this.processRequest(req)
    return res.status(200).json(data)
  }

  async handleWebSocket(ws: WebSocket, req: Request) {
    // Initialize µStream session
    await this.microstream.handleConnection(ws, {
      settlementMethod: 'x402'
    })
  }

  async processRequest(req: Request): Promise<any> {
    // Your application logic here
    return { data: 'sensor reading', value: 23.5 }
  }
}

// Start unified server
const server = new M2MPaymentServer({
  port: 8080,
  facilitatorUrl: 'https://facilitator.x402.org',
  network: 'base',
  asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
  payeeAddress: '0x...',
  maxUnsettled: '100000',
  settlementInterval: 1000
})
```

### Client Usage

```typescript
// Unified client supporting both protocols
class M2MPaymentClient {
  private x402: X402Client
  private microstream: MicroStreamClient

  async request(url: string, options: RequestOptions) {
    // Discover payment options
    const discovery = await fetch(url)
    if (discovery.status !== 402) {
      return discovery.json()
    }

    const paymentOptions = await discovery.json()

    // Choose protocol based on use case
    if (options.streaming || options.frequency > 10) {
      return this.streamingRequest(url, paymentOptions.protocols.microstream)
    } else {
      return this.singleRequest(url, paymentOptions.protocols.x402)
    }
  }

  async singleRequest(url: string, x402Challenge: any) {
    // Pay with x402
    const payment = await this.x402.createPayment(x402Challenge)

    const response = await fetch(url, {
      headers: {
        'X-PAYMENT': payment.header
      }
    })

    return response.json()
  }

  async streamingRequest(url: string, microstreamConfig: any) {
    // Connect with µStream
    await this.microstream.connect(microstreamConfig.endpoint)

    // Stream payments and data
    return new StreamingConnection(this.microstream)
  }
}

// Usage
const client = new M2MPaymentClient({
  x402: { /* config */ },
  microstream: { /* config */ }
})

// Single request
const data = await client.request('https://sensor.com/api/data', {
  streaming: false
})

// Streaming request
const stream = await client.request('https://sensor.com/api/stream', {
  streaming: true,
  frequency: 100 // 100 messages/sec
})

stream.on('data', (data) => console.log(data))
```

---

## Summary

### Integration Benefits

✅ **Flexibility** - Choose right protocol for each use case
✅ **Efficiency** - Optimize costs based on usage pattern
✅ **Compatibility** - x402 handles settlement for both protocols
✅ **Simplicity** - Single settlement infrastructure
✅ **Scalability** - µStream for high-frequency, x402 for occasional

### Best Practices

1. **Start with x402** for simple use cases
2. **Upgrade to µStream** when frequency > 10/sec
3. **Use x402 for settlement** in both protocols (shared infrastructure)
4. **Advertise both protocols** in HTTP 402 responses
5. **Let clients choose** based on their use case
6. **Monitor usage patterns** and recommend optimal protocol

### When to Use What

**Use x402 alone:** Single requests, occasional usage, HTTP-native tooling
**Use µStream alone:** Continuous streaming, bidirectional, high-frequency
**Use both together:** Production M2M platform serving diverse use cases

The combination provides a complete payment solution for the M2M ecosystem! 🚀

