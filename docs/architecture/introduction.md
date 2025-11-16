# Introduction

This document outlines the complete fullstack architecture for **Nillion-Powered Web-Native Micropayment Protocol**, including backend systems, frontend implementation, and their integration. It serves as the single source of truth for AI-driven development, ensuring consistency across the entire technology stack.

This unified approach combines what would traditionally be separate backend and frontend architecture documents, streamlining the development process for this modern fullstack application where these concerns are tightly integrated through shared TypeScript types, Protocol Buffer schemas, and unified Nillion MPC signatures.

## Starter Template or Existing Project

**Template:** Turborepo Official Starter (`npx create-turbo@latest`)

**Rationale:**

This project is based on the **Turborepo official starter** with Next.js and TypeScript. This choice was made because:

1. **Monorepo Requirement**: The PRD specifies tight coordination between 6+ packages (client-sdk, server-sdk, protocol, nillion-adapter, demo app, dashboard app, docs site). Turborepo provides optimal build caching and task orchestration.

2. **TypeScript Ecosystem**: Full TypeScript support with strict mode aligns with the PRD's requirement for TypeScript-first development with Node.js 18+ WebCrypto API support.

3. **Build Performance**: With Epic 1-5 requiring parallel testing across 3 blockchain integrations (Ethereum, Bitcoin, Solana), Turborepo's intelligent caching reduces CI/CD times by 6-10×.

4. **Package Manager Alignment**: Native pnpm workspace support matches the technical assumptions specifying pnpm as the package manager.

5. **Next.js 14 Integration**: Official Turborepo starter includes Next.js configuration pre-optimized for monorepo builds, supporting the dashboard's App Router and React Server Components requirements.

**Architectural Decisions Already Made by Template:**

- **Workspace structure**: `apps/*` for deployable applications, `packages/*` for shared libraries
- **Build tool**: Turborepo for orchestration, tsup/tsc for package compilation, Next.js for app building
- **TypeScript configuration**: Shared tsconfig.json with project-specific extensions
- **Shared tooling**: ESLint, TypeScript configs centralized in `packages/config-*`

**What Can Be Modified:**

- Package contents and internal architecture (fully customizable)
- Database schema and deployment targets (template includes no backend services)
- Testing framework (starter is framework-agnostic)
- Additional packages (Nillion adapter, Protocol Buffer definitions, blockchain integrations)

**What Must Be Retained:**

- Turborepo configuration structure (required for build orchestration)
- pnpm workspace definition (enables shared dependencies)
- Package naming conventions (workspace dependencies use `workspace:*` protocol)

**Template Documentation:** https://turbo.build/repo/docs/getting-started/create-new

---

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|---------|
| 2025-11-16 | 1.0 | Initial architecture document created | Winston (Architect Agent) |

---
