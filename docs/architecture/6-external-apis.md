# 6. External APIs

## x402 Facilitator

**Purpose:** Process discovery fee micropayments and verify payment proofs.

**Base URL:** `https://facilitator.x402.org`

**Key Endpoints:**
- `POST /v1/payments` - Consumer submits x402 payment
- `GET /v1/payments/:id/verify` - Provider verifies payment

**Rate Limits:** 100 requests/minute (payment submission), 1000 requests/minute (verification)

**Integration:** Circuit breaker after 5 failures, 60s timeout, 3 retries with exponential backoff

## Alchemy RPC (Primary)

**Purpose:** Blockchain RPC provider for Base Sepolia and Optimism Sepolia.

**Base URLs:**
- Base Sepolia: `https://base-sepolia.g.alchemy.com/v2/{API_KEY}`
- Optimism Sepolia: `https://opt-sepolia.g.alchemy.com/v2/{API_KEY}`

**Rate Limits:** Free tier: 300 compute units/second (~100 requests/second)

**Fallback:** Automatic failover to Infura on Alchemy unavailability

## Infura RPC (Fallback)

**Purpose:** Backup blockchain RPC provider.

**Base URLs:**
- Base Sepolia: `https://base-sepolia.infura.io/v3/{API_KEY}`
- Optimism Sepolia: `https://optimism-sepolia.infura.io/v3/{API_KEY}`

**Circuit Breaker:** Switch to Infura after 5 consecutive Alchemy failures, reset after 60s

## Block Explorers

- Base Sepolia: `https://sepolia.basescan.org`
- Optimism Sepolia: `https://sepolia-optimism.etherscan.io`

**Use:** Contract verification, transaction inspection, debugging (not in critical path)

---
