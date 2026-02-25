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
