# 640 — Community: Brand Voice, Tone, and Content Guidelines

## Context
ZeroSpoils has a distinct personality: practical, warm, non-judgmental, a little playful (Zesto lives here). Without written guidelines, every social post, community reply, and in-app message will drift in tone depending on who wrote it, leading to an inconsistent brand impression. This document is the single source of truth for how ZeroSpoils speaks — and equally important, how it does NOT speak (no eco-guilt, no shaming, no preachiness).

## Goal
Produce a brand voice and content guidelines document that any team member or contractor can use to write on-brand content for social media, community management, press, app copy, and marketing materials.

## Expected behavior
- Any team member reading the document can write a social post that passes a "sounds like ZeroSpoils" bar
- The document defines: brand voice attributes, tone variations by context (excited launch post vs. empathetic support reply vs. playful Zesto tip), vocabulary to use and avoid, Zesto mascot personality notes, and visual tone guidance
- Existing in-app copy is audited against the guidelines and any off-tone text flagged for update

## Acceptance criteria (Definition of Done)
- [ ] Brand voice defined with 4–5 attributes and short descriptions (e.g., "Encouraging, not preachy — we celebrate small wins, not lecture about climate change")
- [ ] Tone variations documented: launch announcement, educational tip, user win celebration, support/empathy reply, bug acknowledgement
- [ ] Words and phrases to use and avoid documented (avoid: "save the planet", "you should", "guilt"; use: "small wins", "every item counts", "let's make it easy")
- [ ] Zesto personality defined: age, personality traits, how he speaks, what he'd never say
- [ ] 3 before/after examples for each tone context (bad draft → on-brand rewrite)
- [ ] Visual tone note: photography style (real food, home settings, natural light — no sterile stock photos), brand colors in social graphics
- [ ] Document committed to repo: `docs/brand-voice-guidelines.md`
- [ ] Audit of existing in-app strings for off-tone copy completed — issues filed for any that need updating

## Out of scope
- Full visual brand identity system (covered by issue 310 brand assets pack)
- Logo guidelines (part of 310)
- Press kit (separate deliverable if needed)

## Implementation notes
- Zesto's voice: curious, enthusiastic, slightly silly. He talks like a friendly produce department worker who also reads Wikipedia. He does NOT lecture. He does NOT use corporate language ("synergize", "leverage")
- The "no guilt" principle is core to ZeroSpoils differentiation. The business plan explicitly mentions it. Every piece of content should feel like encouragement, not obligation
- Practical writing test: before publishing any content, ask "Would someone feel bad about themselves after reading this?" If yes, rewrite
- This document doubles as an onboarding resource for future community managers, marketers, and contractors

## Test plan
**Automated:**
- N/A — brand voice is a content artifact, not a code artifact

**Manual:**
1. Ask two team members to each write a mock Instagram caption for "I saved $40 this week" using only the guidelines doc — evaluate whether both feel on-brand
2. Ask someone unfamiliar with ZeroSpoils to read the guidelines and then write a Zesto tip — verify it passes the tone bar without coaching
3. Audit 10 existing in-app strings (button labels, empty states, onboarding text) against the guidelines — note any that need updating

## Dependencies
- 310 (brand assets — visual tone note should align with the icon/screenshot aesthetic choices)
- 630 (social media accounts — bio copy should be written or reviewed against these guidelines)
