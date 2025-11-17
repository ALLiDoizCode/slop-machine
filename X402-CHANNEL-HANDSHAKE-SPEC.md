# x402 Channel Handshake Specification
## Using HTTP 402 Payments to Establish Streaming Payment Channels

**Version:** 1.0.0-draft
**Date:** November 17, 2025

---

## Overview

This specification defines how **x402** (HTTP 402 payment protocol) is used for the **handshake phase** to establish payment channels, which are then used for **µStream** streaming micropayments.

### The Architecture

```
┌─────────────────────────────────────────────────────┐
│  Phase 1: HTTP 402 Handshake (x402)                │
│  - Client pays initial fee via x402                 │
│  - Server creates/opens payment channel             │
│  - Returns channel credentials to client            │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Phase 2: WebSocket Upgrade (µStream)               │
│  - Client upgrades to WebSocket with channel ID     │
│  - Begin streaming with signed state commitments    │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Phase 3: Streaming Payments (µStream)              │
│  - Each packet = signed state update                │
│  - Server can settle unilaterally anytime           │
└─────────────────────────────────────────────────────┘
```

### Why This Design?

**x402 for handshake:**
- ✅ Standard HTTP 402 semantics
- ✅ Pay-to-establish-channel model
- ✅ Works with existing HTTP tooling
- ✅ Clear cost for channel setup
- ✅ Prevents spam (costs money to open channel)

**µStream for streaming:**
- ✅ Low latency (WebSocket)
- ✅ Efficient (minimal overhead)
- ✅ Unilateral settlement (signed states)
- ✅ Bidirectional payments

---

## Phase 1: x402 Handshake Flow

### Step 1: Client Discovers Channel Requirements

**Client requests resource without payment:**

```http
GET /api/stream/sensor-data HTTP/1.1
Host: sensor.example.com
Accept: application/json
```

**Server responds with 402 and channel setup requirements:**

```http
HTTP/1.1 402 Payment Required
Content-Type: application/json
X-Protocol-Options: x402-channel-handshake

{
  "error": "Payment Required",
  "message": "Pay to establish streaming channel",

  "handshake": {
    "protocol": "x402",
    "version": "1.0",
    "scheme": "channel-setup",
    "description": "One-time payment to establish payment channel"
  },

  "channelSetup": {
    "type": "state-channel",
    "setupFee": "10000",           // Wei to establish channel
    "minChannelCapacity": "100000", // Minimum channel deposit
    "maxChannelCapacity": "10000000",
    "channelDuration": 86400,       // 24 hours
    "network": "base",
    "asset": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    "contractAddress": "0xChannelContract123...",

    "x402Requirements": {
      "scheme": "exact",
      "network": "base",
      "maxAmountRequired": "10000",
      "payTo": "0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d",
      "resource": "/api/stream/sensor-data/channel-setup",
      "validFor": 300
    }
  },

  "streamingDetails": {
    "protocol": "microstream",
    "version": "0.2",
    "rate": "100",
    "rateUnit": "wei/message",
    "settlementThreshold": "10000"
  }
}
```

### Step 2: Client Pays Setup Fee via x402

**Client creates x402 payment for channel setup:**

```javascript
// Client-side
const x402Payment = await createX402Payment({
  scheme: "exact",
  network: "base",
  amount: "10000", // Setup fee
  recipient: "0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d",
  asset: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",

  // Additional metadata for channel setup
  metadata: {
    purpose: "channel-setup",
    requestedCapacity: "1000000",  // Client wants 1M wei channel
    channelType: "bidirectional",
    clientAddress: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1"
  }
})

// Encode as x402 header
const xPaymentHeader = encodeX402Payment(x402Payment)
```

**Client sends request with X-PAYMENT header:**

```http
POST /api/stream/sensor-data/channel-setup HTTP/1.1
Host: sensor.example.com
Content-Type: application/json
X-PAYMENT: eyJ4NDAyVmVyc2lvbiI6IjEuMCIsInNjaGVtZSI6ImV4YWN0Ii...

{
  "channelCapacity": "1000000",
  "channelType": "bidirectional",
  "channelDuration": 86400,
  "clientAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
  "clientPublicKey": "0x04abcd..."
}
```

### Step 3: Server Verifies x402 Payment

**Server-side processing:**

```javascript
async function handleChannelSetup(req, res) {
  // 1. Verify x402 payment
  const xPayment = req.headers['x-payment']

  if (!xPayment) {
    return res.status(402).json({
      error: 'Payment required for channel setup'
    })
  }

  // Decode and verify x402 payment
  const payment = await x402Handler.verifyPayment(xPayment)

  if (!payment.valid) {
    return res.status(402).json({
      error: 'Invalid payment',
      details: payment.error
    })
  }

  // Verify payment amount covers setup fee
  if (BigInt(payment.amount) < BigInt(config.channelSetupFee)) {
    return res.status(402).json({
      error: 'Insufficient setup fee'
    })
  }

  // 2. Setup payment channel on-chain
  const channelParams = req.body
  const channel = await createPaymentChannel({
    client: channelParams.clientAddress,
    server: config.serverAddress,
    capacity: channelParams.channelCapacity,
    duration: channelParams.channelDuration,
    bidirectional: channelParams.channelType === 'bidirectional'
  })

  // 3. Return channel credentials
  return res.status(200).json({
    success: true,
    setupPayment: {
      txHash: payment.txHash,
      amount: payment.amount,
      verified: true
    },
    channel: {
      channelId: channel.id,
      contractAddress: channel.contractAddress,
      clientAddress: channel.client,
      serverAddress: channel.server,
      capacity: channel.capacity,
      expiresAt: channel.expiresAt,

      // WebSocket endpoint for streaming
      streamEndpoint: `wss://sensor.example.com/stream/${channel.id}`,

      // Authentication token for WebSocket upgrade
      streamToken: generateStreamToken(channel.id, channel.client),
      streamTokenExpiresIn: 300
    },
    protocol: {
      version: "microstream/0.2",
      settlementType: "state-channel",
      rate: "100 wei/message"
    }
  })
}
```

### Step 4: Server Creates Payment Channel On-Chain

**Smart contract interaction:**

```javascript
async function createPaymentChannel(params) {
  const { client, server, capacity, duration, bidirectional } = params

  // Deploy or use existing channel factory contract
  const channelFactory = await ethers.getContractAt(
    'MicroStreamChannelFactory',
    config.channelFactoryAddress
  )

  // Create channel (server pays gas for convenience)
  const tx = await channelFactory.createChannel(
    client,
    server,
    capacity,
    duration,
    bidirectional,
    {
      value: 0 // Client will deposit separately or server fronts it
    }
  )

  const receipt = await tx.wait()

  // Extract channel ID from event
  const event = receipt.events.find(e => e.event === 'ChannelCreated')
  const channelId = event.args.channelId

  return {
    id: channelId,
    contractAddress: config.channelFactoryAddress,
    client: client,
    server: server,
    capacity: capacity,
    expiresAt: Date.now() + (duration * 1000),
    txHash: receipt.transactionHash
  }
}
```

### Step 5: Client Receives Channel Credentials

**Client receives response:**

```json
{
  "success": true,
  "setupPayment": {
    "txHash": "0xabc123...",
    "amount": "10000",
    "verified": true
  },
  "channel": {
    "channelId": "0xch_abc123...def456",
    "contractAddress": "0xChannelContract123...",
    "clientAddress": "0x742d35Cc...",
    "serverAddress": "0x8a791d3a...",
    "capacity": "1000000",
    "expiresAt": "2025-11-18T12:00:00Z",

    "streamEndpoint": "wss://sensor.example.com/stream/0xch_abc123...def456",
    "streamToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "streamTokenExpiresIn": 300
  },
  "protocol": {
    "version": "microstream/0.2",
    "settlementType": "state-channel",
    "rate": "100 wei/message"
  }
}
```

---

## Phase 2: Client Deposits to Channel

### Option A: Client Deposits Immediately

```javascript
// Client deposits to channel contract
const channelContract = await ethers.getContractAt(
  'MicroStreamChannel',
  channelInfo.contractAddress
)

const depositTx = await channelContract.deposit(
  channelInfo.channelId,
  { value: channelInfo.capacity } // 1M wei
)

await depositTx.wait()
```

### Option B: Server Fronts Deposit (Credit Model)

```javascript
// Server deposits on behalf of client (client pays back via streaming)
const depositTx = await channelContract.depositFor(
  channelInfo.channelId,
  channelInfo.clientAddress,
  { value: channelInfo.capacity }
)

// Client owes server the deposit + interest
// Will pay back gradually via µStream packets
```

---

## Phase 3: WebSocket Upgrade with Channel Credentials

### Client Upgrades to WebSocket

```javascript
// Connect to WebSocket with channel credentials
const ws = new WebSocket(channelInfo.streamEndpoint, {
  headers: {
    'Authorization': `Bearer ${channelInfo.streamToken}`
  }
})

// Wait for connection
await new Promise((resolve) => ws.once('open', resolve))

// Send µStream CONNECT with channel info
ws.send(JSON.stringify({
  type: 'CONNECT',
  version: '0.2',
  channel: {
    channelId: channelInfo.channelId,
    channelType: 'state-channel',
    contractAddress: channelInfo.contractAddress,
    capacity: channelInfo.capacity,
    clientAddress: myAddress
  },
  limits: {
    sendMax: channelInfo.capacity,
    receiveMax: '500000' // Willing to receive up to 500k wei back
  }
}))
```

### Server Validates Channel and Establishes µStream Session

```javascript
async function handleWebSocketUpgrade(ws, request) {
  // 1. Validate bearer token
  const token = extractBearerToken(request)
  const session = await verifyStreamToken(token)

  if (!session) {
    ws.close(4001, 'Invalid or expired stream token')
    return
  }

  // 2. Verify channel exists on-chain
  const channel = await channelContract.getChannel(session.channelId)

  if (!channel.isOpen) {
    ws.close(4002, 'Channel not open')
    return
  }

  if (channel.client !== session.clientAddress) {
    ws.close(4003, 'Channel client mismatch')
    return
  }

  // 3. Verify channel has sufficient balance
  const balance = await channelContract.getBalance(session.channelId)

  if (balance < config.minimumChannelBalance) {
    ws.close(4004, 'Insufficient channel balance')
    return
  }

  // 4. Establish µStream session
  const microStreamSession = {
    channelId: session.channelId,
    channelType: 'state-channel',
    contractAddress: channel.contractAddress,
    clientAddress: channel.client,
    serverAddress: channel.server,
    capacity: channel.capacity,
    stateNumber: 0,
    totalClaimable: 0n,
    latestState: null
  }

  sessions.set(session.channelId, microStreamSession)

  // 5. Send CONNECTED acknowledgment
  ws.send(JSON.stringify({
    type: 'CONNECTED',
    sessionId: session.channelId,
    channel: {
      verified: true,
      balance: balance.toString(),
      expiresAt: channel.expiresAt
    },
    limits: {
      sendMax: balance.toString(),
      receiveMax: channel.serverCapacity.toString()
    }
  }))

  // 6. Setup µStream packet handlers
  ws.on('message', (data) => handleMicroStreamPacket(microStreamSession, data))
}
```

---

## Phase 4: µStream Streaming with State Commitments

### Client Sends Payment Packets

```javascript
let stateNumber = 0
let totalPaid = 0

async function sendPayment(amount, data) {
  stateNumber++
  totalPaid += amount

  // Sign state commitment
  const stateCommitment = {
    channelId: channelId,
    stateNumber: stateNumber,
    totalClaimable: totalPaid,
    recipient: serverAddress,
    nonce: generateNonce(),
    timestamp: Date.now()
  }

  const signature = await signStateCommitment(stateCommitment)

  // Send µStream PAYMENT packet
  ws.send(JSON.stringify({
    type: 'PAYMENT',
    seq: stateNumber,
    timestamp: Date.now(),
    payment: {
      channelId: channelId,
      channelType: 'state-channel',
      stateNumber: stateNumber,
      totalClaimable: totalPaid.toString(),
      stateSignature: signature,

      // For bidirectional channels
      counterpartyClaimable: serverTotalOwed.toString(),
      counterpartySignature: lastServerSignature
    },
    data: data
  }))
}

// Stream payments
for (let i = 0; i < 1000; i++) {
  await sendPayment(100, { request: 'temperature' })
  await sleep(100) // 100ms between messages
}
```

### Server Processes and Can Settle Anytime

```javascript
async function handleMicroStreamPacket(session, rawData) {
  const packet = JSON.parse(rawData)

  if (packet.type === 'PAYMENT') {
    const { stateNumber, totalClaimable, stateSignature } = packet.payment

    // Verify state signature
    const isValid = await verifyStateSignature(
      session.channelId,
      stateNumber,
      totalClaimable,
      stateSignature,
      session.clientAddress
    )

    if (!isValid) {
      ws.close(4010, 'Invalid state signature')
      return
    }

    // Store latest state (server can settle anytime!)
    session.stateNumber = stateNumber
    session.totalClaimable = BigInt(totalClaimable)
    session.latestState = {
      stateNumber,
      totalClaimable,
      signature: stateSignature,
      receivedAt: Date.now()
    }

    // Process application request
    const response = await processRequest(packet.data)

    // Send response (optionally with counter-payment)
    ws.send(JSON.stringify({
      type: 'PAYMENT',
      seq: stateNumber,
      timestamp: Date.now(),
      payment: {
        channelId: session.channelId,
        counterpartyClaimable: '50', // Server pays 50 back
        counterpartySignature: await signCounterState(...)
      },
      data: response
    }))

    // Decide whether to settle
    if (shouldSettleChannel(session)) {
      await settleChannel(session)
    }
  }
}

function shouldSettleChannel(session) {
  return (
    session.totalClaimable >= settlementThreshold ||
    Date.now() - session.lastSettlement > 3600000 ||
    session.closing
  )
}

async function settleChannel(session) {
  // Submit latest state to contract (unilateral settlement)
  const tx = await channelContract.settle(
    session.channelId,
    {
      stateNumber: session.stateNumber,
      totalClaimable: session.totalClaimable.toString(),
      recipient: session.serverAddress,
      timestamp: Date.now()
    },
    session.latestState.signature
  )

  await tx.wait()

  session.lastSettlement = Date.now()
  session.settledAmount = session.totalClaimable
}
```

---

## Complete Smart Contract Suite

### MicroStreamChannelFactory

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MicroStreamChannelFactory {
    struct Channel {
        bytes32 id;
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

    mapping(bytes32 => Channel) public channels;

    event ChannelCreated(
        bytes32 indexed channelId,
        address indexed client,
        address indexed server,
        uint256 capacity,
        uint256 expiresAt
    );

    event ChannelDeposit(
        bytes32 indexed channelId,
        address indexed depositor,
        uint256 amount
    );

    event ChannelSettled(
        bytes32 indexed channelId,
        address indexed recipient,
        uint256 amount,
        uint256 stateNumber
    );

    event ChannelClosed(
        bytes32 indexed channelId,
        uint256 clientRefund,
        uint256 serverRefund
    );

    /**
     * Create a new payment channel
     * Server typically calls this after receiving x402 setup payment
     */
    function createChannel(
        address client,
        address server,
        uint256 capacity,
        uint256 duration,
        bool bidirectional
    ) external returns (bytes32) {
        bytes32 channelId = keccak256(
            abi.encodePacked(client, server, block.timestamp, block.number)
        );

        channels[channelId] = Channel({
            id: channelId,
            client: client,
            server: server,
            capacity: capacity,
            clientBalance: 0,
            serverBalance: 0,
            lastStateNumber: 0,
            expiresAt: block.timestamp + duration,
            isOpen: true,
            isBidirectional: bidirectional
        });

        emit ChannelCreated(channelId, client, server, capacity, block.timestamp + duration);

        return channelId;
    }

    /**
     * Client or server deposits to channel
     */
    function deposit(bytes32 channelId) external payable {
        Channel storage channel = channels[channelId];
        require(channel.isOpen, "Channel not open");
        require(msg.value > 0, "No deposit");

        if (msg.sender == channel.client) {
            channel.clientBalance += msg.value;
        } else if (msg.sender == channel.server) {
            channel.serverBalance += msg.value;
        } else {
            revert("Not channel participant");
        }

        emit ChannelDeposit(channelId, msg.sender, msg.value);
    }

    /**
     * Settle channel with signed state commitment
     * Either party can call this with valid signature from counterparty
     */
    function settle(
        bytes32 channelId,
        uint256 stateNumber,
        uint256 claimAmount,
        address recipient,
        uint256 timestamp,
        bytes memory signature
    ) external {
        Channel storage channel = channels[channelId];
        require(channel.isOpen, "Channel not open");
        require(recipient == msg.sender, "Not recipient");

        // Verify state number is newer
        require(stateNumber > channel.lastStateNumber, "Stale state");

        // Recover signer from signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(channelId, stateNumber, claimAmount, recipient, timestamp)
        );
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        address signer = recoverSigner(ethSignedHash, signature);

        // Verify signature is from counterparty
        if (recipient == channel.server) {
            require(signer == channel.client, "Invalid client signature");
            require(claimAmount <= channel.clientBalance, "Insufficient balance");
            channel.clientBalance -= claimAmount;
        } else if (recipient == channel.client) {
            require(channel.isBidirectional, "Not bidirectional");
            require(signer == channel.server, "Invalid server signature");
            require(claimAmount <= channel.serverBalance, "Insufficient balance");
            channel.serverBalance -= claimAmount;
        } else {
            revert("Invalid recipient");
        }

        channel.lastStateNumber = stateNumber;

        // Transfer funds
        payable(recipient).transfer(claimAmount);

        emit ChannelSettled(channelId, recipient, claimAmount, stateNumber);
    }

    /**
     * Close channel and refund remaining balances
     * Can be called by either party after expiry or by mutual agreement
     */
    function closeChannel(bytes32 channelId) external {
        Channel storage channel = channels[channelId];
        require(channel.isOpen, "Channel already closed");

        // Require expiry or caller is participant
        bool isExpired = block.timestamp >= channel.expiresAt;
        bool isParticipant = msg.sender == channel.client || msg.sender == channel.server;

        require(isExpired || isParticipant, "Cannot close yet");

        uint256 clientRefund = channel.clientBalance;
        uint256 serverRefund = channel.serverBalance;

        channel.clientBalance = 0;
        channel.serverBalance = 0;
        channel.isOpen = false;

        // Refund remaining balances
        if (clientRefund > 0) {
            payable(channel.client).transfer(clientRefund);
        }
        if (serverRefund > 0) {
            payable(channel.server).transfer(serverRefund);
        }

        emit ChannelClosed(channelId, clientRefund, serverRefund);
    }

    /**
     * Get channel balance
     */
    function getBalance(bytes32 channelId) external view returns (uint256, uint256) {
        Channel storage channel = channels[channelId];
        return (channel.clientBalance, channel.serverBalance);
    }

    /**
     * Recover signer from signature
     */
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature v");

        return ecrecover(hash, v, r, s);
    }
}
```

---

## Protocol Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     HTTP 402 HANDSHAKE                      │
└─────────────────────────────────────────────────────────────┘

Client                          Server                     Blockchain
  │                               │                             │
  │  GET /api/stream              │                             │
  │─────────────────────────────>│                             │
  │                               │                             │
  │  402 Payment Required         │                             │
  │  (channel setup requirements) │                             │
  │<─────────────────────────────│                             │
  │                               │                             │
  │  POST /channel-setup          │                             │
  │  (X-PAYMENT: x402 header)     │                             │
  │─────────────────────────────>│                             │
  │                               │                             │
  │                               │  createChannel()            │
  │                               │────────────────────────────>│
  │                               │                             │
  │                               │  ChannelCreated event       │
  │                               │<────────────────────────────│
  │                               │                             │
  │  200 OK                       │                             │
  │  (channel credentials)        │                             │
  │<─────────────────────────────│                             │
  │                               │                             │
  │  deposit(channelId)           │                             │
  │──────────────────────────────────────────────────────────>│
  │                               │                             │
  │                               │                             │

┌─────────────────────────────────────────────────────────────┐
│                  WEBSOCKET STREAMING                        │
└─────────────────────────────────────────────────────────────┘

  │  WebSocket Upgrade            │                             │
  │  (Bearer token)               │                             │
  │─────────────────────────────>│                             │
  │                               │                             │
  │  CONNECTED                    │                             │
  │<─────────────────────────────│                             │
  │                               │                             │
  │  PAYMENT (signed state 1)     │                             │
  │─────────────────────────────>│                             │
  │                               │                             │
  │  PAYMENT (response + state)   │                             │
  │<─────────────────────────────│                             │
  │                               │                             │
  │  PAYMENT (signed state 2)     │                             │
  │─────────────────────────────>│                             │
  │                               │                             │
  │         ... streaming ...     │                             │
  │                               │                             │
  │  PAYMENT (signed state N)     │                             │
  │─────────────────────────────>│                             │
  │                               │                             │
  │                               │  settle(channelId, stateN)  │
  │                               │────────────────────────────>│
  │                               │                             │
  │                               │  Transfer funds to server   │
  │                               │<────────────────────────────│
  │                               │                             │
  │  CONTROL/SETTLED              │                             │
  │<─────────────────────────────│                             │
  │                               │                             │
  │         ... continue ...      │                             │
```

---

## Cost Analysis

### Traditional Approach (Every Message On-Chain)

```
1000 messages × $0.001 gas = $1.00
```

### x402 + µStream Approach

```
Setup:
  - x402 handshake: $0.001 (one-time)
  - Channel creation: $0.002 (one-time)
  - Channel deposit: $0.001 (one-time)
  Total setup: $0.004

Streaming:
  - 1000 µStream messages: $0.000 (off-chain)

Settlement:
  - Final settlement: $0.001 (one-time)

Total: $0.005 (99.5% savings!)
```

---

## Security Considerations

### x402 Handshake Security

1. **Setup Fee Prevents Spam**
   - Cost to establish channel deters DoS
   - Server can require higher fees for suspicious clients

2. **Payment Verification**
   - x402 payment verified before channel creation
   - Channel only created after confirmed payment

3. **Channel Credentials**
   - Stream token expires quickly (5 minutes)
   - Must upgrade to WebSocket before expiry
   - Token tied to specific channel ID

### µStream Streaming Security

1. **Signed State Commitments**
   - Every packet cryptographically signed
   - Server verifies signature before accepting
   - Prevents unauthorized state updates

2. **Monotonic State Numbers**
   - State numbers must increase
   - Prevents replay of old states
   - Contract enforces monotonicity

3. **Unilateral Settlement**
   - Server can settle anytime without client cooperation
   - Eliminates griefing vectors
   - Client can't withhold settlement

4. **Channel Expiry**
   - Channels have expiration timestamps
   - Prevents indefinite capital lockup
   - Either party can close after expiry

---

## Implementation Guide

### Server Setup

```javascript
import express from 'express'
import { WebSocketServer } from 'ws'
import { ethers } from 'ethers'

class X402ChannelServer {
  constructor(config) {
    this.x402Handler = new X402Handler(config.x402)
    this.channelFactory = new ethers.Contract(
      config.channelFactoryAddress,
      ChannelFactoryABI,
      config.wallet
    )
    this.sessions = new Map()
  }

  // Setup Express routes
  setupRoutes(app) {
    // Discovery endpoint
    app.get('/api/stream/:resource', this.handleDiscovery.bind(this))

    // Channel setup endpoint
    app.post('/api/stream/:resource/channel-setup', this.handleChannelSetup.bind(this))
  }

  async handleDiscovery(req, res) {
    res.status(402).json({
      error: 'Payment Required',
      handshake: { /* x402 requirements */ },
      channelSetup: { /* channel parameters */ },
      streamingDetails: { /* µStream details */ }
    })
  }

  async handleChannelSetup(req, res) {
    // Verify x402 payment
    const payment = await this.x402Handler.verifyPayment(
      req.headers['x-payment']
    )

    if (!payment.valid) {
      return res.status(402).json({ error: 'Invalid payment' })
    }

    // Create channel on-chain
    const channel = await this.createChannel(req.body)

    // Return credentials
    res.status(200).json({
      success: true,
      channel: {
        channelId: channel.id,
        streamEndpoint: `wss://${req.hostname}/stream/${channel.id}`,
        streamToken: this.generateStreamToken(channel.id),
        // ... other details
      }
    })
  }

  // Setup WebSocket server
  setupWebSocket(wss) {
    wss.on('connection', this.handleWebSocketConnection.bind(this))
  }

  async handleWebSocketConnection(ws, request) {
    // Validate token, verify channel, establish µStream session
    // ... (as shown in previous sections)
  }
}

// Usage
const server = new X402ChannelServer({
  x402: { /* config */ },
  channelFactoryAddress: '0x...',
  wallet: ethersWallet
})

const app = express()
server.setupRoutes(app)

const wss = new WebSocketServer({ server: app })
server.setupWebSocket(wss)

app.listen(8080)
```

### Client Setup

```javascript
class X402ChannelClient {
  async establishChannel(resourceUrl) {
    // 1. Discovery
    const discovery = await fetch(resourceUrl)
    const requirements = await discovery.json()

    // 2. Pay setup fee via x402
    const payment = await this.createX402Payment(
      requirements.channelSetup.x402Requirements
    )

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
          channelType: 'bidirectional',
          clientAddress: this.wallet.address
        })
      }
    )

    const channelInfo = await setupResponse.json()

    // 3. Deposit to channel
    await this.depositToChannel(channelInfo.channel)

    // 4. Connect to WebSocket
    return await this.connectToStream(channelInfo.channel)
  }

  async connectToStream(channelInfo) {
    const ws = new WebSocket(channelInfo.streamEndpoint, {
      headers: {
        'Authorization': `Bearer ${channelInfo.streamToken}`
      }
    })

    // Initialize µStream client
    const streamClient = new MicroStreamClient(ws, {
      channelId: channelInfo.channelId,
      wallet: this.wallet
    })

    return streamClient
  }
}
```

---

## Summary

### The Complete Flow

1. **HTTP 402 Discovery** - Client discovers channel requirements
2. **x402 Payment** - Client pays setup fee via x402
3. **Channel Creation** - Server creates channel on-chain
4. **Channel Deposit** - Client deposits to channel
5. **WebSocket Upgrade** - Client upgrades to µStream
6. **Streaming Payments** - Signed state commitments per packet
7. **Unilateral Settlement** - Server settles when ready

### Benefits

✅ **Standard HTTP 402** - Uses existing HTTP semantics
✅ **Payment Required** - Prevents spam with setup fee
✅ **Unilateral Settlement** - Server controls settlement timing
✅ **Efficient Streaming** - Off-chain until settlement
✅ **Bidirectional** - Optional two-way payment flows
✅ **Secure** - Cryptographic signatures, on-chain verification
✅ **Cost Effective** - 99%+ gas savings vs per-message on-chain

This is the **optimal architecture** for M2M streaming micropayments! 🎯

