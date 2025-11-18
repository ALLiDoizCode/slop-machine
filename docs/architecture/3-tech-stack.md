# 3. Tech Stack

## Cloud Infrastructure

**Provider:** Not applicable for Phase 1 (testnet-only reference implementation)

**Key Services:**
- **Blockchain RPC:** Alchemy (primary), Infura (fallback)
- **Networks:** Base Sepolia (testnet), Optimism Sepolia (testnet)
- **CI/CD:** GitHub Actions
- **Package Registries:** npm, PyPI, crates.io, Go modules

## Technology Stack Table

| **Category** | **Technology** | **Version** | **Purpose** | **Rationale** |
|--------------|----------------|-------------|-------------|---------------|
| **Monorepo** | Turborepo | 1.11.x | Monorepo orchestration | Fast builds, task caching, perfect for multi-SDK coordination |
| **Package Manager** | pnpm | 8.x | Node.js package management | Efficient disk usage, faster than npm, workspace support |
| **Runtime** | Node.js | 20.11.0 LTS | JavaScript runtime | PRD requirement, LTS stability, excellent ecosystem |
| **Language (Primary)** | TypeScript | 5.3.3 | Primary development language | PRD requirement, strong typing, excellent tooling |
| **Backend Framework** | Express.js | 4.18.2 | HTTP server for discovery | PRD requirement, minimal, widely understood |
| **WebSocket Library** | ws | 8.14.2 | WebSocket streaming | PRD requirement, low-level control, performant |
| **Blockchain SDK** | ethers.js | 6.9.0 | Ethereum interaction | PRD requirement, channel creation, signature verification |
| **x402 SDK** | @coinbase/x402 | latest | x402 payment protocol | Discovery fee payment, spam protection |
| **Testing Framework** | Vitest | 1.0.x | Unit + integration tests | PRD requirement, fast, Vite-powered, Jest-compatible |
| **Linting** | ESLint + Prettier | 8.x + 3.x | Code quality | PRD requirement, consistent style |
| **Build Tool** | tsup | 8.x | TypeScript bundling | Fast esbuild-based bundler for SDKs |
| **Smart Contract Language** | Solidity | 0.8.24 | Smart contract development | PRD requirement, latest stable, audit-friendly |
| **Smart Contract Framework** | Hardhat | 2.19.x | Contract dev/test/deploy | PRD requirement, TypeScript support, excellent tooling |
| **Logging** | pino | 8.x | Structured logging | Fast, JSON structured logs, production-ready |
| **Container** | Docker | 24.x | Containerization | Reproducible builds, deployment |

**Python SDK:** Python 3.11+, Poetry 1.7.x, web3.py 6.x, pytest 7.x
**Go SDK:** Go 1.21+, go-ethereum 1.13.x, gorilla/websocket 1.5.x
**Rust SDK:** Rust 1.75+, ethers-rs 2.0.x, tokio-tungstenite 0.20.x, tokio 1.35.x

---
