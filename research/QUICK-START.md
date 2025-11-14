# Permamind Research Quick Start

## Getting Started (5 Minutes)

### 1. Understand the Project Structure

```
research/
├── README.md                    # ← Start here for overview
├── RESEARCH-PROGRESS.md         # ← Track overall progress
├── QUICK-START.md              # ← You are here
├── phase-1-critical/           # ← Week 1: CURRENT FOCUS
│   ├── PHASE-1-TRACKER.md     # ← Phase 1 task list
│   ├── findings/              # ← Structured answers
│   ├── examples/              # ← Working code
│   └── notes/                 # ← Raw research notes
├── deliverables/              # ← Final outputs
└── references/                # ← Source documentation
```

### 2. Current Priority: Phase 1 (Week 1)

**Goal:** Working payment-gated AO process with Apus integration

**Critical Questions to Answer:**
- Q1-Q5: Apus AI inference (SDK, models, pricing, limits, integration)
- Q8: Credit-Notice payment protocol
- Q15: Payment security patterns

### 3. Available Tools

You have access to these MCP servers (configured in `.mcp.json`):

- **permaweb-mcp** - Deploy AO processes, interact with Arweave
- **@permamind/mcp** - Search and publish skills
- **playwright** - Automate web research
- **ao/aoconnect/aolite skills** - AO development expertise

## Starting Phase 1 Research (Now)

### Step 1: Gather Apus Documentation

```bash
# Use the research structure
cd research/phase-1-critical/notes

# Create a research note
# File: 2025-11-13-apus-documentation-gathering.md
```

**Research Tasks:**
1. Find official Apus documentation site
2. Locate Apus SDK GitHub repository
3. Find API reference documentation
4. Identify example code repositories
5. Document in `references/official-docs.md`

### Step 2: Answer Q1 (Apus SDK API Surface)

**Process:**
1. Create notes file: `phase-1-critical/notes/2025-11-13-apus-sdk-exploration.md`
2. Explore documentation, capture raw findings
3. Create structured answer: `phase-1-critical/findings/Q01-apus-sdk-api.md`
   - Use `_TEMPLATE-FINDING.md` as template
4. Create code example: `phase-1-critical/examples/apus-basic-integration.lua`
5. Update `phase-1-critical/PHASE-1-TRACKER.md` with status

### Step 3: Deploy Test Process

**Using permaweb-mcp:**

```javascript
// Test if you can spawn a basic AO process
// Document the process in experiments/apus-tests/
```

**Document:**
- Process ID
- What worked
- What didn't work
- Performance observations
- Costs incurred

### Step 4: Update Progress Trackers

After each research session:

1. Update `phase-1-critical/PHASE-1-TRACKER.md`
   - Check off completed sub-tasks
   - Update status (Not Started → In Progress → Complete)
   - Add experiment results

2. Update `RESEARCH-PROGRESS.md`
   - Update question counts
   - Log key discoveries
   - Track velocity

## Research Workflow

### Daily Research Cycle

1. **Morning: Plan**
   - Review `PHASE-1-TRACKER.md`
   - Identify 1-2 questions to tackle
   - List information sources to check

2. **Midday: Research**
   - Create dated note file in `notes/`
   - Explore documentation, code, community
   - Capture findings in real-time
   - Test with hands-on experiments

3. **Evening: Synthesize**
   - Create structured finding file
   - Write working code example
   - Update trackers
   - Identify next day's priorities

### Research Best Practices

**Documentation Research:**
- Start with official docs (most reliable)
- Look for "Getting Started" and "API Reference" sections
- Check for dated content (prefer 2024-2025)
- Cross-reference multiple sources

**Code Research:**
- Search GitHub for real-world examples
- Look for deployed, production code
- Study error handling patterns
- Extract reusable patterns

**Hands-On Testing:**
- Deploy to testnet first
- Measure actual costs and performance
- Document everything
- Keep experiments small and focused

**Community Validation:**
- Join AO/Apus Discord/forums
- Ask specific questions
- Share findings for feedback
- Build relationships with experts

## Key Questions Answered?

After Phase 1, you should be able to confidently answer:

- ✅ How do I integrate Apus into an AO process?
- ✅ What will Apus inference cost per request?
- ✅ How do I implement payment gating securely?
- ✅ What are the performance limits?
- ✅ Can users estimate costs before execution?

If you can't answer these, Phase 1 isn't complete.

## Getting Help

**Stuck on research?**
1. Check `references/official-docs.md` for starting points
2. Review `_TEMPLATE-FINDING.md` for structure guidance
3. Ask in AO/Apus community channels
4. Document blockers in `PHASE-1-TRACKER.md`

**Need code examples?**
1. Use the 'ao' skill for AO fundamentals
2. Search `references/code-repositories.md`
3. Deploy minimal test to learn by doing

**Unsure what to prioritize?**
1. Follow the phase order: 1 → 2 → 3 → 4
2. Within a phase, tackle questions in numerical order
3. Focus on questions marked CRITICAL first

## Success Indicators

**Phase 1 is complete when:**
- [ ] All 7 questions (Q1-Q5, Q8, Q15) have finding files
- [ ] Working Apus integration code exists
- [ ] Working payment gating code exists
- [ ] Cost estimation is documented
- [ ] Security threats are identified
- [ ] Can deploy a payment-gated process with Apus

**Then proceed to Phase 2.**

## Next Steps After Setup

1. Open `phase-1-critical/PHASE-1-TRACKER.md`
2. Start with Q1: Apus SDK API Surface
3. Create your first research note
4. Begin gathering Apus documentation

Good luck! 🚀
