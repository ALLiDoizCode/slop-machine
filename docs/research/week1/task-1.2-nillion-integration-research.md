# Task 1.2: Nillion Integration Research

**Research Date:** November 15, 2025
**Status:** Documentation Review Complete - Awaiting Team Response
**Researcher:** Research Phase - Week 1

---

## Executive Summary

This document analyzes Nillion's nilCC platform capabilities for integrating with Ethereum-based payment gating. Based on documentation review, we have identified the platform's core capabilities and key unknowns that require direct engagement with the Nillion team.

**Key Findings:**
- ✅ **nilCC supports Docker Compose** - Standard containerized workloads with TEE isolation
- ✅ **RESTful API available** - For workload deployment and management
- ✅ **Cryptographic attestation** - Hardware-guaranteed privacy verification
- ❓ **External HTTP calls unclear** - Need confirmation containers can call Ethereum RPC
- ❓ **Pricing not public** - Cost structure requires team inquiry
- ❓ **Payment gating examples missing** - No reference implementations found

**Next Steps:**
1. Contact Nillion team via Discord/GitHub
2. Schedule technical consultation
3. Get answers to 5 critical questions (below)
4. Obtain cost estimates and sample code

---

## Table of Contents

1. [Research Objectives](#research-objectives)
2. [Documentation Review](#documentation-review)
3. [Critical Questions for Nillion Team](#critical-questions-for-nillion-team)
4. [Outreach Strategy](#outreach-strategy)
5. [Preliminary Architecture Analysis](#preliminary-architecture-analysis)
6. [Risk Assessment](#risk-assessment)
7. [Next Steps](#next-steps)

---

## Research Objectives

### Primary Questions to Answer

1. **Can nilCC containers make HTTP calls to external Ethereum RPC endpoints?**
2. **What's the recommended pattern for external contract verification from TEEs?**
3. **Are there existing examples of payment-gated Nillion programs?**
4. **What are the actual compute costs (per second, per CPU/memory)?**
5. **Can attestation be verified by Ethereum smart contracts for executor authorization?**

---

## Documentation Review

### What We Know: Nillion Architecture

#### 1. Core Components

**nilChain (Coordination Layer)**
- Cosmos SDK-based blockchain
- Manages payments and subscriptions via NIL token
- Coordinates inter-cluster operations
- **Does NOT support smart contract execution** (payment coordination only)

**nilCC (Confidential Compute)**
- General-purpose TEE platform (AMD SEV-SNP)
- Deploys Docker Compose workloads
- RESTful API for management
- Automatic TEE provisioning, isolation, TLS, attestation
- **API Endpoint:** https://api.nilcc.nillion.network
- **OpenAPI Spec:** https://api.nilcc.nillion.network/openapi.json

**nilDB (Private Storage)**
- Encrypted NoSQL database
- Data split into secret shares across ~3 nodes
- Accessed via Secretvaults SDK (TypeScript/Python)
- Supports symmetric encryption, HE, or MPC

**nilAI (Private LLMs)**
- LLMs running in TEEs
- OpenAI-compatible API
- Private inference (provider can't see data)
- User selects specific node for execution

---

#### 2. Payment Model

**NIL Token System:**
- Native cryptocurrency for ALL services
- Subscriptions purchased via nilPay platform
- Testnet tokens available via faucet
- **No public mainnet pricing documentation found**

**Developer Flow:**
1. Create Nillion wallet
2. Get NIL tokens (testnet: faucet, mainnet: purchase)
3. Subscribe to services (nilDB, nilAI) via nilPay
4. For nilCC: Request API key via application form

---

#### 3. Developer Tools

- **Collection Explorer** - No-code schema/collection management
- **Secretvaults SDKs** - TypeScript (NPM) and Python (PyPI) for nilDB
- **nilCC Workload Manager** - Visual workload creation UI
- **Network Status Dashboard** - Real-time testnet/mainnet monitoring
- **GitHub Discussions** - Primary developer support channel
- **Discord** - Community and ticket-based support

---

#### 4. Ethereum Integration Status

**Nillion 2.0 Announcement (Uncertain Timeline):**
- Ethereum L2 deployment planned
- Ethereum bridge for cross-chain functionality
- **Conflicting timelines in sources:**
  - Some sources: February 2025
  - Other sources: February 2026
- Bridge will enable:
  - ERC-20 NIL token migration
  - Staking on Ethereum
  - On-chain coordination
  - Seamless access to compute/storage layer

**Current State:**
- No documented Ethereum integration yet
- No smart contract examples found
- No cross-chain patterns documented

---

### What We Don't Know (Critical Gaps)

#### 1. External Network Access from nilCC

**Question:** Can Docker containers running in nilCC make outbound HTTP/HTTPS calls to external APIs (specifically Ethereum RPC endpoints)?

**Why Critical:** Our architecture requires containers to:
- Call Ethereum RPC to verify credit balance
- Verify user signatures via eth_call
- Submit consumeCredits transactions

**Documentation Status:** Not addressed in public docs

**Fallback Options:**
- Push-based: Ethereum → Nillion relay (requires bridge)
- Oracle service: Separate service queries Ethereum and provides signed proofs to nilCC
- Wait for Ethereum L2 (may simplify integration)

---

#### 2. Compute Pricing

**Question:** What is the actual cost structure for nilCC compute?
- Per second?
- Per CPU core?
- Per GB memory?
- Flat rate per workload?
- Tiered by resource usage?

**Why Critical:** Need to calculate total cost per execution to validate 30%+ margin requirement (Week 2).

**Documentation Status:** Not publicly available

**Known:** NIL token used for payment, but conversion rate to compute resources unknown

---

#### 3. Payment Gating Reference Implementations

**Question:** Does Nillion have examples or templates for payment-gated services?

**Why Critical:**
- Avoid reinventing the wheel
- Learn best practices
- Reduce development risk

**Documentation Status:** No examples found in docs or GitHub

---

#### 4. Attestation Verification by Smart Contracts

**Question:** Can Ethereum smart contracts verify nilCC TEE attestation reports?

**Use Case:** Executor authorization pattern where:
1. Nillion executor generates attestation proving code running in TEE
2. Ethereum smart contract verifies attestation
3. Contract grants executor permission to consume credits

**Why Critical:** Enhances security model - users trust TEE hardware, not individual executors

**Documentation Status:** Not addressed

**Alternative:** Off-chain attestation verification, publish executor public key on-chain

---

#### 5. Compute Limits and Constraints

**Questions:**
- Maximum execution time per workload?
- Memory limits per container?
- CPU allocation model?
- Network bandwidth limits?
- Storage limits?
- Number of containers per workload?

**Why Critical:** Determine if nilCC can support typical AI inference workloads (e.g., Llama 70B requires ~140GB RAM)

**Documentation Status:** Not publicly documented

---

## Critical Questions for Nillion Team

### Tier 1: Must-Have Answers (Blockers)

#### Q1: External API Access from nilCC Containers

**Question:**
> Can Docker containers running in nilCC make outbound HTTP/HTTPS calls to external services, specifically Ethereum RPC endpoints (e.g., Infura, Alchemy)?
>
> If yes:
> - Are there any restrictions on which domains/IPs can be accessed?
> - What is the typical latency overhead for external calls?
> - Are there rate limits or bandwidth constraints?
>
> If no:
> - What is the recommended pattern for integrating external blockchain state into nilCC workloads?
> - Are there plans to support external API access?

**Why Critical:** Our architecture depends on Ethereum RPC calls for payment verification.

---

#### Q2: nilCC Compute Pricing

**Question:**
> What is the cost structure for nilCC compute resources?
>
> Specifically:
> - How is compute usage measured? (per second, per CPU core, per GB RAM, etc.)
> - What is the conversion rate from NIL tokens to compute units?
> - Are there example cost calculations for typical workloads?
> - Is there a pricing tier for different resource levels (CPU, memory)?
> - What is the expected pricing on mainnet (if different from testnet)?

**Why Critical:** Need concrete numbers to build economic model (Week 2 research).

---

#### Q3: Payment-Gated Service Patterns

**Question:**
> Are there existing examples or recommended patterns for implementing payment-gated services on Nillion?
>
> Specifically interested in:
> - M2M micropayment patterns
> - Executor authorization mechanisms
> - Integration with external payment layers (Ethereum, etc.)
> - Refund/dispute resolution patterns
>
> If no examples exist, would the Nillion team be interested in collaborating on developing this pattern?

**Why Critical:** Avoid architectural mistakes, learn best practices.

---

### Tier 2: Important for Design

#### Q4: TEE Attestation and Ethereum Integration

**Question:**
> Can attestation reports from nilCC TEEs be verified by Ethereum smart contracts?
>
> Specifically:
> - What format are attestation reports (AMD SEV-SNP)?
> - Is there a Solidity library for verifying attestation?
> - What is the gas cost of on-chain attestation verification?
> - Can attestation be used to authorize specific executors on-chain?

**Why Critical:** Enables trustless executor authorization model.

---

#### Q5: Resource Limits and Constraints

**Question:**
> What are the resource limits for nilCC workloads?
>
> Specifically:
> - Maximum execution time (timeout)?
> - Maximum memory per container?
> - CPU allocation model (cores, throttling)?
> - Network bandwidth limits?
> - Persistent storage limits?
> - Maximum number of containers in a Docker Compose workload?

**Why Critical:** Determine if platform can handle our use cases (AI inference, data processing).

---

### Tier 3: Nice-to-Have

#### Q6: Ethereum L2 Timeline and Design

**Question:**
> Can you clarify the timeline for Nillion's Ethereum L2 launch?
>
> Conflicting sources indicate:
> - February 2025 (some sources)
> - February 2026 (other sources)
>
> Also:
> - Will the L2 enable direct smart contract coordination with nilCC?
> - What will the bridge architecture look like?
> - Should developers wait for L2 before building Ethereum integrations?

**Why Critical:** May significantly simplify our architecture if launching soon.

---

#### Q7: Developer Support and Early Access

**Question:**
> Is there a program for developers building novel use cases on Nillion?
>
> Specifically:
> - Technical consultation or office hours?
> - Early access to new features (Ethereum bridge, etc.)?
> - Grants or ecosystem funding?
> - Co-marketing opportunities?

**Why Helpful:** Accelerate development, reduce risk, potential funding.

---

## Outreach Strategy

### Primary Channels

1. **Discord** (Highest Priority)
   - Link: https://discord.com/invite/nillionnetwork
   - Action: Join server, create support ticket
   - Questions: All Tier 1 + Tier 2
   - Timeline: Send within 24 hours

2. **GitHub Discussions** (Technical Discussion)
   - Link: https://github.com/orgs/NillionNetwork/discussions
   - Action: Create discussion thread
   - Questions: Q1, Q3 (with code examples)
   - Timeline: Send within 48 hours

3. **Nucleus Builder Program** (If Available)
   - Link: https://nucleus.nillion.com
   - Action: Apply for builder program
   - Questions: All Tier 3
   - Timeline: Apply within 1 week

---

### Outreach Template: Discord Ticket

```
Subject: Payment-Gated M2M AI Services on Nillion - Technical Questions

Hello Nillion team! 👋

I'm researching Nillion as the foundation for a payment-gated M2M AI marketplace and have some technical questions about nilCC integration with Ethereum.

**Project Context:**
Building a marketplace where:
- AI processes run in nilCC (privacy-preserving execution)
- Payments managed via Ethereum smart contracts (micropayments)
- Need atomic payment → execution flow
- Target: 30%+ margins at scale

**Critical Questions:**

1. **External API Access**: Can nilCC containers make HTTP calls to Ethereum RPC endpoints (Infura/Alchemy) for payment verification?

2. **Pricing**: What is the cost structure for nilCC compute? (per second, per CPU, per GB RAM?) Need concrete numbers to build economic model.

3. **Payment Gating Patterns**: Any existing examples of payment-gated services on Nillion? Interested in M2M micropayment patterns.

4. **TEE Attestation**: Can Ethereum smart contracts verify nilCC attestation reports for executor authorization?

5. **Resource Limits**: What are max execution time, memory, CPU limits for nilCC workloads?

**Timeline:**
Conducting 4-week research sprint to evaluate Nillion vs. alternatives. Week 1 deadline approaching!

**Documentation Reviewed:**
- docs.nillion.com/llm.txt
- nilCC API docs
- GitHub repos

**Request:**
Would greatly appreciate answers to Q1-3 (blockers) and potentially a technical consultation call if available.

Happy to share our architecture design and collaborate on developing payment gating patterns for the Nillion ecosystem.

Thanks!
[Your Name]
[Email/Contact]
```

---

### Outreach Template: GitHub Discussion

```markdown
# Payment-Gated Services on Nillion: Architecture Questions

## Context

Exploring Nillion for building a payment-gated M2M AI marketplace with the following architecture:

**Ethereum Layer (Payment):**
- Smart contract manages credits, executor authorization
- Users deposit ETH → buy credits
- Executors consume credits for service execution

**Nillion Layer (Execution):**
- nilCC containers run AI services in TEEs
- Containers verify payment before execution
- Results returned only if payment succeeds

## Critical Technical Question

**Can nilCC containers make outbound HTTP calls to Ethereum RPC endpoints?**

Our proposed flow:
1. User sends signed request to nilCC service
2. Container verifies signature
3. **Container calls Ethereum RPC** (e.g., `eth_call` to check credits)
4. If credits available, execute service
5. Container submits Ethereum transaction to consume credits
6. Return result to user

## Questions for Community

1. Has anyone successfully made external HTTP calls from nilCC containers?
2. Are there examples of blockchain integration with nilCC workloads?
3. What's the recommended pattern for external state verification in TEEs?

## Alternative Architectures (If HTTP Not Supported)

**Option A:** Oracle pattern
- External service queries Ethereum, provides signed proofs
- nilCC container verifies proofs (no direct HTTP needed)

**Option B:** Push-based
- Ethereum → Nillion relay when payment received
- nilCC polls Nillion network for payment confirmations

**Option C:** Wait for Ethereum L2
- Use Nillion's upcoming Ethereum L2 for simpler integration

Which approach would the Nillion team recommend?

## Goal

Build reference implementation for payment-gated services on Nillion to share with community.

Thanks for any guidance!
```

---

## Preliminary Architecture Analysis

### Based on Current Knowledge

#### Scenario A: External HTTP Calls Supported

If nilCC containers CAN make HTTP calls to Ethereum RPC:

```
┌─────────────────────────────────────────────┐
│         ETHEREUM (ARBITRUM L2)              │
│                                             │
│   ┌────────────────────────────────┐       │
│   │  PermamindGate Smart Contract   │       │
│   │  • creditBalance[user][service] │       │
│   │  • authorized[user][service]    │       │
│   └────────────────────────────────┘       │
│              ▲             ▲                │
│              │             │                │
│         (3) Check    (5) Consume            │
│           Credits      Credits              │
└──────────────┼─────────────┼────────────────┘
               │             │
               │             │
┌──────────────▼─────────────▼────────────────┐
│         NILLION nilCC (TEE)                 │
│                                             │
│   ┌────────────────────────────────┐       │
│   │  Docker Container (Service)     │       │
│   │                                 │       │
│   │  1. Receive request + signature │       │
│   │  2. Verify signature (user)     │       │
│   │  3. HTTP → Ethereum RPC         │◄──┐   │
│   │     eth_call(getBalance)        │   │   │
│   │  4. Check balance >= price      │   │   │
│   │  5. HTTP → Ethereum RPC         │   │   │
│   │     eth_sendTransaction(consume)│───┘   │
│   │  6. Execute AI service          │       │
│   │  7. Return result               │       │
│   └────────────────────────────────┘       │
└─────────────────────────────────────────────┘
```

**Pros:**
- Direct verification (no intermediaries)
- Atomic payment → execution
- Simple architecture

**Cons:**
- Cross-chain latency (~1-2 seconds for RPC calls)
- Race condition risk (balance changes between check and consume)
- Depends on Ethereum RPC reliability

**Mitigation:**
- User signature authorizes specific amount (prevents race)
- Nonce prevents replay attacks
- Retry logic for RPC failures

---

#### Scenario B: External HTTP Calls NOT Supported

If nilCC containers CANNOT make external calls, use **Oracle Pattern**:

```
┌──────────────────────────────────┐
│     ETHEREUM (ARBITRUM L2)       │
│                                  │
│  ┌───────────────────────────┐  │
│  │ PermamindGate Contract     │  │
│  └───────────────────────────┘  │
│              ▲                   │
│              │                   │
└──────────────┼───────────────────┘
               │
               │
┌──────────────▼───────────────────┐
│    ORACLE SERVICE                │
│    (Off-chain, Trusted)          │
│                                  │
│  1. Query Ethereum state         │
│  2. Sign payment proof           │
│  3. Send proof to nilCC          │
└──────────────┬───────────────────┘
               │
               │ Signed Proof
               │
┌──────────────▼───────────────────┐
│    NILLION nilCC (TEE)           │
│                                  │
│  1. Receive proof + request      │
│  2. Verify oracle signature      │
│  3. Check proof validity         │
│  4. Execute if proof valid       │
│  5. Return result                │
└──────────────────────────────────┘
```

**Pros:**
- No external HTTP dependency
- Oracle can batch proofs (efficiency)
- TEE still verifies proofs (trustless oracle)

**Cons:**
- Adds oracle dependency (new infrastructure)
- Oracle must be trusted or decentralized
- Additional latency for oracle query

**Oracle Implementation:**
- Centralized: Simple, fast, but trust required
- Decentralized: Chainlink-style, slower but trustless
- Hybrid: TEE-based oracle (Nillion nodes could run it)

---

### Recommended Approach (Pending Team Response)

**Phase 1:** Research (This Week)
- Get answer from Nillion team on HTTP support
- If HTTP supported → proceed with direct RPC pattern
- If not supported → design oracle service

**Phase 2:** Prototype (Week 2-3)
- Implement chosen pattern on testnet
- Measure latency and costs
- Validate security properties

**Phase 3:** Production (Week 4+)
- Deploy on Arbitrum + Nillion mainnet
- Security audit
- Launch MVP

---

## Risk Assessment

### Technical Risks

#### Risk 1: External API Access Not Supported (HIGH)

**Impact:** Architecture requires major redesign (oracle pattern)

**Probability:** Medium (not documented either way)

**Mitigation:**
- Ask Nillion team immediately
- Design oracle fallback in parallel
- Test on testnet ASAP

---

#### Risk 2: Compute Costs Too High (HIGH)

**Impact:** Cannot achieve 30%+ margin, pivot required

**Probability:** Unknown (no pricing data)

**Mitigation:**
- Get pricing from team
- Model scenarios (Week 2)
- Compare to alternatives (AWS, Azure, GCP TEE pricing as proxy)

**Proxy Estimate (Google Cloud Confidential VM):**
- n2d-standard-4 (4 vCPU, 16GB RAM, AMD SEV): ~$0.20/hour
- For 10-second execution: ~$0.0006 per request
- Nillion likely higher (decentralized network overhead)

---

#### Risk 3: Ethereum L2 Delays Architecture (MEDIUM)

**Impact:** May want to wait for L2 instead of building complex bridge

**Probability:** Unknown (conflicting timelines)

**Mitigation:**
- Clarify timeline with team
- Build MVP with current architecture
- Design for L2 migration path

---

#### Risk 4: Resource Limits Too Restrictive (MEDIUM)

**Impact:** Cannot run larger AI models, limits use cases

**Probability:** Low-Medium

**Mitigation:**
- Get limits from team
- Test with actual workload on testnet
- Use nilAI for LLMs (instead of self-hosted)

---

### Business Risks

#### Risk 5: No Pricing Transparency (MEDIUM)

**Impact:** Cannot accurately forecast costs, business plan uncertain

**Probability:** High (current state)

**Mitigation:**
- Demand pricing before major investment
- Build cost contingency into model
- Have fallback architecture (AO, centralized TEE)

---

#### Risk 6: Lack of Developer Examples (LOW)

**Impact:** Slower development, more trial-and-error

**Probability:** High (no examples found)

**Mitigation:**
- Engage Nillion team for guidance
- Build and open-source reference implementation
- Leverage Nucleus builder program if available

---

## Next Steps

### Immediate Actions (This Week)

1. **Send Discord Ticket** (Today)
   - Use template above
   - Include all Tier 1 + Tier 2 questions
   - Request technical consultation call

2. **Post GitHub Discussion** (Tomorrow)
   - Focus on Q1 (external HTTP access)
   - Invite community input
   - Share proposed architecture diagrams

3. **Apply to Nucleus Program** (If Available)
   - Check https://nucleus.nillion.com
   - Submit application with project description
   - Request grants/funding information

4. **Monitor for Responses** (Daily)
   - Check Discord, GitHub, email
   - Compile responses into decision document
   - Update architecture based on answers

---

### Follow-Up Actions (Next Week)

5. **Schedule Technical Call** (If Offered)
   - Prepare detailed architecture diagrams
   - Bring specific code questions
   - Ask about partnership opportunities

6. **Deploy Test Workload** (If Feasible)
   - Simple Docker container on nilCC testnet
   - Test external HTTP calls manually
   - Measure latency and costs

7. **Update Research Documents**
   - Incorporate team responses
   - Revise architecture (Task 1.3)
   - Update cost projections (Task 1.4, Week 2)

---

### Decision Timeline

**Day 3-4:** Receive responses from Nillion team

**Day 5:**
- If HTTP supported → proceed with direct RPC pattern
- If not supported → design oracle service
- If pricing too high → red flag for economics (Week 2)

**Day 6-7:**
- Complete Task 1.3 (Service Architecture Design)
- Complete Task 1.4 (Performance Analysis)
- Produce Week 1 final report

**End of Week 1:**
- **GO/NO-GO decision on Nillion viability**
- If blockers exist, pivot to alternatives research

---

## Appendix: Comparison to Alternatives

While waiting for Nillion team response, researching backup options:

### Alternative 1: AWS Nitro Enclaves

**Pros:**
- Mature, well-documented
- Transparent pricing (~$0.20/hour for TEE)
- External API calls supported
- Enterprise reliability

**Cons:**
- Centralized (AWS controls infrastructure)
- No blockchain integration
- User must trust AWS

---

### Alternative 2: Azure Confidential Compute

**Pros:**
- Similar to AWS Nitro
- Good documentation
- Known pricing

**Cons:**
- Centralized
- No decentralized network effects
- User trust required

---

### Alternative 3: AO (Original Plan)

**Pros:**
- Public computation (no privacy)
- Lower costs (no TEE overhead)
- Simpler architecture (payment built-in)
- Mature ecosystem

**Cons:**
- No privacy (deal-breaker for high-value use cases)
- Locked into AO/Arweave ecosystem
- Lua only (less flexible than Docker)

---

### Alternative 4: Oasis Network

**Pros:**
- Decentralized TEE network (like Nillion)
- Ethereum integration exists
- Privacy-preserving smart contracts

**Cons:**
- Different architecture (not Docker-based)
- Smaller ecosystem than Nillion
- Different security model

---

### Alternative 5: Lit Protocol

**Pros:**
- Programmable decryption/signing
- Ethereum integration
- Active development

**Cons:**
- Not focused on compute (more on access control)
- Different use case than general TEE compute

---

## Conclusion

**Status:** Waiting for Nillion team responses to proceed

**Confidence:** Medium-Low (too many unknowns)

**Recommendation:**
- Send outreach messages immediately
- Continue research in parallel (prepare for both scenarios)
- If no response in 48 hours, escalate via multiple channels
- If no response in 1 week, consider pivot to alternatives

**Critical Path:**
1. External HTTP access answer → Enables/blocks direct RPC pattern
2. Pricing information → Enables/blocks economic viability (Week 2)
3. Resource limits → Enables/blocks use cases

**Blockers:**
- Cannot proceed to detailed architecture design (Task 1.3) without Q1 answer
- Cannot complete economic model (Week 2) without Q2 answer

**Next Task:**
- Await Nillion team responses (24-72 hours)
- Meanwhile, draft architecture for BOTH scenarios (HTTP yes/no)
- Prepare Task 1.3 in parallel with assumptions documented

---

**Document Status:** DRAFT - Pending Team Responses
**Last Updated:** November 15, 2025
