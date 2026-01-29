## Context
Reminders drive retention; they must be robust.

## Goal
Implement local notification scheduling for expiring items.

## Expected behavior
- Notifications scheduled on add
- Rescheduled on edit
- Cancelled when item resolved

## Acceptance criteria (Definition of Done)
- [ ] Permissions flow implemented (iOS/Android)
- [x] Android channels configured
- [x] Scheduling logic tested
- [x] Maps notification IDs to item IDs
- [x] Unit/widget/integration tests added or updated
- [x] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
 - Snooze/dismiss actions with deep links (defer to M3)
 - Preference UI for reminder timing/quiet hours (M3)
 - Cross-device sync of notifications (no backend in M2)
 - Rich push templates and categories beyond basics

## Implementation notes
 - Use `flutter_local_notifications` with timezone-aware scheduling (`timezone` package)
 - Derive schedule time from expiry bucketing (e.g., 9am local on day-before-expiry)
 - Maintain a mapping from `itemId -> notificationId` in repository for cancel/reschedule
 - Handle app restarts: rehydrate scheduled notifications from persisted state
 - Android: create channels (low/normal/high) for urgency; iOS: request provisional permissions when available
 - Respect Do Not Disturb/quiet hours (basic deferral, no UI yet)
 - Keep codebase modular (domain/data/ui layers)

## Test plan
  1.
  2.
 **Automated:**
 - Unit: schedule time calculation based on expiry date and bucket thresholds
 - Unit: reschedule on edit (date moved sooner/later) cancels previous and sets new
 - Unit: cancel on item resolved (used/wasted) removes scheduled notification
 - Unit: timezone correctness (America/NY vs Europe/London) yields expected local times
 - Integration: persist mapping `itemId -> notificationId` and restore after app restart
 - Integration: channel creation verified on Android; default categories used on iOS
 - Integration: multiple items scheduled; ensure no ID collisions
 - Telemetry: `notification_scheduled`, `notification_rescheduled`, `notification_cancelled` emitted with `item_id`, `schedule_time`, `reason`

 **Manual:**
 1. Enable notifications in onboarding; verify permission prompts (iOS + Android)
 2. Add item expiring tomorrow → receive notification at expected time
 3. Edit item to expire in 3 days → previous schedule cancelled; new schedule created
 4. Mark item as used/wasted → scheduled notification cancelled; none fires
 5. Restart app → previously scheduled notifications remain intact (verify after restart)
 6. Change device timezone → scheduled time shifts correctly to local time
 7. Android: verify channel name and importance; iOS: verify notification appears when app backgrounded
 8. Airplane mode/No network → notifications still fire (offline behavior)
 9. Quiet hours window (simulate) → schedule defers outside window
 10. Multiple items due same day → receive distinct notifications without clashes

## Dependencies
- None
