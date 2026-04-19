# 610 — Launch: Google Play Staged Rollout Management

## Context
Google Play allows new apps and updates to be rolled out to a percentage of users rather than 100% at once. For a 1.0 launch this means starting at 5–20% of new installs and monitoring crash rates, ANR rates, and store ratings before expanding. Without a defined rollout plan and monitoring criteria, a critical crash that affects all new users can tank the app's algorithmic ranking before it has a chance to establish a track record.

## Goal
Define, document, and execute a staged rollout plan for the ZeroSpoils 1.0 Play Store launch, with explicit promotion criteria between stages and a rollback threshold.

## Expected behavior
- 1.0 release starts at 20% of new installs
- Promotion to 50% happens only when crash-free rate ≥ 99% and no P0 ANRs over a 48-hour observation window
- Promotion to 100% happens when 50% stage is stable for 72 hours with the same criteria
- Rollback is triggered if crash-free rate drops below 97% at any stage
- Play Console monitoring is checked daily during rollout period

## Acceptance criteria (Definition of Done)
- [ ] Staged rollout plan documented: stages (20% → 50% → 100%), promotion criteria, rollback criteria
- [ ] Play Console release notes written for 1.0 (English + French if i18n issue 195 is done)
- [ ] Content rating questionnaire completed in Play Console (Everyone rating)
- [ ] Data safety form completed (maps to privacy policy in issue 330)
- [ ] App signing: Play App Signing enabled and key uploaded
- [ ] 1.0 AAB (Android App Bundle) uploaded and approved
- [ ] Rollout started at 20%; promoted to 50% and 100% per documented criteria
- [ ] Staged rollout plan committed to repo: `docs/play-staged-rollout.md`
- [ ] Telemetry: Play Console vitals (crash rate, ANR rate) exported to ops dashboard

## Out of scope
- Google Play closed/open testing tracks (covered by issue 270 for internal testing)
- Paid Google UAC campaigns
- Pre-registration campaign (not in scope for 1.0)

## Implementation notes
- Upload AAB not APK — Play prefers AAB for size optimization; build pipeline (issue 030) should already produce AAB
- Data safety form: disclose Firebase Crashlytics (crash data), Firebase Remote Config (app functionality), FCM (push token); mark no data sold
- Content rating: answer "No" to all sensitive content questions → receives "Everyone" rating → required for food/productivity category
- Review timeline: Play typically approves new apps in 3–7 days; factor into launch date planning
- Play Console → Production → Create release → Enable staged rollout → set percentage

## Test plan
**Automated:**
- CI/CD release pipeline produces a valid AAB artifact: `./gradlew bundleRelease` succeeds
- AAB validated with `bundletool build-apks` before upload

**Manual:**
1. Upload AAB to Play Console internal testing first — verify it installs cleanly on a physical Android device
2. Complete data safety form — cross-reference with privacy policy (issue 330) to verify consistency
3. Submit for review — monitor Play Console review status dashboard until approved
4. Start staged rollout at 20% — verify install count climbing and crash-free rate reported in Play Vitals
5. Promote through stages per documented criteria — record each promotion decision with timestamp and metrics

## Dependencies
- 030 (build pipeline producing signed AAB)
- 270 (internal testing track complete and issues resolved)
- 310 (brand assets for Play listing)
- 320 (store listing copy)
- 330 (privacy policy URL for data safety form)
