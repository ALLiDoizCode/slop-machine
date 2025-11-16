# Backend Architecture

## Service Architecture

```
apps/server/src/
├── index.ts
├── config/
├── websocket/
│   ├── server.ts
│   └── handlers/
├── channels/
│   ├── channel-manager.ts
│   └── channel-repository.ts
├── nillion/
│   ├── compute.ts
│   ├── storage.ts
│   └── mock/
├── settlement/
├── blockchains/
│   ├── ethereum/
│   ├── bitcoin/
│   └── solana/
├── monitoring/
└── api/
    └── routes/
```

## Authentication and Authorization

- **SIWE (Sign-In with Ethereum)** for WebSocket authentication
- **JWT tokens** for REST API authentication
- **Wallet signatures** for user verification (no passwords)

---
