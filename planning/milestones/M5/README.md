# Milestone M5 — Public Launch

**Objective:** Prepare for and execute public app store launch with polished brand assets and compliance documentation.

**Scope:**

*Launch Infrastructure:*
- Brand assets pack: icon, screenshots, feature graphic (310)
- Store listing copy for iOS App Store and Google Play (320)
- Privacy policy and terms of service (hosted and in-app links) (330)
- Settings legal links wiring (335)
- End-to-end release checklist (340)
- Support workflow: triage labels, ownership (350)
- In-app FAQ/help center stub (360)
- Settings help & FAQ entry (365)
- Rate app entry (375)
- Settings account entry (345)
- App store review monitoring and response playbook (370)
- Performance/scalability/cost baseline (380)
- Ops observability (crashes, key events, alerts) (390)
- Incident response runbook (400)
- Legal compliance review (cross-jurisdiction) (405)
- App Store Optimization (ASO): keyword, metadata, category strategy (600)
- App Store Connect submission workflow — Apple review prep (605)
- Google Play staged rollout management (610)
- Public TestFlight external beta (615)
- Launch-day operations plan and war room playbook (620)
- First-48h metrics dashboard and post-launch health monitoring (625)

*User Engagement & Retention:*
- Smart Replenishment: predict re-buy items from consumption history (155)
- Weekly Streak Persistence & Progress Summary (160)
- Zesto Phase 3: Tap-to-cycle contextual tips (370-zesto)
- Zesto Phase 3: Unlockable mascot characters (375-zesto)
- Zesto Phase 3: Settings controls for frequency/message types (380-zesto)
- In-app review prompt strategy and implementation (655)
- Onboarding funnel analytics and first-7-days improvement loop (660)

*Community & Social Media:*
- Social media account setup and brand presence (630)
- Community platform launch: Discord server + r/ZeroSpoils subreddit (635)
- Brand voice, tone, and content guidelines (640)
- Content marketing calendar and short-form video pipeline (645)
- Influencer/creator outreach, Product Hunt launch, press strategy (650)

*Ad Monetization (free tier):*
- Free tier ad strategy and AdMob spike — go/no-go decision (665)
- Ad placement UX guidelines and brand-safe ad policy (670)
- AdMob SDK integration: rewarded video + GDPR/ATT consent (675)

**Acceptance:** App published to App Store and Google Play; privacy policy live; support workflow documented; monitoring and alerting configured; engagement features driving DAU/retention; ready for public users.

**Out of Scope:** Pro tier features (household sync, receipt OCR, LLM-powered recipe suggestions), IoT integrations (deferred to M6/M7). Paid advertising campaigns. AdMob integration is gated on the spike (665) go/no-go decision.

**Issues:** 155, 160, 310, 320, 330, 335, 340, 345, 350, 360, 365, 370, 370-zesto, 375, 375-zesto, 380, 380-zesto, 390, 400, 405, 600, 605, 610, 615, 620, 625, 630, 635, 640, 645, 650, 655, 660, 665, 670, 675

**Deferred to M6 Pro Tier:** 185 (Recipe suggestions — requires LLM infrastructure, tiered payment plan TBD)

**Dependencies:** M4 complete (beta testing done, feedback incorporated, crash-free).

---

## M5 Implementation Status

**Last Updated:** April 18, 2026 — **Progress:** 0/36 planned issues complete (0%)**

**Note:** Recipe suggestions (185) deferred to M6 Pro tier (requires LLM infrastructure). M5 focuses on launch infrastructure + free-tier engagement features.

### Issues & Completion

| Issue | Title | Status | PR | Notes |
|-------|-------|--------|----|-------|
| **155** | Smart Replenishment: predict re-buy from consumption history | ⏳ Not Started | — | Free-tier engagement driver; learns buying patterns to suggest shopping list items |
| **160** | Weekly Streak Persistence & Progress Summary | ⏳ Not Started | — | Habit formation (streak counter + weekly comparison); drives DAU/retention |
| **310** | Brand assets pack (icon, screenshots, feature graphic) | ⏳ Not Started | — | No milestone-complete launch asset bundle documented yet |
| **320** | Store listing copy (iOS + Android) | ⏳ Not Started | — | No store copy package tracked as complete |
| **330** | Privacy policy + terms (hosted + in-app links) | ⏳ Not Started | — | Settings currently shows placeholder actions for legal links |
| **335** | Settings legal links wiring | ⚠️ In Progress | — | Privacy/Terms rows exist in `app/lib/presentation/screens/settings_screen.dart` but still show "coming soon" |
| **340** | End-to-end release checklist | ⚠️ In Progress | — | Release guidance exists in `docs/release.md`, but milestone checklist closure not yet tracked |
| **345** | Settings account entry | ⚠️ In Progress | — | Account row exists but opens placeholder snackbar (`Account coming soon`) |
| **350-zesto** | Zesto Phase 3: Tap-to-cycle contextual tips | ⏳ Not Started | — | Interactive mascot tips on each screen (gamification) |
| **375** | Rate app entry | ⚠️ In Progress | — | Rate App row exists in Settings but still placeholder behavior |
| **375-zesto** | Zesto Phase 3: Unlockable mascot characters | ⏳ Not Started | — | Achievement-based character collection (Carrot, Broccoli, Bread mascots) |
| **380** | Performance/scalability/cost baseline | ⏳ Not Started | — | No milestone-level baseline report marked complete |
| **380-zesto** | Zesto Phase 3: Settings controls for frequency/types | ⏳ Not Started | — | User preferences for Zesto appearance frequency and message typestifact yet |
| **365** | Settings help & FAQ entry | ⚠️ In Progress | — | Help & FAQ row exists in Settings but still placeholder behavior |
| **370** | App store review monitoring + response playbook | ⏳ Not Started | — | No review-monitoring playbook tracked as complete |
| **375** | Rate app entry | ⚠️ In Progress | — | Rate App row exists in Settings but still placeholder behavior |
| **380** | Performance/scalability/cost baseline | ⏳ Not Started | — | No milestone-level baseline report marked complete |
| **390** | Ops observability baseline | ⚠️ In Progress | — | Crashlytics and launch-hardening work exists (M4/370), but M5 ops observability deliverables are not fully closed |
| **400** | Incident response runbook | ⏳ Not Started | — | Incident response runbook completion not yet tracked |
| **405** | Legal compliance review (cross-jurisdiction) | ⏳ Not Started | — | Compliance review artifact not yet marked complete |
| **600** | ASO: keyword, metadata, category strategy | ⏳ Not Started | — | Separate from listing copy (320); drives organic search discoverability |
| **605** | App Store Connect submission workflow | ⏳ Not Started | — | Screenshots, privacy labels, export compliance, age rating, review notes |
| **610** | Google Play staged rollout management | ⏳ Not Started | — | 20%→50%→100% with documented promotion criteria and rollback threshold |
| **615** | Public TestFlight external beta | ⏳ Not Started | — | 50–200 real-world testers, go/no-go decision criteria before 1.0 submission |
| **620** | Launch-day operations plan and war room playbook | ⏳ Not Started | — | T-48h to T+24h sequence, role assignments, halt criteria, social post scheduling |
| **625** | First-48h metrics dashboard and post-launch health monitoring | ⏳ Not Started | — | Firebase + Play Console + App Store Connect; crash alert thresholds pre-configured |
| **630** | Social media account setup and brand presence | ⏳ Not Started | — | Instagram, TikTok, Reddit, X — handles secured, bios live, link-in-bio configured |
| **635** | Community platform launch (Discord + r/ZeroSpoils) | ⏳ Not Started | — | Discord server with channel structure; minor app code change to add "Join Community" Settings entry |
| **640** | Brand voice, tone, and content guidelines | ⏳ Not Started | — | Written doc: voice attributes, Zesto personality, vocabulary do/don't, tone by context |
| **645** | Content marketing calendar and short-form video pipeline | ⏳ Not Started | — | 8-week calendar, 6–8 content format templates, first 4 weeks produced before launch |
| **650** | Influencer/creator outreach, Product Hunt, press strategy | ⏳ Not Started | — | PH launch Tuesday–Thursday; 10 influencer contacts; 5 press pitches; outreach tracker |
| **655** | In-app review prompt strategy and implementation | ⏳ Not Started | — | Native StoreKit/Play Review API; trigger: 3 sessions + 5 items + 90-day cooldown; Remote Config tunable |
| **660** | Onboarding funnel analytics and first-7-days optimization | ⏳ Not Started | — | Full funnel instrumentation; D1 ≥40%, D7 ≥20% targets; month-1 improvement loop |
| **665** | Free tier ad strategy and AdMob spike | ⏳ Not Started | — | Research + revenue projection + go/no-go recommendation before any SDK work |
| **670** | Ad placement UX guidelines and brand-safe ad policy | ⏳ Not Started | — | Allowlist/denylist; rewarded video only at launch; gated on 665 "go" decision |
| **675** | AdMob SDK integration: rewarded video + GDPR/ATT | ⏳ Not Started | — | Rewarded video tied to Zesto mascot unlock; UMP consent; ATT post-onboarding; gated on 665+670 |

### Commentary

- **M5 scope expanded (April 2026):** Added launch mechanics (ASO, App Store Connect submission, Play staged rollout, external beta), community/social media track (accounts, Discord, brand voice, content calendar, influencer/PH/press), growth loops (review prompts, onboarding funnel analytics), and ad monetization track (strategy spike → UX policy → SDK integration).
- **Zesto gamification is free tier:** Phases 1–3 (including unlockable mascot characters) are in M5, not Pro. The rewarded video ad mechanic (675) ties into Zesto mascot unlocks as an optional engagement/revenue driver.
- **Ad monetization is gated:** Issues 670 and 675 only proceed if the spike (665) recommends a "go" decision. The UX policy (670) must be approved before any SDK code is written.
- **Recipe suggestions (185) deferred to M6 Pro tier:** LLM-powered personalization justifies premium tier.
- Most original M5 work remains launch-operations heavy; no original issue is fully closed against all acceptance criteria yet.
