# Soft Launch — In-App Proof Capture

Soft launch's job is to **earn proof** (ratings + testimonials) so the Phase 2
push can lead with real numbers. This captures both — reusing the existing
in-app **FeedbackDrawer**, no new UI to build.

Voice: warm, brief, never naggy (Principles 2 & 3). Ask **after a win**, never
mid-task.

---

## 1. Store review prompt

**When to fire (a genuine "win" moment):**
- The user marks an item **used / eaten before it expired**, OR
- They've **saved 3+ items** from going to waste, OR
- They've used the app on **3 separate days**.

**Frequency:** at most once per ~90 days (respect the OS cap), never on first
launch, never twice in one session. Use the native `requestReview` (StoreKit /
In-App Review) — system-styled, no custom rating UI.

**Lead-in copy** (shown just before, if any pre-prompt is used):
> Nice — that's good food saved, not binned. 🎉
> Enjoying ZeroSpoils? A quick rating helps other people find it.

(Then trigger the native review sheet. Don't editorialize after it.)

---

## 2. Testimonial capture (via FeedbackDrawer)

Reuse the existing feedback flow. Add a lightweight prompt entry point after a
win, routing into `FeedbackDrawer` with a "share a win" framing.

**Entry-point nudge (dismissible):**
> Saved something today? Tell us your ZeroSpoils win — it helps us, and it might
> help someone else start. *(Tap to share)*

**Inside the drawer — prompt text above the message field:**
> What's working for you? (Even one line helps.)
> e.g. "Stopped throwing out produce — saved about $30 this month."

**Consent line (small, near submit):**
> OK to quote this anonymously in our App Store / website? *(toggle, default off)*

> Telemetry: tag these as `source: soft_launch_win` so testimonials are easy to
> pull for the Phase 2 kit. Only quote ones with the consent toggle ON.

---

## 3. What we're collecting (for Phase 2)

| Proof type | Used in Phase 2 for |
|------------|---------------------|
| Star rating + count | Product Hunt, launch social ("4.x★, N users") |
| Dollar-saved quotes | Ads, press one-pager, landing copy |
| Before/after stories | Founder thread, community posts |

> Gate: don't start Phase 2 until there's a baseline of ratings + a handful of
> consented quotes. Proof is the whole point of soft-launching first.
