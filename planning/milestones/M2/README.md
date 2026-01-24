# Milestone M2 - Offline MVP (No Backend)

**Objective:** Deliver the first user-facing MVP as an offline-only Flutter app (no Supabase) with expiry tracking and local notifications.

**Scope:**
- Local-first inventory with persistence and migrations.
- Expiry bucketing (Today / 1–3 / 4–7 / Expired) and core inventory screens.
- On-device OCR for expiry dates (optional enhancement using ML Kit).
- Basic local notifications (schedule/reschedule/cancel on item changes).
- Build pipelines for iOS/Android.

**Explicit non-scope (deferred to M3+):**
- Reminder preferences UI and notification scheduling integration (M3).
- Shopping list features and item conversion workflow (M3).
- Offline-first verification suite, data export/delete, telemetry instrumentation (M3).
- Cloud sync, auth, Supabase, serverless functions (M6).
- Full receipt OCR, barcode scanning, batch photo capture (M6).
- Accessibility audit (M4), household sharing (M6), IoT integrations (M7).

**Acceptance:** Core flows work fully offline; notifications behave correctly across edits/restarts; all screens have empty/error states; test coverage exists per issue DoD.

## Progress
**Status:** In Progress (2/10 completed) — Last Updated: Jan 24, 2026

| Issue | Title | Status | PR | Completed |
|-------|-------|--------|----|-----------|
| [M2/100](100-local-storage-implementation-with-migrations.md) | Hive local storage for Items + migrations | ✅ DONE | [#44](https://github.com/bakintunde/zerospoils/pull/44) | Jan 24, 2026 |
| [M2/140](140-mvp-add-item-screen-manual-entry.md) | Add Item screen (manual entry) | ✅ DONE | [#41](https://github.com/bakintunde/zerospoils/pull/41) | Jan 22, 2026 |
| [M2/150](150-mvp-inventory-list-screen-search-filter.md) | Inventory list screen | ⏳ TODO | — | — |
| [M2/170](170-mvp-item-detail-screen-mark-used-wasted.md) | Item detail screen | ⏳ TODO | — | — |
| [M2/110](110-expiry-logic-library-grouping-rules.md) | Expiry bucketing algorithm | ⏳ TODO | — | — |
| [M2/120](120-local-notifications-service-schedule-reschedule.md) | Local notifications service | ⏳ TODO | — | — |
| [M2/142](142-expiry-date-ocr-on-device.md) | Expiry date OCR | ⏳ TODO | — | — |
| [M2/145](145-onboarding-first-run-permissions-flow.md) | Onboarding + permissions | ⏳ TODO | — | — |
| [M2/101](101-shopping-list-repository-persistence.md) | ShoppingList repository | ⏳ TODO | — | — |
| [M2/102](102-events-audit-log-persistence.md) | Events audit log repository | ⏳ TODO | — | — |

**Key tasks (issue files in this folder):**
- `030-set-up-build-pipelines-android-ios-on-tags.md` - CI/CD for iOS/Android builds
- `100-local-storage-implementation-with-migrations.md` - Hive/sqflite local database
- `110-expiry-logic-library-grouping-rules.md` - Expiry bucketing algorithm
- `120-local-notifications-service-schedule-reschedule.md` - Basic notification service
- `140-mvp-add-item-screen-manual-entry.md` - Add item bottom sheet
- `142-expiry-date-ocr-on-device.md` - ML Kit OCR for expiry dates
- `145-onboarding-first-run-permissions-flow.md` - First-run onboarding
- `150-mvp-inventory-list-screen-search-filter.md` - Inventory list view
- `160-mvp-expiring-soon-screen-bucketed-view.md` - Expiring soon screen
- `170-mvp-item-detail-screen-mark-used-wasted.md` - Item detail screen

