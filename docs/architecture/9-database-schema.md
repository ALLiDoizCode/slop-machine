# 9. Database Schema

**Phase 1:** In-memory storage (Map/Set data structures)

**Rationale:**
- Testnet demos are short-lived (minutes to hours)
- Blockchain is source of truth for channels
- Simplifies Docker deployment (no database container)
- Sufficient for protocol validation

**Data Structures:**
- `discoverySessions`: Map<discoveryId, DiscoverySession> (5min TTL)
- `activeSessions`: Map<sessionId, Session> (cleanup on WebSocket close)
- `channelCache`: Map<channelId, Channel> (60s TTL, refreshed from blockchain)
- `paymentStates`: Map<channelId, PaymentState[]> (until channel settled)

**Phase 2+ (Production):** PostgreSQL schema for persistent channel state, session recovery, historical analytics, audit trail

---
