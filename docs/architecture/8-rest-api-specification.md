# 8. REST API Specification

**OpenAPI 3.0 Specification** for provider discovery endpoints.

**Key Endpoints:**

1. **`GET /api/{resource}`** → 402 Payment Required
   - Returns x402 challenge + channel requirements
   - No authentication required

2. **`POST /api/{resource}/setup`** → Create channel
   - Requires `X-PAYMENT` header with x402 proof
   - Returns channelId, WebSocket endpoint, Bearer token

3. **`POST /api/{resource}/dispute`** → Report channel mismatch
   - Consumer-initiated dispute for incorrect channel parameters

4. **`GET /health`** → Health check
   - Returns service status, blockchain connectivity, x402 availability

**Response Format:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error Format:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "context": { ... }
  }
}
```

---
