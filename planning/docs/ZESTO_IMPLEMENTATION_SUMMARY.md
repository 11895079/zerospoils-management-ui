# Zesto Mascot Implementation Plan — Summary & Next Steps

**Status:** Planning & Foundation (Hybrid Approach)  
**Date:** January 21, 2026  
**Target Milestone:** M3 (Issue 350)

---

## ✅ Completed This Session

### 1. **Spec Review & Refinement** (100%)
- Locked down all 10 Phase 1 triggers
- Finalized 5-6 message variations per trigger
- Educational angle for waste messages (storage tips)
- Anti-spam: 5-second minimum gap
- Message history: prevent last 3 messages from repeating
- JSON file for storage tips (20-30 tips across 10 categories)
- Free but unlockable mascots (save 50 items per category)
- Settings with "Milestones Only" as default frequency
- Contextual tap tips (page-specific)

**Reference:** `planning/docs/zesto-mascot-spec.md`

### 2. **Implementation Issues Created** (100%)
Five comprehensive issue specifications ready for GitHub:

| Issue | Milestone | Title | Size | Focus |
|-------|-----------|-------|------|-------|
| **350** | M3 | Zesto Phase 1: Core Triggers (10 Events) | L | Anti-spam, message history, 10 triggers, storage tips JSON, telemetry |
| **360** | M4 | Zesto Phase 2: Advanced Animations | M | Celebrate/shake/wave animations, rich tips UI, 6s display |
| **370** | M5 | Zesto Phase 3: Tap-to-Cycle Tips | S | User-initiated tip cycling, 3-5 contextual tips per page, dynamic data |
| **375** | M5 | Zesto Phase 3: Unlockable Mascots | M | 4 mascots (avocado, carrot, broccoli, bread), unlock progress bars, Settings UI |
| **380** | M5 | Zesto Phase 3: Settings Controls | S | Frequency toggle (Always/Milestones/Never), message type checkboxes |

**Location:** `planning/milestones/M{3,4,5}/`

### 3. **HTML Prototype (Reference Implementation)** (70%)

#### Created:
- **`prototype/data/storage_tips.json`** — 10 categories, 5 tips each (50 total storage tips)
  - Categories: dairy, produce, meat, bread, leftovers, condiments, beverages, snacks, frozen, general

#### Updated:
- **`prototype/index.html`** — Phase 1 trigger infrastructure
  - Expanded `mascotMessages` with 5-6 variations per trigger (10 trigger types)
  - Added anti-spam logic (5s minimum gap)
  - Added message history tracking (last 3 messages)
  - Added trigger handlers: `onItemAdded()`, `onItemConsumed()`, `onItemWasted()`
  - Storage tips integration from JSON file
  - Telemetry logging (console for now)

**Example Usage:**
```javascript
onItemAdded();          // Shows "Welcome! 🎉" if first item
onItemConsumed(item);   // Shows "Saved it! 🎉" or "Just in time! ⏰" (quick save)
onItemWasted(item);     // Shows storage tip (e.g., "💡 Store milk in back of fridge!")
```

### 4. **Flutter/Dart Foundation** (100%)

#### Created Domain Models:
- **`app/lib/domain/models/zesto_model.dart`** — 4 data classes
  - `MascotSettings`: User preferences (enabled, frequency, message type toggles)
  - `MascotUnlockProgress`: Achievement tracking (consumption by category, unlocked characters)
  - `ZestoState`: Current UI state (visible, message, animating)
  - `MascotMessageType`: Enum for 10 trigger types + special events

#### Created Service Layer:
- **`app/lib/domain/repositories/zesto_service.dart`** — Business logic
  - `showMascot(messageType)`: Main trigger method with anti-spam & frequency filtering
  - `_selectMessage()`: Message deduplication + storage tips integration
  - `_isMilestoneEvent()`: Frequency filtering logic
  - `_shouldShowMessageType()`: Message type filtering
  - Telemetry hooks (placeholder for integration)
  - State stream for reactive UI updates

#### Created Persistence Layer:
- **`app/lib/data/repositories/zesto_repository.dart`** — Local storage
  - `SharedPreferences` integration for settings & unlock progress
  - `getSettings()` / `saveSettings()`
  - `getUnlockProgress()` / `saveUnlockProgress()`
  - `addConsumption()` — Track category consumption + detect unlocks
  - `setActiveCharacter()` — Change active mascot
  - `clear()` — Reset for testing

---

## 📋 Next Steps (Implementation Sequence)

### **Phase 1: M3 — Core Triggers (Issue 350)**
**Timeline:** 2-3 weeks (depends on other M3 work)

1. **Integrate Zesto into Data Model**
   - Add category field to Item model (if not exists)
   - Wire `ZestoRepository` into DI container
   - Inject `ZestoService` into item management screens

2. **Implement Trigger Hooks**
   - Item consumed → call `showMascot('consumed')` with context
   - Item wasted → call `showMascot('wasted')` with itemCategory
   - First item added → check inventory.isEmpty before add
   - Badge unlocked → hook into badge system (issue 340)
   - Streak/savings milestones → calculate in progress service

3. **Create Zesto Widget**
   - `ZestoWidget` (Stateful) with stream listener
   - Displays character + bubble with message
   - Handles animation (appear/disappear with curves)
   - Auto-dismiss timer
   - Positioned absolutely (bottom-left, like HTML prototype)

4. **Load Storage Tips**
   - Add `storage_tips.json` to `assets/` folder
   - Create `StorageTipsService` to load & cache JSON
   - Integrate into `ZestoService._selectMessage()`
   - Dynamic tips based on item category

5. **Testing**
   - Unit tests: Anti-spam logic, message deduplication, frequency filtering
   - Widget tests: Mascot appears/disappears, message displays correctly
   - Integration tests: Full flow (consume item → mascot shown)
   - Manual testing: All 10 triggers on real/simulated device

6. **Telemetry**
   - Wire up `mascot_shown` event (messageType, page)
   - Wire up `mascot_dismissed` event (auto vs manual)
   - Track to telemetry service (integration with issue 040)

### **Phase 2: M4 — Advanced Animations (Issue 360)**
**Timeline:** 1 week (after Phase 1 merged)

1. Implement 4 animation states (celebrate, shake, wave, enhanced disappear)
2. Map triggers → animation states
3. Enhance storage tips UI (category icon, larger text, 6s display)
4. Add confetti trigger for celebrate animation
5. Accessibility: `prefers-reduced-motion` support

### **Phase 3: M5 — Tap Interaction & Customization (Issues 370, 375, 380)**
**Timeline:** 2 weeks (after Phase 1-2 merged)

1. **Tap-to-cycle tips** (370): Make mascot interactive, contextual tips per page
2. **Unlockable mascots** (375): Track consumption, unlock UI in Settings, character switching
3. **Settings controls** (380): Frequency toggle, message type filters, enable/disable

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│  UI Layer (Widgets)                     │
├─────────────────────────────────────────┤
│  ZestoWidget (displays state)           │
│  ZestoBubble (message + animation)      │
│  ZestoSettings (Settings section)       │
└────────────┬────────────────────────────┘
             │ streams
┌────────────▼────────────────────────────┐
│  Service Layer (Business Logic)         │
├─────────────────────────────────────────┤
│  ZestoService                           │
│  ├─ showMascot(type) - main trigger     │
│  ├─ Message selection + dedup           │
│  ├─ Frequency filtering                 │
│  └─ State management                    │
│                                         │
│  StorageTipsService                     │
│  └─ Load & cache JSON tips              │
└────────────┬────────────────────────────┘
             │ uses
┌────────────▼────────────────────────────┐
│  Data Layer (Persistence)               │
├─────────────────────────────────────────┤
│  ZestoRepository                        │
│  ├─ SharedPreferences integration       │
│  ├─ Settings persistence                │
│  ├─ Unlock progress tracking            │
│  └─ Active character management         │
│                                         │
│  assets/storage_tips.json               │
│  └─ 50 storage tips (10 categories)     │
└─────────────────────────────────────────┘
```

---

## 📁 File Locations

### Specification & Planning
- **Spec:** `planning/docs/zesto-mascot-spec.md`
- **Issues:** `planning/milestones/M{3,4,5}/35{0,60,70,75,80}-*`

### HTML Prototype (Reference)
- **Data:** `prototype/data/storage_tips.json` ✅
- **Code:** `prototype/index.html` (enhanced with Phase 1 logic) ✅

### Flutter/Dart (Real Implementation)
- **Models:** `app/lib/domain/models/zesto_model.dart` ✅
- **Service:** `app/lib/domain/repositories/zesto_service.dart` ✅
- **Repository:** `app/lib/data/repositories/zesto_repository.dart` ✅
- **Widgets:** `app/lib/presentation/screens/` (to be created in Phase 1)
- **Assets:** `app/assets/data/storage_tips.json` (copy from prototype)

---

## 🎯 Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| **Anti-spam** | 5-second minimum gap | Prevents spamming, allows time between events |
| **Message variety** | 5-6 variations per trigger | Prevents fatigue without bloating |
| **Default frequency** | "Milestones Only" | Balanced engagement (not intrusive for launch) |
| **Storage tips** | JSON file (not hardcoded) | Easy to update without code changes |
| **Mascots** | Free but unlockable | Drives engagement through gameplay, no paywall |
| **Tap interaction** | Contextual tips (not random facts) | More useful than fun facts |
| **Settings scope** | Phase 3 (M5) | Core triggers more important than preferences initially |

---

## 🧪 Testing Strategy

### Unit Tests (Zesto Service)
- Anti-spam prevents rapid messages ✓
- Message history prevents repeats ✓
- Frequency filtering works correctly ✓
- Message type filtering respects settings ✓
- Storage tips integrate with wasted items ✓

### Widget Tests (UI)
- Mascot appears when triggered ✓
- Mascot auto-dismisses after 3s ✓
- Message updates correctly ✓
- Animation plays smoothly ✓
- Mascot dismisses when settings disable ✓

### Integration Tests
- Full flow: Item consumed → mascot shown with correct message ✓
- Full flow: Storage tip shows on waste event ✓
- Full flow: Settings change disables mascot ✓

### Manual Testing (Device)
- Test on iOS simulator (iPhone SE)
- Test on Android emulator
- Verify performance (no jank)
- Verify sound effects (if added in Phase 2)

---

## 🚀 Rollout Plan

### Pre-Launch (M3)
1. Issue 350 merged with all Phase 1 triggers working
2. All automated tests passing (>80% coverage)
3. Manual smoke tests on 2+ devices
4. Telemetry baseline established

### Launch (M3 → M4)
1. Default "Milestones Only" frequency (conservative for launch)
2. Monitor telemetry: is mascot being dismissed?
3. Gather user feedback (in-app survey?)
4. Gather app store reviews for "mascot" mentions

### Post-Launch (M4)
1. Issue 360: Advanced animations (enhance delight)
2. Issue 380: Settings controls (respect user preferences)
3. Monitor disable rate and adjust based on feedback

### Advanced (M5)
1. Issue 370: Tap-to-cycle tips (deeper interaction)
2. Issue 375: Unlockable mascots (collection element)

---

## 💡 Open Questions

1. **Storage tips accuracy:** Should we validate tips against nutrition databases, or is crowd-sourced fine?
2. **Unlock thresholds:** Is 50 items reasonable, or should it vary by category?
3. **Multiple devices:** Should unlock progress sync to backend (Pro tier)?
4. **Localization:** Should mascot messages be translatable? (defer to M6+)
5. **Sound effects:** Should mascot have sound (optional, accessibility concern)?

---

## 📞 Hand-off to Development

This spec is **implementation-ready**. The Flutter foundation code is in place:
- ✅ Data models created
- ✅ Service logic written
- ✅ Repository pattern established
- ✅ HTML prototype working (reference)

**Next developer should:**
1. Create Zesto widgets (display layer)
2. Wire triggers into item/badge/progress services
3. Load storage_tips.json and integrate
4. Write tests
5. Deploy to issue 350

**Estimated effort:** 2-3 weeks (L size)

---

**Questions? Clarifications needed before Phase 1 implementation begins.**
