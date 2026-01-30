# ZeroSpoils - Dependency Map & Critical Path

## Visual Dependency Tree

```
Legend: ✅ Complete | 🟢 Ready | 🟡 Partial | ⚠️ Needs Review | 🔴 Blocked

M1/090 Flutter App Skeleton ✅
    │
    ├─── M2/100 Hive Storage ✅
    │       │
    │       ├─── M2/140 Add Item Screen ✅
    │       │
    │       ├─── M2/150 Inventory List ⚠️ NEEDS VERIFICATION
    │       │       │
    │       │       └─── M2/170 Item Detail 🟡 BLOCKED
    │       │               │
    │       │               └─── Integration Test (deep link) 🔴
    │       │
    │       └─── M2/160 Expiring Soon 🔴 NEEDS M2/110
    │               │
    │               └─── M2/110 Expiry Bucketing 🟢 READY
    │
    ├─── M3/300 Badge Foundation ✅
    │       │
    │       ├─── M3/300 Badge UI 🟢 READY ⭐ START HERE
    │       │       │
    │       │       └─── M3/350 Zesto Phase 1 🟡 BLOCKED
    │       │               │
    │       │               └─── M3/360 Zesto Animations 🔴
    │       │
    │       └─── M3/310 Shareable Progress 🔴
    │
    ├─── M2/120 Notifications 🟡 PARTIAL (permissions pending)
    │       │
    │       └─── M3/180-200 Reminders 🔴 BLOCKED
    │
    ├─── M2/101 Shopping Repo 🔴 NOT STARTED
    │       │
    │       └─── M3/210-220 Shopping UI 🔴 BLOCKED
    │
    └─── Telemetry Infrastructure ✅
            │
            └─── M3/250 Instrumentation 🟢 READY
```

## Critical Path to MVP Beta

### Path 1: Core User Flow (HIGHEST PRIORITY)
```
M2/150 Verify ⚠️  (2-4h)
    ↓
M2/170 Item Detail 🟡 (6-8h)
    ↓
M2/160 Expiring Soon 🔴 (8-10h, needs M2/110)
    ↓
✅ Core MVP Loop Complete
```

**Why Critical:** Users can't complete core workflow without these screens

---

### Path 2: Engagement Features (HIGH PRIORITY)
```
M3/300 Badge UI 🟢 (10-12h) ⭐ READY TO START
    ↓
M3/350 Zesto Phase 1 🟡 (12-16h)
    ↓
✅ Gamification Complete
```

**Why Critical:** Differentiation feature; drives retention

---

### Path 3: Notifications (MEDIUM PRIORITY)
```
M2/120 Notifications 🟡 (6-8h, complete permissions)
    ↓
M3/180-200 Reminders 🔴 (8-10h)
    ↓
✅ Reminder System Complete
```

**Why Important:** User retention; reduces waste

---

### Path 4: Shopping List (MEDIUM PRIORITY)
```
M2/101 Shopping Repo 🔴 (4-6h)
    ↓
M3/210-220 Shopping UI 🔴 (10-12h)
    ↓
✅ Shopping List Complete
```

**Why Important:** Convenience feature; helps users plan

---

## Parallelization Opportunities

**Can be done in parallel:**
- M2/150 + M3/300 Badge UI (different developers)
- M2/170 + M3/250 Telemetry (different files)
- M2/110 + M2/120 Notifications (independent)

**Must be sequential:**
- M2/150 → M2/170 (item detail depends on list working)
- M3/300 UI → M3/350 Zesto (mascot depends on badges)
- M2/120 → M3/180-200 (reminders depend on notifications)

---

## Unblocking Tasks

### To Unblock M2/170 (Item Detail)
1. Verify M2/150 Inventory List works correctly
2. Fix any issues found in search/filter
3. Add missing tests

**Time:** 2-4 hours

---

### To Unblock M2/160 (Expiring Soon)
1. Implement M2/110 Expiry Bucketing algorithm
   - Can be inline or separate service
   - Unit tests required

**Time:** 4-6 hours

---

### To Unblock M3/350 (Zesto Phase 1)
1. Complete M3/300 Badge UI
   - BadgeWidget, BadgesGrid, Progress tab
   - Wire badge checks to item changes

**Time:** 10-12 hours

---

### To Unblock M3/180-200 (Reminders)
1. Complete M2/120 Notifications permissions flow
   - iOS permission dialog
   - Android notification channels
   - Test on devices

**Time:** 6-8 hours

---

### To Unblock M3/210-220 (Shopping List)
1. Implement M2/101 Shopping Repository
   - CRUD operations
   - Hive persistence
   - Unit tests

**Time:** 4-6 hours

---

## Risk Mitigation

### High Risk Tasks (Need Extra Time)
- **M2/170 Item Detail** - Complex UI, multiple flows
- **M3/350 Zesto Phase 1** - New feature, needs UX testing
- **M2/120 Notifications** - Platform-specific quirks

**Buffer:** Add 25% to time estimates for these

---

### Low Risk Tasks (Safe Estimates)
- **M2/150 Verification** - Just testing existing code
- **M3/300 Badge UI** - Models complete, straightforward UI
- **M3/250 Telemetry** - Infrastructure ready, just wiring

**Buffer:** Estimates are accurate

---

## Recommended Work Order (Optimal Sequence)

### Week 1
1. M2/150 Verify Inventory List (2-4h) ⚠️
2. M2/110 Expiry Bucketing (4-6h) 🟢
3. M2/170 Item Detail (6-8h) 🟡
4. M2/160 Expiring Soon (8-10h) 🔴

**Total:** ~20-28h | **Result:** Core MVP loop complete

---

### Week 2
1. M3/300 Badge UI (10-12h) 🟢 ⭐
2. M2/120 Notifications (6-8h) 🟡
3. M3/250 Telemetry (6-8h) 🟢

**Total:** ~22-28h | **Result:** Engagement + analytics ready

---

### Week 3
1. M3/350 Zesto Phase 1 (12-16h) 🟡
2. M2/101 Shopping Repo (4-6h) 🔴

**Total:** ~16-22h | **Result:** Mascot + shopping foundation

---

### Week 4
1. M3/210-220 Shopping UI (10-12h) 🔴
2. M3/180-200 Reminders (8-10h) 🔴

**Total:** ~18-22h | **Result:** Shopping list + reminders complete

---

## Success Metrics

After completing critical path (Weeks 1-2):
- ✅ User can add, view, and manage items
- ✅ User can see expiring items
- ✅ User can mark items as used/wasted
- ✅ User can earn badges and see progress
- ✅ Telemetry events firing on all screens

After completing full MVP (Weeks 3-4):
- ✅ Zesto mascot provides helpful tips
- ✅ Shopping list with conversion workflow
- ✅ Reminders scheduled for expiring items
- ✅ All core flows tested and polished

---

## Next Action

**START HERE:** M2/150 Inventory List Verification (2-4 hours)

This unblocks M2/170 Item Detail, which completes the core MVP loop.
