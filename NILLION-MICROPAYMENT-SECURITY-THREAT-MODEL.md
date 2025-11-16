# Security Threat Model: Nillion-Based Web-Native Micropayment Protocol

**Research Date**: November 15, 2025
**Protocol**: Web-native interledger micropayment protocol (1000 pkt/sec target)
**Key Technologies**: Nillion Private Compute/Storage, Lightning/Raiden payment channels, WebSocket streaming
**Threat Model Version**: 1.0

---

## Executive Summary

### Critical Findings

**HIGH-SEVERITY THREATS IDENTIFIED**:
1. **Nillion Key Retrieval MITM** (Likelihood: Medium, Impact: Critical) - Active network attacker could intercept Nillion Private Compute signing requests
2. **Payment Channel HTLC Jamming** (Likelihood: High, Impact: High) - 483 HTLC slot limit enables DoS attacks
3. **WebSocket Session Hijacking** (Likelihood: Medium, Impact: Critical) - TLS downgrade or compromise exposes payment stream
4. **Cross-Chain Settlement Failures** (Likelihood: Medium, Impact: High) - One chain settles while another fails, causing fund loss
5. **High-Frequency Signing Nonce Exhaustion** (Likelihood: Low, Impact: Critical) - Nonce collision at 1000 sig/sec could enable double-spending

**OVERALL RISK ASSESSMENT**: **HIGH** - Multiple critical vulnerabilities require comprehensive mitigation strategy

**KEY INSIGHT**: The combination of **three security boundaries** (Nillion Private Compute, payment channels, WebSocket protocol) creates a complex threat surface with **interaction vulnerabilities** not present in traditional payment systems.

### Risk Matrix Summary

| Threat Category | Critical Risks | High Risks | Medium Risks | Low Risks | Total |
|-----------------|----------------|------------|--------------|-----------|-------|
| **Key Compromise** | 2 | 1 | 2 | 1 | 6 |
| **Payment Channel Attacks** | 1 | 4 | 3 | 2 | 10 |
| **Protocol Attacks** | 2 | 2 | 2 | 1 | 7 |
| **Cross-Chain Issues** | 1 | 2 | 1 | 0 | 4 |
| **Privacy Leakage** | 0 | 1 | 3 | 2 | 6 |
| **High-Frequency Signing** | 1 | 2 | 1 | 1 | 5 |
| **TOTAL** | **7** | **12** | **12** | **7** | **38** |

### Recommended Security Posture

**Minimum Viable Security (MVP)**:
- TLS 1.3 with certificate pinning
- Watchtower services for all payment channels
- Nonce-based replay prevention
- Rate limiting (100 requests/sec per connection)
- Maximum message size limits (10MB)

**Production Security**:
- Hardware Security Modules (HSMs) for key backup
- Multi-party watchtower redundancy (3+ services)
- Cross-chain atomic settlement protocols
- Comprehensive monitoring and alerting
- Security audit before mainnet launch

**Cost of Security**: ~$500-2,000/month for production-grade security infrastructure (watchtowers, monitoring, HSMs)

---

## 1. Threat Category: Key Compromise

Despite Nillion Private Storage securing keys via Multi-Party Computation (MPC), several residual risks remain.

### Threat 1.1: Man-in-the-Middle (MITM) During Nillion Key Retrieval

**Attack Vector**:
```
Client                    Attacker                     Nillion
  │                          │                            │
  ├─ Sign request ──────────►│                            │
  │                          ├─ Intercept request ───────►│
  │                          │◄─ Return signature ────────┤
  │                          ├─ Forward signature ────────►│
  │◄─ Receive signature ─────┤                            │

  Attacker now knows:
  - Signing request (message to sign)
  - Resulting signature
  - Timing/frequency of signing operations
```

**Likelihood**: **Medium**
- Requires active network attacker between client and Nillion nodes
- TLS encryption mitigates but not if TLS compromised (certificate authority breach, nation-state MITM)
- Cloud provider (AWS, GCP) could theoretically intercept traffic

**Impact**: **Critical**
- Attacker learns payment amounts, frequencies, channel IDs
- With enough signatures, attacker could perform **cryptanalysis** to derive private key (though computationally infeasible with Ed25519)
- **Privacy violation**: All payment metadata exposed

**Mitigations**:

**Existing**:
- ✅ TLS 1.3 encryption (Nillion → Client communication)
- ✅ Nillion MPC architecture (keys never reconstructed in single location)

**Needed**:
- ⚠️ **Certificate pinning** for Nillion endpoints (prevent CA compromise)
- ⚠️ **End-to-end encryption** of signing requests (encrypt request payload before sending to Nillion)
- ⚠️ **Mutual TLS authentication** (client cert verification)
- ⚠️ **VPN or Tor** for client → Nillion communication (hide network-level metadata)

**Residual Risk**: **Medium** (with all mitigations), **High** (without)

---

### Threat 1.2: Nillion Node Compromise (Insider Threat)

**Attack Vector**:
```
Nillion operates via threshold MPC (e.g., 3-of-5 nodes required to sign):

Scenario 1: Attacker compromises 3 out of 5 nodes
  → Can reconstruct private key shares
  → Full key compromise

Scenario 2: Attacker compromises 2 out of 5 nodes
  → Cannot reconstruct key
  → But can DoS signing (refuse to participate)
```

**Likelihood**: **Low**
- Requires insider access or multi-node compromise
- Nillion's decentralized architecture reduces single point of failure
- Nodes run by different entities (in theory)

**Impact**: **Critical**
- **Full key compromise** if threshold nodes compromised
- All funds in payment channels can be stolen
- Attacker can sign arbitrary transactions

**Mitigations**:

**Existing**:
- ✅ MPC threshold security (requires multiple nodes to collude)
- ✅ Nillion network has 500,000+ verifiers (dilutes trust)

**Needed**:
- ⚠️ **Geographic distribution requirement** (nodes in different jurisdictions)
- ⚠️ **Reputation-based node selection** (choose high-reputation nodes)
- ⚠️ **Key rotation** (periodically generate new keys, rotate payment channels)
- ⚠️ **Timeout-based key destruction** (if channel inactive for 30 days, rotate keys)
- ⚠️ **Hardware Security Modules (HSMs)** on Nillion nodes (if available)

**Residual Risk**: **Low** (with geographic distribution + reputation), **Medium** (without)

---

### Threat 1.3: Side-Channel Attacks on Nillion Compute

**Attack Vector**:
```
Attacker observes Nillion compute operations via:
  - Timing analysis (signing latency variations)
  - Power analysis (energy consumption patterns)
  - Cache timing attacks (if nodes share hardware)
  - Memory access patterns

With enough observations → derive key material or plaintext
```

**Likelihood**: **Low**
- Requires physical access to Nillion nodes or co-location attack
- Nillion infrastructure security likely strong (but not publicly documented)

**Impact**: **Critical**
- Key leakage enables full fund theft
- May affect multiple users if nodes shared

**Mitigations**:

**Existing**:
- ✅ Nillion MPC architecture (operations distributed across nodes)
- ⚠️ Unknown: Nillion's side-channel resistance (not documented)

**Needed**:
- ⚠️ **Constant-time cryptographic operations** (Ed25519 implementations must be side-channel resistant)
- ⚠️ **Noise injection** in signing latency (randomize response times)
- ⚠️ **Node isolation** (dedicated hardware per node, no sharing)
- ⚠️ **Regular security audits** of Nillion infrastructure

**Residual Risk**: **Low** (assuming Nillion implements best practices), **High** (if not)

---

### Threat 1.4: Social Engineering Against Users

**Attack Vector**:
```
Attacker targets user (not Nillion):
  1. Phishing: Fake Nillion dashboard, steal credentials
  2. Malware: Keylogger captures Nillion API keys
  3. Fake support: "Nillion support" asks user to export keys
  4. Browser extension: Malicious extension intercepts signing requests
```

**Likelihood**: **Medium**
- Users are weakest link in security chain
- High-value targets (large channel balances) more likely to be targeted

**Impact**: **High**
- User's payment channel keys compromised
- Limited to single user (not systemic)

**Mitigations**:

**Existing**:
- ✅ Nillion Private Storage (keys never exposed to user directly)

**Needed**:
- ⚠️ **Multi-factor authentication (MFA)** for Nillion account access
- ⚠️ **Hardware wallet integration** (Ledger, Trezor for key approval)
- ⚠️ **Rate limiting on signing** (max 1000 signatures/minute, alert on anomalies)
- ⚠️ **User education** on phishing, fake support scams
- ⚠️ **Transaction confirmation UI** (show payment amount/recipient before signing)

**Residual Risk**: **Medium** (always risk of user compromise)

---

### Threat 1.5: Key Recovery Mechanism Exploitation

**Attack Vector**:
```
If Nillion provides key recovery (for lost accounts):

Scenario 1: Weak recovery authentication
  - Attacker answers security questions
  - Recovers user's keys

Scenario 2: Email compromise
  - Attacker compromises user's email
  - Triggers key recovery
  - Receives keys via email

Scenario 3: Insider threat
  - Nillion employee with access to recovery system
  - Exports user keys
```

**Likelihood**: **Low**
- Depends on Nillion's recovery mechanism design (not documented)

**Impact**: **Critical**
- Full key compromise if recovery exploited

**Mitigations**:

**Existing**:
- ⚠️ Unknown: Nillion recovery mechanism (if it exists)

**Needed**:
- ⚠️ **No key recovery** (strongest security, but user hostile)
- ⚠️ **Time-locked recovery** (7-day delay before recovery, allows user to cancel if unauthorized)
- ⚠️ **Multi-signature recovery** (require M-of-N trusted contacts to approve)
- ⚠️ **Hardware-based recovery** (U2F key required for recovery)
- ⚠️ **Audit trail** (log all recovery attempts, alert user)

**Residual Risk**: **Low** (with time-locked + multi-sig), **High** (with weak recovery)

---

### Threat 1.6: Quantum Computing Threat

**Attack Vector**:
```
Future quantum computer with sufficient qubits:
  - Breaks ECDSA/Ed25519 via Shor's algorithm
  - Derives private keys from public keys
  - Steals all funds in payment channels
```

**Likelihood**: **Very Low** (10-20 year horizon)
- Current quantum computers: ~1000 qubits (insufficient)
- Required for ECDSA break: ~4000-8000 logical qubits
- Timeline: 2035-2045 (NIST estimate)

**Impact**: **Critical** (when/if achievable)
- All ECDSA/Ed25519 signatures breakable
- Payment channels using these schemes vulnerable

**Mitigations**:

**Existing**:
- ⚠️ None (no post-quantum cryptography in current design)

**Needed**:
- ⚠️ **Post-quantum signature schemes** (NIST PQC standards: CRYSTALS-Dilithium, Falcon, SPHINCS+)
- ⚠️ **Hybrid signatures** (classical + post-quantum, for transition period)
- ⚠️ **Key rotation plan** (migrate to PQC when standardized)
- ⚠️ **Monitor quantum computing advances** (adjust timeline based on breakthroughs)

**Residual Risk**: **Very Low** (near-term), **High** (2030+)

**Recommendation**: **Low priority for MVP**, **plan for migration path**

---

## 2. Threat Category: Payment Channel Attacks

Payment channels (Lightning/Raiden) have well-documented attack vectors. High-frequency micropayments exacerbate these risks.

### Threat 2.1: HTLC Slot Jamming (Channel Griefing)

**Attack Vector**:
```
Lightning channels support max 483 HTLCs per direction.

Attacker strategy:
  1. Open payment channel with victim
  2. Create 483 HTLCs (each $0.01) → ties up 483 slots
  3. Set HTLC expiry to maximum (2016 blocks ≈ 2 weeks)
  4. Never reveal preimage (HTLCs time out, attacker gets refund)

Result: Victim's channel unusable for 2 weeks, no monetary loss to attacker
```

**Likelihood**: **High**
- Well-known attack, documented in Lightning Network research
- Cheap to execute (no capital loss, just opportunity cost)
- Amplified by circular routing (same channel hit multiple times)

**Impact**: **High**
- **Denial of Service**: Victim cannot send/receive payments
- **Revenue loss**: Streaming service interrupted, users churn
- **Capital inefficiency**: Funds locked in jammed channel

**Mitigations**:

**Existing**:
- ⚠️ HTLC timeout (eventually refunds, but takes days/weeks)

**Needed**:
- ⚠️ **Upfront fees** (charge fee to create HTLC, even if it fails)
  - Proposal: 1% of HTLC value as non-refundable fee
  - Makes jamming expensive (483 × $0.01 × 0.01 = $0.048 per attack, but repeatable)
- ⚠️ **HTLC slot bucketing** (reserve slots for different fee tiers, prevent low-fee spam)
- ⚠️ **Reputation systems** (track failed HTLC rates, ban/throttle repeat offenders)
- ⚠️ **Shorter HTLC expiry** (6 blocks ≈ 1 hour instead of 2016 blocks)
- ⚠️ **Multiple channels** (don't rely on single channel, distribute across 3-5 channels)

**Residual Risk**: **Medium** (with upfront fees + bucketing), **High** (without)

---

### Threat 2.2: Channel Balance Probing (Privacy Attack)

**Attack Vector**:
```
Attacker sends payment probes to discover channel balance:

  1. Send $100 payment through victim's channel
     - If succeeds: Balance ≥ $100
  2. Send $500 payment
     - If fails: $100 < Balance < $500
  3. Binary search: $300, $200, $250...
     - Narrow down balance to ±$10

Result: 89.1% of Lightning channels vulnerable to balance discovery
```

**Likelihood**: **High**
- Lightning Network research shows 89.1% of mainnet channels probed successfully
- Strategic routing exacerbates (least-cost paths reveal more)

**Impact**: **Medium** (privacy violation, not fund loss)
- **Privacy leak**: Attacker learns channel balances, payment capacities
- **Enables targeted attacks**: Attacker knows which channels to jam/exploit
- **Routing advantage**: Attacker can optimize routing with balance knowledge

**Mitigations**:

**Existing**:
- ⚠️ Payment onion routing (source/destination hidden from intermediaries)

**Needed**:
- ⚠️ **Random payment failures** (fail some probes randomly, obscure true balance)
  - Example: Fail 10% of payments randomly, even if balance sufficient
- ⚠️ **Route diversity** (use multiple routes, not always cheapest)
- ⚠️ **Channel balance obfuscation** (advertise inaccurate capacity in gossip)
- ⚠️ **Tor integration** (hide node IP, reduce metadata leakage)
- ⚠️ **Private channels** (don't announce channel to network, only known peers)

**Residual Risk**: **Medium** (privacy always leaks some info in payment routing)

---

### Threat 2.3: Double-Spending via Stale State (Channel Fraud)

**Attack Vector**:
```
Payment channel state progression:
  State 1: Alice: 10 BTC, Bob: 0 BTC
  State 2: Alice: 5 BTC, Bob: 5 BTC (after Alice pays Bob)
  State 3: Alice: 2 BTC, Bob: 8 BTC (after Alice pays Bob again)

Alice (attacker) broadcasts State 1 (old state where she has 10 BTC):
  1. Bob is offline (can't detect fraud)
  2. State 1 settles after challenge period (24 hours)
  3. Alice steals 8 BTC from Bob
```

**Likelihood**: **Low**
- Requires victim offline during challenge period
- Watchtower services mitigate (monitor for fraud)

**Impact**: **Critical**
- **Full channel balance theft** if successful

**Mitigations**:

**Existing**:
- ✅ **Penalty transactions** (Lightning ln-penalty: cheat = lose all funds)
- ✅ **Challenge period** (24 hours for Bitcoin, 2 hours for Ethereum/Raiden)

**Needed**:
- ⚠️ **Watchtower services** (CRITICAL for production)
  - Minimum: 3 independent watchtowers (redundancy)
  - Cost: ~$10-50/month per channel
- ⚠️ **Pre-signed challenge transactions** (ready to broadcast within minutes)
- ⚠️ **Automated fraud monitoring** (alerts within 5 minutes of suspicious close)
- ⚠️ **High uptime requirements** (99.9%+ for dispute response)

**Residual Risk**: **Very Low** (with 3+ watchtowers), **High** (without)

---

### Threat 2.4: Replay Attacks (Nonce Reuse)

**Attack Vector**:
```
Attacker intercepts valid payment commitment with nonce N:

Attack 1: Replay same commitment (duplicate payment)
  - Send commitment nonce=42 twice
  - If server doesn't check: Payment counted twice

Attack 2: Reorder commitments (out-of-order execution)
  - Send nonce=45 before nonce=44
  - Causes state inconsistency
```

**Likelihood**: **Medium**
- Easy to execute if nonce verification weak
- WebSocket replay possible if TLS compromised

**Impact**: **High**
- **Double payment**: Attacker gets service without paying
- **State desync**: Channel state inconsistent, settlement disputes

**Mitigations**:

**Existing**:
- ✅ Sequence numbers (nonce) in payment commitments

**Needed**:
- ⚠️ **Strict nonce ordering** (reject nonce ≤ last_seen_nonce)
- ⚠️ **Nonce gap detection** (reject if nonce > last_nonce + 1, unless batch commit)
- ⚠️ **Timestamp validation** (reject commitments with timestamp in past or >5 min future)
- ⚠️ **Signature verification** (ALWAYS verify signature before processing)
- ⚠️ **State persistence** (persist last_nonce to database, survive server restart)

**Residual Risk**: **Very Low** (with strict nonce checking), **High** (without)

---

### Threat 2.5: HTLC Expiry Attacks (Time Manipulation)

**Attack Vector**:
```
HTLC (Hash Time-Locked Contract) has expiry time:

Attack 1: Eclipse attack (block victim's Bitcoin node)
  - Victim's node thinks it's block 700,000
  - Actual network: block 701,000 (HTLC expired)
  - Victim cannot reclaim funds (HTLC already claimed by attacker)

Attack 2: Time-dilation attack
  - Manipulate victim's system clock
  - Victim thinks HTLC not expired
  - Attacker already claimed HTLC on-chain
```

**Likelihood**: **Low**
- Requires eclipse attack (difficult on well-connected nodes)
- OR system clock manipulation (possible on compromised machines)

**Impact**: **High**
- **Fund loss**: Victim cannot reclaim HTLC funds
- **Channel force-close**: Stale state broadcast

**Mitigations**:

**Existing**:
- ⚠️ HTLC timeout enforced by blockchain (not client clock)

**Needed**:
- ⚠️ **Multiple Bitcoin/blockchain node connections** (prevent eclipse)
  - Minimum: 3 independent nodes (different providers)
- ⚠️ **NTP time synchronization** (prevent clock drift)
- ⚠️ **Conservative HTLC expiry margins** (set expiry 10 blocks early, safety buffer)
- ⚠️ **Watchtower monitoring** (detects HTLC expiry, auto-claims)
- ⚠️ **Alert on clock skew** (>30 seconds deviation from NTP → alert)

**Residual Risk**: **Very Low** (with multi-node + NTP), **Medium** (without)

---

### Threat 2.6: Channel Exhaustion (Liquidity Attack)

**Attack Vector**:
```
At 1000 pkt/sec, $0.001/pkt:
  - Flow: $1/second = $3,600/hour
  - If 80% unidirectional: Depletes $2,880/hour outbound

Attack: Attacker requests high-value stream
  1. Depletes victim's outbound channel capacity
  2. Victim cannot send payments to others (DoS)
  3. Forces victim to rebalance (cost: submarine swap fees)
```

**Likelihood**: **High** (natural consequence of unidirectional traffic)

**Impact**: **Medium**
- **Degraded service**: Cannot fulfill other requests
- **Rebalancing cost**: $2-6 per rebalancing operation

**Mitigations**:

**Existing**:
- ⚠️ Circular rebalancing (cheapest, but requires route availability)

**Needed**:
- ⚠️ **Emergency balance threshold** (trigger rebalancing at 10% capacity)
- ⚠️ **Automated rebalancing** (circular → submarine swap → on-chain fallback)
- ⚠️ **Multiple channels** (distribute traffic across 3-5 channels)
- ⚠️ **Bidirectional pricing** (incentivize reverse traffic with discounts)
- ⚠️ **Channel capacity monitoring** (alert when <20% remaining)

**Residual Risk**: **Low** (with automation + multiple channels), **Medium** (without)

---

### Threat 2.7: Routing Attacks (Malicious Intermediaries)

**Attack Vector**:
```
Multi-hop payment: Alice → Intermediary1 → Intermediary2 → Bob

Malicious intermediary attacks:
  1. Selective dropping (drop payments to specific destinations)
  2. Delay attacks (hold HTLC for max timeout, waste capital)
  3. Fee inflation (higher fees than advertised)
  4. Probing (learn payment graph structure)
```

**Likelihood**: **Medium**
- Any intermediary can attack
- Lightning Network: 70% sender/receiver deanonymization with single adversarial node

**Impact**: **Medium**
- **Payment failure**: User experience degraded
- **Privacy loss**: Payment metadata leaked
- **Higher costs**: Inflated routing fees

**Mitigations**:

**Existing**:
- ⚠️ Onion routing (intermediaries don't see source/destination)

**Needed**:
- ⚠️ **Direct channels** (prefer direct payment, no intermediaries)
- ⚠️ **Reputation systems** (track success rates per routing node, avoid low-reputation)
- ⚠️ **Multi-path payments** (split payment across multiple routes, reduce single-point failure)
- ⚠️ **Timeout monitoring** (detect slow intermediaries, retry on alternate route)
- ⚠️ **Fee validation** (verify actual fee matches advertised fee)

**Residual Risk**: **Low** (with direct channels + reputation), **Medium** (with multi-hop routing)

---

### Threat 2.8: Cross-Chain Atomicity Violations

**Attack Vector**:
```
Payment uses channels on two chains:
  - Ethereum channel (pays for data)
  - Bitcoin channel (settles revenue)

Attack scenario:
  1. Attacker triggers settlement on Ethereum (successful)
  2. Attacker force-closes Bitcoin channel before settlement (failure)
  3. Result: Ethereum payment received, Bitcoin payment not sent
     → Attacker double-dips
```

**Likelihood**: **Medium**
- Coordination across chains is complex
- Network partitions can cause one chain to succeed, other to fail

**Impact**: **High**
- **Fund loss**: One side paid, other side not
- **Accounting inconsistency**: Settlement records don't match

**Mitigations**:

**Existing**:
- ⚠️ Cross-chain atomic swaps (HTLCs across chains)

**Needed**:
- ⚠️ **Atomic settlement protocol** (both chains settle or neither)
  - Use coordinated HTLCs (same preimage, timeouts aligned)
- ⚠️ **Settlement state machine** (ensure both chains in same state before finalizing)
- ⚠️ **Rollback on failure** (if one chain fails, revert other chain)
- ⚠️ **Multi-signature escrow** (trusted arbiter holds funds until both chains confirm)
- ⚠️ **Monitoring both chains** (detect divergence, halt settlement if inconsistent)

**Residual Risk**: **Medium** (cross-chain atomicity is hard problem)

---

### Threat 2.9: Fee Manipulation Attacks

**Attack Vector**:
```
Dynamic fee system allows nodes to adjust fees based on channel balance.

Attack: Fee oscillation attack
  1. Attacker observes victim's fee adjustment algorithm
  2. Sends payments that trigger fee increase
  3. Stops sending (victim's fees now too high, no traffic)
  4. Repeat → DoS by pricing victim out of market
```

**Likelihood**: **Low**
- Requires understanding of victim's fee algorithm

**Impact**: **Low**
- **Revenue loss**: Fewer payments routed through victim

**Mitigations**:

**Existing**:
- ✅ Dynamic fee adjustment (market-driven)

**Needed**:
- ⚠️ **Fee update rate limiting** (max 1 fee change per 10 minutes)
- ⚠️ **Fee bounds** (min/max fee caps, prevent extreme pricing)
- ⚠️ **Smooth fee transitions** (gradual adjustments, not sudden jumps)
- ⚠️ **Fee algorithm privacy** (don't expose exact formula publicly)

**Residual Risk**: **Very Low**

---

### Threat 2.10: Payment Channel Network Fragmentation

**Attack Vector**:
```
Attacker targets high-centrality nodes (hubs):
  1. Jam channels on top 10 routing nodes
  2. Network fragments (reduced connectivity)
  3. Payment success rates drop network-wide
```

**Likelihood**: **Low**
- Requires coordinated attack on multiple nodes
- Expensive (need to jam many channels simultaneously)

**Impact**: **Medium**
- **Network-wide degradation**: All users affected
- **Higher latency**: Longer routes required

**Mitigations**:

**Existing**:
- ⚠️ Decentralized network topology (no single point of failure)

**Needed**:
- ⚠️ **Hub diversity** (connect to 5+ different hubs, not just top 3)
- ⚠️ **Fallback routes** (pre-compute backup routes)
- ⚠️ **Network monitoring** (detect fragmentation, alert)

**Residual Risk**: **Low** (Lightning Network resilient to this)

---

## 3. Threat Category: Protocol Attacks (WebSocket/HTTP Layer)

Web-native protocols introduce additional attack surface beyond traditional payment systems.

### Threat 3.1: Man-in-the-Middle on WebSocket (TLS Downgrade)

**Attack Vector**:
```
Attacker intercepts WebSocket handshake:

Attack 1: TLS stripping
  - Victim requests: wss://secure.example.com (secure WebSocket)
  - Attacker downgrades: ws://secure.example.com (plaintext)
  - Victim doesn't notice (browser shows lock icon is missing)

Attack 2: Certificate forgery
  - Attacker presents fake certificate
  - Victim accepts (user clicks "accept anyway" or pinning not implemented)
  - All WebSocket traffic decrypted by attacker
```

**Likelihood**: **Medium**
- TLS stripping tools widely available (sslstrip, mitmproxy)
- Corporate proxies often MITM TLS (inspect traffic)
- Requires active network attacker (WiFi, ISP, nation-state)

**Impact**: **Critical**
- **Full payment metadata exposure**: Amounts, channels, signatures
- **Session hijacking**: Attacker can replay/modify payments
- **Key material leakage**: If signatures leaked, cryptanalysis possible

**Mitigations**:

**Existing**:
- ✅ TLS 1.3 encryption (default for wss://)

**Needed**:
- ⚠️ **HSTS (HTTP Strict Transport Security)** (force HTTPS/WSS, prevent downgrade)
  - Header: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- ⚠️ **Certificate pinning** (client validates specific certificate, not just CA)
  - Pin server's public key hash, reject mismatches
- ⚠️ **Mutual TLS (mTLS)** (client certificate required, not just server cert)
- ⚠️ **TLS 1.3 only** (disable TLS 1.2, 1.1, 1.0 - prevent protocol downgrade)
- ⚠️ **End-to-end encryption** (encrypt payment payload before WebSocket framing)

**Residual Risk**: **Low** (with HSTS + pinning + mTLS), **High** (without)

---

### Threat 3.2: Replay Attack on WebSocket Messages

**Attack Vector**:
```
Attacker captures valid WebSocket frame with payment:

Attack 1: Replay entire frame
  - Retransmit frame to server
  - Server processes payment again (if nonce not checked)

Attack 2: Cross-session replay
  - Capture payment in session A
  - Replay in session B (different WebSocket connection)
  - Server accepts if session validation weak
```

**Likelihood**: **High** (if nonce validation weak)

**Impact**: **High**
- **Double payment**: Attacker gets service without paying
- **DoS**: Server processes duplicate work

**Mitigations**:

**Existing**:
- ✅ Nonce-based ordering (sequence numbers)

**Needed**:
- ⚠️ **Session binding** (payment commits include session ID)
  - Session ID = HMAC(server_secret, client_id, connection_timestamp)
- ⚠️ **Nonce uniqueness check** (reject if nonce seen before in any session)
- ⚠️ **Timestamp freshness** (reject messages >5 minutes old)
- ⚠️ **TLS session resumption** (0-RTT data with replay protection)

**Residual Risk**: **Very Low** (with session binding + nonce checking)

---

### Threat 3.3: WebSocket Frame Injection

**Attack Vector**:
```
Attacker injects malicious WebSocket frames into victim's connection:

Attack requires:
  - MITM position (intercept WebSocket connection)
  - TLS compromised (or plaintext ws://)

Injected frames:
  - Malicious payment commits (spend victim's balance)
  - Control frames (close connection, disrupt service)
  - Oversized frames (DoS server resources)
```

**Likelihood**: **Low** (requires TLS compromise)

**Impact**: **High**
- **Unauthorized payments**: Attacker spends victim's funds
- **DoS**: Connection disrupted

**Mitigations**:

**Existing**:
- ✅ TLS integrity protection (prevents frame injection if TLS intact)
- ✅ WebSocket frame validation (checks frame format)

**Needed**:
- ⚠️ **Application-layer signatures** (sign each payment frame, not just payment metadata)
- ⚠️ **Frame sequence numbers** (detect injected frames out of sequence)
- ⚠️ **Maximum frame size** (reject frames >10MB)

**Residual Risk**: **Very Low** (if TLS intact)

---

### Threat 3.4: Denial of Service (DoS) via Message Flooding

**Attack Vector**:
```
Attacker floods server with WebSocket messages:

Attack 1: Connection flood
  - Open 10,000 WebSocket connections
  - Exhaust server connection limits

Attack 2: Message flood
  - Send 100,000 messages/second per connection
  - Exhaust server CPU (signature verification)

Attack 3: Large message flood
  - Send 10MB messages repeatedly
  - Exhaust server memory
```

**Likelihood**: **High**
- Easy to execute (simple script)
- Amplified if signature verification expensive

**Impact**: **High**
- **Service outage**: Legitimate users cannot connect
- **Resource exhaustion**: Server crashes

**Mitigations**:

**Existing**:
- ⚠️ None (WebSocket protocol has no built-in rate limiting)

**Needed**:
- ⚠️ **Connection limits** (max 100 connections per IP)
- ⚠️ **Rate limiting** (max 1000 messages/second per connection)
- ⚠️ **Message size limits** (max 10MB per message)
- ⚠️ **Signature verification rate limit** (max 100 signatures/second per connection)
- ⚠️ **DDoS mitigation service** (CloudFlare, AWS Shield)
- ⚠️ **Payment-before-processing** (verify payment before expensive operations)

**Residual Risk**: **Low** (with comprehensive rate limiting), **High** (without)

---

### Threat 3.5: Session Hijacking (Cookie/Token Theft)

**Attack Vector**:
```
WebSocket authentication via:
  - Cookies (set during HTTP handshake)
  - JWT tokens (sent in Sec-WebSocket-Protocol or headers)

Attack 1: XSS (Cross-Site Scripting)
  - Inject script: document.cookie
  - Steal session cookie
  - Hijack WebSocket connection

Attack 2: Token leakage in URL
  - WebSocket URL: wss://example.com/stream?token=abc123
  - Token logged in server logs, browser history, referrer headers
```

**Likelihood**: **Medium**
- XSS vulnerabilities common (OWASP Top 10)
- URL token anti-pattern still used

**Impact**: **Critical**
- **Full session hijack**: Attacker impersonates user
- **Unauthorized payments**: Attacker spends victim's funds

**Mitigations**:

**Existing**:
- ⚠️ HTTPS encryption (prevents eavesdropping)

**Needed**:
- ⚠️ **HttpOnly cookies** (JavaScript cannot access, prevents XSS theft)
- ⚠️ **SameSite=Strict cookies** (prevent CSRF)
- ⚠️ **Tokens in headers, NOT URL** (avoid logging, history leaks)
- ⚠️ **Content Security Policy (CSP)** (prevent XSS injection)
  - Header: `Content-Security-Policy: default-src 'self'; script-src 'self'`
- ⚠️ **Short-lived tokens** (JWT expires in 15 minutes, require refresh)
- ⚠️ **Token rotation** (new token per WebSocket connection)

**Residual Risk**: **Low** (with HttpOnly + CSP + header-based tokens)

---

### Threat 3.6: Packet Injection (Data Tampering)

**Attack Vector**:
```
Attacker modifies WebSocket packet payloads:

Scenario 1: Payment amount manipulation
  - Change payment: {amount: 1000} → {amount: 10}
  - User pays less than required

Scenario 2: Data corruption
  - Modify application data in transit
  - Service receives corrupted data, may crash
```

**Likelihood**: **Low** (if signature covers payload)

**Impact**: **High**
- **Payment fraud**: Underpayment
- **Data integrity loss**: Corrupted application state

**Mitigations**:

**Existing**:
- ✅ TLS integrity (prevents tampering if TLS intact)

**Needed**:
- ⚠️ **Sign payload hash** (signature covers SHA256(payload), not just metadata)
  - Signature = sign(channel_id || amount || sequence || SHA256(payload))
- ⚠️ **Verify signature before processing** (reject if signature invalid)
- ⚠️ **Application-layer checksums** (CRC32 or SHA256 of payload)

**Residual Risk**: **Very Low** (if signature covers payload)

---

### Threat 3.7: Time-Based Attacks (Clock Skew)

**Attack Vector**:
```
Victim's clock is inaccurate:

Attack 1: Expired payment acceptance
  - Victim's clock: 10:00 AM
  - Actual time: 10:30 AM (30 min ahead)
  - Attacker sends payment with timestamp 10:15 AM
  - Victim accepts (thinks payment is recent)
  - But payment already expired on-chain

Attack 2: Future-dated payments
  - Attacker sets payment timestamp to future
  - Exploits timestamp-based nonce generation
```

**Likelihood**: **Low**
- Requires victim clock misconfigured

**Impact**: **Medium**
- **Replay attacks**: Old payments accepted
- **Settlement disputes**: Timestamp mismatches

**Mitigations**:

**Existing**:
- ⚠️ Timestamp validation (reject messages too old/new)

**Needed**:
- ⚠️ **NTP synchronization** (sync with pool.ntp.org, < ±30 sec drift)
- ⚠️ **Timestamp tolerance** (accept ±5 minutes, reject outside window)
- ⚠️ **Alert on clock skew** (if drift >30 seconds, alert operator)
- ⚠️ **Sequence numbers primary** (nonce, not timestamp, for ordering)

**Residual Risk**: **Very Low** (with NTP + tolerance)

---

## 4. Threat Category: Cross-Chain Issues

Multi-chain support introduces atomicity and consistency challenges.

### Threat 4.1: One Chain Settles, Another Fails (Partial Settlement)

**Attack Vector**:
```
Settlement across two chains:
  - Chain A (Ethereum): Settlement submitted, successful (6 confirmations)
  - Chain B (Bitcoin): Settlement submitted, FAILS (low fee, tx dropped)

Result: User paid on Chain A, but not Chain B
  → Accounting mismatch
  → Fund loss
```

**Likelihood**: **Medium**
- Network congestion can cause one chain to succeed, other to fail
- Fee estimation errors (gas price too low)

**Impact**: **Critical**
- **Fund loss**: One side paid, other not
- **Accounting corruption**: Settlement records inconsistent

**Mitigations**:

**Existing**:
- ⚠️ HTLCs (atomic cross-chain swaps)

**Needed**:
- ⚠️ **Two-phase commit** (prepare both chains, commit only if both ready)
  - Phase 1: Submit tx to both chains (pending state)
  - Phase 2: If both confirm, finalize. If either fails, rollback both.
- ⚠️ **Settlement coordinator** (orchestrates multi-chain settlement)
- ⚠️ **Retry logic** (if one chain fails, retry with higher fee)
- ⚠️ **Timeout bounds** (if settlement doesn't complete in 1 hour, abort and rollback)
- ⚠️ **Monitoring both chains** (detect divergence, halt settlement)

**Residual Risk**: **Medium** (cross-chain atomicity inherently risky)

---

### Threat 4.2: Race Conditions During Cross-Chain Settlement

**Attack Vector**:
```
Concurrent settlement attempts:

Timeline:
  T=0: Client triggers settlement on Ethereum
  T=1: Server (independently) triggers settlement on Bitcoin
  T=2: Both settlements succeed
  T=3: Accounting shows double settlement (funds moved twice)
```

**Likelihood**: **Low**
- Requires both parties triggering settlement simultaneously

**Impact**: **High**
- **Double settlement**: Funds settled twice
- **Over-payment**: One party pays more than owed

**Mitigations**:

**Existing**:
- ⚠️ Nonce-based ordering (prevents duplicate settlements)

**Needed**:
- ⚠️ **Settlement lock** (mutex on settlement state, only one settlement at a time)
- ⚠️ **Settlement state machine** (IDLE → PENDING → COMMITTED → FINALIZED)
  - Reject settlement if state != IDLE
- ⚠️ **Settlement coordination protocol** (client and server agree on settlement before submitting)
- ⚠️ **Idempotent settlement** (same settlement request = same result)

**Residual Risk**: **Very Low** (with settlement lock + state machine)

---

### Threat 4.3: Bridge Vulnerabilities (Cross-Chain Messaging)

**Attack Vector**:
```
If using cross-chain bridge for messaging:

Attack 1: Bridge exploit
  - Attacker exploits bridge smart contract
  - Forges cross-chain message ("settlement confirmed on Chain A")
  - Server on Chain B accepts, settles funds
  - But Chain A settlement never happened

Attack 2: Bridge censorship
  - Bridge operators refuse to relay settlement messages
  - One chain settles, other doesn't (due to message block)
```

**Likelihood**: **Low** (if using reputable bridge)
- Bridge hacks common (Wormhole $320M, Ronin $625M)

**Impact**: **Critical**
- **Fund theft**: Forged messages trigger unauthorized settlements
- **Settlement failure**: Censored messages prevent legitimate settlement

**Mitigations**:

**Existing**:
- ⚠️ None (if using third-party bridge)

**Needed**:
- ⚠️ **Avoid bridges** (use HTLCs, not bridge messaging, for settlement coordination)
- ⚠️ **Multi-bridge redundancy** (use 3+ bridges, require M-of-N confirmations)
- ⚠️ **Bridge audit reports** (only use audited bridges)
- ⚠️ **Insurance** (bridge insurance funds for exploit coverage)
- ⚠️ **Manual settlement fallback** (if bridge fails, manual on-chain settlement)

**Residual Risk**: **Medium** (bridges are high-risk components)

---

### Threat 4.4: Blockchain Reorganization (Reorg) Attacks

**Attack Vector**:
```
Settlement transaction confirmed on blockchain:
  - Block 1000: Settlement tx included
  - 6 confirmations: Considered final
  - Block 1007: Blockchain reorganizes (deeper chain found)
  - Settlement tx removed from canonical chain

Result: Settlement reversed, funds not moved
```

**Likelihood**: **Low** (6+ confirmations very unlikely to reorg)
- Bitcoin: 6 blocks (~1 hour) = extremely rare reorg
- Ethereum: 32 blocks (~6.4 min) = finality under PoS

**Impact**: **High**
- **Settlement reversal**: Thought finalized, but reverted
- **Accounting errors**: Database shows settled, blockchain shows not

**Mitigations**:

**Existing**:
- ✅ Confirmation depth (wait for N confirmations)

**Needed**:
- ⚠️ **Deep confirmations** (12+ for Bitcoin, 32+ for Ethereum)
- ⚠️ **Finality monitoring** (detect reorgs, alert immediately)
- ⚠️ **Settlement state: PENDING until finality** (don't mark FINALIZED until deep confirmations)
- ⚠️ **Reorg detection** (monitor blockchain, detect if settlement tx dropped)
- ⚠️ **Automatic re-submission** (if reorg detected, re-submit settlement tx)

**Residual Risk**: **Very Low** (with deep confirmations + monitoring)

---

## 5. Threat Category: Privacy Leakage

High-frequency micropayments create rich metadata for privacy analysis.

### Threat 5.1: Nillion Sees Transaction Metadata

**Attack Vector**:
```
Nillion Private Compute receives signing requests:
  - Request: sign(channel_id, amount, sequence, payload_hash)
  - Nillion nodes can observe:
    - Signing frequency (1000 requests/sec = high-value user)
    - Payment amounts (even if encrypted, frequency reveals throughput)
    - Timing patterns (daily usage, peak hours)

If Nillion is compromised or compelled:
  - Traffic analysis reveals user behavior
  - Payment graph reconstruction
```

**Likelihood**: **Medium**
- Nillion nodes see signing requests (inherent to MPC architecture)
- Legal compulsion (subpoena, government request) could force data disclosure

**Impact**: **Medium** (privacy violation, not fund loss)
- **Deanonymization**: User identity linked to payment patterns
- **Surveillance**: Government/adversary tracks user activity

**Mitigations**:

**Existing**:
- ⚠️ Nillion MPC (no single node sees full plaintext)

**Needed**:
- ⚠️ **Encrypt signing requests** (encrypt payload before sending to Nillion)
  - Nillion sees: sign(encrypted_blob)
  - Nillion doesn't see: channel_id, amount, sequence
- ⚠️ **Tor for Nillion communication** (hide client IP from Nillion nodes)
- ⚠️ **Batching obfuscation** (vary batch sizes randomly, 50-150 packets instead of fixed 100)
- ⚠️ **Dummy signing requests** (send fake requests to obscure true traffic)
- ⚠️ **Nillion node selection** (choose nodes in privacy-friendly jurisdictions)

**Residual Risk**: **Low** (with encryption + Tor), **High** (without)

---

### Threat 5.2: Packet-Payment Correlation

**Attack Vector**:
```
Network observer (ISP, CDN, proxy) sees:
  - WebSocket traffic timing
  - Packet sizes (even if encrypted)
  - Payment frequency (inferred from traffic bursts)

Traffic analysis:
  - Packet size 1KB every 1ms = video streaming
  - Payment burst every 100ms = batched micropayments
  → Observer infers: User watching premium video content
```

**Likelihood**: **High**
- TLS hides content, not metadata (packet sizes, timing)
- ISPs routinely collect this data

**Impact**: **Low** (privacy leak, not critical)
- **Usage pattern deanonymization**: What user is doing
- **Service identification**: Which service user is accessing

**Mitigations**:

**Existing**:
- ✅ TLS encryption (hides payload content)

**Needed**:
- ⚠️ **Traffic padding** (add random bytes to packets, obscure true size)
  - Padded size: round up to nearest 1KB boundary
- ⚠️ **Constant-rate transmission** (send packets at fixed interval, even if no data)
  - Example: Send packet every 1ms, pad with zeros if no data
- ⚠️ **Tor/VPN** (hide source IP from ISP/observer)
- ⚠️ **Packet size randomization** (vary packet sizes ±10%)

**Residual Risk**: **Medium** (traffic analysis always leaks some info)

---

### Threat 5.3: Blockchain Metadata Exposure

**Attack Vector**:
```
Settlement transactions on public blockchains expose:
  - Channel funding amounts (visible on-chain)
  - Settlement timing (when channels settled)
  - Channel participants (addresses visible)
  - Total transaction volume (sum of settlements)

Blockchain analysis:
  - Cluster addresses (heuristics: common input, change address)
  - Link to real-world identity (exchange KYC, IP addresses)
  - Transaction graph analysis (who pays whom)
```

**Likelihood**: **High**
- Blockchain data is public and permanent
- Chainalysis companies specialize in deanonymization

**Impact**: **High** (for privacy-sensitive users)
- **Full payment history exposed**: All settlements visible
- **Identity linking**: Blockchain addresses linked to real names

**Mitigations**:

**Existing**:
- ⚠️ Payment channels (reduce on-chain footprint, most payments off-chain)

**Needed**:
- ⚠️ **Address rotation** (use new address for each channel)
- ⚠️ **CoinJoin/mixing** (mix funds before opening channels)
- ⚠️ **Privacy coins** (use Monero/Zcash for settlement, not Bitcoin/Ethereum)
- ⚠️ **Tor when broadcasting tx** (hide IP from blockchain nodes)
- ⚠️ **Minimum settlement amounts** (don't settle <$100, reduces on-chain leaks)

**Residual Risk**: **High** (public blockchains inherently leak metadata)

---

### Threat 5.4: Routing Privacy (Payment Graph Leakage)

**Attack Vector**:
```
Multi-hop routing reveals payment paths to intermediaries:

Payment: Alice → Node1 → Node2 → Bob

Node1 observes:
  - Payment came from Alice (or someone close to Alice)
  - Payment going toward Bob (or someone close to Bob)
  - Payment amount (even if onion-routed, amount visible)

With many observations:
  - Node1 builds payment graph
  - 70% sender/receiver deanonymization (Lightning Network research)
```

**Likelihood**: **High** (if using multi-hop routing)

**Impact**: **Medium**
- **Payment graph reconstruction**: Who pays whom
- **Deanonymization**: Link payments to identities

**Mitigations**:

**Existing**:
- ⚠️ Onion routing (source/destination hidden from intermediaries)

**Needed**:
- ⚠️ **Direct channels** (no intermediaries, no routing metadata)
- ⚠️ **Route randomization** (don't always use cheapest route)
- ⚠️ **Decoy payments** (send fake payments to obscure true payments)
- ⚠️ **Avoid high-centrality nodes** (don't route through hubs, they see too much)
- ⚠️ **Private channels** (don't announce channels to network)

**Residual Risk**: **Medium** (routing always leaks some info)

---

### Threat 5.5: WebSocket Session Metadata

**Attack Vector**:
```
WebSocket connection metadata visible to network observers:
  - Client IP address
  - Server IP address
  - Connection duration (session length)
  - Data volume (total bytes transferred)
  - Connection timing (when user active/inactive)

ISP/government observer:
  - User 192.168.1.100 connected to premium-streaming-service.com
  - Session: 2 hours, 5GB transferred
  → Infer: User watched 2 hours of premium video
```

**Likelihood**: **High** (metadata always visible)

**Impact**: **Low**
- **Usage tracking**: ISP knows what services user accesses
- **Censorship**: ISP can block access to specific services

**Mitigations**:

**Existing**:
- ✅ TLS encryption (hides content)

**Needed**:
- ⚠️ **VPN/Tor** (hide destination from ISP)
- ⚠️ **Domain fronting** (use CDN to obscure real destination)
  - Connect to cloudflare.com, but route to actual service
- ⚠️ **Obfuscation proxies** (Obfs4, Shadowsocks)

**Residual Risk**: **Medium** (VPN/Tor mitigates, but not perfect)

---

### Threat 5.6: Timing Analysis Attacks

**Attack Vector**:
```
Attacker observes timing of payments:

Scenario: User pays for API calls
  - Payment every 1ms = very high-frequency user (premium tier)
  - Payment every 1s = low-frequency user (free tier)

Attacker observes:
  - Daily payment patterns (9 AM - 5 PM = office worker)
  - Weekend gaps (no payments Saturday/Sunday)
  - Geographic correlation (payment timing matches timezone)

→ Deanonymization via timing fingerprinting
```

**Likelihood**: **Medium**

**Impact**: **Low**
- **User profiling**: Learn user behavior patterns
- **Reduced anonymity**: Timing fingerprint unique to user

**Mitigations**:

**Existing**:
- ⚠️ Batching (obscures per-packet timing)

**Needed**:
- ⚠️ **Random delays** (add 0-100ms random delay to payments)
- ⚠️ **Constant-rate payments** (send payment every 100ms, regardless of actual usage)
- ⚠️ **Dummy payments** (send fake payments during idle periods)

**Residual Risk**: **Low** (with random delays + dummy payments)

---

## 6. Threat Category: High-Frequency Signing Risks

Signing 1000+ packets/second (or even 10 batches/second) introduces unique risks.

### Threat 6.1: Key Exposure from Repeated Operations

**Attack Vector**:
```
High-frequency signing increases attack surface:

Cryptanalysis:
  - Attacker collects 1 million signatures (takes ~16 minutes at 1000/sec)
  - Analyzes signatures for patterns (biased nonce generation, timing side-channels)
  - Derives private key (if implementation flawed)

Example: ECDSA nonce reuse
  - Two signatures with same nonce (k) → private key leakage
  - PlayStation 3 hack (2010): ECDSA nonce reuse → full key compromise
```

**Likelihood**: **Low** (if using Ed25519)
- Ed25519: Deterministic signatures (no RNG, no nonce reuse risk)
- ECDSA: Risky if RNG weak

**Impact**: **Critical**
- **Full key compromise**: Attacker derives private key
- **All channel funds stolen**

**Mitigations**:

**Existing**:
- ✅ Ed25519 (deterministic, no nonce reuse risk)

**Needed**:
- ⚠️ **Use Ed25519, NOT ECDSA** (for high-frequency signing)
- ⚠️ **Nonce validation** (if using ECDSA, verify nonce never reused)
- ⚠️ **Hardware RNG** (if using ECDSA, use hardware entropy source)
- ⚠️ **Side-channel resistant implementation** (constant-time signing)
- ⚠️ **Key rotation** (rotate keys every 1M signatures or 30 days)

**Residual Risk**: **Very Low** (with Ed25519), **High** (with ECDSA)

---

### Threat 6.2: Nonce Management Failures

**Attack Vector**:
```
Nonce (sequence number) must be unique per payment:

Attack 1: Nonce overflow
  - uint32 nonce: Max 4,294,967,295
  - At 1000 pkt/sec: Overflows in 49 days
  - After overflow, nonce wraps to 0 → replay attacks

Attack 2: Nonce collision (if using timestamp-based nonce)
  - Nonce = Unix timestamp (seconds)
  - At 1000 pkt/sec: Multiple packets in same second
  - Same nonce for multiple packets → last one wins, others rejected
```

**Likelihood**: **Medium** (if nonce design flawed)

**Impact**: **Critical**
- **Replay attacks**: After overflow, old payments replayed
- **Payment failures**: Nonce collisions cause rejected payments

**Mitigations**:

**Existing**:
- ⚠️ Nonce-based ordering

**Needed**:
- ⚠️ **uint64 nonce** (max 18 quintillion, never overflows in practice)
  - At 1000 pkt/sec: 584 million years to overflow
- ⚠️ **Nonce overflow detection** (alert when nonce > 2^63)
- ⚠️ **Automatic channel rotation** (close channel after 10M packets, open new one)
- ⚠️ **Timestamp + counter nonce** (if using timestamp, add per-second counter)
  - Nonce = (unix_timestamp << 32) | counter
  - Supports 4 billion packets per second

**Residual Risk**: **Very Low** (with uint64), **High** (with uint32 or timestamp-only)

---

### Threat 6.3: Rate Limiting Bypass

**Attack Vector**:
```
Attacker attempts to exceed rate limits:

Attack 1: Distributed bypass
  - Open 100 WebSocket connections from different IPs
  - Each connection: 100 pkt/sec
  - Total: 10,000 pkt/sec (exceeds single-connection 1000 pkt/sec limit)

Attack 2: Burst attack
  - Send 10,000 packets in 1 second (burst)
  - Server processes all before rate limit kicks in
  - DoS server CPU
```

**Likelihood**: **High**
- Easy to execute (simple script)

**Impact**: **High**
- **DoS**: Server resources exhausted
- **Unfair usage**: Attacker consumes disproportionate resources

**Mitigations**:

**Existing**:
- ⚠️ Per-connection rate limiting

**Needed**:
- ⚠️ **Per-IP rate limiting** (limit total packets from single IP, across all connections)
  - Example: Max 1000 pkt/sec per IP (sum of all connections)
- ⚠️ **Global rate limiting** (limit total server throughput)
  - Example: Max 100,000 pkt/sec server-wide
- ⚠️ **Token bucket algorithm** (allow bursts, but limit sustained rate)
  - Bucket size: 1000 tokens (allows burst of 1000 packets)
  - Refill rate: 1000 tokens/second
- ⚠️ **Payment-based prioritization** (paid users get higher rate limits)

**Residual Risk**: **Low** (with per-IP + global + token bucket)

---

### Threat 6.4: Signature Malleability

**Attack Vector**:
```
Signature malleability: Same message has multiple valid signatures

ECDSA malleability:
  - Signature (r, s) is valid
  - Signature (r, -s mod n) is also valid
  - Attacker modifies signature without private key

Attack:
  1. Intercept valid payment with signature (r, s)
  2. Modify to (r, -s mod n)
  3. Replay modified signature
  4. Server accepts (both signatures valid)
  → Payment counted twice
```

**Likelihood**: **Low**
- Ed25519: Not malleable
- ECDSA: Malleable (but can be normalized)

**Impact**: **High**
- **Double payment**: Modified signature accepted as different payment

**Mitigations**:

**Existing**:
- ✅ Ed25519 (not malleable)

**Needed**:
- ⚠️ **Use Ed25519** (preferred for non-malleability)
- ⚠️ **Low-S normalization** (if using ECDSA, enforce s < n/2)
- ⚠️ **Signature uniqueness check** (reject if different signature for same nonce)

**Residual Risk**: **Very Low** (with Ed25519), **Medium** (with ECDSA)

---

### Threat 6.5: Signature Cache Poisoning

**Attack Vector**:
```
If server caches signature verification results:

Attack:
  1. Send valid payment with signature S (cached as valid)
  2. Send modified payment (different amount) with SAME signature S
  3. Server checks cache: Signature S is valid (cached)
  4. Server accepts modified payment without re-verifying signature
```

**Likelihood**: **Low** (if caching properly implemented)

**Impact**: **High**
- **Payment fraud**: Attacker pays less than required

**Mitigations**:

**Existing**:
- ⚠️ None (if caching not implemented)

**Needed**:
- ⚠️ **Cache key includes full message** (not just signature)
  - Cache key: SHA256(signature || channel_id || amount || sequence || payload_hash)
- ⚠️ **Short cache TTL** (expire cache entries after 1 second)
- ⚠️ **Cache size limits** (max 10,000 entries, LRU eviction)
- ⚠️ **Avoid caching altogether** (signature verification fast enough with Ed25519)

**Residual Risk**: **Very Low** (if caching avoided or properly implemented)

---

## 7. Security Recommendations

### 7.1 Critical Mitigations (MUST Implement for MVP)

**Priority 1 - Prevents Fund Loss**:
1. ✅ **TLS 1.3 with HSTS** (prevent MITM, downgrade attacks)
2. ✅ **Watchtower services (3+)** (prevent stale state fraud)
3. ✅ **Nonce-based replay prevention** (uint64 sequence numbers)
4. ✅ **Signature verification before processing** (payment-first pattern)
5. ✅ **Ed25519 signatures** (deterministic, fast, non-malleable)
6. ✅ **Rate limiting** (per-connection, per-IP, global limits)
7. ✅ **Maximum message size limits** (10MB cap)
8. ✅ **Certificate pinning** (prevent CA compromise)

**Priority 2 - Prevents DoS**:
9. ✅ **HTLC upfront fees** (prevent jamming attacks)
10. ✅ **Emergency balance threshold** (trigger rebalancing at 10%)
11. ✅ **Automated rebalancing** (circular → submarine → on-chain)
12. ✅ **Connection limits** (max 100 per IP)

### 7.2 Production Mitigations (Required for Mainnet)

**Security Infrastructure**:
1. ⚠️ **Multi-signature watchtowers** (3+ independent services)
2. ⚠️ **Hardware Security Modules (HSMs)** (for key backup)
3. ⚠️ **Mutual TLS (mTLS)** (client certificate verification)
4. ⚠️ **Comprehensive monitoring** (Prometheus + Grafana + PagerDuty)
5. ⚠️ **Security audit** (third-party audit before mainnet)

**Payment Channel Hardening**:
6. ⚠️ **Multiple channels** (3-5 channels per service, distribute risk)
7. ⚠️ **HTLC slot bucketing** (prevent low-fee jamming)
8. ⚠️ **Reputation systems** (track routing node success rates)
9. ⚠️ **Pre-signed challenge transactions** (auto-respond to fraud within minutes)

**Protocol Security**:
10. ⚠️ **End-to-end encryption** (encrypt signing requests to Nillion)
11. ⚠️ **Session binding** (payments include session ID)
12. ⚠️ **Timestamp validation** (±5 minute tolerance)
13. ⚠️ **Application-layer signatures** (sign payload hash, not just metadata)

**Cross-Chain Security**:
14. ⚠️ **Two-phase commit** (atomic settlement across chains)
15. ⚠️ **Settlement coordinator** (orchestrate multi-chain settlement)
16. ⚠️ **Deep confirmations** (12+ Bitcoin, 32+ Ethereum)
17. ⚠️ **Reorg detection** (monitor blockchain, re-submit if needed)

**Privacy Enhancements**:
18. ⚠️ **Tor for Nillion communication** (hide client IP)
19. ⚠️ **Traffic padding** (obscure packet sizes)
20. ⚠️ **Address rotation** (new address per channel)

### 7.3 Security Audit Scope

**Recommended Audit Areas**:

**Smart Contracts** (if custom contracts):
- Payment channel contracts (Lightning/Raiden extensions)
- Settlement logic
- Cross-chain bridges (if used)
- Estimated cost: $50,000-150,000 (2-4 weeks, reputable firm)

**Cryptography**:
- Signature schemes (Ed25519 implementation)
- Nonce generation
- Key derivation
- RNG quality
- Estimated cost: $30,000-50,000 (1-2 weeks, crypto specialist)

**Protocol Security**:
- WebSocket handshake protocol
- Payment commitment format
- Replay prevention
- DoS resilience
- Estimated cost: $40,000-80,000 (2-3 weeks, protocol expert)

**Integration Security**:
- Nillion Private Compute integration
- Payment channel integration (Lightning/Raiden)
- Cross-chain coordination
- Estimated cost: $20,000-40,000 (1 week)

**Total Estimated Audit Cost**: **$140,000-320,000** (6-10 weeks)

### 7.4 Recommended Security Budget

**Monthly Operational Costs**:
- Watchtower services (3 providers): $30-150/month
- HSM as a service: $100-500/month
- Monitoring infrastructure (Datadog/New Relic): $100-300/month
- DDoS mitigation (CloudFlare): $200-2,000/month
- Security incident response retainer: $500-2,000/month

**Total Monthly**: **$930-4,950/month** (~$1,000-5,000/month)

**One-Time Costs**:
- Security audit: $140,000-320,000
- Penetration testing: $20,000-50,000
- Infrastructure setup: $10,000-30,000

**Total One-Time**: **$170,000-400,000**

**Year 1 Total Security Cost**: **$180,000-460,000**

### 7.5 Security Metrics & Monitoring

**Key Metrics to Track**:

**Payment Channel Health**:
- Channel balance distribution (alert if <10% remaining)
- HTLC slot usage (alert if >400/483 slots used)
- Successful payment rate (alert if <95%)
- Settlement success rate (alert if <99%)
- Rebalancing frequency (track cost trends)

**Protocol Security**:
- Invalid signature rate (alert if >0.1%)
- Replay attempt rate (should be 0)
- Rate limit violations (track per IP)
- Connection flood attempts (track per IP)
- WebSocket connection duration (detect anomalies)

**Nillion Integration**:
- Signing latency (p50, p95, p99)
- Signing success rate (alert if <99.9%)
- Nillion API errors (alert on any error)
- Key retrieval latency

**Cross-Chain**:
- Settlement atomicity violations (should be 0)
- Blockchain reorg detections
- Cross-chain settlement latency
- Failed settlement transactions

**Privacy**:
- TLS handshake failures (potential MITM)
- Certificate pinning violations (alert immediately)
- Unusual traffic patterns (timing analysis attacks)

**Alerting Thresholds**:
- **P0 (Critical)**: Watchtower offline, key compromise detected, settlement atomicity violation
- **P1 (High)**: Channel balance <5%, HTLC jamming detected, invalid signatures >1%
- **P2 (Medium)**: Channel balance <10%, settlement failure, Nillion latency >500ms
- **P3 (Low)**: Rate limit violations, connection anomalies

### 7.6 Incident Response Plan

**Security Incident Categories**:

**Category 1: Key Compromise**
- Response time: Immediate (<5 minutes)
- Actions:
  1. Halt all signing operations
  2. Force-close all payment channels (submit latest state)
  3. Rotate to backup keys (if available)
  4. Notify all users
  5. Post-mortem within 24 hours

**Category 2: Payment Channel Fraud**
- Response time: <15 minutes (within challenge period)
- Actions:
  1. Watchtower auto-submits challenge transaction
  2. Verify challenge successful (monitor blockchain)
  3. Identify fraud source (log analysis)
  4. Ban attacker IP/channel
  5. Report to law enforcement if >$10k loss

**Category 3: Protocol Attack (DoS)**
- Response time: <30 minutes
- Actions:
  1. Enable aggressive rate limiting
  2. Activate DDoS mitigation (CloudFlare "I'm Under Attack" mode)
  3. Ban attacker IPs
  4. Scale infrastructure (add servers)
  5. Notify users of degraded service

**Category 4: Cross-Chain Settlement Failure**
- Response time: <1 hour
- Actions:
  1. Halt new settlements
  2. Investigate failure (which chain failed, why)
  3. Manual rollback if atomicity violated
  4. Re-submit settlement with higher fee
  5. Audit all recent settlements for consistency

**Category 5: Privacy Breach**
- Response time: <24 hours
- Actions:
  1. Identify scope of breach (what data leaked)
  2. Notify affected users
  3. Implement additional privacy mitigations
  4. Security audit of affected component
  5. Publish transparency report

### 7.7 Security Best Practices Checklist

**Development Phase**:
- [ ] Use Ed25519 signatures (not ECDSA)
- [ ] Implement strict nonce validation (uint64, no gaps)
- [ ] Sign payload hash (not just metadata)
- [ ] Use TLS 1.3 with HSTS
- [ ] Implement certificate pinning
- [ ] Add rate limiting (per-connection, per-IP, global)
- [ ] Set maximum message sizes (10MB)
- [ ] Validate timestamps (±5 minute tolerance)
- [ ] Implement session binding (payments include session ID)
- [ ] Use HttpOnly cookies (prevent XSS theft)
- [ ] Set CSP headers (prevent XSS injection)
- [ ] Enable watchtower services (3+ providers)
- [ ] Implement automated rebalancing
- [ ] Add emergency balance threshold (10%)
- [ ] Use two-phase commit for cross-chain settlement
- [ ] Implement deep confirmation requirements (12+ Bitcoin, 32+ Ethereum)

**Testing Phase**:
- [ ] Penetration testing (third-party)
- [ ] Fuzz testing (payment protocol inputs)
- [ ] Load testing (1000 pkt/sec sustained)
- [ ] Chaos engineering (simulated failures)
- [ ] Replay attack testing
- [ ] DoS resilience testing
- [ ] Cross-chain settlement failure testing
- [ ] Key rotation testing
- [ ] Watchtower failover testing

**Deployment Phase**:
- [ ] Security audit completed (all critical findings resolved)
- [ ] Monitoring deployed (Prometheus + Grafana + PagerDuty)
- [ ] Incident response plan documented
- [ ] Watchtowers activated (3+ independent services)
- [ ] DDoS mitigation enabled (CloudFlare/AWS Shield)
- [ ] HSM configured (for key backup)
- [ ] Backup & disaster recovery tested
- [ ] Security runbook created (for on-call team)

**Operational Phase**:
- [ ] Weekly security metric review
- [ ] Monthly watchtower failover tests
- [ ] Quarterly key rotation
- [ ] Quarterly security posture review
- [ ] Annual security audit
- [ ] Annual penetration testing
- [ ] Bug bounty program (optional, but recommended)

---

## 8. Comparison to Lightning/Raiden Security

### 8.1 Similarities

**Shared Threats**:
1. ✅ HTLC jamming attacks (same 483 slot limit in Lightning)
2. ✅ Balance probing attacks (89.1% of Lightning channels vulnerable)
3. ✅ Stale state fraud (resolved by penalty transactions + watchtowers)
4. ✅ Routing privacy leaks (70% deanonymization in Lightning)
5. ✅ Channel exhaustion (liquidity management challenge)

**Shared Mitigations**:
1. ✅ Watchtower services (Lightning/Raiden standard practice)
2. ✅ Challenge periods (24 hours Lightning, 2 hours Raiden)
3. ✅ Penalty transactions (lose all funds if fraud detected)
4. ✅ Onion routing (hide source/destination from intermediaries)

### 8.2 Differences

**Additional Threats (This Protocol)**:
1. ⚠️ **Nillion dependency**: Lightning/Raiden use client-side signing (no Nillion risk)
2. ⚠️ **WebSocket layer**: Lightning uses P2P network (no HTTP/WebSocket)
3. ⚠️ **Cross-chain atomicity**: Lightning is Bitcoin-only (no multi-chain coordination)
4. ⚠️ **High-frequency signing**: Lightning signs HTLCs (less frequent than 1000 pkt/sec)
5. ⚠️ **Nillion MITM risk**: Lightning keys stored locally (no network retrieval)

**Stronger Security (This Protocol)**:
1. ✅ **Nillion MPC**: Keys never in single location (vs. Lightning hot wallet)
2. ✅ **Batching**: Reduces signature frequency (vs. Lightning per-HTLC signing)
3. ✅ **Ed25519**: Faster, deterministic (vs. Lightning ECDSA with RNG risk)

**Weaker Security (This Protocol)**:
1. ❌ **WebSocket attack surface**: Lightning P2P more resilient
2. ❌ **Nillion dependency**: Single point of failure if Nillion compromised
3. ❌ **Cross-chain complexity**: Lightning single-chain simpler, fewer edge cases

### 8.3 Security Posture Assessment

**Lightning Network Security**: ★★★★☆ (4/5)
- Mature (5+ years production)
- Battle-tested ($200M+ TVL)
- Well-understood attack vectors
- Active mitigation development

**Raiden Network Security**: ★★★★☆ (4/5)
- Mature (4+ years production)
- Audited smart contracts
- Ethereum-specific optimizations
- Lower TVL than Lightning (less battle-tested)

**This Protocol Security**: ★★★☆☆ (3/5, MVP) → ★★★★☆ (4/5, with all mitigations)
- New architecture (not battle-tested)
- Additional dependencies (Nillion, WebSocket)
- Cross-chain complexity
- But: Strong mitigations available
- With full implementation: Comparable to Lightning/Raiden

---

## 9. Residual Risk Summary

After implementing ALL recommended mitigations, residual risks remain:

### 9.1 High Residual Risks (Accept or Avoid Feature)

**Risk 1: Quantum Computing Threat**
- Timeline: 2030-2045
- Mitigation: Plan post-quantum migration path
- Acceptance: Low priority for MVP, monitor developments

**Risk 2: Cross-Chain Settlement Atomicity**
- Inherent complexity of multi-chain coordination
- Mitigation: Two-phase commit, monitoring, retry logic
- Acceptance: Some risk unavoidable, limit exposure via small settlement amounts

**Risk 3: Blockchain Metadata Leakage**
- Public blockchains inherently leak metadata
- Mitigation: Privacy coins, mixing, address rotation
- Acceptance: Privacy-sensitive users should use privacy coins (Monero)

### 9.2 Medium Residual Risks (Monitor)

**Risk 4: Nillion Node Compromise**
- MPC threshold security (requires multiple nodes)
- Mitigation: Geographic distribution, reputation systems
- Monitoring: Audit Nillion node security regularly

**Risk 5: Routing Privacy**
- Multi-hop routing leaks payment graph
- Mitigation: Direct channels, route randomization
- Acceptance: Privacy vs. liquidity tradeoff

**Risk 6: Payment Channel Network Fragmentation**
- Hub-based topology creates single points of failure
- Mitigation: Hub diversity, fallback routes
- Monitoring: Network topology analysis

### 9.3 Low Residual Risks (Acceptable)

**Risk 7: Social Engineering**
- Users always weakest link
- Mitigation: MFA, education, hardware wallets
- Acceptance: User responsibility

**Risk 8: Traffic Analysis**
- Packet timing/size leaks usage patterns
- Mitigation: Padding, Tor, dummy traffic
- Acceptance: Some metadata always leaks

---

## 10. Conclusion

### 10.1 Overall Risk Assessment

**Security Posture: MODERATE to HIGH RISK**

**Critical Vulnerabilities Identified**: 7
**High Vulnerabilities Identified**: 12
**Medium Vulnerabilities Identified**: 12
**Low Vulnerabilities Identified**: 7

**Total Threats Identified**: 38

**With ALL Mitigations Implemented**:
- Critical vulnerabilities: 0-1 (quantum threat only, 2030+ timeline)
- High vulnerabilities: 2-3 (cross-chain atomicity, privacy leaks)
- Medium vulnerabilities: 5-6
- Low vulnerabilities: 7

**Security Grade**:
- **MVP (minimal mitigations)**: C- (HIGH RISK, not production-ready)
- **With critical mitigations**: B (MEDIUM RISK, acceptable for testnet)
- **With all recommended mitigations**: B+ to A- (LOW-MEDIUM RISK, production-ready)

### 10.2 Go/No-Go Recommendation

**MVP Phase (Testnet)**: **CONDITIONAL GO**
- MUST implement all Priority 1 mitigations (TLS, watchtowers, nonce validation, rate limiting)
- MUST NOT use on mainnet until full security audit
- MUST limit testnet exposure to <$1,000 per channel

**Production Phase (Mainnet)**: **CONDITIONAL GO**
- MUST implement ALL Priority 1 + Priority 2 mitigations
- MUST complete third-party security audit ($140k-320k cost)
- MUST deploy 3+ independent watchtower services
- MUST implement comprehensive monitoring (Prometheus/Grafana/PagerDuty)
- MUST have incident response plan and on-call team

**IF Nillion latency >100ms for signing**: **NO-GO for per-packet signing**
- MUST use batching (100 packets per signature)
- Re-architect to reduce Nillion signing frequency
- Consider client-side signing for hot path, Nillion for settlement only

### 10.3 Key Takeaways

**Top 3 Security Priorities**:
1. **Watchtower Services (3+)**: Prevents channel fraud (CRITICAL)
2. **TLS 1.3 + Certificate Pinning**: Prevents MITM attacks (CRITICAL)
3. **Nonce-Based Replay Prevention**: Prevents double-spending (CRITICAL)

**Top 3 Architectural Improvements**:
1. **Batching**: Reduces Nillion signing from 1000/sec to 10/sec (100x reduction)
2. **Direct Channels**: Eliminates routing privacy leaks (no intermediaries)
3. **Single-Chain MVP**: Avoid cross-chain atomicity complexity (defer multi-chain)

**Top 3 Cost Drivers**:
1. **Security Audit**: $140k-320k (one-time)
2. **Watchtower Services**: $30-150/month (ongoing)
3. **DDoS Mitigation**: $200-2,000/month (ongoing)

**Estimated Security Budget**:
- **Year 1**: $180,000-460,000 (includes audit)
- **Year 2+**: $11,000-60,000/year (ongoing operational costs)

### 10.4 Final Recommendation

**This protocol is VIABLE with proper security implementation**, but requires:
- Significant security investment ($180k-460k Year 1)
- Expert security team (on-call 24/7 for incident response)
- Comprehensive monitoring infrastructure
- Third-party security audit before mainnet

**The combination of Nillion Private Compute + Lightning/Raiden payment channels + WebSocket protocol creates a UNIQUE threat surface** not present in traditional payment systems. The additional complexity must be justified by the value proposition (privacy-preserving key management).

**Alternative Architectures to Consider** (if security cost too high):
1. **Client-side signing + Nillion for key recovery only** (simpler, cheaper)
2. **Single-chain Lightning Network** (proven, mature, lower risk)
3. **Batched settlement only** (Nillion signs daily settlement, not per-packet)

**Security is the #1 risk for this protocol**. Budget accordingly.

---

## Appendix A: Threat Matrix (Full Table)

| ID | Threat | Category | Likelihood | Impact | Risk Score | Mitigations | Residual Risk |
|----|--------|----------|------------|--------|------------|-------------|---------------|
| 1.1 | Nillion MITM | Key Compromise | Medium | Critical | HIGH | TLS 1.3, cert pinning, mTLS | Medium |
| 1.2 | Nillion Node Compromise | Key Compromise | Low | Critical | MEDIUM | MPC threshold, geographic distribution | Low |
| 1.3 | Side-Channel on Nillion | Key Compromise | Low | Critical | MEDIUM | Constant-time crypto, noise injection | Low |
| 1.4 | Social Engineering | Key Compromise | Medium | High | MEDIUM | MFA, hardware wallets, rate limiting | Medium |
| 1.5 | Key Recovery Exploit | Key Compromise | Low | Critical | MEDIUM | Time-locked recovery, multi-sig | Low |
| 1.6 | Quantum Computing | Key Compromise | Very Low | Critical | LOW | Post-quantum crypto (future) | Very Low (2030+) |
| 2.1 | HTLC Jamming | Payment Channel | High | High | HIGH | Upfront fees, slot bucketing | Medium |
| 2.2 | Balance Probing | Payment Channel | High | Medium | MEDIUM | Random failures, route diversity | Medium |
| 2.3 | Stale State Fraud | Payment Channel | Low | Critical | MEDIUM | Watchtowers, penalty txs | Very Low |
| 2.4 | Replay Attacks | Payment Channel | Medium | High | MEDIUM | Strict nonce validation | Very Low |
| 2.5 | HTLC Expiry | Payment Channel | Low | High | LOW | Multi-node, NTP sync | Very Low |
| 2.6 | Channel Exhaustion | Payment Channel | High | Medium | MEDIUM | Auto-rebalancing, multiple channels | Low |
| 2.7 | Routing Attacks | Payment Channel | Medium | Medium | MEDIUM | Direct channels, reputation systems | Low |
| 2.8 | Cross-Chain Atomicity | Payment Channel | Medium | High | MEDIUM | Two-phase commit, monitoring | Medium |
| 2.9 | Fee Manipulation | Payment Channel | Low | Low | LOW | Rate limiting, fee bounds | Very Low |
| 2.10 | Network Fragmentation | Payment Channel | Low | Medium | LOW | Hub diversity, fallback routes | Low |
| 3.1 | WebSocket MITM | Protocol | Medium | Critical | HIGH | HSTS, cert pinning, TLS 1.3 | Low |
| 3.2 | WS Replay | Protocol | High | High | HIGH | Session binding, nonce validation | Very Low |
| 3.3 | Frame Injection | Protocol | Low | High | LOW | App-layer signatures | Very Low |
| 3.4 | DoS Flooding | Protocol | High | High | HIGH | Rate limiting, connection limits | Low |
| 3.5 | Session Hijacking | Protocol | Medium | Critical | HIGH | HttpOnly cookies, CSP, short-lived tokens | Low |
| 3.6 | Packet Injection | Protocol | Low | High | LOW | Sign payload hash | Very Low |
| 3.7 | Clock Skew | Protocol | Low | Medium | LOW | NTP sync, timestamp tolerance | Very Low |
| 4.1 | Partial Settlement | Cross-Chain | Medium | Critical | HIGH | Two-phase commit, retry logic | Medium |
| 4.2 | Race Conditions | Cross-Chain | Low | High | LOW | Settlement lock, state machine | Very Low |
| 4.3 | Bridge Vulnerabilities | Cross-Chain | Low | Critical | MEDIUM | Avoid bridges, use HTLCs | Medium |
| 4.4 | Blockchain Reorg | Cross-Chain | Low | High | LOW | Deep confirmations, monitoring | Very Low |
| 5.1 | Nillion Metadata | Privacy | Medium | Medium | MEDIUM | Encrypt requests, Tor | Low |
| 5.2 | Packet-Payment Correlation | Privacy | High | Low | LOW | Traffic padding, Tor | Medium |
| 5.3 | Blockchain Metadata | Privacy | High | High | MEDIUM | Address rotation, privacy coins | High |
| 5.4 | Routing Privacy | Privacy | High | Medium | MEDIUM | Direct channels, private channels | Medium |
| 5.5 | WebSocket Metadata | Privacy | High | Low | LOW | VPN/Tor, domain fronting | Medium |
| 5.6 | Timing Analysis | Privacy | Medium | Low | LOW | Random delays, dummy payments | Low |
| 6.1 | Key Exposure (Repeated) | High-Freq Signing | Low | Critical | MEDIUM | Ed25519, key rotation | Very Low |
| 6.2 | Nonce Management