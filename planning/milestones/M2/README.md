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
**Status:** In Progress (8/14 completed) — Last Updated: Jan 27, 2026

| Issue | Title | Status | PR | Completed |
|-------|-------|--------|----|-----------|
| [M2/030](030-set-up-build-pipelines-android-ios-on-tags.md) | Build pipelines (Android/iOS) | ⚠️ IN REVIEW | [#46](https://github.com/bakintunde/zerospoils/pull/46) | Tag triggered 2026-01-27 |
| [M2/100](100-local-storage-implementation-with-migrations.md) | Hive local storage for Items + migrations | ✅ DONE | [#44](https://github.com/bakintunde/zerospoils/pull/44) | Jan 24, 2026 |
| [M2/110](110-expiry-logic-library-grouping-rules.md) | Expiry bucketing algorithm | 🔄 IN PROGRESS | Local impl exists | ExpiryClassifier complete, 17 tests passing |
| [M2/120](120-local-notifications-service-schedule-reschedule.md) | Local notifications service | ✅ DONE | [#57](https://github.com/bakintunde/zerospoils/pull/57) | Jan 27, 2026 |
| [M2/140](140-mvp-add-item-screen-manual-entry.md) | Add Item screen (manual entry) | ✅ DONE | [#41](https://github.com/bakintunde/zerospoils/pull/41) | Jan 22, 2026 |
| [M2/142](142-expiry-date-ocr-on-device.md) | Expiry date OCR (on-device) | ⏳ TODO | — | Deferred to M3+ (complex, Pro tier) |
| [M2/145](145-onboarding-first-run-permissions-flow.md) | Onboarding + permissions | ⏳ TODO | — | Ready to start (M2/120 dependency) |
| [M2/150](150-mvp-inventory-list-screen-search-filter.md) | Inventory list screen (search/filter) | ✅ DONE | Implemented in M2/100 | Jan 24, 2026 |
| [M2/155](155-demo-mode-data-isolation-toggle-in-settings.md) | Demo mode DB isolation toggle | ⏳ TODO | — | Design in issue file |
| [M2/160](160-mvp-expiring-soon-screen-bucketed-view.md) | Expiring Soon screen (bucketed view) | ⏳ TODO | — | Design in issue file (depends on M2/110) |
| [M2/165](165-backup-restore-local-json-in-settings.md) | Backup/restore (local JSON) in Settings | 🔄 IN PROGRESS | Local impl exists | BackupRestoreService complete, 8 tests passing |
| [M2/170](170-mvp-item-detail-screen-mark-used-wasted.md) | Item detail screen (mark used/wasted) | ✅ DONE | Implemented locally | Jan 24, 2026 |
| [M2/180](180-inventory-view-modes-list-table-grid.md) | Inventory view modes (list/table/grid) | ⏳ TODO | — | Design in issue file |
| [M2/101](101-shopping-list-repository-persistence.md) | ShoppingList repository | ⏳ TODO | — | Deferred (post-MVP) |
| [M2/102](102-events-audit-log-persistence.md) | Events audit log repository | ⏳ TODO | — | Deferred (post-MVP) |

### 🔄 Hidden Implementations (Code Exists, Ready for PR)

**M2/110 (Expiry Bucketing Algorithm)**
- **File:** `app/lib/domain/utils/expiry_classifier.dart`
- **Tests:** 17/17 passing in `expiry_classifier_test.dart`
- **Implementation:**
  - `ExpiryClassifier.classify(item)` → returns `ExpiryBucket` (expired, today, thisWeek, later)
  - Date-only comparisons (no timezone issues)
  - Handles: null expiry, today detection, 1-7 day window, future dates
  - Edge cases: month boundaries, leap years, year rollover, DST transitions
- **Dependencies:** None (pure utility function)

**M2/165 (Backup & Restore Service)**
- **File:** `app/lib/data/services/backup_restore_service.dart`
- **Tests:** 8/8 passing in `backup_restore_service_test.dart`
- **Implementation:**
  - `backup()` → JSON with metadata (app version, schema version, timestamp)
  - `restore(file)` → validates schema, imports items, handles migrations
  - `RestorePreview` for pre-import validation
  - Metadata: backup_version, schema_version, appVersion, exportedAt
- **Dependencies:** Hive (for Item persistence)

---

### 🎯 Phase 1: Merge In-Progress Implementations (Days 1-3)
**Goal:** Get 3 more issues to "DONE" by merging existing code

1. **M2/110 (Expiry Bucketing)** — 17 tests passing, ready for PR
   - Impact: Unblocks M2/160 (Expiring Soon screen)
   - Effort: 30 min (review + merge)

2. **M2/165 (Backup/Restore)** — 8 tests passing, ready for PR
   - Impact: Settings get backup/restore functionality
   - Effort: 45 min (review + integrate)

3. **M2/030 (Build Pipelines - Code Signing)** — Workflows exist, docs in place
   - Impact: CI builds are reproducible for iOS/Android
   - Effort: 1 hour (setup secrets, document)

### 🚀 Phase 2: Start New Implementation (Days 4-7)
4. **M2/145 (Onboarding + Permissions)** — No blockers, design complete
   - Effort: 2-3 days
   - Impact: Users get proper onboarding experience + notification permissions flow

### 📊 Phase 3: Dependent Features (Days 8+)
5. **M2/160 (Expiring Soon Screen)** — Blocked by M2/110
   - Effort: 1-2 days (once M2/110 merged)
   - Impact: Users see expiring items bucketed by urgency

### 🔐 Deferred (Complex/Post-MVP)
- **M2/142 (OCR)** — On-device ML Kit OCR for expiry dates (Pro tier feature)
- **M2/101, M2/102** — ShoppingList and events audit (post-MVP)
- **M2/155, M2/180** — Demo mode and view modes (nice-to-have)

**Key tasks (issue files in this folder):**
- `030-set-up-build-pipelines-android-ios-on-tags.md` - CI/CD for iOS/Android builds
- `100-local-storage-implementation-with-migrations.md` - Hive/sqflite local database
- `110-expiry-logic-library-grouping-rules.md` - Expiry bucketing algorithm
- `120-local-notifications-service-schedule-reschedule.md` - Basic notification service
- `140-mvp-add-item-screen-manual-entry.md` - Add item bottom sheet
- `142-expiry-date-ocr-on-device.md` - ML Kit OCR for expiry dates (gated to Pro)
- `145-onboarding-first-run-permissions-flow.md` - First-run onboarding
- `150-mvp-inventory-list-screen-search-filter.md` - Inventory list view
- `155-demo-mode-data-isolation-toggle-in-settings.md` - Demo mode with separate DB
- `160-mvp-expiring-soon-screen-bucketed-view.md` - Expiring soon screen
- `165-backup-restore-local-json-in-settings.md` - Settings: backup/restore to JSON
- `170-mvp-item-detail-screen-mark-used-wasted.md` - Item detail screen
- `180-inventory-view-modes-list-table-grid.md` - Inventory view modes (list/table/grid)

