# Testing Strategy

## Test Organization

**Frontend Tests:**
- `apps/dashboard/tests/components/` - Component tests
- `apps/dashboard/tests/integration/` - Integration tests
- Vitest + React Testing Library

**Backend Tests:**
- `apps/server/tests/unit/` - Unit tests
- `apps/server/tests/integration/` - Integration tests with Testcontainers
- Vitest

**E2E Testing:**
- Manual flows (MVP)
- Playwright (deferred to production)

---
