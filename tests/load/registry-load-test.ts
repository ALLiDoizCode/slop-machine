/**
 * Registry Process Load Testing Script
 *
 * Validates NFR2: Registry P95 query latency <1 second
 * Validates NFR10: Registry supports 100+ concurrent queries
 *
 * Usage:
 *   REGISTRY_PROCESS_ID=<process-id> npm run load-test
 *   REGISTRY_PROCESS_ID=<process-id> CONCURRENT=200 npm run load-test
 */

import { message, createDataItemSigner } from '@permaweb/aoconnect';
import chalk from 'chalk';

// Configuration
const REGISTRY_PROCESS_ID = process.env.REGISTRY_PROCESS_ID;
const CONCURRENT_QUERIES = parseInt(process.env.CONCURRENT || '100', 10);
const ITERATIONS = parseInt(process.env.ITERATIONS || '10', 10);
const TIMEOUT_MS = parseInt(process.env.TIMEOUT || '5000', 10);

// Mock signer for testing (no actual wallet needed for queries)
const mockSigner = createDataItemSigner({
  // Minimal mock wallet (queries don't require actual signing in most cases)
  publicKey: 'mock_public_key',
  sign: async () => new Uint8Array(512)
} as any);

interface LoadTestResult {
  totalQueries: number;
  successCount: number;
  failureCount: number;
  timeoutCount: number;
  latencies: number[];
  p50: number;
  p95: number;
  p99: number;
  min: number;
  max: number;
  avg: number;
  throughput: number;
  duration: number;
}

/**
 * Perform a single query to the Registry
 * @param action - Action type to test
 * @param tags - Additional tags
 * @returns Latency in milliseconds or null if failed
 */
async function performQuery(
  action: string,
  tags: Record<string, string> = {}
): Promise<number | null> {
  const start = Date.now();

  try {
    const allTags = [
      { name: 'Action', value: action },
      ...Object.entries(tags).map(([name, value]) => ({ name, value }))
    ];

    await Promise.race([
      message({
        process: REGISTRY_PROCESS_ID!,
        tags: allTags,
        signer: mockSigner,
        data: ''
      }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Timeout')), TIMEOUT_MS)
      )
    ]);

    const latency = Date.now() - start;
    return latency;

  } catch (error) {
    const latency = Date.now() - start;
    if (error instanceof Error && error.message === 'Timeout') {
      return null; // Timeout
    }
    console.error(chalk.dim(`  Query failed: ${error}`));
    return null;
  }
}

/**
 * Calculate percentiles from sorted latency array
 */
function calculatePercentiles(sortedLatencies: number[]) {
  const len = sortedLatencies.length;

  if (len === 0) {
    return { p50: 0, p95: 0, p99: 0, min: 0, max: 0, avg: 0 };
  }

  const p50 = sortedLatencies[Math.floor(len * 0.50)];
  const p95 = sortedLatencies[Math.floor(len * 0.95)];
  const p99 = sortedLatencies[Math.floor(len * 0.99)];
  const min = sortedLatencies[0];
  const max = sortedLatencies[len - 1];
  const avg = sortedLatencies.reduce((sum, val) => sum + val, 0) / len;

  return { p50, p95, p99, min, max, avg };
}

/**
 * Run load test for a specific query type
 */
async function runLoadTest(
  testName: string,
  action: string,
  tags: Record<string, string> = {}
): Promise<LoadTestResult> {
  console.log(chalk.cyan(`\n🔄 Running: ${testName}`));
  console.log(chalk.gray(`  Action: ${action}`));
  console.log(chalk.gray(`  Concurrent queries: ${CONCURRENT_QUERIES}`));
  console.log(chalk.gray(`  Iterations: ${ITERATIONS}`));
  console.log(chalk.gray(`  Total queries: ${CONCURRENT_QUERIES * ITERATIONS}\n`));

  const latencies: number[] = [];
  let successCount = 0;
  let failureCount = 0;
  let timeoutCount = 0;

  const overallStart = Date.now();

  for (let iteration = 0; iteration < ITERATIONS; iteration++) {
    const promises: Promise<number | null>[] = [];

    // Launch concurrent queries
    for (let i = 0; i < CONCURRENT_QUERIES; i++) {
      promises.push(performQuery(action, tags));
    }

    // Wait for all to complete
    const results = await Promise.all(promises);

    // Process results
    for (const latency of results) {
      if (latency !== null) {
        latencies.push(latency);
        successCount++;
      } else {
        timeoutCount++;
        failureCount++;
      }
    }

    // Progress indicator
    const progress = Math.round(((iteration + 1) / ITERATIONS) * 100);
    process.stdout.write(`\r  Progress: ${progress}% (${successCount} success, ${failureCount} failed)`);
  }

  const overallDuration = Date.now() - overallStart;
  process.stdout.write('\n');

  // Calculate statistics
  latencies.sort((a, b) => a - b);
  const percentiles = calculatePercentiles(latencies);
  const throughput = (successCount / overallDuration) * 1000; // queries per second

  return {
    totalQueries: CONCURRENT_QUERIES * ITERATIONS,
    successCount,
    failureCount,
    timeoutCount,
    latencies,
    ...percentiles,
    throughput,
    duration: overallDuration
  };
}

/**
 * Display load test results
 */
function displayResults(testName: string, results: LoadTestResult): void {
  console.log(chalk.cyan(`\n📊 Results: ${testName}\n`));

  // Success metrics
  const successRate = (results.successCount / results.totalQueries) * 100;
  const successColor = successRate >= 95 ? chalk.green : chalk.yellow;
  console.log(`  Total Queries:    ${results.totalQueries}`);
  console.log(`  Success:          ${successColor(results.successCount)} (${successRate.toFixed(1)}%)`);
  console.log(`  Failed:           ${chalk.red(results.failureCount)}`);
  console.log(`  Timeouts:         ${chalk.yellow(results.timeoutCount)}`);

  if (results.successCount > 0) {
    // Latency metrics
    console.log(chalk.cyan('\n  Latency (milliseconds):'));
    console.log(`    Min:     ${results.min}ms`);
    console.log(`    Avg:     ${Math.round(results.avg)}ms`);
    console.log(`    P50:     ${results.p50}ms`);

    const p95Color = results.p95 < 1000 ? chalk.green : chalk.red;
    console.log(`    P95:     ${p95Color(results.p95 + 'ms')} ${results.p95 < 1000 ? '✓' : '✗ EXCEEDS TARGET'}`);

    console.log(`    P99:     ${results.p99}ms`);
    console.log(`    Max:     ${results.max}ms`);

    // Throughput
    console.log(chalk.cyan('\n  Performance:'));
    console.log(`    Throughput:   ${results.throughput.toFixed(2)} queries/sec`);
    console.log(`    Duration:     ${(results.duration / 1000).toFixed(2)}s`);
  }
}

/**
 * Validate NFR requirements
 */
function validateNFRs(results: LoadTestResult[]): boolean {
  console.log(chalk.cyan('\n🎯 NFR Validation\n'));

  let allPassed = true;

  // NFR2: P95 latency <1 second
  const avgP95 = results.reduce((sum, r) => sum + r.p95, 0) / results.length;
  const nfr2Passed = avgP95 < 1000;
  const nfr2Color = nfr2Passed ? chalk.green : chalk.red;

  console.log(`  NFR2 - P95 Latency <1s:    ${nfr2Color(avgP95.toFixed(0) + 'ms')} ${nfr2Passed ? '✓ PASS' : '✗ FAIL'}`);

  if (!nfr2Passed) {
    console.log(chalk.yellow(`    → Optimization needed: P95 is ${avgP95.toFixed(0)}ms (target: <1000ms)`));
    allPassed = false;
  }

  // NFR10: 100+ concurrent queries
  const avgSuccessRate = results.reduce((sum, r) => sum + (r.successCount / r.totalQueries), 0) / results.length;
  const nfr10Passed = avgSuccessRate >= 0.95 && CONCURRENT_QUERIES >= 100;
  const nfr10Color = nfr10Passed ? chalk.green : chalk.red;

  console.log(`  NFR10 - 100+ Concurrent:   ${nfr10Color((avgSuccessRate * 100).toFixed(1) + '%')} ${nfr10Passed ? '✓ PASS' : '✗ FAIL'}`);

  if (!nfr10Passed) {
    if (avgSuccessRate < 0.95) {
      console.log(chalk.yellow(`    → Success rate too low: ${(avgSuccessRate * 100).toFixed(1)}% (target: ≥95%)`));
    }
    if (CONCURRENT_QUERIES < 100) {
      console.log(chalk.yellow(`    → Increase CONCURRENT env var to 100+ (current: ${CONCURRENT_QUERIES})`));
    }
    allPassed = false;
  }

  return allPassed;
}

/**
 * Main load test execution
 */
async function main() {
  console.log(chalk.bold.cyan('\n╔════════════════════════════════════════╗'));
  console.log(chalk.bold.cyan('║  Permamind Registry Load Test Suite   ║'));
  console.log(chalk.bold.cyan('╚════════════════════════════════════════╝\n'));

  // Validate configuration
  if (!REGISTRY_PROCESS_ID) {
    console.error(chalk.red('✗ Error: REGISTRY_PROCESS_ID environment variable not set\n'));
    console.error(chalk.gray('  Usage: REGISTRY_PROCESS_ID=<process-id> npm run load-test\n'));
    process.exit(1);
  }

  console.log(chalk.gray(`Registry Process ID: ${REGISTRY_PROCESS_ID}`));
  console.log(chalk.gray(`Timeout: ${TIMEOUT_MS}ms\n`));

  const testResults: LoadTestResult[] = [];

  // Test 1: SearchSkills (most common query)
  const searchSkillsResult = await runLoadTest(
    'SearchSkills Query',
    'SearchSkills',
    { Limit: '10' }
  );
  displayResults('SearchSkills', searchSkillsResult);
  testResults.push(searchSkillsResult);

  // Test 2: SearchProcesses
  const searchProcessesResult = await runLoadTest(
    'SearchProcesses Query',
    'SearchProcesses',
    { Limit: '10' }
  );
  displayResults('SearchProcesses', searchProcessesResult);
  testResults.push(searchProcessesResult);

  // Test 3: GetMarketplaceStats (aggregate query)
  const statsResult = await runLoadTest(
    'GetMarketplaceStats Query',
    'GetMarketplaceStats'
  );
  displayResults('GetMarketplaceStats', statsResult);
  testResults.push(statsResult);

  // Test 4: ScoreSkill (complex computation)
  const scoreSkillResult = await runLoadTest(
    'ScoreSkill Query',
    'ScoreSkill',
    { SkillTxId: 'mock_skill_txid_43_characters_for_testing' }
  );
  displayResults('ScoreSkill', scoreSkillResult);
  testResults.push(scoreSkillResult);

  // Validate NFRs
  const nfrsPassed = validateNFRs(testResults);

  // Summary
  console.log(chalk.cyan('\n📈 Overall Summary\n'));

  const totalSuccess = testResults.reduce((sum, r) => sum + r.successCount, 0);
  const totalQueries = testResults.reduce((sum, r) => sum + r.totalQueries, 0);
  const overallSuccessRate = (totalSuccess / totalQueries) * 100;

  console.log(`  Total Queries:      ${totalQueries}`);
  console.log(`  Total Success:      ${totalSuccess} (${overallSuccessRate.toFixed(1)}%)`);
  console.log(`  Total Failed:       ${testResults.reduce((sum, r) => sum + r.failureCount, 0)}`);

  const avgP95 = testResults.reduce((sum, r) => sum + r.p95, 0) / testResults.length;
  console.log(`  Average P95:        ${avgP95.toFixed(0)}ms`);

  // Final result
  if (nfrsPassed) {
    console.log(chalk.green('\n✅ All NFRs PASSED - Registry is production-ready!\n'));
    process.exit(0);
  } else {
    console.log(chalk.red('\n✗ Some NFRs FAILED - Optimization required before launch\n'));
    console.log(chalk.yellow('Recommendations:'));
    console.log(chalk.gray('  1. Profile Registry process handlers (identify slow operations)'));
    console.log(chalk.gray('  2. Add secondary indexes for common queries (SkillsByTag)'));
    console.log(chalk.gray('  3. Optimize Lua table iteration (use ipairs vs pairs where possible)'));
    console.log(chalk.gray('  4. Consider pagination limit reduction (10 → 5 max per query)'));
    console.log(chalk.gray('  5. Deploy Registry replicas if single process insufficient\n'));
    process.exit(1);
  }
}

/**
 * Handle errors and cleanup
 */
process.on('unhandledRejection', (error) => {
  console.error(chalk.red('\n✗ Unhandled error during load test:'));
  console.error(error);
  process.exit(1);
});

process.on('SIGINT', () => {
  console.log(chalk.yellow('\n\n⚠️  Load test interrupted by user\n'));
  process.exit(130);
});

// Run tests
main().catch((error) => {
  console.error(chalk.red('\n✗ Load test failed:'));
  console.error(error.message);
  process.exit(1);
});
