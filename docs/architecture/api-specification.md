# API Specification

This system uses a **hybrid API architecture**:

- **WebSocket (Binary Protocol Buffers)**: Real-time bidirectional payment streaming
- **REST (OpenAPI 3.0)**: Dashboard queries, analytics, and admin operations

## WebSocket Binary Protocol API

**Connection URL:** `wss://api.nillion-pay.example.com/v1/stream`

**Authentication:** Wallet signature challenge (SIWE - Sign-In with Ethereum)

**Binary Framing:** All messages encoded as Protocol Buffer v3, wrapped in length-prefixed frames

**Message Flow:**
1. Client connects to WebSocket
2. Server sends `AuthChallenge` message
3. Client responds with `AuthResponse` (signed message)
4. Server verifies signature and sends `AuthSuccess` or `AuthFailure`
5. Authenticated clients can send/receive payment messages

**Protocol Buffer Schema (simplified - full schema in packages/protocol/proto/):**

```protobuf
syntax = "proto3";

package nillion.payment.v1;

// Wrapper for all messages
message StreamMessage {
  oneof payload {
    AuthChallenge auth_challenge = 1;
    AuthResponse auth_response = 2;
    AuthSuccess auth_success = 3;
    CreateChannelRequest create_channel_request = 10;
    CreateChannelResponse create_channel_response = 11;
    SendPaymentRequest send_payment_request = 20;
    SendPaymentResponse send_payment_response = 21;
    VoucherPoolStatus voucher_pool_status = 30;
    ChannelUpdate channel_update = 40;
    ErrorMessage error = 99;
  }
}

message AuthChallenge {
  string challenge = 1; // Random nonce
  int64 timestamp = 2;
}

message AuthResponse {
  string ethereum_address = 1;
  string signature = 2; // ECDSA signature of challenge
  optional string bitcoin_address = 3;
  optional string solana_address = 4;
}

message AuthSuccess {
  string user_id = 1;
  string session_id = 2;
}

message CreateChannelRequest {
  string chain_id = 1; // "ETHEREUM_OPTIMISM" | "BITCOIN_LIGHTNING" | "SOLANA"
  string counterparty_address = 2;
  string capacity = 3; // bigint as string (e.g., "1000000000000000000" for 1 ETH)
  string settlement_threshold = 4; // bigint as string
}

message CreateChannelResponse {
  string channel_id = 1;
  string status = 2; // "OPENING" | "OPEN"
  string on_chain_tx_hash = 3;
  VoucherPool voucher_pool = 4;
}

message VoucherPool {
  string pool_id = 1;
  int32 total_vouchers = 2; // Always 100
  int32 unused_vouchers = 3;
  string nillion_storage_id = 4;
  int64 last_backup_at = 5; // Unix timestamp
}

message SendPaymentRequest {
  string channel_id = 1;
  string amount = 2; // bigint as string
  string voucher_id = 3; // Pre-selected voucher from pool
}

message SendPaymentResponse {
  string payment_id = 1;
  string status = 2; // "COMPLETED" | "FAILED"
  int32 latency_ms = 3;
  int32 new_nonce = 4;
  string local_balance = 5; // bigint as string
  string remote_balance = 6; // bigint as string
}

message VoucherPoolStatus {
  string channel_id = 1;
  int32 unused_vouchers = 2;
  bool regeneration_needed = 3; // True if < 10 vouchers remain
}

message ChannelUpdate {
  string channel_id = 1;
  string status = 2; // "OPENING" | "OPEN" | "CLOSING" | "CLOSED"
  string local_balance = 3;
  string remote_balance = 4;
  int32 nonce = 5;
}

message ErrorMessage {
  string code = 1; // "VOUCHER_EXPIRED" | "INSUFFICIENT_BALANCE" | etc.
  string message = 2;
  map<string, string> details = 3;
}
```

**Key WebSocket Operations:**

| Operation | Request Message | Response Message | Purpose |
|-----------|----------------|------------------|---------|
| Authenticate | `AuthResponse` | `AuthSuccess` | Establish authenticated session |
| Open Channel | `CreateChannelRequest` | `CreateChannelResponse` | Create payment channel with voucher pool |
| Send Payment | `SendPaymentRequest` | `SendPaymentResponse` | Execute micropayment using voucher |
| Subscribe to Updates | (implicit on connect) | `ChannelUpdate`, `VoucherPoolStatus` | Real-time channel state notifications |

**Error Handling:**

All errors return `ErrorMessage` with standard error codes:

- `AUTH_FAILED`: Invalid signature or expired challenge
- `VOUCHER_EXPIRED`: Selected voucher past 1-hour TTL
- `VOUCHER_ALREADY_CONSUMED`: Attempted to reuse voucher
- `INSUFFICIENT_BALANCE`: Payment exceeds channel balance
- `CHANNEL_NOT_FOUND`: Invalid channel ID
- `NILLION_UNAVAILABLE`: Nillion MPC service unreachable
- `INVALID_AMOUNT`: Amount ≤ 0 or exceeds voucher limit

---

## REST API Specification

**Base URL:** `https://api.nillion-pay.example.com/v1`

**Authentication:** Bearer token (JWT issued after WebSocket auth, or API key for server-to-server)

**OpenAPI 3.0 Specification:**

```yaml
openapi: 3.0.0
info:
  title: Nillion Micropayment Protocol API
  version: 1.0.0
  description: REST API for queries, analytics, and channel management
servers:
  - url: https://api.nillion-pay.example.com/v1
    description: Production API
  - url: https://api-staging.nillion-pay.example.com/v1
    description: Staging API

security:
  - BearerAuth: []
  - ApiKeyAuth: []

paths:
  /channels:
    get:
      summary: List payment channels
      description: Returns paginated list of channels for authenticated user
      parameters:
        - name: chain_id
          in: query
          schema:
            type: string
            enum: [ETHEREUM_OPTIMISM, BITCOIN_LIGHTNING, SOLANA]
          description: Filter by blockchain
        - name: status
          in: query
          schema:
            type: string
            enum: [OPENING, OPEN, CLOSING, CLOSED, DISPUTED]
          description: Filter by channel status
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  channels:
                    type: array
                    items:
                      $ref: '#/components/schemas/Channel'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
        '401':
          $ref: '#/components/responses/Unauthorized'

  /channels/{channelId}:
    get:
      summary: Get channel details
      parameters:
        - name: channelId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Channel details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ChannelDetail'
        '404':
          $ref: '#/components/responses/NotFound'

  /metrics/performance:
    get:
      summary: Get performance metrics
      parameters:
        - name: metric_type
          in: query
          schema:
            type: string
            enum: [LATENCY, THROUGHPUT, SUCCESS_RATE]
        - name: chain_id
          in: query
          schema:
            type: string
        - name: start_time
          in: query
          required: true
          schema:
            type: string
            format: date-time
        - name: end_time
          in: query
          required: true
          schema:
            type: string
            format: date-time
        - name: interval
          in: query
          schema:
            type: string
            enum: [1m, 5m, 15m, 1h, 1d]
            default: 5m
      responses:
        '200':
          description: Time-series metrics
          content:
            application/json:
              schema:
                type: object
                properties:
                  metrics:
                    type: array
                    items:
                      $ref: '#/components/schemas/PerformanceMetric'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

  schemas:
    Channel:
      type: object
      properties:
        id:
          type: string
        chain_id:
          type: string
          enum: [ETHEREUM_OPTIMISM, BITCOIN_LIGHTNING, SOLANA]
        channel_id:
          type: string
        status:
          type: string
          enum: [OPENING, OPEN, CLOSING, CLOSED, DISPUTED]
        capacity:
          type: string
          description: bigint as string
        local_balance:
          type: string
        remote_balance:
          type: string
        nonce:
          type: integer
        on_chain_tx_hash:
          type: string
        created_at:
          type: string
          format: date-time
        last_activity_at:
          type: string
          format: date-time

    Pagination:
      type: object
      properties:
        page:
          type: integer
        limit:
          type: integer
        total:
          type: integer
        total_pages:
          type: integer

    Error:
      type: object
      properties:
        error:
          type: object
          properties:
            code:
              type: string
            message:
              type: string
            details:
              type: object

  responses:
    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
```

---
