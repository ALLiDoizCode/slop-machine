# Epic 2: Smart Contract Suite & Testnet Deployment

**Status:** Pending
**Priority:** Critical
**Dependencies:** Epic 1 (Foundation & Protocol Core)
**Estimated Duration:** 2-3 weeks

---

## Epic Goal

Develop, test, and deploy the smart contract suite for bidirectional payment channels to Base Sepolia and Optimism Sepolia testnets. This epic delivers production-ready, audited smart contracts with verified security properties, gas optimization, and comprehensive testing.

**Value Delivery:** By the end of this epic, BIMP protocol will have:
- Production-ready smart contracts deployed to two L2 testnets
- Verified security properties (reentrancy protection, signature verification)
- Gas-optimized operations (<$0.01 per settlement)
- Comprehensive test coverage (>95%)

---

## Stories

### Story 2.1: Channel Factory Contract Implementation

**As a** blockchain developer,
**I want** a smart contract that creates and manages bidirectional payment channels,
**so that** BIMP protocol participants can lock funds and settle off-chain payments.

**Acceptance Criteria:**
1. `createChannel()` function creates new bidirectional channels with specified parties and capacity
2. `deposit()` function allows parties to fund channels after creation
3. `settle()` function enables unilateral settlement with signed state commitment
4. `closeChannel()` function refunds remaining balances after channel expiry
5. Channel struct stores: id, parties (client, server), balances, lastStateNumber, expiresAt, isOpen
6. Events emitted for all state changes: ChannelCreated, ChannelFunded, ChannelSettled, ChannelClosed
7. Solidity 0.8.24 used with SafeMath (overflow protection)
8. Contract compiles without errors or warnings
9. Hardhat test suite covers all functions with >95% coverage
10. Gas reporter shows costs within acceptable range (<$0.01 per operation)

**Priority:** Critical
**Estimate:** 8 hours
**Dependencies:** Epic 1 complete

---

### Story 2.2: Signature Verification & Replay Protection

**As a** smart contract developer,
**I want** the contract to verify EIP-712 signatures and enforce state number monotonicity,
**so that** fraudulent settlements and replay attacks are prevented.

**Acceptance Criteria:**
1. `settle()` function verifies EIP-712 signature on payment state
2. Signature recovery identifies signer address and validates against channel party
3. State number must be greater than lastStateNumber (monotonic)
4. Invalid signatures revert with "Invalid signature" error
5. Non-monotonic state numbers revert with "Invalid state number" error
6. EIP-712 domain separator includes contract address and chain ID
7. TypedDataHash matches off-chain signing format (protocol implementation)
8. Unit tests verify signature verification with valid/invalid signatures
9. Unit tests verify replay attack prevention with duplicate state numbers
10. Integration tests verify signature compatibility with ethers.js signing

**Priority:** Critical
**Estimate:** 6 hours
**Dependencies:** Story 2.1

---

### Story 2.3: Reentrancy Protection & Security Hardening

**As a** smart contract security engineer,
**I want** the contract to be protected against reentrancy and other common vulnerabilities,
**so that** user funds are secure and the contract is auditable.

**Acceptance Criteria:**
1. ReentrancyGuard applied to all payable functions (createChannel, deposit, settle, closeChannel)
2. Checks-Effects-Interactions pattern enforced in all functions
3. Access control: only channel parties can settle or close their channel
4. Gas limit checks on all loops (prevent DoS via unbounded iteration)
5. SafeMath used for all arithmetic operations
6. No delegatecall or selfdestruct usage
7. Hardhat security analysis passes with zero high/critical issues
8. Slither static analysis passes with zero high/critical issues
9. Unit tests verify reentrancy protection with malicious contracts
10. Unit tests verify access control with unauthorized callers

**Priority:** Critical
**Estimate:** 6 hours
**Dependencies:** Story 2.2

---

### Story 2.4: Testnet Deployment - Base Sepolia

**As a** protocol deployer,
**I want** to deploy the Channel Factory contract to Base Sepolia testnet,
**so that** BIMP protocol can be tested with real blockchain interactions.

**Acceptance Criteria:**
1. Hardhat deployment script for Base Sepolia configured
2. Deployment script funds deployer wallet with testnet ETH
3. Contract deployed to Base Sepolia with constructor parameters
4. Contract address saved to deployments/base-sepolia.json
5. Contract verified on Basescan block explorer
6. Deployment documentation includes contract address and verification link
7. Gas costs logged and within acceptable range
8. Smoke test: create channel, deposit funds, settle, close channel on testnet
9. README updated with testnet deployment instructions
10. Deployment completes successfully without errors

**Priority:** High
**Estimate:** 4 hours
**Dependencies:** Story 2.3

---

### Story 2.5: Testnet Deployment - Optimism Sepolia

**As a** protocol deployer,
**I want** to deploy the Channel Factory contract to Optimism Sepolia testnet,
**so that** BIMP protocol supports multiple L2 ecosystems.

**Acceptance Criteria:**
1. Hardhat deployment script for Optimism Sepolia configured
2. Deployment script funds deployer wallet with testnet ETH (via Optimism faucet)
3. Contract deployed to Optimism Sepolia with constructor parameters
4. Contract address saved to deployments/optimism-sepolia.json
5. Contract verified on Optimistic Etherscan block explorer
6. Deployment documentation includes contract address and verification link
7. Gas costs logged and compared to Base Sepolia deployment
8. Smoke test: create channel, deposit funds, settle, close channel on testnet
9. README updated with Optimism testnet deployment instructions
10. Deployment completes successfully without errors

**Priority:** High
**Estimate:** 4 hours
**Dependencies:** Story 2.4

---

### Story 2.6: Gas Optimization & Benchmarking

**As a** protocol optimizer,
**I want** to minimize gas costs for all contract operations,
**so that** BIMP protocol is economically viable for micropayments.

**Acceptance Criteria:**
1. Gas reporter enabled for all Hardhat tests
2. Gas costs measured for: createChannel, deposit, settle, closeChannel
3. Storage layout optimized (struct packing, minimal storage writes)
4. Function visibility optimized (external vs public)
5. Events used instead of storage where appropriate
6. Gas costs <$0.01 per operation on Base L2 (at current gas prices)
7. Gas optimization document created with before/after metrics
8. Benchmarking script measures gas costs across different scenarios
9. Gas costs compared to target (NFR requirements)
10. All optimizations maintain >95% test coverage

**Priority:** Medium
**Estimate:** 5 hours
**Dependencies:** Story 2.5

---

## Epic Summary

**Total Stories:** 6
**Total Estimated Time:** 33 hours (~1 week with 1 developer, 2-3 weeks with parallel workstreams)
**Critical Path:** 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6

**Success Criteria:**
- ✅ Smart contracts deployed to Base Sepolia and Optimism Sepolia
- ✅ Contracts verified on block explorers
- ✅ >95% test coverage
- ✅ Zero high/critical security issues
- ✅ Gas costs <$0.01 per operation

**Next Epic:** Epic 3 - Multi-Language SDK Development
