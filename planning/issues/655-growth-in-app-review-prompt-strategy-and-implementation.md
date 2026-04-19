# 655 — Growth: In-App Review Prompt Strategy and Implementation

## Context
App store ratings are a critical trust signal for new users and a ranking factor in both stores. ZeroSpoils already has a "Rate App" row in Settings (issue 375), but that is a passive entry — it only reaches users who open Settings and actively seek it. The industry-standard approach is a smart in-app prompt that appears at the right moment: after the user has experienced a genuine win (saved items, hit a streak milestone, used the app several times). A poorly timed prompt (e.g., on first launch) annoys users and yields 1-star revenge reviews. This issue defines the trigger logic and implements the prompt.

## Goal
Implement a smart in-app review prompt using the native `StoreKit` (iOS) and `In-App Review API` (Android) that appears only when the user is in a positive-experience state, and that can be tuned via Remote Config without an app release.

## Expected behavior
- Prompt appears after the user has: (a) used the app on at least 3 separate days AND (b) has added at least 5 items AND (c) has NOT been prompted in the last 90 days
- Prompt is suppressed for users who just experienced a crash (last session had a Crashlytics event)
- iOS: uses `SKStoreReviewController.requestReview()` — native prompt, no custom UI
- Android: uses `ReviewManager` from Play In-App Review API — native prompt
- All trigger criteria are Remote Config controlled (can loosen/tighten without a release)
- Prompt never appears more than 3 times per user (iOS system limit anyway, but enforced in-app)

## Acceptance criteria (Definition of Done)
- [ ] Trigger criteria implemented: session count ≥3, item count ≥5, days-since-last-prompt ≥90, no recent crash flag
- [ ] iOS: `SKStoreReviewController.requestReview()` called at trigger point (in-scene, not immediately on app open)
- [ ] Android: `ReviewManager.requestReviewFlow()` implemented with proper error handling
- [ ] Remote Config keys defined: `review_prompt_min_sessions`, `review_prompt_min_items`, `review_prompt_cooldown_days` (all overridable)
- [ ] Prompt trigger tracked as telemetry event: `review_prompt_shown` with properties: `trigger_session_count`, `trigger_item_count`, `days_since_install`
- [ ] Unit tests: trigger logic tested for all boundary conditions (exactly at threshold, just below, cooldown active)
- [ ] The Settings "Rate App" entry (issue 375) remains as manual fallback — its behavior is unaffected
- [ ] Telemetry: `review_prompt_shown` event added to telemetry schema

## Out of scope
- Custom rating UI (stars, text input) — use native platform prompts only (App Store policy prohibits custom rating UIs)
- Incentivized reviews (App Store policy violation)
- Tracking whether user actually left a review (platform APIs do not expose this)

## Implementation notes
- Flutter package: `in_app_review` (pub.dev) — wraps both StoreKit and Play In-App Review API
- Trigger point recommendation: after a successful "item saved" action (item marked as consumed before expiry) — this is the moment of maximum positive sentiment
- Crash suppression: check Hive local storage for a `last_crash_timestamp` key written by Crashlytics listener — if within last 24h, skip prompt
- iOS note: Apple limits `requestReview()` to 3 times per 365 days regardless of how many times the app calls it. Enforce a similar limit in-app to not "burn" all 3 on bad timing
- Remote Config default values: sessions=5, items=7, cooldown=90 days — conservative defaults, loosen after first month of ratings data

## Test plan
**Automated:**
- Unit test: `ReviewPromptService.shouldShowPrompt()` returns `false` when session count < threshold
- Unit test: returns `false` when cooldown period is active
- Unit test: returns `false` when `last_crash_timestamp` is within 24h
- Unit test: returns `true` when all criteria are met
- Widget test: review prompt is NOT shown on app cold start (first session)

**Manual:**
1. Install app fresh, add 7 items across 5 separate app sessions — verify prompt appears after session 5
2. Decline or dismiss prompt — reopen app — verify prompt does NOT reappear immediately (cooldown active)
3. Set `review_prompt_min_items` to 1 in Remote Config test environment — verify prompt fires with reduced threshold
4. Test on physical Android device — verify Play In-App Review flow renders the native Play Store review sheet

## Dependencies
- 375 (Rate App Settings entry — must remain working as fallback)
- 360 (Firebase Remote Config integrated)
- 155 or 160 (smart replenishment or streaks — one of these creates the "positive experience moment" ideal for triggering the prompt)
- Telemetry schema must include `review_prompt_shown` event
