# Test Foundation - Phase 0 P1

This directory contains the test infrastructure bootstrap for the ZeroSpoils Management UI.

## Structure

```
api/src/__tests__/
├── smoke.test.ts       # Basic API endpoint validation
├── integration.test.ts # RBAC, error handling, tracing tests
└── helpers.ts          # Shared test utilities (auth client, config, waiters)

frontend/src/__tests__/
└── App.smoke.test.tsx  # Component rendering smoke test
```

## Running Tests

### API Tests

```bash
cd api

# Install dependencies
npm install

# Run all API tests
npm test

# Run smoke tests only
npm test:smoke

# Run integration tests only  
npm test:integration

# Run with coverage
npm test -- --coverage
```

### Frontend Tests

```bash
cd frontend

# Install dependencies
npm install

# Run all frontend tests
npm test

# Run smoke tests only
npm test:smoke

# Run in UI mode
npm run test -- --ui
```

## Test Requirements

### Running Tests Locally

**Prerequisites:**
- API must be running on `http://localhost:3001`
- Worker can be running (health check validates independently)

```bash
# Terminal 1: Start services
docker-compose up

# Terminal 2: Run API tests
cd api && npm test

# Terminal 3: Run frontend tests (after npm run build in frontend/)
cd frontend && npm test
```

### Automated Tests (CI/CD)

Tests are designed to run in CI environments with services available:
- Smoke tests verify health endpoints (no auth required)
- Integration tests verify RBAC and security (use mock tokens)
- Frontend tests render components in jsdom

## Test Coverage

**Phase 0 P1 Baseline Coverage:**

- ✅ Health endpoints (200 status, required fields)
- ✅ Authentication middleware (401 without token, 200 with valid token)
- ✅ Correlation ID tracing (present in all responses)
- ✅ Error responses (no sensitive info leakage)
- ✅ RBAC matrix (admin/analyst/support token validation)
- ✅ Component rendering (App mounts without errors)

**Gap Areas (Future PRs):**
- Unit tests for data generators (mocks/data.ts)
- Integration tests for worker job processing
- E2E tests for complete user workflows
- Performance benchmarks for API endpoints
- Widget tests for UI interactions (forms, navigation)

## Test Configuration

### API (Jest + ts-jest)

Configuration: `api/jest.config.json`
- Preset: `ts-jest` (TypeScript support)
- Test Environment: `node`
- Test Match: `src/__tests__/**/*.test.ts`
- Timeout: 10 seconds per test

### Frontend (Vitest + jsdom)

Configuration: `frontend/vitest.config.ts`
- Test Framework: Vitest (Vite-native)
- Environment: jsdom (browser simulation)
- Test Include: `src/**/*.{test,spec}.{ts,tsx}`

## Mock Tokens for Testing

Tests use mock bearer tokens defined in `api/src/mocks/data.ts`:

```
admin:    Bearer token_admin_abc123
analyst:  Bearer token_analyst_xyz789
support:  Bearer token_support_def456
```

These are hardcoded for local testing only. Production authentication will use Supabase Auth (Issue 710).

## Continuous Integration

CI workflows should:
1. Build all packages (`npm run build`)
2. Run linting (`npm run lint`)
3. Run all tests (`npm test`)
4. Upload coverage reports
5. Fail on test failures or coverage drops

## Common Issues

| Issue | Solution |
|-------|----------|
| "ECONNREFUSED" in API tests | Ensure API is running on port 3001 |
| "Cannot find module" in tests | Run `npm install` and `npm run build` |
| Timeout errors | Increase test timeout or check API response time |
| Import errors in vitest | Ensure `vitest.config.ts` is properly configured |

## Next Steps

- **Phase 0 P2**: Add unit tests for API routes and middleware
- **Phase 1**: Add feature tests for analytics, feedback, telemetry flows
- **Phase 2**: Add E2E tests with Playwright for user workflows
- **Ongoing**: Maintain ≥80% code coverage for modified files
