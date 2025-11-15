# Task 1.3: Nillion Service Architecture Design

**Research Date:** November 15, 2025
**Status:** Draft v1.0 - Designed for Both HTTP Scenarios
**Researcher:** Research Phase - Week 1

---

## Executive Summary

This document presents a detailed service architecture for payment-gated AI services running on Nillion nilCC with Ethereum-based micropayments. Given uncertainty about nilCC's external HTTP capabilities (awaiting team response), we provide **TWO complete architectures**:

- **Architecture A:** Direct RPC (if HTTP calls supported)
- **Architecture B:** Oracle Pattern (if HTTP calls not supported)

Both architectures achieve the same goal: **atomic payment verification before execution** with **cryptographic guarantees** and **privacy preservation**.

**Key Design Decisions:**
- ✅ User signatures authorize credit consumption (prevents unauthorized charges)
- ✅ Nonce-based replay protection (prevents double-spending)
- ✅ TEE isolation for AI execution (privacy-preserving)
- ✅ Refund mechanism for failed executions (user protection)
- ✅ Graceful degradation on errors (robust error handling)

**Status:** Ready for prototyping once Nillion team confirms HTTP capabilities.

---

## Table of Contents

1. [Design Goals](#design-goals)
2. [Architecture A: Direct RPC Pattern](#architecture-a-direct-rpc-pattern)
3. [Architecture B: Oracle Pattern](#architecture-b-oracle-pattern)
4. [Comparison & Recommendation](#comparison--recommendation)
5. [Service Implementation Details](#service-implementation-details)
6. [Error Handling & Edge Cases](#error-handling--edge-cases)
7. [Security Model](#security-model)
8. [Deployment Specification](#deployment-specification)
9. [Testing Strategy](#testing-strategy)
10. [Next Steps](#next-steps)

---

## Design Goals

### Functional Requirements

1. **Atomic Payment Verification**
   - Service MUST verify payment before execution
   - No race conditions between check and consumption
   - User signature authorizes specific amount

2. **Privacy Preservation**
   - AI execution in TEE (AMD SEV-SNP)
   - Input data never exposed to executor
   - Output only returned to authorized user

3. **Graceful Error Handling**
   - Network failures don't lose user funds
   - Failed executions trigger refunds
   - Clear error messages to users

4. **Composability**
   - Services can call other services
   - Nested payment gating supported
   - Skills as context for processes

5. **Auditability**
   - All payments logged on-chain
   - TEE attestation verifiable
   - Service execution provable

---

### Non-Functional Requirements

1. **Latency:** P95 < 2 seconds end-to-end
2. **Cost:** Total cost per execution < $0.50 (enables 30%+ margin at $2 price point)
3. **Reliability:** 99.9% uptime (typical cloud SLA)
4. **Scalability:** Support 100+ concurrent requests
5. **Security:** No fund loss, no data leakage

---

## Architecture A: Direct RPC Pattern

**Assumption:** nilCC containers CAN make outbound HTTP/HTTPS calls to Ethereum RPC endpoints.

---

### System Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER (Client)                                │
│                                                                      │
│  1. Generate request signature                                      │
│     hash = keccak256(service, amount, nonce, input_data_hash)      │
│     signature = sign(hash, user_private_key)                       │
│                                                                      │
│  2. Send request to nilCC service                                   │
│     POST https://[nilcc-service-url]/execute                        │
│     Body: { user, service, amount, nonce, input, signature }       │
│                                                                      │
└───────────────────────────┬──────────────────────────────────────────┘
                            │
                            │ HTTPS Request
                            │
┌───────────────────────────▼──────────────────────────────────────────┐
│                    NILLION nilCC (TEE)                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Docker Container: AI Service                                   │ │
│  │                                                                  │ │
│  │  Step 1: Verify Request Signature                               │ │
│  │  ──────────────────────────────────                             │ │
│  │  - Reconstruct hash from request params                         │ │
│  │  - Recover signer from signature (ecrecover)                    │ │
│  │  - Verify signer == user address                                │ │
│  │  - ABORT if invalid signature                                   │ │
│  │                                                                  │ │
│  │  Step 2: Check Payment on Ethereum (HTTP RPC)                   │ │
│  │  ───────────────────────────────────────────                    │ │
│  │  HTTP POST → https://arb1.arbitrum.io/rpc                       │ │
│  │  {                                                               │ │
│  │    "method": "eth_call",                                         │ │
│  │    "params": [{                                                  │ │
│  │      "to": "0x[PermamindGate]",                                 │ │
│  │      "data": "getBalance(user, service)"                        │ │
│  │    }]                                                            │ │
│  │  }                                                               │ │
│  │  ← Response: balance (uint256)                                  │ │
│  │  - Verify balance >= amount                                     │ │
│  │  - ABORT if insufficient balance                                │ │
│  │                                                                  │ │
│  │  Step 3: Consume Credits (Ethereum Transaction)                 │ │
│  │  ──────────────────────────────────────────                     │ │
│  │  HTTP POST → https://arb1.arbitrum.io/rpc                       │ │
│  │  {                                                               │ │
│  │    "method": "eth_sendRawTransaction",                           │ │
│  │    "params": [{                                                  │ │
│  │      "to": "0x[PermamindGate]",                                 │ │
│  │      "data": "consumeCredits(user, service, amount, nonce,      │ │
│  │                                user_signature)",                 │ │
│  │      "from": "[executor_address]",                              │ │
│  │      "gasLimit": "100000"                                        │ │
│  │    }]                                                            │ │
│  │  }                                                               │ │
│  │  ← Response: txHash                                             │ │
│  │  - Wait for transaction receipt (confirmations)                 │ │
│  │  - ABORT if transaction fails                                   │ │
│  │                                                                  │ │
│  │  Step 4: Execute AI Service (TEE-Isolated)                      │ │
│  │  ─────────────────────────────────────                          │ │
│  │  - Load AI model (in TEE memory)                                │ │
│  │  - Process input data (private)                                 │ │
│  │  - Generate result                                              │ │
│  │  - CATCH errors → initiate refund                               │ │
│  │                                                                  │ │
│  │  Step 5: Return Result                                          │ │
│  │  ─────────────────────                                          │ │
│  │  - Encrypt result for user (optional)                           │ │
│  │  - Sign result with executor key (attestation)                  │ │
│  │  - Return to user                                               │ │
│  │                                                                  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  Attestation: AMD SEV-SNP cryptographic proof                       │
│  - Proves code running in TEE                                       │
│  - Verifiable by users off-chain                                    │
│                                                                      │
└───────────────────────────┬──────────────────────────────────────────┘
                            │
                            │ Ethereum RPC Calls
                            │
┌───────────────────────────▼──────────────────────────────────────────┐
│                  ETHEREUM (ARBITRUM L2)                              │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  PermamindGate Smart Contract                                   │ │
│  │                                                                  │ │
│  │  State:                                                          │ │
│  │  - creditBalance[user][service] = X wei                         │ │
│  │  - authorized[user][service][executor] = true                   │ │
│  │  - lastNonce[user][service] = N                                 │ │
│  │                                                                  │ │
│  │  Functions Called:                                               │ │
│  │  - getBalance(user, service) → uint256                          │ │
│  │  - consumeCredits(user, service, amount, nonce, sig)            │ │
│  │      → emits CreditsConsumed event                              │ │
│  │      → transfers amount to executor                             │ │
│  │                                                                  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Request Flow (Sequence Diagram)

```
User            nilCC Service       Ethereum Contract
  │                   │                      │
  │ 1. Sign Request   │                      │
  │───────────────────►                      │
  │                   │                      │
  │                   │ 2. Verify Signature  │
  │                   │─────────┐            │
  │                   │         │            │
  │                   │◄────────┘            │
  │                   │                      │
  │                   │ 3. eth_call          │
  │                   │    getBalance()      │
  │                   │─────────────────────►│
  │                   │                      │
  │                   │◄─────────────────────│
  │                   │  balance: 1000 wei   │
  │                   │                      │
  │                   │ 4. eth_sendRawTx     │
  │                   │    consumeCredits()  │
  │                   │─────────────────────►│
  │                   │                      │
  │                   │                      │ [Contract Execution]
  │                   │                      │ - Verify nonce
  │                   │                      │ - Verify sig
  │                   │                      │ - Deduct credits
  │                   │                      │ - Pay executor
  │                   │                      │
  │                   │◄─────────────────────│
  │                   │  txHash: 0xabc...    │
  │                   │                      │
  │                   │ 5. Execute AI        │
  │                   │─────────┐            │
  │                   │         │            │
  │                   │   [TEE Isolated]     │
  │                   │   - Load model       │
  │                   │   - Process input    │
  │                   │   - Generate result  │
  │                   │         │            │
  │                   │◄────────┘            │
  │                   │                      │
  │◄──────────────────│ 6. Return Result     │
  │  {result, proof}  │                      │
  │                   │                      │
```

---

### Pseudocode Implementation

#### Service Entry Point (Node.js/TypeScript)

```typescript
// service.ts - Running inside nilCC Docker container

import express from 'express';
import { ethers } from 'ethers';
import { loadAIModel, processInput } from './ai-engine';

const app = express();
const PORT = 3000;

// Ethereum RPC provider (Arbitrum)
const provider = new ethers.providers.JsonRpcProvider(
  'https://arb1.arbitrum.io/rpc'
);

// PermamindGate contract instance
const gateAddress = '0x...'; // Deploy address
const gateABI = [...]; // Contract ABI
const gate = new ethers.Contract(gateAddress, gateABI, provider);

// Executor wallet (has private key in TEE)
const executorWallet = new ethers.Wallet(process.env.EXECUTOR_PRIVATE_KEY, provider);

// Main execution endpoint
app.post('/execute', async (req, res) => {
  try {
    const { user, service, amount, nonce, input, signature } = req.body;

    // ──────────────────────────────────────────
    // STEP 1: Verify User Signature
    // ──────────────────────────────────────────
    const inputHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(JSON.stringify(input)));
    const messageHash = ethers.utils.solidityKeccak256(
      ['address', 'address', 'uint256', 'uint256', 'bytes32'],
      [user, service, amount, nonce, inputHash]
    );

    const recoveredAddress = ethers.utils.recoverAddress(messageHash, signature);

    if (recoveredAddress.toLowerCase() !== user.toLowerCase()) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    // ──────────────────────────────────────────
    // STEP 2: Check Balance (eth_call)
    // ──────────────────────────────────────────
    const balance = await gate.getBalance(user, service);

    if (balance.lt(amount)) {
      return res.status(402).json({
        error: 'Insufficient credits',
        balance: balance.toString(),
        required: amount.toString()
      });
    }

    // ──────────────────────────────────────────
    // STEP 3: Consume Credits (eth_sendTransaction)
    // ──────────────────────────────────────────
    const gateWithSigner = gate.connect(executorWallet);
    const tx = await gateWithSigner.consumeCredits(
      user,
      service,
      amount,
      nonce,
      signature,
      { gasLimit: 100000 }
    );

    // Wait for transaction confirmation
    const receipt = await tx.wait(1); // 1 confirmation

    if (!receipt.status) {
      // Transaction failed (e.g., nonce already used, signature invalid)
      return res.status(400).json({
        error: 'Credit consumption failed',
        txHash: tx.hash
      });
    }

    // ──────────────────────────────────────────
    // STEP 4: Execute AI Service (TEE Isolated)
    // ──────────────────────────────────────────
    let result;
    try {
      const model = await loadAIModel(); // Cached in TEE memory
      result = await processInput(model, input);
    } catch (executionError) {
      // AI execution failed → Issue refund
      // (Could implement refund mechanism in contract)
      return res.status(500).json({
        error: 'Execution failed',
        message: executionError.message,
        txHash: tx.hash, // User can claim refund with this
        refund: amount.toString()
      });
    }

    // ──────────────────────────────────────────
    // STEP 5: Return Result with Proof
    // ──────────────────────────────────────────
    const proof = {
      executor: executorWallet.address,
      txHash: tx.hash,
      blockNumber: receipt.blockNumber,
      timestamp: Date.now()
    };

    res.json({
      success: true,
      result,
      proof
    });

  } catch (error) {
    console.error('Execution error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', tee: 'AMD SEV-SNP' });
});

// TEE attestation endpoint
app.get('/attestation', async (req, res) => {
  // Return AMD SEV-SNP attestation report
  // (Platform-specific API call)
  const attestation = await getAttestationReport();
  res.json({ attestation });
});

app.listen(PORT, () => {
  console.log(`Service running in TEE on port ${PORT}`);
});
```

---

### Dockerfile for nilCC

```dockerfile
# Dockerfile
FROM node:20-alpine

# Install dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Copy service code
COPY src/ ./src/
COPY models/ ./models/

# Expose service port
EXPOSE 3000

# Environment variables (set via nilCC)
# EXECUTOR_PRIVATE_KEY - Executor wallet private key (in TEE)
# ETHEREUM_RPC_URL - Arbitrum RPC endpoint

# Run service
CMD ["node", "src/service.js"]
```

---

### Docker Compose for nilCC

```yaml
# docker-compose.yml
version: '3.8'

services:
  ai-service:
    build: .
    ports:
      - "3000:3000"
    environment:
      - EXECUTOR_PRIVATE_KEY=${EXECUTOR_PRIVATE_KEY}
      - ETHEREUM_RPC_URL=https://arb1.arbitrum.io/rpc
      - GATE_CONTRACT_ADDRESS=0x... # PermamindGate address
      - LOG_LEVEL=info
    volumes:
      - ./models:/app/models:ro # AI models (read-only)
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

### Deployment to nilCC

```bash
# 1. Build Docker image locally
docker build -t my-ai-service:v1.0 .

# 2. Push to container registry (if required)
docker push myregistry/my-ai-service:v1.0

# 3. Deploy to nilCC via API
curl -X POST https://api.nilcc.nillion.network/workloads \
  -H "Authorization: Bearer ${NILCC_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-ai-service",
    "compose": "... (base64 encoded docker-compose.yml) ...",
    "environment": {
      "EXECUTOR_PRIVATE_KEY": "...",
      "GATE_CONTRACT_ADDRESS": "0x..."
    },
    "tee_config": {
      "attestation": true,
      "isolation": "AMD_SEV_SNP"
    }
  }'

# 4. Get deployment URL
# Returns: https://[workload-id].nilcc.nillion.network
```

---

### Pros of Architecture A

1. ✅ **Simple** - No intermediaries, direct RPC calls
2. ✅ **Atomic** - Payment verification happens immediately before execution
3. ✅ **Low Latency** - ~1-2 seconds total (RPC calls + execution)
4. ✅ **Transparent** - Easy to debug and monitor
5. ✅ **Secure** - User signature prevents unauthorized consumption

---

### Cons of Architecture A

1. ❌ **Cross-Chain Race Condition** - User could withdraw between check and consumption
   - *Mitigation:* User signature authorizes specific amount, nonce prevents replay
2. ❌ **RPC Dependency** - Failure if Ethereum RPC down
   - *Mitigation:* Retry logic, multiple RPC endpoints (Infura + Alchemy)
3. ❌ **Gas Costs** - Executor pays gas for consumeCredits transaction
   - *Mitigation:* Executor reimbursed from consumed credits
4. ❌ **Assumption Dependency** - Requires HTTP access from nilCC
   - *Risk:* If not supported, architecture invalid

---

## Architecture B: Oracle Pattern

**Assumption:** nilCC containers CANNOT make outbound HTTP/HTTPS calls.

**Solution:** Use trusted oracle service that queries Ethereum and provides signed payment proofs to nilCC service.

---

### System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER (Client)                            │
│                                                                  │
│  1. Deposit credits on Ethereum                                 │
│  2. Request payment proof from Oracle                           │
│  3. Send request + proof to nilCC service                       │
│                                                                  │
└───────────────────────┬──────────────────────────────────────────┘
                        │
                        │ (2) Request Proof
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                     ORACLE SERVICE                               │
│                  (Trusted / Decentralized)                       │
│                                                                  │
│  1. Receive proof request from user                             │
│     { user, service, amount, nonce }                            │
│                                                                  │
│  2. Query Ethereum contract                                     │
│     balance = gate.getBalance(user, service)                    │
│                                                                  │
│  3. Verify balance >= amount                                    │
│                                                                  │
│  4. Generate signed proof                                       │
│     proof = {                                                   │
│       user, service, amount, nonce,                             │
│       balance, timestamp, blockNumber                           │
│     }                                                            │
│     signature = sign(proof, oracle_private_key)                 │
│                                                                  │
│  5. Return proof to user                                        │
│     { proof, signature }                                        │
│                                                                  │
└───────────────────────┬──────────────────────────────────────────┘
                        │
                        │ (3) Request + Proof
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                    NILLION nilCC (TEE)                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Docker Container: AI Service                               │ │
│  │                                                              │ │
│  │  Step 1: Verify Oracle Signature                            │ │
│  │  ──────────────────────────────                             │ │
│  │  - Reconstruct proof hash                                   │ │
│  │  - Recover signer from signature (ecrecover)                │ │
│  │  - Verify signer == known oracle address                    │ │
│  │  - ABORT if invalid signature                               │ │
│  │                                                              │ │
│  │  Step 2: Verify Proof Validity                              │ │
│  │  ─────────────────────────                                  │ │
│  │  - Check proof.timestamp (not too old, e.g., <5 min)        │ │
│  │  - Check proof.balance >= amount                            │ │
│  │  - Check proof.nonce == request.nonce                       │ │
│  │  - ABORT if proof invalid                                   │ │
│  │                                                              │ │
│  │  Step 3: Execute AI Service (TEE-Isolated)                  │ │
│  │  ─────────────────────────────────────                      │ │
│  │  - Load AI model (in TEE memory)                            │ │
│  │  - Process input data (private)                             │ │
│  │  - Generate result                                          │ │
│  │  - CATCH errors → return error (user can request refund)    │ │
│  │                                                              │ │
│  │  Step 4: Submit Consumption to Oracle                       │ │
│  │  ─────────────────────────────────────                      │ │
│  │  - Send execution proof to oracle                           │ │
│  │  - Oracle submits consumeCredits() transaction on Ethereum  │ │
│  │                                                              │ │
│  │  Step 5: Return Result                                      │ │
│  │  ─────────────────────                                      │ │
│  │  - Encrypt result for user (optional)                       │ │
│  │  - Sign result with executor key (attestation)              │ │
│  │  - Return to user                                           │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────┬────────────────────────────────────────┘
                          │
                          │ (4) Execution Proof
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                     ORACLE SERVICE                               │
│                                                                  │
│  1. Receive execution proof from nilCC service                  │
│  2. Verify proof (service signature, TEE attestation)           │
│  3. Submit Ethereum transaction                                 │
│     gate.consumeCredits(user, service, amount, nonce, sig)      │
│  4. Wait for confirmation                                       │
│  5. Notify service of transaction hash                          │
│                                                                  │
└─────────────────────────┬────────────────────────────────────────┘
                          │
                          │ Ethereum Transaction
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│                  ETHEREUM (ARBITRUM L2)                          │
│                                                                  │
│  PermamindGate Contract                                          │
│  - Deduct credits                                                │
│  - Pay oracle (oracle reimburses executor)                       │
│  - Emit CreditsConsumed event                                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

### Oracle Service Design

#### Option 1: Centralized Oracle (MVP)

**Pros:**
- Simple to implement
- Low latency
- Easy debugging

**Cons:**
- Single point of failure
- Trust required (but TEE verifies signatures)
- Centralization risk

**Implementation:**
```typescript
// oracle-service.ts

import express from 'express';
import { ethers } from 'ethers';

const app = express();
const provider = new ethers.providers.JsonRpcProvider('https://arb1.arbitrum.io/rpc');
const gate = new ethers.Contract(gateAddress, gateABI, provider);
const oracleWallet = new ethers.Wallet(process.env.ORACLE_PRIVATE_KEY, provider);

// Endpoint: Request payment proof
app.post('/proof', async (req, res) => {
  const { user, service, amount, nonce } = req.body;

  // Query Ethereum contract
  const balance = await gate.getBalance(user, service);

  if (balance.lt(amount)) {
    return res.status(402).json({ error: 'Insufficient credits' });
  }

  // Generate proof
  const proof = {
    user,
    service,
    amount: amount.toString(),
    nonce,
    balance: balance.toString(),
    timestamp: Date.now(),
    blockNumber: await provider.getBlockNumber()
  };

  // Sign proof
  const proofHash = ethers.utils.solidityKeccak256(
    ['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
    [user, service, amount, nonce, proof.timestamp, proof.blockNumber]
  );
  const signature = await oracleWallet.signMessage(ethers.utils.arrayify(proofHash));

  res.json({ proof, signature });
});

// Endpoint: Submit consumption (called by nilCC service after execution)
app.post('/consume', async (req, res) => {
  const { user, service, amount, nonce, userSignature, executionProof } = req.body;

  // Verify execution proof (from TEE)
  // ... (verify service signature, attestation) ...

  // Submit transaction to Ethereum
  const tx = await gate.connect(oracleWallet).consumeCredits(
    user,
    service,
    amount,
    nonce,
    userSignature,
    { gasLimit: 100000 }
  );

  const receipt = await tx.wait(1);

  res.json({ txHash: tx.hash, status: receipt.status });
});

app.listen(4000);
```

---

#### Option 2: Decentralized Oracle (Production)

**Pros:**
- No single point of failure
- Trustless (majority consensus)
- Censorship resistant

**Cons:**
- Higher latency (consensus overhead)
- More complex
- Higher costs (multiple nodes)

**Design:**
- Multiple oracle nodes run proof service
- Each node signs proof independently
- nilCC service requires M-of-N signatures (e.g., 3-of-5)
- Threshold signatures or multisig

**Existing Frameworks:**
- Chainlink-style oracle network
- API3 dAPI
- Custom TEE-based oracle (Nillion nodes could run it)

---

### Service Implementation (Oracle Pattern)

```typescript
// service.ts - Architecture B (Oracle Pattern)

import express from 'express';
import { ethers } from 'ethers';
import axios from 'axios';

const app = express();
const ORACLE_URL = process.env.ORACLE_URL || 'https://oracle.permamind.network';
const ORACLE_ADDRESS = '0x...'; // Known oracle public address

app.post('/execute', async (req, res) => {
  try {
    const { user, service, amount, nonce, input, userSignature, oracleProof, oracleSignature } = req.body;

    // ──────────────────────────────────────────
    // STEP 1: Verify Oracle Signature
    // ──────────────────────────────────────────
    const proofHash = ethers.utils.solidityKeccak256(
      ['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256'],
      [
        oracleProof.user,
        oracleProof.service,
        oracleProof.amount,
        oracleProof.nonce,
        oracleProof.timestamp,
        oracleProof.blockNumber
      ]
    );
    const messageHash = ethers.utils.hashMessage(ethers.utils.arrayify(proofHash));
    const recoveredOracle = ethers.utils.recoverAddress(messageHash, oracleSignature);

    if (recoveredOracle.toLowerCase() !== ORACLE_ADDRESS.toLowerCase()) {
      return res.status(401).json({ error: 'Invalid oracle signature' });
    }

    // ──────────────────────────────────────────
    // STEP 2: Verify Proof Validity
    // ──────────────────────────────────────────
    const now = Date.now();
    const proofAge = now - oracleProof.timestamp;

    if (proofAge > 5 * 60 * 1000) { // 5 minutes
      return res.status(400).json({ error: 'Proof too old' });
    }

    if (BigInt(oracleProof.balance) < BigInt(amount)) {
      return res.status(402).json({ error: 'Insufficient credits (per proof)' });
    }

    if (oracleProof.nonce !== nonce) {
      return res.status(400).json({ error: 'Nonce mismatch' });
    }

    // ──────────────────────────────────────────
    // STEP 3: Execute AI Service (TEE Isolated)
    // ──────────────────────────────────────────
    let result;
    try {
      const model = await loadAIModel();
      result = await processInput(model, input);
    } catch (executionError) {
      return res.status(500).json({
        error: 'Execution failed',
        message: executionError.message
      });
    }

    // ──────────────────────────────────────────
    // STEP 4: Submit Consumption to Oracle
    // ──────────────────────────────────────────
    const executionProof = {
      user,
      service,
      amount,
      nonce,
      result: ethers.utils.keccak256(ethers.utils.toUtf8Bytes(JSON.stringify(result))),
      timestamp: Date.now()
    };
    const executionSignature = await signExecutionProof(executionProof);

    const oracleResponse = await axios.post(`${ORACLE_URL}/consume`, {
      user,
      service,
      amount,
      nonce,
      userSignature,
      executionProof,
      executionSignature
    });

    // ──────────────────────────────────────────
    // STEP 5: Return Result
    // ──────────────────────────────────────────
    res.json({
      success: true,
      result,
      proof: {
        txHash: oracleResponse.data.txHash,
        oracleProof,
        executionProof
      }
    });

  } catch (error) {
    console.error('Execution error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000);
```

---

### Pros of Architecture B

1. ✅ **No HTTP Dependency** - Works without external HTTP from nilCC
2. ✅ **Oracle Batching** - Oracle can batch proofs for efficiency
3. ✅ **Flexible** - Oracle can be centralized (simple) or decentralized (trustless)
4. ✅ **Separation of Concerns** - Payment layer separate from execution layer

---

### Cons of Architecture B

1. ❌ **Added Complexity** - Oracle service required (new infrastructure)
2. ❌ **Higher Latency** - Extra round trip to oracle (~500ms-1s added)
3. ❌ **Oracle Trust** - Centralized oracle requires trust (mitigated by signatures)
4. ❌ **Cost** - Oracle infrastructure costs (servers, Ethereum gas for submissions)

---

## Comparison & Recommendation

### Side-by-Side Comparison

| Criteria | Architecture A (Direct RPC) | Architecture B (Oracle) |
|----------|----------------------------|------------------------|
| **Complexity** | Low (1 service) | Medium (service + oracle) |
| **Latency** | 1-2s | 2-3s |
| **Cost** | Low (only gas for consumeCredits) | Medium (oracle infrastructure + gas) |
| **Trust Model** | Trust TEE + Ethereum | Trust TEE + Ethereum + Oracle signatures |
| **Reliability** | Depends on RPC uptime | Depends on oracle uptime |
| **Scalability** | High (stateless service) | High (oracle can be scaled) |
| **Security** | Strong (user signature, nonce) | Strong (oracle signature + user signature) |
| **Decentralization** | High (no intermediary) | Medium-Low (centralized oracle) or High (decentralized oracle) |
| **HTTP Dependency** | YES (BLOCKER if not supported) | NO |
| **Development Time** | 1-2 weeks | 3-4 weeks |
| **Production Readiness** | Simpler to deploy | More moving parts |

---

### Recommendation

**Primary Choice:** **Architecture A (Direct RPC)**

**Rationale:**
1. Simpler architecture (less code, fewer bugs)
2. Lower latency (better UX)
3. Lower costs (no oracle infrastructure)
4. More decentralized (no intermediary trust)

**Contingency:** **Architecture B (Oracle)** if Nillion team confirms HTTP calls not supported

**Hybrid Option:** Start with Architecture A, build Architecture B as fallback. If HTTP supported, ship A. If not, switch to B.

---

### Implementation Priority

**Week 1 (Current):**
- Design both architectures (DONE)
- Get Nillion team response on HTTP access
- Decide which to prototype

**Week 2:**
- If HTTP supported → Build Architecture A prototype
- If not supported → Build Architecture B prototype (centralized oracle MVP)

**Week 3:**
- Deploy to testnet
- Measure latency, costs
- Security testing

**Week 4:**
- Production deployment (if GO decision)
- OR pivot to alternatives (if NO-GO)

---

## Service Implementation Details

### AI Model Loading (TEE-Optimized)

```typescript
// ai-engine.ts

import * as tf from '@tensorflow/tfjs-node';
import { pipeline } from '@xenova/transformers';

// Cache model in memory (TEE has ephemeral state)
let cachedModel: any = null;

export async function loadAIModel(): Promise<any> {
  if (cachedModel) {
    return cachedModel;
  }

  // Load model from volume mount (models baked into Docker image)
  const modelPath = '/app/models/my-ai-model';

  // Example: Load TensorFlow model
  cachedModel = await tf.loadLayersModel(`file://${modelPath}/model.json`);

  // OR: Load Hugging Face transformer
  // cachedModel = await pipeline('text-generation', 'gpt2', {
  //   local_files_only: true,
  //   model_path: modelPath
  // });

  console.log('AI model loaded into TEE memory');
  return cachedModel;
}

export async function processInput(model: any, input: any): Promise<any> {
  // Example: Text generation
  if (input.type === 'text-generation') {
    const result = await model(input.prompt, {
      max_length: input.maxTokens || 100,
      temperature: input.temperature || 0.7
    });
    return { generated: result[0].generated_text };
  }

  // Example: Image classification
  if (input.type === 'image-classification') {
    const tensor = tf.node.decodeImage(Buffer.from(input.imageBase64, 'base64'));
    const predictions = await model.predict(tensor.expandDims(0));
    return { predictions: await predictions.array() };
  }

  throw new Error(`Unsupported input type: ${input.type}`);
}
```

---

### Error Handling & Refunds

```typescript
// error-handler.ts

export async function handleExecutionError(
  error: Error,
  user: string,
  service: string,
  amount: string,
  txHash: string
): Promise<void> {
  console.error('Execution error:', error);

  // Log to monitoring system
  await logError({
    user,
    service,
    amount,
    txHash,
    error: error.message,
    stack: error.stack,
    timestamp: Date.now()
  });

  // Trigger refund (via smart contract or manual process)
  // Option 1: Automatic refund (requires contract support)
  // await gate.refund(user, service, amount, txHash);

  // Option 2: Manual refund queue
  await queueRefund({
    user,
    service,
    amount,
    txHash,
    reason: error.message
  });

  // Notify user
  // (via webhook, email, or on-chain event)
}

async function queueRefund(refund: any): Promise<void> {
  // Store in database for manual processing
  // or submit to smart contract refund queue
  console.log('Refund queued:', refund);
}
```

---

## Error Handling & Edge Cases

### Error Scenarios

| Scenario | Detection | Handling | User Impact |
|----------|-----------|----------|-------------|
| **Invalid signature** | Step 1 (sig verify) | Reject request (401) | No charge, clear error |
| **Insufficient credits** | Step 2 (balance check) | Reject request (402) | No charge, prompt to top up |
| **Nonce already used** | Step 3 (consumeCredits) | Tx fails, reject (400) | No charge, increase nonce |
| **RPC failure** | Step 2 or 3 | Retry 3x, then error (503) | No charge, retry later |
| **Tx reverted** | Step 3 (tx.wait) | Return error (400) | No charge (tx failed) |
| **AI execution error** | Step 4 (processInput) | Return error, queue refund (500) | Charged, refund initiated |
| **Out of memory** | Step 4 (model load) | Return error (507) | No charge (pre-execution) |
| **Timeout** | Any step | Return error (408) | Depends on step (refund if charged) |

---

### Retry Logic

```typescript
async function retryableEthereumCall<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      if (attempt === maxRetries) {
        throw error;
      }

      // Retry on network errors, not on revert/rejection
      if (error.code === 'NETWORK_ERROR' || error.code === 'TIMEOUT') {
        const delay = Math.min(1000 * Math.pow(2, attempt), 5000); // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }

      // Don't retry on application errors
      throw error;
    }
  }
  throw new Error('Unreachable');
}

// Usage
const balance = await retryableEthereumCall(() => gate.getBalance(user, service));
```

---

## Security Model

### Threat Model

#### Threats Mitigated

1. **Unauthorized Credit Consumption**
   - User signature required
   - Nonce prevents replay
   - Executor authorization checked on-chain

2. **Data Leakage**
   - TEE isolation (AMD SEV-SNP)
   - Cryptographic attestation verifiable
   - No logs of user input data

3. **Front-Running**
   - User signature binds to specific executor
   - Nonce prevents multiple executions
   - MEV protection via signature

4. **Executor Dishonesty (Charge Without Execution)**
   - User signature authorizes specific amount
   - Can monitor on-chain events
   - Reputation system (future)

---

#### Residual Risks

1. **TEE Compromise** (Low Probability, High Impact)
   - Risk: AMD SEV-SNP vulnerability discovered
   - Mitigation: Keep TEE firmware updated, monitor security advisories
   - Fallback: ZK proofs for execution verification (future)

2. **Smart Contract Exploit** (Low with Audit)
   - Risk: Bug in PermamindGate contract
   - Mitigation: Security audit, formal verification, bug bounty
   - Limit: Emergency pause mechanism

3. **Cross-Chain Race Condition** (Medium)
   - Risk: User withdraws credits between check and consumption
   - Mitigation: User signature authorizes specific amount (can't withdraw authorized amount)

4. **Oracle Manipulation** (Architecture B Only)
   - Risk: Oracle provides false proofs
   - Mitigation: Oracle signatures verified, decentralized oracle (production)

---

### Attestation Verification

```typescript
// attestation.ts

export async function getAttestationReport(): Promise<any> {
  // AMD SEV-SNP attestation API (platform-specific)
  // This would call nilCC platform APIs

  // Example structure (pseudocode):
  const report = {
    teeType: 'AMD_SEV_SNP',
    measurement: '0x...', // Hash of code + data
    signature: '0x...', // AMD signature
    certificates: [...], // Certificate chain
    timestamp: Date.now()
  };

  return report;
}

export function verifyAttestation(report: any): boolean {
  // Verify:
  // 1. AMD signature is valid
  // 2. Measurement matches expected code hash
  // 3. Certificates chain to AMD root CA
  // 4. Timestamp is recent

  // This would use AMD SEV-SNP verification libraries
  // Or submit to smart contract for on-chain verification

  return true; // Placeholder
}
```

---

## Deployment Specification

### Infrastructure Requirements

**Nillion nilCC:**
- TEE: AMD SEV-SNP
- CPU: 4 cores minimum
- RAM: 8GB minimum (16GB for larger models)
- Storage: 20GB for model + code
- Network: Outbound HTTPS (if Architecture A)

**Ethereum:**
- Network: Arbitrum One (L2 for low fees)
- Contract: PermamindGate deployed
- Wallet: Executor wallet with ETH for gas

**Oracle (Architecture B only):**
- Server: 2 CPU cores, 4GB RAM
- Network: HTTPS ingress/egress
- Wallet: Oracle wallet with ETH for gas
- Database: Optional (for proof logging)

---

### Cost Estimates (Per Execution)

| Component | Architecture A | Architecture B |
|-----------|---------------|----------------|
| Ethereum Gas (consumeCredits) | $0.00006 (Arbitrum) | $0.00006 |
| Nillion nilCC Compute | **TBD** (need pricing) | **TBD** |
| AI Inference (10s @ 4 CPU) | **~$0.0006** (proxy: $0.20/hr) | **~$0.0006** |
| Oracle Infrastructure | - | **$0.0001** (amortized) |
| RPC Calls (Infura) | $0.0001 | - |
| **TOTAL (Ethereum + Compute)** | **~$0.0008** | **~$0.0008** |
| **Nillion Compute (Unknown)** | **+TBD** | **+TBD** |
| **GRAND TOTAL** | **~$0.001 + TBD** | **~$0.001 + TBD** |

**Assumptions:**
- Nillion compute ~2-3x Google Cloud TEE pricing → ~$0.002 per execution (10s)
- **Estimated Total: ~$0.003 per execution**

**Margin Analysis (at $2.00 user price):**
- Cost: $0.003
- Revenue: $2.00
- Gross Margin: ($2.00 - $0.003) / $2.00 = **99.85%** 🎉

**Reality Check:**
- This assumes Nillion compute is cheap
- **Week 2 research MUST validate actual Nillion pricing**
- If Nillion costs $0.50 per execution, margin drops to 75% (still viable)
- If Nillion costs $1.50 per execution, margin drops to 25% (borderline)

---

## Testing Strategy

### Unit Tests

```typescript
// service.test.ts

import { expect } from 'chai';
import { ethers } from 'ethers';
import { verifySignature, checkBalance } from './service';

describe('Service Unit Tests', () => {
  it('should verify valid user signature', () => {
    const wallet = ethers.Wallet.createRandom();
    const message = 'test message';
    const signature = wallet.signMessage(message);

    const recovered = verifySignature(message, signature);
    expect(recovered).to.equal(wallet.address);
  });

  it('should reject invalid signature', () => {
    const signature = '0xinvalid';
    expect(() => verifySignature('test', signature)).to.throw();
  });

  it('should check balance correctly', async () => {
    // Mock Ethereum RPC
    const balance = await checkBalance('0xUser', '0xService');
    expect(balance).to.be.a('bigint');
  });
});
```

---

### Integration Tests (Testnet)

```bash
# integration-test.sh

#!/bin/bash

# 1. Deploy PermamindGate contract to Arbitrum Sepolia
forge create PermamindGate --rpc-url $ARB_SEPOLIA_RPC --private-key $DEPLOYER_KEY

# 2. User buys credits
cast send $GATE_ADDRESS "buyCredits(address)" $SERVICE_ADDRESS \
  --value 1ether --private-key $USER_KEY

# 3. User authorizes executor
cast send $GATE_ADDRESS "authorizeExecutor(address,address)" $EXECUTOR_ADDRESS $SERVICE_ADDRESS \
  --private-key $USER_KEY

# 4. Send execution request to nilCC service
curl -X POST https://[nilcc-service-url]/execute \
  -H "Content-Type: application/json" \
  -d '{
    "user": "0xUser...",
    "service": "0xService...",
    "amount": "100000000000000000",
    "nonce": 1,
    "input": {"prompt": "Hello, world!"},
    "signature": "0x..."
  }'

# 5. Verify result returned
# 6. Verify credits consumed on-chain
cast call $GATE_ADDRESS "getBalance(address,address)" $USER_ADDRESS $SERVICE_ADDRESS
```

---

### Security Tests

1. **Signature Verification**
   - Valid signature → accept
   - Invalid signature → reject
   - Signature from wrong user → reject

2. **Replay Protection**
   - Same nonce twice → second fails
   - Old nonce → reject

3. **Balance Checks**
   - Sufficient balance → execute
   - Insufficient balance → reject
   - Balance = 0 → reject

4. **TEE Attestation**
   - Valid attestation → verify
   - Invalid attestation → reject
   - Tampered code → measurement mismatch

---

## Next Steps

### Immediate Actions (This Week)

1. **Get Nillion Team Response** (BLOCKER)
   - Send Discord ticket (DONE - prepared message)
   - Send GitHub discussion (DONE - prepared message)
   - Wait 24-48 hours for response

2. **Finalize Architecture** (Depends on Response)
   - If HTTP supported → Architecture A
   - If not → Architecture B
   - Update Task 1.4 with chosen design

3. **Week 1 Report** (End of Week)
   - Compile all research into summary
   - Make GO/NO-GO recommendation
   - Identify blockers for Week 2

---

### Week 2 Actions (If GO)

4. **Build Prototype**
   - Smart contract (PermamindGate)
   - nilCC service (Docker + code)
   - Oracle (if Architecture B)

5. **Deploy to Testnet**
   - Arbitrum Sepolia (Ethereum)
   - Nillion Testnet
   - Test end-to-end flow

6. **Measure Performance**
   - Latency (P50, P95, P99)
   - Costs (Ethereum gas, Nillion compute)
   - Reliability (error rates)

7. **Economic Modeling**
   - With ACTUAL Nillion pricing
   - Validate 30%+ margin
   - Sensitivity analysis

---

## Conclusion

**Status:** Architecture design complete for BOTH scenarios

**Confidence:**
- Architecture A (Direct RPC): High IF HTTP supported
- Architecture B (Oracle): High (can definitely build this)

**Recommendation:**
- Prefer Architecture A (simpler, faster, cheaper)
- Have Architecture B ready as fallback
- Decision point: Nillion team response on HTTP access

**Blockers:**
1. Nillion HTTP access confirmation (CRITICAL)
2. Nillion compute pricing (CRITICAL for Week 2)

**Risk Level:**
- Technical: Low (both architectures viable)
- Economic: Medium (depends on Nillion pricing)
- Timeline: Medium (waiting on Nillion team response)

**Next Document:** Task 1.4 - Performance Analysis & Documentation (once architecture finalized)

---

**Document Status:** COMPLETE - Awaiting Nillion Team Response
**Last Updated:** November 15, 2025
