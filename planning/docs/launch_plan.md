# ZeroSpoils Launch Plan (Now -> June 2026)

## Purpose

Lock in a practical, low-risk path from the current build state to public launch in June 2026, while starting demand generation immediately through organic channels and a waitlist.

Reference input: launch framework notes synthesized from Chris Raroque's app-launch framework video.

---

## Current Reality Check (May 4, 2026)

### Product readiness (from milestone status)
- M3 is materially advanced, with key MVP foundations complete.
- Remaining M3 quality gaps that affect launch confidence:
	- Issue 201: receipt review UX completion (tri-color overlay + promote/demote workflow)
	- Issue 202: confirmation confidence indicators + telemetry verification
	- Issue 361: Firebase App Distribution tester workflow still open
	- Reference-data update packs are implemented and no longer a launch blocker; keep any extra rollout guardrails in the post-launch hardening backlog only if telemetry or ops need more work.

### Beta and hardening readiness
- M4/370 is near-complete; one critical item remains: server-side endpoint gating.
- M4/280 and M4/285 feedback flow is still placeholder.
- M4/295 dark mode is functionally done; manual contrast QA remains.

### Launch operations readiness
- M5 includes launch and growth tracks, but is mostly unstarted.
- This means June launch is possible only with strict scope control: ship core value + must-have launch infrastructure; defer non-critical expansion.

---

## Launch Strategy

### Strategy type
Organic-first launch with staged exposure:
- Build in public lightly (weekly updates, no heavy paid acquisition)
- Run closed beta immediately
- Collect waitlist now
- Use retention and crash data to determine launch confidence
- Launch in June with staged rollout, not all-at-once

### Scope rule for June
Must ship by launch:
- Reliable core item flows
- Stable receipt/batch flow for target users
- Crash and telemetry visibility
- Feedback capture loop
- Store listings and release operations

Can defer to post-launch:
- Nice-to-have growth features
- Broad social/community automation
- Pro-tier and advanced roadmap items

---

## Execution Plan by Workstream

## 1) Product and quality gate (must pass)

### Work to complete before launch candidate
- Finish M3/201 user-facing review loop (hidden lines + promote/demote)
- Close M3/202 UX/telemetry gaps
- Complete M4/370 server-side endpoint gating
- Complete M4/295 manual contrast/accessibility pass

### Launch quality gates
- Crash-free sessions >= 99.5% over 7 days of beta
- No P0/P1 open defects
- Receipt capture and add-item critical paths pass regression on both iOS and Android
- Cold start and scroll performance meet current M4 targets

## 2) Beta distribution and feedback loop (start now)

### Immediate
- Start rolling weekly beta drops to a small tester cohort (10-20 users)
- Use existing channels first: Firebase App Distribution and store internal tracks
- Prioritize M3/361 and M4/275 so tester feedback is operational, not ad hoc

### Required loop per build
- Publish release notes
- Collect qualitative feedback
- Triage within 24-48h
- Ship at least one visible fix/improvement per week

## 3) Waitlist and landing pages (start this week)

### Waitlist page (immediate)
Goal: collect intent and recruit high-quality testers before launch.

Minimum page sections:
- Clear value prop (reduce household food waste, save money)
- 3 core benefits
- 1 product screenshot or short GIF
- Email form + optional platform selection (iOS/Android)
- Lightweight privacy notice

Data to capture:
- Email
- Platform interest
- Optional country
- Optional top pain point

### Public landing page (June launch asset)
Build second page (or expand waitlist page) for launch week:
- Product story
- Feature overview
- Social proof from beta testers
- Store buttons
- FAQ and support links

## 4) Analytics and launch decision framework

### Metrics to watch weekly (now through launch)
- Activation: onboarding complete rate, first item added rate
- Early retention: D1 and D7
- Reliability: crash-free users/sessions, ANR on Android
- OCR flow quality: attempt success, manual correction rate, abandonment points
- Feedback throughput: number submitted, median time to first response, resolved count

### June go/no-go criteria
- D1 >= 35% in beta cohort
- D7 >= 15% in beta cohort
- Crash-free sessions >= 99.5%
- No unresolved security/privacy blockers
- Support process ready (triage owner + SLA)

If criteria are not met by launch week, use a staged soft launch (region-limited or cohort-limited) and continue hardening.

## 5) Organic growth plan (test waters now)

### Weekly cadence (starting now)
- 2 short build-progress posts (before/after, bug fix, feature highlight)
- 1 practical food-waste tip post connected to app behavior
- 1 tester call-to-action post to waitlist
- 1 feedback recap post: "you asked, we shipped"

### Channels
- Priority: X, LinkedIn, Reddit (relevant subreddits), personal network
- Optional: Product Hunt teaser and launch prep

### Content angles that fit ZeroSpoils
- Money saved by reducing spoilage
- Expiry rescue wins
- Real beta user workflows
- "Built this week" transparent changelog style

## 6) Store readiness and launch operations

### Must complete before submission
- App Store and Play listing copy and screenshots
- Privacy policy + terms links live and wired in app
- Release checklist and rollback plan
- First-48h monitoring dashboard ready

### Launch week approach (June)
- T-14 days: finalize screenshots/copy, freeze launch scope
- T-7 days: release candidate to broad beta, no new feature risk
- T-3 days: final bug triage and store submission checks
- Launch day: staged rollout + active monitoring window
- T+1 to T+7 days: daily patch window for critical fixes

---

## Week-by-Week Plan (May -> June)

## Week of May 4
- Publish waitlist page v1
- Begin weekly beta release notes cadence
- Close plan for M4/280+285 feedback flow implementation choice
- Start M4/370 final server-side gating task

## Week of May 11
- Ship first integrated feedback loop in app
- Complete M3/202 remaining UX/telemetry gaps
- Recruit first 20 waitlist/beta users

## Week of May 18
- Complete M3/201 review workflow gaps
- Run structured beta test cycle across iOS + Android
- Draft store listing copy and screenshot shotlist

## Week of May 25
- Finish security hardening closure and accessibility pass
- Create release candidate branch and freeze risky scope
- Prepare landing page v2 (store-ready)

## Week of June 1
- Submit / stage rollout (platform-specific timing)
- Launch organic campaign with waitlist conversion push
- Monitor first-48h metrics and triage continuously

---

## Mapping to Existing Milestones

### Already aligned
- Feedback systems concept: M4/275, M4/280, M4/285
- Beta and hardening: M4/260, 265, 270, 290, 370
- Launch operations: M5/310, 320, 330, 335, 340, 605, 610, 620, 625
- Organic launch and content: M5/630, 640, 645, 650

### Gaps to explicitly add to planning
1. Waitlist page setup and lifecycle management (now -> launch)
2. Launch decision scorecard (single source of truth for go/no-go)
3. Weekly organic content + tester recruitment runbook

Recommendation: add these as concrete planning issues in M4/M5 so progress is tracked like feature work.

---

## Decisions Needed This Week

1. Waitlist stack
- Option A: Framer + FormSpark + Loops
- Option B: Lightweight static page + form backend already in your stack

2. Feedback stack for launch
- Option A: Firebase App Distribution feedback + store feedback + email routing
- Option B: Add dedicated public board (Canny/UserJot) now

3. Launch scope lock
- Confirm which open M3/M4 items are mandatory for June launch versus post-launch.

---

## Source

- https://www.youtube.com/watch?v=MnF-zJhyUtE