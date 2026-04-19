# 675 — Monetization: AdMob SDK Integration (Rewarded Video + GDPR/ATT Consent)

## Context
Following the ad spike (issue 665) and placement policy (issue 670), this issue implements the AdMob SDK, the rewarded video unit for the Zesto mascot unlock mechanic, and the privacy consent infrastructure (Google UMP for GDPR, ATT for iOS). This is a code-heavy issue with non-trivial privacy compliance requirements and must follow the placement policy as a hard constraint.

## Goal
Integrate Google Mobile Ads SDK (AdMob) into the Flutter app with a rewarded video ad unit tied to the Zesto mascot unlock mechanic, full GDPR/PIPEDA consent flow, and iOS ATT prompt — all without violating the ad placement policy from issue 670.

## Expected behavior
- On the Achievements screen, users see an offer: "Watch a short video to unlock [Mascot Name]" — tapping it shows a rewarded video ad
- If the user watches to completion, the mascot unlock is granted and persisted to Hive local storage
- If the user dismisses the ad, no reward is granted and no penalty is applied
- GDPR consent banner appears for EU users before any ad is served (Google UMP SDK)
- iOS ATT prompt appears after onboarding completion and first item added (not on first launch)
- Admob ad unit IDs and app IDs are stored in Remote Config / environment config, not hardcoded

## Acceptance criteria (Definition of Done)
- [ ] `google_mobile_ads` Flutter package added to `pubspec.yaml`
- [ ] AdMob app IDs registered for iOS and Android in AdMob console; test app IDs used in debug builds
- [ ] Rewarded video ad unit created in AdMob console; test ad unit ID used in debug/staging builds
- [ ] `RewardedAdService` implemented: loads ad, tracks load/failure, calls `show()` on successful load only
- [ ] Reward callback: on successful watch completion, calls `MascotUnlockService.unlockMascot(mascotId)` — persisted to Hive
- [ ] Placement enforcement: `RewardedAdService` enforces that ad is only shown from the Achievements screen (throws assertion in debug if called from elsewhere)
- [ ] Google UMP consent SDK integrated: consent form displayed to EU-region users before first ad request; consent status stored and respected on subsequent launches
- [ ] iOS ATT prompt: `AppTrackingTransparency` package integrated; prompt shown after `first_item_added` event fires, not before
- [ ] Ad unit IDs and app IDs loaded from `--dart-define` or `flutter_dotenv` (not hardcoded in source)
- [ ] Test mode enforced in debug builds: test device IDs registered in `RequestConfiguration`
- [ ] Telemetry events: `ad_rewarded_offered`, `ad_rewarded_started`, `ad_rewarded_completed`, `ad_rewarded_dismissed`, `mascot_unlocked_via_ad`
- [ ] Unit tests: `RewardedAdService` state machine (loading → ready → showing → completed/dismissed)
- [ ] Widget test: Achievements screen shows "Watch video" offer when ad is loaded and hides it when not loaded
- [ ] All new events added to telemetry schema

## Out of scope
- Banner or interstitial ad units (Phase 2 — rewarded video only for launch per placement policy)
- Ad mediation waterfall (AdMob direct only for M5; add MAX/ironSource mediation post-launch)
- Server-side reward verification (sufficient for cosmetic unlocks; required for real-value rewards)

## Implementation notes
- Flutter package: `google_mobile_ads` (official Google package on pub.dev)
- UMP SDK: included in `google_mobile_ads` package — initialize via `ConsentInformation.instance.requestConsentInfoUpdate()`
- ATT package: `app_tracking_transparency` on pub.dev; must add `NSUserTrackingUsageDescription` to `Info.plist`
- Test ads: use Google's test ad unit IDs during development — NEVER request live ads with a test device (policy violation)
- GDPR: if consent is not obtained, still show ads but with `npa=1` (non-personalized ads) — do not block ad serving for non-consent, just degrade to non-personalized
- PIPEDA (Canada): no opt-in consent requirement for behavioral advertising in Canada (unlike GDPR) — standard privacy policy disclosure is sufficient; document this in the spike (issue 665)
- AdMob initialization must happen before any ad is requested but AFTER consent status is determined

```dart
// Initialization order (critical):
// 1. Initialize UMP consent SDK
// 2. Check consent status
// 3. Initialize MobileAds.instance (with npa=1 if no consent)
// 4. Load first ad unit
```

## Test plan
**Automated:**
- Unit test: `RewardedAdService` starts in `notLoaded` state, transitions to `loading` on `loadAd()`, to `ready` on mock load success
- Unit test: `rewardCallback` calls `MascotUnlockService.unlockMascot()` exactly once on completion
- Unit test: `rewardCallback` is NOT called when ad is dismissed before completion
- Widget test: "Watch video to unlock" CTA is visible when `RewardedAdService.isReady == true`
- Widget test: CTA is hidden or shows "loading..." when ad is not ready
- Integration test: UMP consent flow mock — verify `MobileAds.initialize()` is NOT called before consent status is resolved

**Manual:**
1. Run app in debug mode — verify test ads appear (AdMob test ad with "Test Ad" watermark)
2. Watch a test rewarded ad to completion — verify mascot unlock granted and persists across app restart
3. Dismiss a test rewarded ad mid-video — verify mascot is NOT unlocked
4. Test on a device with region set to Germany (EU) — verify UMP consent banner appears before first ad
5. Test ATT prompt timing on iOS: install fresh, complete onboarding, add first item — verify ATT prompt appears after item is added, not before

## Dependencies
- 665 (ad spike must confirm "go" decision before this issue is scheduled)
- 670 (ad placement policy — placement enforcement in code references the policy)
- 375-zesto (unlockable mascot characters — this issue integrates with that unlock mechanic)
- 360 (Firebase Remote Config — ad unit IDs and feature flag `ads_enabled` stored there)
- Telemetry schema must include all 5 new ad events
