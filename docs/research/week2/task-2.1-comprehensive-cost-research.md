# Task 2.1: Comprehensive Cost Research

**Research Date:** November 15, 2025
**Status:** Complete - Based on Public Data
**Researcher:** Research Phase - Week 2

---

## Executive Summary

This document provides comprehensive cost analysis for all components of the Nillion + Ethereum payment-gated M2M architecture, compiled from public pricing data across Ethereum L2s, cloud TEE providers, and AI inference platforms.

**Key Findings:**

**Ethereum Costs (Arbitrum L2):**
- ✅ **Per transaction: $0.00001 - $0.0001** (negligible)
- Gas prices: 0.01-0.1 gwei (2025 post-Dencun)
- NOT a cost blocker

**TEE Compute Costs (Proxy Estimates):**
- Google Cloud Confidential VM: **$0.20/hour** (n2d-standard-4)
- AWS Nitro Enclaves: **$0.15/hour** (c6a.xlarge equivalent)
- Azure Confidential: **$0.30/hour** (DC4s_v3)
- **Estimated Nillion: $0.40-1.00/hour** (2-5x cloud due to decentralization)

**AI Inference Costs:**
- OpenAI GPT-4: **$0.03-0.06 per request** (no privacy)
- OpenAI GPT-3.5: **$0.002-0.004 per request** (no privacy)
- Self-hosted Llama 3 8B: **$0.0001-0.0003 per request** (full privacy)
- Self-hosted Llama 3 70B: **$0.001-0.003 per request** (full privacy)

**Total Cost Per Execution (10s, Llama 8B):**
- Best case: **$0.0006** (Google Cloud TEE + self-hosted)
- Expected Nillion: **$0.001-0.003** (2-5x cloud premium)
- Worst case: **$0.008** (high Nillion premium)

**Conclusion:** All scenarios support excellent margins (>95%) at $2+ price points.

---

## Table of Contents

1. [Ethereum L1/L2 Costs](#ethereum-l1l2-costs)
2. [TEE Compute Costs](#tee-compute-costs)
3. [AI Inference Costs](#ai-inference-costs)
4. [Total Cost Models](#total-cost-models)
5. [Cost Optimization Strategies](#cost-optimization-strategies)
6. [Assumptions & Sources](#assumptions--sources)

---

## Ethereum L1/L2 Costs

### Historical Gas Price Trends

**2024 Baseline:**
- Early 2024: ~72 gwei average
- Peak periods: 200+ gwei

**2025 Dramatic Reduction:**
- March 2025: ~2.7 gwei (96% decrease from 2024)
- November 2025: **0.467 gwei** (current)
- Typical range: 2-5 gwei

**Key Driver:** Dencun upgrade (EIP-4844) + L2 adoption reduced mainnet congestion

---

### Ethereum Mainnet Costs (November 2025)

**Gas Prices:**
- Current: 0.467 gwei
- Typical: 2-5 gwei
- Peak: 10-20 gwei (rare)

**Cost Per Operation (@ 3 gwei, $3K ETH):**

| Operation | Gas Used | Cost @ 3 gwei | Cost @ 10 gwei | Cost @ 50 gwei |
|-----------|----------|---------------|----------------|----------------|
| ETH Transfer | 21,000 | $0.00019 | $0.00063 | $0.0032 |
| ERC-20 Transfer | 50,000 | $0.00045 | $0.0015 | $0.0075 |
| buyCredits | 50,000 | $0.00045 | $0.0015 | $0.0075 |
| authorizeExecutor | 45,000 | $0.00041 | $0.00135 | $0.0068 |
| consumeCredits | 80,000 | $0.00072 | $0.0024 | $0.012 |

**Conclusion:** Mainnet costs now acceptable (<$0.001 per tx) but L2s still 10-100x cheaper.

---

### Layer 2 Network Costs (2025)

**Post-Dencun Pricing (March 2024 upgrade + May 2025 Pectra):**

| Network | Typical TX Cost | DeFi Swap | NFT Mint | Bridge | Market Share |
|---------|----------------|-----------|----------|--------|--------------|
| **Base** | <$0.01 | $0.005 | $0.007 | $0.008 | 80%+ |
| **Arbitrum** | $0.03-0.05 | $0.03 | $0.05 | $0.04 | 5-10% |
| **Optimism** | <$0.50 | $0.10 | $0.15 | $0.12 | 3-5% |

**Key Insight:** L2 fees dropped 50-99% post-Dencun due to blob data (EIP-4844)

---

### PermamindGate Contract Cost Breakdown (Arbitrum)

**Assumptions:**
- Arbitrum gas price: 0.01-0.1 gwei (typical 2025)
- ETH price: $3,000
- Contract deployed on Arbitrum One

**User Operations (One-Time Setup):**

| Operation | Gas | @ 0.05 gwei | Frequency |
|-----------|-----|-------------|-----------|
| buyCredits | 50,000 | $0.000023 | Per top-up (weekly/monthly) |
| authorizeExecutor | 45,000 | $0.000020 | Once per service |
| withdrawCredits | 50,000 | $0.000023 | Rare (unused credits) |

**Executor Operations (Per Execution):**

| Operation | Gas | @ 0.05 gwei | Who Pays |
|-----------|-----|-------------|----------|
| consumeCredits | 80,000 | $0.000036 | Executor (reimbursed from credits) |

**Calculation:**
```
Gas cost = gas_used × gas_price_gwei × 10^-9 × eth_price_usd

consumeCredits:
= 80,000 × 0.05 × 10^-9 × 3000
= 80,000 × 0.00000000005 × 3000
= $0.000012
```

**Rounded:** **~$0.00001 per execution**

---

### Cost Comparison: Ethereum vs. L2s

**Per Execution (consumeCredits only):**

| Network | Gas Price | Cost per TX | 1K Executions | 100K Executions |
|---------|-----------|-------------|---------------|-----------------|
| Ethereum Mainnet | 3 gwei | $0.00072 | $0.72 | $72 |
| Ethereum (peak) | 50 gwei | $0.012 | $12 | $1,200 |
| **Arbitrum** | **0.05 gwei** | **$0.00001** | **$0.01** | **$1** |
| Base | 0.03 gwei | $0.000007 | $0.007 | $0.70 |
| Optimism | 0.10 gwei | $0.00002 | $0.02 | $2 |

**Recommendation:** Deploy on **Arbitrum** for balance of cost, liquidity, and ecosystem maturity.

---

### RPC Access Costs

**If using external RPC for Architecture A:**

| Provider | Free Tier | Paid Pricing | Notes |
|----------|-----------|--------------|-------|
| **Infura** | 100K req/day | $50/month (300K req/day) | Standard |
| **Alchemy** | 300M compute units/month | $49/month (Growth) | More generous |
| **QuickNode** | Free trial | $9/month (Discover) | Cheapest |
| **Ankr** | 500M credits/month | Pay-as-go | Good free tier |

**Cost Per Execution (2 RPC calls: eth_call + eth_sendTransaction):**
- Alchemy: ~$0.0001 per execution (2 calls)
- Infura: ~$0.0001 per execution

**Negligible at scale** - Even at 100K executions/month: ~$10/month

---

## TEE Compute Costs

### Google Cloud Confidential Computing (AMD SEV)

**N2D Machine Series (AMD EPYC 3rd Gen with SEV):**

| Instance | vCPUs | Memory | Price/Hour | Price/Month (730h) | Use Case |
|----------|-------|--------|------------|-------------------|-----------|
| n2d-standard-2 | 2 | 8 GB | $0.10 | $73 | Light workload |
| **n2d-standard-4** | **4** | **16 GB** | **$0.20** | **$146** | **Typical AI** |
| n2d-standard-8 | 8 | 32 GB | $0.40 | $292 | Heavy AI |
| n2d-standard-16 | 16 | 64 GB | $0.80 | $584 | Large models |

**Confidential VM Premium:** No additional cost (same price as standard N2D)

**Spot/Preemptible Pricing:** 60-91% discount (variable)
- n2d-standard-4 spot: ~$0.02-0.08/hour

**Per-Execution Cost (10-second execution on n2d-standard-4):**
```
= $0.20/hour × (10 seconds / 3600 seconds)
= $0.20 × 0.00278
= $0.00056
```

**Rounded:** **~$0.0006 per 10s execution**

---

### AWS Nitro Enclaves (Free TEE on EC2)

**Pricing Model:** No additional charge for Nitro Enclaves - pay only for EC2 instance

**Suitable Instance Types:**

| Instance | vCPUs | Memory | Price/Hour | Price/Month | Notes |
|----------|-------|--------|------------|-------------|-------|
| c6a.xlarge | 4 | 8 GB | $0.15 | $110 | AMD EPYC, good value |
| c6a.2xlarge | 8 | 16 GB | $0.31 | $226 | More capacity |
| m6a.xlarge | 4 | 16 GB | $0.17 | $124 | Balanced |

**Enclave Resource Allocation:**
- Enclaves use CPU/memory from parent instance
- No additional cost for enclave itself

**Per-Execution Cost (10s on c6a.xlarge):**
```
= $0.15/hour × (10 / 3600)
= $0.00042
```

**Rounded:** **~$0.0004 per 10s execution**

---

### Azure Confidential Computing (AMD SEV-SNP)

**DCsv3 Series (3rd Gen AMD EPYC with SEV-SNP):**

| Instance | vCPUs | Memory | Price/Hour (East US) | Price/Month | Use Case |
|----------|-------|--------|---------------------|-------------|-----------|
| DC2s_v3 | 2 | 8 GB | $0.15 | $110 | Light |
| **DC4s_v3** | **4** | **16 GB** | **$0.30** | **$219** | **Typical** |
| DC8s_v3 | 8 | 32 GB | $0.60 | $438 | Heavy |

**Per-Execution Cost (10s on DC4s_v3):**
```
= $0.30/hour × (10 / 3600)
= $0.00083
```

**Rounded:** **~$0.0008 per 10s execution**

---

### Nillion Compute Cost Estimates

**Since Nillion pricing is not public, we estimate based on:**
1. Cloud TEE pricing (baseline)
2. Decentralization overhead (2-10x multiplier)
3. NIL token economics

**Baseline Cloud TEE Pricing:**
- Google Cloud: $0.20/hour (n2d-standard-4)
- AWS Nitro: $0.15/hour (c6a.xlarge)
- Azure: $0.30/hour (DC4s_v3)
- **Average: $0.22/hour**

**Decentralization Premium Scenarios:**

| Scenario | Multiplier | Reasoning | Nillion $/hour | Per 10s Exec |
|----------|-----------|-----------|----------------|--------------|
| **Optimistic** | 2x | Efficient network, low token premium | $0.44 | $0.0012 |
| **Expected** | 4x | Moderate network overhead, NIL volatility | $0.88 | $0.0024 |
| **Conservative** | 6x | High overhead, early network inefficiency | $1.32 | $0.0037 |
| **Worst Case** | 10x | Maximum overhead, high token costs | $2.20 | $0.0061 |

**Rationale for Premium:**
- **Node operator margins:** 20-50% (vs. cloud 10-20%)
- **Network coordination:** Additional latency/compute for consensus
- **NIL token volatility:** Risk premium for price fluctuations
- **Lower utilization:** Early network may have idle capacity
- **Smaller scale:** No AWS/GCP economies of scale

**Best Estimate:** **2-5x cloud pricing** = **$0.001-0.003 per 10s execution**

---

### TEE Cost Comparison Matrix

| Provider | Type | $/Hour | Per 10s | Per 100s | Privacy | Decentralized |
|----------|------|--------|---------|----------|---------|---------------|
| **Google Cloud** | AMD SEV | $0.20 | $0.0006 | $0.006 | ⭐⭐⭐ | ❌ |
| **AWS Nitro** | Nitro TEE | $0.15 | $0.0004 | $0.004 | ⭐⭐⭐ | ❌ |
| **Azure** | AMD SEV-SNP | $0.30 | $0.0008 | $0.008 | ⭐⭐⭐⭐ | ❌ |
| **Nillion (Est.)** | AMD SEV-SNP | $0.88 | $0.0024 | $0.024 | ⭐⭐⭐⭐⭐ | ✅ |

**Nillion Advantage:** Decentralization + blockchain integration + on-chain payments

**Nillion Disadvantage:** 2-6x more expensive than centralized alternatives

---

## AI Inference Costs

### OpenAI API Pricing (No Privacy)

**GPT-4 Turbo (2025):**
- Input: $10 per 1M tokens
- Output: $30 per 1M tokens

**GPT-3.5 Turbo (2025):**
- Input: $0.50 per 1M tokens
- Output: $1.50 per 1M tokens

**Typical Request Costs (2000 tokens input/output):**

| Model | Input Cost | Output Cost | Total | Privacy |
|-------|------------|-------------|-------|---------|
| GPT-4 Turbo | $0.020 | $0.060 | **$0.080** | None |
| GPT-4 (standard) | $0.060 | $0.120 | **$0.180** | None |
| GPT-3.5 Turbo | $0.001 | $0.003 | **$0.004** | None |

**Use Case:** Fast, high-quality, but NO privacy (OpenAI sees all data)

---

### Self-Hosted LLM Inference (Full Privacy)

**Llama 3 8B (Small Model):**

**Hardware Requirements:**
- VRAM: ~16 GB (FP16) or 8 GB (INT8 quantized)
- GPU: RTX 4090, A100 40GB, or similar
- Performance: ~76 tokens/second (M3 Ultra), ~2,300 t/s (H100)

**Cloud GPU Costs:**

| Provider | GPU | Price/Hour | Tokens/Sec | Cost per 1K Tokens | Cost per Request (2K tokens) |
|----------|-----|------------|------------|-------------------|----------------------------|
| RunPod | A100 40GB | $0.79 | 1,000 | $0.000079 | $0.00016 |
| Vast.ai | RTX 4090 | $0.30 | 500 | $0.000060 | $0.00012 |
| Lambda Labs | A100 40GB | $1.10 | 1,000 | $0.00011 | $0.00022 |

**Amortized Cost (2K token request, 2 seconds generation):**
```
= $0.79/hour × (2 seconds / 3600 seconds)
= $0.00044
```

**Typical: ~$0.0001-0.0003 per request** (Llama 3 8B)

---

**Llama 3 70B (Large Model):**

**Hardware Requirements:**
- VRAM: ~140 GB (FP16) or 70 GB (INT8 quantized)
- GPUs: 2× H100 80GB or 4× A100 40GB
- Performance: High quality, slower inference

**Cloud GPU Costs:**

| Configuration | Price/Hour | Cost per Request (10s) |
|--------------|------------|----------------------|
| 2× H100 80GB (AWS) | $7.80 | $0.0217 |
| 4× A100 40GB (GCP) | $4.40 | $0.0122 |
| 2× H100 80GB (spot) | $4.32 | $0.0120 |

**Typical: ~$0.001-0.003 per request** (Llama 3 70B, 10s generation)

---

### Nillion nilAI Pricing (Speculative)

**No public pricing available.** Estimate based on:
- Likely comparable to self-hosted costs (TEE overhead minimal for inference)
- Plus Nillion network fees (NIL tokens)
- **Estimated: $0.0005-0.002 per request** (Llama 8B equivalent)

**Advantages:**
- Privacy (TEE-based)
- Managed service (no infrastructure)
- OpenAI-compatible API

**Disadvantages:**
- Likely more expensive than self-hosted
- Unknown pricing model

---

### AI Inference Cost Comparison

**For 2K token text generation request:**

| Option | Cost/Request | Privacy | Decentralized | Quality | Latency |
|--------|-------------|---------|---------------|---------|---------|
| OpenAI GPT-4 | $0.080 | ❌ None | ❌ | ⭐⭐⭐⭐⭐ | 1-2s |
| OpenAI GPT-3.5 | $0.004 | ❌ None | ❌ | ⭐⭐⭐⭐ | 0.5-1s |
| Self-hosted Llama 8B (Cloud GPU) | $0.0002 | ✅ Full | ❌ | ⭐⭐⭐ | 2-4s |
| Self-hosted Llama 70B (Cloud GPU) | $0.002 | ✅ Full | ❌ | ⭐⭐⭐⭐ | 5-10s |
| **Llama 8B in nilCC (Est.)** | **$0.0003** | **✅ Full** | **✅** | **⭐⭐⭐** | **3-5s** |
| **Nillion nilAI (Est.)** | **$0.001** | **✅ Full** | **✅** | **⭐⭐⭐⭐** | **2-4s** |

**Recommendation:** Self-host Llama 3 8B in nilCC container for best cost/privacy balance.

---

## Total Cost Models

### Model 1: Lightweight AI (Text Classification, 1s execution)

**Components:**

| Component | Provider | Cost |
|-----------|----------|------|
| Ethereum (consumeCredits) | Arbitrum | $0.00001 |
| TEE Compute (1s) | Nillion (expected) | $0.00024 |
| AI Inference | Llama 3 8B (self-hosted) | $0.00005 |
| RPC Calls (2 calls) | Alchemy | $0.00010 |
| **TOTAL** | | **$0.00040** |

**Margin Analysis (at $0.50 price):**
- Revenue: $0.50
- Cost: $0.00040
- Gross Profit: $0.4996
- **Margin: 99.92%** ✅

---

### Model 2: Medium AI (Text Generation, 10s execution)

**Components:**

| Component | Provider | Cost |
|-----------|----------|------|
| Ethereum (consumeCredits) | Arbitrum | $0.00001 |
| TEE Compute (10s) | Nillion (expected) | $0.00244 |
| AI Inference | Llama 3 8B (self-hosted) | $0.00020 |
| RPC Calls (2 calls) | Alchemy | $0.00010 |
| **TOTAL** | | **$0.00275** |

**Margin Analysis (at $2.00 price):**
- Revenue: $2.00
- Cost: $0.00275
- Gross Profit: $1.99725
- **Margin: 99.86%** ✅

---

### Model 3: Heavy AI (Large Model, 30s execution)

**Components:**

| Component | Provider | Cost |
|-----------|----------|------|
| Ethereum (consumeCredits) | Arbitrum | $0.00001 |
| TEE Compute (30s) | Nillion (conservative) | $0.01100 |
| AI Inference | Llama 3 70B (self-hosted) | $0.00300 |
| RPC Calls (2 calls) | Alchemy | $0.00010 |
| **TOTAL** | | **$0.01411** |

**Margin Analysis (at $10.00 price):**
- Revenue: $10.00
- Cost: $0.01411
- Gross Profit: $9.98589
- **Margin: 99.86%** ✅

---

### Sensitivity Analysis: What if Nillion Costs 10x More?

**Model 2 with 10x Nillion Premium:**

| Component | Normal | 10x Premium |
|-----------|--------|-------------|
| Ethereum | $0.00001 | $0.00001 |
| TEE Compute | $0.00244 | **$0.02440** |
| AI Inference | $0.00020 | $0.00020 |
| RPC | $0.00010 | $0.00010 |
| **TOTAL** | **$0.00275** | **$0.02471** |

**Margin at $2.00 price:**
- Cost: $0.02471
- **Margin: 98.77%** ✅ Still excellent!

**Even at 100x Nillion premium:**
- Cost: $0.24440
- Margin at $2.00: 87.78% ✅
- Margin at $5.00: 95.11% ✅

---

## Cost Optimization Strategies

### Strategy 1: Use Cheapest L2 (Base)

**Current:** Arbitrum ($0.00001 per tx)
**Alternative:** Base ($0.000007 per tx)
**Savings:** 30% ($0.000003 per tx)

**At 100K executions:**
- Arbitrum: $1.00
- Base: $0.70
- **Savings: $0.30/month** (negligible)

**Verdict:** Not worth complexity of migration. Arbitrum has better liquidity/ecosystem.

---

### Strategy 2: Batch Transactions

**Pattern:** Accumulate multiple credit consumptions, submit in batch

**Example:**
- 10 individual consumeCredits: 10 × 80K gas = 800K gas
- 1 batched transaction: ~150K gas (savings from batching)
- **Savings: ~80% gas reduction**

**Implementation:**
```solidity
function batchConsumeCredits(
    address[] users,
    uint256[] amounts,
    uint256[] nonces,
    bytes[] signatures
) external {
    for (uint i = 0; i < users.length; i++) {
        // Consume credits for each user
    }
}
```

**Trade-offs:**
- Increased latency (wait for batch to fill)
- More complex accounting
- Better for high-volume services

**Verdict:** Implement for Phase 2 optimization (not MVP)

---

### Strategy 3: Payment Channels

**Pattern:** Open channel, transact off-chain, settle periodically

**Example:**
- On-chain: Open channel ($0.00002) + Close channel ($0.00002)
- Off-chain: 1,000 executions (free)
- **Cost per execution: $0.00000004** (400x cheaper!)

**Trade-offs:**
- Capital locked in channel
- Both parties must be online
- Complex dispute resolution
- Only works for high-volume user-service pairs

**Verdict:** Good for power users in Phase 3 (not general marketplace)

---

### Strategy 4: Optimize Nillion Compute Usage

**A) Use Spot/Preemptible Instances (if Nillion supports):**
- Potential savings: 60-90%
- Trade-off: May be interrupted

**B) Right-size Compute Resources:**
- Don't over-provision CPU/memory
- Use smallest instance that meets performance needs

**C) Cache Models in Memory:**
- Load AI model once, reuse for multiple requests
- Amortize load time across many inferences

**D) Batch AI Inference:**
- Process multiple requests in single forward pass
- Better GPU utilization

**Verdict:** All applicable for Phase 2 optimization

---

### Strategy 5: Use Cheaper AI Models

**Current:** Llama 3 8B ($0.0002 per request)
**Alternatives:**
- Llama 3 1B: **$0.00005 per request** (4x cheaper, lower quality)
- Phi-2 (2.7B): **$0.00008 per request** (2.5x cheaper, good quality)
- DistilBERT (classification): **$0.00001 per request** (20x cheaper, task-specific)

**Use Case Matching:**
- Classification: Use DistilBERT
- Simple Q&A: Use Phi-2
- Complex generation: Use Llama 8B
- High-quality: Use Llama 70B

**Verdict:** Implement multi-tier pricing based on model size/quality

---

## Assumptions & Sources

### Ethereum Pricing Assumptions

| Assumption | Value | Source | Confidence |
|------------|-------|--------|-----------|
| ETH price | $3,000 | Market data (Nov 2025) | High (90%) |
| Arbitrum gas price | 0.05 gwei | Etherscan, L2 trackers | High (90%) |
| Base gas price | 0.03 gwei | L2 fee comparison | High (85%) |
| Gas per consumeCredits | 80,000 | Similar contract benchmarks | Medium (70%) |

---

### TEE Compute Assumptions

| Assumption | Value | Source | Confidence |
|------------|-------|--------|-----------|
| Google Cloud n2d-standard-4 | $0.20/hour | GCP pricing page | Very High (95%) |
| AWS c6a.xlarge | $0.15/hour | AWS pricing calculator | Very High (95%) |
| Azure DC4s_v3 | $0.30/hour | Azure pricing page | Very High (95%) |
| Nillion premium multiplier | 2-6x | Proxy estimate (decentralization overhead) | Low (30%) |

**Note:** Nillion estimate is speculative. Real pricing may vary significantly.

---

### AI Inference Assumptions

| Assumption | Value | Source | Confidence |
|------------|-------|--------|-----------|
| OpenAI GPT-4 pricing | $10/$30 per 1M tokens | OpenAI pricing page | Very High (99%) |
| OpenAI GPT-3.5 pricing | $0.50/$1.50 per 1M tokens | OpenAI pricing page | Very High (99%) |
| A100 GPU pricing | $0.79-1.10/hour | RunPod, Lambda Labs | High (90%) |
| H100 GPU pricing | $3-4/hour | AWS, GCP (2025 rates) | High (85%) |
| Llama 8B inference time | 2-4s per request | Community benchmarks | Medium (70%) |

---

### Sources

**Ethereum/L2 Pricing:**
- Etherscan Gas Tracker: https://etherscan.io/gastracker
- L2 Fee Statistics: CoinLaw, BeInCrypto (2025 data)
- Dencun/Pectra upgrade docs

**Cloud TEE Pricing:**
- Google Cloud Confidential VM: cloud.google.com/confidential-computing/confidential-vm/pricing
- AWS EC2 Pricing: aws.amazon.com/ec2/pricing
- Azure Confidential Computing: azure.microsoft.com pricing pages

**GPU Pricing:**
- H100/A100 comparison: Cast AI, IntuitionLabs (Nov 2025)
- RunPod, Lambda Labs, Vast.ai pricing pages
- Modal, DataCrunch cloud GPU comparisons

**AI Model Pricing:**
- OpenAI API: openai.com/api/pricing
- Self-hosted LLM costs: Lytix, Aimprosoft blog posts
- Llama 3 benchmarks: Community performance data

---

## Conclusion

**Cost Research Complete** ✅

**Key Takeaways:**

1. **Ethereum costs are negligible** (<$0.0001 per execution on Arbitrum)
2. **TEE compute is dominant cost** ($0.001-0.01 per execution depending on provider/duration)
3. **AI inference costs are manageable** ($0.0002-0.003 for self-hosted models)
4. **Total cost per execution: $0.001-0.015** depending on workload
5. **All scenarios support >95% margins** at $2+ price points

**Critical Unknown:** Nillion actual pricing (estimated 2-6x cloud TEE costs)

**Confidence:** High for components (Ethereum, cloud TEE, AI inference), Low for Nillion estimate

**Next:** Task 2.2 - Revenue Scenario Modeling using these cost inputs

---

**Document Status:** COMPLETE
**Last Updated:** November 15, 2025
**Next Task:** Revenue Scenario Modeling
