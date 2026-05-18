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
- Full computer-vision batch photo capture (M6); shopping batch capture with optional receipt-photo attachment and barcode-assisted packaged-item fast add are deferred to M3. Receipt OCR remains separately feature-flagged and does not need to be Pro-only.
- Accessibility audit (M4), household sharing (M6), IoT integrations (M7).

**Acceptance:** Core flows work fully offline; notifications behave correctly across edits/restarts; all screens have empty/error states; test coverage exists per issue DoD.

## Progress
**Status:** Complete (17/17) — Last Updated: May 18, 2026

| Issue | Title | Status | PR | Completed |
|-------|-------|--------|----|-----------|
| [M2/030](030-set-up-build-pipelines-android-ios-on-tags.md) | Build pipelines (Android/iOS) | ✅ DONE | [#46](https://github.com/bakintunde/zerospoils/pull/46) | `build-android.yml`, `build-ios.yml`, `distribute-beta-android.yml`, `distribute-beta-ios.yml` all present and functional; Apple enrollment complete; TestFlight active |
| [M2/100](100-local-storage-implementation-with-migrations.md) | Hive local storage for Items + migrations | ✅ DONE | [#44](https://github.com/bakintunde/zerospoils/pull/44) | Jan 24, 2026 |
| [M2/101](101-shopping-list-repository-persistence.md) | ShoppingList repository | ✅ DONE | Implemented locally | Feb 12, 2026 |
| [M2/102](102-events-audit-log-persistence.md) | Events audit log repository | ✅ DONE | [#66](https://github.com/11895079/zerospoils/pull/66) | Feb 3, 2026 |
| [M2/110](110-expiry-logic-library-grouping-rules.md) | Expiry bucketing algorithm | ✅ DONE | Implemented locally | Jan 27, 2026 |
| [M2/120](120-local-notifications-service-schedule-reschedule.md) | Local notifications service | ✅ DONE | [#57](https://github.com/bakintunde/zerospoils/pull/57) | Jan 28, 2026 |
| [M2/140](140-mvp-add-item-screen-manual-entry.md) | Add Item screen (manual entry) | ✅ DONE | [#41](https://github.com/bakintunde/zerospoils/pull/41) | Jan 22, 2026 |
| [M2/142](142-expiry-date-ocr-on-device.md) | Expiry date OCR | ✅ DONE | [#113](https://github.com/11895079/zerospoils/pull/113) | May 17, 2026 (device-level integration coverage + telemetry aligned) |
| [M2/145](145-onboarding-first-run-permissions-flow.md) | Onboarding + permissions | ✅ DONE | [commit 7264c7d](https://github.com/bakintunde/zerospoils/commit/7264c7d) | Feb 3, 2026 |
| [M2/150](150-mvp-inventory-list-screen-search-filter.md) | Inventory list screen (search/filter) | ✅ DONE | Implemented in M2/100 | Jan 24, 2026 |
| [M2/155](155-demo-mode-data-isolation-toggle-in-settings.md) | Demo mode DB isolation toggle | ✅ DONE | [#114](https://github.com/11895079/zerospoils/pull/114) | May 18, 2026 (telemetry + accessibility complete) |
| [M2/160](160-mvp-expiring-soon-screen-bucketed-view.md) | Expiring Soon screen (bucketed view) | ✅ DONE | Implemented locally | Feb 12, 2026 (Accessibility pending) |
| [M2/165](165-backup-restore-local-json-in-settings.md) | Backup/restore (local JSON) in Settings | ✅ DONE | Implemented locally | Feb 12, 2026 (Accessibility pending) |
| [M2/170](170-mvp-item-detail-screen-mark-used-wasted.md) | Item detail screen (mark used/wasted) | ✅ DONE | Implemented locally | Jan 24, 2026 |
| [M2/180](180-inventory-view-modes-list-table-grid.md) | Inventory view modes (list/table/grid) | ✅ DONE | Implemented locally | Feb 15, 2026 (Accessibility pending) |
| [M2/185](185-user-defined-category-management-crud.md) | User-defined category management | ✅ DONE | Implemented locally | Feb 20, 2026 |
| [M2/190](190-batch-receipt-capture-mvp.md) | Batch receipt capture MVP | ✅ SUPERSEDED | [#71](https://github.com/11895079/zerospoils/pull/71), [#105](https://github.com/11895079/zerospoils/pull/105), [#106](https://github.com/11895079/zerospoils/pull/106) | Fully delivered by M3/198 — 5 dedicated screens (live scan, batch capture, review, detail, history); all M2/190 scope covered |

## Milestone Completion Summary
- All 17 issues complete or superseded by M3 work
- Core flows fully functional offline
- Notifications behave correctly across edits/restarts  
- All screens have empty/error states
- Test coverage per issue DoD
- Build pipelines fully operational (iOS/Android)
- Expiry OCR with telemetry integration complete
- Demo mode with telemetry and accessibility complete
- M2 is now ready for handoff to M3 auth and advanced features

## Next Priorities (M3 onwards)

**Recommended next:** M3 Authentication Work
- Email + password auth UI entry points
- Google Sign-In integration
- Apple Sign-In integration
- Estimated effort: 4-6 hours

**Secondary:** M3 Gaps
- M3/201: Receipt live scan (AR overlay, tri-color coding, hidden-lines)
- M3/202: Fresh produce recognition (confidence indicators, telemetry)
- M3/203: Haptic/sound settings (Settings section, per-scanner toggles)

