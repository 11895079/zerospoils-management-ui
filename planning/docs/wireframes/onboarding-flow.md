# Wireframe: Onboarding Flow (First-Time User Experience)

## Purpose
Educate new users on the app's core value (reducing food waste, saving money, better organization) and guide them through the three main user workflows with clear visual examples. **Key goal: Clarify shopping list → inventory conversion flow.**

## Overall Flow

```
App Launch
    ↓
┌─ Splash Screen (Welcome)
├─ Screen 1: Problem (Why we built this)
├─ Screen 2: Solution (What the app does)
├─ Screen 3: Workflow A - Inventory Management
├─ Screen 4: Workflow B - Shopping → Inventory (KEY CLARIFICATION)
├─ Screen 5: Workflow C - Reduce Waste
├─ Screen 6: Permissions Request (Camera for OCR)
├─ Screen 7: Get Started (First real action)
    ↓
Main App (with first-action guidance)
```

---

## Onboarding Screens

### Screen 1: Splash / Welcome

```
┌─────────────────────────────────┐
│                                 │
│         🌱 ZeroSpoils          │ ← Logo/wordmark
│                                 │
│    Reduce Food Waste.           │ ← Tagline
│    Save Money.                  │
│    Organize Your Kitchen.       │
│                                 │
│                                 │
│  ┌─────────────────────────────┤
│  │    Let's Get Started        │ │ ← CTA button
│  └─────────────────────────────┘│
│                                 │
│              Skip >>            │ ← Optional skip
│                                 │
└─────────────────────────────────┘
```

### Screen 2: The Problem

```
┌─────────────────────────────────┐
│     ← Back              Skip >> │ ← Navigation
├─────────────────────────────────┤
│                                 │
│         🗑️ 1/6                  │ ← Progress indicator
│                                 │
│    Did you know?                │
│                                 │
│  ~30% of groceries end up      │
│  in the trash. That's money,   │
│  time, and resources wasted.   │
│                                 │
│  Ever forgotten what you have  │
│  in the fridge? Or bought      │
│  something you already have?   │
│                                 │
│  We've all been there.         │
│                                 │
│  ┌─────────────────────────────┤
│  │    Next                     │ │ ← CTA
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Screen 3: The Solution

```
┌─────────────────────────────────┐
│     ← Back              Skip >> │
├─────────────────────────────────┤
│                                 │
│         💡 2/6                  │
│                                 │
│    ZeroSpoils helps you:       │
│                                 │
│  ✓ Track all your food        │
│    (what you have, when it    │
│     expires)                   │
│                                 │
│  ✓ Plan your shopping smarter  │
│    (avoid buying duplicates)   │
│                                 │
│  ✓ Reduce waste proactively    │
│    (eat items before they      │
│     expire)                    │
│                                 │
│  Result: Save $, reduce waste, │
│  better organized kitchen 🎉   │
│                                 │
│  ┌─────────────────────────────┤
│  │    Next                     │ │
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Screen 4: Workflow A - Add & Track Inventory

```
┌─────────────────────────────────┐
│     ← Back              Skip >> │
├─────────────────────────────────┤
│                                 │
│      📦 Inventory 3/6           │
│                                 │
│  Step 1: Add items you buy    │
│                                 │
│    You brought home milk?      │
│    Add it with expiry date.    │
│    (Tap the + button)          │
│                                 │
│    📦 → 🥛 Milk (Jan 15)       │
│                                 │
│  Step 2: Check what's expiring │
│                                 │
│    The "Expiring Soon" tab     │
│    shows what you should eat   │
│    first. Don't let food spoil!│
│                                 │
│    ⏰ → 🥛 Milk (Today!)       │
│                                 │
│  ┌─────────────────────────────┤
│  │    Next                     │ │
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Screen 5: Workflow B - Shopping List → Inventory (KEY CLARIFICATION)

```
┌─────────────────────────────────┐
│     ← Back              Skip >> │
├─────────────────────────────────┤
│                                 │
│     🛒 Shopping List 4/6        │
│                                 │
│  Planning a trip? Use the       │
│  Shopping List tab!             │
│                                 │
│  STEP 1: Before you shop      │
│  ┌─────────────────────────────┤
│  │ ✓ Check inventory first    │ │
│  │   (Do you need milk? Check │ │
│  │    the fridge for Jan 15)  │ │
│  │ ✓ Add to shopping list     │ │
│  │   (Things you need)        │ │
│  └─────────────────────────────┘│
│                                 │
│  STEP 2: After you shop       │
│  ┌─────────────────────────────┤
│  │ ✓ Mark as purchased        │ │
│  │   (Check off the item)     │ │
│  │ ✓ Add to inventory         │ │
│  │   (Enter expiry date)      │ │
│  │   → Item moves to 📦       │ │
│  │     Inventory tab          │ │
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┤
│  │    Next                     │ │
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Screen 6: Workflow C - Reduce Waste

```
┌─────────────────────────────────┐
│     ← Back              Skip >> │
├─────────────────────────────────┤
│                                 │
│      ♻️ Reduce Waste 5/6        │
│                                 │
│  When you use an item:         │
│  Tap it → "✓ Mark Consumed"    │
│                                 │
│  When something goes bad:      │
│  Tap it → "🗑️ Mark Wasted"     │
│  Tell us why + how much        │
│  (We track patterns to help    │
│   you improve over time)       │
│                                 │
│  Your waste log:               │
│  📊 This week: 12% of purchases│
│  📊 Last week: 15% of purchases│
│  → You're getting better! 🎯  │
│                                 │
│  ┌─────────────────────────────┤
│  │    Next                     │ │
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Screen 7: Permissions Request

```
┌─────────────────────────────────┐
│     ← Back              Skip >> │
├─────────────────────────────────┤
│                                 │
│       📷 Scanning 6/6           │
│                                 │
│  Enable camera for faster      │
│  expiry date entry             │
│                                 │
│  Point your camera at the      │
│  "Best By" date on packaging   │
│  and we'll auto-fill it.       │
│                                 │
│  (You can always enter dates   │
│   manually too)                │
│                                 │
│  Privacy: We only scan expiry  │
│  dates, nothing else. No data  │
│  is sent to servers.           │
│                                 │
│  ┌─────────────────────────────┤
│  │  Allow Camera Access        │ │ ← Platform permission
│  └─────────────────────────────┘│
│                                 │
│        Not now >>              │
│                                 │
└─────────────────────────────────┘
```

### Screen 8: Get Started (First Real Action)

```
┌─────────────────────────────────┐
│                                 │
│       🎉 All Set!              │
│                                 │
│    Your kitchen inventory      │
│    is empty. Let's fill it!    │
│                                 │
│  Tap the + button below to     │
│  add your first item.          │
│                                 │
│  Or add something from your    │
│  shopping list.                │
│                                 │
│  Tip: Take a photo of your     │
│  fridge and add items as you   │
│  see them. It takes ~2 min!    │
│                                 │
│  ┌─────────────────────────────┤
│  │  Add First Item             │ │ ← Opens add-item sheet
│  └─────────────────────────────┘│
│                                 │
│              ← Skip             │
│                                 │
└─────────────────────────────────┘
```

---

## First-App Guidance (After Onboarding)

After onboarding completes:
1. FAB has pulsing animation + tooltip: "Tap to add an item"
2. Empty state shows brief tip: "Add items by tapping +"
3. After first item added: Highlight "Expiring Soon" tab with tooltip
4. After first expiry check: Show toast with encouragement

---

## Interaction Details

- **Back button:** Return to previous screen (can re-do onboarding)
- **Skip button:** Jump directly to app (no data is lost, can revisit onboarding anytime from Settings)
- **Progress indicator:** Shows "X/6" to give sense of progress
- **Next button:** Advance to next screen
- **No paywalls:** Entire onboarding and core app is free
- **Timing:** Entire onboarding takes 3-4 minutes
- **Re-engagement:** Users can access onboarding again from Settings → Help → Onboarding

---

## Analytics Events

```
onboarding_started
onboarding_screen_viewed (properties: screen_id, screen_number, duration_seconds)
onboarding_skipped (properties: from_screen_id, skip_action)
onboarding_completed (properties: total_duration_seconds, camera_permission_granted)
onboarding_permissions_granted (properties: permission_type: 'camera')
first_item_added (properties: is_from_onboarding_guidance: true)
```

---

## Key Design Principles

1. **Answer WHY first** (Screens 2-3) before teaching HOW (Screens 4-6)
   - Users need context before learning mechanics
2. **Visual storytelling** - Use emojis and simple examples, not dense text
   - Emoji flow: 📦 → 🥛 → ⏰ tells the story without words
3. **Build confidence** - Progress bar, encouragement, success messages
   - "You're getting better! 🎯" validates effort
4. **Clarify shopping flow explicitly** (Screen 5) - Shows step-by-step conversion
   - Directly addresses user feedback on confusion
5. **Progressive disclosure** - One concept per screen
   - Don't overload users with all features at once
6. **Respectful of time** - ~3-4 min total, can skip anytime
   - Mobile users have limited patience
7. **Lowercase-first-time** - Permissions only when needed, not upfront
   - Don't ask for camera until user understands why

---

## Prototype Implementation Notes

Screens should be built as HTML pages in `prototype/onboarding/`:
```
prototype/onboarding/
├── welcome.html
├── problem.html
├── solution.html
├── inventory.html
├── shopping.html        ← KEY: Shopping → Inventory flow with animated arrows
├── waste.html
├── permissions.html
├── get-started.html
└── styles.css
```

Each screen should:
- Show progress indicator (X/6)
- Have accessible back/skip buttons
- Use consistent spacing and typography
- Include smooth transitions between screens
- Log analytics events on view/skip/complete

---

## Related to Issue #060

This onboarding flow directly addresses user testing feedback:
- **Confusion:** Shopping list → Inventory conversion (Screen 5 clarifies with step-by-step breakdown)
- **Motivation:** Users understand WHY they're using the app (Screens 2-3)
- **Guidance:** First-time users learn the core workflows before encountering them in practice

Onboarding can be integrated into user testing:
- Show onboarding before task scenarios
- Measure comprehension (did they understand the shopping flow?)
- Collect feedback on clarity via post-test survey

---

## Status

🚧 **PLACEHOLDER** - To be implemented in HTML prototype + Flutter app during M1.

## Figma Expansion Prompt

> **Prompt:** "Design an 8-screen onboarding flow for a food waste reduction app. Screen progression: (1) Splash with tagline + CTA, (2) Problem statement with 30% waste stat, (3) Solution benefits (track, plan, reduce), (4) Inventory management walkthrough (add → track → expiring), (5) **Shopping List workflow** emphasizing the conversion path (check inventory → add to list → buy → mark purchased → add to inventory with expiry → track), (6) Waste reduction loop (use/consume vs waste → log reasons + %), (7) Camera permissions request with privacy assurance, (8) 'All Set' call-to-action with first item guidance. Use progress indicator (X/6), allow skip/back navigation. Typography: bold 24pt headings, 15pt body, light spacing. Emojis as visual cues (📦→🥛→⏰). Color: green primary (#2f9e44) for CTAs, light backgrounds, encouraging tone. Include animation hints for button pulsing on Screen 8 FAB and slide transitions between screens. Design for 15-30sec per screen, no paywalls, respectful of user time. Accessibility: high contrast, clear labels, screen reader friendly."

