# Registry Load Testing

Validates that the Permamind Registry Process meets performance requirements under concurrent load.

## Prerequisites

- Node.js 18+
- Deployed Registry Process (testnet or mainnet)
- Network access to AO

## Installation

```bash
cd tests/load
npm install
```

## Usage

### Basic Load Test (100 concurrent queries)

```bash
REGISTRY_PROCESS_ID=<your-registry-process-id> npm run load-test
```

### Quick Test (10 concurrent queries, faster)

```bash
REGISTRY_PROCESS_ID=<your-registry-process-id> npm run load-test:quick
```

### Heavy Load Test (200 concurrent queries)

```bash
REGISTRY_PROCESS_ID=<your-registry-process-id> npm run load-test:heavy
```

### Custom Configuration

```bash
REGISTRY_PROCESS_ID=<process-id> \
CONCURRENT=150 \
ITERATIONS=15 \
TIMEOUT=10000 \
npm run load-test
```

## Configuration Options

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `REGISTRY_PROCESS_ID` | (required) | AO process ID of Registry to test |
| `CONCURRENT` | 100 | Number of concurrent queries per iteration |
| `ITERATIONS` | 10 | Number of iterations to run |
| `TIMEOUT` | 5000 | Query timeout in milliseconds |

## Test Scenarios

The load test suite validates four query types:

1. **SearchSkills** - Most common query, tag and keyword filtering
2. **SearchProcesses** - Process discovery with capability filtering
3. **GetMarketplaceStats** - Aggregate statistics (complex computation)
4. **ScoreSkill** - Quality scoring algorithm (weighted calculation)

## NFR Validation

The test automatically validates against PRD non-functional requirements:

- **NFR2:** Registry P95 query latency <1 second ✅
- **NFR10:** Registry supports 100+ concurrent queries without degradation ✅

## Sample Output

```
╔════════════════════════════════════════╗
║  Permamind Registry Load Test Suite   ║
╚════════════════════════════════════════╝

Registry Process ID: abc123...xyz789
Timeout: 5000ms

🔄 Running: SearchSkills Query
  Action: SearchSkills
  Concurrent queries: 100
  Iterations: 10
  Total queries: 1000

  Progress: 100% (998 success, 2 failed)

📊 Results: SearchSkills

  Total Queries:    1000
  Success:          998 (99.8%)
  Failed:           2
  Timeouts:         2

  Latency (milliseconds):
    Min:     245ms
    Avg:     623ms
    P50:     587ms
    P95:     892ms ✓
    P99:     1043ms
    Max:     1234ms

  Performance:
    Throughput:   15.23 queries/sec
    Duration:     65.52s

[... results for other queries ...]

🎯 NFR Validation

  NFR2 - P95 Latency <1s:    876ms ✓ PASS
  NFR10 - 100+ Concurrent:   99.2% ✓ PASS

✅ All NFRs PASSED - Registry is production-ready!
```

## Interpretation

### Success Criteria

- **Success Rate ≥95%:** Registry handles concurrent load reliably
- **P95 Latency <1000ms:** 95% of queries complete within 1 second (NFR2)
- **No Crashes:** Registry process continues responding throughout test

### Common Issues

**High Timeout Rate (>5%):**
- Registry process may be overloaded
- Check AO network congestion
- Consider reducing concurrent queries or adding delays between iterations

**P95 Latency >1000ms:**
- Registry needs optimization (add secondary indexes)
- Linear search may be too slow (consider pagination limit reduction)
- Deploy Registry replicas for read scaling

**Low Throughput (<5 queries/sec):**
- Network latency to AO may be high
- Run test closer to AO infrastructure
- Check local internet connection

## Optimization Recommendations

If NFRs fail, consider these optimizations (in order of impact):

1. **Add Secondary Indexes:**
   ```lua
   -- In registry.lua
   SkillsByTag = SkillsByTag or {}
   -- SkillsByTag["security"] = { txId1, txId2, ... }
   ```

2. **Reduce Default Pagination Limit:**
   - Change default from 10 → 5 results per query
   - Forces clients to paginate more (faster individual queries)

3. **Optimize Lua Iteration:**
   - Use `ipairs` for arrays (faster than `pairs`)
   - Early exit from loops when possible

4. **Deploy Read Replicas:**
   - Multiple Registry processes with same state
   - Load balance queries across replicas
   - Eventual consistency acceptable for discovery use case

5. **Cache Computed Metrics:**
   - Pre-calculate quality scores on metric updates
   - Avoid recalculating on every search query

## Continuous Performance Testing

**Pre-Launch:**
- Run load test on testnet Registry before mainnet deployment
- Validate NFRs pass with realistic data (100+ skills, 50+ processes)

**Post-Launch:**
- Run weekly on production Registry (off-peak hours)
- Track P95 latency trends over time
- Alert if P95 exceeds 800ms (80% of threshold)

## Troubleshooting

**Error: "REGISTRY_PROCESS_ID environment variable not set"**
- Set the env var: `export REGISTRY_PROCESS_ID=<your-process-id>`
- Or inline: `REGISTRY_PROCESS_ID=<id> npm run load-test`

**Error: "Connection timeout"**
- Increase TIMEOUT: `TIMEOUT=10000 npm run load-test`
- Check Registry process is deployed and responding: `aos <process-id>`

**All queries timing out:**
- Verify Registry process ID is correct
- Check AO network status
- Try with CONCURRENT=1 to isolate issue

**Inconsistent results between runs:**
- Normal due to network variability
- Run multiple times and average results
- Focus on P95/P99 (more stable than P50)
