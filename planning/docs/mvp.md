# ZeroSpoils MVP Scope

## Executive Summary

ZeroSpoils MVP is a **cross-platform mobile app** (iOS & Android) that helps households track food in their kitchen and prevent spoilage through timely reminders. The MVP focuses on three core capabilities:

1. **Awareness** – Know what's in the kitchen and when it expires
2. **Action** – Get reminded before food spoils
3. **Insight** – See money saved and waste avoided

**Target Users:** Busy parents, young professionals, eco-conscious households in Canada  
**Geographic Focus:** Canada (high food prices, smartphone penetration, sustainability awareness)  
**Business Model:** Freemium (free MVP core, Pro tier adds receipt OCR, household sync, advanced analytics)

---

## MVP Features (In Scope)

### 1. Inventory Management
**Manual Item Entry & Editing**
- Add items by entering: name, category, location (fridge/pantry/freezer/other), quantity, expiry date
- Edit item details (update category, quantity, expiry date)
- Delete items individually or mark as used/wasted
- Categories: Produce, Dairy, Meat, Grains, Pantry, Other
- Locations: Fridge, Pantry, Freezer, Other
- Acceptance: Users can add/edit/delete 100s of items without friction; form validation prevents invalid dates

### 2. Inventory Views
**Inventory List Screen**
- Display all items sorted by location
- Search by item name (autocomplete)
- Filter by category, location, expiry status
- Show: item name, category, location, days until expiry (color-coded)
- Acceptance: List loads in <500ms; search responsive; filters work in combination

**Expiring Soon Screen (Priority View)**
- Bucketed view: Today | This Week | Expired (overdue)
- Shows count of items in each bucket
- Quick action: tap to mark consumed/wasted
- Accept criteria: Clearly visible which items are most urgent to consume

### 3. Smart Reminders
**Configurable Notification Defaults**
- Users set preferred lead times: 1, 3, or 5 days before expiry
- System sends local push notification at user-selected time (e.g., 9 AM)
- Tapping notification opens app to "Expiring Soon" screen
- Users can disable reminders per-item or globally
- Acceptance: Reminders fire reliably; timezone-aware scheduling works

### 4. Shopping List
**Shopping List Management**
- Create new shopping list
- Add items manually or convert expiring items to shopping list
- Reorder items by frequency added (most common at top)
- Mark items purchased (convert to inventory with defaults: location=Fridge, quantity=1)
- Share shopping list snapshot via text/email (read-only)
- Acceptance: Shopping list syncs locally; "Next Shop" workflow intuitive

### 5. Offline-First Architecture
**Core Features Work Without Internet**
- All inventory data stored locally (encrypted on device)
- Reminders function without internet
- Add/edit/delete items in airplane mode
- UI remains responsive (no cloud latency)
- Acceptance: Verify all core screens load in offline mode; no "network error" states for MVP features

### 6. Data Privacy & Control
**Data Export & Deletion**
- Users can export all inventory data as CSV (for backup or migration)
- Users can delete all data with one tap (irreversible)
- No telemetry by default (opt-in at first launch)
- Acceptance: Export includes all item fields; deletion is instantaneous; no data sent to analytics by default

### 7. Onboarding & Permissions
**First-Run Experience**
- Welcome screen explaining app purpose
- Request notification permissions (optional, not mandatory)
- Simple tutorial (skip available)
- Empty state guidance: "Start by adding an item"
- Acceptance: Users clear on purpose; permissions clear and justified

---

## Non-Goals (Explicitly Out of Scope)

### Deferred to Pro Tier
- **Receipt OCR / Batch Photo Capture** – Capturing items from photos or receipts with computer vision (M5/M6 roadmap)
- **Household Sync / Multi-User Accounts** – Family account support and real-time sync (M3/M4 roadmap)
- **Advanced Analytics Dashboard** – Charts, trends, money saved calculators (M5 roadmap)
- **Meal Planning** – Recipe suggestions and meal plan scheduling (M6 roadmap)

### Deferred to Future / Out of Scope Long-Term
- **Barcode Scanning** – Will not implement; competitors already saturated in this space; we differentiate via photos/receipts
- **IoT Integrations** – NFC tags, smart shelves, Bluetooth scales (M7 roadmap)
- **Web App** – Initial launch is mobile-only; web may follow post-MVP
- **Internationalization** – MVP supports English only; French, Spanish, etc. deferred
- **Third-Party Integrations** – Grocery delivery APIs, meal-plan apps, smart fridge ecosystems (future exploration)

---

## Success Metrics (How We Measure MVP Effectiveness)

### Engagement & Activity
| Metric | Target | Rationale |
|--------|--------|-----------|
| **Items Added / Week** | ≥3 items/week | Indicates active use and food tracking behavior |
| **Reminders Received / Week** | ≥2 notifications/week | Shows system is working for intended purpose |
| **Reminder Open Rate** | ≥40% | Measures relevance and timeliness of notifications |
| **Items Marked Consumed/Week** | ≥2 items/week | Direct evidence of waste reduction action |

### Retention & Growth
| Metric | Target | Rationale |
|--------|--------|-----------|
| **Day 1 Retention (D1R)** | ≥50% | Users return after first day |
| **Day 7 Retention (D7R)** | ≥25% | Users stick around past first week |
| **Day 30 Retention (D30R)** | ≥10% | Sustainable habit formation |
| **Time to First Item** | <5 min | Low friction to activation |

### Impact
| Metric | Target | Rationale |
|--------|--------|-----------|
| **Items Wasted Ratio** | <15% | Items marked "wasted" vs. total items (lower is better) |
| **Cost Saved Estimate** | Calculate at launch | Est. $X per user per month based on avg item value |
| **Session Duration** | ≥2 min average | Users engage meaningfully, not just drive-by |

### Technical
| Metric | Target | Rationale |
|--------|--------|-----------|
| **Crash Rate** | <0.1% | Stability for core user flows |
| **App Launch Time (Cold)** | <2 sec | Responsive, not sluggish |
| **Notification Delivery Rate** | ≥95% | Reliability of core feature |

---

## Roadmap Context (Why We're Doing This MVP)

### Phase 1: MVP (M1–M3) – Awareness & Action
Establish baseline: users track food, get timely reminders, avoid waste. Free tier, no account required, offline-first.

### Phase 2: Engagement (M4) – Polish & Launch
Refine UX, accessibility audit, performance optimization. Ready for public launch on App Store & Google Play.

### Phase 3: Pro Tier (M5–M6) – Insight & Efficiency
Add receipt scanning, household accounts, advanced analytics. Monetization via subscription (~$5/month or $40/year).

### Phase 4: Ecosystem (M7+) – IoT & Extensibility
NFC tags, smart camera station, Home Assistant integration, ML-based recipe suggestions.

---

## Definition of Done for MVP Features

Every MVP feature issue (M2 issues 140–250) must include:

- ✅ Code implementation (Dart/Flutter)
- ✅ Unit, widget, or integration tests (≥80% coverage)
- ✅ Telemetry instrumentation (event names, key properties per `docs/telemetry.md`)
- ✅ Offline-first verification (core features work without internet)
- ✅ Accessibility basics (labels, contrast ≥4.5:1, touch targets ≥44pt)
- ✅ Documentation (if new data model or UI patterns)
- ✅ Performance baseline (cold start <2s, list scroll ≥60fps)

---

## Acceptance Criteria for This Document

- [x] MVP features clearly defined with acceptance criteria
- [x] Non-goals explicitly listed to prevent scope creep
- [x] Success metrics measurable and tied to telemetry events
- [x] Roadmap context provided (phases 1–4)
- [x] Definition of Done specified for all MVP issues
- [x] Linked to competitive analysis and market context (from PRD)
- [x] Ready for product team walkthrough and developer reference

---

## How This Document Will Be Used

1. **Development Teams** – Reference for feature prioritization; acceptance criteria for issues 140–250
2. **Product/Design** – Boundary for UX flows, screen designs, and user journeys
3. **Stakeholders** – Shared understanding of MVP definition and launch readiness
4. **AI Coding Agents** – Direct prompt for implementing features without scope creep
5. **QA/Testing** – Success metrics are automated and manual test criteria

---

## Related Documents

- [data-model.md](data-model.md) – Schema, enums, migrations
- [telemetry.md](telemetry.md) – Event taxonomy and privacy strategy
- [app-flows.md](app-flows.md) – User journey diagrams
- [design-tokens.md](design-tokens.md) – Spacing, typography, colors
- [ux.md](ux.md) – UX patterns and interaction guidelines
- [planning/docs/prd/](prd/) – Market research and competitive analysis
