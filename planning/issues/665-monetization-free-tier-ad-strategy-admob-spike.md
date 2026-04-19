# 665 — Monetization: Free Tier Ad Strategy and AdMob Spike

## Context
ZeroSpoils' current business model is free tier (core features) + Pro tier subscription (household sync, OCR, advanced analytics). Ads are a third monetization pillar that can generate revenue from free-tier users who never convert to Pro, without requiring them to pay. However, ads done badly destroy the user experience and contradict the brand's "calm and helpful" tone. This spike defines which ad formats are acceptable, evaluates expected revenue per user, and determines whether ads are worth integrating before or after the Pro tier launches.

## Goal
Evaluate ad monetization as a free-tier revenue complement, recommend an ad format and placement strategy, and produce a go/no-go recommendation with expected revenue estimate and UX impact assessment before any SDK integration work begins.

## Expected behavior
- Spike produces a written recommendation: ad formats to use, placements, expected eCPM range, projected monthly ad revenue at various DAU levels (1k, 5k, 10k, 50k)
- Recommendation explicitly addresses: does ad revenue meaningfully supplement Pro subscription revenue at realistic user scale? What is the DAU threshold at which ads become worth the UX tradeoff?
- Privacy/consent compliance path defined: GDPR (EU), COPPA (US), PIPEDA (Canada) implications of ad SDK data collection

## Acceptance criteria (Definition of Done)
- [ ] AdMob eCPM benchmarks researched for Canada/US for: banner ads, interstitial ads, rewarded video ads in Lifestyle/Food & Drink category
- [ ] Revenue projection model built: DAU × sessions/day × ad impressions/session × eCPM = monthly ad revenue (at 1k, 5k, 10k, 50k DAU)
- [ ] Ad formats evaluated for brand fit: banner (low revenue, low disruption), interstitial (moderate revenue, moderate disruption), rewarded video (high revenue, opt-in, high brand fit)
- [ ] Recommended format documented with rationale: recommendation is **rewarded video only** (opt-in, non-intrusive, aligns with "earn" mindset) — confirm or revise based on research
- [ ] Privacy compliance path documented: ATT (iOS App Tracking Transparency) prompt strategy, GDPR consent requirement (Google UMP SDK), PIPEDA compliance
- [ ] DAU viability threshold identified: minimum DAU at which ads generate >$100/month (practical break-even for the integration effort)
- [ ] Spike deliverable committed: `docs/ad-monetization-spike.md` with full analysis and recommendation
- [ ] Go/no-go decision recorded in the spike doc with reasoning

## Out of scope
- AdMob SDK integration (covered by issue 675 — only if this spike recommends proceeding)
- Direct ad sales / brand sponsorships (later stage when brand has sufficient audience)
- In-app purchases for ad removal (handled by Pro tier upgrade path)

## Implementation notes
- AdMob benchmark sources: Google AdMob help docs, AppFlood reports, Appodeal industry benchmarks, AdColony eCPM reports
- Recommended ad placement philosophy for ZeroSpoils: ads should NEVER appear during active item management (adding items, checking expiry). Acceptable placements: after completing a weekly streak summary, before viewing the savings history dashboard, as an optional "watch an ad to unlock a Zesto character" mechanic
- The "rewarded video to unlock Zesto characters" mechanic has dual value: ad revenue AND drives engagement with the gamification system. This should be the first ad format to evaluate seriously
- Privacy: AdMob requires ATT prompt on iOS (reduce IDFA collection consent request friction by timing after user has experienced value, not on first launch). GDPR: Google's UMP (User Messaging Platform) SDK handles consent banner for EU users — include in integration spec if proceeding
- Alternative ad networks to consider: Unity Ads (high eCPM for rewarded), ironSource (Tapjoy merger), AppLovin MAX (mediation) — include in spike if mediation is worth evaluating at small scale

## Test plan
**Automated:**
- N/A — spike is a research and analysis deliverable

**Manual:**
1. Build the revenue projection model in a spreadsheet — validate the formula with a peer review
2. Install 3 competitor apps (Fridgely, Best Before, similar) — evaluate their ad placement strategy and note UX impact (does it feel acceptable or intrusive?)
3. Review AdMob policy for Food & Drink category — verify no category restrictions exist
4. Review PIPEDA requirements for behavioral ad targeting in Canada — document compliance path

## Dependencies
- 410 (subscription strategy — ads are complementary monetization, must be positioned consistently with Pro value prop)
- 675 (AdMob integration — only starts after this spike produces a "go" recommendation)
