# µStream Payment Channel Integration
## Unilateral Settlement with Signed State Commitments

**Version:** 0.2.0-draft
**Date:** November 17, 2025

---

## The Key Insight

You're absolutely right! With payment channels (Lightning, Raiden, state channels), each µStream packet should contain a **signed state commitment** that the payee can unilaterally settle on-chain **whenever they want**, without asking the payer for permission.

### The Problem with the Original Design

**Original µStream (WRONG):**
```
1. Client streams payments (accumulates balance)
2. Server asks: "Please settle now"
3. Client decides when to settle
4. Server waits for client cooperation
```

❌ **Problem:** Server depends on client cooperation for settlement!

### The Payment Channel Solution (RIGHT)

**µStream with Payment Channels:**
```
1. Client opens payment channel (escrows funds)
2. Each µStream packet = signed state update
3. Server can claim funds anytime (unilateral settlement)
4. No client cooperation needed after signature
```

✅ **Benefit:** Payee has **unilateral settlement rights** immediately upon receiving signed packet!

---

## Architecture: Payment Channel-Native µStream

### Three-Phase Model

```
┌─────────────────────────────────────────────────────┐
│  Phase 1: Channel Establishment                     │
│                                                     │
│  Client → Blockchain: Open payment channel          │
│  - Escrow 1,000,000 wei in channel contract        │
│  - Set recipient = Server address                  │
│  - Set timeout = 1 week                            │
│                                                     │
│  Result: Channel ID = 0xabc123...                  │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Phase 2: µStream Packets = State Updates          │
│                                                     │
│  Packet 1: Client signs "Server can claim 100"     │
│  Packet 2: Client signs "Server can claim 200"     │
│  Packet 3: Client signs "Server can claim 300"     │
│  ...                                                │
│  Packet N: Client signs "Server can claim 100,000" │
│                                                     │
│  Each signature = unilateral claim right            │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│  Phase 3: Settlement (Server decides when)         │
│                                                     │
│  Server → Blockchain: Claim funds                   │
│  - Submit latest signed state (100,000 wei)        │
│  - Contract verifies signature                     │
│  - Contract transfers 100,000 to server            │
│  - Remaining 900,000 returns to client             │
│                                                     │
│  NO CLIENT COOPERATION NEEDED!                      │
└─────────────────────────────────────────────────────┘
```

---

## Revised Packet Format: Signed State Commitments

### µStream PAYMENT Packet with Channel State

```typescript
interface ChannelPaymentPacket extends BasePacket {
  type: 'PAYMENT'
  payment: {
    // Channel information
    channelId: string              // Payment channel ID
    channelType: 'lightning' | 'raiden' | 'state-channel' | 'htlc'

    // State commitment
    stateNumber: number            // Monotonically increasing
    totalClaimable: string         // Total amount recipient can claim

    // Signature proving client authorizes this state
    stateSignature: string         // Signs: (channelId, stateNumber, totalClaimable, recipient)

    // Lightning-specific (if applicable)
    paymentHash?: string           // For HTLC channels
    preimage?: string              // Revealed when settling

    // Optional: bidirectional state
    counterpartyClaimable?: string // Amount client can claim back
    counterpartySignature?: string // Server's signature (if bidirectional)
  }
  data?: any                        // Application data
}
```

### Example: Streaming with Lightning Channel

```json
// Packet 1
{
  "type": "PAYMENT",
  "seq": 1,
  "timestamp": 1700234567890,
  "payment": {
    "channelId": "0xabc123...def456",
    "channelType": "lightning",
    "stateNumber": 1,
    "totalClaimable": "100",
    "stateSignature": "0x1234abcd...",
    "paymentHash": "abc123..."
  },
  "data": { "request": "temperature" }
}

// Packet 2 (supersedes Packet 1)
{
  "type": "PAYMENT",
  "seq": 2,
  "timestamp": 1700234568000,
  "payment": {
    "channelId": "0xabc123...def456",
    "channelType": "lightning",
    "stateNumber": 2,
    "totalClaimable": "200",       // ← Now 200 total
    "stateSignature": "0x5678efgh...",
    "paymentHash": "abc123..."
  },
  "data": { "request": "temperature" }
}

// Packet 100
{
  "type": "PAYMENT",
  "seq": 100,
  "timestamp": 1700234600000,
  "payment": {
    "channelId": "0xabc123...def456",
    "channelType": "lightning",
    "stateNumber": 100,
    "totalClaimable": "10000",     // ← Server can claim 10k anytime!
    "stateSignature": "0x9012ijkl..."
  },
  "data": { "request": "temperature" }
}
```

**Key Property:** Each packet **replaces** the previous state. The latest signature is the only one that matters.

---

## Signature Format: State Commitments

### What Gets Signed

```javascript
const stateCommitment = {
  channelId: "0xabc123...def456",
  stateNumber: 100,
  totalClaimable: "10000",
  recipient: "0x8a791d3aC3aF9cb52b2dC0f9E016E7aF1B5E4c1d",
  nonce: "unique-nonce-per-state",
  timestamp: 1700234600000
}

// EIP-712 typed data signature
const domain = {
  name: "MicroStream Payment Channel",
  version: "1",
  chainId: 8453, // Base
  verifyingContract: channelContractAddress
}

const types = {
  StateCommitment: [
    { name: "channelId", type: "bytes32" },
    { name: "stateNumber", type: "uint256" },
    { name: "totalClaimable", type: "uint256" },
    { name: "recipient", type: "address" },
    { name: "nonce", type: "bytes32" },
    { name: "timestamp", type: "uint256" }
  ]
}

const signature = await signer._signTypedData(domain, types, stateCommitment)
```

### On-Chain Verification

```solidity
// Payment channel contract
contract MicroStreamChannel {
  struct State {
    uint256 stateNumber;
    uint256 totalClaimable;
    address recipient;
    bytes32 nonce;
    uint256 timestamp;
  }

  function settle(
    bytes32 channelId,
    State memory finalState,
    bytes memory signature
  ) external {
    Channel storage channel = channels[channelId];

    require(channel.isOpen, "Channel closed");
    require(finalState.recipient == msg.sender, "Not recipient");

    // Verify signature
    address signer = recoverSigner(finalState, signature);
    require(signer == channel.payer, "Invalid signature");

    // Verify state number is valid (prevents replay of old states)
    require(
      finalState.stateNumber > channel.lastSettledState,
      "Stale state"
    );

    // Transfer funds
    require(finalState.totalClaimable <= channel.balance, "Insufficient balance");

    channel.balance -= finalState.totalClaimable;
    channel.lastSettledState = finalState.stateNumber;

    payable(finalState.recipient).transfer(finalState.totalClaimable);

    emit ChannelSettled(channelId, finalState.totalClaimable);
  }

  function closeChannel(bytes32 channelId) external {
    Channel storage channel = channels[channelId];
    require(channel.payer == msg.sender, "Not payer");

    // Return remaining balance to payer
    uint256 remaining = channel.balance;
    channel.balance = 0;
    channel.isOpen = false;

    payable(channel.payer).transfer(remaining);
  }
}
```

---

## Bidirectional Channels

### Dual State Commitments

In a bidirectional channel, **both parties** sign state updates:

```typescript
interface BidirectionalChannelPacket extends BasePacket {
  type: 'PAYMENT'
  payment: {
    channelId: string
    channelType: 'bidirectional'
    stateNumber: number

    // Client → Server balance
    serverClaimable: string
    clientSignature: string        // Client signs server's claim

    // Server → Client balance
    clientClaimable: string
    serverSignature: string        // Server signs client's claim

    // Net balance (for efficiency)
    netOwed: string                // Positive = client owes, negative = server owes
  }
  data?: any
}
```

### Example: Bidirectional State Update

```json
// Client pays server 100, server pays client 30
{
  "type": "PAYMENT",
  "seq": 1,
  "payment": {
    "channelId": "0xabc123",
    "channelType": "bidirectional",
    "stateNumber": 1,

    "serverClaimable": "100",
    "clientSignature": "0x1234...",  // Client signs: "Server can claim 100"

    "clientClaimable": "30",
    "serverSignature": "0x5678...",  // Server signs: "Client can claim 30"

    "netOwed": "70"                  // Net: client owes 70
  },
  "data": { "temperature": 23.5 }
}

// Next state: client pays 100 more, server pays 50 more
{
  "type": "PAYMENT",
  "seq": 2,
  "payment": {
    "channelId": "0xabc123",
    "channelType": "bidirectional",
    "stateNumber": 2,

    "serverClaimable": "200",         // ← Cumulative: 100 + 100
    "clientSignature": "0xabcd...",

    "clientClaimable": "80",          // ← Cumulative: 30 + 50
    "serverSignature": "0xefgh...",

    "netOwed": "120"                  // Net: client owes 120
  },
  "data": { "temperature": 24.1 }
}
```

**Settlement:** Either party can settle their claim anytime!

---

## Lightning Network Integration

### Lightning-Specific Implementation

Lightning uses **HTLCs (Hash Time-Locked Contracts)** for conditional payments.

#### Phase 1: Channel Setup

```
Client → Lightning Network: Open channel
- Capacity: 1,000,000 sats
- Peer: Server's Lightning node
- Channel ID: 12345678:1:0
```

#### Phase 2: µStream with Lightning HTLCs

```javascript
// Each µStream packet includes Lightning payment details
{
  "type": "PAYMENT",
  "seq": 1,
  "payment": {
    "channelId": "12345678:1:0",
    "channelType": "lightning",
    "stateNumber": 1,
    "totalClaimable": "100",  // sats

    // Lightning HTLC details
    "paymentHash": "abc123...",     // SHA-256 hash of preimage
    "htlcExpiry": 1700234600,       // HTLC timeout

    // State signature (Lightning-style)
    "stateSignature": "0x...",

    // Preimage revealed when server provides service
    "preimage": null  // Server reveals after delivering data
  }
}
```

#### Phase 3: Server Settles HTLCs

```javascript
// Server can settle individual HTLCs or batch them
async function settleLightningHTLCs(htlcs) {
  for (const htlc of htlcs) {
    // Reveal preimage to claim payment
    await lightningNode.revealPreimage(htlc.paymentHash, htlc.preimage)

    // Lightning network automatically updates channel balance
    // No on-chain transaction needed (off-chain settlement)
  }
}
```

**Key Benefit:** Lightning settlement is **instant and off-chain** until channel closes!

---

## State Channel Integration (Raiden, Perun, Nitro)

### Ethereum State Channel Example

```solidity
// State channel contract
contract MicroStreamStateChannel {
  struct ChannelState {
    uint256 nonce;
    uint256 serverBalance;
    uint256 clientBalance;
  }

  struct Channel {
    address client;
    address server;
    uint256 totalDeposit;
    ChannelState latestState;
    bool isOpen;
  }

  mapping(bytes32 => Channel) public channels;

  // Client opens channel with deposit
  function openChannel(address server) external payable returns (bytes32) {
    bytes32 channelId = keccak256(abi.encodePacked(msg.sender, server, block.number));

    channels[channelId] = Channel({
      client: msg.sender,
      server: server,
      totalDeposit: msg.value,
      latestState: ChannelState({
        nonce: 0,
        serverBalance: 0,
        clientBalance: msg.value
      }),
      isOpen: true
    });

    return channelId;
  }

  // Server settles with latest signed state
  function settle(
    bytes32 channelId,
    ChannelState memory newState,
    bytes memory clientSig,
    bytes memory serverSig
  ) external {
    Channel storage channel = channels[channelId];
    require(channel.isOpen, "Channel closed");
    require(msg.sender == channel.server, "Only server");

    // Verify signatures
    require(verifyState(channelId, newState, clientSig, channel.client), "Invalid client sig");
    require(verifyState(channelId, newState, serverSig, channel.server), "Invalid server sig");

    // Verify nonce (prevent replay)
    require(newState.nonce > channel.latestState.nonce, "Stale state");

    // Update state
    channel.latestState = newState;

    // Transfer balances
    uint256 serverPayout = newState.serverBalance;
    uint256 clientRefund = newState.clientBalance;

    channel.isOpen = false;

    payable(channel.server).transfer(serverPayout);
    payable(channel.client).transfer(clientRefund);
  }

  function verifyState(
    bytes32 channelId,
    ChannelState memory state,
    bytes memory sig,
    address expectedSigner
  ) internal pure returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(channelId, state.nonce, state.serverBalance, state.clientBalance));
    bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    return recoverSigner(ethSignedHash, sig) == expectedSigner;
  }
}
```

### µStream Packets with State Channel

```json
{
  "type": "PAYMENT",
  "seq": 1,
  "payment": {
    "channelId": "0xabc123",
    "channelType": "state-channel",
    "stateNumber": 1,

    // State commitment
    "serverBalance": "100",     // Server can claim 100
    "clientBalance": "999900",  // Client keeps 999,900

    // Both parties sign the state
    "clientSignature": "0x1234...",
    "serverSignature": "0x5678..."
  },
  "data": { "request": "data" }
}
```

**Server settles whenever they want** by calling `settle()` on-chain with the latest signed state.

---

## Unilateral Settlement: No Permission Needed

### The Key Property

```
❌ OLD MODEL (request-based):
   Server: "Please settle now"
   Client: "OK, here's the settlement" (or ignores request)

✅ NEW MODEL (unilateral):
   Client: Signs state commitment in every packet
   Server: Can claim funds anytime without asking
```

### Settlement Decision Flow

```javascript
class MicroStreamServerWithChannels {
  constructor(config) {
    this.sessions = new Map()
    this.settlementThreshold = config.settlementThreshold || 100000
  }

  async handlePaymentPacket(session, packet) {
    const { channelId, stateNumber, totalClaimable, stateSignature } = packet.payment

    // Verify signature immediately
    const isValid = await this.verifyStateSignature(
      channelId,
      stateNumber,
      totalClaimable,
      stateSignature,
      session.clientAddress
    )

    if (!isValid) {
      throw new Error('Invalid state signature')
    }

    // Store latest state (server can settle this anytime)
    session.latestState = {
      stateNumber,
      totalClaimable,
      signature: stateSignature,
      receivedAt: Date.now()
    }

    // Process application data
    const response = await this.processRequest(packet.data)

    // Decide whether to settle now
    if (this.shouldSettle(session)) {
      // Server unilaterally settles (no client permission needed!)
      await this.settleChannel(session)
    }

    return response
  }

  shouldSettle(session) {
    const { totalClaimable } = session.latestState

    // Settlement conditions (server decides!)
    return (
      // Threshold reached
      BigInt(totalClaimable) >= this.settlementThreshold ||

      // Periodic settlement (every hour)
      Date.now() - session.lastSettlement > 3600000 ||

      // Connection closing
      session.closing ||

      // Risk management (client seems unreliable)
      this.isHighRisk(session)
    )
  }

  async settleChannel(session) {
    const { channelId, stateNumber, totalClaimable, signature } = session.latestState

    // Submit to blockchain
    const tx = await this.channelContract.settle(
      channelId,
      {
        stateNumber,
        totalClaimable,
        recipient: this.serverAddress,
        nonce: session.nonce,
        timestamp: Date.now()
      },
      signature
    )

    await tx.wait()

    console.log(`Settled ${totalClaimable} from channel ${channelId}`)

    session.lastSettlement = Date.now()
    session.settledAmount = BigInt(session.settledAmount) + BigInt(totalClaimable)
  }
}
```

---

## Complete Example: Lightning-Based µStream

### Client Implementation

```javascript
import { LightningClient } from '@lightning/client'
import { createHash } from 'crypto'

class MicroStreamLightningClient {
  constructor(config) {
    this.lightning = new LightningClient(config.lightningNode)
    this.channelId = null
    this.stateNumber = 0
    this.totalPaid = 0
  }

  async connect(serverNode, capacity) {
    // Open Lightning channel
    const channel = await this.lightning.openChannel({
      node: serverNode,
      capacity: capacity  // e.g., 1,000,000 sats
    })

    this.channelId = channel.channelId

    // Establish µStream WebSocket
    this.ws = new WebSocket(serverNode.streamEndpoint)

    await this.sendConnect({
      channelId: this.channelId,
      channelType: 'lightning',
      capacity: capacity
    })
  }

  async sendPayment(amount, data) {
    this.stateNumber++
    this.totalPaid += amount

    // Generate payment hash/preimage (Lightning-style)
    const preimage = this.generatePreimage()
    const paymentHash = createHash('sha256').update(preimage).digest('hex')

    // Sign state commitment
    const stateCommitment = {
      channelId: this.channelId,
      stateNumber: this.stateNumber,
      totalClaimable: this.totalPaid,
      recipient: this.serverAddress,
      paymentHash: paymentHash
    }

    const signature = await this.signStateCommitment(stateCommitment)

    // Send µStream packet
    this.ws.send(JSON.stringify({
      type: 'PAYMENT',
      seq: this.stateNumber,
      timestamp: Date.now(),
      payment: {
        channelId: this.channelId,
        channelType: 'lightning',
        stateNumber: this.stateNumber,
        totalClaimable: this.totalPaid.toString(),
        paymentHash: paymentHash,
        preimage: null,  // Server reveals after service
        stateSignature: signature
      },
      data: data
    }))

    // Wait for response with preimage
    return new Promise((resolve) => {
      this.ws.once('message', (msg) => {
        const response = JSON.parse(msg)

        // Verify preimage matches hash
        const hash = createHash('sha256').update(response.preimage).digest('hex')
        if (hash !== paymentHash) {
          throw new Error('Invalid preimage')
        }

        resolve(response.data)
      })
    })
  }

  generatePreimage() {
    return Buffer.from(crypto.randomBytes(32)).toString('hex')
  }

  async signStateCommitment(commitment) {
    // Sign with Lightning node's key
    return await this.lightning.signMessage(JSON.stringify(commitment))
  }
}

// Usage
const client = new MicroStreamLightningClient({
  lightningNode: 'localhost:10009'
})

await client.connect('03abc...@server.com:9735', 1000000)

// Stream payments
for (let i = 0; i < 1000; i++) {
  const data = await client.sendPayment(100, { request: 'temperature' })
  console.log(data)
}
```

### Server Implementation

```javascript
class MicroStreamLightningServer {
  constructor(config) {
    this.lightning = new LightningClient(config.lightningNode)
    this.sessions = new Map()
  }

  async handlePaymentPacket(session, packet) {
    const { channelId, stateNumber, totalClaimable, paymentHash, stateSignature } = packet.payment

    // Verify state signature
    const isValid = await this.verifyStateSignature(
      channelId,
      stateNumber,
      totalClaimable,
      stateSignature,
      session.clientPubkey
    )

    if (!isValid) {
      throw new Error('Invalid signature')
    }

    // Store state (can settle anytime!)
    session.latestState = {
      stateNumber,
      totalClaimable,
      paymentHash,
      signature: stateSignature
    }

    // Process request
    const responseData = await this.processRequest(packet.data)

    // Generate preimage (proves service delivered)
    const preimage = this.generatePreimage(paymentHash)

    // Send response with preimage
    const response = {
      type: 'PAYMENT',
      seq: stateNumber,
      timestamp: Date.now(),
      payment: {
        preimage: preimage  // Client needs this to complete HTLC
      },
      data: responseData
    }

    session.ws.send(JSON.stringify(response))

    // Decide if we should settle now
    if (BigInt(totalClaimable) >= this.settlementThreshold) {
      // Server settles unilaterally!
      await this.settleLightningChannel(session)
    }
  }

  async settleLightningChannel(session) {
    const { channelId, totalClaimable } = session.latestState

    // Update Lightning channel state (off-chain)
    await this.lightning.updateChannelBalance(channelId, totalClaimable)

    console.log(`Settled ${totalClaimable} sats from Lightning channel ${channelId}`)

    // No on-chain transaction needed (Lightning magic!)
  }
}
```

---

## Comparison: Settlement Models

### Request-Based Settlement (Original - WRONG)

```
Unsettled: 100,000 wei

Server → Client: "Please settle"
Client → Server: "OK" (executes x402)
    OR
Client → Server: [IGNORES REQUEST]  ← Problem!

Server: Stuck waiting for client
```

### Unilateral Settlement (Payment Channels - RIGHT)

```
Latest State: Client signed "Server can claim 100,000"

Server: "I'm settling now"
Server → Blockchain: Submit signed state
Blockchain: Verifies signature, transfers funds
Server: ✅ Paid!

Client cooperation: NOT NEEDED
```

---

## Benefits of Payment Channel Integration

### 1. Unilateral Settlement
✅ Payee controls when to settle
✅ No dependence on payer cooperation
✅ Can't be griefed by offline/uncooperative payer

### 2. Lower Settlement Costs
✅ Lightning: Zero on-chain cost until channel close
✅ State channels: One on-chain tx per settlement (not per payment)
✅ Batch thousands of µStream payments into one settlement

### 3. Instant Finality (for payee)
✅ Signed state = immediate claim right
✅ Payee has cryptographic proof
✅ Can settle on-chain anytime if needed

### 4. Security
✅ Funds escrowed in channel contract
✅ Cryptographic signatures prevent fraud
✅ Monotonic state numbers prevent rollback
✅ Timeouts protect both parties

---

## Updated µStream Specification

### Channel Establishment (New Phase)

**Before streaming, establish payment channel:**

```http
HTTP/1.1 402 Payment Required

{
  "paymentOptions": [
    {
      "protocol": "microstream",
      "settlementMethod": "lightning-channel",
      "channelSetup": {
        "lightningNode": "03abc...@server.com:9735",
        "minCapacity": "1000000",
        "maxCapacity": "10000000"
      }
    },
    {
      "protocol": "microstream",
      "settlementMethod": "state-channel",
      "channelSetup": {
        "contractAddress": "0xabc123...",
        "minDeposit": "1000000",
        "timeout": 86400
      }
    }
  ]
}
```

### PAYMENT Packet (Updated)

```typescript
interface ChannelPaymentPacket {
  type: 'PAYMENT'
  seq: number
  timestamp: number
  payment: {
    // Channel info
    channelId: string
    channelType: 'lightning' | 'state-channel' | 'raiden'

    // State commitment (UNILATERAL SETTLEMENT!)
    stateNumber: number
    totalClaimable: string
    stateSignature: string      // Payee can use this to claim anytime

    // Optional: bidirectional
    counterpartyClaimable?: string
    counterpartySignature?: string
  }
  data?: any
}
```

---

## Summary

### The Key Change

**Original µStream:** Settlement requires payer cooperation
**Payment Channel µStream:** Settlement is unilateral (payee decides)

### How It Works

1. **Channel opened:** Payer escrows funds
2. **Streaming:** Each packet = signed state commitment
3. **Settlement:** Payee can claim funds anytime (no permission)

### Perfect for M2M

✅ Trustless (cryptographic guarantees)
✅ Efficient (batch settlements)
✅ Unilateral (no cooperation needed)
✅ Works with Lightning, Raiden, state channels
✅ Bidirectional capable

This is the **correct architecture** for µStream! Thank you for catching that critical design issue. 🎯

