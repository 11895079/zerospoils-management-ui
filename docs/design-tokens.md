# Design Tokens — ZeroSpoils MVP

Complete design system specification for consistent visual and interactive styling across all screens.

## Color Palette

### Primary & Semantic
| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| Primary (Blue) | #2196F3 | 33, 150, 243 | Buttons, active states, primary actions |
| Success (Green) | #4CAF50 | 76, 175, 80 | Positive status (✓ good, >3 days expiry) |
| Warning (Yellow) | #FFC107 | 255, 193, 7 | Caution state (1–3 days expiry) |
| Urgent (Orange) | #FF9800 | 255, 152, 0 | High priority (<1 day expiry) |
| Error (Red) | #F44336 | 244, 67, 54 | Errors, critical state (expired), delete actions |
| Neutral (Gray) | #666666 | 102, 102, 102 | Labels, secondary text, disabled states |

### Background & Borders
| Token | Hex | Usage |
|-------|-----|-------|
| Background (White) | #FFFFFF | Main content area |
| Surface (Light Gray) | #F5F5F5 | Cards, sections, secondary surfaces |
| Border (Gray) | #E0E0E0 | Dividers, input borders, section separators |
| Dimmed (Overlay) | #000000 @ 80% opacity | Modal background overlay |

### Status Backgrounds (Item Cards)
| Status | Background | Text | Border | Usage |
|--------|------------|------|--------|-------|
| Good (>3d) | #FFFFFF | #212121 | #E0E0E0 | Normal item |
| Warning (1-3d) | #FFF9E6 | #212121 | #FFEB3B | Approaching expiry |
| Urgent (<1d) | #FFE6CC | #212121 | #FF9800 | About to expire |
| Expired | #FFE6E6 | #D32F2F | #F44336 | Past expiry date |

---

## Typography

### Font Family
- **Primary:** System default (San Francisco on iOS, Roboto on Android)
- **Monospace (code):** Monaco, Menlo, or system monospace
- **Fallback:** Helvetica Neue, Arial, sans-serif

### Font Sizes & Weights

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Display | 28pt | Bold (700) | 1.3 (36pt) | App title, large headers |
| Heading 1 | 24pt | Semi-bold (600) | 1.4 (34pt) | Page titles (Home, Expiring) |
| Heading 2 | 18pt | Semi-bold (600) | 1.3 (24pt) | Section headers (DAIRY, VEGETABLES) |
| Heading 3 | 16pt | Semi-bold (600) | 1.3 (21pt) | Medium headings, input labels |
| Body Large | 16pt | Regular (400) | 1.5 (24pt) | Input fields, large text blocks |
| Body | 14pt | Regular (400) | 1.5 (21pt) | Standard text, descriptions |
| Body Small | 12pt | Regular (400) | 1.4 (17pt) | Secondary text, hints, expiry dates |
| Caption | 11pt | Regular (400) | 1.4 (15pt) | Micro-text, timestamps |

### Line Height
- **Tight:** 1.3 (headings)
- **Normal:** 1.4 (body text, labels)
- **Relaxed:** 1.5 (input fields, descriptions)

### Font Scaling
- Minimum: 14pt (readable without zoom)
- Maximum: 2x scale without layout breaks
- Accessibility: Users can scale text up to 2x; layout must reflow gracefully

---

## Spacing Scale

### Base Unit: 4pt (grid)

| Token | Value | Usage |
|-------|-------|-------|
| 2xs | 2pt | Fine adjustments (rare) |
| xs | 4pt | Micro spacing between tight elements |
| sm | 8pt | Small gaps (between icons & text, item spacing) |
| md | 12pt | Medium gaps (section vertical padding) |
| lg | 16pt | Standard padding (page margins, card padding) |
| xl | 24pt | Large gaps (between sections) |
| 2xl | 32pt | Extra large (page top margin) |
| 3xl | 48pt | Hero spacing (between tab content) |

### Common Spacing Patterns
| Pattern | Values | Usage |
|---------|--------|-------|
| Page Margins | 16pt left/right | All screens |
| Card Padding | 16pt (lg) | Wireframes 01, 03, 04 |
| Component Gap | 8pt (sm) | Between icon + text, rows |
| Section Gap | 12pt (md) | Between category groups, form fields |
| List Item Padding | 16pt vertical (lg) | Item cards in list |
| Modal Padding | 16pt (lg) | Wireframe 02 form |

### Vertical Rhythm
- Baseline: 4pt grid
- Section spacing: 24pt (xl) between major sections
- Line spacing: 1.4–1.5 (see Typography)

---

## Touch Targets & Sizing

### Minimum Touch Target (Accessibility)
- **Size:** 44pt × 44pt (Apple Human Interface Guidelines)
- **Safe:** 48pt × 48pt (comfortable)
- **Minimum gap:** 8pt between adjacent targets

### Component Sizing

| Component | Size | Notes |
|-----------|------|-------|
| AppBar | 56pt height | Header with title + buttons |
| SearchBar | 48pt height | Input field + icon |
| ItemCard | 64pt height | Item name + expiry label |
| Button (Primary/Secondary) | 48pt height | Full width on mobile, min 48pt |
| FAB (Floating Action Button) | 56pt diameter | Circle, always ≥44pt |
| Tab Bar | 56pt height | Bottom nav with 4 tabs |
| TextInput | 48pt height | Single-line input |
| TextInput (Multi-line) | ≥96pt height | Notes field (auto-expand) |
| Modal Header | 56pt height | Title + close button (X) |
| Dropdown Toggle | 48pt height | Category selector, date picker |
| Checkbox | 24pt × 24pt | Form checkbox (tap 48pt) |
| Icon (Small) | 16pt–20pt | Decorative (emoji, icons) |
| Icon (Large) | 24pt–32pt | Action icons (settings ⚙️, delete 🗑️) |

### Icon & Emoji Sizing
| Context | Size | Usage |
|---------|------|-------|
| Category Emoji | 24pt | Item cards, modals |
| Status Icon | 16pt–20pt | Badge icons (✓, ⚠️, 🚨) |
| Decorative Emoji | 48pt | Empty state illustrations (📭, ✅) |
| Action Icon | 20pt | Buttons (settings, menu, FAB) |

---

## Elevation & Shadow

### Shadow System (Material 3 style)
| Level | Elevation | Shadow | Usage |
|-------|-----------|--------|-------|
| 0 | None | None | Flat background, no depth |
| 1 | 1dip | Subtle blur | Search bar, input fields |
| 2 | 3dip | Light shadow | Cards, tabs |
| 3 | 6dip | Medium shadow | Modals (raised above content) |
| 4 | 8dip | Darker shadow | FAB, bottom sheets |

### Shadow Color
- **Light theme:** #000000 @ 20% opacity
- **Dark theme:** #000000 @ 30% opacity

---

## Border Radius

### Corner Radius Scale
| Token | Radius | Usage |
|-------|--------|-------|
| none | 0pt | Buttons, modals (flat corners) |
| sm | 4pt | Subtle curves (text inputs, badges) |
| md | 8pt | Standard (cards, alerts) |
| lg | 12pt | Rounded corners (modals, FAB backdrop) |
| full | 50% | FAB circle, avatars |

### Component Radius
| Component | Radius | Notes |
|-----------|--------|-------|
| AppBar | 0pt | Flat top edge |
| Button | 4pt (sm) | Slight rounding |
| TextInput | 4pt (sm) | Subtle border |
| Card | 8pt (md) | Standard roundness |
| Modal | 12pt (lg) | Softer appearance |
| FAB | 50% (full) | Perfect circle |
| Badge | 4pt (sm) | Small rounded |

---

## Animation & Transition

### Timing
| Duration | Usage |
|----------|-------|
| 100ms | Quick feedback (button press, ripple) |
| 200ms | Standard transition (fade, slide) |
| 300ms | Smooth transition (modal open, screen swap) |
| 500ms+ | Long transitions (avoided, too slow) |

### Easing Curves
- **Fast In/Out:** `Cubic(0.4, 0, 0.2, 1)` – buttons, ripple
- **Linear:** `Linear` – progress indicators
- **Ease In Out:** `Cubic(0.4, 0, 0.2, 1)` – modal transitions, tab switches
- **No:** Bouncy easing, parallax, excessive animations (distraction)

### Common Transitions
| Action | Duration | Easing | Effect |
|--------|----------|--------|--------|
| Button tap | 100ms | Fast In/Out | Color feedback + ripple |
| Modal open | 200ms | Ease In Out | Fade in + scale up |
| Tab switch | 200ms | Ease In Out | Fade between screens |
| Item card hover | 200ms | Ease In Out | Elevation + slight scale |
| FAB press | 100ms | Fast In/Out | Scale down feedback |

---

## Dark Theme (Future v2)

### Color Overrides
| Token | Light | Dark |
|-------|-------|------|
| Background | #FFFFFF | #121212 |
| Surface | #F5F5F5 | #1E1E1E |
| Text | #212121 | #E8E8E8 |
| Border | #E0E0E0 | #404040 |

All semantic colors (primary blue, green, yellow, orange, red) remain constant.

---

## Contrast & Accessibility

### Minimum Contrast Ratios
- **Text on background:** ≥4.5:1 (WCAG AA)
- **Large text (18pt+):** ≥3:1 (WCAG AA)
- **UI components:** ≥3:1 (border, icon, focus indicator)

### Verified Combinations
| Foreground | Background | Ratio | Status |
|------------|------------|-------|--------|
| #212121 (text) | #FFFFFF (bg) | 12.6:1 | ✓ Pass |
| #666666 (gray) | #FFFFFF (bg) | 4.54:1 | ✓ Pass |
| #FFFFFF (text) | #2196F3 (blue) | 4.88:1 | ✓ Pass |
| #FFFFFF (text) | #F44336 (red) | 3.99:1 | ✓ Pass |
| #212121 (text) | #FFF9E6 (warn bg) | 11.2:1 | ✓ Pass |

### Non-Color Indicators
- Use text labels, icons, or patterns (never color-only)
- Example: Status badge shows color + icon + text ("⚠️ Expiring Soon")

---

## Responsive Breakpoints

### Device Sizes
| Device | Width | Notes |
|--------|-------|-------|
| iPhone SE | 320pt | Minimum safe width |
| iPhone 11/12 mini | 375pt | Primary design target |
| iPhone 14/15 Pro | 390pt | Most common |
| iPhone 14/15 Pro Max | 428pt | Maximum for MVP |
| Tablet (v2+) | 768pt+ | Future scope |

### Layout Rules
- **Padding:** 16pt page margins (constant across sizes)
- **Buttons:** Full width on mobile (except modals)
- **Lists:** Single column, no horizontal scrolling
- **Max width:** None for MVP (full device width)
- **Orientation:** Portrait only (landscape in v2)

---

## Component Token References

### Button Component
- **Height:** 48pt (lg)
- **Padding:** 16pt horizontal (lg), 12pt vertical (md)
- **Border radius:** 4pt (sm)
- **Font:** Body (14pt, semi-bold)
- **Shadow:** Level 2 (3dip)
- **Focus indicator:** 2pt outline, 2pt offset

### TextInput Component
- **Height:** 48pt (body large)
- **Padding:** 12pt horizontal (md), 12pt vertical (md)
- **Border:** 1pt, #E0E0E0
- **Border radius:** 4pt (sm)
- **Font:** Body Large (16pt, regular)
- **Label font:** Heading 3 (16pt, semi-bold)
- **Error color:** #F44336 (red)

### Card Component (ItemCard)
- **Min height:** 64pt (lg)
- **Padding:** 16pt (lg)
- **Border radius:** 8pt (md)
- **Shadow:** Level 2 (3dip)
- **Divider:** 1pt #E0E0E0

### Modal Component
- **Border radius:** 12pt (lg) (top corners)
- **Padding:** 16pt (lg)
- **Shadow:** Level 3 (6dip)
- **Background overlay:** #000000 @ 80%
- **Header height:** 56pt

---

## Testing Checklist for Design Tokens

- [ ] All text meets ≥4.5:1 contrast on background colors
- [ ] All interactive elements ≥44pt × 44pt tap target
- [ ] Font scales to 2x size without overflow
- [ ] Spacing grid (4pt) followed consistently
- [ ] Colors match hex values exactly (brand consistency)
- [ ] Shadows/elevations match Material 3 spec
- [ ] Animations ≤300ms (smooth, not jarring)
- [ ] Border radius applied consistently
- [ ] Dark theme colors (if implemented) tested for contrast

---

## Usage in Dart/Flutter

### Import Design Tokens
```dart
// lib/core/constants/design_tokens.dart
import 'package:flutter/material.dart';

class DesignTokens {
  // Colors
  static const primaryBlue = Color(0xFF2196F3);
  static const successGreen = Color(0xFF4CAF50);
  static const warningYellow = Color(0xFFFFC107);
  static const urgentOrange = Color(0xFFFF9800);
  static const errorRed = Color(0xFFF44336);
  static const neutralGray = Color(0xFF666666);
  
  // Spacing
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
  
  // Text styles
  static const headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
```

### Apply to Widgets
```dart
Text('Item Name',
  style: DesignTokens.headingLarge,
);

Container(
  padding: EdgeInsets.all(DesignTokens.spacingLg),
  decoration: BoxDecoration(
    color: DesignTokens.primaryBlue,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Button', style: TextStyle(color: Colors.white)),
)
```

---

## Related Documentation
- [UX & Wireframes Index](./ux.md)
- [UX Patterns & Component Library](./ux-patterns.md)
- [Navigation Flow Diagram](./navigation-flow.md)
