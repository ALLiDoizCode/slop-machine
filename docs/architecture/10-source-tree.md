# 10. Source Tree

```
bimp-protocol/                          # Monorepo root
├── apps/                               # Deployable applications
│   ├── reference-provider/             # Provider implementation
│   └── reference-consumer/             # Consumer implementation
├── packages/                           # Shared packages
│   ├── protocol-core/                  # Core BIMP protocol
│   ├── sdk-typescript/                 # TypeScript SDK (npm)
│   ├── sdk-python/                     # Python SDK (PyPI)
│   ├── sdk-go/                         # Go SDK (Go modules)
│   ├── sdk-rust/                       # Rust SDK (Cargo)
│   └── contracts/                      # Smart contracts
├── demos/                              # Demo applications
│   ├── iot-marketplace/                # IoT sensor data marketplace
│   ├── ai-agent-trading/               # AI agent service trading
│   └── api-monetization/               # API monetization demo
├── docs/                               # Documentation
│   ├── architecture.md                 # This document
│   ├── prd.md                          # Product requirements
│   └── protocol-spec.md                # BIMP protocol specification
├── scripts/                            # Monorepo scripts
├── tools/                              # Development tools
├── package.json                        # Root package.json
├── pnpm-workspace.yaml                 # pnpm workspace config
├── turbo.json                          # Turborepo configuration
└── tsconfig.json                       # Root TypeScript config
```

**Package Naming:** `@bimp/protocol-core`, `@bimp/sdk-typescript`, `@bimp/contracts`

---
