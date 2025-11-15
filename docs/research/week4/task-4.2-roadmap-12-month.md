# Task 4.2: 12-Month Roadmap - Nillion M2M AI Marketplace

**Research Date:** November 15, 2025
**Status:** Complete - Detailed Execution Plan
**Researcher:** Research Phase - Week 4

---

## Executive Summary

This roadmap provides a detailed 12-month execution plan for launching the Nillion-based M2M AI marketplace, focusing on **Healthcare AI** as the primary market with foundation for future expansion into Personal AI, Developer Tools, and Enterprise B2B.

**12-Month Goals:**
- ✅ Launch Healthcare AI product (MVP)
- ✅ Acquire 50-200 hospital customers
- ✅ Achieve $100K-500K MRR
- ✅ Publish clinical validation study
- ✅ Build foundation for Personal AI launch (Month 13+)

**Team: 6 FTEs at peak** (4 engineers, 1 medical advisor, 1 product)
**Budget: $1.2M** ($100K/month average)
**Milestones: 12 key milestones** (monthly cadence)

---

## Table of Contents

1. [Q1 (Months 1-3): Foundation & MVP](#q1-months-1-3-foundation--mvp)
2. [Q2 (Months 4-6): Pilot & Validation](#q2-months-4-6-pilot--validation)
3. [Q3 (Months 7-9): Scale & Growth](#q3-months-7-9-scale--growth)
4. [Q4 (Months 10-12): Optimization & Expansion](#q4-months-10-12-optimization--expansion)
5. [Team & Budget](#team--budget)
6. [Success Metrics](#success-metrics)
7. [Risk Mitigation](#risk-mitigation)

---

## Q1 (Months 1-3): Foundation & MVP

### Month 1: Architecture & Infrastructure

**Objectives:**
1. Deploy smart contracts to Arbitrum testnet
2. Build nilCC service MVP (Architecture A or B)
3. Validate Nillion pricing and performance
4. Begin clinical validation study design

---

**Week 1-2: Smart Contract Development**

**Deliverables:**
- [ ] PermamindGate.sol implementation (Solidity)
- [ ] Unit tests (100% coverage critical functions)
- [ ] Deploy to Arbitrum Sepolia testnet
- [ ] Frontend for credit management (web app)

**Team:** 2 backend engineers
**Budget:** $30K (eng salary)

**Code Estimate:**
```solidity
// PermamindGate.sol (~500 lines)
contract PermamindGate {
    mapping(address => mapping(address => uint256)) public creditBalance;
    mapping(address => mapping(address => mapping(address => bool))) public authorized;
    mapping(address => mapping(address => uint256)) public lastNonce;

    function buyCredits(address service) external payable { }
    function authorizeExecutor(address executor, address service) external { }
    function consumeCredits(...) external { }
    function batchConsumeCredits(...) external { }  // Phase 2 optimization
    function withdrawCredits(address service, uint256 amount) external { }
}
```

---

**Week 3-4: Nillion Service Development**

**Deliverables:**
- [ ] Docker container with AI model (Llama 3 70B medical-tuned)
- [ ] Payment verification logic (Architecture A: RPC OR Architecture B: Oracle)
- [ ] DICOM image processing pipeline
- [ ] Deploy to Nillion testnet (nilCC)
- [ ] End-to-end test (Arbitrum testnet → Nillion testnet)

**Team:** 2 backend engineers
**Budget:** $30K

**Stack:**
```typescript
// service.ts (~1,000 lines)
import express from 'express';
import { ethers } from 'ethers';
import { loadMedicalModel, analyzeDICOM } from './ai-engine';

app.post('/diagnose', async (req, res) => {
    // 1. Verify signature
    // 2. Check credits (RPC or oracle proof)
    // 3. Consume credits
    // 4. Analyze medical image (TEE-isolated)
    // 5. Return diagnosis with confidence scores
});
```

---

**Month 1 Milestones:**
- ✅ Smart contract deployed (Arbitrum testnet)
- ✅ nilCC service running (Nillion testnet)
- ✅ End-to-end payment → execution flow working
- ✅ Empirical cost data ($X per execution measured)
- ✅ Latency measured (X.Xs P95)

**Success Criteria:**
- Payment flow works (no critical bugs)
- Actual costs validate estimates (within 2x)
- Latency <2.5s P95 (acceptable)

---

### Month 2: Clinical Validation & Security

**Objectives:**
1. Design clinical validation study
2. Security audit of smart contracts
3. Build HIPAA compliance documentation
4. Recruit academic medical center partner

---

**Week 1-2: Clinical Study Design**

**Deliverables:**
- [ ] Study protocol (retrospective analysis)
- [ ] Dataset selection (ChestX-ray14, MIMIC-CXR, or equivalent)
- [ ] IRB application (if required)
- [ ] Academic partner agreement (1-2 medical centers)

**Approach:**
1. **Retrospective study** (faster than prospective)
2. **Public datasets** (no patient recruitment needed)
3. **Sensitivity/specificity benchmarks** vs. radiologist ground truth
4. **Target journal:** PLOS Digital Health or Nature Digital Medicine

**Team:** 1 medical advisor + 1 engineer (data science)
**Budget:** $20K (advisor consulting, data access, compute)

---

**Week 3-4: Security Audit**

**Deliverables:**
- [ ] Smart contract audit (external firm)
- [ ] Penetration testing (TEE service)
- [ ] Security documentation
- [ ] Bug fixes from audit

**Audit Scope:**
- PermamindGate.sol (all functions)
- Payment flow (signature verification, nonce handling)
- Common vulnerabilities (reentrancy, overflow, front-running)

**Auditor:**
- OpenZeppelin (preferred) OR
- Trail of Bits OR
- Consensys Diligence

**Team:** 1 engineer (implement fixes)
**Budget:** $30K ($25K audit + $5K fixes)

---

**Month 2 Milestones:**
- ✅ Clinical study designed (protocol ready)
- ✅ Academic partner recruited (signed agreement)
- ✅ Security audit complete (no critical issues)
- ✅ HIPAA documentation draft

**Success Criteria:**
- Study feasible (data accessible, timeline 3-6 months)
- No critical security vulnerabilities found
- Academic partner committed (signed LOI or contract)

---

### Month 3: MVP Launch Prep

**Objectives:**
1. Deploy to mainnet (Arbitrum + Nillion)
2. Build hospital onboarding flow
3. Create marketing materials
4. Recruit first pilot customers (2-3 hospitals)

---

**Week 1-2: Mainnet Deployment**

**Deliverables:**
- [ ] Deploy PermamindGate to Arbitrum One (mainnet)
- [ ] Deploy service to Nillion mainnet (nilCC)
- [ ] Smoke tests on mainnet
- [ ] Monitoring and alerting setup

**Infrastructure:**
- Arbitrum RPC (Alchemy or Infura)
- Nillion nilCC API key
- Monitoring (Datadog, Sentry)
- Uptime tracking (99.5% SLA target)

**Team:** 2 engineers
**Budget:** $30K (eng) + $5K (infrastructure)

---

**Week 3-4: Go-to-Market Prep**

**Deliverables:**
- [ ] Hospital onboarding docs (HIPAA BAA template, integration guide)
- [ ] Marketing website (landing page, product demo)
- [ ] Outreach to 20-30 hospitals (target 5 pilots)
- [ ] Pricing finalized ($10/diagnosis confirmed)

**Marketing Materials:**
- Landing page: "Private AI Diagnostics - HIPAA Compliant, $10/case"
- Demo video (2 min): How it works, privacy guarantees
- White paper: TEE architecture for healthcare AI
- Case for privacy: $11M avg breach cost

**Outreach:**
1. Academic medical centers (Johns Hopkins, Mayo, Stanford)
2. Small-medium hospitals (100-400 beds)
3. Telemedicine platforms (Teladoc, Amwell)

**Team:** 1 product manager + 1 engineer (frontend)
**Budget:** $25K (eng + PM) + $10K (website, design)

---

**Month 3 Milestones:**
- ✅ Mainnet live (Arbitrum + Nillion)
- ✅ 2-3 pilot hospitals recruited
- ✅ Marketing materials ready
- ✅ Onboarding process validated (dry run with friendly user)

**Success Criteria:**
- Mainnet stable (no downtime)
- ≥2 signed pilot agreements
- Website converts ≥5% visitors to signup

---

**Q1 Budget:** $185K
**Q1 Team:** 3-4 FTEs (2 backend, 1 full-stack, 1 medical advisor PT)

---

## Q2 (Months 4-6): Pilot & Validation

### Month 4: Pilot Execution

**Objectives:**
1. Onboard pilot customers (2-3 hospitals)
2. Process first 100-500 diagnoses
3. Collect feedback and iterate
4. Begin clinical validation study data collection

---

**Week 1-2: Customer Onboarding**

**Deliverables:**
- [ ] Hospital 1 onboarded (HIPAA BAA signed, integration complete)
- [ ] Hospital 2 onboarded
- [ ] Hospital 3 onboarded (if 3rd pilot secured)
- [ ] Training sessions with radiologists

**Onboarding Checklist (Per Hospital):**
1. Legal: Execute HIPAA BAA
2. Technical: DICOM integration (manual upload or API)
3. Training: 1-hour session with 3-5 radiologists
4. Support: Slack channel or email support
5. Monitoring: Track usage, errors, feedback

**Team:** 1 engineer (integration support), 1 medical advisor (training)
**Budget:** $25K (eng + advisor)

---

**Week 3-4: Pilot Execution & Data Collection**

**Deliverables:**
- [ ] 100-500 diagnoses processed
- [ ] User feedback collected (NPS survey after each diagnosis)
- [ ] Clinical data for validation study
- [ ] Bug fixes and improvements

**Metrics to Track:**
- Diagnostic accuracy (vs. radiologist ground truth)
- Time savings (minutes saved per diagnosis)
- Errors/bugs (should be <1% failure rate)
- Customer satisfaction (NPS target ≥40)

**Team:** 1 engineer (on-call support), 1 medical advisor (quality review)
**Budget:** $25K

---

**Month 4 Milestones:**
- ✅ 2-3 hospitals using product in production
- ✅ 100-500 diagnoses completed
- ✅ NPS ≥40 (would recommend)
- ✅ <1% technical errors
- ✅ Clinical validation data collection started

**Success Criteria:**
- Customers actively using (not ghosting)
- Positive feedback (NPS ≥40)
- No major technical issues

---

### Month 5: Iterate & Expand Pilots

**Objectives:**
1. Recruit 3-5 additional pilot hospitals
2. Iterate based on feedback (v1.1 release)
3. Expand clinical validation dataset
4. Prepare for paid conversions (Month 6)

---

**Week 1-2: Product Iteration**

**Deliverables:**
- [ ] v1.1 release (top 5 feature requests)
- [ ] Improved DICOM handling (based on pilot feedback)
- [ ] Better reporting (PDF reports for radiologists)
- [ ] Performance optimizations (latency, accuracy)

**Common Feedback (Expected):**
1. Integration with PACS (easier image upload)
2. Faster results (latency optimization)
3. More detailed reports (findings + confidence scores)
4. Radiologist collaboration features (2nd opinion workflow)

**Team:** 2 engineers
**Budget:** $30K

---

**Week 3-4: Pilot Expansion**

**Deliverables:**
- [ ] 3-5 additional hospitals recruited
- [ ] Total: 5-8 pilot hospitals
- [ ] 500-1,000 diagnoses/month volume
- [ ] Pricing validation (survey: is $10 acceptable?)

**Outreach:**
- Referrals from existing pilots
- Conference presentations (local radiology societies)
- Direct outreach to 50 hospitals (target 10% response rate)

**Team:** 1 product manager (sales + onboarding)
**Budget:** $20K (PM salary) + $5K (conference travel)

---

**Month 5 Milestones:**
- ✅ 5-8 total pilot hospitals
- ✅ 500-1,000 diagnoses/month
- ✅ v1.1 released with feedback improvements
- ✅ $10 pricing validated (surveys)

**Success Criteria:**
- Organic growth (1-2 referrals from existing pilots)
- Improved NPS (≥50)
- Reduced error rate (<0.5%)

---

### Month 6: Pilot-to-Paid Conversion

**Objectives:**
1. Convert pilots to paid contracts (target 50% conversion)
2. Complete clinical validation study (submit for publication)
3. Launch paid tier (end of free pilot)
4. Achieve first revenue

---

**Week 1-2: Pilot-to-Paid Conversion**

**Deliverables:**
- [ ] Pricing presentation to pilot hospitals
- [ ] 3-4 paid contracts signed (50% of 6-8 pilots)
- [ ] First revenue month
- [ ] Case studies from paying customers

**Conversion Strategy:**
1. Present ROI data (time savings, no breaches, cost vs traditional)
2. Offer discount (50% off first 3 months)
3. Flexible payment (monthly, not annual)
4. Start small (50 diagnoses/month commitment)

**Team:** 1 PM (negotiations), 1 medical advisor (value demonstration)
**Budget:** $25K

---

**Week 3-4: Clinical Study Completion**

**Deliverables:**
- [ ] Data analysis complete (1,000-2,000 diagnoses)
- [ ] Manuscript written (draft submission)
- [ ] Submit to journal (PLOS Digital Health or similar)
- [ ] Prepare presentation for conferences

**Study Results (Expected):**
- Sensitivity: 85-95% (comparable to radiologists)
- Specificity: 90-95%
- Time savings: 20-40% (radiologist productivity improvement)
- Cost: $10 vs $200-500 traditional (95%+ savings)

**Team:** 1 medical advisor (lead author), 1 engineer (data analysis)
**Budget:** $15K (advisor time) + $3K (publication fees)

---

**Month 6 Milestones:**
- ✅ First revenue: $5K-20K MRR (3-4 paying hospitals × 50-200 diagnoses × $10)
- ✅ Clinical study submitted for publication
- ✅ 50% pilot-to-paid conversion
- ✅ Product-market fit validated

**Success Criteria:**
- ≥3 paying customers
- ≥$5K MRR
- Customers renew month 2 (retention ≥80%)

---

**Q1 Budget:** $260K
**Q1 Team:** 4 FTEs (2 backend, 1 full-stack, 1 medical advisor)
**Q1 Revenue:** $0 (free pilots)

---

## Q2 (Months 4-6): Pilot & Validation

*(Covered above in Month 4-6)*

**Q2 Budget:** $243K
**Q2 Team:** 4-5 FTEs (+1 PM in Month 5)
**Q2 Revenue:** $0 (Month 4-5), $5K-20K MRR (Month 6)

---

## Q3 (Months 7-9): Scale & Growth

### Month 7: Sales & Marketing Launch

**Objectives:**
1. Launch formal sales process
2. Expand to 10-20 paying hospitals
3. Present at major conference (RSNA or HIMSS)
4. Publish clinical validation results

---

**Week 1-2: Sales Infrastructure**

**Deliverables:**
- [ ] Hire sales rep (healthcare focus)
- [ ] Sales materials (deck, one-pager, ROI calculator)
- [ ] CRM setup (HubSpot or Salesforce)
- [ ] Outreach to 100 hospitals (target 10-20 pilots)

**Sales Process:**
1. Initial contact (email, LinkedIn)
2. Demo call (15 min product demo)
3. Trial offer (50 free diagnoses)
4. Evaluation period (1-2 months)
5. Contract negotiation
6. Onboarding (1 week)

**Team:** 1 sales rep (new hire) + 1 PM (sales support)
**Budget:** $35K (sales salary + PM) + $5K (CRM, tools)

---

**Week 3-4: Conference & Publication**

**Deliverables:**
- [ ] Present at RSNA (Radiological Society of North America) or HIMSS
- [ ] Clinical study published (or accepted)
- [ ] PR campaign (TechCrunch, Healthcare IT News)
- [ ] Lead generation from conference

**Conference Strategy:**
- Poster presentation (clinical study results)
- Booth (if budget allows)
- Networking (CIOs, CMIOs, radiologists)
- Collect leads (target 50-100 qualified)

**Team:** 1 medical advisor (presenter) + 1 PM (booth/networking)
**Budget:** $15K (conference fees, travel, booth)

---

**Month 7 Milestones:**
- ✅ Sales rep hired
- ✅ Conference presentation delivered
- ✅ Clinical study published or accepted
- ✅ 50-100 qualified leads generated

---

### Month 8: Customer Acquisition

**Objectives:**
1. Onboard 10-20 new hospitals (total: 13-24)
2. Scale infrastructure (handle 2K-5K diagnoses/month)
3. Implement feedback from customers
4. Optimize for margin (cost reduction Phase 1)

---

**Week 1-4: Rapid Onboarding**

**Deliverables:**
- [ ] 10-20 new hospitals onboarded
- [ ] Total: 13-24 paying hospitals
- [ ] Volume: 1,000-3,000 diagnoses/month
- [ ] Revenue: $10K-30K MRR

**Onboarding Acceleration:**
- Streamlined DICOM integration (pre-built connectors for top 3 PACS vendors)
- Self-serve onboarding (reduce PM time)
- Group training webinars (1:many instead of 1:1)

**Team:** 1 sales rep (close deals), 1 engineer (integration support), 1 PM (onboarding)
**Budget:** $50K (team) + $10K (PACS integrations)

---

**Month 8 Milestones:**
- ✅ 13-24 paying hospitals
- ✅ $10K-30K MRR
- ✅ 1,000-3,000 diagnoses/month

---

### Month 9: Optimization & Expansion Prep

**Objectives:**
1. Implement Phase 1 optimizations (cost reduction)
2. Expand modalities (CT, MRI beyond X-ray)
3. Begin Personal AI development
4. Achieve $30K-50K MRR

---

**Week 1-2: Cost Optimizations**

**Deliverables:**
- [ ] Model quantization (INT8) - 50% cost reduction
- [ ] Model caching - 60% faster, cheaper
- [ ] Right-sized compute resources - 50-75% cost reduction
- [ ] Total: 95% cost reduction vs baseline

**Implementation:**
```typescript
// Before: Load model every request (5s load + 10s inference = 15s total)
const model = await loadModel();  // $0.0033
const result = await model.predict(input);  // $0.0022

// After: Cache model in memory (0s load + 10s inference = 10s total)
if (!cachedModel) cachedModel = await loadModel();  // Once
const result = await cachedModel.predict(input);  // $0.0022 only
// Savings: 33% latency, 60% cost
```

**Team:** 1 engineer (optimizations)
**Budget:** $20K

---

**Week 3-4: Product Expansion**

**Deliverables:**
- [ ] Add CT scan support (expand beyond X-ray)
- [ ] Add MRI support (high-value modality)
- [ ] Multi-modality pricing (X-ray: $10, CT: $15, MRI: $20)
- [ ] Begin Personal AI MVP development (separate team)

**Team:** 1 engineer (CT/MRI models), +2 engineers (Personal AI)
**Budget:** $50K (3 engineers)

---

**Month 9 Milestones:**
- ✅ $30K-50K MRR (healthcare)
- ✅ 3,000-5,000 diagnoses/month
- ✅ 95% cost reduction implemented (margins improve)
- ✅ CT/MRI support launched (higher revenue per customer)
- ✅ Personal AI MVP development started

---

**Q3 Budget:** $360K
**Q3 Team:** 6 FTEs (3 healthcare, 2 personal AI, 1 PM/sales)
**Q3 Revenue:** $10K-50K MRR (cumulative)

---

## Q4 (Months 10-12): Optimization & Expansion

### Month 10: Scale Healthcare

**Objectives:**
1. Reach 50+ paying hospitals
2. Achieve $50K-100K MRR (healthcare)
3. SOC 2 Type II certification (start process)
4. Personal AI alpha launch

---

**Week 1-4: Sales Acceleration**

**Deliverables:**
- [ ] 30-50 new hospitals (total: 50+)
- [ ] $50K-100K MRR
- [ ] Hire 2nd sales rep (expand capacity)
- [ ] Referral program (incentivize existing customers)

**Scaling Tactics:**
1. **Referral incentives:** 1 month free for each referral
2. **Case studies:** 3-5 published customer stories
3. **Webinars:** Monthly "Private AI for Healthcare" webinars (50-100 attendees)
4. **Partnerships:** PACS vendor co-marketing (Merge, Intelerad)

**Team:** 2 sales reps, 1 PM, 1 engineer (support)
**Budget:** $70K

---

**Month 10 Milestones:**
- ✅ 50+ hospitals
- ✅ $50K-100K MRR
- ✅ SOC 2 audit initiated (required for enterprise)
- ✅ Personal AI alpha (100 users)

---

### Month 11: Enterprise Prep & Personal AI Beta

**Objectives:**
1. Prepare for enterprise tier (SOC 2, SSO, RBAC)
2. Personal AI beta launch (1,000 users)
3. Developer Tools planning
4. Reach $100K MRR (healthcare)

---

**Week 1-2: Enterprise Features**

**Deliverables:**
- [ ] SSO integration (Okta, Azure AD)
- [ ] RBAC (admin, radiologist, viewer roles)
- [ ] Audit logs (blockchain-based, immutable)
- [ ] API for programmatic access (health systems)

**Team:** 2 engineers
**Budget:** $30K

---

**Week 3-4: Personal AI Beta**

**Deliverables:**
- [ ] Personal AI beta launch (invite-only)
- [ ] 1,000 beta users
- [ ] Integrations: Gmail, Google Calendar (read-only)
- [ ] Core features: Email summarization, calendar assistance

**Team:** 2 engineers (Personal AI track)
**Budget:** $30K

---

**Month 11 Milestones:**
- ✅ $100K MRR (healthcare - 100 hospitals × 100 diagnoses × $10)
- ✅ Enterprise features ready
- ✅ Personal AI beta (1,000 users, 10-20% paid)
- ✅ SOC 2 audit progressing

---

### Month 12: Consolidation & Year 2 Planning

**Objectives:**
1. Achieve $100K-200K MRR (combined)
2. Complete SOC 2 certification
3. Plan Year 2 expansion (enterprise, developer tools)
4. Fundraising (Series A prep if needed)

---

**Week 1-2: Year-End Push**

**Deliverables:**
- [ ] 100-200 hospitals (healthcare)
- [ ] 5K-10K personal AI users (500-1K paid)
- [ ] $100K-200K MRR combined
- [ ] SOC 2 Type II certification complete

**Team:** 2 sales reps, 1 PM, 4 engineers
**Budget:** $100K

---

**Week 3-4: Strategic Planning**

**Deliverables:**
- [ ] Year 2 roadmap (enterprise B2B, developer tools)
- [ ] Budget for Year 2 ($3M-5M)
- [ ] Fundraising deck (if Series A)
- [ ] Team expansion plan (hire 5-10 in Year 2)

**Year 2 Targets:**
- Healthcare: $500K MRR (500 hospitals)
- Personal AI: $1M MRR (100K users)
- Developer Tools: Launch (Month 13)
- Enterprise B2B: Pilots (Month 19)
- **Total Year 2 Target: $6M-10M ARR**

**Team:** Founders + PM
**Budget:** $15K (planning, legal for fundraise)

---

**Month 12 Milestones:**
- ✅ $100K-200K MRR (combined)
- ✅ 100-200 hospitals paying
- ✅ 10K personal AI users (500-1K paid)
- ✅ SOC 2 certified (enterprise-ready)
- ✅ Year 2 plan finalized

---

**Q4 Budget:** $445K
**Q4 Team:** 6 FTEs (2 sales, 3 engineers, 1 PM)
**Q4 Revenue:** $50K-200K MRR (cumulative growth)

---

## Team & Budget

### Team Composition (12 Months)

**Months 1-3 (Q1): 4 FTEs**
- 2 Backend Engineers (smart contracts, nilCC service)
- 1 Full-stack Engineer (frontend, integrations)
- 1 Medical Advisor (part-time, clinical expertise)

**Months 4-6 (Q2): 5 FTEs**
- 3 Engineers (as above)
- 1 Product Manager (onboarding, sales support)
- 1 Medical Advisor

**Months 7-9 (Q3): 6 FTEs**
- 3 Healthcare Engineers
- 2 Personal AI Engineers
- 1 Sales Rep (healthcare)
- 1 PM

**Months 10-12 (Q4): 7-8 FTEs**
- 4 Engineers (3 healthcare, 2 personal AI, split)
- 2 Sales Reps
- 1 PM
- 1 Medical Advisor

**Average Team Size:** 5.5 FTEs

---

### Budget Breakdown (12 Months)

**Personnel:**

| Role | Headcount | Avg Salary | Annual | Notes |
|------|-----------|-----------|--------|-------|
| **Engineers** | 4 avg | $150K | $600K | Backend, full-stack, ML |
| **Sales Reps** | 1 avg | $120K | $120K | Healthcare sales experience |
| **Product Manager** | 1 | $140K | $140K | Months 5-12 (8 months × $11.7K) |
| **Medical Advisor** | 0.25 | $80K | $20K | Part-time consultant |
| **TOTAL PERSONNEL** | | | **$880K** | |

---

**Infrastructure:**

| Category | Monthly | Annual | Notes |
|----------|---------|--------|-------|
| **Nillion nilCC** | $2K | $24K | Estimated (may be free in early stage) |
| **Ethereum RPC** | $500 | $6K | Alchemy Growth plan |
| **Cloud Infrastructure** | $1K | $12K | Hosting, monitoring, backups |
| **Security/Compliance** | $2K | $24K | SOC 2 audit, pen testing |
| **TOTAL INFRASTRUCTURE** | | **$66K** | |

---

**Other Expenses:**

| Category | Amount | Notes |
|----------|--------|-------|
| **Smart Contract Audit** | $30K | One-time (Month 2) |
| **Clinical Study** | $23K | Data, publication, advisor time |
| **Conferences** | $30K | RSNA, HIMSS (3 conferences × $10K) |
| **Marketing** | $50K | Website, ads, materials |
| **Legal** | $30K | Corp formation, contracts, IP |
| **Software/Tools** | $15K | GitHub, Figma, Slack, misc |
| **TOTAL OTHER** | **$178K** | |

---

**12-Month Total Budget:**

| Category | Amount | % of Total |
|----------|--------|------------|
| Personnel | $880K | 76% |
| Infrastructure | $66K | 6% |
| Other | $178K | 15% |
| Contingency (10%) | $112K | 10% |
| **TOTAL** | **$1,236K** | 100% |

**Rounded: $1.2M for 12 months** ($100K/month average)

---

### Funding Requirements

**Runway: 18-24 months** (safe buffer beyond 12-month plan)
**Total Raise: $1.5M-2M** (covers 12-month plan + 6-12 month buffer)

**Funding Options:**

**Option A: Angel/Pre-Seed**
- Amount: $1.5M
- Valuation: $10M post-money (15% dilution)
- Timeline: Month 0-1 (before starting)

**Option B: Grants (Non-Dilutive)**
- Nillion ecosystem grant: $100K-500K
- NIH Small Business Innovation Research (SBIR): $150K-1M
- State grants (healthcare innovation): $50K-250K
- **Total potential: $300K-1.75M**

**Option C: Hybrid (Recommended)**
- Grants: $500K-1M (non-dilutive)
- Angel: $500K-1M (10-15% dilution)
- **Total: $1-2M** with less dilution

---

## Success Metrics

### Monthly KPIs

**Month 1-3 (MVP):**
- [ ] Smart contract deployed ✅
- [ ] nilCC service live ✅
- [ ] First pilot hospital ✅
- [ ] Costs validated (within 2x estimate)

**Month 4-6 (Validation):**
- [ ] 5-8 pilot hospitals
- [ ] 500-1,000 diagnoses/month
- [ ] NPS ≥40
- [ ] First paid customers (Month 6)

**Month 7-9 (Scale):**
- [ ] 20-50 paying hospitals
- [ ] $20K-50K MRR
- [ ] Clinical study published
- [ ] Conference presentation

**Month 10-12 (Growth):**
- [ ] 100-200 hospitals
- [ ] $100K-200K MRR
- [ ] SOC 2 certified
- [ ] Personal AI beta (1K+ users)

---

### Financial Metrics

**Revenue Milestones:**

| Month | Hospitals | Diagnoses/Month | MRR | ARR Run-Rate |
|-------|-----------|-----------------|-----|--------------|
| 6 | 3-4 | 300 | $3K | $36K |
| 7 | 10 | 1,000 | $10K | $120K |
| 9 | 30 | 3,000 | $30K | $360K |
| 12 | 100 | 10,000 | $100K | $1.2M |

**Break-Even Analysis:**
- Monthly costs: $100K (average)
- Break-even MRR: $100K
- **Target: Month 12** (end of Year 1)

**Profitability:**
- Month 12 revenue: $100K-200K
- Month 12 costs: $100K
- **Profit: $0-100K/month** (or slightly negative, but path to profitability clear)

---

### Non-Financial Metrics

**Product:**
- Diagnostic accuracy: ≥90% (vs radiologist ground truth)
- Latency: <2s P95 (user experience)
- Uptime: ≥99.5% (SLA)
- Error rate: <0.5% (reliability)

**Customer:**
- NPS: ≥40 (would recommend)
- Retention: ≥80% month-over-month
- Churn: <20% monthly
- Expansion revenue: 20% of customers increase usage

**Team:**
- Engineering velocity: 2-week sprints, ship every 2 weeks
- Sales efficiency: ≥20% close rate (pilot → paid)
- Time to onboard: <2 weeks (hospital ready to use)

---

## Risk Mitigation

### Critical Risks & Mitigations

**Risk 1: Nillion Costs Higher Than Expected**

**If Nillion costs $0.02/exec (10x estimate):**
- Margin at $10 price: 99.8% → 99.0% (still excellent) ✅
- Action: Continue

**If Nillion costs $0.10/exec (50x estimate):**
- Margin at $10 price: 99% → 90% (acceptable) ✅
- Action: Continue, consider price increase to $15

**If Nillion costs >$0.50/exec (250x estimate):**
- Margin at $10 price: 95% (still profitable) ⚠️
- Action: Increase price to $20-25 OR pivot to Oasis Sapphire

**Mitigation Timeline:**
- Month 1: Measure actual costs on testnet
- Month 2: Validate with production pilot
- Month 3: Decide GO/PIVOT based on empirical data

---

**Risk 2: Slower Customer Acquisition**

**If only 20 hospitals by Month 12 (vs. 100 target):**
- Revenue: $20K MRR (vs. $100K target)
- Runway: Need to reduce burn or raise more

**Mitigation:**
1. **Extend runway** (raise $2M instead of $1.5M)
2. **Reduce burn** (slower hiring, fewer conferences)
3. **Accelerate Personal AI** (faster GTM, more volume)
4. **Pivot to enterprise earlier** (larger contracts, fewer customers)

---

**Risk 3: Nillion Network Issues**

**If uptime <99% OR significant bugs:**
- Customer churn risk (SLA failures)
- Reputation damage

**Mitigation:**
1. **Conservative SLAs initially** (99.5% not 99.9%)
2. **Gradual rollout** (limit to 10 hospitals until proven)
3. **Fallback architecture** (Oracle pattern if RPC unstable)
4. **Oasis Sapphire** (migrate if Nillion fails)

**Decision Point:** Month 3-4 (after 1,000 diagnoses)

---

## Conclusion

**12-Month Roadmap: COMPLETE** ✅

**Expected Outcomes (End of Month 12):**
- ✅ **100-200 hospitals** paying for healthcare AI
- ✅ **$100K-200K MRR** ($1.2M-2.4M ARR)
- ✅ **10,000 diagnoses/month** volume
- ✅ **SOC 2 certified** (enterprise-ready)
- ✅ **Personal AI launched** (1K-10K users)
- ✅ **Clinical study published** (credibility)

**Team: 7-8 FTEs**
**Budget: $1.2M**
**Burn Rate: $100K/month** (sustainable with $1.5-2M raise)

**Path to Profitability:**
- Break-even: Month 12 ($100K MRR)
- Profitable: Month 13-15 (as MRR exceeds $100K)
- Series A ready: Month 18-24 ($5M+ ARR)

---

**Next:** Task 4.3 - Final Documentation (Executive Summary, Presentation Deck)

---

**Document Status:** COMPLETE
**Last Updated:** November 15, 2025
**Next:** Final Executive Summary & Presentation
