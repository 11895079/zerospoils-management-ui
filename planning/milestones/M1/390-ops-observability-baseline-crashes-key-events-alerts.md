## Context
Post-launch, you need early-warning signals for crashes and critical flow breaks.

## Goal
Implement basic observability and alerting for core user journeys.

## Expected behavior
- Crashes and critical errors are visible within 24h
- Alerts trigger on regressions

## Acceptance criteria (Definition of Done)
- [ ] Define SLO-lite metrics: crash-free sessions, app start failures, reminder delivery failures
- [ ] Set up alerts for spikes/drops (best-effort depending on tooling)
- [ ] Document dashboards and alert ownership in `docs/ops/observability.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full distributed tracing (not needed early).

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
**Automated:**
- Verify `docs/ops/observability.md` contains SLO definitions and alert configurations
- Script validates dashboard config files (if applicable) parse correctly

**Manual:**
1. Trigger test crash and verify it appears in dashboard within 24h
2. Simulate app start failure and confirm alert fires
3. Review SLO metrics with ops team (crash-free sessions target, e.g., 99.5%)
4. Verify alert ownership documented (who gets paged)
5. Test runbook steps for common alerts

## Dependencies
- Crash reporting integrated (from Beta)