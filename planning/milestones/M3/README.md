# Milestone M3 — MVP Quality & Shopping

**Objective:** Complete MVP feature set with shopping list, quality assurance, telemetry instrumentation.

**Scope:**
- Reminder preferences and notification integration (180, 190, 200)
- Date format preference (205)
- Shopping list UI and conversion workflow (210, 220)
- Offline-first verification suite (230)
- Data export/delete for privacy baseline (240)
- Telemetry instrumentation for core funnel (250)
- Feature flags framework (130)
- Localization/i18n strategy (195 - optional)

**Acceptance:** All MVP screens complete; shopping list functional; offline suite passes; telemetry events logging; privacy baseline met; ready for beta distribution.

**Out of Scope:** Pro tier features (household sync, receipt OCR), IoT integrations, full recipe feature.

**Issues:** 130, 180, 190, 195, 200, 205, 210, 220, 230, 240, 250, 300, 350

**New M3 Features (Zesto Mascot - Phase 1):**
- **Issue 300:** Badge system (20 badges) — prerequisite for mascot unlocks
- **Issue 350:** Zesto Phase 1 (10 triggers, anti-spam, storage tips) — interactive mascot companion with educational content

**Dependencies:** M2 complete (core screens functional, build pipelines working).

---

## M3 Implementation Status

**Last Updated:** February 15, 2026 — **Progress:** 1/13 issues complete

### Issues & Completion

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| **130** | Feature flags framework (prepare for Pro) | ⏳ Not Started | No implementation detected in `app/` yet |
| **180** | Reminder preferences UI | ⏳ Not Started | Scheduled after M2 notifications integration |
| **190** | Notification scheduling integration | ⏳ Not Started | M2/120 partial; M3 integration pending |
| **195** | Localization/i18n strategy | ⏳ Not Started | Optional for M3 scope |
| **200** | Reminder interaction logging (local) | ⏳ Not Started | Depends on reminder UI/integration |
| **205** | Settings date format preference | ⏳ Not Started | No preference UI detected |
| **210** | Shopping list UI (Next Shop) | ⏳ Not Started | No UI surface detected |
| **220** | Convert purchased list items → inventory | ⏳ Not Started | No conversion flow detected |
| **230** | Offline-first verification suite | ⏳ Not Started | No verification suite in `app/test` |
| **240** | Data export/delete (privacy baseline) | ⏳ Not Started | No export/delete tooling detected |
| **250** | Telemetry instrumentation for core funnel | ⏳ Not Started | M1 telemetry baseline exists; M3 funnel not yet implemented |
| **300** | Accountability/achievement badges | ✅ Complete (Foundation) | Domain models + service + repository + tests (see `planning/M3_300_COMPLETION.md`) |
| **350** | Zesto Phase 1 core triggers | ⏳ Not Started | Depends on badge triggers and UI hooks |
