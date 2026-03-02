## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver notification scheduling integration that keeps item expiry notifications correct across create/update/delete flows and app restart, with tests and telemetry.

## Expected behavior
- Items with expiry dates schedule local notifications at configured lead time
- Updating an item's expiry date reschedules its notification
- Removing expiry date or deleting item cancels its notification
- App startup restores scheduled notifications from persisted items
- Scheduling respects preferences (master toggle, lead time, sound, vibration)
- Works offline without requiring login

## Acceptance criteria (Definition of Done)
- [x] Item create/update/delete notification flows integrated in repository layer
- [x] Expiry-date updates reschedule notifications; clearing expiry cancels notifications
- [x] App startup restores scheduled notifications from persisted items
- [x] Scheduling respects preferences (master toggle, lead time, sound, vibration)
- [x] Telemetry events emitted for scheduling operations
- [x] Unit/widget/integration tests added or updated
- [x] Offline-first behavior verified (no backend dependency)

## Out of scope
- Cloud sync
- Receipt scanning
- Household sharing

## Implementation notes
- Follow design tokens in theme.
- Keep domain/data/ui separation.
- Repository integration is implemented in `HiveItemRepository.saveItem()` and `deleteItem()`.
- Startup restoration is implemented in `main.dart` init flow via `NotificationService.restoreScheduled(items: ...)`.
- `NotificationService` now supports:
  - `scheduleForItem`, `rescheduleForItem`, `cancelForItem`
  - `cancelAllNotifications`, `rescheduleAllNotifications`, `restoreScheduled`
- Notification IDs are parsed safely from persisted string IDs (numeric IDs schedule; non-numeric IDs are skipped).

## Test plan
**Automated:**
- Unit test: schedule/reschedule/cancel flows for single items
- Unit test: `rescheduleAllNotifications` honors enabled/disabled + lead time
- Unit test: `restoreScheduled` restores notifications on startup and skips invalid items
- Widget test: Settings preference changes trigger reschedule behavior path

**Manual:**
1. Add item with expiry date; verify notification appears in scheduled list
2. Edit same item expiry date; verify scheduled time changes
3. Clear expiry date and delete item; verify notification canceled
4. Restart app; verify notifications are restored from persisted items
5. Toggle notifications OFF in Settings; verify no notifications are scheduled

## Dependencies
- None
