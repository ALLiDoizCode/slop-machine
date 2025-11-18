# 15. Security

**Security Principles:**
1. **Defense in Depth** - Multiple security layers
2. **Fail-Secure** - Errors default to rejecting transactions
3. **Least Privilege** - Minimum required permissions
4. **Zero Trust** - Verify all inputs
5. **Cryptographic Integrity** - EIP-712 signatures

**Key Security Measures:**

**Input Validation:**
- Zod schemas for all API inputs
- Whitelist approach (not blacklist)
- Validate at API boundary before business logic

**Authentication & Authorization:**
- JWT Bearer tokens (5min expiry)
- Token verification on every WebSocket message
- Never trust client-provided identifiers

**Secrets Management:**
- Development: `.env` files (git-ignored)
- Production: AWS Secrets Manager / HashiCorp Vault (future)
- Validate required secrets on startup
- NEVER log secrets or include in error messages

**API Security:**
- Rate limiting (express-rate-limit)
- CORS policy (whitelist origins)
- Security headers (helmet)
- HTTPS enforcement in production
- TLS 1.3+ only

**Data Protection:**
- Encryption in transit: TLS 1.3+
- No PII storage (Ethereum addresses are public)
- Sanitize logs (partially redact IPs, limit user agent)

**Smart Contract Security:**
- Reentrancy protection (OpenZeppelin ReentrancyGuard)
- Checks-Effects-Interactions pattern
- Slither static analysis
- Professional audit before mainnet
- Gas limit checks on loops
- Access control on all functions
- Signature verification for all state changes

**Dependency Security:**
- npm audit on every CI run
- Dependabot for automated updates
- Auto-merge security patches
- Monthly dependency review

**Critical Requirements:**
- ✅ NEVER log secrets, signatures, or private keys
- ✅ NEVER hardcode secrets
- ✅ ALWAYS validate inputs
- ✅ ALWAYS use HTTPS in production
- ✅ ALWAYS verify signatures before processing payments
- ✅ ALWAYS use EIP-712 for payment states

---
