## Context
UX foundations (wireframes, interaction patterns, component primitives, design tokens) guide consistent implementation across screens.

## Goal
Deliver complete UX foundations: wireframes for MVP flows, interaction patterns, component guidelines, and design tokens.

## Expected behavior

### Screens & Flows
1. **Onboarding** (3 screens max) - Welcome, permissions, quick tutorial
2. **Inventory** - List all items, search/filter, quick add via FAB
3. **Add Item Modal** - Quick entry form (name, category, expiry)
4. **Item Detail** - Full view, edit fields, actions (delete, mark-used)
5. **Expiring Soon** - Alerts grouped by urgency (today, 3 days, 7 days)
6. **Shopping List** - Curated suggestions, categories
7. **Settings** - Preferences, notifications, about
8. **Empty States** - Each screen with no data

### Design Principles
- **Navigation:** Bottom tabs (4 max) + FAB for primary action
- **Interaction:** Swipe, tap, modal dialogs (minimize typing)
- **Accessibility:** Tap targets ≥44pt, labels, high contrast
- **Consistency:** Reuse 5-6 core components across all screens

## Acceptance criteria (Definition of Done)
- [ ] Wireframes created under `docs/wireframes/` and linked in `docs/ux.md`
- [ ] Includes empty states + onboarding flows
- [ ] UX patterns doc created with component guidelines (buttons, lists, cards, modals)
- [ ] Design tokens documented in `docs/design-tokens.md`
- [ ] Reviewed by at least one team member (engineering + product)
- [ ] Clickable prototype (060) references patterns and tokens
- [ ] Accessibility annotations included on wireframes (tap targets ≥44pt, contrast ≥4.5:1, semantic labels)
- [N/A] Unit/widget/integration tests (documentation only)
- [N/A] Offline-first behavior verification (implementation concern, not wireframes)
- [N/A] Telemetry instrumentation (implemented in feature work)

## Out of scope
- High-fidelity visual design system and final brand assets (handled in launch milestone)

## Implementation notes
- **Format:** Markdown with ASCII art + structured sections (see wireframe template below)
- **Grayscale:** Wireframes are black & white; color details in design tokens
- **Mobile-first:** Assume 375pt width (iPhone SE), scale up to 428pt (iPhone 14)
- **Components:** Define 6 core widgets (ItemCard, SearchBar, FAB, Modal, ListTile, EmptyState)
- **Interactions:** Keep patterns simple—tap, swipe (delete), long-press (edit), modal dialogs
- **Defaults:** Notification lead times (3 days warning), category buckets (Dairy, Vegetables, etc.)

### Wireframe Template (Per Screen)
Each wireframe file should include:
```markdown
## <Screen Name>

### Purpose
<What task does user accomplish?>

### Layout
<ASCII art of screen>

### Components
| Name | Size | Purpose |
|------|------|---------|
| SearchBar | 48pt | Filter items |

### Interactions
1. **Tap item** → Navigate to detail
2. **Swipe left** → Delete option

### Accessibility
- [ ] Tap targets ≥44pt
- [ ] Labels visible
- [ ] Contrast ≥4.5:1
- [ ] Font scales to 2x

### Empty State
<Description or ASCII art of empty state>

### Telemetry Events
- `inventory_opened` - {item_count, filter_active}
- `item_tapped` - {item_id, category}
```

## Test plan
**Automated:**
- Parse `docs/ux.md` and verify all wireframe files referenced exist
- Validate `docs/design-tokens.md` contains required sections (spacing, typography, colors, touch targets)

**Manual:**
1. Review wireframes with engineering team for feasibility
2. Validate accessibility annotations (tap targets, contrast) on all screens
3. Confirm navigation flow matches documented patterns
4. Run clickable prototype walkthrough with 5 users (see 060)

## Dependencies
- None
