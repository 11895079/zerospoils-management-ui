# Milestone M3 — MVP Quality & Shopping

**Objective:** Complete MVP feature set with shopping list, quality assurance, telemetry instrumentation.

**Scope:**
- Reminder preferences and notification integration (180, 190, 200)
- Date format preference (205)
- Expiry OCR reliability, packaged-item fast add, and barcode/reference-data follow-up (196, 197, 199, 206)
- Shopping batch capture with receipt-photo attachment for free-tier add flows (198-shopping-batch-receipt-capture)
- Shopping list UI and conversion workflow (210, 220)
- Offline-first verification suite (230)
- Data export/delete for privacy baseline (240)
- Telemetry instrumentation for core funnel (250)
- Feature flags framework (130)
- Firebase integration for mobile tooling (360)
- Localization/i18n strategy (195 - optional)

**Acceptance:** All MVP screens complete; shopping list functional; offline suite passes; telemetry events logging; privacy baseline met; Firebase integrated for crashlytics/feature flags; ready for beta distribution.

**Out of Scope:** Pro tier features (household sync), IoT integrations, full recipe feature, and countertop/fridge goods-photo batch detection. Firebase Firestore/Cloud Functions (using local Hive/sqflite for M3; Supabase for Pro tier in M6).

**Issues:** 130, 180, 190, 195, 196, 197, 198, 199, 200, 201, 202, 205, 206, 210, 220, 230, 240, 250, 300, 350, 360, 361

**New M3 Features:**
- **Issue 201:** Receipt line-item extraction with AR overlay — excludes HST/GST/totals/card lines; live AR bounding boxes on viewfinder; text panel moved below camera
- **Issue 202:** Fresh produce packaged item recognition — identifies fish, meat, and deli sticker labels; extracts weight, price/kg, pack date, best-before without a separate scanner mode
- **Issue 300:** Badge system (20 badges) — prerequisite for mascot unlocks
- **Issue 350:** Zesto Phase 1 (10 triggers, anti-spam, storage tips) — interactive mascot companion with educational content
- **Issue 360:** Firebase integration (Crashlytics, Remote Config, FCM) — mobile tooling for crash reporting, feature flags, push notifications (Spark Plan free tier only)
- **Issue 361:** Firebase App Distribution — Tester API integration for beta build delivery and in-app tester feedback collection

**Dependencies:** M2 complete (core screens functional, build pipelines working).

---

## M3 Implementation Status

**Last Updated:** May 4, 2026 — **Progress:** 15/22 issues complete (68%); 3 issues reclassified from Not Started → Partial based on code audit

Note: M3 scope expanded by PR #97 to include three receipt/AR features (201, 202, 361); prior M3 work completed 13 issues; PR #96 added issue 360 (Firebase/FCM).

### Issues & Completion

| Issue | Title | Status | PR | Notes |
|-------|-------|--------|----|----|
| **130** | Feature flags framework (prepare for Pro) | ✅ Complete | — | `FeatureFlagsService` + Riverpod providers + Remote Config integration + local overrides via SharedPreferences; tests present |
| **180** | Reminder preferences UI | ✅ Complete | — | Master toggle + lead time (1/3/7 days) + sound/vibration; 10 tests (2 unit + 8 widget); telemetry integrated |
| **190** | Notification scheduling integration | ✅ Complete | — | Startup restore from persisted items + bulk reschedule/cancel helpers + preference-aware scheduling + tests |
| **195** | Localization/i18n strategy | ⏳ Not Started | — | Optional for M3 scope |
| **196** | Live expiry OCR multi-angle capture | ✅ Complete | — | `ExpiryOcrCaptureScreen` with live camera stream, auto-capture, haptic debounce, 5-photo cap, torch toggle, status panel moved outside camera viewport; `ExpiryOcrCaptureSession` unit tests |
| **197** | Hybrid packaged-item fast add (barcode + expiry OCR) | ✅ Complete | — | `PackagedItemFastAddScreen` with 7-stage flow (barcode → result/miss → pkg-label → expiry → locked → confirm); lookup precedence: learned→seed→manual; learned mapping saved on confirm; 9 widget tests + 7 barcode lookup unit tests |
| **198** | Shopping batch receipt capture | ✅ Complete | [#105](https://github.com/11895079/zerospoils/pull/105), [#106](https://github.com/11895079/zerospoils/pull/106) | Batch capture + review flows, retroactive linking, batch history/detail, payment method metadata, and inventory/item batch associations shipped |
| **199** | Canada seed barcode catalog curation | ✅ Complete | — | 3-tier lookup chain wired (learned → local seed → OFx live); v2 artifact (141 records); GTIN validation; runtime ingestion via `LocalBarcodeCatalog.fromAsset()` + providers; 477 tests pass |
| **200** | Reminder interaction logging (local) | ✅ Complete | [#82](https://github.com/11895079/zerospoils/pull/82) | Notification tap handler + attribution store + telemetry; 14 tests; merged to main |
| **201** | Receipt line-item extraction with AR overlay | ⚠️ Partial | — | `ReceiptLiveScanScreen` with live AR overlay (green boxes only), `ReceiptRowClassification` pipeline (tax/total/payment/etc.), `ReceiptParseResult` with `.rows`/`.acceptedRows`/`.rejectedRows`. Missing: tri-color AR coding (amber/grey for excluded lines), hidden-lines section in review screen, promote/demote UI for excluded rows |
| **202** | Fresh produce packaged item recognition | ⚠️ Partial | — | `FreshProduceOcrParser` fully implemented (fish/seafood/meat/deli, weight, price/kg, pack date, best-before), integrated in `PackagedItemFastAddScreen` (`packageLabelScan` stage). Missing: per-field confidence indicators on confirmation screen, fresh-produce-specific telemetry events |
| **205** | Settings date format preference | ✅ Complete | [#77](https://github.com/11895079/zerospoils/pull/77) | DateFormatter utility + FutureProvider + telemetry (8/8 unit tests) |
| **206** | Downloadable reference-data update packs | ⚠️ Stub Only | — | `LocalBarcodeCatalog` loads bundled `barcode_seed_ca.v2.json` from assets (design is update-pack compatible per docs). No remote manifest fetch, pack validation, atomic activation, or rollback implemented yet |
| **210** | Shopping list UI (Next Shop) | ✅ Complete | [#76](https://github.com/11895079/zerospoils/pull/76) | ShoppingListScreen with add/delete; CRUD persists to SQLite |
| **220** | Convert purchased list items → inventory | ✅ Complete | [#76](https://github.com/11895079/zerospoils/pull/76) | Convert dialog with expiry date + optional location; telemetry tracking |
| **230** | Offline-first verification suite | ✅ Complete | — | `test/unit/offline_first_verification_test.dart`: 5 groups covering item Hive persistence, shopping list Hive, barcode catalog (local-only), expiry parser (pure Dart), receipt parser (pure Dart); all tests verify no network dependency |
| **240** | Data export/delete (privacy baseline) | ✅ Complete | [#78](https://github.com/11895079/zerospoils/pull/78) | CSV/JSON export + delete-all with confirmation; BackupRestoreService; Settings → Privacy & Data section; telemetry events |
| **250** | Telemetry instrumentation for core funnel | ✅ Complete | [#81](https://github.com/11895079/zerospoils/pull/81) | Analytics consent toggle + schema validation + screen view events (22 new tests, 262/262 passing); merged |
| **300** | Accountability/achievement badges | ✅ Complete (Foundation) | — | Domain models (BadgeType, BadgeProgress) + BadgeService + tests; UI in progress_screen.dart |
| **350** | Zesto Phase 1 core triggers | ⏳ Not Started | — | Depends on badge triggers and UI hooks |
| **360** | Firebase integration (mobile tooling) | ✅ Complete | [#96](https://github.com/11895079/zerospoils/pull/96) | Crashlytics + Remote Config + FCM foreground/background handlers + permission request + device token + onMessageOpenedApp; all integrated in `firebase_bootstrap_service.dart` |
| **361** | Firebase App Distribution — Tester API | ⏳ Not Started | — | CI upload to App Distribution on beta tags; Tester SDK for in-app update checks and shake-to-feedback |
