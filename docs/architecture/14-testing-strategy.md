# 14. Testing Strategy

**Test Pyramid:**
- **Unit Tests:** 60% (Vitest, ≥90% coverage)
- **Integration Tests:** 30% (Hardhat Network)
- **E2E Tests:** 10% (Docker Compose)

**Test Types:**

1. **Unit Tests** - Individual function testing, mock all external dependencies
2. **Integration Tests** - Component boundary testing, Hardhat Network for blockchain
3. **Smart Contract Tests** - Hardhat + Chai, ≥95% coverage, security test patterns
4. **E2E Tests** - Full protocol flow, Docker Compose environment

**AI Agent Requirements:**
- Generate unit tests for all public methods
- Cover edge cases: null, undefined, empty arrays, boundary values
- Test error conditions: invalid inputs throw expected errors
- Mock external dependencies: Never call real blockchain in unit tests
- Follow AAA pattern: Arrange, Act, Assert

**Test Data Management:**
- Factory pattern for test data generation
- Fixtures for smart contract tests
- Faker.js for random test data

**CI Integration:**
- Run all tests on every PR
- Enforce coverage thresholds (90% protocol-core, 95% contracts)
- Upload coverage to Codecov
- Total CI time: <10 minutes

---
