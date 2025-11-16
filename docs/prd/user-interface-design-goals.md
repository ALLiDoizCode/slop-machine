# User Interface Design Goals

## Overall UX Vision

The user experience should feel like **"Stripe for micropayments"** — invisible to end users during streaming, transparent and informative for developers. The wallet extension should mimic MetaMask's familiarity (one-time install, persistent background process) while the monitoring dashboard should provide Stripe-quality observability into Nillion operations. Core principle: **hide Nillion MPC complexity, surface payment value and privacy benefits**.

Target users tolerate 10-second handshake delay (one-time per session) because they understand it enables privacy-preserving payments. Developers get real-time visibility into Nillion voucher consumption, MPC signing events, and settlement triggers without needing to understand underlying cryptography.

## Key Interaction Paradigms

- **Auto-streaming payments:** Once wallet funded and channel open, payments flow automatically during API consumption with no per-transaction user confirmation (learned from Web Monetization success pattern)
- **Threshold-based notifications:** Users receive alerts at meaningful monetary milestones ($800 accumulated = 80% of $1000 threshold approaching) rather than technical events
- **Dashboard-driven debugging:** Developers troubleshoot payment issues via web UI showing Nillion-specific metrics (voucher depletion graphs, MPC latency spikes, Storage recovery events) not CLI logs
- **Progressive disclosure:** SDK hides Nillion by default (`new NillionMicropaymentServer({ ratePerPacket: '0.01' })`), exposes advanced MPC config only for power users

## Core Screens and Views

**Developer-Facing:**
1. **Monitoring Dashboard** — Real-time graphs of Nillion voucher usage, MPC signing latency, payment success/failure rates, settlement events with monetary thresholds
2. **SDK Documentation Site** — Interactive examples, TypeScript API reference, Nillion-specific troubleshooting guides
3. **Channel Management UI** — View open channels across all 3 chains (ETH/BTC/SOL), balance per channel, settlement history
4. **Cross-Chain Routing Visualizer** — See payment path from source to destination chain with fees and latency per hop

**End-User Facing:**
1. **Wallet Extension Popup** — Current balance across all chains, running total of session spend, top-up prompt when low
2. **Payment History** — Log of all micropayments with merchant, amount, timestamp, chain used
3. **Channel Funding Flow** — Guided wizard to open and fund payment channels (one-time setup, target <30 seconds)
4. **Privacy Indicator** — Visual badge showing "Nillion MPC Privacy Active" when vouchers being used vs "Standard Privacy" fallback

## Accessibility

**WCAG AA compliance** for dashboard and wallet extension:
- Keyboard navigation for all dashboard interactions (developers may use screen readers)
- Color contrast ratios ≥4.5:1 for text, 3:1 for UI components
- Screen reader support for payment alerts and balance updates
- No reliance on color alone for status indication (voucher depletion uses icons + text + color)

**Rationale:** Developer tools increasingly expected to be accessible (GitHub, Stripe meet WCAG AA). End-user wallet should match MetaMask accessibility standards.

## Branding

**Developer-Facing (SDK/Dashboard):**
- Clean, technical aesthetic similar to Stripe Dashboard or Vercel Analytics
- Nillion brand colors for MPC-specific UI elements (voucher graphs, privacy indicators)
- Monospace fonts for code examples and transaction IDs
- Dark mode support (developer preference, reduce eye strain during debugging)

**End-User Facing (Wallet):**
- Familiar Web3 wallet paradigm (MetaMask-inspired for adoption)
- Privacy-first visual language (locks, shields for Nillion MPC features)
- Minimal cognitive load (large numbers for balance, clear call-to-action buttons)

**No existing style guide provided** — will need design system definition in UX Expert phase.

## Target Device and Platforms

**Web Responsive** for all developer-facing interfaces:
- Desktop primary (1920×1080, 1366×768 common developer resolutions)
- Tablet secondary (iPad for dashboard monitoring on the go)
- Mobile tertiary (phone access to dashboard metrics acceptable but not optimized)

**Browser Extension** for end-user wallet:
- Chrome, Firefox, Safari, Edge (95%+ browser coverage)
- Responsive to extension popup size constraints (340×600px typical)

**No mobile apps (iOS/Android) in MVP scope** — deferred to Phase 2 per Project Brief constraints.

---
