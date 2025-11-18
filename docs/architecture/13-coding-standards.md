# 13. Coding Standards

**⚠️ MANDATORY for AI Developers**

**Core Standards:**
- **Languages:** TypeScript 5.3.3 strict mode, Node.js 20.11.0 LTS
- **Style:** ESLint + Prettier (ZERO warnings in CI)
- **Testing:** Vitest, 90%+ coverage for protocol-core and contracts
- **Imports:** Organize in 3 groups (external, @bimp/*, relative)

**Critical Rules (MUST FOLLOW):**

1. **No `console.log` in Production Code** - Use `logger` instead
2. **All API Responses Use Standard Format** - Consistent structure
3. **Never Direct Database Queries Outside Repositories** - Repository pattern
4. **All Blockchain Interactions Use Retry Logic** - Wrap in `withRetry()`
5. **All User Inputs Must Be Validated** - Validate at API boundary
6. **Secrets Must NEVER Be Hardcoded** - Environment variables only
7. **BigInt for All Blockchain Amounts** - JavaScript number loses precision
8. **Async Functions Must Handle Errors** - Try-catch or explicit error handling
9. **No Mutable Exports** - Encapsulate in classes
10. **EIP-712 Signatures Only for Payment States** - Never raw ECDSA

**Naming Conventions:**
- Files: kebab-case (`channel-manager.ts`)
- Classes: PascalCase (`ChannelManager`)
- Functions: camelCase (`createChannel`)
- Constants: UPPER_SNAKE_CASE (`DEFAULT_GAS_LIMIT`)

**Documentation:**
- JSDoc for all public APIs
- Inline comments only for complex logic (explain WHY, not WHAT)

---
