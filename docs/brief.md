# Project Brief: Permamind

## Executive Summary

**Permamind** is the first AI Compute Marketplace designed for autonomous agents to discover, purchase, and execute specialized AI services in a machine-to-machine (M2M) economy. Built on permanent infrastructure (Arweave + AO + Apus Network), Permamind enables AI agents to transact directly with each other without human intermediaries.

While human developers initially create payment-gated AI processes to bootstrap the ecosystem, the end vision is **agents creating AI services for other agents** - a fully autonomous marketplace where AI capabilities are bought, sold, and composed entirely through cryptographic protocols.

**Primary Users:** Autonomous agents requiring specialized AI capabilities (code review, data analysis, content generation, trading strategies) with ability to pay in tokens.

**Key Value Proposition:** First M2M marketplace where agents can monetize their own expertise by creating and selling AI services to other agents, powered by permanent context (Skills on Arweave), secure payment rails (AO Credit-Notice), and verifiable computation (Apus attestation).

---

## Problem Statement

**Current State:**

Autonomous agents exist in isolated ecosystems where AI capabilities are either:
1. **Hardcoded by developers** - Fixed functionality that can't adapt or specialize
2. **Centralized API-gated** - Require facilitators to process payments, creating trust dependencies
3. **Free but commoditized** - Generic models without domain expertise or specialized context

This creates three critical gaps in the emerging M2M economy:

### Gap 1: Payment Gating Requires Centralized Facilitators

Recent developments like **x402-ao-facilitator** (Load Network) demonstrate that payment-gated HTTP endpoints CAN use AO tokens, achieving sub-300ms settlement with permanent on-chain receipts. This is a significant advancement over traditional payment methods.

However, x402 (even with AO token support) operates as a **middleware layer** sitting between agents and services. Every transaction flows through the Load Network facilitator infrastructure:

- **Trust dependency:** Agents must trust the facilitator to correctly verify payments and grant access
- **Availability dependency:** If the facilitator is down, the entire payment rail fails
- **Architectural mismatch:** HTTP endpoints are external to AO - agents leave the AO message-passing environment to interact with Web2 APIs

For agents operating **natively within AO**, this is architectural friction. AO processes communicate through message passing, not HTTP requests. Agents need **process-to-process payment gating** using AO's native Credit-Notice pattern, not HTTP middleware routing through external facilitators.

### Gap 2: No Infrastructure for Permanent, Composable AI Services

While x402-ao enables payment for HTTP endpoints (like Arweave uploads or API access), it doesn't provide infrastructure for:

- **Payment-gated AO processes** - Native on-chain execution with built-in payment handling
- **AI inference within AO** - Processes that can call Apus for verifiable computation
- **Revenue sharing protocols** - Automatic splits between skill creators, process operators, and infrastructure providers
- **Permanent skill context** - Arweave-stored expertise that processes can reference and compensate creators for using
- **Composable AI services** - Processes calling processes, with payment flows cascading automatically

**The fundamental difference:** x402-ao enables "pay to access an HTTP endpoint," while Permamind enables "pay to execute an AO process that performs AI inference using permanent skill context with verifiable computation."

### Gap 3: No Discovery Layer for Agent-to-Agent Commerce

Even with x402-ao facilitating payments, there's no registry or marketplace where:
- Agents can discover what AI services exist
- Service metadata (pricing, capabilities, reputation) is standardized
- Quality and reliability can be assessed through on-chain metrics
- Agents can publish their own services for other agents to discover

x402-ao solves **how agents pay** but not **how agents find services** or **how creators monetize expertise**.

### Impact & Urgency

- **Architectural friction:** Forcing AO agents to use HTTP endpoints undermines native message-passing benefits
- **Facilitator dependency:** Centralized infrastructure contradicts agent autonomy principles
- **Missing AI layer:** No integration between payment rails and AI inference capabilities
- **No creator economy:** Subject matter experts can't monetize expertise as permanent AI context
- **Discovery gap:** Agents can't find each other or advertise capabilities

### Why Existing Solutions Fall Short

| Solution | Payment | Native to AO | AI Inference | Permanent Skills | Discovery | Key Limitation |
|----------|---------|--------------|--------------|------------------|-----------|----------------|
| **x402-ao (Load)** | ✅ AO tokens | ❌ HTTP middleware | ❌ No | ❌ No | ❌ No | **External facilitator + HTTP architecture** |
| **AO Processes** | ✅ Credit-Notice | ✅ Native | ❌ No AI | ✅ Arweave | ❌ No registry | No AI inference layer |
| **Apus Network** | ❌ Credits only | ❌ Router process | ✅ Gemma3-27B | ❌ No | ❌ No | Single-purpose inference, no marketplace |
| **Permamind v1** | ❌ No | ✅ MCP server | ❌ No | ✅ Skills on Arweave | ✅ Registry | No monetization or execution |

### The Core Problem

There is no **fully native AO marketplace** that combines:
- **Native payment gating** (Credit-Notice, no external facilitators)
- **AI inference integration** (Apus within AO processes)
- **Permanent skill storage** (Arweave context)
- **Revenue sharing protocols** (multi-party splits)
- **Service discovery** (searchable registry)

...enabling autonomous agents to both CONSUME and CREATE specialized AI services entirely within the AO ecosystem.

---

## Proposed Solution

Permamind is a **three-layer architecture** that creates a complete marketplace for AI services within the AO ecosystem, enabling autonomous agents to discover, pay for, and execute specialized AI capabilities without any centralized intermediaries.

### Layer 1: Skills (Permanent AI Context on Arweave)

**Skills** are immutable bundles of domain expertise stored permanently on Arweave. Each skill contains:
- **Specialized prompts and templates** - Expert-crafted instructions for AI models
- **Domain knowledge and examples** - Context that makes generic AI models perform like specialists
- **Metadata** - Pricing, licensing terms, creator attribution, versioning

**Key Innovation:** Skills separate domain expertise (human-readable, permanent) from execution logic (machine-executable, upgradeable). A security expert can create a "secure code review" skill once, store it on Arweave forever, and earn royalties every time an AI process uses it - no ongoing maintenance required.

**Revenue Model:** Processes that reference skills automatically send a licensing fee (via Credit-Notice) to the skill creator's wallet. This creates passive income for expertise providers.

### Layer 2: Processes (Payment-Gated Execution on AO)

**Processes** are AO smart contracts that execute AI tasks using Apus inference + skill context. Each process implements:
- **Native payment gating** - Uses AO's Credit-Notice pattern to receive payments from agents
- **Skill loading** - Fetches referenced skills from Arweave and caches them in process state
- **Apus integration** - Calls Apus AI inference with skill context + user prompt
- **Revenue sharing** - Automatically splits payments between skill creators, process operators, and infrastructure

**The Permamind SDK** makes creating payment-gated processes trivial:

```lua
local permamind = require("@permamind/sdk")

permamind.init({
  pricing = { CodeReview = "1000000" },  -- 0.001 AR per review
  skills = { primary = "SKILL_TX_ID" }    -- Reference skill on Arweave
})

Handlers.add("CodeReview",
  permamind.gated("CodeReview", function(msg)
    local skillContext = permamind.loadSkill("SKILL_TX_ID")
    local result = permamind.apus.infer(skillContext .. "\n\n" .. msg.Data)
    Send({ Target = msg.From, Data = result })
  end)
)
```

**Key Differentiator:** No external facilitators, no HTTP endpoints. Pure AO message passing with cryptographic payment proofs.

### Layer 3: Registry (Searchable Marketplace)

The **Registry Process** maintains a searchable index of all skills and processes in the ecosystem:
- **Skill discovery** - Search by tags, category, pricing, creator reputation
- **Process discovery** - Find AI services by capability, cost, performance metrics
- **On-chain analytics** - Usage stats, revenue generated, quality ratings
- **Quality curation** - Community-driven verification and featured listings

Agents query the registry to find services, compare pricing, check reputation, and initiate payment + execution - all through AO messages.

### How It Works (End-to-End Flow)

```
1. Agent needs code review
   ↓
2. Queries Registry Process: "Find code review services under 0.002 AR"
   ↓
3. Registry returns: [Process A: 0.001 AR, Process B: 0.0015 AR, ...]
   ↓
4. Agent sends payment + code to Process A via Credit-Notice
   ↓
5. Process A:
   - Receives Credit-Notice (payment verified)
   - Loads "secure-code-review" skill from Arweave
   - Pays skill creator 10% licensing fee
   - Calls Apus with skill context + agent's code
   - Returns AI analysis with cryptographic attestation
   ↓
6. Agent receives verifiable code review results
   ↓
7. Optional: Agent rates service quality in Registry
```

### Core Value Propositions

**For Autonomous Agents (Buyers):**
- **Discover specialized AI** - Find expert services via searchable registry
- **Pay with native tokens** - AO Credit-Notice, no facilitators or API keys
- **Verify results** - Cryptographic attestation from Apus ensures legitimate computation
- **Compose services** - Chain multiple AI processes together with automatic payment flows

**For Human Developers (Initial Creators):**
- **One-command monetization** - `skills monetize ./my-process.lua` wraps existing code with payment gating
- **Instant distribution** - Publish to registry, immediately discoverable by all agents
- **Battle-tested SDK** - Payment security, refunds, rate limiting handled automatically
- **Revenue sharing** - Earn from operating processes + using premium skills

**For Subject Matter Experts (Skill Creators):**
- **Monetize expertise** - Create once, earn forever from skill licensing fees
- **No technical barriers** - Write markdown documentation, not code
- **Permanent attribution** - Arweave storage ensures credit and royalties in perpetuity
- **Passive income** - Earn every time a process uses your skill

**For Future Agent Creators:**
- **Agent-to-agent economy** - Agents create new AI services for other agents to use
- **Emergent specialization** - Market signals drive agents to develop unique capabilities
- **Composable value chains** - Agents build on each other's services without coordination

### Why This Solution Will Succeed

**Technical Moat:**
- **First-mover in AO + Apus + Arweave stack** - Deep integration across three networks
- **Standards capture** - Becoming THE way to monetize on AO creates network lock-in
- **Permanent infrastructure** - Arweave storage means skills outlive any competitor

**Economic Moat:**
- **Network effects** - More agents using → more creators building → more value locked in ecosystem
- **Liquidity aggregation** - All AI service payments flow through our protocols
- **Creator relationships** - Early skill creators become advocates and evangelists

**Architectural Advantages Over x402-ao:**
- **No facilitator dependency** - Pure AO, no external infrastructure to fail or censor
- **Integrated AI layer** - Payment + inference + skills in single atomic transaction
- **Discovery built-in** - Registry as core feature vs afterthought
- **Revenue sharing protocol** - Multi-party splits standardized at protocol level

---

## Target Users

Permamind serves **four distinct user segments** across two evolutionary phases:

### Phase 1: Bootstrap (Months 1-12) - Human-Led Ecosystem

#### Primary User Segment: AO Developers

**Demographic/Firmographic Profile:**
- Developers already building on AO/Arweave ecosystem
- 2-10 years programming experience, comfortable with Lua
- Active in decentralized/Web3 communities (Discord, Twitter, hackathons)
- 50-500 strong globally, concentrated in crypto-native regions

**Current Behaviors and Workflows:**
- Building AO processes for personal projects, clients, or DAOs
- Manually implementing payment gating with Credit-Notice handlers
- Copy-pasting boilerplate security patterns from examples
- Distributing processes through GitHub, Discord, or direct messaging

**Specific Needs and Pain Points:**
- **Monetization friction:** 50+ lines of boilerplate to add payment gating securely
- **Distribution challenge:** No standard way for users to discover their processes
- **Revenue uncertainty:** Can't estimate earnings potential before building
- **Security burden:** One mistake in payment logic = drained funds

**Goals They're Trying to Achieve:**
- Build sustainable income from AO development work
- Establish reputation as expert process builders
- Focus on business logic, not payment infrastructure
- Reach more users without manual marketing

**How Permamind Helps:**
- SDK reduces payment gating to 5 lines of code
- Instant distribution via registry (publish once, discoverable forever)
- Analytics showing usage/revenue projections
- Battle-tested security patterns baked into SDK

#### Secondary User Segment: Subject Matter Experts (Non-Developers)

**Demographic/Firmographic Profile:**
- Security researchers, trading strategists, data analysts, content creators
- Deep expertise in specific domains but limited coding experience
- Age 25-45, earn $75K-$200K annually from consulting/content
- Interested in passive income and Web3 but intimidated by technical barriers

**Current Behaviors and Workflows:**
- Selling expertise through consulting, courses, or premium content
- Writing guides, documentation, and analysis in markdown/notion
- Frustrated by inability to capture value from expertise being used by AI models
- Exploring ways to monetize knowledge without active effort

**Specific Needs and Pain Points:**
- **Technical barriers:** Can't write code, don't understand smart contracts
- **Value leakage:** Expertise used to train AI models without compensation
- **Active effort required:** Consulting/courses require ongoing time commitment
- **Limited scale:** Can only serve X clients per month

**Goals They're Trying to Achieve:**
- Create passive income streams from existing expertise
- Get credited and compensated when AI uses their knowledge
- Reach global audience without marketing effort
- Build assets that appreciate over time (permanent skills on Arweave)

**How Permamind Helps:**
- Write skills in markdown - no coding required
- Automatic royalties every time a process uses their skill
- Permanent attribution on Arweave - credit lasts forever
- Developers handle the technical implementation

### Phase 2: Agent Economy (Year 2+) - Agent-Led Ecosystem

#### Primary User Segment: Autonomous Agents (AI-Native Consumers & Creators)

**Demographic/Firmographic Profile:**
- AI agents operating autonomously on AO with token budgets
- Range from simple bots to sophisticated multi-agent systems
- Owner: DAOs, protocols, individual humans, or other agents
- Quantity: 10K-1M+ agents by year 3

**Current Behaviors and Workflows:**
- Executing predefined tasks with limited adaptability
- Hardcoded capabilities or calling centralized APIs (if they have access)
- Operating within narrow domains due to lack of specialized AI
- Unable to monetize their own capabilities or expertise

**Specific Needs and Pain Points:**
- **Limited capabilities:** Can't access specialized AI without human intervention
- **Payment friction:** No way to autonomously pay for services
- **Discovery problem:** Can't find what services exist or evaluate quality
- **Monetization gap:** Have valuable capabilities but can't sell them to other agents

**Goals They're Trying to Achieve:**
- Access specialized AI capabilities on-demand (code review, data analysis, etc.)
- Pay for services using tokens without human approval
- Discover and evaluate service providers based on reputation/cost
- Eventually: Create and sell their own AI services to other agents

**How Permamind Helps:**
- Searchable registry of AI services (query, compare, select)
- Native AO payment flows (Credit-Notice, no human required)
- Cryptographic attestation for trust without reputation systems
- SDK enables agents to create services (future capability)

### User Journey Evolution

**Month 1-6: Developer-Focused**
- Target: 50-100 early adopter AO developers
- Focus: SDK adoption, first paid processes deployed
- Success metric: 10+ processes generating revenue

**Month 7-12: Expert Onboarding**
- Target: 20-50 subject matter experts creating skills
- Focus: Skill monetization, revenue sharing flows
- Success metric: 5+ skills earning passive royalties

**Year 2: Agent Bootstrap**
- Target: 100-1,000 agents using paid services
- Focus: Agent-friendly UX, discovery optimization
- Success metric: 50+ agents transacting daily

**Year 3+: Agent Creators**
- Target: Agents creating services for agents
- Focus: Emergent specialization, complex value chains
- Success metric: First agent-created service used by 100+ other agents

---

## Goals & Success Metrics

### Business Objectives

**1. Establish Permamind as the standard for monetization on AO**
- **Metric:** 80% of paid AO processes use Permamind SDK by Month 12
- **Target:** Achieve "npm for paid AI services" status within AO ecosystem
- **Timeline:** Month 1-12

**2. Create sustainable marketplace with active transactions**
- **Metric:** $10K total transaction volume (in AR value) by Month 6, $100K by Month 12
- **Target:** Prove economic viability and product-market fit
- **Timeline:** Month 3-12

**3. Bootstrap creator economy with skill royalties**
- **Metric:** 5+ skill creators earning >$100/month in passive royalties by Month 12
- **Target:** Demonstrate that expertise monetization works
- **Timeline:** Month 7-12

**4. Transition from human-led to agent-led marketplace**
- **Metric:** 50%+ of transactions involve autonomous agents (vs human-operated wallets) by Month 18
- **Target:** Validate M2M economy thesis
- **Timeline:** Month 13-24

### User Success Metrics

**Developer Adoption (Phase 1):**
- **Onboarding velocity:** Time from account creation to first paid process deployed <4 hours
- **SDK adoption:** 100+ processes deployed using Permamind SDK by Month 12
- **Revenue generation:** Average process earns >$50/month by Month 6
- **Retention:** 60% of developers who deploy a process are still active (deploying updates/new processes) at Month 6

**Skill Creator Success (Phase 1):**
- **Skill publication:** 50+ skills published to Arweave by Month 12
- **Utilization rate:** 40% of published skills are referenced by at least one active process
- **Royalty distribution:** $5K+ total skill royalties paid out by Month 12
- **Creator satisfaction:** NPS score >40 among skill creators

**Agent Activity (Phase 2):**
- **Agent onboarding:** 100+ unique agent addresses transacting by Month 18
- **Daily active agents:** 50+ agents making at least 1 transaction per day by Month 24
- **Service diversity:** Agents using 5+ different service categories (code review, data analysis, etc.)
- **Autonomous creation:** First agent-created service published by Month 24

### Key Performance Indicators (KPIs)

**Marketplace Health:**
- **Total Value Locked (TVL):** AR tokens deposited in processes for pre-payment (target: 1,000 AR by Month 12)
- **Transaction count:** Total Credit-Notice payments processed (target: 1,000 by Month 6, 10,000 by Month 12)
- **Transaction value:** Median transaction size (target: 0.001-0.01 AR)
- **Revenue distribution:** Total AR distributed to skill creators vs process operators (target: 10-20% to skills)

**Growth Metrics:**
- **Monthly Active Processes (MAP):** Processes that receive at least 1 payment (target: 50 by Month 12)
- **Month-over-month growth:** Transaction volume growing >15% MoM after Month 3
- **User acquisition cost:** Organic growth via community (target: $0 paid marketing in Phase 1)
- **Virality coefficient:** Each new process creator refers 1.5+ others on average

**Quality & Trust:**
- **Success rate:** % of transactions that complete successfully without refunds (target: >95%)
- **Average rating:** Process quality ratings from users (target: >4.0/5.0)
- **Response time:** P95 latency from payment to result delivery (target: <60 seconds, accounting for ~50s Apus inference)
- **Dispute rate:** % of transactions with payment disputes or refund requests (target: <2%)

**Technical Performance:**
- **Uptime:** Registry process availability (target: >99.5%)
- **Security:** Zero critical security vulnerabilities exploited
- **Apus integration:** <5% failure rate on AI inference calls
- **Cost efficiency:** Platform fee revenue covers infrastructure costs by Month 9

### Success Criteria for MVP

**Must-Have (Launch Blockers):**
- ✅ 5+ payment-gated processes deployed and accepting payments
- ✅ 3+ skills published to Arweave with revenue sharing working
- ✅ Registry process searchable via AO messages
- ✅ Zero security vulnerabilities in SDK payment gating
- ✅ Documentation complete for developers and skill creators

**Should-Have (Post-Launch Priority):**
- 🎯 10+ active developers building on Permamind
- 🎯 100+ transactions processed successfully
- 🎯 Community Discord with 50+ members
- 🎯 Analytics dashboard showing marketplace metrics
- 🎯 At least 1 case study of developer earning >$500/month

**Nice-to-Have (Future Enhancement):**
- 💡 Web UI for browsing marketplace (in addition to AO messages)
- 💡 Reputation system for processes and creators
- 💡 Advanced skill composition (skills referencing skills)
- 💡 Multi-token payment support (beyond AR)

### Long-Term Vision Metrics (Year 2-3)

**Agent Economy Maturity:**
- **Agent creators:** 10+ agents autonomously creating and deploying AI services
- **Agent transaction volume:** $1M+ annual transaction volume between agents
- **Service specialization:** 50+ distinct service categories in registry
- **Composability:** Average service calls 2+ other services (value chains)

**Ecosystem Impact:**
- **AO ecosystem share:** Permamind processes represent 20%+ of all AO compute usage
- **Developer income:** 100+ developers earning >$1K/month from Permamind processes
- **Skill creator income:** 50+ skill creators earning passive royalties
- **Industry recognition:** Cited as case study in M2M economy research/media

---

## MVP Scope

The MVP focuses on proving the core value proposition: **developers can monetize AI processes using the Permamind SDK, and autonomous agents can discover and pay for these services using AO tokens.** We deliberately limit scope to validate the economic model before building advanced features.

### Core Features (Must Have)

#### 1. Permamind Lua SDK

**Payment Gating Module:**
- `permamind.init()` - Configure pricing (in AO tokens), skill references, royalty splits
- `permamind.gated()` - Wrapper function that checks AO payment before execution
- Credit-Notice handler - Automatic balance tracking for incoming AO payments
- Withdrawal handler - Users can reclaim unused AO deposits
- Balance query - Check user's deposited balance in process

**Apus Integration Module:**
- `permamind.apus.infer()` - Call Apus AI inference with composed skill context
- Automatic credit management - Track Apus credits consumed per inference
- Error handling and retries - Handle Apus failures gracefully
- Cost estimation - Calculate expected Apus credit cost before execution

**Skill Loading & Composition Module:**
- `permamind.loadSkill(txId)` - Fetch skill from Arweave, cache in process state
- **Dependency resolution** - Automatically load skills referenced by other skills
- **Recursive composition** - Combine skill context with dependencies in correct order
- Licensing fee automation - Send AO Credit-Notices to ALL skill creators in dependency chain
- Context optimization - Truncate/prioritize skills to fit within Apus token limits
- Circular dependency detection - Prevent infinite loops in skill references

**Example Composition:**
```lua
-- Skill A: "secure-coding-principles" (no dependencies)
-- Skill B: "javascript-security" (depends on Skill A)
-- Skill C: "react-security-review" (depends on Skills A + B)

local context = permamind.loadSkill("SKILL_C_TX_ID")
-- Automatically loads C → B → A, combines contexts
-- Sends royalties to creators of C, B, and A (proportional split)
```

**Revenue Sharing Protocol:**
- Automatic AO Credit-Notice splits between:
  - Process operator (configurable %, default 70%)
  - Skill creators (proportional to dependency depth, default 30% total)
  - Example: If Skill C uses B uses A: C creator gets 15%, B gets 10%, A gets 5%
- Configurable royalty percentages per skill
- Fallback handling if skill creator wallet unreachable

**Security Patterns:**
- Checks-Effects-Interactions pattern enforcement
- Message ID tracking to prevent replay attacks
- Balance audit functions to detect inconsistencies
- Refund mechanisms for failed executions

**Rationale:** Skill composition is essential architecture - skills will naturally depend on foundational knowledge (e.g., React security builds on JavaScript security builds on general security principles). The SDK must handle this automatically or every developer reimplements it incorrectly.

#### 2. Registry Process with Agent-Accessible Quality Metrics

**Skill Registry:**
- Publish skill metadata (Arweave TX ID, creator AO wallet, tags, royalty %, description, **dependencies**)
- Search skills by tags, creator, or keyword
- View skill dependency graph
- Validate skill dependencies (check that referenced skills exist)
- View skill analytics (usage count, total royalties earned, dependency tree)

**Skill Quality Metrics (For Agent Decision-Making):**

Agents need objective, programmatically accessible metrics to choose between competing skills. The Registry Process returns:

**Usage Metrics:**
- **Total usage count:** How many processes have referenced this skill
- **Active process count:** How many currently-operating processes use this skill
- **Total royalties earned:** Cumulative AO paid to skill creator
- **Avg royalty per use:** Total royalties / usage count (direct measure of what processes value the skill at)
- **Last used timestamp:** Recency (stale skills may be outdated)

**Performance Metrics:**
- **Avg inference latency:** When used with Apus, how long does it take
- **Success rate:** % of inferences using this skill that complete without errors
- **Token efficiency:** Avg tokens consumed (shorter skills = lower Apus cost)

**Quality Signals:**
- **Refund rate:** % of transactions using this skill that resulted in refunds (lower = better)
- **Dependency count:** How many other skills depend on this (foundational skills score higher)
- **Creator reputation:** Total royalties earned across ALL creator's skills

**Example API Response:**
```json
{
  "skillId": "skill-a-tx-id",
  "name": "JavaScript Security Pro",
  "creator": "alice-wallet",
  "royaltyPercent": 10,
  "dependencies": ["general-security-tx-id"],
  "metrics": {
    "usageCount": 150,
    "activeProcesses": 12,
    "totalRoyalties": "5.2 AO",
    "avgRoyaltyPerUse": "0.0347 AO",
    "successRate": 0.97,
    "avgLatency": 48.3,
    "refundRate": 0.02,
    "dependencyCount": 8,
    "lastUsed": "2025-11-12T10:30:00Z"
  }
}
```

**Standardized Scoring API:**

Agents can request computed scores based on their preferences:

```lua
{
  Action = "ScoreSkill",
  SkillTxId = "...",
  Weights = {
    successRate: 0.4,
    usageCount: 0.2,
    refundRate: 0.2,
    recency: 0.1,
    dependencies: 0.1
  }
}
-- Returns normalized score (0-100) based on agent's priorities
```

**Process Registry:**
- Publish process metadata (AO address, capabilities, pricing in AO, required skills)
- Search processes by service type, pricing, or performance metrics
- View process analytics (transaction count, success rate, avg latency)
- Quality ratings (simple star rating from users)

**Process Quality Metrics:**
- **Transaction count:** Total payments received
- **Success rate:** % transactions without refunds
- **Avg response time:** P50, P95, P99 latencies
- **Price:** AO cost per transaction
- **Skill quality score:** Aggregate score of all skills used

**Query Interface:**
- AO message-based queries (no HTTP endpoints)
- JSON response format for easy parsing by agents
- Pagination for large result sets
- Filter and sort capabilities
- Dependency graph visualization data
- Comparison queries (side-by-side metrics for multiple skills/processes)

**Analytics Collection System:**
- Listen for Credit-Notice messages → update usage count and revenue metrics
- Track refund messages → calculate refund rates
- Monitor process telemetry → track latency and success rates
- Real-time updates (metrics reflect current state)

**Rationale:** Agents can't make subjective judgments - they need objective, programmatically accessible metrics. Without this, agents would pick skills randomly, eliminating incentive for quality. Metrics enable market-driven quality competition.

#### 3. Token Economics & Wallet Guidance

**Human Creator Flow (AR + AO):**
- Documentation: "How to fund your AR wallet for Arweave uploads"
- Documentation: "How to fund your AO wallet for registry transactions"
- Estimated costs breakdown:
  - Skill upload to Arweave: ~$0.01-0.05 per skill (one-time, in AR)
  - Skill registration: ~0.0001 AO (one-time)
  - Total barrier to entry: <$1 USD equivalent

**Agent Payment Flow (AO only):**
- Agents only need AO tokens to use processes
- Payment flow: Agent → Process (AO) → Skill creators (AO royalties) → Apus (credits)
- No AR handling needed for agents

**Wallet Setup Tooling:**
- CLI tool checks wallet balances (AR + AO)
- Warnings if insufficient balance for operations
- Links to faucets/exchanges for acquiring tokens

**Rationale:** Acknowledging the two-token reality is critical for user experience. Humans need AR for permanent storage, agents only interact with AO economy.

#### 4. Example Processes & Skills with Dependencies

**Foundational Skills (No Dependencies):**

1. **General Security Principles**
   - Content: OWASP Top 10, threat modeling, secure coding basics
   - Arweave TX: (example)
   - Royalty: 5% of process revenue
   - Target metrics: High dependency count, low avg royalty per use

**Intermediate Skills (1-level Dependencies):**

2. **JavaScript Security Best Practices**
   - Content: XSS prevention, prototype pollution, npm audit
   - Dependencies: [General Security Principles]
   - Royalty: 7% of process revenue
   - Target metrics: Medium dependency count, medium avg royalty per use

3. **Python Security Patterns**
   - Content: Injection prevention, serialization safety, dependency scanning
   - Dependencies: [General Security Principles]
   - Royalty: 7% of process revenue

**Specialized Skills (Multi-level Dependencies):**

4. **React Security Reviewer**
   - Content: Component security, XSS in JSX, React-specific vulnerabilities
   - Dependencies: [JavaScript Security, General Security Principles]
   - Royalty: 10% of process revenue
   - Target metrics: Low dependency count, high avg royalty per use

**Example Process:**

**Secure Code Reviewer for React**
- Uses Skill: React Security Reviewer (which loads JS Security → General Security)
- Total royalties: 10% (React) + 7% (JS) + 5% (General) = 22% to skill creators
- Process operator keeps: 78%
- Pricing: 0.001 AO per review
- Target metrics: High success rate, consistent latency

**Rationale:** Real dependency chain demonstrates composition, revenue splitting, and shows how foundational skills earn from multiple downstream skills. Examples also demonstrate metric differentiation.

#### 5. Documentation & Tooling

**Developer Documentation:**
- Quick start guide (0 to deployed process in <30 minutes)
- SDK API reference with code examples
- Security best practices guide
- Deployment tutorial
- AR/AO wallet setup guide

**Skill Creator Guide:**
- How to write effective skills in markdown
- Skill metadata schema and best practices
- Arweave upload instructions (AR wallet needed)
- Registry publishing (AO wallet needed)
- Revenue sharing explanation
- Dependency best practices

**Agent Integration Guide:**
- How agents query registry for skills/processes
- Metric interpretation and scoring examples
- Sample decision logic in Lua
- Payment flow walkthrough

**CLI Tool:**
- `permamind init` - Scaffold new process with SDK boilerplate
- `permamind publish` - Deploy process and register in marketplace
- `permamind skill-upload` - Upload skill to Arweave (AR) and register (AO)
- `permamind test` - Local testing with aolite integration
- `permamind wallet-check` - Verify AR and AO balances

**Rationale:** Documentation quality directly impacts adoption velocity. CLI tooling reduces friction and enforces best practices. Agent-specific docs enable autonomous consumption.

---

### Out of Scope for MVP

**Explicitly Deferred to Post-MVP:**

- ❌ **Web UI marketplace** - Message-based queries only for MVP; web UI adds complexity without validating core value
- ❌ **Advanced reputation system** - Objective metrics sufficient; complex reputation requires transaction history
- ❌ **Additional payment tokens beyond AO** - Agents pay in AO; humans can acquire AR/AO via existing exchanges
- ❌ **Agent creation tools** - Agents consume services first; creation capabilities come in Phase 2
- ❌ **Subscription models** - Pay-per-use only; subscriptions add state complexity
- ❌ **Escrow/dispute resolution** - Refunds only; formal arbitration requires governance
- ❌ **Process-to-process calls** - Single-level transactions only; composition comes later
- ❌ **Advanced analytics dashboard** - Basic metrics in registry; detailed analytics post-MVP
- ❌ **MCP server improvements** - Current Permamind MCP works; advanced features not critical
- ❌ **Gaming prevention mechanisms** - Basic metrics tracking only; anti-gaming comes after observing behavior

**Why These Can Wait:**

1. **Web UI** - Agents don't need it; can add when targeting human users more directly
2. **Advanced reputation** - Objective metrics prove concept; reputation layer after metric validation
3. **Additional tokens** - AR/AO sufficient for MVP; adding ETH/SOL/etc. adds complexity
4. **Process composition** - Valuable but complex; processes calling processes is Phase 2
5. **Agent creators** - Consumption validates market; creation is Phase 2 bet
6. **Anti-gaming** - Need to see how actors behave before building countermeasures

---

### MVP Success Criteria

**Technical Validation:**
- ✅ SDK handles 3-level skill dependency chains correctly
- ✅ Automatic royalty splits work (all creators in chain receive AO payments)
- ✅ Registry accurately tracks all metrics in real-time
- ✅ Agent can query metrics and receive response in <1 second
- ✅ Scoring algorithm produces consistent, reasonable results
- ✅ SDK integrated into 5+ processes by different developers
- ✅ All example processes functional and generating revenue
- ✅ Zero critical security vulnerabilities discovered
- ✅ Registry displays dependency graphs accurately
- ✅ Apus integration success rate >95%

**Economic Validation:**
- ✅ $1,000+ total transaction volume (in AO) within first month
- ✅ At least 1 foundational skill earns royalties from 3+ downstream skills
- ✅ At least 1 developer earning >$100 from their process
- ✅ Revenue splitting works (creators receive correct % via Credit-Notice)
- ✅ Median transaction completes successfully (no refund)
- ✅ Metrics demonstrate differentiation (competing skills show measurable differences)

**User Validation:**
- ✅ 10+ developers integrate SDK (validates developer UX)
- ✅ 5+ skills published with dependency relationships
- ✅ At least 2 competing skills in 1 category with different metric profiles
- ✅ 50+ unique AO addresses make payments (validates agent/user demand)
- ✅ Positive feedback from early adopters (qualitative validation)
- ✅ Humans successfully navigate AR (storage) + AO (registry) funding
- ✅ At least 1 agent programmatically chooses skill based on metrics

**Timeline:**
- Week 1-2: SDK core modules + skill composition + **versioning** + dependency resolution
- Week 3-4: Registry process + **version tracking** + **metrics collection** + dependency tracking + query interface
- Week 5: Example processes + skills with dependency chains + **version upgrades (v1.0 → v1.1)**
- Week 6: Documentation (AR/AO wallet setup, agent integration, **versioning best practices**) + CLI tooling
- Week 7-8: Testing (dependency edge cases, **version resolution**, **metrics accuracy**), bug fixes, security audit
- Week 9-10: MVP launch prep + early adopter onboarding 🚀

---

## Post-MVP Vision

The MVP validates the core economic model: **payment-gated AI processes with skill monetization and versioning**. Post-MVP phases expand the marketplace into a full agent economy with advanced capabilities.

### Phase 2: Enhanced Marketplace (Months 4-12)

#### Web UI Marketplace
**Problem:** Message-based queries work for agents but limit human discovery and onboarding

**Solution:**
- Browser-based marketplace for browsing skills and processes
- Visual dependency graphs (see how skills connect)
- Version comparison interface (side-by-side metrics for v1.0 vs v1.1)
- Interactive metrics dashboards
- One-click process invocation (wallet integration)
- Skill preview and testing interface

**Value:** Attracts non-technical skill creators and casual users who won't learn AO message passing

#### Advanced Reputation System
**Problem:** Simple metrics don't capture nuanced quality signals

**Solution:**
- Time-weighted reputation (recent performance matters more)
- Category-specific expertise scores (expert in security, beginner in data analysis)
- Endorsements from reputable processes/creators
- Verified badges (audited security, high uptime, featured creator)
- Dispute resolution history transparency

**Value:** Reduces risk for agents choosing untested skills/processes

#### Process-to-Process Composition
**Problem:** Complex workflows require multiple AI steps that can't be automated

**Solution:**
- Processes can call other processes via AO messages
- Automatic payment cascading (user pays once, fees split across chain)
- Workflow orchestration primitives
- Example: Code review → Auto-fix → Re-review → Deploy

**Value:** Enables complex agent workflows without human coordination

**Example:**
```lua
-- Process A: Code Review
local result = permamind.apus.infer(code)

if result.hasVulnerabilities then
  -- Call Process B: Auto-Fix
  local fixed = permamind.callProcess("auto-fix-process-id", code)

  -- Call Process C: Re-review
  local verification = permamind.callProcess("verify-fix-process-id", fixed)

  return verification
end
```

### Phase 3: Agent Creators (Year 2)

#### Agent-Friendly SDK Extensions
**Problem:** Agents can consume services but not create them

**Solution:**
- Template-based process generation (agents fill in parameters)
- Natural language → Lua transpilation (describe service, get code)
- Automatic testing and deployment
- Safety rails (cost limits, rollback mechanisms)

**Value:** Agents become suppliers, not just consumers, accelerating marketplace growth

#### Advanced Skill Evolution
**Problem:** Fork-and-improve workflow doesn't exist yet

**Solution:**
- Skill forking (create derivative works with attribution)
- Royalty inheritance (forked skills pay parent creator percentage)
- Community governance for featured skills
- Skill bounties (pay for specific improvements)

**Value:** Accelerates skill quality through community collaboration

#### Multi-Model Support
**Problem:** Apus only offers Gemma3-27B (limits use cases)

**Solution:**
- SDK abstracts model selection (specify requirements, get best model)
- Support for specialized models (code, vision, embeddings)
- Cost optimization (route to cheapest model that meets requirements)
- Multi-provider support (Apus, other decentralized inference networks)

**Value:** Expands addressable use cases, reduces single-provider risk

### Phase 4: Advanced Economics (Year 2-3)

#### Subscription Models
**Problem:** Pay-per-use creates friction for heavy users

**Solution:**
- Time-based subscriptions (unlimited use for 30 days)
- Volume-based subscriptions (1000 calls/month)
- Tiered pricing (basic/pro/enterprise)
- Subscription revenue split between skill creators

**Value:** Predictable revenue for creators, better economics for power users

#### Revenue Optimization Tools
**Problem:** Creators don't know optimal pricing

**Solution:**
- A/B testing framework (test different prices)
- Demand elasticity analytics
- Dynamic pricing (surge pricing during high demand)
- Bundle pricing (package multiple skills together)

**Value:** Maximizes creator revenue, market efficiency

#### Marketplace Incentives
**Problem:** Chicken-and-egg (need skills to attract processes, need processes to attract agents)

**Solution:**
- Liquidity mining (rewards for early participants)
- Referral bonuses (skill creators earn from referring process developers)
- Matching grants (community fund matches skill royalties for high-impact work)
- Hackathon prizes (incentivize building on Permamind)

**Value:** Accelerates network effects, attracts quality creators

### Phase 5: Ecosystem Expansion (Year 3+)

#### Cross-Chain Integration
**Problem:** Agents on other chains can't access Permamind

**Solution:**
- Bridge to Ethereum/Solana/Cosmos (accept ETH, SOL, ATOM payments)
- Wrapped skills (reference Arweave skills from other chains)
- Universal registry (query from any chain)

**Value:** 10-100x addressable market

#### Enterprise Features
**Problem:** Organizations need compliance, governance, and control

**Solution:**
- Private skill repositories (internal use only)
- Allowlist/blocklist for approved services
- Audit logging and compliance reports
- Multi-signature approval for spending
- SLA guarantees (backed by stake)

**Value:** Opens enterprise market segment

#### Agent Coordination Protocols
**Problem:** Complex tasks require multiple agents working together

**Solution:**
- Multi-agent task decomposition (split work, aggregate results)
- Auction mechanisms (agents bid for work)
- Reputation-based delegation (high-rep agents manage low-rep agents)
- Dispute arbitration (decentralized conflict resolution)

**Value:** Enables sophisticated multi-agent economies

### Deferred Features (Intentionally Not Prioritized)

**Features we're consciously NOT building:**

1. **Human-in-the-loop services** - Focus is autonomous, not hybrid
2. **Fiat payment rails** - Crypto-native only (let x402 handle fiat)
3. **Centralized compute** - Apus or decentralized alternatives only
4. **Proprietary models** - Open models and open infrastructure only
5. **Advertising/promotion** - Organic discovery via metrics, no paid placement

**Why:** These dilute the core vision of autonomous, decentralized agent economy

---

## Technical Considerations

Based on comprehensive research (Phase 1-2 complete findings), here are the critical technical decisions and constraints:

### Platform Requirements

**Target Platforms:**
- **AO Network:** Primary execution environment for all processes
- **Arweave:** Permanent storage for skills and metadata
- **Apus Network:** AI inference layer

**Browser/Client Support:**
- Agents: AO message-passing only (no browser required)
- Human users (future): Modern browsers with wallet extensions (ArConnect, etc.)

**Performance Requirements:**
- **Latency:** 50-60 second P95 (dominated by ~50s Apus inference)
- **Throughput:** Sequential from client perspective; registry must handle 100+ concurrent queries
- **Uptime:** 99.5%+ for registry process

### Technology Stack

**Frontend (Phase 1 - CLI only):**
- **Language:** TypeScript/Node.js
- **CLI Framework:** Commander.js or oclif
- **Wallet Integration:** ArConnect for Arweave, aoconnect for AO

**Backend (AO Processes):**
- **Language:** Lua 5.3 (AO runtime)
- **Standard Libraries:** JSON, string, table, math (limited stdlib)
- **Message Passing:** AO native handlers
- **State:** Automatic persistence to Arweave

**SDK (Permamind Lua SDK):**
- **Package Format:** AO blueprints via apm (AO package manager)
- **Distribution:** `apm install @permamind/sdk`
- **Dependencies:** @apus/ai, JSON library, crypto utilities

**Infrastructure:**
- **Development:** aolite (local AO testing framework)
- **Deployment:** aos CLI to AO mainnet
- **Monitoring:** AO message logs, custom analytics process

### Architecture Considerations

**Repository Structure:**

```
permamind/
├── sdk/                    # Permamind Lua SDK
│   ├── payment-gating.lua
│   ├── skill-loading.lua
│   ├── apus-integration.lua
│   ├── versioning.lua
│   └── security.lua
├── registry/               # Registry AO Process
│   ├── skill-registry.lua
│   ├── process-registry.lua
│   ├── metrics-collector.lua
│   └── query-interface.lua
├── cli/                    # CLI tool (TypeScript)
│   ├── src/
│   │   ├── commands/
│   │   │   ├── init.ts
│   │   │   ├── publish.ts
│   │   │   └── skill-upload.ts
│   │   └── utils/
│   └── package.json
├── examples/               # Example processes & skills
│   ├── secure-code-review/
│   ├── data-analyzer/
│   └── content-generator/
├── docs/                   # Documentation
│   ├── getting-started.md
│   ├── sdk-reference.md
│   ├── security-guide.md
│   └── versioning-guide.md
└── tests/                  # Test suite (aolite)
    ├── sdk/
    ├── registry/
    └── integration/
```

**Service Architecture:**
- Single-repo monolith for MVP (simplicity over microservices)
- Can split later if needed

**Integration Requirements:**

**Apus Network:**
- Router Process: `TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g`
- Credit management, error handling, retry logic
- Async callback pattern for inference

**Arweave:**
- Gateway access for reads, direct uploads for writes
- Process-level caching for frequently used skills
- Cost: ~$5-10 per GB one-time

**AO Token Standard:**
- Credit-Notice/Debit-Notice for all payments
- Multi-recipient transfers for revenue sharing

**Security & Compliance:**
- Checks-Effects-Interactions pattern
- Message ID tracking for replay prevention
- Public by design (all transactions on-chain)
- No PII collection

### Known Constraints & Limitations

**AO Lua Environment:**
- No native HTTP (must use gateway processes)
- Limited stdlib (no file system, complex crypto, image processing)
- Compute limits (~50-100MB memory, ~30s execution time)

**Apus Network:**
- Single model (Gemma3-27B, 8K context)
- ~50 second inference latency
- Volatile $APUS pricing
- Unknown uptime SLA

**Arweave Integration:**
- No direct read from AO processes
- First load latency for cold fetches
- Context window limits (8,192 tokens total)

### Technology Preferences & Rationale

**Lua for SDK:** Native to AO, lightweight
**TypeScript for CLI:** Rich ecosystem, type safety
**Arweave for Storage:** Permanent, immutable
**AO for Execution:** Native message passing, auto persistence
**Apus for AI:** Only decentralized option on AO

---

## Constraints & Assumptions

### Constraints

**Budget:**
- MVP Phase: $0 infrastructure costs (AO/Arweave gas only)
- Skill uploads: ~$0.01-0.05 per skill (creator-funded)
- Development: Self-funded or grant-funded
- Hard constraint: Must show traction by Month 6

**Timeline:**
- MVP delivery: 10 weeks from start
- First revenue: Month 1 post-launch
- Product-market fit validation: Month 6

**Resources:**
- Team: 1-2 developers for MVP
- Community-driven support
- Lua expertise required (limited pool)

**Technical:**
- Apus latency: ~50 seconds minimum (hard constraint)
- Single AI model: Gemma3-27B only
- AO compute limits: ~30 second execution time per message
- Token limits: 8,192 tokens total
- No streaming responses

### Key Assumptions

**Market Assumptions:**

1. **M2M Economy Will Emerge** - Autonomous agents will become economic actors by 2026
   - Risk: Agents remain human-controlled
   - Validation: Track % autonomous vs human wallets

2. **AO Ecosystem Will Grow** - 1000+ developers by 2026
   - Risk: Small community remains small
   - Validation: Monitor Discord membership, process deployments

3. **Developers Will Pay for Specialized AI** - Generic models aren't sufficient
   - Risk: GPT-4/Claude are "good enough"
   - Validation: Track avg royalty per use

**Technical Assumptions:**

4. **Apus Will Remain Stable** - Won't shut down or radically change
   - Risk: New tech, no track record
   - Mitigation: Multi-provider support in Phase 3

5. **50s Latency Acceptable for Agents** - Async operation is natural
   - Risk: Latency-sensitive use cases excluded
   - Validation: Survey early adopters

6. **Gateway Processes Will Emerge** - Community builds needed infrastructure
   - Risk: May need to build ourselves
   - Mitigation: Plan for self-built gateways

**Economic Assumptions:**

7. **Revenue Sharing Incentivizes Quality** - Royalties drive improvements
   - Risk: Creators abandon after upload
   - Validation: Track version update frequency

8. **Agents Choose Based on Metrics** - Objective measures sufficient
   - Risk: Metrics get gamed
   - Mitigation: Monitor and adjust metrics

9. **Organic Growth** - Network effects drive viral adoption
   - Risk: Plateau at low volume
   - Mitigation: Incentive programs if needed

**User Behavior Assumptions:**

10. **Developers Will Learn Lua** - Monetization > learning curve
    - Risk: Language barrier limits adoption
    - Validation: Track completion rate

11. **Experts Will Create Skills** - Non-technical can write markdown
    - Risk: Low-quality or few creators
    - Validation: Quality ratings, creator surveys

12. **Humans Bootstrap, Agents Take Over** - Phase transition occurs
    - Risk: Stuck in human-led market
    - Validation: Track agent % quarterly

### Dependencies

**Core Dependencies:**
- Arweave operational and cost-effective
- AO backward-compatible
- Apus continuing service
- AO community growth
- Wallet infrastructure stability

**Success Dependencies (MVP):**
- 50+ active AO developers
- Apus available for 10-week dev cycle
- Arweave costs <$10/GB
- AO message passing reliable
- Community support available

**Success Dependencies (Long-term):**
- AO ecosystem → 1000+ developers
- Agents gain creation capabilities
- Multi-model AI options emerge
- Stable crypto market
- Favorable regulatory environment

---

## Risks & Open Questions

### Key Risks

**Technical Risks:**

1. **Apus Network Dependency (🔴 High)** - Shutdown or major changes break AI layer
   - Mitigation: Provider abstraction, multi-provider in Phase 3
   - Contingency: Pivot to HTTP-based AI via gateways

2. **Payment Security Vulnerabilities (🔴 High)** - Exploits drain funds
   - Mitigation: Security patterns, external audit, bug bounty
   - Contingency: Pause system, refund users, deploy fixes

3. **Skill Dependency Chain Breaks (🟡 Medium)** - Deep chains exceed limits
   - Mitigation: Depth limits, circular dependency detection
   - Contingency: Flatten skills, reduce dependencies

4. **Registry Scalability (🟡 Medium)** - Can't handle 1000+ concurrent queries
   - Mitigation: Load testing, pagination, caching
   - Contingency: Deploy multiple registries, load balance

**Market Risks:**

5. **AO Ecosystem Doesn't Grow (🔴 High)** - Remains small community
   - Mitigation: Contribute to ecosystem, build demos
   - Contingency: Pivot to other platforms

6. **Generic AI "Good Enough" (🟡 Medium)** - No premium for specialization
   - Mitigation: Focus on niches, verifiability, cost
   - Contingency: Pivot to curation value prop

7. **Competitive Threats (🟡 Medium)** - x402-ao or others compete
   - Mitigation: First-mover advantage, deeper integration
   - Contingency: Partner or differentiate

**Economic Risks:**

8. **Insufficient Creator Revenue (🟡 Medium)** - Creators earn <$10/month, abandon
   - Mitigation: Incentives, promote case studies
   - Contingency: Creator grants, subsidies

9. **Token Price Volatility (🟡 Medium)** - Unpredictable costs
   - Mitigation: Price ranges, budget caps
   - Contingency: Stablecoin support

10. **Metric Gaming (🟡 Medium)** - Fake usage inflates metrics
    - Mitigation: Monitor patterns, community reporting
    - Contingency: Adjust formulas, blacklist actors

**Operational Risks:**

11. **Developer Acquisition Fails (🔴 High)** - Can't attract 50 developers
    - Mitigation: Great docs, outreach, hackathons
    - Contingency: Build examples ourselves, seed marketplace

12. **Security Incident (🔴 High)** - Post-launch exploit
    - Mitigation: Testing, audit, bounty, low limits
    - Contingency: Pause, disclosure, compensation

### Open Questions

**Technical:**
- Q1: How deep can skill dependency chains go? (Test edge cases)
- Q2: Will community build gateways? (Decision by Week 4)
- Q3: Optimal royalty split? (Validate with early transactions)
- Q4: Apus downtime handling? (Monitor during dev)

**Market:**
- Q5: Will agents become creators? (Critical for long-term vision)
- Q6: Right pricing? (A/B test post-launch)
- Q7: Typical skill file sizes? (Create diverse examples)
- Q8: Will experts write skills? (User interviews needed)

**Strategic:**
- Q9: Depth (AO-only) vs Breadth (multi-chain)? (Decide Month 12)
- Q10: When to add Web UI? (Track CLI drop-off)
- Q11: Balance openness vs revenue? (Community feedback)
- Q12: Anti-gaming in MVP? (Monitor first month)

### Research Needed

**Pre-Launch (High Priority):**
1. Load test registry with 1000+ queries
2. Measure Apus failure rates
3. Calculate token budgets for dependency chains
4. Security audit payment gating
5. Validate wallet funding UX

**First Month (Medium Priority):**
6. Survey latency tolerance
7. A/B test pricing
8. Interview skill creators
9. Analyze gaming patterns
10. Benchmark vs x402-ao

---

## Appendices

