# 625 — Launch: First-48h Metrics Dashboard and Post-Launch Health Monitoring

## Context
The 48 hours after launch are the highest-signal, highest-stakes window of the product lifecycle. App store algorithms form early signals about install velocity, crash rate, and retention. Without a defined set of metrics, thresholds, and a dashboard pre-built before launch, the team is flying blind and reacting to anecdote rather than data. This issue builds the monitoring setup that turns launch day from chaotic to measured.

## Goal
Define the key launch health metrics, configure dashboards in Firebase + App Store Connect + Play Console, and set alert thresholds that allow the team to distinguish a healthy launch from one requiring urgent action — all before launch day.

## Expected behavior
- Dashboard is live and showing data within 1 hour of first installs
- Alerts fire to Slack/email within 15 minutes of a threshold breach
- Team can answer the following questions at any point in the first 48h: new installs (iOS + Android), crash-free rate, D1 retention rate, avg session length, top error types
- Weekly health report template defined and sent after week 1

## Acceptance criteria (Definition of Done)
- [ ] Key metrics defined and documented: installs, DAU, crash-free rate, D1 retention, session length, items added, notification opt-in rate
- [ ] Firebase Analytics dashboard configured with those events (verify events fire via DebugView before launch)
- [ ] App Store Connect Analytics and Play Console Acquisition reports bookmarked and verified showing real data in staging
- [ ] Alert thresholds set in Firebase Crashlytics: crash-free rate alert if <98% over 1-hour rolling window
- [ ] Slack/email webhook configured for Crashlytics alerts
- [ ] Post-launch metrics report template created: `docs/launch-metrics-template.md`
- [ ] Week-1 metrics report produced and committed after launch: `docs/launch-metrics-week1.md`
- [ ] Telemetry: key events instrumented in app — `app_open`, `item_added`, `notification_opt_in`, `onboarding_complete` (verify in telemetry schema)

## Out of scope
- Advanced product analytics tooling (Mixpanel, Amplitude) — Firebase is sufficient for M5
- Paid monitoring tools
- Long-term retention cohort analysis (Month 1+ — post-launch)

## Implementation notes
- Firebase Analytics retention: set user property `install_date` at first launch for D1/D7/D30 cohort queries
- Play Console "Acquisition reports" shows store listing conversion rate — useful for validating ASO issue 600
- App Store Connect "Metrics" tab: check Impressions, Product Page Views, Conversion Rate, Sessions, Active Devices
- Set up a single bookmarked dashboard page or Notion doc with links to all consoles so the team doesn't waste time finding them on launch day
- Weekly health report should be <1 page: installs, retention, top crashes, notable feedback themes, one action item

## Test plan
**Automated:**
- Firebase DebugView: run `flutter run --dart-define=FIREBASE_DEBUG=true` — verify all key events appear in real-time DebugView before launch
- Unit test: telemetry event schemas validated against `telemetry/events/*.json` schema files

**Manual:**
1. Pre-launch: open Firebase Analytics → Events — verify `app_open` and `item_added` events appear for a test device
2. Pre-launch: trigger a test crash via Crashlytics test API — verify alert fires to configured Slack channel within 15 minutes
3. Launch +1h: confirm install events are incrementing in App Store Connect and Play Console
4. Launch +24h: pull first data export — verify D0 retention definition is correct (session on install day)
5. Day 7: produce week-1 report from template — verify all metric fields are populated

## Dependencies
- 360 (Firebase Crashlytics + Analytics integrated)
- 390 (ops observability baseline)
- 605 (App Store Connect account active)
- 610 (Play Console active)
- Telemetry schema files in `telemetry/` must include all key events above
