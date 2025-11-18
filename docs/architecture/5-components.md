# 5. Components

## Component 1: BIMPPeer (Core Protocol Engine)

**Responsibility:** Core protocol implementation supporting both consumer and provider roles.

**Key Interfaces:**
- `connect(providerUrl, options)` - Initiate connection as consumer
- `listen(port, options)` - Start listening as provider
- `sendPayment(amount, data)` - Send payment packet
- `onPayment(callback)` - Register payment received handler
- `settle()` - Trigger channel settlement

**Dependencies:** ws, ethers.js, @coinbase/x402
**Technology:** TypeScript 5.3.3, Node.js 20.11.0 LTS, Event-driven architecture

## Component 2: ChannelManager

**Responsibility:** Manages payment channel lifecycle.

**Key Interfaces:**
- `createChannel(consumer, capacity)` - Provider creates channel on-chain
- `getChannel(channelId)` - Retrieve channel state from blockchain
- `verifyChannel(channelId, expectedParams)` - Consumer verifies channel parameters
- `settleChannel(channelId, finalState, signature)` - Submit settlement transaction

**Dependencies:** ethers.js, pino, SettlementAdapter

## Component 3: StateManager

**Responsibility:** Manages off-chain payment state.

**Key Interfaces:**
- `createState(channelId, amount)` - Create new payment state
- `updateState(channelId, newState)` - Update to new state (validates monotonicity)
- `getLatestState(channelId)` - Retrieve current state
- `validateState(state, signature)` - Validate state signature and monotonicity

## Component 4: SignatureService

**Responsibility:** Handles EIP-712 signature creation and verification.

**Key Interfaces:**
- `signState(state, privateKey)` - Sign payment state with EIP-712
- `verifySignature(state, signature, expectedSigner)` - Verify signature validity

## Component 5: DiscoveryService (Provider-Side)

**Responsibility:** Handles HTTP 402 discovery endpoint for providers.

**Key Interfaces:**
- `handleDiscoveryRequest(req, res)` - HTTP handler for discovery requests
- `validateX402Payment(proof)` - Verify x402 payment with facilitator
- `issueWebSocketCredentials(channelId)` - Generate Bearer token for WebSocket

## Component 6: StreamingService

**Responsibility:** Manages WebSocket connections and packet routing.

**Key Interfaces:**
- `handleConnection(ws, channelId, bearerToken)` - Accept WebSocket connection
- `sendPacket(sessionId, packet)` - Send BIMP packet to peer
- `closeSession(sessionId, reason)` - Gracefully close session

## Component 7: SettlementAdapter (Interface)

**Responsibility:** Pluggable interface for different settlement backends.

**Key Interfaces:**
- `createChannel(params)` - Create channel on settlement backend
- `verifyChannel(channelId)` - Verify channel exists
- `settleChannel(channelId, finalState)` - Settle channel

## Component 8: WalletManager (Provider Hot Wallet)

**Responsibility:** Secure management of provider's hot wallet for channel creation.

**Key Interfaces:**
- `getAddress()` - Get wallet address
- `signTransaction(tx)` - Sign transaction
- `getNonce()` - Get next nonce (handles concurrency)

---
