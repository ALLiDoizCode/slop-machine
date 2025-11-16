# External APIs

This project integrates with multiple external services for blockchain RPC, price oracles, and Nillion MPC operations. Key integrations include:

## Nillion Private Compute API

**Purpose:** MPC-based voucher pre-signing and signature verification

**Key Endpoints Used:**
- `POST /compute/sign` - Pre-sign 100 vouchers (10-second operation)
- `POST /compute/verify` - Verify MPC signature (sub-millisecond)

**Integration Notes:**
- **CRITICAL MVP BLOCKER**: Requires Nillion partnership and SDK access
- **Fallback**: Mock adapter provides local development capability

## Nillion Private Storage API

**Purpose:** Encrypted backup/recovery of voucher pools for crash resilience

**Key Endpoints Used:**
- `POST /storage/store` - Backup voucher pool
- `GET /storage/retrieve/:storageId` - Restore voucher pool

## Infura Ethereum RPC (Primary)

**Purpose:** Ethereum Optimism blockchain RPC

**Base URL:** `https://optimism-sepolia.infura.io/v3/{PROJECT_ID}` (testnet)

**Rate Limits:** Free tier: 100,000 requests/day

## Other External Services

- **Alchemy Ethereum RPC** (Backup)
- **Bitcoin Testnet Public RPC**
- **Solana Devnet RPC**
- **Chainlink Price Feeds** (ETH/USD)
- **Pyth Network Oracle** (SOL/USD)

---
