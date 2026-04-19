# 660 — Growth: Onboarding Funnel Analytics and First-7-Days Improvement Loop

## Context
The most critical period in any consumer app's lifecycle is the first 7 days. Users who don't experience value in that window churn and never return. ZeroSpoils has an onboarding flow (issue 145) and a first-run experience, but without instrumented funnel analytics, the team cannot know where users drop off, which permission prompts are declined, or whether users who complete onboarding actually add their first item. This issue defines the measurement framework and the process to iterate on the onboarding funnel post-launch.

## Goal
Instrument the full onboarding funnel with event analytics, define D1/D7 retention baseline targets, and establish a monthly iteration cadence for improving the first-run experience based on data.

## Expected behavior
- Every step of the onboarding flow fires a telemetry event so funnel completion rates are visible in Firebase Analytics
- D1 retention (users who return on Day 1 after install) target: ≥40% at launch
- D7 retention target: ≥20% at launch (industry average for consumer apps is 10–20%; ZeroSpoils should beat this given the habit-loop design)
- The "first item added" conversion rate from onboarding completion is tracked as the primary activation metric
- A monthly onboarding review meeting is in the ops calendar, with data from Firebase + user feedback from community

## Acceptance criteria (Definition of Done)
- [ ] Funnel events instrumented: `onboarding_started`, `onboarding_step_N_completed` (for each step), `onboarding_completed`, `permission_requested` (camera, notifications), `permission_granted`, `permission_denied`, `first_item_added`
- [ ] All events include standard properties: `platform`, `app_version`, `install_source` (if determinable)
- [ ] Firebase Analytics funnel visualization configured for the above event sequence
- [ ] D1 and D7 retention cohort queries set up in Firebase Analytics (or BigQuery export if needed)
- [ ] Baseline targets documented: D1 ≥40%, D7 ≥20%, onboarding-to-first-item-added ≥60%
- [ ] Month-1 funnel report produced: actual vs. target for each metric; top 3 drop-off points identified; 2 hypotheses for improvement
- [ ] Onboarding improvement backlog: at least 3 concrete hypotheses for A/B testing or iterative improvement based on Month-1 data
- [ ] All new events added to telemetry schema: `telemetry/events/onboarding.json`
- [ ] Unit tests: each funnel event fires exactly once per corresponding user action (no duplicate events)

## Out of scope
- A/B testing framework implementation (Phase 2 — use Firebase Remote Config for simple variant testing)
- Full product analytics platform (Mixpanel, Amplitude) — Firebase is sufficient for M5
- Onboarding redesign (this issue defines measurement; redesign is a follow-on issue based on data)

## Implementation notes
- `install_source` is deterministic on Android (Play Install Referrer API) and probabilistic on iOS (SKAdNetwork attribution) — implement Android first, iOS as best-effort
- D1 retention definition: user opens the app on a calendar day different from install day, within 24h of first install
- "Activation event" = `first_item_added` — this is the single most predictive leading indicator of 30-day retention for a pantry/inventory app
- Onboarding step numbering: align event names with actual onboarding screen order — document the mapping in telemetry schema
- Firebase Analytics retains raw events for 60 days; export to BigQuery for longer retention if needed post-launch

## Test plan
**Automated:**
- Unit test: `OnboardingAnalyticsService` fires `onboarding_step_1_completed` exactly once when step 1 screen is dismissed
- Unit test: `first_item_added` fires exactly once on the first item save (not on every subsequent save)
- Unit test: `permission_denied` fires when camera permission is denied — verify no crash
- Integration test: complete full onboarding flow in test harness — verify all expected events fire in sequence via mock analytics client

**Manual:**
1. Install app fresh on a device with Firebase DebugView enabled — walk through onboarding and verify each step event appears in DebugView in real-time
2. Deny notifications permission during onboarding — verify `permission_denied` fires and onboarding continues without crashing
3. Complete onboarding but do NOT add an item — verify `first_item_added` has not fired
4. 30 days post-launch: pull Firebase Analytics funnel report — verify step completion rates are populated and actionable

## Dependencies
- 145 (onboarding/first-run flow — this issue adds instrumentation to it)
- 360 (Firebase Analytics integrated)
- 625 (launch metrics dashboard — D1/D7 retention is part of that dashboard)
- Telemetry schema: `telemetry/events/onboarding.json` must be created/updated
