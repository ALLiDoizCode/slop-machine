# Monitoring and Observability

## Monitoring Stack

- **Frontend:** Vercel Analytics (Web Vitals)
- **Backend:** Railway Metrics (MVP), Datadog (Production)
- **Error Tracking:** Sentry
- **Performance:** TimescaleDB metrics + Grafana

## Key Metrics

**Frontend:**
- Core Web Vitals (LCP <2.5s, FID <100ms, CLS <0.1)
- JavaScript error rate (< 1%)
- API response times (p95 <300ms)

**Backend:**
- Request rate (target: 1000 pkt/sec)
- Error rate (< 1%)
- Payment latency (p95 <100ms)
- Database query performance (p95 <50ms)
- Settlement success rate (> 99%)

---
