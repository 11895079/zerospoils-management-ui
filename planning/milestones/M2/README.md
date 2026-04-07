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
**Status:** In Progress (13/17 completed) — Last Updated: Apr 6, 2026

| Issue | Title | Status | PR | Completed |
|-------|-------|--------|----|-----------|
| [M2/030](030-set-up-build-pipelines-android-ios-on-tags.md) | Build pipelines (Android/iOS) | ⚠️ IN PROGRESS (split: Android now, iOS blocked) | [#46](https://github.com/bakintunde/zerospoils/pull/46) | Android/AAB + signing validation pending; iOS blocked by Apple enrollment |
| [M2/100](100-local-storage-implementation-with-migrations.md) | Hive local storage for Items + migrations | ✅ DONE | [#44](https://github.com/bakintunde/zerospoils/pull/44) | Jan 24, 2026 |
| [M2/101](101-shopping-list-repository-persistence.md) | ShoppingList repository | ✅ DONE | Implemented locally | Feb 12, 2026 |
| [M2/102](102-events-audit-log-persistence.md) | Events audit log repository | ✅ DONE | [#66](https://github.com/11895079/zerospoils/pull/66) | Feb 3, 2026 |
| [M2/110](110-expiry-logic-library-grouping-rules.md) | Expiry bucketing algorithm | ✅ DONE | Implemented locally | Jan 27, 2026 |
| [M2/120](120-local-notifications-service-schedule-reschedule.md) | Local notifications service | ✅ DONE | [#57](https://github.com/bakintunde/zerospoils/pull/57) | Jan 28, 2026 |
| [M2/140](140-mvp-add-item-screen-manual-entry.md) | Add Item screen (manual entry) | ✅ DONE | [#41](https://github.com/bakintunde/zerospoils/pull/41) | Jan 22, 2026 |
| [M2/142](142-expiry-date-ocr-on-device.md) | Expiry date OCR | ⚠️ PARTIAL | Implemented locally | Free-tier offline ML Kit flow, guidance prompt, and widget prefill coverage exist; dedicated device-level integration coverage still pending |
| [M2/145](145-onboarding-first-run-permissions-flow.md) | Onboarding + permissions | ✅ DONE | [commit 7264c7d](https://github.com/bakintunde/zerospoils/commit/7264c7d) | Feb 3, 2026 |
| [M2/150](150-mvp-inventory-list-screen-search-filter.md) | Inventory list screen (search/filter) | ✅ DONE | Implemented in M2/100 | Jan 24, 2026 |
| [M2/155](155-demo-mode-data-isolation-toggle-in-settings.md) | Demo mode DB isolation toggle | ⚠️ PARTIAL | Implemented locally | Feb 12, 2026 (Telemetry + accessibility pending) |
| [M2/160](160-mvp-expiring-soon-screen-bucketed-view.md) | Expiring Soon screen (bucketed view) | ✅ DONE | Implemented locally | Feb 12, 2026 (Accessibility pending) |
| [M2/165](165-backup-restore-local-json-in-settings.md) | Backup/restore (local JSON) in Settings | ✅ DONE | Implemented locally | Feb 12, 2026 (Accessibility pending) |
| [M2/170](170-mvp-item-detail-screen-mark-used-wasted.md) | Item detail screen (mark used/wasted) | ✅ DONE | Implemented locally | Jan 24, 2026 |
| [M2/180](180-inventory-view-modes-list-table-grid.md) | Inventory view modes (list/table/grid) | ✅ DONE | Implemented locally | Feb 15, 2026 (Accessibility pending) |
| [M2/185](185-user-defined-category-management-crud.md) | User-defined category management | ✅ DONE | Implemented locally | Feb 20, 2026 |
| [M2/190](190-batch-receipt-capture-mvp.md) | Batch receipt capture MVP | ⚠️ PARTIAL | [#71](https://github.com/11895079/zerospoils/pull/71) | Entry points + permissions gaps |

## Next Priorities

**Recommended next issue: M2/030 - Build Pipelines (Android first pass)**
- Complete Android release CI for signed APK + AAB artifacts on tag push
- Validate keystore secret decode and version/tag mismatch guard in CI
- Defer iOS signing validation until Apple Developer enrollment is active
- Estimated effort: 2-4 hours

**Secondary: M2/155 - Demo Mode DB Isolation Toggle**
- Add `demo_mode_toggled` telemetry + accessibility polish
- Important for analytics baseline and UX clarity
- Estimated effort: 2-3 hours

**Backlog (remaining M2 gaps):**
1. **M2/030** - Build pipelines (Android now; iOS after Apple enrollment)
2. **M2/155** - Demo mode telemetry + accessibility polish
3. **M2/190** - Batch receipt capture entry points + permissions

