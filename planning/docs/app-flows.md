# App Flow Document

## Purpose
Visualize end-to-end user journeys through the app with happy paths, edge cases, and decision points. Ensures consistent navigation and interaction patterns across screens.

## How to Fill
1. **User Journey Diagrams (Mermaid):** Create flowcharts for 5 core journeys
   - **Initial Setup → First Value:** Install → Onboarding → Permissions → Add first item → See expiring view → Receive first reminder
   - **Weekly Grocery Flow:** Review expiring items → Create shopping list → Shop → Add items to inventory → Notifications scheduled
   - **Daily Habit Loop:** Receive reminder → Open app → View expiring items → Mark consumed/wasted → Log outcome
   - **Settings & Preferences:** Access settings → Adjust reminder lead times → Configure notification quiet hours → Save preferences
   - **Shopping List Workflow:** Create list → Add items → Mark purchased → Convert to inventory → Update expiry dates

2. **Screen Transitions:** Document navigation patterns
   - Tab bar navigation (Inventory, Expiring, Shopping, Progress)
   - Left drawer navigation (Onboarding, Inventory, Expiring Soon, Shopping List, Progress, Settings)
   - Modal sheets for Add Item, Edit Item
   - Deep links from notifications to Expiring Soon screen

3. **Edge Cases:** Handle error states and empty states
   - First-run empty inventory ("Add your first item" CTA)
   - No expiring items ("All clear!" positive message)
   - Notification permission denied (graceful degradation)
   - Offline mode indicator

## How It Will Be Used
- **UX design:** Foundation for wireframes and screen mockups
- **Onboarding implementation (145):** Step-by-step flow validation
- **Navigation/routing setup (090):** Define route structure and deep link handling
- **Testing:** End-to-end integration test scenarios
- **Stakeholder review:** Visual walkthrough for feedback sessions
- **AI coding agents:** Reference for implementing navigation logic and state transitions

## Source Material
Synthesize from PRD Section 5.1 (Jobs-to-be-Done) and MVP issues (140-250) expected behaviors.

## Status
🚧 **PLACEHOLDER** - To be filled during M1 milestone completion. See `docs/wireframes/` for visual diagrams.
