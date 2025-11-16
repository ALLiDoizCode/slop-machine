# Frontend Architecture

## Component Organization

```
apps/dashboard/src/
├── app/                          # Next.js App Router
│   ├── layout.tsx
│   ├── page.tsx
│   ├── channels/
│   ├── routing/
│   ├── transactions/
│   ├── performance/
│   └── api/                      # API routes (BFF)
├── components/
│   ├── ui/                       # shadcn/ui components
│   └── dashboard/                # Domain-specific components
├── lib/
├── hooks/
└── stores/                       # Zustand stores
```

## State Management

- **Zustand** for real-time WebSocket data (performance metrics, channel updates)
- **TanStack Query** for REST API data (caching, refetching)
- **Server Components** for initial data (SSR performance)

---
