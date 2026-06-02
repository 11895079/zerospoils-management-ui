# ZeroSpoils — Launch Playbook

A step-by-step runbook for a first-time launch. It sequences every asset in
this repo into the order you actually use them. Strategy: **soft launch first,
earn proof, then fire one promotional moment.**

**Cross-cutting rules (true at every step):**
- Lead with the wallet; let the planet be the reason people stay.
- Never invent a number — stats and proof live as tokens in `variables.md` and
  are filled only when real.
- Voice stays warm and plain (see `foundation/03-brand-foundation.md`).

---

## Phase 0 — Prep (before you ship anything)

1. **Fill the tokens.** Open `variables.md` and set `{{ORG_NAME}}`,
   `{{ORG_LEGAL}}`, `{{SUPPORT_EMAIL}}`, `{{WEBSITE}}`, `{{SOCIAL_HANDLE}}`.
   (Leave the proof + store-URL tokens blank for now.)
2. **Claims pass.** Source `{{STAT_HOUSEHOLD_WASTE_USD}}` (USDA ERS / ReFED) or
   don't use a dollar figure publicly. The App Store copy already avoids it.
3. **Finalize the store listing** from `soft-launch/app-store-listing.md`:
   app name, subtitle, keywords, description (mind the char limits).
4. **Produce store visuals.** App icon, 5 screenshots — the gallery captions in
   `promotion/product-hunt-kit.md` tell you what each screenshot should show.
   Complete privacy labels / data-safety form.
5. **Wire the in-app copy** from `in-app/ux-copy.md`: onboarding (3 screens),
   empty state, expiry notifications.
6. **Wire proof capture** from `soft-launch/in-app-proof-capture.md`: native
   review prompt after a "win," and the testimonial ask via the existing
   FeedbackDrawer (tagged `source: soft_launch_win`).

---

## Phase 1 — Soft launch (ship quietly)

7. **Submit** to the App Store and Google Play using the finalized listing.
   Once live, fill `{{APP_STORE_URL}}` / `{{PLAY_STORE_URL}}` in `variables.md`.
8. **Do NOT promote yet.** No Product Hunt, no press, no paid.
9. **Tell your circle.** Send `soft-launch/soft-launch-note.md` to friends,
   family, and early users. Ask for honest feedback — not hype.
10. **Let proof accrue.** Review prompts fire after real wins; testimonials come
    in through the feedback flow. Watch ratings, crash-free rate, and what
    confuses people.
11. **Fix the rough edges** surfaced by early users. This is the whole point of
    soft-launching.

---

## ⛔ Gate — earn proof before promoting

Do **not** start Phase 2 until you have:
- A baseline store rating with a handful of reviews (e.g. 4.x ★),
- A few **consented** testimonials (toggle ON), ideally with dollar figures,
- A stable build you're confident handing to a crowd.

Then fill the proof tokens in `variables.md`: `{{RATING}}`, `{{RATING_COUNT}}`,
`{{USER_COUNT}}`, `{{AVG_SAVED}}`.

---

## Phase 2 — Promotional moment (fire once, coordinated)

Pick a launch day (Tue–Thu tend to work best). Then, in order:

12. **Product Hunt** (`promotion/product-hunt-kit.md`): schedule for 12:01 a.m.
    PT, post the maker's first comment immediately, and reply to every comment
    all day. Ask for feedback, never upvotes.
13. **Email** your soft-launch list (`promotion/launch-email.md`) the same
    morning.
14. **Social** (`promotion/launch-day-social.md`): post the X founder thread, the
    Instagram caption, and the TikTok/Reels hook.
15. **Communities** (`promotion/community-posts.md`): r/Frugal,
    r/EatCheapAndHealthy, r/ZeroWaste — value-first, disclose you're the maker,
    follow each sub's rules. One post each, then engage in comments.
16. **Press** (`promotion/press-one-pager.md`): send to relevant journalists,
    newsletters, and roundups. Personalize the first line.

---

## After launch

- Refine the App Store listing using real search/conversion data.
- Keep collecting consented testimonials — they fuel ongoing copy.
- **Out of scope for v1 (later):** paid-ad creative testing, UK/EU/ANZ
  localization, influencer/PR outreach lists, in-app UX-copy overhaul.

---

## Asset index (what to grab, when)

| Phase | Asset |
|-------|-------|
| Prep | `variables.md`, `foundation/*` (reference) |
| Prep | `soft-launch/app-store-listing.md`, `in-app/ux-copy.md`, `soft-launch/in-app-proof-capture.md` |
| Soft launch | `soft-launch/soft-launch-note.md` |
| Promotion | `promotion/product-hunt-kit.md`, `launch-email.md`, `launch-day-social.md`, `community-posts.md`, `press-one-pager.md` |
| Always-on | `backstory.md` (About page / founder story) |
