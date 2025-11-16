# Data Models

These models represent the core business entities of the Nillion micropayment protocol. All models are defined as TypeScript interfaces in `packages/shared/src/types` and used across frontend, backend, and SDKs.

## Model: User

**Purpose:** Represents a participant in the payment system (payer or payee). Users are identified by their blockchain wallet addresses across all three chains.

**Key Attributes:**
- `id`: string (UUID) - Internal unique identifier for database relations
- `ethereumAddress`: string (0x-prefixed hex) - Ethereum Optimism wallet address (primary identity)
- `bitcoinAddress`: string (optional) - Bitcoin Lightning node public key or on-chain address
- `solanaAddress`: string (optional) - Solana wallet public key (base58 encoded)
- `nillionUserId`: string (optional) - Nillion network user ID for MPC operations
- `createdAt`: Date - Account creation timestamp
- `lastSeenAt`: Date - Last activity timestamp

### TypeScript Interface

```typescript
export interface User {
  id: string; // UUID v4
  ethereumAddress: string; // Required: primary identity
  bitcoinAddress?: string; // Optional: Bitcoin Lightning pubkey
  solanaAddress?: string; // Optional: Solana pubkey
  nillionUserId?: string; // Optional: assigned after first Nillion operation
  createdAt: Date;
  lastSeenAt: Date;
}
```

### Relationships
- One User has many PaymentChannels (as opener or counterparty)
- One User has many VoucherPools
- One User has many Transactions (as sender or receiver)

---

## Model: PaymentChannel

**Purpose:** Represents an off-chain payment channel on one of the three blockchains. Channels enable high-frequency micropayments without on-chain settlement for every transaction.

**Key Attributes:**
- `id`: string (UUID) - Internal unique identifier
- `chainId`: ChainType - Which blockchain (ETHEREUM_OPTIMISM | BITCOIN_LIGHTNING | SOLANA)
- `channelId`: string - On-chain channel identifier (chain-specific format)
- `openerUserId`: string - User who created/funded the channel
- `counterpartyUserId`: string - Other participant
- `status`: ChannelStatus - OPENING | OPEN | CLOSING | CLOSED | DISPUTED
- `capacity`: bigint - Maximum channel capacity in smallest unit (wei/satoshi/lamport)
- `localBalance`: bigint - Opener's current balance
- `remoteBalance`: bigint - Counterparty's current balance
- `nonce`: number - State update counter (prevents replay attacks)
- `settlementThreshold`: bigint - Monetary threshold for automatic settlement
- `onChainTxHash`: string - Opening transaction hash
- `createdAt`: Date
- `lastActivityAt`: Date
- `closedAt`: Date (optional)

### TypeScript Interface

```typescript
export enum ChainType {
  ETHEREUM_OPTIMISM = 'ETHEREUM_OPTIMISM',
  BITCOIN_LIGHTNING = 'BITCOIN_LIGHTNING',
  SOLANA = 'SOLANA',
}

export enum ChannelStatus {
  OPENING = 'OPENING',     // Transaction submitted, awaiting confirmation
  OPEN = 'OPEN',           // Active, can process payments
  CLOSING = 'CLOSING',     // Closure initiated, awaiting finalization
  CLOSED = 'CLOSED',       // Finalized on-chain
  DISPUTED = 'DISPUTED',   // Fraud proof challenge period
}

export interface PaymentChannel {
  id: string;
  chainId: ChainType;
  channelId: string; // Format depends on chain (e.g., Vector channelAddress, LN channel point)
  openerUserId: string;
  counterpartyUserId: string;
  status: ChannelStatus;
  capacity: bigint; // Total locked funds
  localBalance: bigint; // Opener's balance
  remoteBalance: bigint; // Counterparty's balance
  nonce: number; // Increments with each state update
  settlementThreshold: bigint; // e.g., $100 in wei/sat/lamport
  onChainTxHash: string;
  createdAt: Date;
  lastActivityAt: Date;
  closedAt?: Date;
}
```

### Relationships
- One PaymentChannel belongs to one User (opener)
- One PaymentChannel belongs to one User (counterparty)
- One PaymentChannel has many Payments
- One PaymentChannel has one active VoucherPool

---

## Model: Voucher

**Purpose:** Represents a pre-signed Nillion MPC voucher that authorizes a payment up to a specific amount without requiring real-time MPC signing. This is the core innovation enabling <100ms latency.

**Key Attributes:**
- `id`: string (UUID) - Internal identifier
- `voucherId`: string - Unique voucher identifier (embedded in MPC signature)
- `channelId`: string - Associated payment channel
- `nonce`: number - Voucher sequence number within pool
- `amountLimit`: bigint - Maximum payment this voucher can authorize
- `expiresAt`: Date - Expiration timestamp (1-hour TTL)
- `mpcSignature`: Buffer - Nillion MPC signature (binary)
- `status`: VoucherStatus - UNUSED | CONSUMED | EXPIRED
- `consumedByPaymentId`: string (optional) - Payment that used this voucher
- `createdAt`: Date

### TypeScript Interface

```typescript
export enum VoucherStatus {
  UNUSED = 'UNUSED',       // Available in pool
  CONSUMED = 'CONSUMED',   // Used for a payment
  EXPIRED = 'EXPIRED',     // TTL exceeded
}

export interface Voucher {
  id: string;
  voucherId: string; // Format: nillion_<uuid>
  channelId: string; // FK to PaymentChannel
  nonce: number; // 0-99 for 100-voucher pool
  amountLimit: bigint;
  expiresAt: Date; // createdAt + 1 hour
  mpcSignature: Buffer; // Binary Nillion signature
  status: VoucherStatus;
  consumedByPaymentId?: string;
  createdAt: Date;
}
```

### Relationships
- One Voucher belongs to one PaymentChannel
- One Voucher consumed by zero or one Payment

---

## Model: VoucherPool

**Purpose:** Represents a collection of 100 pre-signed vouchers created during the handshake phase. Pools are backed up to Nillion Private Storage for crash recovery.

**Key Attributes:**
- `id`: string (UUID)
- `channelId`: string - Associated payment channel
- `poolNonce`: number - Pool sequence number (increments when regenerated)
- `voucherCount`: number - Total vouchers (always 100)
- `unusedCount`: number - Available vouchers (decrements as consumed)
- `nillionStorageId`: string - Nillion Private Storage backup reference
- `lastBackupAt`: Date - Last backup to Nillion Storage
- `createdAt`: Date

### TypeScript Interface

```typescript
export interface VoucherPool {
  id: string;
  channelId: string; // FK to PaymentChannel
  poolNonce: number; // Increments each time pool is regenerated
  voucherCount: number; // Always 100
  unusedCount: number; // Decrements as vouchers consumed
  nillionStorageId: string; // Reference to Nillion Private Storage backup
  lastBackupAt: Date;
  createdAt: Date;
}
```

### Relationships
- One VoucherPool belongs to one PaymentChannel
- One VoucherPool has many Vouchers (100)

---

## Model: Payment

**Purpose:** Represents a single micropayment within a payment channel. Payments are authorized by consuming a voucher and update the channel's local/remote balance.

**Key Attributes:**
- `id`: string (UUID)
- `channelId`: string - Payment channel
- `voucherId`: string - Authorizing voucher
- `senderUserId`: string
- `receiverUserId`: string
- `amount`: bigint - Payment amount in smallest unit
- `nonce`: number - Channel state nonce after this payment
- `status`: PaymentStatus - PENDING | COMPLETED | FAILED
- `latencyMs`: number - End-to-end processing time (target <100ms)
- `createdAt`: Date
- `completedAt`: Date (optional)

### TypeScript Interface

```typescript
export enum PaymentStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

export interface Payment {
  id: string;
  channelId: string; // FK to PaymentChannel
  voucherId: string; // FK to Voucher
  senderUserId: string; // FK to User
  receiverUserId: string; // FK to User
  amount: bigint;
  nonce: number; // Channel state nonce after payment
  status: PaymentStatus;
  latencyMs: number; // Measured end-to-end
  createdAt: Date;
  completedAt?: Date;
}
```

### Relationships
- One Payment belongs to one PaymentChannel
- One Payment consumes one Voucher
- One Payment has one sender (User)
- One Payment has one receiver (User)

---

## Model: Settlement

**Purpose:** Represents an on-chain settlement triggered by monetary threshold. Settlements batch multiple payments and finalize them on the blockchain.

**Key Attributes:**
- `id`: string (UUID)
- `channelId`: string
- `chainId`: ChainType
- `settlementType`: SettlementType - MONETARY_THRESHOLD | MANUAL | CHANNEL_CLOSURE
- `paymentCount`: number - Number of payments included
- `totalAmount`: bigint - Sum of all payments
- `onChainTxHash`: string
- `status`: SettlementStatus - PENDING | CONFIRMED | FAILED
- `gasUsed`: bigint (optional)
- `gasCost`: bigint (optional)
- `createdAt`: Date
- `confirmedAt`: Date (optional)

### TypeScript Interface

```typescript
export enum SettlementType {
  MONETARY_THRESHOLD = 'MONETARY_THRESHOLD', // $100/$1000 threshold hit
  MANUAL = 'MANUAL', // User-initiated
  CHANNEL_CLOSURE = 'CHANNEL_CLOSURE', // Channel closing
}

export enum SettlementStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  FAILED = 'FAILED',
}

export interface Settlement {
  id: string;
  channelId: string; // FK to PaymentChannel
  chainId: ChainType;
  settlementType: SettlementType;
  paymentCount: number;
  totalAmount: bigint;
  onChainTxHash: string;
  status: SettlementStatus;
  gasUsed?: bigint;
  gasCost?: bigint;
  createdAt: Date;
  confirmedAt?: Date;
}
```

### Relationships
- One Settlement belongs to one PaymentChannel
- One Settlement finalizes many Payments (implicit, tracked via channel nonce)

---

## Model: CrossChainSwap

**Purpose:** Represents an atomic swap between two blockchains (e.g., BTC → ETH). Swaps use HTLCs (Hash Time-Locked Contracts) to ensure atomicity.

**Key Attributes:**
- `id`: string (UUID)
- `sourceChainId`: ChainType
- `destinationChainId`: ChainType
- `sourceChannelId`: string
- `destinationChannelId`: string
- `userId`: string - User initiating swap
- `sourceAmount`: bigint
- `destinationAmount`: bigint
- `exchangeRate`: number - Locked-in rate at swap initiation
- `htlcSecret`: Buffer - Preimage for HTLC unlock
- `htlcHash`: string - Hash of secret (public)
- `status`: SwapStatus
- `sourceTxHash`: string (optional)
- `destinationTxHash`: string (optional)
- `expiresAt`: Date - HTLC timeout (30 minutes)
- `createdAt`: Date
- `completedAt`: Date (optional)

### TypeScript Interface

```typescript
export enum SwapStatus {
  INITIATED = 'INITIATED',         // Swap created
  SOURCE_LOCKED = 'SOURCE_LOCKED', // Source chain funds locked
  DEST_LOCKED = 'DEST_LOCKED',     // Destination chain funds locked
  COMPLETED = 'COMPLETED',         // Secret revealed, both chains settled
  REFUNDED = 'REFUNDED',           // Timeout, funds returned
  FAILED = 'FAILED',               // Error during process
}

export interface CrossChainSwap {
  id: string;
  sourceChainId: ChainType;
  destinationChainId: ChainType;
  sourceChannelId: string; // FK to PaymentChannel
  destinationChannelId: string; // FK to PaymentChannel
  userId: string; // FK to User (initiator)
  sourceAmount: bigint;
  destinationAmount: bigint;
  exchangeRate: number; // e.g., 0.000033 BTC/ETH
  htlcSecret: Buffer; // Kept secret until reveal phase
  htlcHash: string; // SHA256(htlcSecret), public
  status: SwapStatus;
  sourceTxHash?: string;
  destinationTxHash?: string;
  expiresAt: Date; // HTLC timeout (30 min)
  createdAt: Date;
  completedAt?: Date;
}
```

### Relationships
- One CrossChainSwap has one source PaymentChannel
- One CrossChainSwap has one destination PaymentChannel
- One CrossChainSwap belongs to one User (initiator)

---

## Model: PerformanceMetric

**Purpose:** Time-series data for monitoring system performance. Stored in TimescaleDB hypertables for efficient aggregation and querying.

**Key Attributes:**
- `timestamp`: Date - Measurement time (hypertable partition key)
- `metricType`: MetricType - LATENCY | THROUGHPUT | SUCCESS_RATE
- `chainId`: ChainType (optional) - Null for cross-chain metrics
- `value`: number - Metric value (ms for latency, pkt/sec for throughput, % for success rate)
- `p50`: number (optional) - 50th percentile (for latency)
- `p95`: number (optional) - 95th percentile (for latency)
- `p99`: number (optional) - 99th percentile (for latency)

### TypeScript Interface

```typescript
export enum MetricType {
  LATENCY = 'LATENCY',
  THROUGHPUT = 'THROUGHPUT',
  SUCCESS_RATE = 'SUCCESS_RATE',
}

export interface PerformanceMetric {
  timestamp: Date; // TimescaleDB partition key
  metricType: MetricType;
  chainId?: ChainType; // Null for aggregate metrics
  value: number; // Actual measured value
  p50?: number; // Median latency
  p95?: number; // 95th percentile latency (target: <100ms)
  p99?: number; // 99th percentile latency
}
```

### Relationships
- No foreign keys (time-series data, optimized for append-only writes)

---
