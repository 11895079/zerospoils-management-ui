# 620 — Launch: Launch-Day Operations Plan and War Room Playbook

## Context
Public launch is a time-compressed, high-visibility event. Without a choreographed plan, things break silently (store listing not live in a region, notifications misfiring, social posts going out before the app is actually available), and the team scrambles reactively. A launch-day playbook defines the exact sequence of events, who is responsible for each action, what monitoring is being watched, and what constitutes a "halt launch" signal.

## Goal
Produce and rehearse a launch-day operations document covering the hour-by-hour sequence from T-48h to T+24h, including store availability verification, announcement timing, monitoring thresholds, and an on-call rotation.

## Expected behavior
- All team members know their launch-day role before launch day
- Store listings go live in the correct sequence (Play first since review is faster, then App Store)
- Social media announcements are pre-written and scheduled, triggered only after store availability is confirmed
- Monitoring dashboard is open and being watched from T-0 to T+24h
- Any P0 issue (crash rate >3%, store listing pulled, payment processing down) triggers a documented response

## Acceptance criteria (Definition of Done)
- [ ] Launch timeline written: T-48h (final checklist), T-24h (staging confirmation), T-0 (go-live), T+1h, T+4h, T+24h checkpoints
- [ ] Role assignments defined: who monitors crash dashboard, who publishes social posts, who triages user reviews/emails
- [ ] Pre-written social posts for each channel (Instagram, TikTok, Reddit, X) ready and scheduled in scheduling tool — NOT auto-published; require manual trigger after store confirmation
- [ ] Store availability spot-check script or manual checklist: verify app is downloadable from a fresh device in CA, US, UK
- [ ] Monitoring dashboard active (Firebase Crashlytics + Play Console Vitals + App Store Connect analytics)
- [ ] Halt criteria documented: crash-free rate <97%, payment-related crash (if applicable), App Store listing pulled for policy violation
- [ ] Rollback plan: Play staged rollout halt at current %, iOS expedited review request process documented
- [ ] Playbook committed to repo: `docs/launch-day-playbook.md`

## Out of scope
- Long-term community management (covered by issue 635)
- Paid advertising campaigns at launch
- Press embargo management (not in initial scope unless press outreach issue 650 is completed first)

## Implementation notes
- Play Store goes live within hours of approval; App Store typically at 12:00 AM PST on release date if scheduled
- Sequence recommendation: schedule Play release 1 day before iOS — gives 24h to catch Android-specific issues before iOS launch amplifies traffic
- Social scheduling tools: Buffer, Later, or Hootsuite free tiers are sufficient for launch
- "War room" is async-friendly: a shared Slack/Discord channel with pinned monitoring links, not necessarily everyone on a call

## Test plan
**Automated:**
- Smoke test suite runs on release candidate: `flutter test integration_test/` — must pass before any launch action
- Uptime monitor (e.g. UptimeRobot free) configured for any web-facing assets (privacy policy URL, terms URL)

**Manual:**
1. T-24h dry run: follow the playbook start-to-finish using staging environment — identify any missing steps
2. T-0 store availability check: attempt to find and install the app from a device in incognito/fresh profile — confirm listing shows correct copy and screenshots
3. T+1h: verify crash-free rate is reported in Firebase and Play Console (not just "no data yet")
4. T+4h: check all scheduled social posts actually published — verify store links in posts resolve correctly
5. T+24h retrospective: note what went to plan and what didn't — update playbook before next release

## Dependencies
- 320 (store listing copy finalized)
- 605 (App Store Connect submission complete)
- 610 (Play staged rollout plan documented)
- 630 (social media accounts exist before scheduling posts)
- 640 (brand voice guidelines so posts are on-tone)
- 390 (ops observability baseline active)
