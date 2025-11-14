# Permamind Fullstack Architecture Document

## Introduction

This document outlines the complete fullstack architecture for **Permamind**, including backend systems, frontend implementation, and their integration. It serves as the single source of truth for AI-driven development, ensuring consistency across the entire technology stack.

This unified approach combines what would traditionally be separate backend and frontend architecture documents, streamlining the development process for modern fullstack applications where these concerns are increasingly intertwined.

### Starter Template or Existing Project

**Status:** N/A - Greenfield project

This is a greenfield implementation with no existing starter templates. The project architecture will be designed from scratch based on the unique requirements of the AO ecosystem, Arweave permanence, and Apus AI integration. The technology stack is highly specialized and not served by conventional fullstack starters.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-14 | 0.1 | Initial architecture draft from PRD | Winston (Architect) |
| 2025-11-14 | 0.2 | Added JSON schema validation and load testing enhancements | Winston (Architect) |

---

## High Level Architecture

### Technical Summary

Permamind implements a **message-driven, decentralized AI marketplace architecture** built entirely on the AO network with permanent storage on Arweave and AI inference via Apus Network. The system consists of three primary layers: (1) **Skills** - immutable AI context bundles stored on Arweave earning passive royalties, (2) **Processes** - payment-gated AO smart contracts executing specialized AI tasks, and (3) **Registry** - a centralized AO process providing searchable discovery with quality metrics.

The architecture follows a **monorepo pattern** with Lua-based on-chain components (SDK, Registry) and TypeScript-based developer tooling (CLI). All inter-component communication uses AO's native message-passing protocol with Credit-Notice payments, eliminating HTTP endpoints and centralized facilitators. The CLI serves as the primary developer interface for scaffolding, deployment, and marketplace interaction, while the SDK provides security-hardened payment gating, skill composition, and Apus inference capabilities that process developers embed directly into their AO contracts.

This architecture achieves the PRD goals by enabling autonomous agents to discover services via Registry queries, pay via AO Credit-Notices, and receive AI-powered results without leaving the AO ecosystem, while skill creators earn automatic royalty splits on every process invocation.

### Platform and Infrastructure Choice

**Platform:** AO Network (Arweave-based decentralized compute)

**Key Services:**
- **AO Network:** Process execution runtime, message passing, state persistence
- **Arweave:** Permanent data storage for skills and process state
- **Apus Network:** Decentralized AI inference (Gemma3-27B model)
- **Registry Process:** Centralized marketplace discovery (single AO process)

**Deployment Host and Regions:**
- AO mainnet (globally distributed validator network)
- No regional selection (decentralized by design)
- Development: Local via aolite, Testing: AO testnet (if available) or mainnet test wallets

### Repository Structure

**Structure:** Monorepo

**Monorepo Tool:** npm workspaces (lightweight, Node.js native)

**Package Organization:**
```
permamind/
├── sdk/                    # Lua SDK (AO blueprints)
├── registry/               # Registry AO Process (Lua)
├── cli/                    # CLI tool (TypeScript/Node.js)
├── examples/               # Example processes & skills
├── docs/                   # Documentation
└── tests/                  # Test suite (aolite)
```

### High Level Architecture Diagram

```mermaid
graph TB
    subgraph "Developer Tools (Off-Chain)"
        CLI[CLI Tool<br/>TypeScript/Node.js]
    end

    subgraph "AO Network (On-Chain)"
        SDK[Permamind SDK<br/>Lua Library]
        Process1[Payment-Gated Process 1<br/>Uses SDK]
        Process2[Payment-Gated Process 2<br/>Uses SDK]
        Registry[Registry Process<br/>Discovery & Metrics]
    end

    subgraph "Permanent Storage"
        Arweave[(Arweave<br/>Skill Storage)]
    end

    subgraph "AI Infrastructure"
        Apus[Apus Router<br/>AI Inference]
    end

    User[User/Agent<br/>AO Wallet] -->|AO Messages| Process1
    User -->|AO Messages| Process2
    User -->|Query/Search| Registry

    CLI -->|Deploy| Process1
    CLI -->|Deploy| Process2
    CLI -->|Upload Skills| Arweave
    CLI -->|Register| Registry

    SDK -.->|Embedded In| Process1
    SDK -.->|Embedded In| Process2

    Process1 -->|Fetch Skills| Arweave
    Process2 -->|Fetch Skills| Arweave
    Process1 -->|Inference Request| Apus
    Process2 -->|Inference Request| Apus

    Process1 -->|Credit-Notice Events| Registry
    Process2 -->|Credit-Notice Events| Registry

    Registry -->|Skill Metadata| Arweave

    Apus -->|Async Response| Process1
    Apus -->|Async Response| Process2

    style SDK fill:#e1f5ff
    style Registry fill:#fff4e1
    style Arweave fill:#e8f5e9
    style Apus fill:#f3e5f5
```

### Architectural Patterns

- **Message-Driven Architecture:** All inter-process communication via AO message passing (Credit-Notice, queries, responses). No HTTP endpoints. - _Rationale:_ Native AO pattern ensures trustless execution without centralized facilitators.

- **Embedded SDK (Library Pattern):** SDK code bundled into each process, not a separate service. - _Rationale:_ AO processes cannot import external dependencies at runtime; all code must be deployed with the process.

- **Event Sourcing (Registry Metrics):** Registry listens to Credit-Notice and Refund-Notice messages to update quality metrics in real-time. - _Rationale:_ Avoids manual reporting; metrics derived from on-chain transaction truth.

- **Repository Pattern (Skill Loading):** Abstracted skill fetching with caching layer in process state. - _Rationale:_ Arweave gateway latency (5-10s) requires aggressive caching; pattern allows fallback gateway switching.

- **Checks-Effects-Interactions (CEI) Pattern:** All payment handlers validate → update state → external calls (Apus, royalties). - _Rationale:_ Critical security pattern preventing reentrancy and state corruption.

- **Async Callback Pattern:** Apus inference uses message references for request-response matching due to ~50s latency. - _Rationale:_ AO message handlers cannot block; must return immediately and handle results in separate handler.

- **Single Registry (Centralized Discovery):** One authoritative Registry process for marketplace data. - _Rationale:_ Simplifies queries and consistency; distributed registries add complexity without MVP benefit.

- **CLI-First Development:** Terminal commands for all developer operations (no web dashboard). - _Rationale:_ Faster MVP delivery; web UI deferred to Phase 2 per PRD.

---

## Tech Stack

This is the **single source of truth** for all technology choices. All development must use these exact versions.

### Technology Stack Table

| Category | Technology | Version | Purpose | Rationale |
|----------|-----------|---------|---------|-----------|
| **SDK Language** | Lua | 5.3 | AO process runtime language | AO network requirement; only supported language for on-chain logic |
| **CLI Language** | TypeScript | 5.3+ | Developer tooling and CLI implementation | Type safety, rich ecosystem (commander, inquirer), cross-platform Node.js support |
| **CLI Runtime** | Node.js | 18+ LTS | CLI execution environment | Modern JS features, stable LTS, cross-platform (macOS/Linux/Windows) |
| **Monorepo Tool** | npm workspaces | 9+ | Package management and workspace coordination | Native to npm, zero additional deps, sufficient for 6-package monorepo |
| **AO SDK** | @permaweb/aoconnect | Latest | AO message sending and process interaction from CLI | Official AO JavaScript library for external integrations |
| **AO CLI** | aos | Latest | Process deployment to AO network | Official AO command-line tool for process management |
| **AO Testing** | aolite | Latest | Local AO process simulation and testing | Fast local iteration without mainnet deployment costs |
| **AO Package Manager** | apm | Latest | SDK distribution as @permamind/sdk | Official AO package registry (planned distribution method) |
| **Arweave Client** | arweave-js | 1.14+ | Arweave transaction creation and gateway queries | Official Arweave JavaScript SDK for wallet and data operations |
| **Apus Integration** | Native AO Messages | N/A | AI inference via message-passing to router process | Apus Router Process ID: TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g |
| **Apus Model** | Gemma3-27B | N/A | AI inference model (8,192 token context) | Only model supported by Apus in MVP; sufficient for text-based skills |
| **Database** | AO Process State | N/A | Automatic persistence to Arweave | Built-in AO feature; no separate database needed |
| **Storage** | Arweave | N/A | Permanent skill storage (~$5-10/GB one-time) | Immutable, permanent, decentralized storage for skill content |
| **CLI Framework** | Commander.js | 11+ | Command-line argument parsing and structure | Industry standard, simple API, rich help generation |
| **CLI Prompts** | Inquirer.js | 9+ | Interactive command-line prompts | Best-in-class UX for CLI wizards (init, config) |
| **CLI Output** | Chalk | 5+ | Terminal color and styling | Beautiful, readable terminal output for errors/success |
| **CLI Spinners** | Ora | 7+ | Progress indicators for async operations | Professional UX for uploads, deployments, waiting |
| **CLI Tables** | cli-table3 | 0.6+ | Formatted table output for search results | Clean table rendering for skills/processes display |
| **Schema Validation** | Zod | 3.22+ | Runtime JSON schema validation | Validate process.json before deployment, prevent errors |
| **Linting (TS)** | ESLint | 8+ | TypeScript code quality enforcement | Standard linter with TypeScript support |
| **Formatting (TS)** | Prettier | 3+ | Code formatting automation | Consistent code style across team |
| **Lua Formatting** | Manual/StyLua | N/A | Lua code formatting (manual in MVP) | Follow aos conventions; automated formatting post-MVP |
| **Unit Testing (Lua)** | aolite assertions | N/A | SDK and Registry unit tests | Built-in to aolite framework |
| **Unit Testing (TS)** | Jest | 29+ | CLI unit tests | Industry standard, great TypeScript support |
| **Build Tool** | tsc (TypeScript Compiler) | 5.3+ | CLI compilation | Native TypeScript toolchain, no bundler needed for Node.js |
| **CI/CD** | GitHub Actions | N/A | Automated testing and npm publishing | Free for open source, native GitHub integration |
| **Version Control** | Git + GitHub | N/A | Source control and collaboration | Industry standard, hosts CI/CD |
| **Documentation** | Markdown | N/A | All documentation format | Simple, readable, GitHub-native rendering |
| **Wallet (AR)** | ArConnect / JSON Keyfile | N/A | Arweave transaction signing | Browser extension for ease, keyfile for automation |
| **Wallet (AO)** | AO Wallet (derived from seed) | N/A | AO message signing and payments | CLI generates from SEED_PHRASE env variable |
| **Monitoring** | Manual Log Inspection | N/A | Debug via AO message logs (public by design) | No APM for MVP; all transactions visible on-chain |
| **Logging** | AO Message Logs | N/A | All process activity logged automatically | Public blockchain logs; no additional logging infrastructure |

---

## Data Models

Core data models shared between SDK (Lua) and CLI (TypeScript), with TypeScript interfaces serving as the canonical schema.

### Model: Skill

**Purpose:** Represents an immutable AI expertise bundle stored on Arweave, referenced by processes for context composition, with automatic royalty tracking.

**Key Attributes:**
- **txId**: `string` (43 chars) - Arweave transaction ID (unique identifier)
- **name**: `string` - Human-readable skill name (e.g., "React Security Review")
- **description**: `string` - Detailed explanation of skill capabilities
- **content**: `string` - Full skill markdown content (AI context)
- **version**: `string` - Semantic version (e.g., "1.0.0")
- **creator**: `string` (43 chars) - AO wallet address of skill creator
- **royaltyPercent**: `number` (0-100) - Percentage of process payment owed to creator
- **dependencies**: `string[]` - Array of Arweave TX IDs (dependent skills)
- **tags**: `string[]` - Searchable keywords (e.g., ["security", "react", "javascript"])
- **createdAt**: `number` - Unix timestamp of Arweave upload
- **tokenCount**: `number` - Estimated token count for Apus context limit

#### TypeScript Interface

```typescript
interface Skill {
  txId: string;                    // Arweave TX ID (43 characters)
  name: string;
  description: string;
  content: string;                 // Full markdown content
  version: string;                 // Semantic versioning
  creator: string;                 // AO wallet address
  royaltyPercent: number;          // 0-100
  dependencies: string[];          // Array of skill TX IDs
  tags: string[];                  // Searchable keywords
  createdAt: number;               // Unix timestamp
  tokenCount: number;              // For 8,192 token limit validation
}
```

#### Relationships
- **Parent Skills**: Skills referenced in `dependencies` array (composition)
- **Used By Processes**: Processes that load this skill for context (many-to-many)
- **Creator**: Links to User/Wallet entity (one-to-many)
- **Metrics**: Links to SkillMetrics entity for quality tracking (one-to-one)

---

### Model: Process

**Purpose:** Represents a payment-gated AO process offering AI-powered services, registered in the Registry for discovery, with automated royalty distribution to skill creators.

**Key Attributes:**
- **processId**: `string` (43 chars) - AO process address (unique identifier)
- **name**: `string` - Service name (e.g., "Code Security Reviewer")
- **description**: `string` - Detailed service capabilities
- **capabilities**: `string[]` - Searchable keywords for what service provides
- **pricing**: `Record<string, number>` - Map of action names to AO token prices (e.g., `{ "ReviewCode": 1000000 }`)
- **skills**: `string[]` - Array of skill TX IDs used by this process
- **creator**: `string` (43 chars) - AO wallet address of process deployer
- **version**: `string` - Process version (immutable; redeploy for updates)
- **createdAt**: `number` - Unix timestamp of deployment
- **updatedAt**: `number` - Timestamp of last metadata update

#### TypeScript Interface

```typescript
interface Process {
  processId: string;               // AO process address (43 characters)
  name: string;
  description: string;
  capabilities: string[];          // Searchable service tags
  pricing: Record<string, number>; // Action → AO token amount
  skills: string[];                // Skill TX IDs used
  creator: string;                 // AO wallet address
  version: string;
  createdAt: number;               // Unix timestamp
  updatedAt: number;               // Unix timestamp
}
```

#### Relationships
- **Uses Skills**: Skills loaded via `permamind.loadSkill()` (many-to-many)
- **Creator**: Links to User/Wallet entity (one-to-many)
- **Metrics**: Links to ProcessMetrics entity for performance tracking (one-to-one)
- **Transactions**: Links to Transaction entity for payment history (one-to-many)

---

### Model: SkillMetrics

**Purpose:** Real-time quality and performance metrics for skills, updated automatically by Registry via Credit-Notice monitoring.

**Key Attributes:**
- **skillTxId**: `string` (43 chars) - Foreign key to Skill
- **usageCount**: `number` - Total times skill loaded by processes
- **activeProcessCount**: `number` - Number of live processes using this skill
- **totalRoyalties**: `number` - Total AO tokens earned (cumulative)
- **avgRoyaltyPerUse**: `number` - Calculated: `totalRoyalties / usageCount`
- **refundRate**: `number` (0-1) - Percentage of uses resulting in refunds
- **successRate**: `number` (0-1) - Calculated: `1 - refundRate`
- **lastUsed**: `number` - Unix timestamp of most recent usage
- **qualityScore**: `number` (0-100) - Composite score from scoring algorithm

#### TypeScript Interface

```typescript
interface SkillMetrics {
  skillTxId: string;               // Foreign key
  usageCount: number;
  activeProcessCount: number;
  totalRoyalties: number;          // In AO token base units
  avgRoyaltyPerUse: number;        // Calculated field
  refundRate: number;              // 0.0 to 1.0
  successRate: number;             // 1 - refundRate
  lastUsed: number;                // Unix timestamp
  qualityScore: number;            // 0-100 composite score
}
```

#### Relationships
- **Belongs To Skill**: One-to-one relationship with Skill entity

---

### Model: ProcessMetrics

**Purpose:** Real-time performance and reliability metrics for processes, tracked by Registry and used for discovery ranking.

**Key Attributes:**
- **processId**: `string` (43 chars) - Foreign key to Process
- **transactionCount**: `number` - Total paid actions executed
- **refundCount**: `number` - Total refunds issued (failures)
- **successRate**: `number` (0-1) - Calculated: `(transactionCount - refundCount) / transactionCount`
- **totalRevenue**: `number` - Total AO tokens collected (excluding royalties paid out)
- **p50ResponseTime**: `number` - Median response time in milliseconds
- **p95ResponseTime**: `number` - 95th percentile response time
- **p99ResponseTime**: `number` - 99th percentile response time
- **avgInferenceLatency**: `number` - Average Apus inference time
- **lastActive**: `number` - Unix timestamp of most recent transaction

#### TypeScript Interface

```typescript
interface ProcessMetrics {
  processId: string;               // Foreign key
  transactionCount: number;
  refundCount: number;
  successRate: number;             // (txCount - refunds) / txCount
  totalRevenue: number;            // AO tokens (gross, before royalties)
  p50ResponseTime: number;         // Milliseconds
  p95ResponseTime: number;
  p99ResponseTime: number;
  avgInferenceLatency: number;     // Milliseconds (Apus-specific)
  lastActive: number;              // Unix timestamp
}
```

#### Relationships
- **Belongs To Process**: One-to-one relationship with Process entity

---

### Model: Transaction

**Purpose:** Record of a completed payment-gated action, used for audit trails and metrics calculation (not stored permanently in MVP; derived from on-chain logs).

**Key Attributes:**
- **messageId**: `string` (43 chars) - AO message ID (unique identifier)
- **processId**: `string` (43 chars) - Process that handled transaction
- **user**: `string` (43 chars) - AO wallet that paid
- **action**: `string` - Action name (e.g., "ReviewCode")
- **amount**: `number` - Payment amount in AO tokens
- **royaltiesPaid**: `Record<string, number>` - Map of creator addresses to royalty amounts
- **status**: `'success' | 'refunded' | 'failed'` - Transaction outcome
- **timestamp**: `number` - Unix timestamp
- **responseTime**: `number` - Milliseconds from payment to result delivery

#### TypeScript Interface

```typescript
type TransactionStatus = 'success' | 'refunded' | 'failed';

interface Transaction {
  messageId: string;               // AO message ID (unique)
  processId: string;               // Which process handled this
  user: string;                    // Payer's AO wallet
  action: string;                  // Action invoked
  amount: number;                  // Payment in AO tokens
  royaltiesPaid: Record<string, number>; // Creator → amount
  status: TransactionStatus;
  timestamp: number;               // Unix timestamp
  responseTime: number;            // Milliseconds (performance tracking)
}
```

#### Relationships
- **Belongs To Process**: Many-to-one relationship with Process
- **Paid By User**: Many-to-one relationship with User/Wallet
- **Includes Royalties**: Maps to multiple Skill creators

---

## API Specification

Permamind uses **AO message-passing** instead of REST/GraphQL/tRPC. The "API" is the set of **message handlers** that processes respond to, with tags defining actions and data containing payloads.

### API Style: AO Message-Based

**Pattern:** Processes register handlers for specific `Action` tags. Users/agents send messages with:
- **Tags**: Key-value metadata (e.g., `Action: "RegisterSkill"`, `Param1: "value"`)
- **Data**: String payload (JSON for complex data, plain text for simple)

**Example Message Structure:**

```lua
-- Sending a message (from CLI/agent)
ao.send({
  Target = "REGISTRY_PROCESS_ID",
  Tags = {
    { name = "Action", value = "SearchSkills" },
    { name = "Tags", value = "security,react" },
    { name = "Limit", value = "10" }
  }
})

-- Handler receives:
msg.Tags["Action"]  -- "SearchSkills"
msg.Tags["Tags"]    -- "security,react"
msg.Tags["Limit"]   -- "10"
msg.From            -- Sender's AO address
```

**Response Pattern:**
Processes send reply messages back to `msg.From` with results in `Data` field (typically JSON).

### Registry Process Handlers

**Base Process ID:** `<REGISTRY_PROCESS_ID>` (deployed during MVP launch)

#### Handler: RegisterSkill

**Purpose:** Register a new skill in the marketplace

**Tags:**
- `Action`: "RegisterSkill" (required)
- `TxId`: Arweave transaction ID (43 chars, required)
- `Name`: Skill name (required)
- `Description`: Skill description (required)
- `Tags`: Comma-separated tags (optional, e.g., "security,react")
- `RoyaltyPercent`: Percentage 0-100 (required)
- `Creator`: AO wallet address (required)
- `Dependencies`: JSON array of TX IDs (optional, e.g., `["tx1","tx2"]`)

**Data:** None (all params in tags)

**Response:**
```json
{
  "success": true,
  "skillTxId": "arweave_tx_id_43_chars",
  "message": "Skill registered successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Invalid TX ID format",
  "code": "VALIDATION_ERROR"
}
```

#### Handler: SearchSkills

**Purpose:** Query skills by tags, keywords, or creator

**Tags:**
- `Action`: "SearchSkills" (required)
- `Tags`: Comma-separated tags for filtering (optional, AND logic)
- `Keyword`: Search term for name/description (optional)
- `Creator`: Filter by creator address (optional)
- `SortBy`: Field to sort by (optional, default: "usageCount")
- `Limit`: Results per page (optional, default: 10, max: 100)
- `Offset`: Pagination offset (optional, default: 0)

**Data:** None

**Response:**
```json
{
  "skills": [
    {
      "txId": "skill_tx_id",
      "name": "React Security Review",
      "description": "...",
      "tags": ["security", "react"],
      "royaltyPercent": 15,
      "creator": "creator_address",
      "metrics": {
        "usageCount": 42,
        "successRate": 0.98,
        "totalRoyalties": 5000000
      }
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

*(Additional handlers documented similarly: RegisterProcess, SearchProcesses, ScoreSkill, GetDependencyGraph, GetMarketplaceStats)*

### Payment-Gated Process Handlers (SDK-Powered)

These handlers are implemented by **process developers** using the Permamind SDK.

#### Handler: Credit-Notice (Automatic)

**Purpose:** Receive AO token deposits for payment gating

**Tags:**
- `Action`: "Credit-Notice" (automatic from AO token transfers)
- `Sender`: Depositor's address
- `Quantity`: Amount in base units

**Response:**
```json
{
  "message": "Deposit confirmed",
  "balance": 2000000,
  "address": "sender_address"
}
```

#### Handler: Balance

**Purpose:** Query deposited balance in process

**Tags:**
- `Action`: "Balance" (required)

**Response:**
```json
{
  "balance": 1500000,
  "address": "msg_from_address"
}
```

#### Handler: Custom Gated Actions (Example: ReviewCode)

**Purpose:** Execute payment-gated AI-powered service

**Tags:**
- `Action`: "ReviewCode" (or any action defined in `permamind.init()`)

**Data:** User's code to review (plain text or JSON)

**Response:**
```json
{
  "result": "AI-generated security review...",
  "skillsUsed": ["react_security_txid", "js_security_txid"],
  "royaltiesPaid": {
    "creator1_address": 150000,
    "creator2_address": 100000
  },
  "cost": 1000000,
  "timestamp": 1731600000
}
```

---

## Components

Major logical components and services across the Permamind architecture.

### Component: Permamind SDK (Lua Library)

**Responsibility:** Provides reusable payment gating, skill composition, and Apus integration logic that process developers embed into their AO contracts.

**Key Interfaces:**
- `permamind.init(config)` - Initialize process with pricing, wallet, skill configuration
- `permamind.gated(action, handler, options)` - Wrap handler with payment verification and royalty distribution
- `permamind.loadSkill(txId)` - Fetch and compose skill context from Arweave
- `permamind.apus.infer(prompt, skillContext)` - Request AI inference with async callback
- `permamind.creditNoticeHandler(msg)` - Automatic deposit tracking (internal)
- `permamind.balanceHandler(msg)` - Query user balance (public handler)
- `permamind.withdrawHandler(msg)` - Process withdrawal requests (public handler)

**Dependencies:**
- **Arweave Gateway** (external) - Fetch skill content via HTTP/gateway process
- **Apus Router Process** (external) - Send inference requests, receive async responses
- **AO Message System** (platform) - Credit-Notice events, message-passing

**Technology Stack:**
- **Language:** Lua 5.3
- **Deployment:** Bundled into each process (embedded library pattern)
- **Distribution:** apm package registry (`@permamind/sdk`)
- **State Management:** Process-local Lua tables (`Balances`, `ProcessedMessages`, `SkillCache`)

**Internal Modules:**
- `sdk/init.lua` - Configuration and initialization
- `sdk/payment-gating.lua` - CEI pattern enforcement, balance management
- `sdk/skill-loading.lua` - Arweave fetching, dependency resolution, caching
- `sdk/apus-integration.lua` - Inference requests, callback handling, credit management
- `sdk/security.lua` - Message ID tracking, replay prevention, validation
- `sdk/utils.lua` - JSON parsing, string utilities, token counting

---

### Component: Registry Process (AO Smart Contract)

**Responsibility:** Centralized marketplace discovery and metrics tracking. Provides searchable catalog of skills and processes, real-time quality metrics, and scoring algorithms for autonomous agent decision-making.

**Key Interfaces:**
- `RegisterSkill` handler - Add new skill to marketplace
- `RegisterProcess` handler - Add new process to marketplace
- `SearchSkills` handler - Query skills with filters and pagination
- `SearchProcesses` handler - Query processes with filters and pagination
- `ScoreSkill` handler - Calculate weighted quality score
- `GetDependencyGraph` handler - Retrieve skill dependency tree
- `GetMarketplaceStats` handler - Aggregate analytics
- `Credit-Notice` listener (passive) - Update metrics from payment events
- `Refund-Notice` listener (passive) - Update success rates from refunds

**Dependencies:**
- **Arweave** (read-only) - Validate skill TX IDs exist
- **AO Message System** - Receive queries, send responses, listen to network events

**Technology Stack:**
- **Language:** Lua 5.3
- **Deployment:** Single AO process on mainnet
- **State Management:** In-memory Lua tables with automatic AO persistence to Arweave
- **Data Structures:** `Skills[txId]`, `Processes[processId]`, `SkillMetrics[txId]`, `ProcessMetrics[processId]`

---

### Component: CLI Tool (TypeScript Application)

**Responsibility:** Developer-facing command-line interface for process scaffolding, deployment, skill publishing, wallet management, and marketplace interaction.

**Key Interfaces:**
- `permamind init <project-name>` - Scaffold new payment-gated process
- `permamind publish <directory>` - Deploy process and register in marketplace
- `permamind skill-upload <file>` - Upload skill to Arweave and register
- `permamind wallet-check` - Display AR and AO balances
- `permamind search skills [options]` - Query Registry for skills
- `permamind search processes [options]` - Query Registry for processes
- `permamind skill-graph <txId>` - Visualize dependency tree
- `permamind test <directory>` - Run local tests with aolite
- `permamind estimate <processId> <action>` - Calculate cost before payment

**Dependencies:**
- **@permaweb/aoconnect** - Send AO messages, deploy processes
- **arweave-js** - Upload skills, manage AR wallet
- **aos CLI** - Process deployment (shell execution)
- **aolite** - Local testing framework (shell execution)
- **Registry Process** - Query marketplace data
- **Arweave Gateway** - Fetch skills for dependency graph

**Technology Stack:**
- **Language:** TypeScript 5.3+
- **Runtime:** Node.js 18+
- **Framework:** Commander.js (CLI structure)
- **UI Libraries:** Inquirer (prompts), Chalk (colors), Ora (spinners)
- **Build:** tsc (TypeScript compiler)
- **Distribution:** npm registry (`npm install -g @permamind/cli`)

---

### Component: Payment-Gated Processes (Developer-Created)

**Responsibility:** Individual AI services built by third-party developers using the Permamind SDK. Accept payments, compose skill context, call Apus inference, return results, distribute royalties.

**Key Interfaces:**
- Custom gated actions (e.g., `ReviewCode`, `AnalyzeData`) - Defined by process developer
- `Balance` handler - Inherited from SDK
- `Withdraw` handler - Inherited from SDK
- `Credit-Notice` handler - Inherited from SDK (automatic)

**Dependencies:**
- **Permamind SDK** (embedded) - All core functionality
- **Skills on Arweave** - Load domain expertise
- **Apus Router** - AI inference
- **Registry Process** - Self-registration (via CLI)

**Technology Stack:**
- **Language:** Lua 5.3
- **Deployment:** Independent AO processes (one per service)
- **State Management:** Process-local (user balances, message IDs, skill cache, Apus credits)

---

## External APIs

### API: Arweave Gateway

**Purpose:** Retrieve permanently stored skill content by transaction ID.

**Documentation:** https://docs.arweave.org/developers/server/http-api

**Base URL(s):**
- Primary: `https://arweave.net`
- Fallback: `https://ar-io.net` (decentralized gateway network)

**Authentication:** None required for read operations (public data)

**Rate Limits:** None officially documented; gateway-dependent (~1000 req/min safe assumption)

**Key Endpoints Used:**

- `GET /{transaction_id}` - Fetch transaction data (skill content)
- `GET /tx/{transaction_id}` - Get transaction metadata

**Integration Notes:**
- **Caching Strategy:** SDK caches fetched skills in process state (`SkillCache[txId] = content`)
- **Fallback Pattern:** If primary gateway fails (timeout >10s), retry with fallback gateway
- **Performance:** Typical latency 200-500ms for cached TX, 5-10s for uncached

---

### API: Apus Router Process (AO Message-Based)

**Purpose:** Submit AI inference requests with composed skill context and receive async results.

**Documentation:** https://docs.apus.network (assumed; verify actual URL)

**Router Process ID:** `TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g` (hardcoded in SDK)

**Authentication:** AO message signature (automatic via `ao.send()`)

**Key Operations:**

**Inference Request** (via AO message)
- **Tags:**
  - `Action: "Inference"`
  - `Model: "Gemma3-27B"`
  - `Callback-Target: <requesting_process_id>`
  - `Message-Reference: <unique_request_id>`
- **Data:** Combined prompt (skill context + user input, max 8,192 tokens)
- **Response:** Async message to `Callback-Target` with inference result in `Data`
- **Latency:** ~50s P95 (per PRD assumptions)

**Integration Notes:**
- **Async Pattern Required:** SDK registers callback handler to receive results (cannot block for ~50s)
- **Request-Response Matching:** Use `Message-Reference` tag to correlate requests with responses
- **Timeout Handling:** If no response within 120s, consider inference failed and issue refund
- **Retry Logic:** Transient failures (timeout, network) retry 3x with exponential backoff

---

### API: AO Network (Platform)

**Purpose:** Foundational compute and message-passing infrastructure.

**Documentation:** https://ao.arweave.dev (official AO docs)

**Key Operations:**

**Send Message** (via `aoconnect.message()` from CLI)
- **Purpose:** Send message to any AO process from external client

**Deploy Process** (via `aos` CLI or `aoconnect.spawn()`)
- **Purpose:** Create new AO process and upload Lua code

**Credit-Notice Events** (automatic AO token transfers)
- **Purpose:** Notify processes of incoming token deposits
- **Format:** AO message with tags `Action: Credit-Notice`, `Sender: <address>`, `Quantity: <amount>`

---

## Core Workflows

### Workflow 1: User Pays for AI Service and Receives Result

```mermaid
sequenceDiagram
    participant User
    participant Process as Payment-Gated Process
    participant SDK as Permamind SDK
    participant Arweave
    participant Apus as Apus Router
    participant Creators as Skill Creators
    participant Registry

    Note over User,Registry: Phase 1: Payment Deposit
    User->>Process: Credit-Notice (1,000,000 AO tokens)
    Process->>SDK: creditNoticeHandler(msg)
    SDK->>SDK: Validate message ID (replay check)
    SDK->>SDK: Update Balances[User] += 1,000,000
    SDK->>SDK: Store ProcessedMessages[msg.Id] = true
    SDK->>User: Confirmation (Balance: 1,000,000)

    Note over User,Registry: Phase 2: Service Request
    User->>Process: ReviewCode Action + code data
    Process->>SDK: gated("ReviewCode", handler)
    SDK->>SDK: Check Balances[User] >= 1,000,000 ✓
    SDK->>SDK: Deduct balance: Balances[User] -= 1,000,000

    Note over User,Registry: Phase 3: Skill Composition
    SDK->>Arweave: GET /react_security_txid
    Arweave-->>SDK: Skill content (markdown)
    SDK->>SDK: Resolve dependencies (JS Security, General Security)
    SDK->>Arweave: GET /js_security_txid
    Arweave-->>SDK: Skill content
    SDK->>Arweave: GET /general_security_txid
    Arweave-->>SDK: Skill content
    SDK->>SDK: Compose context (3 skills combined)
    SDK->>SDK: Validate token count < 6,000 ✓

    Note over User,Registry: Phase 4: Royalty Distribution
    SDK->>SDK: Calculate royalties (React: 15%, JS: 10%, Gen: 5%)
    SDK->>Creators: Credit-Notice (150,000 to React creator)
    SDK->>Creators: Credit-Notice (100,000 to JS creator)
    SDK->>Creators: Credit-Notice (50,000 to Gen creator)
    SDK->>Registry: Credit-Notice events (passive listening)
    Registry->>Registry: Update skill metrics (usageCount++, totalRoyalties+=)

    Note over User,Registry: Phase 5: AI Inference
    SDK->>Apus: Inference request (skill context + user code)
    Note over Apus: ~50 second processing
    Apus-->>Process: Async callback (security review result)
    SDK->>SDK: Match response to request via msg.Reference

    Note over User,Registry: Phase 6: Result Delivery
    Process->>User: Security review result (AI-generated)
    Registry->>Registry: Update process metrics (txCount++, latency)
```

---

### Workflow 2: Error Handling - Apus Inference Failure with Refund

```mermaid
sequenceDiagram
    participant User
    participant Process
    participant SDK
    participant Apus
    participant Registry

    User->>Process: Credit-Notice (1,000,000 AO) + ReviewCode action
    Process->>SDK: gated("ReviewCode", handler)
    SDK->>SDK: Deduct balance (Balances[User] -= 1M)
    SDK->>SDK: Load skills + compose context
    SDK->>SDK: Distribute royalties (300,000 to creators)

    Note over SDK,Apus: Attempt 1
    SDK->>Apus: Inference request
    Note over Apus: Timeout after 120s (no response)
    SDK->>SDK: No response received → retry

    Note over SDK,Apus: Attempt 2 (after 2s backoff)
    SDK->>Apus: Inference request (same prompt)
    Note over Apus: Apus error: "Model temporarily unavailable"
    Apus-->>SDK: Error response
    SDK->>SDK: Transient error → retry

    Note over SDK,Apus: Attempt 3 (after 4s backoff)
    SDK->>Apus: Inference request
    Note over Apus: Timeout again
    SDK->>SDK: Max retries exceeded → refund user

    Note over SDK,Registry: Refund Flow
    SDK->>SDK: Restore balance: Balances[User] += 700,000 (1M - 300K royalties)
    Note over SDK: Royalties already paid are NOT refunded (creator compensation)
    SDK->>User: Error message + partial refund notice
    SDK->>Registry: Refund-Notice (processId, amount, reason)
    Registry->>Registry: Increment refundCount
    Registry->>Registry: Recalculate successRate = (txCount - refunds) / txCount
    Registry->>Registry: Update ProcessMetrics (lower score)

    SDK->>Process: Log failure (timestamp, user, action, error)
```

---

## Database Schema

Permamind uses **AO's built-in state persistence** instead of traditional databases. All data is stored in Lua tables within process memory and automatically persisted to Arweave after each message handler execution.

### Schema: Registry Process State

#### Table: Skills

**Purpose:** Store registered skill metadata and references

**Lua Structure:**
```lua
Skills = {
  ["arweave_tx_id_43_chars"] = {
    txId = "arweave_tx_id_43_chars",           -- Primary key (Arweave TX ID)
    name = "React Security Review",
    description = "Expert security analysis for React components...",
    version = "1.0.0",
    creator = "ao_wallet_address_43_chars",
    royaltyPercent = 15,                       -- Number: 0-100
    dependencies = {                           -- Array of skill TX IDs
      "js_security_txid_43_chars",
      "general_security_txid_43_chars"
    },
    tags = { "security", "react", "javascript" }, -- Array of strings
    createdAt = 1731600000,                    -- Unix timestamp
    tokenCount = 1200                          -- Estimated tokens for context limit
  },
  -- ... more skills indexed by txId
}
```

**Indexes:** Primary: `txId` (Lua table key)

**Constraints:**
- `txId` must be 43 characters (validated on insert)
- `royaltyPercent` must be 0-100 (validated on insert)
- `dependencies` array elements must reference existing skills (validated on insert)

---

#### Table: Processes

**Purpose:** Store registered payment-gated process metadata

**Lua Structure:**
```lua
Processes = {
  ["ao_process_id_43_chars"] = {
    processId = "ao_process_id_43_chars",      -- Primary key (AO address)
    name = "Code Security Reviewer",
    description = "AI-powered security analysis for code...",
    capabilities = { "code-review", "security", "react" }, -- Array
    pricing = {                                -- Table: action -> amount
      ReviewCode = 1000000,                    -- In AO token base units
      QuickScan = 500000
    },
    skills = {                                 -- Array of skill TX IDs used
      "react_security_txid_43_chars"
    },
    creator = "ao_wallet_address_43_chars",
    version = "1.0.0",
    createdAt = 1731600000,                    -- Unix timestamp
    updatedAt = 1731600000                     -- Unix timestamp (re-registration updates)
  },
  -- ... more processes indexed by processId
}
```

---

#### Table: SkillMetrics

**Purpose:** Real-time quality metrics for skills, updated on Credit-Notice events

**Lua Structure:**
```lua
SkillMetrics = {
  ["skill_txid_43_chars"] = {
    skillTxId = "skill_txid_43_chars",         -- Foreign key to Skills
    usageCount = 42,                           -- Total uses across all processes
    activeProcessCount = 5,                    -- Processes currently using this skill
    totalRoyalties = 5000000,                  -- Total AO tokens earned (cumulative)
    avgRoyaltyPerUse = 119047,                 -- Calculated: totalRoyalties / usageCount
    refundRate = 0.02,                         -- 0.0 to 1.0 (2% refund rate)
    successRate = 0.98,                        -- 1.0 - refundRate
    lastUsed = 1731700000,                     -- Unix timestamp of most recent usage
    qualityScore = 87.5                        -- 0-100 composite score
  },
  -- ... metrics for each skill
}
```

---

### Schema: Payment-Gated Process State (SDK-Managed)

#### Table: Balances

**Purpose:** Track user deposited balances for payment gating

**Lua Structure:**
```lua
Balances = {
  ["user_ao_address_43_chars"] = 1500000,     -- Address -> AO token balance
  ["another_user_address"] = 2000000,
  -- ... one entry per user who has deposited
}
```

**Update Triggers:**
- `Credit-Notice` → `Balances[sender] = (Balances[sender] or 0) + amount`
- Gated action → `Balances[user] = Balances[user] - price`
- `Withdraw` → `Balances[user] = Balances[user] - withdrawAmount`

---

#### Table: ProcessedMessages

**Purpose:** Prevent replay attacks by tracking processed message IDs

**Lua Structure:**
```lua
ProcessedMessages = {
  ["message_id_43_chars"] = true,             -- Message ID -> boolean (set membership)
  ["another_message_id"] = true,
  -- ... grows over time
}
```

**Update Triggers:**
- Every `Credit-Notice` → `ProcessedMessages[msg.Id] = true`
- Check before processing: `if ProcessedMessages[msg.Id] then error("Duplicate") end`

---

#### Table: SkillCache

**Purpose:** Cache fetched skills to avoid redundant Arweave gateway calls

**Lua Structure:**
```lua
SkillCache = {
  ["skill_txid_43_chars"] = {
    content = "# React Security Review\n\nExpertise for...",
    fetchedAt = 1731600000,                    -- Unix timestamp
    tokenCount = 1200
  },
  -- ... one entry per skill loaded by this process
}
```

---

## Frontend Architecture (CLI)

**Note:** Permamind MVP is **CLI-first** with no web UI. This section documents the command-line interface architecture.

### CLI Architecture Overview

The CLI serves as the "frontend" for human developers, providing terminal-based interaction with the Permamind ecosystem.

### Command Organization

**File Structure:**
```
cli/src/
├── index.ts                    # Entry point, commander setup
├── commands/
│   ├── init.ts                 # permamind init
│   ├── publish.ts              # permamind publish
│   ├── skill-upload.ts         # permamind skill-upload
│   ├── wallet-check.ts         # permamind wallet-check
│   ├── search.ts               # permamind search (skills/processes)
│   ├── skill-graph.ts          # permamind skill-graph
│   ├── test.ts                 # permamind test
│   └── estimate.ts             # permamind estimate
├── utils/
│   ├── wallet.ts               # AR/AO wallet management
│   ├── arweave.ts              # Arweave upload and queries
│   ├── ao.ts                   # AO message sending via aoconnect
│   ├── formatting.ts           # Table display, tree visualization
│   ├── validation.ts           # Input validation (TX IDs, addresses)
│   └── spinner.ts              # Progress indicators with ora
├── templates/
│   └── process-template.lua    # Boilerplate for permamind init
└── types/
    └── index.ts                # TypeScript interfaces (Skill, Process, etc.)
```

### Command Pattern

Each command follows this structure:

```typescript
// cli/src/commands/example.ts
import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';

export function registerExampleCommand(program: Command) {
  program
    .command('example <arg>')
    .description('Description of what this command does')
    .option('-f, --flag', 'Optional flag description')
    .action(async (arg, options) => {
      // 1. Validate inputs
      if (!isValid(arg)) {
        console.error(chalk.red('Error: Invalid argument'));
        process.exit(1);
      }

      // 2. Show progress
      const spinner = ora('Processing...').start();

      try {
        // 3. Execute logic
        const result = await doWork(arg, options);

        // 4. Success output
        spinner.succeed(chalk.green('Success!'));
        console.log(result);

      } catch (error) {
        // 5. Error handling
        spinner.fail(chalk.red('Failed'));
        console.error(error.message);
        process.exit(1);
      }
    });
}
```

---

## Backend Architecture

The "backend" in Permamind consists of Lua code running on AO processes. There are no traditional servers; instead, we have **message-driven smart contracts** with embedded logic.

### Service Architecture: AO Process Pattern

Permamind uses a **process-per-service** architecture:

1. **SDK (Library)** - Embedded in each payment-gated process
2. **Registry Process** - Single centralized marketplace index
3. **Payment-Gated Processes** - Developer-created services (N processes)

### SDK Core: Payment Gating Implementation (CEI Pattern)

**Checks-Effects-Interactions (CEI) Enforcement:**

```lua
-- sdk/payment-gating.lua
local M = {}

-- Global state (managed by SDK)
Balances = Balances or {}
ProcessedMessages = ProcessedMessages or {}
Config = Config or {}

function M.createGatedHandler(actionName, userHandler, options)
  return function(msg)
    -- CHECKS: Validate before any state changes

    -- 1. Replay attack prevention
    if ProcessedMessages[msg.Id] then
      error("Duplicate message (replay attack)")
    end

    -- 2. Check user balance
    local price = Config.pricing[actionName]
    assert(price, "Action not configured: " .. actionName)

    local balance = Balances[msg.From] or 0
    if balance < price then
      ao.send({
        Target = msg.From,
        Data = json.encode({
          error = "Insufficient balance",
          required = price,
          current = balance
        })
      })
      return
    end

    -- EFFECTS: Update state before external interactions

    -- 3. Deduct balance BEFORE executing handler
    Balances[msg.From] = balance - price
    ProcessedMessages[msg.Id] = true

    -- 4. Calculate and distribute royalties
    if options and options.skills then
      local royalties = calculateRoyalties(options.skills, price)
      for creator, amount in pairs(royalties) do
        ao.send({
          Target = "AO_TOKEN_PROCESS",
          Tags = {
            { name = "Action", value = "Transfer" },
            { name = "Recipient", value = creator },
            { name = "Quantity", value = tostring(amount) },
            { name = "Royalty-For", value = options.skills[1] }
          }
        })
      end
    end

    -- INTERACTIONS: External calls AFTER state updates

    -- 5. Execute user's handler (may call Apus, Arweave, etc.)
    local success, result = pcall(userHandler, msg)

    if not success then
      -- Handler failed → issue refund
      local refundAmount = price - calculateTotalRoyalties(options.skills, price)
      Balances[msg.From] = Balances[msg.From] + refundAmount

      ao.send({
        Target = msg.From,
        Data = json.encode({
          error = "Processing failed",
          refunded = refundAmount
        })
      })
    end
  end
end

return M
```

---

## Unified Project Structure

Complete directory structure for the Permamind monorepo with npm workspaces.

```plaintext
permamind/
├── .github/                          # CI/CD workflows
│   └── workflows/
│       ├── ci.yaml                   # Run tests on push/PR
│       ├── npm-publish.yaml          # Publish CLI to npm registry
│       └── apm-publish.yaml          # Publish SDK to apm (future)
│
├── sdk/                              # Permamind SDK (Lua)
│   ├── permamind.lua                 # Main entry point, public API
│   ├── init.lua                      # Configuration and initialization
│   ├── payment-gating.lua            # CEI pattern, balance management
│   ├── skill-loading.lua             # Arweave fetching, dependency resolution
│   ├── apus-integration.lua          # Inference requests, callbacks
│   ├── security.lua                  # Message ID tracking, replay prevention
│   ├── utils.lua                     # JSON parsing, string utilities
│   ├── package.json                  # Metadata (for apm distribution)
│   └── README.md                     # SDK usage documentation
│
├── registry/                         # Registry Process (Lua)
│   ├── registry.lua                  # Main process file, handler registration
│   ├── utils.lua                     # JSON, tag parsing, validation
│   ├── search.lua                    # Filtering, sorting, pagination
│   ├── scoring.lua                   # Quality score calculation
│   ├── metrics.lua                   # Real-time metrics aggregation
│   ├── dependency-graph.lua          # DFS traversal, cycle detection
│   ├── repositories/                 # Data access layer
│   │   ├── skill-repository.lua
│   │   └── process-repository.lua
│   ├── deploy.sh                     # Deployment script (aos CLI)
│   └── README.md                     # Registry deployment guide
│
├── cli/                              # CLI Tool (TypeScript/Node.js)
│   ├── src/
│   │   ├── index.ts                  # Entry point, commander setup
│   │   ├── commands/                 # Command implementations
│   │   │   ├── init.ts               # permamind init
│   │   │   ├── publish.ts            # permamind publish
│   │   │   ├── skill-upload.ts       # permamind skill-upload
│   │   │   ├── wallet-check.ts       # permamind wallet-check
│   │   │   ├── search.ts             # permamind search
│   │   │   ├── skill-graph.ts        # permamind skill-graph
│   │   │   ├── test.ts               # permamind test
│   │   │   └── estimate.ts           # permamind estimate
│   │   ├── schemas/                  # JSON schema validation
│   │   │   └── process-schema.ts     # Zod schema for process.json
│   │   ├── utils/                    # Utility modules
│   │   │   ├── wallet.ts             # AR/AO wallet management
│   │   │   ├── arweave.ts            # Arweave upload and queries
│   │   │   ├── ao.ts                 # AO message sending (aoconnect)
│   │   │   ├── formatting.ts         # Table display, tree visualization
│   │   │   ├── validation.ts         # Input validation (TX IDs, etc.)
│   │   │   ├── process-validator.ts  # process.json validation utilities
│   │   │   └── spinner.ts            # Progress indicators
│   │   ├── templates/                # Boilerplate templates
│   │   │   ├── process-template.lua  # Default process scaffold
│   │   │   └── process.json.template # Metadata template
│   │   └── types/                    # TypeScript interfaces
│   │       └── index.ts              # Skill, Process, Metrics types
│   ├── dist/                         # Compiled JavaScript (gitignored)
│   ├── tests/                        # Jest tests
│   │   ├── commands/                 # Command unit tests
│   │   └── utils/                    # Utility unit tests
│   ├── package.json                  # Dependencies, scripts, bin config
│   ├── tsconfig.json                 # TypeScript configuration
│   ├── .eslintrc.js                  # ESLint rules
│   ├── .prettierrc                   # Prettier config
│   └── README.md                     # CLI usage and installation
│
├── examples/                         # Example processes and skills
│   ├── skills/                       # Example skill markdown
│   │   ├── general-security.md       # General Security Principles
│   │   ├── javascript-security.md    # JavaScript Security Best Practices
│   │   ├── react-security.md         # React Security Reviewer
│   │   ├── data-analysis.md          # Data Analysis Techniques
│   │   └── skill-registry.json       # Published TX IDs for reference
│   ├── code-review/                  # Code Review Process example
│   │   ├── src/
│   │   │   └── process.lua           # Payment-gated code review process
│   │   ├── tests/
│   │   │   └── code-review.test.lua  # aolite tests
│   │   ├── process.json              # Process metadata
│   │   ├── deploy.sh                 # Deployment script
│   │   └── README.md                 # Setup and usage guide
│   ├── data-analyzer/                # Data Analysis Process example
│   │   ├── src/
│   │   │   └── process.lua
│   │   ├── tests/
│   │   │   └── data-analyzer.test.lua
│   │   ├── process.json
│   │   └── README.md
│   └── hello-world/                  # Simple payment-gated example
│       ├── process.lua               # Minimal SDK usage
│       └── README.md                 # Tutorial walkthrough
│
├── tests/                            # Integration and unit tests
│   ├── integration/                  # aolite integration tests
│   │   ├── payment-flow.test.lua     # End-to-end payment workflow
│   │   ├── skill-loading.test.lua    # Skill composition tests
│   │   ├── apus-integration.test.lua # Mocked Apus inference tests
│   │   └── registry-queries.test.lua # Registry search tests
│   ├── unit/                         # SDK unit tests (aolite)
│   │   ├── payment-gating.test.lua   # CEI pattern tests
│   │   ├── security.test.lua         # Replay attack prevention tests
│   │   └── utils.test.lua            # Utility function tests
│   ├── load/                         # Performance/load tests
│   │   ├── registry-load-test.ts     # Registry concurrent query testing
│   │   ├── package.json              # Load test dependencies
│   │   └── README.md                 # Load testing guide
│   ├── setup.lua                     # Test environment setup
│   └── README.md                     # Testing guide
│
├── docs/                             # Documentation
│   ├── prd.md                        # Product Requirements Document
│   ├── architecture.md               # This file (architecture document)
│   ├── quick-start.md                # Developer quick start guide
│   ├── sdk-reference.md              # SDK API reference
│   ├── skill-creator-guide.md        # Skill creator documentation
│   ├── agent-integration.md          # Agent integration guide
│   ├── security-guide.md             # Security best practices
│   ├── wallet-setup.md               # Wallet setup instructions
│   ├── skill-schema.md               # Skill metadata schema
│   ├── registry-deployment.md        # Registry deployment guide
│   ├── apus-integration.md           # Apus integration details
│   ├── testing-report.md             # QA testing results
│   └── security-audit-summary.md     # Audit findings (future)
│
├── scripts/                          # Build and deployment scripts
│   ├── deploy-registry.sh            # Deploy Registry to AO mainnet
│   ├── publish-example-skills.sh     # Upload all example skills
│   ├── test-all.sh                   # Run all tests (aolite + Jest)
│   └── version-bump.sh               # Synchronize versions across packages
│
├── .gitignore                        # Git ignore patterns
├── .env.example                      # Example environment variables
├── package.json                      # Root package.json (workspaces)
├── package-lock.json                 # Lock file
├── README.md                         # Project overview and setup
├── LICENSE                           # License file
└── CONTRIBUTING.md                   # Contribution guidelines
```

---

## Development Workflow

### Local Development Setup

#### Prerequisites

**Required Software:**

```bash
# Check versions
node --version          # v18+ required
npm --version           # v9+ required
git --version           # Any recent version

# AO tooling
aos --version           # Latest AO CLI
apm --version           # AO package manager (optional)

# Lua (for syntax checking)
lua -v                  # Lua 5.3
```

#### Initial Setup

**Step 1: Clone Repository**

```bash
git clone https://github.com/permamind/permamind.git
cd permamind
```

**Step 2: Install Dependencies**

```bash
# Install all workspace dependencies
npm install
```

**Step 3: Environment Configuration**

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your credentials
nano .env
```

**.env File Contents:**

```bash
# Arweave Wallet (choose one method)
ARWEAVE_WALLET_PATH=/path/to/wallet.json

# AO Wallet (from seed phrase)
SEED_PHRASE="your 12 word mnemonic seed phrase here"

# Network Selection
PERMAMIND_NETWORK=testnet                           # mainnet | testnet

# Registry Process ID (override for testing)
REGISTRY_PROCESS_ID=                                # Leave blank to use default

# Apus Router (override for testing)
APUS_ROUTER_PROCESS_ID=TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g

# Development Mode
VERBOSE=false                                       # Set to true for debug logs
```

**Step 4: Build CLI**

```bash
cd cli
npm run build                       # Compiles TypeScript to dist/

# Link CLI globally for local development
npm link                            # Creates global 'permamind' command

# Verify installation
permamind --version
permamind --help
```

---

## Deployment Architecture

### Deployment Strategy

#### CLI Deployment

**Distribution Method:** npm registry

**Package Name:** `@permamind/cli`

**Deployment Pipeline (GitHub Actions):**

```yaml
# .github/workflows/npm-publish.yaml
name: Publish CLI to npm

on:
  push:
    tags:
      - 'v*.*.*'                # Triggered by version tag (e.g., v1.0.0)

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          registry-url: 'https://registry.npmjs.org'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm run test

      - name: Build CLI
        run: |
          cd cli
          npm run build

      - name: Publish to npm
        run: |
          cd cli
          npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

#### Registry Process Deployment

**Deployment Target:** AO Mainnet (single long-lived process)

**Deployment Method:** Manual deployment via aos CLI

**Deployment Process:**

```bash
cd registry

# 1. Pre-deployment checks
./pre-deploy-checklist.sh

# 2. Deploy to AO
aos                            # Start aos CLI
.load registry.lua             # Load process code
# Process spawns and receives new process ID

# 3. Save process ID
echo "REGISTRY_PROCESS_ID=abc123...xyz789" > .deployed

# 4. Initialize state (first deployment only)
Send({ Target = ao.id, Action = "Initialize" })

# 5. Update documentation
# Update docs/architecture.md with new process ID
# Update CLI default REGISTRY_PROCESS_ID

# 6. Verify deployment
Send({ Target = ao.id, Action = "GetMarketplaceStats" })
```

---

### Environments

| Environment | Purpose | Registry Process | CLI Version | Network |
|-------------|---------|------------------|-------------|---------|
| **Development** | Local testing | Local aolite simulation | Source code (npm link) | N/A (local) |
| **Testnet** | Pre-production validation | Deployed Registry (testnet) | Release candidate | AO testnet |
| **Production** | Live marketplace | Deployed Registry (mainnet) | Stable release | AO mainnet |

---

## Security and Performance

### Security Requirements

#### SDK Security (Critical - Handles User Funds)

**1. Checks-Effects-Interactions (CEI) Pattern**

```lua
function gatedHandler(msg)
  -- CHECKS: Validate ALL inputs before state changes
  assert(msg.From, "Missing sender")
  assert(Balances[msg.From] >= price, "Insufficient balance")
  assert(not ProcessedMessages[msg.Id], "Duplicate message")

  -- EFFECTS: Update state BEFORE external calls
  Balances[msg.From] = Balances[msg.From] - price
  ProcessedMessages[msg.Id] = true

  -- INTERACTIONS: External calls LAST (Apus, royalties)
  distributeRoyalties(...)
  callApusInference(...)
end
```

**2. Replay Attack Prevention**

```lua
ProcessedMessages = ProcessedMessages or {}

-- In every Credit-Notice handler
if ProcessedMessages[msg.Id] then
  error("Duplicate message ID - replay attack detected")
end

ProcessedMessages[msg.Id] = true
```

**3. Input Validation**

```lua
function validateInput(txId, amount)
  if #txId ~= 43 then
    error("Invalid TX ID: must be 43 characters (got: " .. #txId .. ")")
  end

  if amount <= 0 then
    error("Invalid amount: must be positive (got: " .. amount .. ")")
  end
end
```

---

### Performance Optimization

#### SDK Performance

**1. Skill Caching Strategy**

```lua
SkillCache = SkillCache or {}

function loadSkill(txId)
  -- Check cache first (O(1) lookup)
  if SkillCache[txId] then
    return SkillCache[txId].content
  end

  -- Fetch from Arweave (5-10s latency)
  local content = fetchFromArweave(txId)

  -- Cache indefinitely (skills are immutable)
  SkillCache[txId] = {
    content = content,
    fetchedAt = os.time(),
    tokenCount = estimateTokens(content)
  }

  return content
end
```

**Performance Gain:**
- First load: ~5-10 seconds (Arweave gateway)
- Cached load: <10ms (Lua table lookup)
- 99% reduction in latency for repeat uses

---

### Performance Targets (from PRD NFRs)

| Metric | Target | Measurement | Status |
|--------|--------|-------------|--------|
| Registry query latency (P95) | <1 second | aoconnect.results() timing | ✅ Achievable with linear scan |
| Transaction completion (P95) | <60 seconds | Payment → result delivery | ⚠️ Dominated by Apus (~50s) |
| Transaction success rate | >95% | (txCount - refunds) / txCount | ✅ Depends on Apus reliability |
| Apus inference success | >95% | Apus callback received / requests | ⚠️ External dependency |
| Skill dependency resolution | <30 seconds | Within AO execution limit | ✅ Caching ensures <5s |
| Registry concurrent queries | 100+ | Load testing with aoconnect | ✅ AO process handles concurrency |

---

## Testing Strategy

### Testing Pyramid

```
           E2E Tests (5%)
          /            \
     Integration Tests (30%)
    /                      \
Unit Tests (65%)
```

**Distribution:**
- **Unit Tests (65%):** Fast, isolated, high coverage (>80% line coverage)
- **Integration Tests (30%):** Component interactions, aolite simulation
- **E2E Tests (5%):** Full workflows on testnet, manual validation

### Test Organization

#### SDK Unit Tests (aolite)

**Location:** `tests/unit/`

**Test Files:**
```
tests/unit/
├── payment-gating.test.lua       # CEI pattern, balance management
├── security.test.lua              # Replay attack prevention
├── skill-loading.test.lua         # Arweave fetching, caching
├── apus-integration.test.lua      # Inference requests (mocked)
├── utils.test.lua                 # JSON parsing, validation
└── royalty-calculation.test.lua   # Royalty split logic
```

**Example Unit Test:**

```lua
-- tests/unit/payment-gating.test.lua
describe("Payment Gating", function()
  local permamind

  before_each(function()
    -- Reset state between tests
    Balances = {}
    ProcessedMessages = {}

    permamind = require("sdk.payment-gating")
    permamind.init({ pricing = { TestAction = 1000 } })
  end)

  it("should accept valid Credit-Notice and update balance", function()
    local msg = {
      Id = "msg_001",
      From = "token_process",
      Tags = {
        Sender = "user_001",
        Quantity = "5000"
      }
    }

    permamind.creditNoticeHandler(msg)

    assert.equal(5000, Balances["user_001"])
    assert.is_true(ProcessedMessages["msg_001"])
  end)

  it("should reject duplicate Credit-Notice (replay attack)", function()
    local msg = { Id = "msg_002", Tags = { Sender = "user_001", Quantity = "1000" } }

    -- First call succeeds
    permamind.creditNoticeHandler(msg)
    assert.equal(1000, Balances["user_001"])

    -- Second call fails
    assert.has_error(function()
      permamind.creditNoticeHandler(msg)
    end, "Duplicate message")
  end)
end)
```

---

## Coding Standards

**MINIMAL but CRITICAL** standards focused on project-specific rules that prevent common mistakes.

### Critical Fullstack Rules

**1. CEI Pattern Enforcement**
- **Rule:** ALL payment handlers MUST follow Checks-Effects-Interactions pattern
- **Check:** Validate inputs
- **Effect:** Update state (balances, message IDs)
- **Interaction:** External calls (Apus, royalties) LAST

**2. Message ID Tracking**
- **Rule:** ALWAYS track ProcessedMessages[msg.Id] for Credit-Notice handlers
- **Purpose:** Prevent replay attacks

**3. Input Validation Before Processing**
- **Rule:** Validate ALL user inputs BEFORE any state changes
- **Apply to:** TX IDs, addresses, amounts, tags

**4. Skill Context Token Limits**
- **Rule:** ALWAYS validate composed skill context < 6,000 tokens before Apus call

**5. Error Messages Must Be Actionable**
- **Bad:** `"Invalid input"`
- **Good:** `"TX ID must be 43 characters (got: 42)"`

**6. No Hardcoded Secrets**
- **Rule:** NEVER hardcode wallet private keys, seed phrases, or API keys
- **Use:** Environment variables only

**7. Royalty Splits Must Sum to ≤30%**
- **Rule:** Total royalty percentage MUST NOT exceed 30% of payment

**8. Async Operations Require Callback Matching**
- **Rule:** Apus inference requests MUST include Message-Reference tag for response matching

---

### Naming Conventions

| Element | Lua (SDK/Registry) | TypeScript (CLI) | Example |
|---------|-------------------|------------------|---------|
| **Functions** | camelCase | camelCase | `loadSkill()`, `validateTxId()` |
| **Variables** | camelCase | camelCase | `balanceAmount`, `txId` |
| **Constants** | UPPER_SNAKE_CASE | UPPER_SNAKE_CASE | `MAX_DEPTH`, `TOKEN_LIMIT` |
| **Global Tables** | PascalCase | N/A (no globals) | `Balances`, `Skills` |
| **Handlers** | PascalCase with Handler suffix | N/A | `CreditNoticeHandler` |
| **Types/Interfaces** | N/A (no types) | PascalCase | `Skill`, `Process` |
| **Files (Lua)** | kebab-case.lua | N/A | `payment-gating.lua` |
| **Files (TS)** | N/A | kebab-case.ts | `skill-upload.ts` |

---

## Error Handling Strategy

### Error Categories and Handling

#### 1. Validation Errors (User Input)

**Category:** Client-side errors, user can fix

**Handling Strategy:**
```lua
-- SDK/Registry: Reject immediately with clear message
function validateInput(txId, amount)
  if #txId ~= 43 then
    error("Invalid TX ID: must be 43 characters (got: " .. #txId .. ")")
  end

  if amount <= 0 then
    error("Invalid amount: must be positive (got: " .. amount .. ")")
  end
end
```

**Response Format (AO Messages):**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid TX ID: must be 43 characters (got: 42)",
    "field": "txId",
    "expected": "43 characters",
    "received": "42 characters"
  }
}
```

---

#### 2. External Service Errors (Transient)

**Category:** Retryable, automatic recovery

**Handling Strategy:**
```lua
-- SDK: Exponential backoff retry
function fetchWithRetry(url, maxAttempts)
  local attempts = 0
  local delays = { 1, 2, 4 }  -- Exponential backoff (seconds)

  while attempts < maxAttempts do
    attempts = attempts + 1

    local success, result = pcall(function()
      return httpGet(url, { timeout = 10 })
    end)

    if success then
      return result
    end

    if not isTransientError(result) then
      error("Permanent error: " .. result)
    end

    if attempts < maxAttempts then
      local delay = delays[attempts] or 4
      sleep(delay)
    end
  end

  error("Max retries exceeded after " .. maxAttempts .. " attempts")
end
```

---

### Refund Policy

**Automatic Refunds:**

1. **Apus Inference Failure:** Refund = payment - royalties already paid
2. **Skill Loading Failure:** Full refund (royalties not yet paid)
3. **Internal Errors:** Full refund (unless royalties already distributed)

---

## Monitoring and Observability

### Monitoring Philosophy

**Core Principle:** All Permamind transactions are **public by design** (on Arweave blockchain).

**MVP Approach:**
- ✅ **Registry-based metrics** (built-in)
- ✅ **Manual log inspection** (AO message logs)
- ✅ **CLI-based queries** (permamind commands)
- ⏸️ **APM/Dashboards** (deferred to post-MVP)

### Monitoring Stack

**MVP:**
- **Registry Process:** Built-in analytics via `GetMarketplaceStats` action
- **AO Message Logs:** Public transaction history (searchable via block explorers)
- **CLI Queries:** `permamind search skills`, `permamind wallet-check`
- **Manual Inspection:** aos CLI, aoconnect scripts

**Post-MVP (Future):**
- **Grafana Dashboards:** Query Registry metrics, visualize trends
- **Alerting:** Webhook notifications for critical events
- **Log Aggregation:** Parse AO messages into searchable database

### Key Metrics

#### Marketplace Health Metrics

**Source:** Registry Process (`GetMarketplaceStats` action)

```typescript
interface MarketplaceStats {
  totalSkills: number;
  totalProcesses: number;
  totalTransactions: number;
  totalVolume: number;
  avgSkillQualityScore: number;
  avgProcessSuccessRate: number;
  topSkills: Skill[];
  topProcesses: Process[];
  last24hTransactions: number;
  timestamp: number;
}
```

**Query:**
```bash
permamind search stats
```

---

## Architecture Validation Report

### Executive Summary

**Overall Architecture Readiness:** ✅ **HIGH** - Ready for development with minor enhancements recommended

**Project Type:** Full-stack (AO Process-based backend + CLI frontend) with unique constraints

**Critical Risks Identified:**
1. Single Registry process as potential bottleneck (mitigated by AO's concurrency handling)
2. Immutable deployment model limits flexibility (inherent to AO, well-documented)
3. External dependency on Apus for core functionality (retry logic + refunds mitigate)

**Key Strengths:**
- **Exceptional security focus**: CEI pattern enforcement, replay attack prevention, comprehensive validation
- **Clear implementation guidance**: Detailed for AI agent implementation with code examples
- **Pragmatic MVP scope**: Defers complexity appropriately (e.g., manual monitoring, CLI-first)
- **Well-documented trade-offs**: Each decision includes rationale and alternatives considered

---

---

## Enhancements Implemented

### Enhancement 1: JSON Schema Validation for process.json

**Location:** `cli/src/schemas/process-schema.ts`

**Purpose:** Prevent deployment errors from malformed process metadata by validating process.json against a strict schema before publish operations.

**Implementation:** Using Zod for runtime validation with TypeScript type inference

**Validated Fields:**
- `name` - Required, 1-100 characters
- `version` - Semantic versioning format (e.g., "1.0.0")
- `description` - Required, 10-1000 characters
- `pricing` - Object with at least one action, positive integer amounts
- `skills` - Array of valid TX IDs (43 chars), max 10 skills
- `capabilities` - Array of 2-50 character strings
- `creator` - Valid 43-character AO address
- `processId` - Valid 43-character AO address (optional, added after deployment)

**Error Messages:**
```
✗ Validation Failed

process.json validation failed:
  • pricing.ReviewCode: Token amount must be positive
  • skills.0: Transaction ID must be exactly 43 characters (got: 42)
  • description: Description must be at least 10 characters

💡 Tip: Check the process.json schema documentation
  Run: permamind init --help
```

**Integration Points:**
- `permamind publish` command validates before deployment
- `permamind init` generates valid process.json from template
- CLI utilities use `loadAndValidateProcessMetadata()` helper

**Benefits:**
- ✅ Catch metadata errors before expensive AO deployment
- ✅ Clear, actionable error messages with field-level detail
- ✅ Type-safe metadata handling in CLI (TypeScript inference)
- ✅ Prevents common mistakes (negative prices, invalid TX IDs, missing fields)

---

### Enhancement 2: Registry Load Testing Script

**Location:** `tests/load/registry-load-test.ts`

**Purpose:** Validate NFR2 (P95 <1s) and NFR10 (100+ concurrent queries) before production deployment through automated performance testing.

**Test Coverage:**
1. **SearchSkills** - Most common query type, tests tag/keyword filtering
2. **SearchProcesses** - Capability filtering and price comparisons
3. **GetMarketplaceStats** - Complex aggregate computation
4. **ScoreSkill** - Quality scoring algorithm with weighted calculations

**Configuration:**
```bash
# Standard test (100 concurrent, 10 iterations = 1000 total queries)
REGISTRY_PROCESS_ID=<id> npm run load-test

# Quick test (10 concurrent, 3 iterations = 30 total queries)
REGISTRY_PROCESS_ID=<id> npm run load-test:quick

# Heavy test (200 concurrent, 20 iterations = 4000 total queries)
REGISTRY_PROCESS_ID=<id> npm run load-test:heavy
```

**Metrics Collected:**
- Success rate (target: ≥95%)
- P50, P95, P99 latency (P95 target: <1000ms)
- Min/Max/Avg latency
- Throughput (queries per second)
- Timeout count

**Output:**
- Real-time progress indicator
- Per-test-type results breakdown
- NFR validation (PASS/FAIL with specific thresholds)
- Optimization recommendations if NFRs fail

**NFR Validation:**
- ✅ **NFR2:** P95 latency <1 second (automated check)
- ✅ **NFR10:** 100+ concurrent queries (configurable, automated check)

**Exit Codes:**
- `0` - All NFRs passed (production-ready)
- `1` - Some NFRs failed (optimization required)

**Benefits:**
- ✅ Automated validation before launch (no manual testing)
- ✅ Concrete evidence that Registry meets performance requirements
- ✅ Identifies bottlenecks early (before user-facing issues)
- ✅ Provides optimization guidance if tests fail

---

**Updated Next Steps:**
1. ✅ **Enhancements complete** - JSON validation and load testing implemented
2. Begin development with **Epic 1** (Foundation & Payment Gating SDK)
3. Run load test before Registry mainnet deployment: `npm run load-test`
4. Proceed with confidence - this architecture is production-ready ✅
