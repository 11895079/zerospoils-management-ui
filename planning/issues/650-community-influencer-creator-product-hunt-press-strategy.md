# 650 — Community: Influencer/Creator Outreach, Product Hunt Launch, and Press Strategy

## Context
Organic social content builds slowly. A coordinated launch moment — a Product Hunt drop, a handful of sustainability micro-influencer posts, and a targeted press email — can create the initial install spike that seeds algorithmic momentum in both stores. This issue covers the three zero/low-budget amplification levers that have the highest ROI for an early-stage consumer app: Product Hunt (free, high-signal launch platform), micro-influencer gifting (low cost, high trust), and targeted press outreach to food/sustainability journalists.

## Goal
Execute a Product Hunt launch campaign, identify and outreach to 10–20 sustainability/food micro-influencers for organic app reviews, and pitch 5–10 press contacts to generate at least 2 pieces of earned media coverage around ZeroSpoils' launch.

## Expected behavior
- ZeroSpoils is listed on Product Hunt on launch day and reaches top-5 Product of the Day in its category
- At least 5 micro-influencers post authentic reviews within 2 weeks of launch
- At least 2 press mentions or blog posts published within 4 weeks of launch
- All outreach is tracked in a CRM-lite document (Notion or Google Sheets)

## Acceptance criteria (Definition of Done)
- [ ] Product Hunt listing created: headline, tagline, description, media gallery (at least 3 screenshots + app icon), maker profile linked
- [ ] Product Hunt launch scheduled for Tuesday–Thursday (highest traffic days) at 12:01 AM PT
- [ ] Hunter recruited (someone with an existing PH following willing to "hunt" the product) OR self-hunted with maker account
- [ ] Influencer prospect list: 20 sustainability/food/frugality micro-influencers identified (10k–100k followers, ≥3% engagement rate, genuine food waste or zero-waste content)
- [ ] Outreach email template written (personalized, non-spammy, offers free Pro access in exchange for honest review)
- [ ] 10 influencers contacted; at least 5 respond; at least 3 post
- [ ] Press contacts list: 10 journalists/bloggers who cover food tech, sustainability apps, or personal finance (food waste angle)
- [ ] Press release written: 400-word announcement covering problem (food waste stats), solution (ZeroSpoils), traction (beta users, savings metrics), availability
- [ ] 5 press pitches sent with personalized opening paragraph
- [ ] Outreach tracker committed to repo (template only — no names/emails in repo): `docs/launch-outreach-tracker-template.md`
- [ ] Product Hunt results documented post-launch: rank, upvotes, traffic driven

## Out of scope
- Paid influencer partnerships or sponsored posts (organic/gifted only for launch)
- PR agency retainer
- Podcast outreach (Phase 2 — different content format requires audio content preparation)

## Implementation notes
- Product Hunt strategy: notify your personal network to upvote on launch day (email, social post day-of). Upvotes in the first 2 hours determine rank. Do NOT ask people to upvote in bulk (PH detects this and penalizes). Ask authentically: "We launched today — check it out if it resonates"
- Micro-influencer identification sources: Instagram hashtags (#zerowaste, #foodwaste, #mealprep), TikTok search, YouTube "no waste cooking" channels, Reddit moderators of r/ZeroWaste
- Influencer outreach tone: lead with genuine appreciation for their content, not a pitch. Offer value (Pro access) but make it clear it's for an honest review, not a scripted post
- Press angle: the $1,500/year household food waste stat + "Canadian-built app solving it" is a strong local story for Canadian tech/food press
- Target press: CBC Food, Canadian Living, Toronto Life (for Canadian angle), The Kitchn, Food52, Wirecutter (apps section) for broader North American coverage

## Test plan
**Automated:**
- N/A — outreach and launch campaign is a non-code deliverable

**Manual:**
1. Product Hunt: verify listing looks correct in preview mode before going live — check all links, gallery images, and description
2. Launch day: monitor PH rank every hour from midnight PT for the first 6 hours — engage with every comment
3. Influencer check: review each influencer post for brand accuracy — flag any misleading claims and respond kindly with correction
4. Press: set up Google Alerts for "ZeroSpoils" — verify any coverage is tracked and responded to (thank journalist, share on social)
5. 30-day retrospective: calculate referral installs from PH (UTM link) vs influencer vs press — rank by install conversion

## Dependencies
- 320 (store listing copy — Product Hunt description pulls from this)
- 310 (brand assets — gallery images for Product Hunt)
- 630 (social media accounts live to share PH launch post)
- 640 (brand voice — press release and outreach emails must be on-brand)
- App must be publicly available on both stores before PH launch day
