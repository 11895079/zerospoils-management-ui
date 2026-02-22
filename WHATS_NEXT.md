# What's Next to Build - ZeroSpoils Priority Roadmap

**Generated:** January 30, 2026 | **Last Updated:** February 21, 2026  
**Status:** M1 Complete ✅ | M2 82% Complete 🟡 | M3 38% Complete 🟡

---

## Executive Summary

ZeroSpoils has a **solid and growing foundation**: all core screens are implemented, data persistence (Hive), OCR, badge engine, shopping list, shopping-to-inventory conversion, date preferences, and privacy baseline (data export/delete) are all shipped. The next phase focuses on **completing MVP quality gates** — telemetry consent + instrumentation, offline verification, feature flags, and notification integration — to reach beta-launch readiness.

### Current State (Feb 21, 2026)
- ✅ **M1 Complete (10/10):** App skeleton, routing, theming, DI, CI/CD, telemetry infrastructure, docs
- 🟡 **M2 82% Complete (14/17):** Hive storage, Add Item, Inventory List, Item Detail, Expiring Soon, Notifications, OCR, Backup/Restore, Demo Mode (partial), Batch Receipt (partial); M2/030 build pipelines in review
- 🟡 **M3 38% Complete (5/13):** Shopping List (210, 220), Date Preference (205), Badge Foundation (300), **Data Export/Delete (240) ← just shipped**

### Recommended Next Issue: M3/250 — Telemetry Instrumentation for Core Funnel ⭐
The telemetry client, event schemas, and local sink already exist from M1. Most screens are already partially wired. What's missing is the **consent toggle** in Settings, **schema validation** in debug builds, and ensuring all core funnel events (`app_installed`, `onboarding_completed`, `item_added`, `item_consumed`, `item_wasted`, `inventory_viewed`, `expiring_viewed`, `shopping_item_added`, `shopping_converted`) fire with correct properties.

**Why this is the best next step:**
- Unblocks data-driven decisions for launch
- Infrastructure is 80% ready — effort is 6-8 hours (lowest effort, high value)
- No dependencies on incomplete features
- Directly enables measuring whether the MVP is solving the food waste problem

### After M3/250: Recommended Sequence
1. **M3/130 — Feature Flags** (6-8h): Gate Pro/cloud features; prerequisite for clean Pro upsell path; no dependencies
2. **M3/230 — Offline-First Verification Suite** (8-10h): Critical quality gate before beta; ensure all flows work without network
3. **M3/190 — Notification Scheduling Integration** (8-10h): Wire expiry-based reminders using the M2/120 service; depends on M2/120 being complete
4. **M3/180 + M3/200 — Reminder Preferences + Logging** (6-8h combined): UI for reminder prefs + tap-through logging; depends on M3/190
5. **M3/350 — Zesto Phase 1** (12-16h): Mascot triggers; depends on M3/300 badge UI

---

## Priority 1: Complete M3 Quality Gates (Current Focus)

These tasks close the remaining MVP quality gaps and unlock beta launch readiness.

### 1.1 M3/250: Telemetry Instrumentation for Core Funnel ⭐ NEXT BEST ISSUE
**Status:** Infrastructure ready (TelemetryClient + local Hive sink exist from M1); most screens partially wired; consent toggle + schema validation missing  
**Effort:** 6-8 hours  
**Why:** Enables data-driven product decisions; required for measuring user retention and funnel drop-off at launch

**Tasks:**
- [ ] Add "Share anonymous usage data" consent toggle to Settings → Privacy & Data
- [ ] Add `AnalyticsConsentProvider` (Riverpod) that gates all event emission
- [ ] Add schema validation in debug builds (reject events missing required fields, block PII keys)
- [ ] Wire `app_installed` + `onboarding_completed` events in `onboarding_screen.dart`
- [ ] Wire `tab_switched` event in `home_shell.dart` (currently missing telemetry)
- [ ] Confirm `item_added`, `item_edited`, `item_consumed`, `item_wasted` events fire with correct properties
- [ ] Confirm `inventory_viewed`, `expiring_viewed` screen events fire on navigation
- [ ] Confirm `shopping_item_added`, `shopping_item_purchased`, `shopping_converted` fire correctly
- [ ] Unit tests: each event emits required properties; PII keys are rejected
- [ ] Widget test: consent OFF → no events queued; consent ON → events queued

**Blocking:** Nothing (TelemetryClient, HiveEventRepository, and event schemas all exist)

**File Locations:**
- `app/lib/presentation/screens/settings_screen.dart` (add consent toggle)
- `app/lib/presentation/screens/home_shell.dart` (add tab_switched event)
- `app/lib/presentation/screens/onboarding_screen.dart` (add app_installed + onboarding_completed)
- `app/lib/presentation/di/service_locator.dart` (add AnalyticsConsentProvider)
- `app/test/unit/telemetry_instrumentation_test.dart` (create)

---

### 1.2 M3/130: Feature Flags Framework 🟢 READY TO START
**Status:** Not started  
**Effort:** 6-8 hours  
**Why:** Required to gate Pro/cloud features cleanly; prevents ad-hoc `if` checks from scattering through the codebase

**Tasks:**
- [ ] Define `FeatureFlagKey` enum with flags: `cloudSync`, `cloudAnalyticsExport`, `receiptOcr`, `batchPhotoCapture`, `householdSync`, `iotHooks`, `expiryDateOcr`
- [ ] Implement `FeatureFlags` service with precedence: local override > code default
- [ ] Persist local overrides via SharedPreferences
- [ ] Add Developer Settings screen (debug builds only) listing all flags with toggle UI
- [ ] Gate existing OCR entry method behind `expiryDateOcr` flag
- [ ] Gate cloud analytics export toggle behind `cloudAnalyticsExport` flag
- [ ] Create `docs/flags.md` with flag registry table
- [ ] Unit tests: precedence rules, default values, override persistence, reset behavior
- [ ] Widget test: Developer Settings renders all flags; reset restores defaults

**Blocking:** Nothing

---

### 1.3 M3/230: Offline-First Verification Suite 🟢 READY TO START
**Status:** Not started (no integration test suite for connectivity scenarios)  
**Effort:** 8-10 hours  
**Why:** Critical quality gate; must verify all core flows work without network before beta launch

**Tasks:**
- [ ] Create `test/integration/offline_suite_test.dart` with mock connectivity service
- [ ] Verify Add Item → persist to Hive → appears in Inventory List with no network
- [ ] Verify Expiring Soon screen loads from local DB offline
- [ ] Verify Shopping List CRUD works offline
- [ ] Verify Backup/Restore export works offline
- [ ] Verify telemetry events queue locally when offline (no crash)
- [ ] Verify app restores state correctly after simulated connectivity loss and restore
- [ ] Document results in planning/milestones/M3/README.md

**Blocking:** Nothing (ConnectivityService already wired via Riverpod)

---

## Priority 2: Notifications & Engagement (Next 4-6 weeks)

### 2.1 M3/190: Notification Scheduling Integration
**Status:** M2/120 notifications service shipped; M3 integration (expiry-based scheduling) pending  
**Effort:** 8-10 hours  
**Blocking:** M2/120 (complete ✅)

**Tasks:**
- [ ] Wire `NotificationsService.scheduleExpiryReminder()` when items are added/edited
- [ ] Cancel notifications when items are deleted or marked used/wasted
- [ ] Reschedule notifications on item expiry date change
- [ ] Integration test: add item → verify notification scheduled in Hive

---

### 2.2 M3/180 + M3/200: Reminder Preferences + Interaction Logging
**Status:** Not started; depends on M3/190  
**Effort:** 6-8 hours combined  
**Blocking:** M3/190

**Tasks:**
- [ ] Settings UI: "Remind me X days before expiry" (1/2/3/7 days selector per item or globally)
- [ ] Persist reminder preference via SharedPreferences
- [ ] Log notification tap-through events (`reminder_opened`) to HiveEventRepository

---

### 2.3 M3/350: Zesto Phase 1 (Mascot Triggers)
**Status:** Models + ZestoService exist; trigger logic and UI widget not implemented  
**Effort:** 12-16 hours  
**Blocking:** M3/300 Badge foundation (✅ complete — domain models, BadgeService)

**Tasks:**
- [ ] Implement ZestoTriggerService (10 core triggers: itemAdded, itemExpiringSoon, itemWasted, badgeUnlocked, etc.)
- [ ] Load storage tips from `prototype/data/storage_tips.json` (already exists)
- [ ] Message deduplication (anti-spam: once per session per trigger type)
- [ ] Create ZestoWidget (bottom sheet with mascot image + message + dismiss)
- [ ] Wire triggers into item state change callbacks (Riverpod notifiers)
- [ ] Unit tests for trigger conditions and deduplication logic
- [ ] Widget tests for ZestoWidget display

---

## Priority 3: Polish & Remaining M2 Gaps

### 3.1 M2/030: Build Pipelines (iOS/Android) — ⚠️ IN REVIEW
**Status:** PR #46 in review  
**Why:** Required for distributing builds to testers; blocks beta distribution

### 3.2 M2/155: Demo Mode Telemetry + Accessibility Polish
**Status:** Partial (UI implemented; `demo_mode_toggled` telemetry event missing; accessibility labels incomplete)  
**Effort:** 2-3 hours

### 3.3 M2/190: Batch Receipt Capture — Remaining Gaps
**Status:** Partial (core OCR and review flow implemented; Shopping List CTA entry point missing; permission recovery messaging incomplete)  
**Effort:** 3-5 hours

### 3.4 M3/195: Localization / i18n Strategy (Optional)
**Status:** Not started; optional for M3  
**Effort:** 8-12 hours  
**Why:** Deferred — English-only is acceptable for MVP beta

---

## Blocking Dependencies Map (Updated Feb 21, 2026)

```
M1/090 (App Skeleton) ✅
    ├─> M2/100 (Hive Storage) ✅
    │       ├─> M2/140 (Add Item) ✅
    │       ├─> M2/150 (Inventory List) ✅
    │       ├─> M2/170 (Item Detail) ✅
    │       └─> M2/160 (Expiring Soon) ✅
    │
    ├─> M3/300 (Badge Foundation) ✅
    │       └─> M3/350 (Zesto Phase 1) 🟢 READY (domain layer done)
    │
    ├─> M2/120 (Notifications) ✅
    │       └─> M3/190 (Notification Scheduling) 🟢 READY
    │               └─> M3/180+200 (Reminder Prefs + Logging) 🟡 BLOCKED by M3/190
    │
    ├─> M2/101 (Shopping Repo) ✅
    │       └─> M3/210+220 (Shopping List UI + Convert) ✅
    │
    ├─> M3/240 (Privacy: Export/Delete) ✅
    │       └─> M3/250 (Telemetry Consent) 🟢 READY (infrastructure complete)
    │
    └─> M3/130 (Feature Flags) 🟢 READY (no dependencies)

Legend:
✅ Complete
🟢 Ready to start (no blockers)
🟡 Partial or in progress
🔴 Blocked by dependencies
```

---

## Risk Assessment

### High Risk (Address Soon)
1. **M2/030 Build Pipelines** (in review) — blocks beta distribution to testers
2. **M3/190 Notification Scheduling** — platform-specific quirks (iOS/Android); must test on device

### Medium Risk (Plan Carefully)
1. **M3/350 Zesto** — complex trigger logic; needs careful anti-spam UX testing
2. **M4 Accessibility Audit** — can uncover deep issues; plan buffer time

### Low Risk (Safe to Start)
1. **M3/250 Telemetry** — infrastructure ready, consent toggle + schema validation is straightforward
2. **M3/130 Feature Flags** — clean enum + SharedPreferences, well-scoped
3. **M3/230 Offline Suite** — integration tests with mock connectivity service; no production risk

---

## Effort Estimates Summary (Feb 21, 2026)

| Phase | Remaining Issues | Est. Hours | Priority |
|-------|-----------------|-----------|---------|
| **M3 Quality Gates** (250, 130, 230) | 3 issues | 20-26h | P0 — Next |
| **M3 Notifications** (190, 180, 200) | 3 issues | 22-28h | P1 |
| **M3 Engagement** (350) | 1 issue | 12-16h | P1 |
| **M2 Gaps** (030, 155, 190) | 3 issues | 8-13h | P1 |
| **M3 Optional** (195) | 1 issue | 8-12h | P2 |
| **M4 Accessibility** | 1 issue | 10-12h | P2 |
| **Total Remaining** | **~12 items** | **~80-107h** | ~6-8 weeks |

### Cumulative Hours Invested So Far
- Planning & Docs: ~40h ✅
- M1/090 Skeleton: ~20h ✅
- M2/100 Hive Storage: ~14h ✅
- M2/140 Add Item: ~8h ✅
- M2 Core Screens + Notifications + OCR + Shopping: ~50h ✅
- M3/205 Date Preference: ~4h ✅
- M3/210+220 Shopping List + Convert: ~12h ✅
- M3/240 Data Export/Delete: ~10h ✅
- M3/300 Badge Foundation: ~8h ✅
- **Total to Date: ~166h**

### Total to MVP Beta Launch
- **Invested:** ~166h
- **Remaining:** ~80-107h
- **Total:** ~246-273h (4-6 weeks at 20h/week)

---

## Success Metrics (What Done Looks Like)

### MVP Core Loop ✅ All Complete
- ✅ User can add item with all fields (including OCR)
- ✅ User can view inventory list with search/filter
- ✅ User can view item details and mark as used/wasted
- ✅ User can see expiring items bucketed by days
- ✅ User can manage shopping list and convert items to inventory
- ✅ User can earn badges and see progress
- ✅ User can export and delete their data (privacy baseline)

### Quality Gates (M3 Remaining)
- [ ] Telemetry events fire on all core screens with consent controls (M3/250)
- [ ] Feature flags gate Pro/cloud features cleanly (M3/130)
- [ ] All flows verified working offline with integration tests (M3/230)
- [ ] Notifications scheduled based on expiry dates (M3/190)
- [ ] Reminder preferences UI in Settings (M3/180)

### Launch Ready
- [ ] Feature flags gate Pro features (M3/130)
- [ ] All flows work offline (M3/230)
- [ ] Accessibility audit complete — WCAG 2.1 AA (M4)
- ✅ Data export/delete implemented (M3/240)
- [ ] iOS/Android build pipelines green (M2/030)

---

## Next Steps (This Week, Feb 21, 2026)

1. **Implement M3/250 — Telemetry Instrumentation** ⭐ (6-8 hours)
   - Add consent toggle in Settings → Privacy & Data
   - Add schema validation in debug builds
   - Wire `app_installed`, `onboarding_completed`, `tab_switched` events (currently missing)
   - Confirm all core funnel events fire with required properties

2. **Implement M3/130 — Feature Flags** (6-8 hours)
   - Define `FeatureFlagKey` enum
   - Add `FeatureFlags` service with SharedPreferences persistence
   - Add Developer Settings screen (debug builds)
   - Gate existing `expiryDateOcr` and `cloudAnalyticsExport` features

3. **Implement M3/230 — Offline-First Verification Suite** (8-10 hours)
   - Create integration test suite with mock connectivity
   - Verify all core flows (Add Item, Inventory, Shopping, Export) work offline

**Total: ~20-26 hours**

---

## References

- **M1 Status:** [planning/milestones/M1/README.md](planning/milestones/M1/README.md)
- **M2 Status:** [planning/milestones/M2/README.md](planning/milestones/M2/README.md)
- **M3 Status:** [planning/milestones/M3/README.md](planning/milestones/M3/README.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Questions or Blockers?

If you encounter blockers or have questions about priorities:
1. Check issue files in `planning/milestones/M2/` and `planning/milestones/M3/`
2. Check ARCHITECTURE.md for design patterns
3. See docs/code-patterns.md for practical examples

---

**Generated:** January 30, 2026 | **Last Updated:** February 21, 2026  
**Status:** Living document, update as progress is made  
**Next Review:** After M3 quality gates complete (M3/250, M3/130, M3/230)
