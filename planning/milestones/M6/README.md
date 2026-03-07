# Milestone M6 — Pro Tier Features

**Objective:** Launch subscription-based Pro tier with household sync, receipt OCR, advanced analytics, and batch photo capture.

**Backend Architecture:**
- **Supabase:** Pro tier backend database (PostgreSQL for relational queries, auth, RLS, real-time sync)
- **Firebase:** Mobile tooling only (Crashlytics, Remote Config, FCM — already integrated in M3)
- **Local DB:** Primary storage for offline-first (Hive/sqflite — continues from M3)

**Scope:**
- Subscription strategy and feature gating (410)
- In-app purchases (IAP) and entitlement storage (420)
- Receipt capture UX with consent messaging (430)
- OCR integration spike (accuracy, cost, latency) (440)
- Receipt parsing with normalized line items and confidence scoring (450)
- Receipt review UI: add to inventory with mapping rules (460)
- AI category inference for Pro item entry (510)
- Household accounts: auth + shared household model (470)
- Data sync settings toggle + status (475)
- Sync rules and conflict resolution (inventory + shopping list) (480)
- Advanced insights dashboard (money saved, items saved, trends) (490)
- Meal planning toggle in Settings (495)
- Consent model for aggregated analytics export (500)
- Full recipe suggestions feature (prioritize expiring items) (185)

**Acceptance:** Pro tier subscription working with IAP; receipt OCR functional; household sync operational; advanced analytics dashboard live; recipe suggestions recommending meals based on expiring items.

**Out of Scope:** IoT integrations (deferred to M7).

**Issues:** 185, 410, 420, 430, 440, 450, 460, 470, 475, 480, 490, 495, 500, 510

**Dependencies:** M5 complete (public launch successful, user base established).

---

## M6 Implementation Status

**Last Updated:** March 7, 2026 — **Progress:** 0/14 planned issues complete (0%)

### Issues & Completion

| Issue | Title | Status | PR | Notes |
|-------|-------|--------|----|-------|
| **185** | Full recipe suggestions (prioritize expiring items) | ⚠️ In Progress | — | Recipe suggestion artifacts exist, but full feature is not tracked complete in milestone status |
| **410** | Subscription strategy + feature gating | ⏳ Not Started | — | No end-to-end subscription launch implementation marked complete |
| **420** | In-app purchases (IAP) + entitlement storage | ⏳ Not Started | — | IAP pipeline not yet tracked complete |
| **430** | Receipt capture UX + consent messaging | ⚠️ In Progress | — | Receipt and batch-capture foundations exist; Pro-tier capture UX and consent workflow remain open |
| **440** | OCR integration spike (accuracy/cost/latency) | ⏳ Not Started | — | Spike report deliverable (`docs/pro/ocr-spike.md`) not present |
| **450** | Receipt parsing with normalized line items + confidence | ⚠️ In Progress | — | Parser/domain foundations exist; full confidence-scored Pro parsing workflow remains open |
| **460** | Receipt review UI + mapping rules | ⏳ Not Started | — | Pro review workflow completion not yet tracked |
| **470** | Household accounts + shared household model | ⏳ Not Started | — | Household auth/sync model not yet implemented |
| **475** | Data sync settings toggle + status | ⚠️ In Progress | — | Data Sync toggle row exists in Settings but is disabled (`Soon`) and not integrated with sync status |
| **480** | Sync rules + conflict resolution | ⏳ Not Started | — | Conflict resolution implementation not yet tracked |
| **490** | Advanced insights dashboard | ⏳ Not Started | — | Advanced Pro analytics dashboard not yet tracked |
| **495** | Meal planning toggle in Settings | ⚠️ In Progress | — | Meal Planning toggle row exists in Settings but is disabled (`Soon`) |
| **500** | Consent model for aggregated analytics export | ⚠️ In Progress | — | Analytics consent controls exist in Settings; full Pro consent/export model remains open |
| **510** | AI category inference (Pro) | ⏳ Not Started | — | AI inference path for Pro item entry is not yet tracked complete |

### Commentary

- M6 has several foundational signals in the codebase (auth, receipt primitives, settings placeholders), but no issue is fully closed to milestone DoD yet.
- Current state indicates architecture groundwork rather than delivered Pro-tier product readiness.
