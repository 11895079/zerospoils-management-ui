# 645 — Community: Content Marketing Calendar and Short-Form Video Pipeline

## Context
The business plan identifies Instagram/TikTok "I saved $X this month" content and Reddit community engagement as the primary organic growth channels. Without a structured content calendar and a repeatable production process, organic content output depends entirely on motivation — and motivation isn't a strategy. This issue builds the pipeline: a content calendar template, a library of content formats that work for ZeroSpoils, and a minimum viable publishing cadence that can be maintained by one person part-time.

## Goal
Define a sustainable content calendar with at least 8 weeks of planned content formats, produce the first 4 weeks of actual content, and establish a repeatable video/post production workflow for the launch period and beyond.

## Expected behavior
- Content calendar is populated at least 4 weeks ahead at all times
- Minimum publishing cadence: 3x/week (Instagram + TikTok), 2x/week (Reddit organic participation), 1x/week (X)
- Each content piece is created from a defined format template (no blank-page syndrome)
- Content is produced in batches (e.g., 2 hours on Sunday = 1 week of posts)
- First 4 weeks of content are ready before launch day

## Acceptance criteria (Definition of Done)
- [ ] Content format library documented: 6–8 repeatable formats (see implementation notes)
- [ ] 8-week content calendar template created (spreadsheet or Notion template) with: post date, platform, format, topic, caption draft, visual notes, status
- [ ] First 4 weeks of content fully produced (captions written, visuals created or filmed, ready to schedule)
- [ ] Video production micro-workflow defined: shoot → edit (CapCut or DaVinci Resolve) → caption → schedule → post
- [ ] Content batching calendar defined: content production session scheduled weekly (e.g., 2h Sunday)
- [ ] Scheduling tool configured: Buffer, Later, or Hootsuite free tier with all platform accounts connected
- [ ] First post on each platform published at or before launch day
- [ ] Content calendar and format library committed to repo: `docs/content-calendar-template.md`

## Out of scope
- Paid content promotion or boosted posts
- Hiring a content creator (this is a solo/founder-tier content process)
- YouTube long-form video (Phase 2)
- Influencer-specific content (covered by issue 650)

## Implementation notes
**Content format library (recommended 8 formats):**
1. **Savings snapshot** — "I saved $X and Y items this [week/month]" with app screenshot overlay
2. **Zesto tip** — 15-second Zesto character animation or graphic with a storage/food tip
3. **"Before ZeroSpoils vs. After"** — split screen or transition showing fridge organization
4. **Community question** — "What food do you waste the most?" (drives comments/shares)
5. **Recipe idea from leftovers** — short video: "3 things about to expire → this meal in 20 minutes"
6. **Sustainability stat** — eye-catching stat ("The average household wastes $1,500 of food per year") + call to action
7. **User win** — with permission, reshare a user's savings milestone from the community
8. **Behind the build** — founder/team story content about why ZeroSpoils exists

**Platform notes:**
- TikTok: vertical video, hook in first 2 seconds, captions on screen (auto-generated + edited), trending audio optional
- Instagram: Reels > static posts for reach; Stories for daily engagement; Feed for evergreen content
- Reddit: participate in r/ZeroWaste, r/EatCheapAndHealthy, r/MealPrepSunday authentically (not just self-promotion)

## Test plan
**Automated:**
- N/A — content marketing is a non-code deliverable

**Manual:**
1. Produce 1 full week of content using the format library and calendar template — measure time spent; target <3 hours for 5 posts
2. Schedule posts for the first week using the scheduling tool — verify all posts publish at correct times
3. Week 2: review engagement metrics per format — identify 2 formats with highest engagement and 2 with lowest
4. Month 1 retrospective: which formats drove the most app install clicks? Rank formats by install referral if trackable

## Dependencies
- 630 (social media accounts must exist to schedule posts)
- 640 (brand voice guidelines — all content must be reviewed against them)
- 310 (brand assets — graphics should use consistent brand colors and icon)
- 635 (community platform — "user win" format requires active community)
