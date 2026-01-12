# Design Tokens Document

## Purpose
Define reusable design system values (spacing, typography, colors, touch targets) to ensure visual consistency and accessibility compliance across the app.

## How to Fill
1. **Spacing Scale (8pt grid):**
   - `spacing-xs`: 4pt (tight padding)
   - `spacing-sm`: 8pt (default padding)
   - `spacing-md`: 16pt (section spacing)
   - `spacing-lg`: 24pt (screen margins)
   - `spacing-xl`: 32pt (hero spacing)

2. **Typography:**
   - **Font family:** System default (SF Pro on iOS, Roboto on Android)
   - **Scale:** 
     - `text-xs`: 12pt (captions, helper text)
     - `text-sm`: 14pt (body text, list items)
     - `text-base`: 16pt (default body)
     - `text-lg`: 18pt (section headers)
     - `text-xl`: 24pt (screen titles)
     - `text-2xl`: 32pt (hero headings)
   - **Weights:** Regular (400), Medium (500), Bold (700)

3. **Color Palette:**
   - **Primary:** Green (#2f9e44) - sustainable theme
   - **Secondary:** Orange (#f08c00) - expiring items alert
   - **Danger:** Red (#e03131) - expired items
   - **Neutral:** Gray scale (#f8f9fa to #343a40)
   - **Background:** White (#ffffff)
   - **Surface:** Light gray (#f1f3f5) for cards
   - **Text:** Dark gray (#212529) primary, (#6c757d) secondary

4. **Touch Targets:**
   - Minimum tap target: **44pt × 44pt** (WCAG 2.1 AAA)
   - Interactive elements: Add 8pt padding around visual bounds

5. **Contrast Ratios:**
   - Normal text: **4.5:1** minimum (WCAG AA)
   - Large text (18pt+): **3:1** minimum
   - Icons and UI components: **3:1** minimum

## How It Will Be Used
- **Theme implementation (090):** Flutter theme configuration
- **All MVP screens:** Consistent styling references
- **Accessibility audit (165):** Compliance validation
- **Brand consistency:** Unified visual identity
- **AI coding agents:** Authoritative token values; prevents arbitrary sizing/colors

## Source Material
Research best practices for mobile design systems. Align with Material Design 3 and iOS Human Interface Guidelines.

## Status
🚧 **PLACEHOLDER** - To be filled during M1 milestone completion.
