# MVP Scope Document

## Purpose
Define executable specification for Minimum Viable Product: features included, explicit non-goals to prevent scope creep, and success metrics to measure MVP effectiveness.

## How to Fill
1. **MVP Features (In Scope):** List each feature with brief description and acceptance criteria
   - Manual item entry/editing (name, category, location, quantity/unit, expiry date)
   - On-device OCR for expiry dates (optional enhancement to reduce manual entry friction)
   - Inventory list view with search/filter
   - Expiring soon view (bucketed: today/this week/expired)
   - Smart reminders (configurable lead times: 1/3/5 days before expiry)
   - Shopping list with "Next Shop" workflow
   - Purchased items convert to inventory
   - Offline-first (all core features work without internet)
   - Data export/delete (privacy baseline)

2. **Non-Goals (Explicitly Out of Scope):** Features deferred to Pro tier or future releases
   - Full receipt OCR / batch photo capture with computer vision
   - Barcode scanning
   - Household sync/multi-user accounts
   - Advanced analytics dashboard
   - IoT integrations (NFC tags, smart shelves)
   - Meal planning

3. **Success Metrics:** Measurable KPIs to validate MVP effectiveness
   - Items added per user per week
   - Reminder open rate
   - Items marked consumed vs. wasted (waste reduction %)
   - 7-day retention rate
   - Time from install to first item added

## How It Will Be Used
- **Development teams:** Reference for feature prioritization and implementation scope
- **Product/design:** Boundary for UX flows and screen designs
- **Stakeholders:** Alignment on MVP definition and launch readiness criteria
- **Issue creation:** Source of truth when writing acceptance criteria for MVP issues (140-250)
- **AI coding agents:** Direct prompt for implementing features; prevents scope creep questions

## Source Material
Extract from `ZeroSpoils_Market_Report_FINAL_fixed_citations.md` Section 6.2 (MVP Features) and Section 6.3 (Extended Roadmap - use to define non-goals).

## Status
🚧 **PLACEHOLDER** - To be filled during M1 milestone completion.
