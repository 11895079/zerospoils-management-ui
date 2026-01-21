# Wireframe to Prototype Mapping

**Purpose:** Bridge between design intent (wireframes) and implementation source (interactive prototypes). Coding agents should reference prototypes as the source of truth for implementation details (styling, interactions, component behavior).

---

## Core App Screens

| Wireframe | Prototype | Status | Notes |
|-----------|-----------|--------|-------|
| `inventory-list.md` | `prototype/index.html` | ✅ Complete | Includes location filters, prepared items (cooked rice), help button linking to onboarding |
| `add-item.md` | `prototype/add-item.html` | ✅ Complete | Type toggle (Raw/Prepared), prepared date field, smart defaults (freezer +30 days), OCR simulation |
| `item-detail.md` | `prototype/item-detail.html` | ✅ Complete | Waste % slider (0-100%), notes field, Type/Prepared Date info rows |
| `expiring-soon.md` | `prototype/expiring-soon.html` | ✅ Complete | Grouped by urgency (Today/This Week/Expired), alert icons |
| `shopping-list.md` | `prototype/shopping-list.html` | ✅ Complete | Convert-to-inventory modal with quantity + expiry picker, auto-fills quantity from purchased count |
| `onboarding-flow.md` | `prototype/onboarding/welcome.html` (+ 7 more) | ✅ Complete | 8-screen educational flow, shopping list clarification (Screen 5), progress through screens |

---

## New Features (Prototype Only, No Wireframe Yet)

| Feature | Prototype | Status | Wireframe Needed? |
|---------|-----------|--------|-------------------|
| **Progress Dashboard** | `prototype/progress.html` | ✅ Complete | Optional — detailed wireframe would help for Flutter implementation |
| **Interactive Tutorial** | `prototype/tutorial.html` | ✅ Complete | No — implementation guide already exists (`planning/docs/interactive-tutorial-implementation.md`) |
| **Share Card Modal** | `prototype/progress.html` (modal) | ✅ Complete | No — embedded in progress page |

---

## Prototype Enhancements Beyond Wireframes

These features exist in prototypes but weren't in original wireframe specs:

1. **Quantity on Convert** (`shopping-list.html`)
   - Wireframe: Basic conversion flow
   - Prototype: Quantity input field, auto-fills from purchased count

2. **Waste Percentage** (`item-detail.html`)
   - Wireframe: Waste reason picker only
   - Prototype: Waste % slider (0-100%) + notes textarea

3. **Prepared Items** (`add-item.html`, `index.html`)
   - Wireframe: Basic item addition
   - Prototype: Type toggle (Raw/Prepared), prepared date field, freezer default

4. **Progress Tab** (`progress.html`)
   - Wireframe: Not originally designed
   - Prototype: Full analytics dashboard (waste %, savings, CO₂, charts, impact, share card)

5. **Help Button** (`index.html`)
   - Wireframe: Not specified
   - Prototype: ℹ️ button in header linking back to onboarding

6. **Demo Badge** (`tutorial.html`)
   - Wireframe: N/A
   - Prototype: "📚 Demo Mode" badge shows tutorial is active

---

## File Locations

### Wireframes
```
planning/docs/wireframes/
├── inventory-list.md
├── add-item.md
├── item-detail.md
├── expiring-soon.md
├── shopping-list.md
└── onboarding-flow.md
```

### Prototypes
```
prototype/
├── index.html                  (Inventory List)
├── add-item.html               (Add Item)
├── item-detail.html            (Item Detail)
├── expiring-soon.html          (Expiring Soon)
├── shopping-list.html          (Shopping List)
├── progress.html               (Progress Dashboard) [NEW]
├── tutorial.html               (Interactive Tutorial) [NEW]
├── styles.css                  (Shared styles)
├── README.md                   (Deployment guide)
└── onboarding/
    ├── welcome.html            (Onboarding Screen 1)
    ├── problem.html            (Onboarding Screen 2)
    ├── solution.html           (Onboarding Screen 3)
    ├── inventory.html          (Onboarding Screen 4)
    ├── shopping.html           (Onboarding Screen 5 — KEY: Shopping flow clarification)
    ├── waste.html              (Onboarding Screen 6)
    ├── permissions.html        (Onboarding Screen 7)
    ├── get-started.html        (Onboarding Screen 8 — CTA for tutorial)
    ├── onboarding.css          (Dedicated onboarding styles)
    └── README.md               (Onboarding flow docs)
```

---

## Using This Mapping

### For Developers
1. Read wireframe to understand **design intent** (flows, user journey, layout)
2. Open corresponding prototype to see **implementation details** (styling, interactions, component behavior)
3. Use prototype as source of truth for code generation

### For AI Coding Agents
When implementing a feature:
```
1. Identify the issue (e.g., "Implement shopping list screen")
2. Look up wireframe for design intent
3. Reference prototype for exact implementation
4. Extract:
   - HTML structure (semantic elements, classes)
   - CSS patterns (colors, spacing, typography)
   - JavaScript interactions (modals, toasts, form validation)
   - User flows (button click → modal → form → success toast)
```

### Example Workflow
**Task:** Implement Shopping List screen in Flutter

1. **Design Intent:** Read `planning/docs/wireframes/shopping-list.md`
   - Understand: checkable items, purchased section, convert flow
   
2. **Implementation Source:** Open `prototype/shopping-list.html`
   - Extract: 
     - Convert modal structure (quantity + expiry + location)
     - Auto-fill logic for quantity (based on purchased count)
     - Toast messages ("✓ 2 Eggs added to inventory!")
     - Color scheme (green buttons, yellow badges)

3. **Flutter Code:** Translate HTML/CSS/JS patterns to Flutter widgets
   - HTML form → Flutter Form widget
   - Modal → showModalBottomSheet
   - Toast → SnackBar

---

## Prototype Deployment URLs

**For User Testing:**
- Netlify: https://zerospoils-prototype.netlify.app (or your custom URL)
- GitHub Pages: https://username.github.io/zerospoils/ (if configured)
- Local: `open prototype/index.html` (works offline)

**Onboarding Flow Entry Point:**
- Start: `prototype/onboarding/welcome.html`
- After completion: Links to `prototype/tutorial.html` (guided walkthrough) or `prototype/index.html` (main app)

---

## Key Design Patterns (From Prototypes)

### Color Scheme
- **Primary Green:** `#2f9e44` (buttons, headers, progress)
- **Accent Green:** `#51cf66` (gradients, highlights)
- **Warning:** `#ffc107` (expiring soon badges)
- **Danger:** `#ff6b6b` (expired items, wasted count)
- **Background:** `#f8f9fa` (page backgrounds)

### Typography
- **Headers:** 18-24px, bold
- **Body:** 14-16px, regular
- **Labels:** 13-14px, medium weight
- **Emojis:** Used throughout for visual storytelling

### Component Patterns
- **Bottom Nav:** 4 tabs (Inventory, Expiring, Shopping, Progress)
- **Modal:** Slide-up from bottom, dark overlay
- **Toast:** Fixed bottom position, auto-dismiss after 2s
- **FAB:** Fixed bottom-right, green, + icon
- **Cards:** White background, rounded corners, subtle shadow
- **Badges:** Colored pills (yellow/red/green based on urgency)

---

## Updates & Maintenance

When prototypes are updated:
1. Update this mapping document
2. Add note to corresponding wireframe (reference prototype for latest)
3. Log changes in `prototype/CHANGELOG.md` (if created)

When wireframes are updated:
1. Decide if prototype needs update
2. If yes, implement in prototype first (faster iteration)
3. Update wireframe after prototype is validated

**Rule of Thumb:** Prototypes lead, wireframes document intent.
