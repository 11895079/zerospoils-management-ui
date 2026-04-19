# 630 — Community: Social Media Account Setup and Brand Presence

## Context
ZeroSpoils stands for something — reducing household food waste through awareness, habit formation, and a bit of joy (Zesto). That mission resonates on social platforms where sustainability, zero-waste living, frugality, and meal prep communities already have millions of engaged followers. Before the product launches, the brand needs to exist on the platforms where those communities live — with handles secured, bios consistent with brand voice, and link-in-bio infrastructure ready to direct traffic to the store listings.

## Goal
Create and configure ZeroSpoils social media accounts on all priority platforms, secure consistent handles, and have them ready to post from on launch day.

## Expected behavior
- ZeroSpoils exists on Instagram, TikTok, Reddit, and X (Twitter) with consistent handles (e.g. @zerospoils across platforms)
- Profile photos use the app icon or a brand-safe variant (from issue 310)
- Bio text is consistent, on-brand, and includes a link-in-bio (Linktree or equivalent) pointing to App Store + Play Store
- Each account has at least 1 pinned "about us" post before launch day
- Account credentials and recovery emails are stored securely (not in repo)

## Acceptance criteria (Definition of Done)
- [ ] Handles secured on Instagram, TikTok, X, Reddit (r/ZeroSpoils subreddit created or claimed)
- [ ] Profile photos uploaded: app icon (1024×1024 or platform-specific crop)
- [ ] Bio text written and published on all platforms (follows brand voice from issue 640)
- [ ] Link-in-bio page created (Linktree free or Beacons free) with links to App Store, Play Store, and privacy policy
- [ ] At least 1 pre-launch "we're coming soon" post on each platform (can be same content adapted per platform)
- [ ] Account credentials documented in a team password manager (NOT committed to repo)
- [ ] 2FA enabled on all accounts
- [ ] Platform-specific handle list committed to: `docs/social-media-accounts.md` (handles and links only, no credentials)

## Out of scope
- Posting strategy and content calendar (covered by issue 645)
- Paid promotion or boosting posts
- Brand voice and tone guidelines (covered by issue 640 — that should be done first or in parallel)
- YouTube channel (Phase 2 — video production capacity needed)

## Implementation notes
- Handle priority: @zerospoils on all platforms. If taken, try @zerospoils_app, @zerospoilsapp
- Reddit: create r/ZeroSpoils as a subreddit (requires a Reddit account with 30+ days history to create). If the handle is taken, claim via moderator request. Community rules must be set before first post
- Instagram vs TikTok tone: Instagram leans polished and aspirational; TikTok leans raw, funny, and human. Same brand, different energy
- X (Twitter): lower priority for a consumer food app but worth securing the handle
- Link-in-bio: update the link-in-bio URL to add "now live!" messaging on launch day — update this issue

## Test plan
**Automated:**
- N/A (social media account setup is a non-code ops task)

**Manual:**
1. Attempt to find @zerospoils on each platform from a logged-out browser — verify the profile is discoverable and shows correct bio + link
2. Click the link-in-bio on each platform — verify App Store and Play Store links resolve to correct listings
3. Post a test image from each account — verify brand assets render correctly on platform (icon not cropped oddly, colors accurate)
4. Verify 2FA is active on all accounts before launch week

## Dependencies
- 310 (brand assets — icon and profile photo variants needed)
- 640 (brand voice guidelines — bio text should follow them; can be done in parallel)
