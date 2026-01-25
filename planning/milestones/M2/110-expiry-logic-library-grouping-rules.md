## Context
We need consistent grouping: expiring today/soon/expired.

## Goal
Implement a testable expiry classification library.

## Expected behavior
- Items classified into buckets based on today() and settings
- Timezone and date-only comparisons handled

## Acceptance criteria (Definition of Done)
- [ ] Unit tests cover boundary cases
- [ ] Buckets configurable (Today, 1–3, 4–7, Expired)
- [ ] Consistent behavior on iOS/Android
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Cloud sync or remote configuration of bucket thresholds
- UI for customizing bucket ranges (use hardcoded defaults)

## Implementation notes
- Create `ExpiryBucket` enum in domain/models/ (TODAY, THIS_WEEK, EXPIRED, LATER)
- Create `ExpiryClassifier` utility class in domain/utils/ with static method `classify(Item item) -> ExpiryBucket`
- Use date-only comparisons (no time component) to avoid timezone issues on device
- Bucket boundaries: TODAY (0-24hrs), THIS_WEEK (25hrs-7days), EXPIRED (< today), LATER (> 7days)
- Keep codebase modular (domain/data/ui layers)
- No dependency on Riverpod or UI framework; pure Dart logic

## Test plan

**Automated:**
- Unit test: Today bucket (expiry is today at any time)
- Unit test: Boundary 24-hour threshold (23:59 before today vs 00:00 after)
- Unit test: This Week bucket (1-7 days from today)
- Unit test: Expired bucket (past dates, including far past)
- Unit test: Later bucket (8+ days from today)
- Unit test: Null expiry date handling (returns LATER bucket)
- Unit test: Timezone consistency (same item should classify same way across timezones)
- Unit test: Leap year handling (Feb 28 → Mar 1)
- Unit test: Year boundary (Dec 31 → Jan 1)
- Unit test: Same-day edge case (item expires at 00:00, classify at 23:59)

**Manual:**
1. Fresh install; add item with today's expiry date → should appear in TODAY bucket on Expiring Soon screen
2. Add item expiring tomorrow → should appear in THIS_WEEK bucket
3. Add item expiring 7 days from now → should appear in THIS_WEEK bucket
4. Add item expiring 8 days from now → should NOT appear on Expiring Soon screen
5. Add item with no expiry date → should NOT appear on Expiring Soon screen
6. Add expired item (past date) → should appear in EXPIRED bucket
7. Restart app; items should remain in same buckets (persistence test)

## Dependencies
- None (pure Dart utility)
