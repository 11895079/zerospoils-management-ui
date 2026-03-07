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

*User Engagement & Retention:*
- Smart Replenishment: predict re-buy items from consumption history (155)
- Weekly Streak Persistence & Progress Summary (160)
- Zesto Phase 3: Tap-to-cycle contextual tips (370-zesto)
- Zesto Phase 3: Unlockable mascot characters (375-zesto)
- Zesto Phase 3: Settings controls for frequency/message types (380-zesto)

**Acceptance:** App published to App Store and Google Play; privacy policy live; support workflow documented; monitoring and alerting configured; engagement features driving DAU/retention; ready for public users.

**Out of Scope:** Pro tier features (household sync, receipt OCR, LLM-powered recipe suggestions), IoT integrations (deferred to M6/M7).

**Issues:** 155, 160, 310, 320, 330, 335, 340, 345, 350, 360, 365, 370, 370-zesto, 375, 375-zesto, 380, 380-zesto, 390, 400, 405

**Deferred to M6 Pro Tier:** 185 (Recipe suggestions — requires LLM infrastructure, tiered payment plan TBD)

**Dependencies:** M4 complete (beta testing done, feedback incorporated, crash-free).

---

## M5 Implementation Status

**Last Updated:** March 7, 2026 — **Progress:** 0/20 planned issues complete (0%)**

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
**M5 scope expanded:** Now includes user engagement/retention features (Smart Replenishment, Weekly Streaks, Zesto gamification) to drive DAU after public launch
- **Recipe suggestions (185) deferred to M6 Pro tier:** No half-measures; LLM-powered personalization justifies premium tier
- M5 currently has preparatory signals in Settings and release docs, but no issue is fully closed against all acceptance criteria
- Most M5 work remains launch-operations and governance heavy, with new engagement features to be implemented after core launch infrastructure
- **Key engagement strategy:** Free-tier features (Smart Replenishment, Streaks) drive habit formation; Pro tier (M6) offers premium LLM/ML features

- M5 currently has preparatory signals in Settings and release docs, but no issue is fully closed against all acceptance criteria.
- Most M5 work remains launch-operations and governance heavy, and should be tracked with explicit docs + PR links as implementation proceeds.
