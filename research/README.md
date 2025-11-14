# Permamind Research Organization

This directory contains systematic research findings for the Permamind project, organized by development phase.

## Directory Structure

```
research/
├── phase-1-critical/          # Week 1: Apus + Payment Gating (CRITICAL PATH)
│   ├── findings/             # Structured answers to research questions
│   ├── examples/             # Working code examples
│   └── notes/                # Raw research notes and explorations
│
├── phase-2-core/             # Week 2: AO Development + Arweave Storage
│   ├── findings/
│   ├── examples/
│   └── notes/
│
├── phase-3-economics/        # Week 3: Economic Modeling + SDK Design
│   ├── findings/
│   ├── examples/
│   └── notes/
│
├── phase-4-advanced/         # Ongoing: Ecosystem & Advanced Patterns
│   ├── findings/
│   ├── examples/
│   └── notes/
│
├── deliverables/             # Final research outputs
│   ├── executive-summary.md
│   ├── apus-integration-guide.md
│   ├── ao-process-handbook.md
│   ├── payment-implementation.md
│   ├── arweave-storage-strategy.md
│   ├── economic-model-analysis.md
│   ├── sdk-architecture-spec.md
│   └── risk-assessment.md
│
├── references/               # Source documentation and links
│   ├── official-docs.md
│   ├── code-repositories.md
│   └── community-resources.md
│
└── experiments/              # Hands-on testing and prototypes
    ├── apus-tests/
    ├── payment-prototypes/
    └── process-templates/
```

## Research Workflow

### Phase-by-Phase Approach

Each phase follows this workflow:

1. **Notes** - Capture raw findings from documentation, code review, and testing
2. **Findings** - Synthesize notes into structured answers to research questions
3. **Examples** - Create working code demonstrating key concepts
4. **Deliverables** - Compile polished outputs for decision-making

### File Naming Conventions

**Findings Files:**
- `Q{number}-{topic}.md` - Answer to specific research question
- Example: `Q01-apus-sdk-api.md`, `Q08-credit-notice-protocol.md`

**Example Files:**
- `{topic}-example.lua` or `{topic}-example.js`
- Example: `apus-integration-example.lua`, `payment-gating-example.lua`

**Notes Files:**
- `{YYYY-MM-DD}-{topic}.md` - Date-stamped exploration notes
- Example: `2025-11-13-apus-sdk-exploration.md`

## Current Phase: Phase 1 (Critical Path)

### Priority Research Questions

**Apus AI Inference (Q1-Q5):**
- [ ] Q1: Complete Apus SDK API surface
- [ ] Q2: Available AI models and capabilities
- [ ] Q3: Apus pricing and cost structure
- [ ] Q4: Performance limits and constraints
- [ ] Q5: Integration with AO message passing

**Payment Security (Q8, Q15):**
- [ ] Q8: Credit-Notice/Debit-Notice protocol implementation
- [ ] Q15: Security patterns for payment gating

### Success Criteria for Phase 1

✅ Working payment-gated AO process with Apus integration
✅ Cost estimation capability for AI inference calls
✅ Security analysis of payment patterns
✅ Documented performance limits and constraints

## Research Tools & MCP Servers

Available tools in `.mcp.json`:
- **@permamind/mcp** - Skill publishing and registry search
- **permaweb-mcp** - AO process interaction, Arweave uploads, ArNS management
- **playwright** - Browser automation for documentation research
- **shadcn-ui** - UI components (if needed for frontend)

## Next Steps

1. Begin Phase 1 research with Apus documentation
2. Deploy test AO process with payment gating
3. Document findings in `phase-1-critical/findings/`
4. Create working examples in `phase-1-critical/examples/`
5. Compile into deliverable: `deliverables/apus-integration-guide.md`

## Research Principles

- **Documentation First** - Start with official docs, validate with code
- **Hands-On Validation** - Test claims with real deployments
- **Multiple Sources** - Cross-reference findings
- **Recency Priority** - Favor 2024-2025 information
- **Completeness** - Full working examples, not snippets
