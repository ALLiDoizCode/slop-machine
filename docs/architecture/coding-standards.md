# Coding Standards

## Critical Fullstack Rules

- **Type Sharing:** Always define types in `packages/shared`
- **API Calls:** Use service layer, not direct fetch
- **Environment Variables:** Access via config objects only
- **Error Handling:** Use standard error handler
- **State Updates:** Never mutate state directly
- **bigint Serialization:** Always serialize as string for JSON
- **Database Transactions:** All payment/channel updates in transactions

## Naming Conventions

| Element | Frontend | Backend | Example |
|---------|----------|---------|---------|
| Components | PascalCase | - | `UserProfile.tsx` |
| Hooks | camelCase with 'use' | - | `useAuth.ts` |
| API Routes | - | kebab-case | `/api/user-profile` |
| Database Tables | - | snake_case | `user_profiles` |

---
