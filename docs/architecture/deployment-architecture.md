# Deployment Architecture

## Deployment Strategy

**Frontend:**
- **Platform:** Vercel
- **Build Command:** `cd apps/dashboard && pnpm run build`
- **Output Directory:** `.next`
- **CDN:** Vercel Edge Network

**Backend:**
- **Platform:** Railway (MVP), AWS ECS (Production)
- **Build Command:** `cd apps/server && pnpm run build`
- **Deployment:** Docker container

## Environments

| Environment | Frontend URL | Backend URL | Purpose |
|-------------|--------------|-------------|---------|
| Development | localhost:3000 | localhost:8080 | Local dev |
| Staging | staging-dashboard.* | staging-api.* | Pre-prod testing |
| Production | dashboard.* | api.* | Live environment |

---
