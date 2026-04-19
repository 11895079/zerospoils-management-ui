# 635 — Community: Community Platform Launch (Discord Server or r/ZeroSpoils Subreddit)

## Context
A dedicated community space does something social media feeds cannot: it allows users to have ongoing conversations, share wins, ask questions, report bugs, and build identity around ZeroSpoils. Early community members become advocates who recruit others organically. The community platform is also the fastest customer support channel (users help each other) and the richest source of product feedback. The question is which platform to lead with: a managed Discord server (more control, synchronous, better for engaged core users) or a subreddit (lower friction, already where the audience lives, but less control).

## Goal
Launch a primary community space — recommendation is a Discord server initially, with r/ZeroSpoils as a secondary presence — and seed it with enough structure and initial content that new members find value immediately.

## Expected behavior
- Community platform is live before or on launch day
- New members encounter clear welcome messaging, channel structure, and community rules
- At least one team member is active in the community weekly
- The community is linked from the app (Settings → Community or Help section) and from all social media bios

## Acceptance criteria (Definition of Done)
- [ ] Discord server created with channel structure: #welcome, #announcements, #general, #app-feedback, #feature-requests, #wins-and-savings (users share food waste wins), #help
- [ ] Community rules written and pinned (no spam, no PII sharing, constructive feedback only, food waste mission focus)
- [ ] Welcome bot or pinned welcome message greets new members with: what ZeroSpoils is, link to app, how to get help
- [ ] Invite link (permanent, non-expiring) added to: Settings screen community entry (or link from Help), social media bios, store listing
- [ ] r/ZeroSpoils subreddit created as secondary channel with identical community rules and link to Discord as primary
- [ ] Team moderation rotation defined: at minimum, one check per weekday during first month post-launch
- [ ] Seed content: 5 starter posts/discussions ready before first external members join (e.g., "What's your biggest food waste habit you're trying to break?")
- [ ] Community link in app: Settings screen or Help screen includes "Join the Community" tappable entry (requires a minor code change)

## Out of scope
- Custom Discord bot development (use MEE6 free tier or built-in welcome features)
- Paid Discord server boosts
- Community analytics tooling (track via Discord Server Insights free tier)

## Implementation notes
- Discord is recommended over Slack because it's free-tier friendly, has public discoverability via Discord Discover, and is where sustainability communities (r/ZeroWaste Discord servers) already operate
- Reddit strategy: r/ZeroWaste and r/MealPrepSunday are where the existing audience lives — use those for awareness; r/ZeroSpoils is for brand community specifically
- "Join Community" in app: add a `ListTile` to the Settings screen (similar to Help & FAQ entry in issue 365) with an `url_launcher` call to the Discord invite link — this is a small code change
- Flag the community link as Remote Config controlled so the URL can be updated without an app release

## Test plan
**Automated:**
- Widget test: "Join Community" Settings entry exists and its `url_launcher` call fires on tap (mock url_launcher in test)
- Remote Config: community URL key resolves correctly in test environment

**Manual:**
1. Join the Discord server from a fresh account — verify welcome message appears and channel structure is clear
2. Post a question in #app-feedback — verify a team member responds within the defined SLA (24h during launch month)
3. Open Settings → tap "Join Community" on a physical device — verify Discord/Reddit opens correctly
4. Check r/ZeroSpoils subreddit is findable via Reddit search
5. Attempt to post spam to test moderation rules are configured

## Dependencies
- 365 (Settings help entry — community link follows same pattern)
- 630 (social media accounts — bios should link to community)
- 640 (brand voice — community rules and welcome messaging should be on-brand)
