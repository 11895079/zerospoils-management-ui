# UX & Wireframes Index

This folder contains wireframe specifications and UX patterns for ZeroSpoils MVP screens.

## Wireframes (by priority)

### Core MVP Screens
1. **[01 - Inventory List](./wireframes/01-inventory-list.md)** – Main screen showing all items grouped by category
2. **[02 - Add Item Modal](./wireframes/02-add-item-modal.md)** – Form to add new item (name, category, expiry, notes)
3. **[03 - Item Detail](./wireframes/03-item-detail.md)** – View, edit, delete single item
4. **[04 - Expiring Soon Tab](./wireframes/04-expiring-soon-tab.md)** – Quick view of items expiring in next 7 days

### Future Screens (Out of M1 scope)
- Shopping List Tab – Separate tab for meal planning
- Settings Screen – User preferences, notifications, app info
- Onboarding Flow – Welcome & tutorial screens (M2)

## Design Reference

### [UX Patterns & Component Library](./ux-patterns.md)
Reusable UI components used across all screens:
- **AppBar** – Screen headers with navigation
- **SearchBar** – Filter items by text
- **ItemCard** – Reusable item display component
- **FAB** – Floating action button (add item)
- **Modal** – Form overlays (add, edit, delete)
- **Buttons** – Primary, secondary, danger variants
- **Empty States** – User-friendly "no items" messages
- **Color Coding** – Status colors (green = good, yellow = warning, red = urgent)
- **Accessibility** – Tap targets, labels, contrast, screen readers
- **Animations** – Smooth, 200-300ms transitions
- **Responsive Design** – Mobile-first (320px - 428px)

## File Structure

```
docs/
├── ux.md                       ← You are here (this file)
├── ux-patterns.md              ← Component & pattern library
└── wireframes/
    ├── 01-inventory-list.md
    ├── 02-add-item-modal.md
    ├── 03-item-detail.md
    └── 04-expiring-soon-tab.md
```

## Wireframe Template

Each wireframe includes:
1. **Purpose** – What task does user accomplish?
2. **Layout** – ASCII art of screen structure
3. **Components** – Reusable UI elements (from ux-patterns.md)
4. **Interactions** – User actions and what happens
5. **Accessibility** – Checklist for a11y compliance
6. **Empty States** – How screen looks with no data
7. **Telemetry Events** – Tracking events for analytics
8. **Notes** – Implementation tips, edge cases, performance hints

## How to Use These Wireframes

### For Designers & Product Managers
1. Review wireframes for layout & flow
2. Provide feedback on screen order, components, interactions
3. Align on UX decisions (color coding, grouping, etc.)
4. Use as design reference for high-fidelity mockups (v2)

### For Developers
1. Read "Purpose" and "Layout" to understand screen goals
2. Use "Components" list to identify reusable code
3. Follow "Interactions" for navigation and form logic
4. Check "Accessibility" checklist during implementation
5. Implement "Telemetry Events" alongside features
6. Handle "Empty States" explicitly in code
7. Reference ux-patterns.md for component API

### For QA & Testers
1. Check interactions against "Interactions" section
2. Verify all "Accessibility" checklist items
3. Test "Empty States" with no/few items
4. Validate telemetry events in app analytics
5. Test on 320px (SE) and 428px (14) devices
6. Test with 2x font size scaling

## Design System Reference

### Colors
- **Primary Blue:** #2196F3 (buttons, active states)
- **Success Green:** #4CAF50 (✓ good status)
- **Warning Yellow:** #FFC107 (1-3 days to expiry)
- **Urgent Orange:** #FF9800 (<1 day to expiry)
- **Error Red:** #F44336 (expired, errors)
- **Neutral Gray:** #666666 (labels, secondary text)

### Typography
- **Base Font:** 14pt (text), 16pt (inputs)
- **Headings:** 24pt (page title), 18pt (section), 16pt (medium)
- **All fonts scale to 2x** without breaking layout

### Spacing
- **Standard padding:** 16pt sides, 12pt vertical
- **Component gap:** 8pt between elements
- **Margins:** Consistent 16pt page margins

### Tap Targets
- **Minimum:** 44pt × 44pt (Apple/Android standard)
- **Comfortable:** 48pt × 48pt (buttons)
- **Buttons:** Full width on mobile (except modals)

---

## Implementation Status

| Wireframe | Design Spec | Code | Tests | Status |
|-----------|-------------|------|-------|--------|
| Inventory List | ✅ | 🚧 | 🚧 | Ready to build |
| Add Item Modal | ✅ | 🚧 | 🚧 | Ready to build |
| Item Detail | ✅ | 🚧 | 🚧 | Ready to build |
| Expiring Soon | ✅ | 🚧 | 🚧 | Ready to build |
| UX Patterns | ✅ | 🚧 | 🚧 | Reference doc |

---

## Next Steps

1. **Team Review** – Share wireframes with team, get alignment
2. **Refinements** – Update wireframes based on feedback
3. **Implementation** – Developers build screens per wireframe spec
4. **Testing** – QA verifies against wireframe checklist
5. **High-Fidelity Design** – Designers create visual mockups (v2)

## Related Issues

- **M1/050** – Wireframes for core MVP screens (this work)
- **M1/090** – Flutter app skeleton (routing, theming, DI) – COMPLETE
- **M1/060** – Clickable prototype (build from these wireframes)
- **M1/080** – Data model implementation

## Questions or Updates?

If you need to:
- **Add a new screen:** Copy wireframe template, fill in all sections
- **Update layout:** Edit ASCII art and component list
- **Change interaction:** Update "Interactions" section + telemetry events
- **Find a component:** Search ux-patterns.md for component API

All changes should be reviewed by team before implementation begins.
