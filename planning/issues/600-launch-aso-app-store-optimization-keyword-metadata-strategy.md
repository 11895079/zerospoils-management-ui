# 600 — Launch: App Store Optimization (ASO) — Keyword, Metadata & Category Strategy

## Context
Writing store listing copy (issue 320) is necessary but not sufficient. ASO is the discipline of maximizing organic discoverability once the app is live: selecting the right category, optimizing the title, subtitle, and keyword fields to rank for high-intent search terms ("food expiry tracker", "grocery waste app", "pantry organizer"), and iterating based on impressions/conversion data. Without a deliberate ASO strategy, even a polished listing will be invisible.

## Goal
Research, document, and implement a keyword strategy for both the iOS App Store and Google Play that maximizes organic search discoverability at launch. Set up a process to iterate post-launch.

## Expected behavior
- App ranks in top 20 for at least 5 target high-intent keywords within 60 days of launch
- Title/subtitle (iOS) and title/short description (Play) incorporate primary keywords without sacrificing readability
- Long-tail keyword fields are fully populated (100-char iOS keyword field, Play metadata)
- Category selection justified with competitive analysis
- Baseline keyword ranking recorded at launch so iteration can be measured

## Acceptance criteria (Definition of Done)
- [ ] Primary keyword list researched (20–30 terms) using App Store Connect trends, Play Console, and free tools (AppFollow free tier, AppTweak trial, or sensor tower)
- [ ] Title and subtitle (iOS) and title + short description (Play) finalized with keywords embedded naturally
- [ ] iOS keyword field (100 chars) filled and justified
- [ ] Play metadata keywords embedded in long description
- [ ] Category selected: primary "Food & Drink" or "Health & Fitness" — justified with competitor analysis
- [ ] Keyword ranking baseline snapshot taken at launch (manual screenshot or export)
- [ ] Post-launch review cadence defined (monthly keyword review in ops calendar)
- [ ] Unit/widget/integration tests added or updated (N/A — ops/marketing artifact; store metadata files added to repo for version control)
- [ ] Telemetry: App Store search impressions + conversion rate tracked via App Store Connect / Play Console analytics
- [ ] Accessibility basics: N/A (metadata only)

## Out of scope
- Paid Apple Search Ads or Google UAC campaigns (separate budget decision)
- A/B testing store listing variants (App Store Connect product page optimization — Phase 2 post-launch)
- Competitive paid tools subscription (free tier research is sufficient for launch)

## Implementation notes
- iOS keyword field: 100 chars, comma-separated, no spaces after commas, no repeated words from title/subtitle
- Play does not have a separate keyword field — keywords must be woven into title, short description, and full description naturally
- Primary category recommendation: **Food & Drink** (higher traffic) with secondary consideration for **Productivity** (iOS allows one)
- Competitor apps to analyze: Fridgely, Kitche, Pantry Check, Best Before
- Store listing copy from issue 320 is the source text — ASO wraps and optimizes it, not replaces it
- Deliverable is a committed markdown file: `docs/aso-strategy.md` with keyword table, placement decisions, and rationale

## Test plan
**Automated:**
- CI check: `docs/aso-strategy.md` exists and is non-empty (shell script in CI)
- Schema check: keyword file contains required sections (keyword list, placement decisions, category justification)

**Manual:**
1. Search each of the top 5 target keywords in the App Store and Play Store — verify ZeroSpoils appears in results within 2 weeks of launch
2. Cross-check that the iOS keyword field contains no duplicates with title or subtitle (App Store Connect flags this as a warning)
3. Review Play Console "Search terms" report 30 days post-launch — verify top impressions terms align with strategy

## Dependencies
- 320 (store listing copy must be drafted first — ASO optimizes that text)
- App Store Connect and Google Play Console developer accounts must be active
