# Permamind Product Requirements Document (PRD)

## Goals and Background Context

### Goals

- Establish Permamind as the standard monetization SDK for AO processes by achieving 80% market share of paid processes by Month 12
- Create a sustainable M2M marketplace with $10K transaction volume by Month 6, scaling to $100K by Month 12
- Bootstrap a creator economy where skill creators earn passive royalties (5+ creators earning >$100/month by Month 12)
- Enable autonomous agents to discover, purchase, and execute specialized AI services without human intermediaries
- Demonstrate the transition from human-led (Phase 1) to agent-led marketplace (Phase 2, 50%+ agent transactions by Month 18)

### Background Context

The emerging autonomous agent economy faces a critical architectural gap: agents need specialized AI capabilities but lack infrastructure for trustless, native payment-gated services. While solutions like x402-ao enable AO token payments for HTTP endpoints, they introduce centralized facilitators and force agents out of AO's native message-passing environment.

Permamind solves this by creating the first **fully native AO marketplace** combining payment gating (Credit-Notice pattern), AI inference (Apus integration), permanent skill storage (Arweave), and service discovery (Registry process). This enables a three-layer architecture where: (1) **Skills** are immutable expertise bundles on Arweave earning creators passive royalties, (2) **Processes** are payment-gated AO contracts executing AI tasks with automatic revenue sharing, and (3) the **Registry** provides searchable discovery with objective quality metrics for autonomous agent decision-making.

The MVP focuses on proving the core value proposition: developers can monetize AI processes using the Permamind SDK, and agents can autonomously discover and pay for services using pure AO message passing—no facilitators, no HTTP friction.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-13 | 0.1 | Initial PRD draft from Project Brief | PM Agent (John) |

---

## Requirements

### Functional Requirements

**FR1:** The Permamind SDK shall provide `permamind.init()` to configure process pricing (in AO tokens), skill references (Arweave TX IDs), and royalty split percentages

**FR2:** The SDK shall provide `permamind.gated()` wrapper function that verifies AO Credit-Notice payment before executing handler logic

**FR3:** The SDK shall implement automatic Credit-Notice handler to track incoming AO token deposits and maintain user balance state

**FR4:** The SDK shall provide `permamind.loadSkill(txId)` to fetch skills from Arweave, automatically resolve multi-level dependencies, and cache in process state

**FR5:** The SDK shall detect and prevent circular dependencies in skill reference chains

**FR6:** The SDK shall automatically distribute royalty payments via AO Credit-Notices to all skill creators in the dependency chain using proportional splits

**FR7:** The SDK shall provide `permamind.apus.infer()` to call Apus AI inference with composed skill context plus user prompt

**FR8:** The SDK shall handle Apus credit management, error handling, and retry logic for failed inference calls

**FR9:** The Registry Process shall accept skill registration messages containing Arweave TX ID, creator AO wallet, tags, royalty percentage, description, and dependency list

**FR10:** The Registry Process shall provide searchable skill queries by tags, creator, keyword, and return dependency graphs

**FR11:** The Registry Process shall validate that all skill dependencies reference existing registered skills

**FR12:** The Registry Process shall track and expose quality metrics including: usage count, active process count, total royalties earned, average royalty per use, success rate, average inference latency, refund rate, dependency count, and last used timestamp

**FR13:** The Registry Process shall provide a `ScoreSkill` action accepting custom weight parameters and returning normalized quality scores (0-100)

**FR14:** The Registry Process shall accept process registration messages containing AO address, capabilities, pricing in AO, and required skill references

**FR15:** The Registry Process shall track process quality metrics including: transaction count, success rate, P50/P95/P99 response times, and pricing

**FR16:** The Registry Process shall support pagination, filtering, and sorting for query results

**FR17:** The Registry Process shall listen for Credit-Notice messages to update usage counts and revenue metrics in real-time

**FR18:** The Registry Process shall monitor refund messages to calculate and update refund rates

**FR19:** The CLI tool shall provide `permamind init` command to scaffold new payment-gated process with SDK boilerplate

**FR20:** The CLI tool shall provide `permamind publish` command to deploy process to AO and register in marketplace

**FR21:** The CLI tool shall provide `permamind skill-upload` command to upload skill markdown to Arweave (using AR) and register in Registry (using AO)

**FR22:** The CLI tool shall provide `permamind wallet-check` command to verify AR and AO wallet balances with warnings for insufficient funds

**FR23:** The SDK shall provide withdrawal handler allowing users to reclaim unused AO deposits from processes

**FR24:** The SDK shall provide balance query handler to check user's deposited balance in any process

**FR25:** The SDK shall implement Checks-Effects-Interactions pattern and message ID tracking to prevent replay attacks

### Non-Functional Requirements

**NFR1:** The Registry Process shall maintain 99.5%+ uptime for query availability

**NFR2:** The Registry Process shall respond to queries with P95 latency <1 second

**NFR3:** The SDK payment gating implementation shall have zero critical security vulnerabilities (validated via external audit)

**NFR4:** The system shall achieve >95% success rate on Apus AI inference calls

**NFR5:** The SDK shall handle 3+ levels of skill dependency chains without exceeding AO compute limits (~30s execution time)

**NFR6:** Transaction completion (payment to result delivery) shall achieve P95 latency <60 seconds (accounting for ~50s Apus inference)

**NFR7:** The system shall achieve >95% transaction success rate without refunds required

**NFR8:** All payment and royalty flows shall execute via AO Credit-Notice pattern without external facilitators or HTTP endpoints

**NFR9:** Skills uploaded to Arweave shall cost <$0.10 per skill (one-time storage cost)

**NFR10:** The Registry Process shall support 100+ concurrent query requests without degradation

**NFR11:** Documentation shall enable developers to deploy their first payment-gated process in <30 minutes from zero knowledge

**NFR12:** The SDK shall enforce automatic process state persistence to Arweave via AO's native mechanisms

**NFR13:** All skill context loading shall respect Apus 8,192 token limit via automatic truncation or prioritization

**NFR14:** The CLI tool shall work on macOS, Linux, and Windows with Node.js 18+

**NFR15:** The system shall publicly log all transactions on-chain with no PII collection

---

## User Interface Design Goals

### Overall UX Vision

Permamind MVP prioritizes **developer experience** through CLI tooling and **agent experience** through programmatic AO message interfaces. The CLI should feel like familiar package managers (npm, cargo) with clear feedback and minimal friction. For agents, the message-based query interface must return structured JSON responses optimized for programmatic parsing and decision-making.

Post-MVP, a web UI will target human skill creators and casual users, featuring visual dependency graphs, interactive metrics dashboards, and wallet-integrated process invocation.

### Key Interaction Paradigms

**CLI-First for Developers:**
- Command-driven workflow: `permamind init` → edit code → `permamind publish`
- Rich terminal output with progress indicators for Arweave uploads and AO deployments
- Immediate feedback on wallet balances, cost estimates, and deployment status
- Error messages with actionable solutions (e.g., "Insufficient AR balance. Need 0.05 AR for skill upload. Get testnet tokens at...")

**Message-Based for Agents:**
- Pure AO message passing (no HTTP endpoints)
- Structured JSON request/response format
- Pagination and filtering via message tags
- Idempotent queries (safe to retry)

**Future Web UI (Post-MVP):**
- Browse marketplace with visual skill dependency graphs
- Compare skills/processes side-by-side with metrics
- One-click wallet-connected process invocation
- Real-time transaction history and analytics dashboards

### Core Screens and Views

**Phase 1 (MVP - CLI Only):**

1. **Init Wizard** - Interactive prompts for process scaffolding (name, pricing, skills)
2. **Publish Flow** - Progress display showing: wallet check → Arweave upload → AO deployment → Registry registration
3. **Wallet Status** - Balance display for AR and AO with funding instructions
4. **Skill Upload** - File selection, metadata input, cost estimate, upload confirmation
5. **Registry Query Results** - Formatted table display of skills/processes with key metrics

**Phase 2 (Post-MVP - Web UI):**

6. **Marketplace Browse** - Grid/list view of skills and processes with search and filters
7. **Skill Detail Page** - Full metadata, dependency graph visualization, usage metrics, creator profile
8. **Process Detail Page** - Capabilities, pricing, performance metrics, integration examples
9. **Analytics Dashboard** - Creator earnings, usage trends, quality scores over time
10. **Dependency Graph Viewer** - Interactive visualization of skill composition chains

### Accessibility

None for MVP (CLI targets developers via terminal, OS-level accessibility tools). Post-MVP web UI will aim for WCAG AA compliance.

### Branding

**Minimal CLI Aesthetic:**
- Clean, monospace output with subtle color coding (success=green, warnings=yellow, errors=red)
- ASCII art logo optional (keep it subtle)
- Consistent with AO ecosystem tooling (aos, apm style)

**Future Web UI:**
- Modern, technical aesthetic reflecting decentralized infrastructure
- Visual language emphasizing permanence (Arweave), autonomy (AO), intelligence (Apus)
- Color palette: Deep blues (trust), vibrant accents (AI/energy), neutral grays (data/tech)

### Target Device and Platforms

**MVP:**
- CLI (Cross-Platform Terminal): macOS, Linux, Windows (Node.js 18+)
- No mobile support for CLI

**Post-MVP Web UI:**
- Desktop browsers (Chrome, Firefox, Safari, Edge - latest 2 versions)
- Responsive design for tablet (secondary priority)
- Mobile view for browsing only (no wallet transactions on mobile in MVP)

---

## Technical Assumptions

### Repository Structure: Monorepo

**Decision:** Single monorepo containing SDK (Lua), Registry Process (Lua), CLI (TypeScript), examples, docs, and tests.

**Rationale:**
- Simplifies dependency management between SDK and CLI
- Easier version coordination (SDK v1.0 works with CLI v1.0)
- All examples stay in sync with SDK changes
- Can split into polyrepo post-MVP if needed (YAGNI applies)
- Standard for early-stage projects with small team (1-2 developers)

**Structure:**
```
permamind/
├── sdk/                    # Permamind Lua SDK (AO blueprints)
├── registry/               # Registry AO Process (Lua)
├── cli/                    # CLI tool (TypeScript/Node.js)
├── examples/               # Example processes & skills
├── docs/                   # Documentation
└── tests/                  # Test suite (aolite)
```

### Service Architecture

**Decision:** Monolithic AO processes with message-based communication (no microservices).

**Rationale:**
- **AO processes are naturally isolated** - Each process runs independently with separate state
- **Message passing is built-in** - AO's native communication pattern handles inter-process calls
- **Microservices add complexity** - Unnecessary for MVP scale (<100 processes expected)
- **Registry as single process** - Centralized search is simpler than distributed indexing
- **SDK as library** - Embedded in each process, not a separate service

**Architecture Pattern:**
- **SDK:** Library code imported into each payment-gated process
- **Registry:** Single AO process maintaining skill/process indexes and metrics
- **Processes:** Independent AO contracts using SDK for common functionality
- **Communication:** Pure AO message passing (Credit-Notice, queries, responses)

**Post-MVP Consideration:** If Registry becomes bottleneck (>1000 concurrent queries), deploy multiple registry replicas with load balancing.

### Testing Requirements

**Decision:** Unit + Integration testing with aolite (AO local testing framework).

**Test Pyramid:**
1. **Unit Tests (60%):** SDK modules in isolation (payment gating, skill loading, Apus calls)
2. **Integration Tests (30%):** Full process flows (payment → skill load → Apus → response)
3. **Manual Testing (10%):** Real AO deployment, Arweave uploads, end-to-end user flows

**Tooling:**
- **aolite:** Local AO process simulation for fast iteration
- **Jest/Mocha:** CLI tool testing (TypeScript)
- **Manual:** Testnet deployments before mainnet

**Critical Test Scenarios:**
- Multi-level skill dependency resolution (3+ levels)
- Payment security (replay attacks, insufficient balance, refunds)
- Apus error handling (timeout, failure, retry logic)
- Registry concurrency (100+ simultaneous queries)
- Edge cases (circular dependencies, missing skills, invalid payments)

**Rationale:** E2E testing on real AO is slow and costly. aolite enables fast local iteration. Manual testing validates real network behavior before launch.

### Additional Technical Assumptions and Requests

**Languages & Frameworks:**
- **Lua 5.3:** SDK and Registry (AO runtime requirement)
- **TypeScript:** CLI tool (type safety, rich ecosystem)
- **Node.js 18+:** CLI runtime (modern JS features, cross-platform)

**AO Ecosystem Dependencies:**
- **aos CLI:** Process deployment to AO network
- **apm (AO Package Manager):** SDK distribution as `@permamind/sdk`
- **aoconnect:** JavaScript library for AO interaction from CLI
- **aolite:** Local testing framework

**Arweave Integration:**
- **Arweave Gateway:** Read access for skill fetching (public endpoint)
- **ArConnect:** Wallet integration for AR token transactions (skill uploads)
- **Turbo/Bundlr:** Optional upload acceleration (if needed for UX)

**Apus Network Integration:**
- **Router Process ID:** `TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g` (hardcoded in SDK)
- **Gemma3-27B Model:** Only model supported in MVP (8,192 token context limit)
- **Apus Credit System:** SDK manages credit purchases and consumption tracking
- **Async Callback Pattern:** Handle 50s+ inference latency via message replies

**Deployment Targets:**
- **Development:** Local aolite simulation
- **Testing:** AO testnet (if available, otherwise mainnet with test wallets)
- **Production:** AO mainnet
- **CLI Distribution:** npm registry (`npm install -g @permamind/cli`)
- **SDK Distribution:** apm registry (`apm install @permamind/sdk`)

**Security Patterns (CRITICAL):**
- **Checks-Effects-Interactions (CEI):** All payment handlers must validate → update state → external calls
- **Message ID Tracking:** Prevent replay attacks by storing processed message IDs
- **Balance Auditing:** Runtime checks ensuring deposits = withdrawals + usage
- **Refund Mechanisms:** Automatic refunds for failed Apus calls or processing errors
- **No Upgradeable Contracts:** Immutable process code (deploy new version if bugs found)

**Performance Constraints:**
- **AO Execution Limit:** ~30 seconds per message handler
- **Memory Limit:** ~50-100MB per process
- **Apus Latency:** ~50 seconds P95 (cannot optimize)
- **Token Context:** 8,192 tokens total (skill context + user prompt)
- **Registry Query Target:** <1 second P95 response time

**Data Storage:**
- **Skills:** Arweave permanent storage (~$5-10 per GB one-time)
- **Process State:** Automatic AO persistence to Arweave
- **Registry Indexes:** In-memory with AO auto-persistence
- **Metrics:** Real-time aggregation in Registry process state

**Token Economics:**
- **AR Token:** Required for Arweave uploads (skill publishing ~$0.01-0.05 per skill)
- **AO Token:** Required for all payments, royalties, and registry transactions
- **Apus Credits:** Purchased with process funds, consumed per inference
- **No Stablecoins:** AO/AR only for MVP (volatility accepted as ecosystem norm)

**Wallet Requirements:**
- **Developers:** AR wallet (skill uploads) + AO wallet (registry, payments)
- **Agents:** AO wallet only (no Arweave interaction)
- **CLI:** Support both ArConnect (browser extension) and JSON keyfile

**External Service Assumptions:**
- **Arweave uptime:** 99%+ (proven track record)
- **AO network stability:** Assuming backward compatibility during MVP dev
- **Apus availability:** Unproven - SDK must handle outages gracefully
- **Gateway reliability:** Public gateways may be slow/unreliable (acceptable for MVP)

**Development Tools:**
- **IDE:** VS Code with Lua extensions
- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions for CLI tests and npm publishing
- **Documentation:** Markdown with code examples
- **Code Style:** Lua - follow aos conventions; TypeScript - Prettier + ESLint

**Observability:**
- **Logging:** AO message logs (public by design)
- **Metrics:** Registry process exposes analytics via queries
- **Monitoring:** Manual log inspection (no APM for MVP)
- **Debugging:** aolite local testing + testnet trials

**Constraints Acknowledged:**
- **No HTTP from AO processes:** Must use gateway processes if needed
- **Limited stdlib:** No file system, complex crypto, or image processing in Lua
- **Single AI model:** Gemma3-27B only (limits use cases to text)
- **No streaming:** Apus returns full response after inference completes
- **Public by default:** All transactions visible on-chain (no privacy)

---

## Epic List

### Epic 1: Foundation & Payment Gating SDK
**Goal:** Establish project infrastructure and deliver core SDK payment gating module, enabling developers to create payment-gated AO processes with secure Credit-Notice handling.

### Epic 2: Skill System & Composition Engine
**Goal:** Implement skill loading from Arweave with multi-level dependency resolution and automatic royalty distribution, enabling processes to compose specialized AI context from permanent skill storage.

### Epic 3: Apus AI Integration & Inference
**Goal:** Integrate Apus Network for AI inference with skill context composition, credit management, and error handling, enabling processes to deliver AI-powered services to users.

### Epic 4: Registry Process & Discovery
**Goal:** Deploy searchable Registry Process with skill/process registration, quality metrics tracking, and agent-accessible query interface, enabling autonomous discovery and comparison of marketplace services.

### Epic 5: CLI Tooling & Developer Experience
**Goal:** Build CLI tool for process scaffolding, deployment, skill publishing, and wallet management, reducing developer friction from hours to minutes.

### Epic 6: Example Processes & Documentation
**Goal:** Create production-ready example processes demonstrating skill composition, publish comprehensive documentation, and validate end-to-end user flows, enabling first wave of developer adoption.

### Epic 7: Testing, Security Audit & Launch Prep
**Goal:** Execute comprehensive testing (unit, integration, edge cases), conduct external security audit, fix critical issues, and prepare for MVP launch with early adopter onboarding.

---

## Epic 1: Foundation & Payment Gating SDK

**Epic Goal:** Establish monorepo project infrastructure (Git, CI/CD, testing framework) and deliver core SDK payment gating module with secure Credit-Notice handling, enabling developers to create their first payment-gated AO process that accepts AO token deposits and enforces payment before execution.

### Story 1.1: Project Monorepo Setup

**As a** developer,
**I want** a well-structured monorepo with organized directories for SDK, Registry, CLI, examples, docs, and tests,
**so that** I can easily navigate the codebase and understand where each component lives.

#### Acceptance Criteria

1. Repository created with folders: `/sdk`, `/registry`, `/cli`, `/examples`, `/docs`, `/tests`
2. Root-level `README.md` explains project structure and quick start instructions
3. `.gitignore` configured for Node.js, Lua, and AO-specific build artifacts
4. `package.json` created for monorepo with workspace configuration (if using npm/yarn workspaces)
5. All directories contain placeholder `README.md` files explaining their purpose

### Story 1.2: CI/CD Pipeline for Automated Testing

**As a** developer,
**I want** automated tests to run on every commit and pull request,
**so that** I catch bugs early and maintain code quality throughout development.

#### Acceptance Criteria

1. GitHub Actions workflow configured to run on push and pull request events
2. Workflow installs Node.js 18+ and Lua 5.3 dependencies
3. Workflow runs TypeScript linter (ESLint) and formatter (Prettier) checks on `/cli`
4. Workflow executes all tests in `/tests` directory using aolite
5. Workflow fails the build if any test fails or linting errors exist
6. Badge added to `README.md` showing CI status (passing/failing)

### Story 1.3: aolite Testing Framework Integration

**As a** developer,
**I want** local AO process testing capability with aolite,
**so that** I can rapidly iterate on SDK code without deploying to mainnet.

#### Acceptance Criteria

1. aolite installed and configured in `/tests` directory
2. Sample test file demonstrates loading a Lua module and asserting behavior
3. Test runner script (`npm test` or equivalent) executes all aolite tests
4. Tests output clear pass/fail status with error messages
5. Documentation in `/docs` explains how to write and run tests locally
6. At least one passing test validates aolite is working correctly

### Story 1.4: SDK Core Module Structure

**As a** process developer,
**I want** a well-organized SDK with clear module separation,
**so that** I can import only the functionality I need and understand the codebase easily.

#### Acceptance Criteria

1. SDK files created: `/sdk/init.lua`, `/sdk/payment-gating.lua`, `/sdk/security.lua`, `/sdk/utils.lua`
2. Main entry point `/sdk/permamind.lua` exports all public functions
3. Each module contains header comments explaining its purpose and public API
4. Module structure follows Lua best practices (local functions, explicit returns)
5. No circular dependencies between modules
6. Placeholder implementations for core functions (`init()`, `gated()`, `checkPayment()`)

### Story 1.5: SDK Initialization and Configuration

**As a** process developer,
**I want** to configure my process pricing and settings using `permamind.init()`,
**so that** I can declaratively set up payment gating without manual state management.

#### Acceptance Criteria

1. `permamind.init()` accepts table with fields: `pricing` (table of action→amount), `wallet` (AO address for withdrawals)
2. Configuration stored in process global state (accessible across handlers)
3. Function validates required fields and throws clear error if missing
4. Function validates pricing amounts are positive integers
5. Function validates wallet address format (43 character AO address)
6. Unit test verifies initialization stores configuration correctly
7. Unit test verifies initialization rejects invalid configurations with helpful error messages

### Story 1.6: Credit-Notice Handler for Payment Tracking

**As a** process,
**I want** to automatically track incoming AO token payments via Credit-Notice messages,
**so that** users can deposit funds and I can verify balances before executing paid actions.

#### Acceptance Criteria

1. Handler registered for `Credit-Notice` action in SDK
2. Handler extracts `Sender` (wallet address), `Quantity` (token amount), and `Message-Id` from Credit-Notice
3. Handler updates global `Balances` table: `Balances[Sender] = (Balances[Sender] or 0) + Quantity`
4. Handler tracks `ProcessedMessages[Message-Id] = true` to prevent replay attacks
5. Handler rejects duplicate Message-Ids with error response
6. Handler sends acknowledgment message to sender confirming deposit
7. Unit test verifies balance increases correctly on valid Credit-Notice
8. Unit test verifies replay attack prevention (duplicate Message-Id rejected)
9. Integration test using aolite simulates sending Credit-Notice and verifies balance update

### Story 1.7: Balance Query Handler

**As a** user or agent,
**I want** to query my current balance in a process,
**so that** I know how much I've deposited and can decide whether to add more funds.

#### Acceptance Criteria

1. Handler registered for `Balance` action
2. Handler responds with sender's current balance from `Balances` table
3. Response format: `{ Balance = "1000000", Address = msg.From }`
4. Handler returns `"0"` for addresses with no deposits
5. Handler responds within 1 second (no external calls)
6. Unit test verifies balance query returns correct amount
7. Unit test verifies zero balance for new addresses
8. Integration test queries balance after simulated deposit

### Story 1.8: Payment Gating Wrapper Function

**As a** process developer,
**I want** a `permamind.gated()` wrapper function that checks payment before executing my handler logic,
**so that** I can easily add payment gating to any action without duplicating security code.

#### Acceptance Criteria

1. `permamind.gated(actionName, handlerFunction)` returns a handler function
2. Wrapper extracts required payment amount from `pricing` configuration for the specified action
3. Wrapper checks if sender has sufficient balance in `Balances` table
4. If insufficient balance, wrapper sends error response and does NOT execute handler function
5. If sufficient balance, wrapper deducts payment from balance BEFORE executing handler
6. Wrapper executes handler function with original message
7. Wrapper implements Checks-Effects-Interactions pattern (validate → update state → execute)
8. Unit test verifies handler executes when balance is sufficient
9. Unit test verifies handler does NOT execute when balance is insufficient
10. Unit test verifies balance is deducted before handler execution (CEI pattern)
11. Integration test demonstrates complete flow: deposit → gated action → balance reduced

### Story 1.9: Withdrawal Handler for Refunds

**As a** user,
**I want** to withdraw unused deposited funds from a process,
**so that** I can reclaim my tokens if I no longer need the service.

#### Acceptance Criteria

1. Handler registered for `Withdraw` action
2. Handler accepts optional `Amount` parameter (defaults to full balance)
3. Handler validates sender has sufficient balance for requested withdrawal
4. Handler deducts withdrawal amount from `Balances[msg.From]`
5. Handler sends Debit-Notice to sender's wallet with withdrawn amount
6. Handler responds with confirmation message including withdrawn amount
7. Handler prevents withdrawal of more than available balance (error response)
8. Unit test verifies full withdrawal zeroes balance
9. Unit test verifies partial withdrawal reduces balance correctly
10. Unit test verifies over-withdrawal is rejected
11. Integration test simulates deposit → partial withdrawal → balance check

### Story 1.10: Example Payment-Gated "Hello World" Process

**As a** developer learning Permamind,
**I want** a simple example process that demonstrates payment gating,
**so that** I can understand how to integrate the SDK into my own processes.

#### Acceptance Criteria

1. Example process file created at `/examples/hello-world/process.lua`
2. Process imports SDK: `local permamind = require("permamind")`
3. Process initializes SDK with pricing: `{ SayHello = "1000" }` (0.000001 AO tokens)
4. Process defines `SayHello` handler using `permamind.gated()`
5. Handler returns simple message: `"Hello, " .. msg.From .. "!"`
6. Example includes comments explaining each step
7. Example includes manual deployment instructions in `/examples/hello-world/README.md`
8. README explains how to test: deposit tokens → call SayHello → receive response
9. Integration test deploys example to aolite and validates complete flow
10. Example can be manually deployed to AO testnet and successfully executes paid action

---

## Epic 2: Skill System & Composition Engine

**Epic Goal:** Implement skill loading from Arweave with multi-level dependency resolution (up to 3 levels) and automatic royalty distribution via Credit-Notice, enabling processes to compose specialized AI context from permanent skill storage while compensating all skill creators in the dependency chain.

### Story 2.1: Skill Metadata Schema Definition

**As a** skill creator,
**I want** a standardized metadata format for skills stored on Arweave,
**so that** processes can reliably parse skill information and dependencies.

#### Acceptance Criteria

1. Skill metadata schema documented in `/docs/skill-schema.md`
2. Schema defines required fields: `name`, `description`, `content`, `version`, `creator`, `royaltyPercent`
3. Schema defines optional field: `dependencies` (array of Arweave TX IDs)
4. Schema specifies JSON format with example
5. Schema validates `royaltyPercent` range (0-100)
6. Schema validates `creator` as 43-character Arweave/AO address
7. Schema validates `dependencies` as array of 43-character TX IDs
8. Example skill JSON files created in `/examples/skills/` (at least 3 skills with dependency relationships)

### Story 2.2: Arweave Gateway Integration for Skill Fetching

**As a** process,
**I want** to fetch skill content from Arweave using transaction IDs,
**so that** I can load permanent skill context into my process state.

#### Acceptance Criteria

1. Function `fetchFromArweave(txId)` created in `/sdk/skill-loading.lua`
2. Function uses AO's gateway capability to fetch data from Arweave
3. Function returns skill content as string (JSON or markdown)
4. Function handles errors: invalid TX ID, network timeout, gateway unavailable
5. Function implements retry logic (3 attempts with exponential backoff)
6. Function caches fetched skills in process state to avoid redundant fetches
7. Unit test mocks Arweave response and verifies parsing
8. Integration test fetches real skill from Arweave testnet/mainnet
9. Performance test verifies cold fetch completes within 10 seconds

### Story 2.3: Skill Dependency Graph Resolution

**As a** process,
**I want** to automatically resolve and load all skills in a dependency chain,
**so that** I don't manually manage transitive dependencies.

#### Acceptance Criteria

1. Function `resolveDependencies(skillTxId)` returns ordered list of all skills in dependency tree
2. Function performs depth-first traversal of dependency graph
3. Function detects circular dependencies and throws clear error
4. Function limits maximum dependency depth to 3 levels (configurable)
5. Function deduplicates skills (if Skill C depends on A and Skill B also depends on A, A appears once)
6. Function orders skills: leaf dependencies first, root skill last
7. Unit test verifies linear chain (A→B→C) resolves to [A, B, C]
8. Unit test verifies diamond dependency (C→B→A, C→D→A) resolves to [A, B, D, C]
9. Unit test verifies circular dependency (A→B→C→A) throws error
10. Unit test verifies depth limit (A→B→C→D at depth 4) throws error

### Story 2.4: Skill Context Composition

**As a** process,
**I want** to combine multiple skill contents into a single context string,
**so that** I can pass complete domain expertise to Apus AI inference.

#### Acceptance Criteria

1. Function `composeContext(skillTxIds)` returns single string with all skill content
2. Function resolves dependencies for each skill ID
3. Function fetches content for all resolved skills from Arweave
4. Function concatenates skill content in dependency order (foundations first, specialized last)
5. Function adds separators between skills (e.g., `\n\n--- Skill: {name} ---\n\n`)
6. Function validates total token count does not exceed 6,000 tokens (leaving 2,192 for user prompt)
7. Function truncates or prioritizes skills if token limit exceeded (warn user)
8. Unit test verifies composition order for multi-level dependencies
9. Unit test verifies token counting is accurate
10. Integration test composes context from 3-level dependency chain

### Story 2.5: Royalty Split Calculation

**As a** process,
**I want** to calculate how much to pay each skill creator based on dependency depth,
**so that** foundational skills earn fair compensation even when used transitively.

#### Acceptance Criteria

1. Function `calculateRoyalties(skillTxIds, totalPayment)` returns table mapping creator addresses to amounts
2. Function uses dependency depth for weighting (deeper skills get higher %, foundations get lower %)
3. Default split: 30% of payment goes to skills, 70% to process operator
4. Within skill royalties: proportional to configured `royaltyPercent` in skill metadata
5. Example: Skill C (15%), Skill B (10%), Skill A (5%) = 30% total to skills
6. Function validates total royalties do not exceed configured percentage cap
7. Function handles skills with same creator (combine royalties to single payment)
8. Unit test verifies split for 1-skill process (single creator gets configured %)
9. Unit test verifies split for 3-skill chain (all creators get proportional amounts)
10. Unit test verifies edge case: skill creator is also process operator (receives both splits)

### Story 2.6: Automatic Credit-Notice Royalty Distribution

**As a** skill creator,
**I want** to automatically receive royalty payments when processes use my skills,
**so that** I earn passive income without manual invoicing.

#### Acceptance Criteria

1. Function `distributeRoyalties(royaltyMap)` sends Credit-Notice to each creator
2. Function sends AO token transfers from process balance to creator wallets
3. Function includes metadata tags: `Royalty-For` (skill TX ID), `Process` (sender process ID)
4. Function handles errors: insufficient process balance, invalid creator address
5. Function logs all royalty payments to process state for transparency
6. Function executes after payment is deducted but before handler executes (CEI pattern)
7. Unit test verifies Credit-Notice messages sent to correct addresses
8. Unit test verifies amounts match royalty calculation
9. Integration test simulates payment → royalty distribution → creator balance increase
10. Integration test verifies process balance reduced by both payment and royalties

### Story 2.7: SDK loadSkill() Public API

**As a** process developer,
**I want** a simple `permamind.loadSkill(txId)` function that handles all complexity,
**so that** I can use skills without understanding dependency resolution internals.

#### Acceptance Criteria

1. Function `permamind.loadSkill(txId)` exposed in SDK public API
2. Function resolves dependencies, fetches content, composes context, returns final string
3. Function caches composed context in process state for performance
4. Function validates TX ID format (43 characters)
5. Function throws clear errors: skill not found, circular dependency, token limit exceeded
6. Function works with both single skills and skill chains
7. Documentation in `/docs/sdk-reference.md` explains usage with examples
8. Unit test verifies simple skill load (no dependencies)
9. Unit test verifies complex skill load (3-level dependency chain)
10. Integration test loads skill from real Arweave and returns valid context

### Story 2.8: Enhanced Gated Handler with Royalty Support

**As a** process developer,
**I want** `permamind.gated()` to automatically distribute royalties when my handler uses skills,
**so that** skill creators are compensated without extra code.

#### Acceptance Criteria

1. `permamind.gated()` accepts optional `skills` parameter (array of skill TX IDs)
2. Function calculates royalties for specified skills before executing handler
3. Function distributes royalties via Credit-Notice after deducting payment but before handler execution
4. Function reduces process operator's share to account for royalties (e.g., 70% of payment minus royalty total)
5. Function passes composed skill context to handler as additional parameter
6. Function handles case where no skills specified (100% to operator, no royalties)
7. Unit test verifies royalty distribution occurs for gated handler with skills
8. Unit test verifies no royalties sent when skills parameter is empty
9. Integration test demonstrates: user pays → royalties sent → handler executes → process keeps remainder
10. Documentation updated with skill usage examples

### Story 2.9: Example Multi-Skill Process (Code Review)

**As a** developer,
**I want** an example process demonstrating skill composition and royalties,
**so that** I understand how to build processes using multiple skills.

#### Acceptance Criteria

1. Example process created at `/examples/code-review/process.lua`
2. Process uses 3 skills in dependency chain: General Security → JavaScript Security → React Security
3. Process defines `ReviewCode` action priced at 0.001 AO
4. Process loads skill context using `permamind.loadSkill(reactSkillTxId)`
5. Process uses gated handler with automatic royalty distribution
6. Process placeholder: calls Apus (stubbed for now, will integrate in Epic 3)
7. Example skills published to Arweave with dependency relationships
8. README explains: skill relationships, royalty splits, how to test
9. Integration test deploys process and verifies royalty distribution on paid action
10. Manual test on testnet confirms all three skill creators receive royalties

### Story 2.10: Skill Dependency Visualization Tool

**As a** developer or skill creator,
**I want** a CLI command to visualize skill dependency graphs,
**so that** I can understand complex skill relationships before using them.

#### Acceptance Criteria

1. CLI command `permamind skill-graph <txId>` implemented
2. Command fetches skill and all dependencies from Arweave
3. Command outputs ASCII tree showing dependency hierarchy
4. Command displays: skill name, creator, royalty %, TX ID (truncated)
5. Command detects and warns about circular dependencies
6. Command shows total estimated royalty percentage for entire chain
7. Command works offline if skills are already cached
8. Output example:
   ```
   React Security Review (15%)
   ├── JavaScript Security (10%)
   │   └── General Security (5%)
   └── Total Royalties: 30%
   ```
9. Unit test verifies ASCII tree generation for 3-level chain
10. Integration test fetches real skills and displays correct graph

---

## Epic 3: Apus AI Integration & Inference

**Epic Goal:** Integrate Apus Network for AI inference with skill context composition, credit management, error handling, and async callback pattern, enabling processes to deliver AI-powered services with verifiable computation and ~50 second response times.

### Story 3.1: Apus Router Process Connection

**As a** process,
**I want** to send messages to the Apus Router Process for AI inference,
**so that** I can leverage decentralized AI capabilities within my AO process.

#### Acceptance Criteria

1. Apus Router Process ID hardcoded in SDK: `TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g`
2. Function `connectApus()` validates router process ID format
3. Function creates message template for inference requests
4. Configuration option to override router ID (for testing/future multi-provider)
5. Documentation in `/docs/apus-integration.md` explains Apus architecture
6. Unit test verifies router ID is correctly configured
7. Integration test sends test message to Apus router and receives acknowledgment

### Story 3.2: Apus Credit Purchase and Management

**As a** process,
**I want** to purchase and track Apus credits for AI inference,
**so that** I can pay for computation without manual credit top-ups.

#### Acceptance Criteria

1. Function `purchaseApusCredits(amount)` sends payment to Apus credit process
2. Function tracks purchased credits in process state: `ApusCredits = X`
3. Function validates process has sufficient AO token balance before purchase
4. Function handles purchase confirmation and updates credit balance
5. Function `getApusCredits()` returns current credit balance
6. Function warns when credits fall below threshold (e.g., < 1000 credits)
7. Documentation explains credit costs per inference (~X credits per 1K tokens)
8. Unit test verifies credit purchase deducts AO tokens
9. Unit test verifies credit balance updates after purchase
10. Integration test purchases credits on testnet and verifies balance increase

### Story 3.3: Inference Request Message Construction

**As a** process,
**I want** to construct properly formatted Apus inference requests,
**so that** Apus Router correctly processes my AI inference jobs.

#### Acceptance Criteria

1. Function `buildInferenceRequest(prompt, skillContext)` returns message table
2. Message includes required tags: `Action = "Inference"`, `Model = "Gemma3-27B"`
3. Message data contains combined prompt: `{skillContext}\n\n{userPrompt}`
4. Function validates total prompt length <= 8,192 tokens (Apus limit)
5. Function includes callback target (process ID requesting inference)
6. Function includes message reference for matching responses
7. Function throws error if prompt exceeds token limit with truncation suggestion
8. Unit test verifies message structure matches Apus specification
9. Unit test verifies token counting prevents oversized prompts
10. Documentation includes example request/response message formats

### Story 3.4: Async Callback Handler for Inference Results

**As a** process,
**I want** to receive and process Apus inference results via async callbacks,
**so that** I can handle the ~50 second latency without blocking my process.

#### Acceptance Criteria

1. Handler registered for `Apus-Response` action (or equivalent callback tag)
2. Handler extracts inference result from response message data
3. Handler matches response to original request using message reference
4. Handler stores result in temporary state keyed by request ID
5. Handler triggers completion callback or notifies waiting user
6. Handler handles errors: timeout, inference failure, invalid response
7. Handler logs inference latency for performance monitoring
8. Unit test verifies callback handler extracts result correctly
9. Integration test sends inference request and receives callback within 60 seconds
10. Integration test verifies request-response matching works correctly

### Story 3.5: Credit Deduction and Cost Tracking

**As a** process,
**I want** to automatically deduct Apus credits after each inference,
**so that** I maintain accurate credit balances and prevent over-spending.

#### Acceptance Criteria

1. Function `deductInferenceCredits(tokenCount)` reduces `ApusCredits` balance
2. Function calculates credit cost based on token count (formula documented)
3. Function validates sufficient credits before allowing inference
4. Function logs each deduction with timestamp and message reference
5. Function prevents negative credit balances (blocks inference if insufficient)
6. Function sends alert when credits drop below 10% of initial balance
7. Unit test verifies credit deduction calculation is accurate
8. Unit test verifies insufficient credits blocks inference
9. Integration test tracks credits before/after inference and verifies deduction
10. Documentation explains credit costs and refill procedures

### Story 3.6: Error Handling and Retry Logic

**As a** process,
**I want** robust error handling for Apus failures,
**so that** temporary issues don't permanently fail user requests.

#### Acceptance Criteria

1. Function implements retry logic for transient failures (3 attempts max)
2. Function distinguishes between retryable (timeout, network) and permanent (invalid prompt) errors
3. Function uses exponential backoff: 1s, 2s, 4s delays between retries
4. Function logs all errors with context (request ID, attempt number, error type)
5. Function refunds user payment if all retries fail
6. Function returns clear error message to user explaining failure
7. Function tracks failure rate for monitoring (store in process state)
8. Unit test verifies retry logic attempts 3 times on timeout
9. Unit test verifies no retry on permanent errors (invalid prompt)
10. Integration test simulates Apus timeout and verifies retry behavior

### Story 3.7: Public API permamind.apus.infer()

**As a** process developer,
**I want** a simple `permamind.apus.infer(prompt, skillContext)` function,
**so that** I can get AI inference results without managing async callbacks manually.

#### Acceptance Criteria

1. Function `permamind.apus.infer(prompt, skillContext)` exposed in SDK
2. Function combines skill context and user prompt
3. Function checks Apus credit balance before sending request
4. Function sends inference request to Apus Router
5. Function registers callback handler for async response
6. Function returns request ID (caller waits for callback via message flow)
7. Function validates parameters: prompt is string, skillContext is optional string
8. Function throws errors: insufficient credits, prompt too long, invalid parameters
9. Documentation in `/docs/sdk-reference.md` includes usage examples
10. Integration test calls `infer()` and receives result within 60 seconds

### Story 3.8: Integration with Gated Handlers

**As a** process developer,
**I want** seamless Apus integration within gated handlers,
**so that** users pay once and receive AI-powered results automatically.

#### Acceptance Criteria

1. `permamind.gated()` supports handlers that call `permamind.apus.infer()`
2. Skill context automatically loaded and passed to inference (if skills configured)
3. Apus credits deducted from process balance (not user balance)
4. User receives inference result via message response
5. If inference fails after retries, user payment is refunded automatically
6. Handler logs complete flow: payment → skill load → inference → response
7. Unit test verifies payment → inference → response flow
8. Unit test verifies refund on inference failure
9. Integration test demonstrates end-to-end: user pays → AI result received
10. Example updated in `/examples/code-review/` to use real Apus inference

### Story 3.9: Cost Estimation Function

**As a** user or agent,
**I want** to estimate Apus inference costs before paying,
**so that** I can budget appropriately and compare service pricing.

#### Acceptance Criteria

1. Function `permamind.estimateCost(actionName, promptLength)` returns estimated total cost
2. Function calculates: action price + Apus credits + skill royalties
3. Function returns breakdown: `{ actionPrice, apusCredits, royalties, total }`
4. Function accounts for skill context token count in Apus estimate
5. Function returns costs in AO token amounts (not just credits)
6. Handler registered for `EstimateCost` action accessible to users
7. Documentation explains how to call estimation before payment
8. Unit test verifies cost calculation matches actual charges
9. Integration test compares estimate with real inference cost (within 5% tolerance)
10. CLI tool supports `permamind estimate <processId> <action>` command

### Story 3.10: Updated Code Review Example with Full AI

**As a** developer,
**I want** a complete working example of AI-powered code review,
**so that** I can see the entire Permamind system in action.

#### Acceptance Criteria

1. Example process `/examples/code-review/process.lua` updated with real Apus inference
2. Process uses 3-skill chain (General Security → JS Security → React Security)
3. Process accepts `ReviewCode` action with user's code as message data
4. Process loads skill context, calls Apus with code + context
5. Process returns AI-generated code review to user
6. Process handles errors: invalid code, Apus failure, insufficient credits
7. README includes: setup instructions, skill publishing, deployment, testing
8. Example demonstrates complete flow: payment → skill royalties → AI inference → result
9. Integration test deploys to testnet and performs real code review
10. Manual testing verifies: realistic code input → meaningful security review output

---

## Epic 4: Registry Process & Discovery

**Epic Goal:** Deploy searchable Registry Process with skill/process registration, real-time quality metrics tracking, agent-accessible query interface, and scoring algorithms, enabling autonomous agents to discover, compare, and select marketplace services based on objective performance data.

### Story 4.1: Registry Process Foundation

**As a** marketplace operator,
**I want** a dedicated AO process for the Registry with organized state management,
**so that** skill and process metadata can be reliably stored and queried.

#### Acceptance Criteria

1. Registry process file created at `/registry/registry.lua`
2. Global state tables initialized: `Skills = {}`, `Processes = {}`, `Metrics = {}`
3. Process includes initialization logic in main handler
4. Process ID generation documented for deployment
5. Process structure follows AO best practices (handlers, state, utilities)
6. Unit test verifies state initialization on first message
7. Integration test deploys registry to aolite and confirms process is active
8. Documentation in `/docs/registry-deployment.md` explains deployment procedure

### Story 4.2: Skill Registration Handler

**As a** skill creator,
**I want** to register my skill in the Registry with metadata,
**so that** processes can discover and use my skill.

#### Acceptance Criteria

1. Handler registered for `RegisterSkill` action
2. Handler accepts parameters: `TxId`, `Name`, `Description`, `Tags`, `RoyaltyPercent`, `Dependencies`, `Creator`
3. Handler validates: TxId format (43 chars), RoyaltyPercent (0-100), Creator address format
4. Handler validates all dependency TxIds reference existing registered skills
5. Handler stores skill in `Skills[TxId]` table with metadata and timestamp
6. Handler initializes metrics for skill: `{ usageCount = 0, totalRoyalties = 0, ... }`
7. Handler sends confirmation message to creator with skill registration details
8. Handler rejects duplicate registrations (TxId already exists)
9. Unit test verifies valid skill registration stores correctly
10. Unit test verifies invalid parameters are rejected with clear errors
11. Integration test registers skill with dependencies and queries it back

### Story 4.3: Process Registration Handler

**As a** process developer,
**I want** to register my process in the Registry with capabilities and pricing,
**so that** users and agents can discover my service.

#### Acceptance Criteria

1. Handler registered for `RegisterProcess` action
2. Handler accepts parameters: `ProcessId`, `Name`, `Description`, `Capabilities`, `Pricing`, `Skills`, `Creator`
3. Handler validates: ProcessId format (43 chars), Pricing table (action→amount), Creator address
4. Handler validates all skill TxIds in `Skills` array reference registered skills
5. Handler stores process in `Processes[ProcessId]` table with metadata and timestamp
6. Handler initializes metrics: `{ transactionCount = 0, successRate = 1.0, totalRevenue = 0, ... }`
7. Handler sends confirmation message to creator
8. Handler allows updates (re-registration with same ProcessId updates metadata)
9. Unit test verifies valid process registration
10. Unit test verifies validation catches invalid skills references
11. Integration test registers process and queries it back

### Story 4.4: Skill Search and Query Interface

**As a** user or agent,
**I want** to search for skills by tags, keywords, or creator,
**so that** I can find specialized AI context relevant to my needs.

#### Acceptance Criteria

1. Handler registered for `SearchSkills` action
2. Handler accepts parameters: `Tags` (array), `Keyword` (string), `Creator` (address), `SortBy` (field name)
3. Handler filters skills matching all specified tags (AND logic)
4. Handler filters skills where keyword appears in name or description (case-insensitive)
5. Handler filters by creator address if specified
6. Handler sorts results by specified field (default: `usageCount` descending)
7. Handler supports pagination: `Limit` (default 10, max 100), `Offset` (default 0)
8. Handler returns JSON array of matching skills with full metadata and metrics
9. Handler includes dependency information in results
10. Unit test verifies tag filtering (multiple tags)
11. Unit test verifies keyword search (partial match)
12. Unit test verifies sorting and pagination
13. Integration test searches skills and verifies correct results

### Story 4.5: Process Search and Query Interface

**As a** user or agent,
**I want** to search for processes by capability, price range, or quality metrics,
**so that** I can find the best AI service for my task and budget.

#### Acceptance Criteria

1. Handler registered for `SearchProcesses` action
2. Handler accepts parameters: `Capability` (string), `MaxPrice` (amount), `MinSuccessRate` (0-1), `SortBy`, `Limit`, `Offset`
3. Handler filters processes where capability keyword matches
4. Handler filters processes where any pricing <= MaxPrice
5. Handler filters processes with successRate >= MinSuccessRate
6. Handler sorts by specified field (default: `successRate` descending)
7. Handler supports pagination (same as skills)
8. Handler returns JSON array with full process metadata and metrics
9. Handler includes aggregated skill quality scores for processes
10. Unit test verifies price filtering
11. Unit test verifies success rate filtering
12. Unit test verifies multi-criteria filtering
13. Integration test searches for high-quality, affordable processes

### Story 4.6: Real-Time Metrics Collection from Credit-Notices

**As a** marketplace operator,
**I want** the Registry to automatically track usage metrics by monitoring Credit-Notices,
**so that** skill and process quality data stays current without manual updates.

#### Acceptance Criteria

1. Handler registered for `Credit-Notice` action (listens to network-wide events)
2. Handler extracts: `Sender`, `Recipient`, `Amount`, `Royalty-For` tag (skill TxId), `Process` tag
3. If `Royalty-For` tag present: increment skill `usageCount`, add to `totalRoyalties`
4. If `Process` tag present: increment process `transactionCount`, add to `totalRevenue`
5. Handler updates `lastUsed` timestamp for skills and processes
6. Handler calculates `avgRoyaltyPerUse` for skills: `totalRoyalties / usageCount`
7. Handler stores transaction reference for potential auditing
8. Handler ignores non-Permamind Credit-Notices (validate tags)
9. Unit test verifies skill metrics update on royalty Credit-Notice
10. Unit test verifies process metrics update on payment Credit-Notice
11. Integration test simulates payment flow and verifies Registry metrics reflect transactions

### Story 4.7: Refund Tracking and Success Rate Calculation

**As a** marketplace participant,
**I want** refund events to negatively impact quality scores,
**so that** unreliable processes are deprioritized in search results.

#### Acceptance Criteria

1. Handler registered for `Refund-Notice` action (custom tag for Permamind refunds)
2. Handler extracts: `ProcessId`, `Amount`, `Reason`, `OriginalMessageId`
3. Handler increments process `refundCount`
4. Handler recalculates `successRate`: `(transactionCount - refundCount) / transactionCount`
5. Handler updates skill `refundRate` if refund related to skill usage
6. Handler stores refund details for transparency
7. Handler sends warning to process creator if refund rate exceeds threshold (e.g., >5%)
8. Unit test verifies success rate decreases after refund
9. Unit test verifies multiple refunds compound correctly
10. Integration test simulates payment → refund → success rate update

### Story 4.8: Skill Quality Scoring Algorithm

**As a** agent,
**I want** a standardized quality score for skills based on multiple metrics,
**so that** I can programmatically compare competing skills.

#### Acceptance Criteria

1. Handler registered for `ScoreSkill` action
2. Handler accepts parameters: `SkillTxId`, `Weights` (optional custom weights)
3. Default weights: `{ usageCount: 0.3, successRate: 0.3, refundRate: 0.2, recency: 0.1, dependencies: 0.1 }`
4. Handler normalizes each metric to 0-1 scale (e.g., usageCount relative to max in marketplace)
5. Handler calculates weighted sum: `score = Σ(metric * weight)`
6. Handler returns score (0-100) with breakdown of individual metric contributions
7. Handler validates weights sum to 1.0
8. Handler handles edge cases: new skills (no usage), stale skills (old lastUsed)
9. Unit test verifies score calculation with default weights
10. Unit test verifies custom weights produce different scores
11. Integration test compares scores for two competing skills and validates logic

### Story 4.9: Dependency Graph Query

**As a** developer or agent,
**I want** to retrieve the complete dependency graph for a skill,
**so that** I understand all transitive dependencies and total royalty costs.

#### Acceptance Criteria

1. Handler registered for `GetDependencyGraph` action
2. Handler accepts parameter: `SkillTxId`
3. Handler recursively resolves all dependencies (depth-first)
4. Handler returns tree structure: `{ skill, dependencies: [ { skill, dependencies: [...] } ] }`
5. Handler includes metadata for each skill in tree (name, creator, royaltyPercent)
6. Handler calculates total estimated royalty percentage for entire chain
7. Handler detects and reports circular dependencies (error response)
8. Handler limits maximum depth to 3 levels (configurable)
9. Unit test verifies linear chain returns correct tree
10. Unit test verifies diamond dependency deduplicates correctly
11. Integration test queries multi-level dependency and validates structure

### Story 4.10: Registry Analytics Dashboard Data

**As a** marketplace operator,
**I want** aggregate marketplace statistics available via query,
**so that** I can monitor ecosystem health and growth.

#### Acceptance Criteria

1. Handler registered for `GetMarketplaceStats` action
2. Handler returns: total skills, total processes, total transactions, total transaction volume (AO)
3. Handler returns: average skill quality score, average process success rate
4. Handler returns: top 10 skills by usage, top 10 processes by revenue
5. Handler returns: recent activity (last 24 hours transaction count)
6. Handler calculates statistics on-demand from current state (no caching in MVP)
7. Handler includes timestamp of stats generation
8. Response format is JSON for easy parsing
9. Unit test verifies stat calculations with sample data
10. Integration test queries stats from live registry with real data
11. Documentation includes example API calls and response formats

---

## Epic 5: CLI Tooling & Developer Experience

**Epic Goal:** Build comprehensive CLI tool for process scaffolding, deployment automation, skill publishing to Arweave, wallet balance checking, and local testing, reducing developer onboarding from hours to minutes and eliminating error-prone manual operations.

### Story 5.1: CLI Project Setup and Core Architecture

**As a** CLI developer,
**I want** a well-structured TypeScript CLI project with proper tooling,
**so that** I can build maintainable, cross-platform command-line tools.

#### Acceptance Criteria

1. CLI project created at `/cli` with TypeScript configuration
2. Package.json configured with dependencies: `commander`, `chalk`, `ora`, `inquirer`, `@permaweb/aoconnect`
3. Build configuration uses `tsc` for TypeScript compilation
4. Entry point `/cli/src/index.ts` sets up commander CLI framework
5. Utility modules created: `/cli/src/utils/wallet.ts`, `/cli/src/utils/arweave.ts`, `/cli/src/utils/ao.ts`
6. CLI binary configured in package.json: `"bin": { "permamind": "./dist/index.js" }`
7. Development script supports live reload: `npm run dev`
8. ESLint and Prettier configured for code quality
9. Unit test verifies CLI loads and displays help text
10. README in `/cli` explains development setup and contribution guidelines

### Story 5.2: Wallet Balance Check Command

**As a** developer,
**I want** to check my AR and AO wallet balances with a single command,
**so that** I know if I have sufficient funds before attempting operations.

#### Acceptance Criteria

1. Command `permamind wallet-check` implemented
2. Command accepts optional `--wallet` flag for keyfile path (defaults to ArConnect or env var)
3. Command queries Arweave balance using arweave.js
4. Command queries AO token balance using aoconnect
5. Command displays balances in human-readable format with currency symbols
6. Command shows warnings if balances are low for common operations (< 0.1 AR or < 100 AO)
7. Command includes helpful text: "Get testnet tokens at [URL]" if zero balance
8. Command handles errors: wallet file not found, network unreachable
9. Unit test mocks wallet queries and verifies output format
10. Integration test queries real testnet wallets and displays balances

### Story 5.3: Process Scaffolding Command (init)

**As a** developer,
**I want** to scaffold a new payment-gated process with boilerplate code,
**so that** I can start building my service without manual setup.

#### Acceptance Criteria

1. Command `permamind init <project-name>` implemented
2. Command creates directory structure: `<project-name>/src/process.lua`, `<project-name>/README.md`
3. Command prompts user for: process name, description, default action price
4. Command generates process.lua with SDK imports, `permamind.init()`, sample gated handler
5. Command generates README with deployment instructions and usage examples
6. Command initializes package metadata file (process.json)
7. Command uses `inquirer` for interactive prompts with sensible defaults
8. Command displays success message with next steps
9. Unit test verifies directory creation and file generation
10. Integration test runs init command and validates generated process compiles

### Story 5.4: Skill Upload Command

**As a** skill creator,
**I want** to upload my skill markdown to Arweave and register it in the Registry,
**so that** processes can discover and use my skill.

#### Acceptance Criteria

1. Command `permamind skill-upload <file-path>` implemented
2. Command accepts flags: `--name`, `--description`, `--tags`, `--royalty-percent`, `--dependencies`
3. Command validates skill file exists and is readable
4. Command estimates Arweave upload cost and displays to user
5. Command prompts for confirmation before uploading
6. Command uploads file to Arweave using wallet (AR tokens)
7. Command waits for transaction confirmation and retrieves TX ID
8. Command registers skill in Registry using AO message (AO tokens)
9. Command displays final skill TX ID and Registry confirmation
10. Command handles errors: insufficient AR, upload failure, registry rejection
11. Unit test mocks Arweave upload and verifies flow
12. Integration test uploads small test skill to testnet

### Story 5.5: Process Deployment and Registration Command

**As a** developer,
**I want** to deploy my process to AO and register it in the Registry,
**so that** my service is discoverable and operational.

#### Acceptance Criteria

1. Command `permamind publish <process-directory>` implemented
2. Command validates process.lua exists and contains valid Lua code
3. Command reads metadata from process.json (name, description, pricing, skills)
4. Command deploys process to AO using `aos` CLI or aoconnect
5. Command waits for deployment confirmation and retrieves process ID
6. Command registers process in Registry with metadata
7. Command displays: process ID, Registry confirmation, estimated costs
8. Command updates process.json with deployed process ID for future reference
9. Command handles errors: invalid Lua syntax, deployment failure, registry rejection
10. Unit test mocks deployment and verifies flow
11. Integration test deploys simple process to testnet and confirms registration

### Story 5.6: Local Testing with aolite Integration

**As a** developer,
**I want** to test my process locally before deploying,
**so that** I catch bugs without wasting gas fees.

#### Acceptance Criteria

1. Command `permamind test <process-directory>` implemented
2. Command loads process.lua into aolite local environment
3. Command runs test suite from `<process-directory>/tests/*.lua`
4. Command simulates Credit-Notice deposits and gated actions
5. Command displays test results with pass/fail status
6. Command shows execution logs for debugging
7. Command validates: payment gating works, balances update correctly, handlers execute
8. Command supports watch mode: `permamind test --watch` (re-runs on file changes)
9. Unit test verifies test runner executes aolite correctly
10. Integration test runs example process tests and validates all pass

### Story 5.7: Skill Dependency Visualization Command

**As a** developer,
**I want** to visualize skill dependency graphs from the CLI,
**so that** I understand skill relationships before integrating them.

#### Acceptance Criteria

1. Command `permamind skill-graph <skill-tx-id>` implemented
2. Command queries Registry for skill metadata and dependencies
3. Command recursively fetches all dependency skills
4. Command generates ASCII tree visualization (similar to `tree` command)
5. Command displays: skill name, creator (truncated), royalty %, TX ID (first 8 chars)
6. Command shows total estimated royalty percentage at bottom
7. Command detects circular dependencies and displays warning
8. Command supports `--json` flag for machine-readable output
9. Unit test verifies tree generation logic
10. Integration test fetches real skill graph from Registry and displays

### Story 5.8: Process Query and Discovery Command

**As a** user or developer,
**I want** to search the Registry for processes from the CLI,
**so that** I can discover services without writing AO messages.

#### Acceptance Criteria

1. Command `permamind search processes` implemented
2. Command accepts flags: `--capability`, `--max-price`, `--min-success-rate`, `--limit`
3. Command queries Registry using SearchProcesses action
4. Command displays results as formatted table: Name, ProcessID (truncated), Price, Success Rate
5. Command supports `--json` flag for programmatic usage
6. Command sorts by success rate (descending) by default
7. Command allows `--sort-by` flag to change sort field
8. Command displays "No results found" message if no matches
9. Unit test mocks Registry query and verifies output formatting
10. Integration test searches Registry and validates real results

### Story 5.9: Skill Query and Discovery Command

**As a** developer,
**I want** to search the Registry for skills from the CLI,
**so that** I can find domain expertise to integrate into my processes.

#### Acceptance Criteria

1. Command `permamind search skills` implemented
2. Command accepts flags: `--tags`, `--keyword`, `--creator`, `--limit`
3. Command queries Registry using SearchSkills action
4. Command displays results as formatted table: Name, TX ID (truncated), Royalty %, Usage Count
5. Command supports `--json` flag for programmatic usage
6. Command sorts by usage count (descending) by default
7. Command allows `--sort-by` flag to change sort field
8. Command displays dependency count for each skill
9. Unit test mocks Registry query and verifies output
10. Integration test searches skills and validates results

### Story 5.10: Enhanced Help and Documentation

**As a** new developer,
**I want** comprehensive help text and examples for every command,
**so that** I can learn the CLI without reading external documentation.

#### Acceptance Criteria

1. Global help command `permamind --help` lists all commands with brief descriptions
2. Each command supports `--help` flag with detailed usage, flags, and examples
3. Help text includes: command syntax, flag descriptions, example usage, common errors
4. Help text uses colors (via chalk) for readability: commands (blue), flags (green), examples (gray)
5. Version command `permamind --version` displays CLI version and SDK compatibility
6. Global `--verbose` flag enables debug logging for all commands
7. Error messages include suggestions (e.g., "Did you mean `permamind init`?")
8. README in `/cli` includes quick start guide and command reference
9. Unit test verifies help text is present for all commands
10. Manual testing confirms help text is accurate and helpful

---

## Epic 6: Example Processes & Documentation

**Epic Goal:** Create production-ready example processes demonstrating complete Permamind capabilities (payment gating, skill composition, AI inference, royalty distribution), publish comprehensive documentation for developers, skill creators, and agents, and validate end-to-end user flows to enable the first wave of developer adoption.

### Story 6.1: Foundational Skills Creation and Publishing

**As a** skill creator,
**I want** production-ready example skills with real content,
**so that** example processes demonstrate realistic skill composition.

#### Acceptance Criteria

1. Skill created: **General Security Principles** (`/examples/skills/general-security.md`)
2. Content includes: OWASP Top 10 summary, secure coding principles, threat modeling basics
3. Metadata: `name`, `description`, `tags: [security, general]`, `royaltyPercent: 5`, `dependencies: []`
4. Skill created: **JavaScript Security Best Practices** (`/examples/skills/javascript-security.md`)
5. Content includes: XSS prevention, prototype pollution, npm audit, input validation
6. Metadata: `tags: [security, javascript]`, `royaltyPercent: 7`, `dependencies: [general-security-tx-id]`
7. Skill created: **React Security Reviewer** (`/examples/skills/react-security.md`)
8. Content includes: JSX injection risks, component security, React-specific vulnerabilities
9. Metadata: `tags: [security, react, javascript]`, `royaltyPercent: 10`, `dependencies: [javascript-security-tx-id]`
10. All skills uploaded to Arweave testnet/mainnet
11. All skills registered in Registry Process
12. TX IDs documented in `/examples/skills/skill-registry.json`
13. Manual verification: dependency chain resolves correctly (React → JS → General)

### Story 6.2: Secure Code Review Process Example

**As a** developer,
**I want** a complete code review process example,
**so that** I can see the entire Permamind system working end-to-end.

#### Acceptance Criteria

1. Process created: `/examples/code-review/process.lua`
2. Process uses all three security skills (React Security → JS Security → General Security)
3. Process defines `ReviewCode` action priced at 0.001 AO tokens
4. Process implements gated handler with automatic skill loading and royalty distribution
5. Process calls Apus inference with composed skill context + user's code
6. Process returns AI-generated security review to user
7. Process handles errors: payment insufficient, Apus failure, invalid code
8. Process includes refund logic for failed reviews
9. README documents: deployment steps, testing procedures, expected costs
10. Example includes sample test code (vulnerable React component) for demonstration
11. Process deployed to testnet and process ID documented
12. Manual test: submit payment + code → receive security review → verify royalties sent

### Story 6.3: Data Analysis Process Example

**As a** developer,
**I want** an example demonstrating different skill usage,
**so that** I understand Permamind's versatility beyond code review.

#### Acceptance Criteria

1. Skill created: **Data Analysis Techniques** (`/examples/skills/data-analysis.md`)
2. Content includes: statistical methods, trend identification, data visualization concepts
3. Skill uploaded and registered (no dependencies)
4. Process created: `/examples/data-analyzer/process.lua`
5. Process defines `AnalyzeData` action priced at 0.0005 AO tokens
6. Process accepts CSV or JSON data, calls Apus with data analysis skill context
7. Process returns: summary statistics, trends, insights, recommendations
8. Process demonstrates single-skill usage (simpler than code review)
9. README includes usage examples with sample datasets
10. Process deployed to testnet with documented process ID

### Story 6.4: Developer Quick Start Guide

**As a** new developer,
**I want** a comprehensive quick start guide,
**so that** I can go from zero to deployed process in under 30 minutes.

#### Acceptance Criteria

1. Document created: `/docs/quick-start.md`
2. Guide includes: prerequisites (Node.js, wallets), installation, first process
3. Step-by-step walkthrough: install CLI → check wallets → init project → customize → test → deploy
4. Guide includes code snippets with explanations
5. Guide addresses common issues: low balance, Lua syntax errors, deployment failures
6. Guide includes: expected outputs, screenshots of CLI commands
7. Guide links to detailed documentation for deeper topics
8. Guide tested by following verbatim (all steps work)
9. Estimated time: <30 minutes for someone with basic Lua knowledge
10. Guide includes "What's Next?" section pointing to SDK reference and examples

### Story 6.5: SDK API Reference Documentation

**As a** developer,
**I want** complete API reference for all SDK functions,
**so that** I can understand parameters, return values, and error handling.

#### Acceptance Criteria

1. Document created: `/docs/sdk-reference.md`
2. Documentation for `permamind.init(config)`: parameters, examples, validation rules
3. Documentation for `permamind.gated(actionName, handler, options)`: usage patterns, skills parameter
4. Documentation for `permamind.loadSkill(txId)`: return value, caching behavior, errors
5. Documentation for `permamind.apus.infer(prompt, skillContext)`: async pattern, credit costs
6. Documentation for balance/withdrawal handlers: user-facing actions
7. Each function includes: description, parameters table, return value, example code, error scenarios
8. Examples demonstrate common patterns: simple payment, skill composition, error handling
9. Documentation includes troubleshooting section for frequent issues
10. Code snippets are syntax-highlighted and copy-pasteable

### Story 6.6: Skill Creator Guide

**As a** subject matter expert (non-developer),
**I want** a guide for creating and monetizing skills,
**so that** I can earn passive income from my expertise.

#### Acceptance Criteria

1. Document created: `/docs/skill-creator-guide.md`
2. Guide explains: what skills are, how royalties work, revenue potential
3. Guide includes skill content best practices: markdown format, clear instructions, examples
4. Guide explains dependency system: when to depend on other skills, how royalties cascade
5. Guide walks through: writing skill markdown → getting AR wallet → uploading to Arweave → registering in Registry
6. Guide includes cost breakdown: Arweave upload (~$0.01-0.05), registry fee (~0.0001 AO)
7. Guide includes skill template with metadata schema
8. Guide explains quality metrics: usage count, royalties earned, success rate
9. Guide addresses: how to price royalties, how to improve skill ranking
10. Guide tested by non-technical reviewer for clarity

### Story 6.7: Agent Integration Guide

**As a** agent developer,
**I want** documentation for integrating Permamind into autonomous agents,
**so that** my agents can discover and pay for AI services programmatically.

#### Acceptance Criteria

1. Document created: `/docs/agent-integration.md`
2. Guide explains: AO message-based interaction, no HTTP endpoints
3. Guide includes: querying Registry, interpreting quality metrics, calculating costs
4. Guide demonstrates: search for processes → score skills → send payment → receive result
5. Guide includes example AO message formats (JSON) for all actions
6. Guide explains scoring algorithm: default weights, custom weights, interpreting scores
7. Guide includes decision logic example: "Choose process with highest score under budget"
8. Guide addresses: handling async responses, retry logic, refund scenarios
9. Guide includes complete Lua code example for agent decision-making
10. Guide explains future capabilities: agents creating services (Phase 2)

### Story 6.8: Security Best Practices Documentation

**As a** process developer,
**I want** security guidelines for building payment-gated processes,
**so that** I avoid vulnerabilities that could drain user funds.

#### Acceptance Criteria

1. Document created: `/docs/security-guide.md`
2. Guide explains Checks-Effects-Interactions (CEI) pattern with examples
3. Guide covers: replay attack prevention, message ID tracking, balance auditing
4. Guide demonstrates: common vulnerabilities (reentrancy, race conditions), how SDK prevents them
5. Guide includes: input validation, error handling, secure state management
6. Guide addresses: refund security, withdrawal limits, rate limiting
7. Guide includes checklist: security audit before deployment
8. Guide links to external audit report (when available)
9. Guide includes examples of vulnerable code vs secure code (side-by-side)
10. Guide tested by security-conscious developer for completeness

### Story 6.9: Wallet Setup and Token Economics Guide

**As a** new user,
**I want** clear instructions for setting up wallets and acquiring tokens,
**so that** I can participate in the Permamind ecosystem.

#### Acceptance Criteria

1. Document created: `/docs/wallet-setup.md`
2. Guide explains two-token system: AR (Arweave storage), AO (marketplace payments)
3. Guide includes: creating AR wallet (ArConnect extension, JSON keyfile)
4. Guide includes: creating AO wallet, bridging tokens if needed
5. Guide explains: who needs which tokens (creators: both, agents: AO only, users: AO only)
6. Guide includes: getting testnet tokens (faucets), buying mainnet tokens (exchanges)
7. Guide includes cost estimates: typical operations (skill upload, process deployment, inference)
8. Guide addresses: wallet security, private key management, backup procedures
9. Guide includes screenshots for ArConnect installation and usage
10. Guide tested by non-crypto-native user for clarity

### Story 6.10: End-to-End Integration Testing and Validation

**As a** PM,
**I want** comprehensive validation that all examples and docs work,
**so that** early adopters have a smooth experience.

#### Acceptance Criteria

1. Test plan created covering all example processes and documentation flows
2. Test: Follow quick start guide verbatim, deploy example process, verify it works
3. Test: Upload all example skills, verify dependency resolution
4. Test: Run code review example end-to-end (payment → review → royalties)
5. Test: Run data analyzer example end-to-end
6. Test: Query Registry for skills and processes using CLI
7. Test: Verify all documented CLI commands work as described
8. Test: Verify all code snippets in docs are syntactically correct
9. Test: Have non-team member follow docs and report friction points
10. All critical paths tested on testnet before MVP launch
11. Test results documented in `/docs/testing-report.md`
12. All blockers resolved before Epic 7

---

## Epic 7: Testing, Security Audit & Launch Prep

**Epic Goal:** Execute comprehensive testing across unit, integration, and edge cases, conduct external security audit of payment gating and SDK code, fix all critical and high-priority vulnerabilities, perform load testing on Registry Process, and prepare for MVP launch with early adopter onboarding materials and success metrics tracking.

### Story 7.1: Comprehensive Unit Test Suite

**As a** developer,
**I want** complete unit test coverage for all SDK modules,
**so that** I can confidently make changes without breaking existing functionality.

#### Acceptance Criteria

1. Unit tests created for all SDK modules: payment-gating, skill-loading, apus-integration, security
2. Test coverage: `permamind.init()`, `permamind.gated()`, `permamind.loadSkill()`, `permamind.apus.infer()`
3. Tests cover: happy paths, error conditions, edge cases, boundary values
4. Tests validate: CEI pattern enforcement, replay attack prevention, balance auditing
5. Tests use mocked dependencies (no actual Arweave/Apus/AO calls)
6. Test coverage report generated: aim for >80% line coverage
7. All tests pass consistently (no flaky tests)
8. Tests run automatically in CI pipeline
9. Test execution time <2 minutes for entire suite
10. Documentation in `/tests/README.md` explains test structure and how to add tests

### Story 7.2: Integration Testing with aolite

**As a** developer,
**I want** integration tests simulating complete user flows,
**so that** I verify the system works end-to-end before deploying.

#### Acceptance Criteria

1. Integration tests created in `/tests/integration/` using aolite
2. Test: User deposits → calls gated action → balance deducted → handler executes
3. Test: Multi-level skill dependency resolution (3 levels) → royalty distribution → all creators receive payments
4. Test: Apus inference request → async callback → result returned
5. Test: Failed inference → retry logic → eventual success or refund
6. Test: Registry queries (search skills, search processes, score skill, dependency graph)
7. Test: Insufficient balance rejection → error message → no execution
8. Test: Withdrawal request → Debit-Notice sent → balance zeroed
9. All integration tests pass on aolite local environment
10. Integration test suite runs in CI after unit tests
11. Test execution time <5 minutes for entire suite

### Story 7.3: Edge Case and Security Testing

**As a** security engineer,
**I want** tests validating security-critical edge cases,
**so that** I know the system resists common attacks.

#### Acceptance Criteria

1. Test: Replay attack prevention (duplicate Message-ID rejected)
2. Test: Race condition handling (concurrent payments to same action)
3. Test: Integer overflow/underflow in balance calculations
4. Test: Circular dependency detection in skills (throws error, no infinite loop)
5. Test: Maximum dependency depth enforcement (4 levels rejected)
6. Test: Token limit enforcement (8,192 token prompt rejected)
7. Test: Malformed Credit-Notice handling (invalid amount, missing fields)
8. Test: Withdrawal exceeding balance (rejected with clear error)
9. Test: Negative payment amounts (rejected)
10. Test: Royalty calculation edge cases (single creator multiple skills, 100% royalty)
11. All security tests pass with no vulnerabilities discovered
12. Security test suite documented in `/docs/security-testing.md`

### Story 7.4: Registry Process Load Testing

**As a** marketplace operator,
**I want** to verify the Registry handles 100+ concurrent queries,
**so that** I know it won't fail under real usage.

#### Acceptance Criteria

1. Load test script created: `/tests/load/registry-load-test.js`
2. Test simulates: 100 concurrent SearchSkills queries
3. Test simulates: 100 concurrent SearchProcesses queries
4. Test simulates: 50 concurrent ScoreSkill queries with different weights
5. Test measures: P50, P95, P99 response times, success rate, error rate
6. Target: P95 latency <1 second, 100% success rate
7. Test simulates: 500 total queries over 60 seconds (steady load)
8. Test monitors: Registry process memory usage, AO execution time
9. Test validates: No queries timeout, all return valid JSON
10. Load test results documented with performance recommendations
11. If targets not met, optimization performed and re-tested

### Story 7.5: External Security Audit Preparation

**As a** PM,
**I want** code prepared for external security audit,
**so that** auditors can efficiently review critical components.

#### Acceptance Criteria

1. Audit scope documented: SDK payment gating, royalty distribution, Registry handlers
2. Code frozen: no changes to security-critical modules during audit period
3. Audit package prepared: codebase snapshot, architecture docs, threat model
4. Threat model document created identifying: assets (user funds), threats (replay attacks, drains), mitigations (CEI, Message-ID tracking)
5. Known issues documented with severity ratings and mitigation plans
6. Contact created with security audit firm (or community auditors)
7. Audit timeline: 1-2 weeks for review, 1 week for fixes
8. Budget allocated for audit (or bounty program if community audit)
9. Non-disclosure agreement signed if using external firm
10. Audit kick-off meeting scheduled with clear deliverables

### Story 7.6: Security Audit Remediation

**As a** developer,
**I want** to fix all critical and high-priority vulnerabilities,
**so that** the system is secure before launch.

#### Acceptance Criteria

1. Audit report received with findings categorized: Critical, High, Medium, Low, Informational
2. All Critical vulnerabilities fixed within 48 hours
3. All High vulnerabilities fixed within 1 week
4. Medium vulnerabilities assessed: fix before launch or document as known issues
5. Low/Informational findings triaged for post-MVP
6. Fixes validated with new tests preventing regression
7. Re-audit performed on fixed code (if Critical findings existed)
8. Final audit report: no Critical or High vulnerabilities remaining
9. Audit summary published in `/docs/security-audit-summary.md`
10. Bug bounty program scoped for post-launch ongoing security

### Story 7.7: Testnet Deployment and Validation

**As a** PM,
**I want** full system deployed to testnet and validated,
**so that** we catch environment-specific issues before mainnet launch.

#### Acceptance Criteria

1. All example skills uploaded to Arweave testnet (or mainnet if no testnet)
2. All example skills registered in Registry Process (testnet deployment)
3. Registry Process deployed to AO testnet with documented process ID
4. Example processes (code-review, data-analyzer) deployed to testnet
5. CLI tool configured to interact with testnet Registry
6. End-to-end test: User deposits testnet tokens → calls process → receives AI result → skill creators receive royalties
7. Registry queries tested: search, scoring, dependency graphs
8. Performance validated: inference latency, query response times
9. All critical user flows tested by non-team members
10. Issues found on testnet documented and resolved
11. Testnet deployment guide created for early adopters

### Story 7.8: Launch Metrics and Analytics Setup

**As a** PM,
**I want** mechanisms to track MVP success metrics,
**so that** I can measure progress toward goals and identify issues.

#### Acceptance Criteria

1. Metrics tracking plan documented: KPIs from Project Brief mapped to data sources
2. Registry Process exposes analytics: total transactions, transaction volume, active processes, skill usage
3. CLI tool includes optional telemetry: command usage (anonymized), error rates
4. Tracking spreadsheet created for manual metrics: developer signups, community engagement, feedback
5. Weekly metrics review process established
6. Dashboard mockup created (even if manual initially): transaction volume, active developers, top skills
7. Alerts configured: zero transactions in 24 hours, Registry downtime, critical errors
8. Success criteria checklist from Project Brief converted to measurable gates
9. Metrics collection respects privacy: no PII, opt-in telemetry
10. First metrics snapshot taken at launch as baseline

### Story 7.9: Early Adopter Onboarding Materials

**As a** PM,
**I want** materials for onboarding first developers,
**so that** early adopters have a smooth experience and become advocates.

#### Acceptance Criteria

1. Launch announcement drafted: what Permamind is, why it matters, how to get started
2. Onboarding email sequence created: welcome, quick win, deep dive, support
3. Discord/Telegram community channels set up with clear guidelines
4. FAQ document created addressing common questions and concerns
5. Video tutorial recorded: 5-minute walkthrough from install to deployed process
6. Early adopter incentive program designed: rewards for first deployments, skill creation
7. Support resources documented: where to ask questions, how to report bugs
8. Case study template created for successful early adopters
9. Social media content prepared: launch tweets, blog post, demo video
10. Early adopter feedback form created to capture friction points

### Story 7.10: MVP Launch Readiness Review and Go/No-Go Decision

**As a** PM,
**I want** a comprehensive launch readiness review,
**so that** we launch only when truly ready and set ourselves up for success.

#### Acceptance Criteria

1. Launch checklist created from all epic acceptance criteria
2. All must-have MVP features verified working: SDK, Registry, CLI, examples, docs
3. All critical bugs resolved (zero P0 bugs)
4. Security audit complete with no Critical/High vulnerabilities
5. Testnet validation complete with all flows working
6. Documentation complete and reviewed for accuracy
7. Early adopter materials prepared and ready to distribute
8. Metrics tracking operational
9. Team prepared for launch support (monitoring, bug fixes, community engagement)
10. Go/No-Go meeting held with stakeholders
11. If GO: Launch date set, announcement scheduled, community notified
12. If NO-GO: Blockers documented, remediation plan created, re-review scheduled
13. Launch retrospective planned for Week 1 post-launch

---

## Checklist Results Report

### Executive Summary

**Overall PRD Completeness:** 95%
**MVP Scope Appropriateness:** Just Right
**Readiness for Architecture Phase:** Ready
**Most Critical Concerns:** Minor gaps in data requirements schema specifics and operational deployment frequency details. No blockers identified.

### Category Analysis Table

| Category                         | Status  | Critical Issues |
| -------------------------------- | ------- | --------------- |
| 1. Problem Definition & Context  | PASS    | None            |
| 2. MVP Scope Definition          | PASS    | None            |
| 3. User Experience Requirements  | PASS    | None            |
| 4. Functional Requirements       | PASS    | None            |
| 5. Non-Functional Requirements   | PASS    | None            |
| 6. Epic & Story Structure        | PASS    | None            |
| 7. Technical Guidance            | PASS    | None            |
| 8. Cross-Functional Requirements | PARTIAL | Missing: Specific data schema for Registry state tables, deployment frequency timeline |
| 9. Clarity & Communication       | PASS    | None            |

### Top Issues by Priority

#### BLOCKERS: None ✅

No blockers identified. PRD is ready for architecture phase.

#### HIGH: Data Schema Documentation

**Issue:** Registry state table schemas (Skills, Processes, Metrics) structure not explicitly documented in a single reference.

**Impact:** Architect may need to infer field types and relationships from scattered FRs and story ACs.

**Recommendation:** Add to Epic 4, Story 4.1 acceptance criteria:
```
9. Document Registry state schema in /docs/registry-schema.md with tables: Skills, Processes, Metrics
```

#### MEDIUM: Deployment Frequency and Environment Strategy

**Issue:** No explicit statement about deployment frequency, environment promotion strategy.

**Impact:** Operational readiness may be unclear.

**Recommendation:** Add to Technical Assumptions > Deployment Targets:
```
**Deployment Strategy:**
- MVP Phase: Deploy updates as needed (no fixed cadence)
- Post-MVP: Weekly releases to mainnet after testnet validation
- Hotfixes: Immediate deployment for Critical/High security issues
```

### Final Decision

**✅ READY FOR ARCHITECT**

The PRD and epics are comprehensive, properly structured, and ready for architectural design. The identified gaps (data schema, deployment frequency) are minor and can be addressed during architecture phase or early epic implementation without blocking progress.

---

## Next Steps

### UX Expert Prompt

**Context:** The Permamind MVP is a CLI-first AI marketplace on AO. Phase 1 targets developers via terminal tooling and agents via AO message interfaces. Web UI is explicitly deferred to post-MVP.

**Your Mission:** While the MVP is CLI-focused, please design the future web UI experience and validate that the current CLI/message-based UX patterns will translate well when we add visual interfaces in Phase 2.

**Specific Tasks:**

1. **Review CLI User Flows:** Analyze the developer workflow (init → publish) and agent message flow (search → score → pay → receive). Identify any UX friction that could be smoothed now to avoid migration issues later.

2. **Design Web UI Information Architecture:** Create the structure for the future marketplace browse experience, skill detail pages, and process discovery interfaces referenced in the UI Design Goals section.

3. **Validate Metrics for Discovery:** Review the Registry quality metrics (usage count, success rate, refund rate, etc.) from a UX perspective. Are these sufficient for users to make informed decisions? What's missing?

4. **Skill Dependency Graph Visualization:** Design how we'll visualize 3-level skill dependency chains in the web UI. This needs to be intuitive for non-technical skill creators.

5. **Error State UX:** Review error handling across CLI commands and suggest improvements for clarity. Ensure error messages guide users toward solutions.

6. **Accessibility Plan:** Though CLI-first for MVP, plan for WCAG AA compliance in the future web UI.

**Deliverables:**
- Web UI wireframes for key screens (marketplace browse, skill detail, process detail)
- CLI UX improvement recommendations (if any)
- Dependency graph visualization design
- Accessibility compliance roadmap

**Constraints:**
- MVP stays CLI-only (don't redesign what's working)
- Future web UI must support wallet integration (ArConnect)
- Visual design should reflect: permanence (Arweave), autonomy (AO), intelligence (Apus)

### Architect Prompt

**Context:** Permamind is a three-layer AI marketplace (Skills on Arweave, Processes on AO, Registry for discovery) enabling payment-gated AI services with automatic royalty distribution. See the complete PRD above.

**Your Mission:** Design the technical architecture for the MVP, focusing on the high-risk areas identified in the PM Checklist: dependency resolution, Registry scalability, security patterns, and Arweave caching.

**Specific Tasks:**

1. **SDK Architecture:** Design the module structure for payment-gating.lua, skill-loading.lua, apus-integration.lua. Specify:
   - CEI pattern implementation (Checks-Effects-Interactions)
   - Message ID tracking for replay prevention
   - Balance auditing mechanisms
   - Error propagation and refund logic

2. **Skill Dependency Resolution Algorithm:** Architect the 3-level dependency resolver with:
   - Circular dependency detection (before fetching, not during)
   - Token counting strategy to stay under 6,000 token budget
   - Caching strategy (process state vs temporary)
   - Fallback if Arweave gateway slow/unavailable

3. **Registry Process Data Structures:** Design Lua table schemas for:
   - `Skills[TxId]` - what fields? how to index for search?
   - `Processes[ProcessId]` - same questions
   - `Metrics[entityId]` - real-time aggregation approach?
   - Query optimization given limited Lua stdlib

4. **Apus Integration Async Pattern:** Architect the callback flow:
   - Request-response matching (message references)
   - Timeout handling (50s nominal, but what if 120s?)
   - Credit deduction timing (before or after confirmation?)
   - Concurrent request handling

5. **Registry Scalability:** Design for 100+ concurrent queries:
   - Can single AO process handle this? Or need sharding?
   - Pagination strategy
   - Caching layer (if any)
   - Load testing plan details

6. **Security Architecture:** Deep dive on:
   - CEI pattern enforcement (how to prevent violations?)
   - Message ID tracking (data structure, memory management)
   - Royalty split calculation (prevent rounding exploits)
   - Withdrawal limits (rate limiting?)

7. **Testing Architecture:** Design aolite test setup:
   - How to simulate Credit-Notices locally?
   - Mocking Arweave/Apus in tests
   - Integration test environment configuration

8. **Arweave Gateway Caching:** Strategy for skill loading:
   - When to cache (first fetch? all fetches?)
   - How to invalidate (or accept staleness?)
   - Fallback gateways if primary fails?

**Deliverables:**
- Architecture document with diagrams (component, sequence, data flow)
- Registry state schema specification (Lua tables)
- Security pattern reference implementation examples
- aolite testing setup guide
- Identified technical risks with mitigation strategies

**Constraints:**
- AO Lua 5.3 with limited stdlib (no file system, minimal crypto)
- 30-second execution time limit per message handler
- 8,192 token limit for Apus inference (including skill context)
- Immutable process code (no upgrades, only redeployment)
- Public by design (all transactions on-chain)

**High Priority Areas (from PM Checklist):**
1. Arweave gateway caching strategy
2. Registry process state optimization
3. Message ID tracking implementation
4. Dependency resolution within 30s execution limit
