# Test Coverage Strategy - Phase 0 P2

Comprehensive test infrastructure for API, frontend, and E2E scenarios with coverage reporting.

## Test Layers

### Layer 1: Unit Tests (Middleware & Routes)

**API Middleware Tests** (`api/src/__tests__/middleware.test.ts`)
- Correlation ID generation and preservation
- Authentication token validation
- RBAC enforcement
- Error response security (no token leakage)
- Role-based access control matrix

**API Routes Tests** (`api/src/__tests__/routes.test.ts`)
- Metrics endpoint structure and data validation
- Feedback endpoint list and triage operations
- Telemetry event aggregation and platform distribution
- Data validation (ranges, formats, ISO timestamps)

### Layer 2: Integration Tests (API Contract)

**Smoke Tests** (`api/src/__tests__/smoke.test.ts`)
- Health endpoints (200 status, required fields)
- Authentication (401 without token, 200 with valid token)
- Metrics endpoints (returns data, matches schema)
- Correlation ID presence in all responses

**Integration Tests** (`api/src/__tests__/integration.test.ts`)
- Full RBAC matrix (admin/analyst/support access)
- Error response security (no token/sensitive values)
- Request tracing (correlation ID propagation)
- Service configuration endpoint

### Layer 3: E2E Tests (Browser Testing)

**Playwright E2E Tests** (`frontend/src/__tests__/e2e.spec.ts`)
- Login & authentication flow
- Dashboard rendering and data display
- Navigation between main views
- System health status visibility
- Component error handling

### Layer 4: Frontend Unit Tests

**Component Tests** (`frontend/src/__tests__/App.smoke.test.tsx`)
- App component renders without crashing
- Layout structure and presence
- No console errors during render

## Running Tests

### API Tests

```bash
cd api

# All tests
npm test

# Smoke tests only (requires API running on 3001)
npm test:smoke

# Unit tests only (middleware, routes)
npm test:unit

# Integration tests (requires API running)
npm test:integration

# With coverage report
npm test:coverage
```

### Frontend Tests

```bash
cd frontend

# Unit + component tests
npm test

# Smoke tests only
npm test:smoke

# E2E tests (requires app running)
npm test:e2e

# E2E UI mode
npm test:e2e:ui

# With coverage report
npm test:coverage
```

## Coverage Thresholds

### API (Jest)

```json
{
  "global": {
    "branches": 50,
    "functions": 50,
    "lines": 50,
    "statements": 50
  }
}
```

**Excluded from coverage:**
- `src/server.ts` (entry point, integration tested)
- `src/mocks/**` (mock data generators)
- `src/__tests__/**` (test files)

### Frontend (Vitest)

```json
{
  "lines": 50,
  "functions": 50,
  "branches": 50,
  "statements": 50
}
```

**Excluded from coverage:**
- `src/__tests__/**` (test files)

## Test Execution Flow

### Local Development

```bash
# Terminal 1: Start all services
docker-compose up

# Terminal 2: Run API tests (requires API on 3001)
cd api && npm test

# Terminal 3: Run Frontend tests
cd frontend && npm test

# Terminal 4: Run E2E tests (requires frontend on 3000)
cd frontend && npm test:e2e
```

### CI/CD Pipeline (GitHub Actions)

Expected workflow:
1. Lint & format check
2. Build all packages (api, worker, frontend)
3. Run API unit tests (no dependencies)
4. Run Frontend unit tests (no dependencies)
5. Start services in background
6. Run API integration tests (requires API running)
7. Run E2E tests (requires frontend running)
8. Generate coverage reports
9. Fail if coverage drops below threshold

## Test File Structure

```
api/src/__tests__/
├── smoke.test.ts           # Health, auth, basic endpoints
├── integration.test.ts     # RBAC, security, tracing
├── middleware.test.ts      # Auth, correlation ID, logging
├── routes.test.ts          # Metrics, feedback, telemetry
└── helpers.ts              # Reusable utilities

frontend/src/__tests__/
├── App.smoke.test.tsx      # Component rendering
└── e2e.spec.ts             # Browser automation

frontend/
├── vitest.config.ts        # Vitest configuration
└── playwright.config.ts    # Playwright configuration
```

## Coverage Baseline (Phase 0 P2)

**Targets:**
- API: 50% coverage across all metrics (lines, branches, functions, statements)
- Frontend: 50% coverage on modified files
- E2E: Smoke test coverage only (no deep scenarios)

**Future Improvements:**
- Phase 1: Increase to 75% coverage
- Phase 2: Increase to 85%+ coverage
- Phase 3: Enforce coverage gates in CI/CD

## Mock Data Strategy

### API Mocks
- Mock tokens (admin/analyst/support) for auth testing
- Synthetic metrics data from `generateMockMetrics()`
- Random telemetry events for load testing
- Fixed feedback items for consistency

### Frontend Mocks
- Mock API responses via interceptors
- Browser local storage mocks
- Service worker mocks for offline scenarios

## CI/CD Integration

### GitHub Actions Workflow

```yaml
test:
  runs-on: ubuntu-latest
  services:
    redis:
      image: redis:7-alpine
      options: >-
        --health-cmd "redis-cli ping"
        --health-interval 10s
        --health-timeout 5s

  steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Build
      run: npm run build --workspaces
    
    - name: Test API
      run: cd api && npm test
    
    - name: Test Frontend
      run: cd frontend && npm test
    
    - name: E2E Tests
      run: cd frontend && npm test:e2e
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v3
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Cannot find module axios" | Run `npm install` in api/frontend |
| E2E tests fail with "Connection refused" | Ensure frontend running on 3000, API on 3001 |
| Coverage below threshold | Check `.ts` file exclusions in config |
| Tests timeout | Increase `testTimeout` in jest/vitest config |
| Module resolution errors | Verify `moduleResolution: bundler` in tsconfig |

## Test Maintenance

### Adding New Tests

1. Create test file in `src/__tests__/` with `.test.ts` or `.spec.ts`
2. Import test utilities and helpers
3. Group tests with `describe()` blocks
4. Verify test fails first (TDD)
5. Implement code to make test pass
6. Check coverage with `npm test:coverage`

### Updating Tests

- When API contract changes, update integration test expectations
- When UI components update, update component test selectors
- When adding new endpoints, add smoke + integration tests
- Never commit with skipped tests (`skip()` or `.only()`)

## Performance Baseline

**Target execution times:**
- Unit tests: <5 seconds (api + frontend combined)
- Integration tests: <30 seconds
- E2E tests: <60 seconds
- Full suite: <90 seconds

Monitor test execution time in CI/CD and flag regressions.
