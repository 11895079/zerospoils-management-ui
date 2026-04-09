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

**Out of Scope:** Pro tier features (household sync, receipt OCR), IoT integrations, full recipe feature. Firebase Firestore/Cloud Functions (using local Hive/sqflite for M3; Supabase for Pro tier in M6).

**Issues:** 130, 180, 190, 195, 196, 197, 198, 199, 200, 205, 206, 210, 220, 230, 240, 250, 300, 350, 360

**New M3 Features:**
- **Issue 300:** Badge system (20 badges) — prerequisite for mascot unlocks
- **Issue 350:** Zesto Phase 1 (10 triggers, anti-spam, storage tips) — interactive mascot companion with educational content
- **Issue 360:** Firebase integration (Crashlytics, Remote Config, FCM) — mobile tooling for crash reporting, feature flags, push notifications (Spark Plan free tier only)

**Dependencies:** M2 complete (core screens functional, build pipelines working).

---

## M3 Implementation Status

**Last Updated:** April 8, 2026 — **Progress:** 9/19 issues complete (47%)

### Issues & Completion

| Issue | Title | Status | PR | Notes |
|-------|-------|--------|----|----|
| **130** | Feature flags framework (prepare for Pro) | ⏳ Not Started | — | No implementation detected in `app/` yet |
| **180** | Reminder preferences UI | ✅ Complete | — | Master toggle + lead time (1/3/7 days) + sound/vibration; 10 tests (2 unit + 8 widget); telemetry integrated |
| **190** | Notification scheduling integration | ✅ Complete | — | Startup restore from persisted items + bulk reschedule/cancel helpers + preference-aware scheduling + tests |
| **195** | Localization/i18n strategy | ⏳ Not Started | — | Optional for M3 scope |
| **196** | Live expiry OCR multi-angle capture | ⏳ Not Started | — | Follow-up to issue 142 for live camera, auto-capture, haptics, and 5-angle capture reliability |
| **197** | Hybrid packaged-item fast add (barcode + expiry OCR) | ⏳ Not Started | — | Free-tier sub-10-second packaged-item flow using local barcode lookup plus expiry OCR |
| **198** | Shopping batch receipt capture | ⏳ Not Started | — | Free-tier shopping-batch metadata, single receipt photo attachment, item linking, and history views |
| **199** | Canada seed barcode catalog curation | ⏳ Not Started | — | Curated Canada-first packaged-product seed catalog artifact, attribution, size budget, and packaging workflow |
| **200** | Reminder interaction logging (local) | ✅ Complete | [#82](https://github.com/11895079/zerospoils/pull/82) | Notification tap handler + attribution store + telemetry; 14 tests; merged to main |
| **205** | Settings date format preference | ✅ Complete | [#77](https://github.com/11895079/zerospoils/pull/77) | DateFormatter utility + FutureProvider + telemetry (8/8 unit tests) |
| **206** | Downloadable reference-data update packs | ⏳ Not Started | — | Remote manifest plus validated update packs for barcode catalogs, categories, locations, and other app-managed lists |
| **210** | Shopping list UI (Next Shop) | ✅ Complete | [#76](https://github.com/11895079/zerospoils/pull/76) | ShoppingListScreen with add/delete; CRUD persists to SQLite |
| **220** | Convert purchased list items → inventory | ✅ Complete | [#76](https://github.com/11895079/zerospoils/pull/76) | Convert dialog with expiry date + optional location; telemetry tracking |
| **230** | Offline-first verification suite | ⏳ Not Started | — | No verification suite in `app/test` |
| **240** | Data export/delete (privacy baseline) | ✅ Complete | [#78](https://github.com/11895079/zerospoils/pull/78) | CSV/JSON export + delete-all with confirmation; BackupRestoreService; Settings → Privacy & Data section; telemetry events |
| **250** | Telemetry instrumentation for core funnel | ✅ Complete | [#81](https://github.com/11895079/zerospoils/pull/81) | Analytics consent toggle + schema validation + screen view events (22 new tests, 262/262 passing); merged |
| **300** | Accountability/achievement badges | ✅ Complete (Foundation) | — | Domain models (BadgeType, BadgeProgress) + BadgeService + tests; UI in progress_screen.dart |
| **350** | Zesto Phase 1 core triggers | ⏳ Not Started | — | Depends on badge triggers and UI hooks |
| **360** | Firebase integration (mobile tooling) | ⏳ Not Started | — | Crashlytics + Remote Config + FCM; implements M3/130 feature flags; Spark Plan (free tier) only |
