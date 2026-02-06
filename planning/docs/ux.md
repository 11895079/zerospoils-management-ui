# UX Foundations Document

## Purpose
Document core UX principles, interaction patterns, component guidelines, and navigation structure. Provides visual reference for consistent implementation across all screens.

## How to Fill
1. **Design Principles:**
   - **Minimal friction:** Reduce typing; prefer taps, swipes, defaults
   - **Encouraging tone:** Non-judgmental messaging (avoid "wasted" guilt)
   - **Offline-first:** Clear offline indicators; no blocking network calls
   - **Accessibility-first:** WCAG 2.1 AA compliance; touch targets ≥44pt

2. **Component Patterns:**
   - **Buttons:** Primary (solid), secondary (outline), tertiary (text-only)
   - **Lists:** Swipeable cards with quick actions (mark consumed, edit, delete)
   - **Modals:** Bottom sheet for Add/Edit Item (dismissible, form validation)
   - **Empty states:** Illustrated placeholders with actionable CTAs
   - **Dialogs:** Confirmation for destructive actions (delete item)

3. **Interaction Primitives:**
   - **Quick add:** Floating action button (FAB) on Inventory screen
   - **Swipe actions:** Left swipe = Delete, Right swipe = Mark consumed
   - **Pull to refresh:** Update expiry bucketing (even in offline mode)
   - **Tab bar navigation:** 4 tabs (Inventory, Expiring, Shopping, Progress)
   - **Left drawer navigation:** Onboarding, Inventory, Expiring Soon, Shopping List, Progress, Settings
   - **OCR capture:** Camera button (📷) in expiry date field; tap → camera overlay with focus area → capture → extract → pre-fill

4. **Wireframes:** Link to screen mockups
   - Add Item (modal sheet with form fields)
   - Inventory List (searchable list with category filters)
   - Expiring Soon (bucketed list: Today / This Week / Expired)
   - Item Detail (full-screen with edit/consume/discard actions)
   - Shopping List (Next Shop list with checkboxes)
   - Settings (reminder preferences, about, privacy)
   - Onboarding (3-step intro with permissions)

## How It Will Be Used
- **Design handoff:** Figma links and Mobbin inspiration references
- **Implementation:** All MVP screens (140-210) reference these patterns
- **QA/testing:** Visual regression testing baseline
- **Accessibility audit (165):** Compliance checklist validation
- **AI coding agents:** Consistent component usage; prevents reinventing patterns

## Source Material
Research Mobbin/Behance for inventory/expiry tracking patterns. Extract requirements from issue 050-wireframes and 070-notification-ux-defaults.

## Links
- See `docs/wireframes/` folder for Mermaid diagrams and Figma prompts
- See `docs/design-tokens.md` for spacing, typography, colors

## Status
🚧 **PLACEHOLDER** - To be filled during M1 milestone completion.
