# 615 — Launch: Public TestFlight External Beta

## Context
Issue 260 covers internal TestFlight (team members). Before submitting to the App Store for public release, running an external beta with real users outside the team catches usability issues, device-specific bugs, and copy confusion that internal testers miss. Apple allows up to 10,000 external testers via TestFlight without App Store review (first build requires basic review). This is the last quality gate before 1.0 public launch.

## Goal
Run a structured external beta via TestFlight with 50–200 real users over 2–3 weeks, triage all meaningful feedback, and ship a polished 1.0 candidate as a result.

## Expected behavior
- External beta invite links shared via relevant communities (ZeroWaste subreddit, sustainability Discord servers, personal networks)
- Beta testers receive clear onboarding instructions and a structured feedback prompt
- Crash reports and feedback reviewed weekly; blocking issues fixed before 1.0 submission
- Beta culminates in a documented "go/no-go" decision with explicit criteria

## Acceptance criteria (Definition of Done)
- [ ] External TestFlight group created with beta description and "What to Test" notes
- [ ] Public TestFlight link (or invite-only link) distributed to target tester profiles
- [ ] Minimum 30 real-device installs and 7 days of active usage data collected
- [ ] All crash reports from TestFlight reviewed and P0/P1 crashes resolved
- [ ] Beta feedback survey (Google Form or Tally) link included in TestFlight notes — minimum 10 survey responses
- [ ] Known issues list maintained in TestFlight notes for each build
- [ ] Go/no-go decision documented: criteria (crash-free ≥99%, no unresolved P0, ≥5 explicit "I'd use this daily" survey responses)
- [ ] Final beta build (last RC) == 1.0 submission binary (same build number)
- [ ] Beta summary document committed: `docs/beta-external-summary.md` (tester count, top feedback themes, issues resolved)

## Out of scope
- Android external beta (handled via Play open testing track — can be added as a sub-task of issue 270)
- Paid beta recruitment or beta testing services (Centercode, etc.)

## Implementation notes
- TestFlight external review: first build submitted for external testing requires Apple to review beta app — submit 5 days before intended beta start
- "What to Test" notes per build: focus testers on specific flows (onboarding, item entry, expiry notifications, shopping list)
- Feedback channels: TestFlight in-app feedback (screenshot + comment), plus a short survey for structured input
- Ideal tester profile: people who cook at home, grocery shop weekly, have some interest in reducing waste — not tech-savvy testers
- Build numbering: use `1.0.0 (rcN)` scheme; final RC that passes go/no-go is submitted as-is to App Store (no rebuild)

## Test plan
**Automated:**
- Beta build produced by CI on tag `rc/*` — identical pipeline to release build
- Firebase Crashlytics alerts configured: any new crash type → Slack/email within 1 hour

**Manual:**
1. Install beta on a device not previously used with ZeroSpoils — complete full onboarding from scratch
2. Add 5 items, set expiry dates, trigger a notification — verify notification arrives
3. Ask a non-technical family member or friend to install and use it for 3 days without guidance — observe and note confusion points
4. Review TestFlight crash logs weekly — open a GitHub issue for each unique P0/P1 crash
5. Go/no-go meeting: review crash rate, survey results, and known issues against documented criteria

## Dependencies
- 260 (internal TestFlight setup — external builds on the same pipeline)
- 360 (Firebase Crashlytics integrated for crash reporting during beta)
- 605 (App Store Connect account and app record must exist before external TestFlight group can be created)
