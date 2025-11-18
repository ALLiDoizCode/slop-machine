# 12. Error Handling Strategy

**Error Model:** Exception-based with structured error types

**Error Hierarchy:**
```typescript
BIMPError (base)
├── DiscoveryError
├── PaymentVerificationError
├── BlockchainError
├── ChannelError
├── SignatureError
├── ProtocolError
└── StateValidationError
```

**Patterns:**

1. **Retry with Exponential Backoff** - 3 retries, 1s/2s/4s delays for transient failures
2. **Circuit Breaker** - Opens after 5 consecutive failures, 60s timeout
3. **Timeout on All Async Operations** - Prevents hanging operations
4. **Structured JSON Logging** - Pino with correlation IDs
5. **Idempotency** - Track processed x402 payment IDs to prevent duplicate channels

**Logging Standards:**
- **Levels:** trace, debug, info, warn, error, fatal
- **Format:** JSON structured logs
- **Context:** Correlation ID, channelId, operation name
- **Never log:** Secrets, private keys, signatures, JWTs

**Error Translation:**
- HTTP Layer: Map to status codes (400, 402, 500)
- WebSocket Layer: Close codes (4010-4099 client errors, 4500-4599 server errors)
- User-facing messages: Translate error codes to actionable messages

---
