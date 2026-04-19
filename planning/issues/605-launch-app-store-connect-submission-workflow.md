# 605 — Launch: App Store Connect Submission Workflow (Apple Review Preparation)

## Context
Submitting to the iOS App Store involves far more than uploading a binary. Apple requires screenshots at exact pixel dimensions for every supported device size, an age rating questionnaire, export compliance declaration (for any encryption use), privacy nutrition labels (data types collected, purposes, third-party SDKs), review notes for the reviewer, and a demo account if the app has authentication. Skipping or mis-filling any of these causes rejection, which costs days. This issue ensures the submission is prepared correctly the first time.

## Goal
Produce a complete App Store Connect submission package — screenshots, metadata, privacy labels, and compliance declarations — and submit the 1.0 binary for Apple review without rejection.

## Expected behavior
- All required screenshot sizes produced and uploaded (6.7", 6.1", 5.5" iPhone; 12.9" iPad if supported)
- Privacy nutrition labels accurately reflect all data collected (crash logs, usage data, identifiers via Firebase)
- Export compliance: app uses standard HTTPS/TLS encryption → select "Yes, uses standard encryption" and provide BPS exemption
- Age rating: 4+ (no objectionable content, no user-generated public content)
- Review notes include: demo flow description, any features requiring specific permissions (camera, notifications)
- 1.0 submitted and approved without rejection

## Acceptance criteria (Definition of Done)
- [ ] Screenshot set produced for all required device sizes using the Xcode simulator (or Fastlane Snapshot if available)
- [ ] Screenshots reviewed for correct content, no status bar artifacts, and brand alignment
- [ ] Privacy nutrition labels completed in App Store Connect (data types: crash data, performance data; third-party: Firebase Crashlytics, Remote Config)
- [ ] Export compliance declaration complete (standard HTTPS encryption, BPS exemption)
- [ ] Age rating questionnaire answered (4+)
- [ ] Review notes written: summary of app purpose, demo credential if needed, permission justifications (camera for OCR, notifications for expiry reminders)
- [ ] 1.0 binary uploaded via Xcode Organizer or `xcrun altool` / Fastlane
- [ ] Binary passes automated App Store review checks before human review
- [ ] App approved and released (or scheduled release configured)
- [ ] Submission checklist committed to repo: `docs/app-store-submission-checklist.md`
- [ ] Telemetry: first install source tracked via App Store Connect analytics

## Out of scope
- App Store product page optimization / A/B testing (post-launch)
- Paid Apple Search Ads setup
- TestFlight external beta (covered by issue 615)

## Implementation notes
- Required screenshot sizes (2026): 6.7" (1290×2796), 6.5" (1242×2688), 5.5" (1242×2208), and 12.9" iPad Pro (2048×2732) — check App Store Connect for current requirements at submission time
- Firebase SDKs (Crashlytics, Remote Config, FCM) require disclosure under "Analytics → Crash Data" and "App Functionality" in privacy labels
- If using any third-party analytics beyond Firebase, audit and disclose all
- Camera usage: privacy label discloses "Camera" under "App Functionality" only (not sold/linked to identity)
- Demo account: create a stable demo@zerospoils.app account with pre-populated inventory for reviewer
- App review typically takes 24–48 hours; plan submission at least 5 business days before target launch date

## Test plan
**Automated:**
- CI/CD release pipeline (issue 030) produces an IPA artifact on git tag — verify IPA is valid with `xcrun altool --validate-app`
- Screenshot dimensions validated by a script against Apple's required sizes before upload

**Manual:**
1. Upload IPA to App Store Connect → verify "No issues found" before submitting for review
2. Walk through each privacy label section — verify no undisclosed data collection exists
3. Review notes: ask a team member unfamiliar with the app to follow the review notes and successfully demo core features
4. Post-approval: download from the App Store on a device not enrolled in TestFlight — verify clean install and onboarding flow

## Dependencies
- 030 (build pipeline producing signed IPA)
- 310 (brand assets: icon, screenshots concept)
- 320 (store listing copy)
- 330 (privacy policy hosted URL — required for privacy label URL field)
- 615 (external TestFlight beta should be complete before public submission)
