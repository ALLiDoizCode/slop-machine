# 1. Introduction

This document outlines the overall project architecture for **BIMP Protocol Implementation**, including backend systems, smart contracts, and SDK development. Its primary goal is to serve as the guiding architectural blueprint for AI-driven development, ensuring consistency and adherence to chosen patterns and technologies.

**Relationship to Frontend Architecture:**
This project is **backend-focused** with no significant user interface requirements. The deliverables include:
- Reference implementation (Node.js peer for consumers and providers)
- Smart contract deployment to Ethereum L2 testnets
- Multi-language SDKs (TypeScript, Python, Go, Rust)
- Demo applications (programmatic, not UI-based)

Future dashboard/monitoring UIs would require a separate Frontend Architecture Document.

## Starter Template

**Decision:** Use **Turborepo** for monorepo orchestration

**Rationale:**
- Best for monorepos with TypeScript-heavy workloads
- Built-in caching and task orchestration
- Perfect for coordinated SDK development across multiple packages
- Excellent CI/CD integration with remote caching support

For smart contracts, we use **Hardhat** (as specified in PRD) with TypeScript initialization.

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-18 | 1.0.0 | Initial architecture document | Winston (Architect) |

---
