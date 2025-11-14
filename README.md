# Permamind

[![CI](https://github.com/ALLiDoizCode/slop-machine/actions/workflows/ci.yaml/badge.svg)](https://github.com/ALLiDoizCode/slop-machine/actions/workflows/ci.yaml)

**Decentralized AI Marketplace on AO Network**

Permamind is a payment-gated AI marketplace built on the AO network, enabling developers to monetize AI skills and compose complex AI workflows with automatic royalty distribution.

## Architecture

Permamind consists of three main components:

- **Permamind SDK (Lua)**: A library for AO processes that provides payment gating, skill loading, and AI inference integration. Implements the CEI (Checks-Effects-Interactions) pattern for secure payment handling.

- **Registry Process (AO Smart Contract)**: A decentralized marketplace for skill discovery, metrics tracking, and dependency resolution. Runs as an AO process with public query handlers.

- **CLI Tool (TypeScript)**: Developer tooling for deploying processes, publishing skills, and interacting with the marketplace. Built with Node.js for cross-platform support.

## Monorepo Structure

```
permamind/
├── sdk/                      # Permamind SDK (Lua) - Payment gating & skill loading
├── registry/                 # Registry Process (Lua) - Marketplace discovery
├── cli/                      # CLI Tool (TypeScript) - Developer tooling
├── examples/                 # Example processes and skills
│   ├── skills/              # Example skill markdown files
│   └── hello-world/         # Simple payment-gated example
├── tests/                    # Unit, integration, and load tests
│   ├── unit/                # SDK unit tests (aolite)
│   ├── integration/         # Integration tests (aolite)
│   └── load/                # Performance and load tests
├── scripts/                  # Build and deployment automation
├── docs/                     # Documentation
│   ├── prd/                 # Product requirements
│   └── architecture/        # Technical architecture
└── .github/workflows/        # CI/CD pipelines
```

## Quick Start

### Prerequisites

- **Node.js** 18+ LTS
- **npm** 9+
- **Lua** 5.3
- **Git**

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd permamind

# Install dependencies
npm install
```

### Testing

See `/tests/README.md` for detailed testing instructions.

Testing pyramid:
- 65% unit tests (aolite for Lua SDK)
- 30% integration tests (aolite simulation)
- 5% E2E tests (manual testnet validation)

## Documentation

- **Product Requirements**: See `/docs/prd/` for detailed product specifications
- **Technical Architecture**: See `/docs/architecture/` for system design and component specifications
- **Development Workflow**: See `/docs/architecture/development-workflow.md` for git conventions and deployment processes

## Development Workflow

Permamind uses a monorepo structure with npm workspaces:

- **SDK Development**: Lua files in `/sdk` directory, tested with aolite
- **Registry Development**: Lua files in `/registry` directory, deployed with aos CLI
- **CLI Development**: TypeScript in `/cli` directory, built with tsc

## Contributing

Contributions welcome! Please follow the coding standards in `/docs/architecture/coding-standards.md`.

Key development principles:
- CEI pattern for all payment handlers
- Input validation before state changes
- Comprehensive testing (65/30/5 pyramid)
- Message ID tracking for replay prevention

## License

MIT (pending confirmation)

---

**Status**: MVP Development (Epic 1 - Foundation & Payment Gating SDK)
