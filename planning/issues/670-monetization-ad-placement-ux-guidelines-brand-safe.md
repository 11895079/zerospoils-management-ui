# 670 — Monetization: Ad Placement UX Guidelines and Brand-Safe Ad Policy

## Context
If the ad spike (issue 665) recommends proceeding with ads, ZeroSpoils needs a UX contract that governs where, when, and how ads appear — before a single line of AdMob integration code is written. Without this contract, the temptation to maximize impression count leads to placements that feel intrusive, damage trust, and cause users to churn or leave negative reviews. This document is the UX guardrail for all current and future ad placements.

## Goal
Define a brand-safe ad placement policy that maximizes ad revenue while preserving ZeroSpoils' calm, helpful, non-intrusive experience. Any engineer or product person should be able to evaluate a proposed ad placement against this policy and get a clear yes/no answer.

## Expected behavior
- Every proposed ad placement can be evaluated against the policy in under 60 seconds
- No ad ever appears during: item entry, expiry alerts, shopping list management, or any flow where the user is completing a task
- Rewarded video placements are always opt-in with a clear "skip" path that doesn't penalize the user
- The policy is versioned and any changes require explicit review

## Acceptance criteria (Definition of Done)
- [ ] Ad placement allowlist defined: screens/moments where ads ARE acceptable
- [ ] Ad placement denylist defined: screens/moments where ads are NEVER acceptable (hard rule)
- [ ] Rewarded video UX spec: trigger moment, offer description to user ("Watch a short video to unlock Zesto's Carrot character"), skip/dismiss path, reward delivery timing
- [ ] Banner ad spec (if used): maximum banner height, placement (bottom only — never interrupts content), no ads within 48dp of interactive elements (App Store / Play Store policy compliance)
- [ ] Frequency caps defined: max 1 rewarded video offer per session, max 2 interstitial per day
- [ ] User control: "Ad preferences" entry in Settings — either opt out of personalized ads (via ATT/UMP) or opt out of all ads via Pro upgrade CTA
- [ ] Policy document committed: `docs/ad-placement-policy.md`
- [ ] Policy reviewed against AdMob and App Store / Play Store ad content policies (document compliance)

## Out of scope
- AdMob SDK integration code (covered by issue 675)
- Ad creative design (AdMob serves creatives from advertisers — ZeroSpoils does not produce ad creative)
- Mediation waterfall configuration

## Implementation notes
**Allowlist (ads acceptable here):**
- After completing "Weekly Streak Summary" screen — user is in a celebratory, positive state
- On the "Savings History" empty state (first visit before data exists) — user not mid-task
- As an optional reward mechanic: "Watch a video to unlock a Zesto mascot character" on the Achievements screen
- Between app sessions (interstitial on cold start — only after 3+ prior sessions, never on first 3 opens)

**Denylist (ads never here):**
- Any item entry or editing flow
- Expiry notification tap-through screens
- Shopping list active editing
- Onboarding flow (all screens)
- Any error or empty state where user needs help
- Within 1 screen of a Crashlytics-detected error session

**ATT prompt timing (iOS):** Show ATT only after the user has completed onboarding and added their first item. Never show ATT on first app open — this is both bad UX and contradicts Apple's usage-before-prompt recommendation.

## Test plan
**Automated:**
- N/A — UX policy document, not a code artifact
- Once issue 675 is implemented: integration test verifies no ad is shown on any denylist screen (mock ad SDK, assert no impression event fires on those screens)

**Manual:**
1. Walk through the full app using the allowlist/denylist — mark every screen as "allow" or "deny" with rationale — verify the policy covers all screens without ambiguity
2. Review AdMob content policy and Play Store / App Store ad policies — cross-check against the denylist for any policy-required restrictions not already captured
3. User test: show a prototype with a rewarded video placement (in Achievements) to 3 users — ask "Does this feel intrusive?" — target: 0/3 say yes

## Dependencies
- 665 (ad spike must recommend proceeding before this policy has value)
- 675 (integration issue references this policy for placement decisions)
- 310 (brand assets — Zesto mascot characters used in rewarded video offer UX)
- 375-zesto (unlockable mascot characters — these are the reward for rewarded video)
