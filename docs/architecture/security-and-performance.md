# Security and Performance

## Security Requirements

**Frontend:**
- CSP Headers: `script-src 'self'`
- XSS Prevention: React escaping
- Secure Storage: JWT in httpOnly cookies

**Backend:**
- Input Validation: Zod schemas
- Rate Limiting: 100 req/min per IP
- CORS: Whitelist dashboard domain

**Authentication:**
- Token Storage: httpOnly secure cookies
- Session: 24-hour expiry
- Wallet-based auth (no passwords)

## Performance Optimization

**Frontend:**
- Bundle Size: <200KB gzipped
- Loading: Code splitting, lazy load charts
- Caching: Vercel edge cache + TanStack Query

**Backend:**
- Response Time: <100ms p95 (payments), <200ms (API)
- Database: Connection pooling, partial indexes
- Caching: Redis 99%+ hit rate on vouchers

---
