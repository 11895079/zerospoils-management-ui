# What's Next to Build - ZeroSpoils Priority Roadmap

**Generated:** January 30, 2026  
**Status:** M1 Complete ✅ | M2 75% Complete 🟡 | M3 30% Complete 🟡

---

## Executive Summary

ZeroSpoils has a **solid foundation** with app skeleton, data models, storage, and basic UI screens. The next phase focuses on completing the **MVP feature set** and adding **engagement features** (Zesto mascot, badges, notifications) to drive user retention.

### Current State
- ✅ **M1 Complete:** App skeleton, routing, theming, DI, CI/CD, telemetry infrastructure
- 🟡 **M2 75% Complete:** Local storage (Hive), Add Item screen, Inventory List (partial)
- 🟡 **M3 30% Complete:** Badge system foundation (models + service logic)

### Critical Path Forward
**Priority 1 (Next 2-4 weeks):**
1. Complete M2 core screens (Inventory List verification, Item Detail, Expiring Soon)
2. Implement M3/300 Badge UI (Progress tab, share dialogs)
3. Implement M3/350 Zesto Phase 1 (mascot triggers)

**Priority 2 (4-8 weeks):**
4. Complete M2 notifications service
5. Implement M3 shopping list features
6. Add M3 reminders and telemetry instrumentation

---

## Priority 1: MVP Core Loop Completion (2-4 weeks)

These tasks complete the essential user flow: **Add Item → View in Inventory → See Details → Mark Used/Wasted → View Progress**

### 1.1 M2/150: Inventory List Screen Verification ⚠️ HIGH PRIORITY
**Status:** Implemented but needs verification  
**Effort:** 2-4 hours  
**Why:** Core screen that shows all items; search/filter crucial for usability

**Tasks:**
- [ ] Verify search functionality works correctly
- [ ] Verify filter by category/location/status works
- [ ] Test empty states and error handling
- [ ] Verify sorting (by expiry, by name, by date added)
- [ ] Add widget tests for search/filter
- [ ] Test performance with 100+ items

**Blocking:** Nothing (file exists: `app/lib/presentation/screens/inventory/inventory_list_screen.dart`)

**File Locations:**
- `app/lib/presentation/screens/inventory/inventory_list_screen.dart`
- `test/widget/inventory_list_screen_test.dart` (create)

---

### 1.2 M2/170: Item Detail Screen ⚠️ HIGH PRIORITY
**Status:** Partially implemented, needs completion  
**Effort:** 6-8 hours  
**Why:** Critical for mark-as-used/wasted workflow; completes core MVP loop

**Tasks:**
- [ ] Display full item details (all fields from Item model)
- [ ] "Mark as Used" button with confirmation
- [ ] "Mark as Wasted" button with waste reason selector
- [ ] Edit button → navigate to Edit Item screen
- [ ] Delete button with confirmation dialog
- [ ] Deep link integration test (zerospoils://item/{id})
- [ ] Telemetry: item_viewed, item_consumed, item_wasted events
- [ ] Widget tests for all actions

**Blocking:** Nothing (HiveItemRepository complete)

**File Locations:**
- `app/lib/presentation/screens/inventory/item_detail_screen.dart`
- `app/lib/presentation/screens/inventory/edit_item_screen.dart` (reuse Add Item form)
- `test/widget/item_detail_screen_test.dart` (create)
- `test/integration/deep_link_test.dart` (create)

---

### 1.3 M2/160: Expiring Soon Screen 🔵 MEDIUM PRIORITY
**Status:** Not started  
**Effort:** 8-10 hours  
**Why:** Key feature for waste prevention; helps users prioritize what to consume first

**Tasks:**
- [ ] Implement expiry bucketing logic (Today, 1-3 days, 4-7 days, Expired)
- [ ] Create bucket view UI (grouped list or tabs)
- [ ] Display items with days until expiry badge
- [ ] Quick actions: Mark as Used, Add to Shopping List
- [ ] Empty state when no expiring items
- [ ] Unit tests for bucketing algorithm
- [ ] Widget tests for bucket UI

**Blocking:** M2/110 (Expiry bucketing algorithm) - can implement inline or as separate service

**File Locations:**
- `app/lib/domain/services/expiry_service.dart` (create - bucketing logic)
- `app/lib/presentation/screens/expiring/expiring_soon_screen.dart`
- `test/unit/expiry_service_test.dart` (create)
- `test/widget/expiring_soon_screen_test.dart` (create)

---

### 1.4 M3/300: Badge UI Implementation 🟢 READY TO START
**Status:** Foundation complete (models + service + persistence), UI needs implementation  
**Effort:** 10-12 hours  
**Why:** Engagement feature; motivates users; prerequisite for Zesto mascot integration

**Tasks:**
- [ ] Create BadgeWidget (single badge display with earned/locked states)
- [ ] Create BadgesGridWidget (all 5 badges on Progress tab)
- [ ] Create BadgeDetailSheet (modal with description + share button)
- [ ] Create ShareBadgeDialog (copy text or generate shareable image)
- [ ] Add Progress tab to home navigation (5th tab)
- [ ] Implement badge check on item state changes (auto-earn)
- [ ] Toast notification when badge earned
- [ ] Wire BadgeRepository into Riverpod providers
- [ ] Add widget tests for all components
- [ ] Add telemetry: badge_earned, badge_shared events

**Blocking:** Nothing (M3/300 foundation complete)

**File Locations:**
- `app/lib/presentation/widgets/badge_widget.dart` (create)
- `app/lib/presentation/widgets/badges_grid_widget.dart` (create)
- `app/lib/presentation/screens/progress/progress_screen.dart` (create)
- `app/lib/presentation/providers/badge_provider.dart` (create - Riverpod state)
- `test/widget/badge_widget_test.dart` (create)
- `test/widget/progress_screen_test.dart` (create)

---

### 1.5 M3/350: Zesto Phase 1 (Mascot Triggers) 🟢 READY TO START
**Status:** Models complete, trigger logic needs implementation  
**Effort:** 12-16 hours  
**Why:** Differentiation feature; educational content; user engagement

**Tasks:**
- [ ] Implement ZestoTriggerService (10 core triggers)
- [ ] Wire badge unlock trigger (badgeUnlocked → show mascot)
- [ ] Implement itemAdded, itemExpiringSoon, itemWasted triggers
- [ ] Load storage tips from JSON (prototype/data/storage_tips.json)
- [ ] Show random storage tip based on item category
- [ ] Message deduplication logic (anti-spam, once per session)
- [ ] Create ZestoWidget (bottom sheet or overlay with mascot + message)
- [ ] Animations: idle, speaking, celebrating, encouraging (basic states)
- [ ] Unit tests for trigger conditions
- [ ] Widget tests for mascot UI

**Blocking:** M3/300 Badge UI (badge unlock trigger depends on badges)

**File Locations:**
- `app/lib/domain/services/zesto_trigger_service.dart` (create)
- `app/lib/presentation/widgets/zesto_widget.dart` (create)
- `app/lib/domain/repositories/zesto_service.dart` (already exists - enhance)
- `prototype/data/storage_tips.json` (already exists)
- `test/unit/zesto_trigger_service_test.dart` (create)
- `test/widget/zesto_widget_test.dart` (create)

---

## Priority 2: Feature Completeness (4-8 weeks)

These tasks complete the MVP feature set for beta launch.

### 2.1 M2/120: Local Notifications Service 🟡 PARTIAL
**Status:** Permissions flow pending  
**Effort:** 6-8 hours remaining  
**Why:** Critical for reminders; user retention feature

**Tasks:**
- [ ] Complete permissions request flow (iOS + Android)
- [ ] Test notification scheduling on device
- [ ] Implement reschedule on item update/delete
- [ ] Add notification settings in Settings screen
- [ ] Test notification behavior across app restarts
- [ ] Integration tests for notification flows

**Blocking:** Nothing (PR #57 merged, permissions pending)

---

### 2.2 M2/110: Expiry Bucketing Algorithm 🔵 MEDIUM
**Status:** Not started  
**Effort:** 4-6 hours  
**Why:** Foundation for Expiring Soon screen

**Tasks:**
- [ ] Create ExpiryService with bucket logic
- [ ] Define buckets: Today, 1-3 days, 4-7 days, Expired
- [ ] Unit tests for edge cases (no expiry date, past dates, null dates)
- [ ] Integration with Item model (isExpired, isExpiringSoon methods)

**Blocking:** Nothing (can implement standalone)

---

### 2.3 M3/210-220: Shopping List Features 🟢 MODELS READY
**Status:** ShoppingListItem model exists, UI not implemented  
**Effort:** 10-12 hours  
**Why:** MVP feature; user convenience

**Tasks:**
- [ ] Implement Shopping List screen (CRUD)
- [ ] Add "Add to Shopping List" from Inventory screen
- [ ] Implement "Convert to Inventory" flow (purchased items)
- [ ] Shopping list persistence (HiveShoppingListRepository)
- [ ] Share shopping list (read-only snapshot as text)
- [ ] Unit + widget tests

**Blocking:** M2/101 (ShoppingList repository) - can implement inline

---

### 2.4 M3/180-200: Reminders & Notification Integration 🟡 PARTIAL
**Status:** Notification service partially complete  
**Effort:** 8-10 hours  
**Why:** User retention feature; reduces waste

**Tasks:**
- [ ] Settings screen with notification preferences
- [ ] Reminder scheduling based on expiry dates
- [ ] "Remind me 1 day before expiry" toggle per item
- [ ] Notification interaction logging (opened, dismissed)
- [ ] Integration tests

**Blocking:** M2/120 (Notifications service) must be complete

---

### 2.5 M3/250: Telemetry Instrumentation 🔵 FOUNDATION READY
**Status:** Telemetry infrastructure complete, events need wiring  
**Effort:** 6-8 hours  
**Why:** Analytics; user behavior insights; product decisions

**Tasks:**
- [ ] Wire all screens to telemetry client
- [ ] Instrument core funnel: app_installed → item_added → item_viewed → item_consumed
- [ ] Add screen_viewed events for all screens
- [ ] Add interaction events (button_tapped, tab_switched, filter_applied)
- [ ] Verify events in local queue (Hive)
- [ ] Add tests for telemetry calls

**Blocking:** Nothing (telemetry client exists, schemas complete)

---

## Priority 3: Polish & Launch Prep (8-12 weeks)

### 3.1 M2/145: Onboarding + First-Run Flow 🟡 NOT STARTED
**Effort:** 6-8 hours  
**Tasks:** Welcome screens, permission requests, demo mode toggle

---

### 3.2 M2/155: Demo Mode Data Isolation 🟡 NOT STARTED
**Effort:** 4-6 hours  
**Tasks:** Toggle in Settings, separate Hive boxes, clear demo data

---

### 3.3 M2/165: Backup/Restore (Local JSON) 🟡 NOT STARTED
**Effort:** 6-8 hours  
**Tasks:** Export all data to JSON, import from JSON, settings UI

---

### 3.4 M3/130: Feature Flags Framework 🟡 NOT STARTED
**Effort:** 6-8 hours  
**Tasks:** FeatureFlag enum, toggle in Settings, gate Pro features

---

### 3.5 M3/230: Offline-First Verification Suite 🟡 NOT STARTED
**Effort:** 8-10 hours  
**Tasks:** Integration tests with mock connectivity, verify all flows work offline

---

### 3.6 M3/240: Data Export/Delete (Privacy) 🟡 NOT STARTED
**Effort:** 8-10 hours  
**Tasks:** GDPR/PIPEDA compliance, export all data, delete account + data

---

### 3.7 M4/165: Accessibility Audit 🟡 NOT STARTED
**Effort:** 10-12 hours  
**Tasks:** TalkBack/VoiceOver testing, contrast audit, keyboard navigation, WCAG 2.1 AA

---

## Recommended Implementation Sequence

### Week 1-2: Core Screens
1. **M2/150 Verification** (2-4h) - Verify inventory list works correctly
2. **M2/170 Item Detail** (6-8h) - Complete mark-as-used/wasted flows
3. **M2/160 Expiring Soon** (8-10h) - Implement bucket view

**Result:** Users can add items, view inventory, see expiring items, mark as used/wasted

---

### Week 3-4: Engagement Features
1. **M3/300 Badge UI** (10-12h) - Progress tab, badge widgets, share dialogs
2. **M3/350 Zesto Phase 1** (12-16h) - Mascot triggers, storage tips

**Result:** Gamification + educational features drive user engagement

---

### Week 5-6: Notifications & Shopping
1. **M2/120 Notifications** (6-8h) - Complete permissions flow
2. **M3/210-220 Shopping List** (10-12h) - CRUD + conversion workflow
3. **M3/180-200 Reminders** (8-10h) - Schedule notifications based on expiry

**Result:** Full reminder system + shopping list convenience

---

### Week 7-8: Telemetry & Polish
1. **M3/250 Telemetry** (6-8h) - Instrument all events
2. **M2/145 Onboarding** (6-8h) - First-run flow
3. **M2/155 Demo Mode** (4-6h) - Data isolation
4. **M2/165 Backup/Restore** (6-8h) - Export/import

**Result:** Analytics in place, onboarding ready, data portability

---

### Week 9-10: Quality & Compliance
1. **M3/130 Feature Flags** (6-8h) - Gate Pro features
2. **M3/230 Offline Suite** (8-10h) - Verify offline-first
3. **M3/240 Privacy** (8-10h) - Data export/delete
4. **M4/165 Accessibility** (10-12h) - Audit + fixes

**Result:** Production-ready for beta launch

---

## Blocking Dependencies Map

```
M1/090 (App Skeleton) ✅
    ├─> M2/100 (Hive Storage) ✅
    │       ├─> M2/140 (Add Item) ✅
    │       ├─> M2/150 (Inventory List) ⚠️ NEEDS VERIFICATION
    │       ├─> M2/170 (Item Detail) 🔴 BLOCKED BY VERIFICATION
    │       └─> M2/160 (Expiring Soon) 🔴 NEEDS M2/110
    │
    ├─> M3/300 (Badge Foundation) ✅
    │       ├─> M3/300 UI (Badge Widgets) 🟢 READY
    │       └─> M3/350 (Zesto Phase 1) 🟡 BLOCKED BY M3/300 UI
    │
    ├─> M2/120 (Notifications) 🟡 PARTIAL
    │       └─> M3/180-200 (Reminders) 🔴 BLOCKED
    │
    └─> M2/101 (Shopping Repo) 🔴 NOT STARTED
            └─> M3/210-220 (Shopping UI) 🔴 BLOCKED

Legend:
✅ Complete
🟢 Ready to start (no blockers)
🟡 Partial or in progress
⚠️ Needs review
🔴 Blocked by dependencies
```

---

## Risk Assessment

### High Risk (Address Immediately)
1. **M2/150 Inventory List** - Core screen, needs verification
2. **M2/170 Item Detail** - Completes MVP loop, high priority

### Medium Risk (Plan Carefully)
1. **M2/120 Notifications** - Platform-specific quirks (iOS/Android permissions)
2. **M3/350 Zesto** - Complex feature, needs careful UX testing
3. **M4/165 Accessibility** - Can uncover deep issues, plan buffer time

### Low Risk (Safe to Start)
1. **M3/300 Badge UI** - Models complete, UI is straightforward
2. **M3/250 Telemetry** - Infrastructure ready, just wiring needed
3. **M2/165 Backup/Restore** - Self-contained feature

---

## Effort Estimates Summary

| Phase | Total Hours | Priority | Status |
|-------|-------------|----------|--------|
| **Priority 1** (MVP Core) | 50-60h | P0 | Next 2-4 weeks |
| **Priority 2** (Features) | 40-50h | P1 | 4-8 weeks |
| **Priority 3** (Polish) | 48-64h | P2 | 8-12 weeks |
| **Total Remaining** | **138-174h** | — | ~12 weeks |

### Cumulative Hours Invested So Far
- Planning & Docs: ~40h ✅
- M1/090 Skeleton: ~20h ✅
- M2/100 Hive Storage: ~14h ✅
- M2/140 Add Item: ~8h ✅
- M3/300 Badge Foundation: ~8h ✅
- **Total to Date: ~90h**

### Total to MVP Beta Launch
- **Invested:** ~90h
- **Remaining:** ~138-174h
- **Total:** ~228-264h (11-13 weeks at 20h/week)

---

## Success Metrics (What Done Looks Like)

### MVP Core Loop (Priority 1)
- ✅ User can add item with all fields
- ✅ User can view inventory list with search/filter
- ✅ User can view item details
- ✅ User can mark item as used or wasted with reason
- ✅ User can see expiring items bucketed by days
- ✅ User can earn badges and see progress
- ✅ Zesto mascot appears with helpful tips

### Feature Completeness (Priority 2)
- ✅ Notifications scheduled for expiring items
- ✅ Shopping list with add/convert workflow
- ✅ Telemetry events firing on all screens
- ✅ Onboarding flow with permissions
- ✅ Backup/restore data to JSON

### Launch Ready (Priority 3)
- ✅ Feature flags gate Pro features
- ✅ All flows work offline
- ✅ Data export/delete implemented
- ✅ Accessibility audit complete (WCAG 2.1 AA)
- ✅ Zero critical bugs, minimal warnings

---

## Next Steps (This Week)

1. **Verify M2/150 Inventory List** (2-4 hours)
   - Run app, test search/filter/sort
   - Add widget tests if missing
   - Document any issues

2. **Implement M2/170 Item Detail** (6-8 hours)
   - Create ItemDetailScreen with all actions
   - Wire telemetry events
   - Add tests

3. **Start M3/300 Badge UI** (10-12 hours)
   - Create BadgeWidget and BadgesGrid
   - Add Progress tab to navigation
   - Wire badge checks to item changes

**Total: ~18-24 hours this week**

---

## References

- **M1 Status:** [planning/milestones/M1/README.md](planning/milestones/M1/README.md)
- **M2 Status:** [planning/milestones/M2/README.md](planning/milestones/M2/README.md)
- **M3 Status:** [planning/milestones/M3/README.md](planning/milestones/M3/README.md)
- **M1/090 Completion:** [planning/M1_090_COMPLETION.md](planning/M1_090_COMPLETION.md)
- **M3/300 Completion:** [planning/M3_300_COMPLETION.md](planning/M3_300_COMPLETION.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Questions or Blockers?

If you encounter blockers or have questions about priorities:
1. Check issue files in `planning/milestones/M2/` and `planning/milestones/M3/`
2. Review completion reports (M1_090_COMPLETION.md, M3_300_COMPLETION.md)
3. Check ARCHITECTURE.md for design patterns
4. See docs/code-patterns.md for practical examples

---

**Generated:** January 30, 2026  
**Status:** Living document, update as progress is made  
**Next Review:** After Priority 1 tasks complete (~2-4 weeks)
