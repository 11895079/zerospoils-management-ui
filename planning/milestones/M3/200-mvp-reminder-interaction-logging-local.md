## Context
Reminders are a core value driver. We must measure whether reminders lead to action and be able to debug reminder behavior offline without relying on a backend.

## Goal
Log reminder interactions locally (and via the telemetry service) in a privacy-safe, offline-first way:
- When a reminder notification is opened
- When a user takes a follow-up action (consume/waste) after arriving from a reminder

## Expected behavior
- Tapping a reminder opens the relevant item detail (or expiring list) reliably.
- A `reminder_opened` event is recorded with the required properties from `docs/telemetry.md`.
- Follow-up actions can be attributed to “came from reminder” for funnel measurement.

## Acceptance criteria (Definition of Done)
- [ ] Notification payload includes a stable `item_id` and `lead_time_days` so taps can be attributed.
- [ ] On notification tap, route to the correct in-app destination and log `reminder_opened`.
- [ ] `reminder_opened` includes at least: `lead_time_days`, `time_of_day` ("morning" | "afternoon" | "evening"), plus standard properties.
- [ ] When an item is marked consumed/wasted from a reminder-entry flow, emit `item_consumed` / `item_wasted` with an attribution property (e.g., `source="reminder"`).
- [ ] Events are persisted locally (event log / DB) so they survive restarts and can be exported later.
- [ ] No PII is written to reminder event payloads.

## Out of scope
- Rich notification actions (buttons) unless explicitly planned elsewhere.
- Backend export of telemetry (handled later).

## Implementation notes
- Use the same event names and property keys defined in `docs/telemetry.md`.
- Attach reminder attribution to existing events (`item_marked_used`,
	`item_marked_wasted`) via `source="reminder"` to align with current code.
- Include a JSON `payload` in notification schedules with `item_id` and
	`lead_time_days`.
- Add `onDidReceiveNotificationResponse` handling to parse payload, emit
	`reminder_opened`, and route via GoRouter to `/item/:id` (fallback to
	expiring list if missing/invalid `item_id`).
- Add a small helper for `time_of_day` mapping (morning/afternoon/evening)
	to keep tests deterministic.

## Test plan
**Automated:**
- Unit test: payload parsing returns `item_id`, `lead_time_days`, and
	`time_of_day` for `reminder_opened`.
- Unit test: reminder context adds `source="reminder"` to
	`item_marked_used` / `item_marked_wasted` events.
- Integration test: simulate notification tap callback, verify
	`reminder_opened` enqueued and navigation targets the correct item.

**Manual:**
1. Add an item with reminders enabled; trigger/tap a reminder; confirm the
	 item detail opens.
2. Mark item consumed/wasted; confirm `source="reminder"` is present in the
	 telemetry event (via local debug telemetry log).
3. Edit item expiry and re-trigger reminder; confirm events continue to log
	 correctly offline.

## Dependencies
- `190-mvp-notification-scheduling-integration.md`
- `250-mvp-telemetry-instrumentation-for-core-funnel.md`
- `docs/telemetry.md`
