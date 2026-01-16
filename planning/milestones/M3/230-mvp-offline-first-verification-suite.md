## Context
Offline-first is a core promise. We need an automated suite that prevents regressions (accidental network dependence, broken persistence, reminder failures) as features grow.

## Goal
Create an offline-first verification suite (automated + manual checklist) that validates core MVP flows with *no network available* and across app restarts.

## Expected behavior
- Tests fail if the app attempts outbound network calls during offline MVP flows.
- Core flows continue to work: inventory CRUD, expiry buckets, reminders, shopping list, export/delete.
- Persistence is verified across restarts.

## Acceptance criteria (Definition of Done)
- [ ] Add at least one automated integration test file (e.g., `integration_test/offline_mvp_flows_test.dart`) that:
  - [ ] Forces “no network” by overriding HTTP/socket creation (fail-fast if any network call occurs).
  - [ ] Adds an item, verifies it appears in inventory and correct expiry bucket.
  - [ ] Edits expiry date, verifies bucket changes.
  - [ ] Verifies reminder scheduling/rescheduling/cancel behavior via the app’s notification abstraction (use a fake scheduler in tests).
  - [ ] Marks item consumed/wasted and verifies it no longer appears and reminders are canceled.
  - [ ] Runs export/delete and verifies data is exported then wiped.
- [ ] Wire the suite into CI (run on PR as part of the test job).
- [ ] Create `docs/qa/offline-first-checklist.md` with device-level manual steps (airplane mode, restart, notification tap).

## Out of scope
- Load/performance testing at scale.
- Cloud sync verification (later milestone).

## Implementation notes
- Prefer fakes over waiting for real notifications in automated tests.
- Keep tests deterministic: fixed clock/timezone where possible to validate date boundaries.

## Test plan
**Automated:**
- CI executes the offline suite and fails on any network attempt.

**Manual:**
1. Enable airplane mode.
2. Add/edit/consume/waste items; verify expiry buckets update.
3. Restart the app; verify data persists.
4. Confirm reminders still trigger/tap-through to correct item when offline.

## Dependencies
- `100-local-storage-implementation-with-migrations.md`
- `110-expiry-logic-library-grouping-rules.md`
- `120-local-notifications-service-schedule-reschedule.md`
- `190-mvp-notification-scheduling-integration.md`
- `210-mvp-shopping-list-ui-next-shop.md`
- `240-mvp-data-export-delete-privacy-baseline.md`
