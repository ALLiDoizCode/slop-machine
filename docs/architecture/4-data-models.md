# 4. Data Models

## Model 1: Channel

**Purpose:** Represents a bidirectional payment channel between consumer and provider peers.

**Key Attributes:**
- `channelId`: bytes32 - Unique identifier
- `consumer`: address - Consumer peer's Ethereum address
- `provider`: address - Provider peer's Ethereum address
- `capacity`: uint256 - Total channel capacity in wei
- `consumerBalance`: uint256 - Consumer's current claimable balance
- `providerBalance`: uint256 - Provider's current claimable balance
- `lastStateNumber`: uint64 - Monotonically increasing state counter
- `settlementThreshold`: uint256 - Auto-settlement trigger amount
- `createdAt`: uint256 - Block timestamp of channel creation
- `expiresAt`: uint256 - Expiry timestamp
- `isActive`: boolean - Channel active status
- `isBidirectional`: boolean - True if both peers can receive payments

**Relationships:**
- Consumer → Channel (1:N)
- Provider → Channel (1:N)
- Channel → PaymentState (1:N)
- Channel → Session (1:1)

## Model 2: PaymentState

**Purpose:** Represents a signed state commitment within a payment channel.

**Key Attributes:**
- `channelId`: bytes32
- `stateNumber`: uint64
- `consumerClaimable`: uint256
- `providerClaimable`: uint256
- `signature`: bytes - EIP-712 signature (65 bytes)
- `signer`: address
- `timestamp`: uint256
- `nonce`: bytes32
- `isFinal`: boolean

## Model 3: Session

**Purpose:** Represents an active WebSocket streaming session.

**Key Attributes:**
- `sessionId`: string (UUID v4)
- `channelId`: bytes32
- `consumerAddress`: address
- `providerAddress`: address
- `bearerToken`: string (JWT)
- `connectedAt`: Date
- `state`: enum (CONNECTING, CONNECTED, STREAMING, CLOSING, CLOSED)
- `lastConsumerState`: PaymentState
- `lastProviderState`: PaymentState

## Model 4: DiscoverySession

**Purpose:** Tracks discovery phase before channel creation.

**Key Attributes:**
- `discoveryId`: string (UUID)
- `x402PaymentProof`: string
- `x402Amount`: uint256
- `channelId`: bytes32 | null
- `status`: enum (PAID, CHANNEL_CREATED, EXPIRED, FAILED)
- `expiresAt`: Date (5 minutes after payment)

---
