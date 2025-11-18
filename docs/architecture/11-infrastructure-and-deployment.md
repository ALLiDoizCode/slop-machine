# 11. Infrastructure and Deployment

**Strategy:** Docker + Docker Compose for Phase 1

**CI/CD:** GitHub Actions

**Environments:**
- **Local:** Docker Compose (development)
- **Base Sepolia Testnet:** Self-hosted or cloud VM
- **Optimism Sepolia Testnet:** Self-hosted or cloud VM
- **Mainnet:** Future, post-audit (Kubernetes cluster)

**Deployment Flow:** Local → Base Sepolia → Optimism Sepolia → Mainnet (manual approval gates)

**Rollback Strategy:**
- **Applications:** Redeploy previous Docker image (~5 minutes)
- **Smart Contracts:** Deploy new version forward (immutable, cannot rollback)

**Monitoring (Phase 1):**
- Logging: Pino JSON logs to stdout
- Health checks: `/health` endpoint
- Metrics: Manual log inspection

**Monitoring (Future):**
- Prometheus + Grafana for metrics
- Elasticsearch + Kibana for logs
- OpenTelemetry for tracing

---
