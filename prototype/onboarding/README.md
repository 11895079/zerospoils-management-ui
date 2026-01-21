# ZeroSpoils Onboarding Flow

Interactive onboarding experience that educates users on the app's purpose, teaches core workflows, and **clarifies the shopping list → inventory conversion process**.

## Quick Start

### First-time user experience:
1. Open `onboarding/welcome.html` to begin
2. Progress through 8 screens (~3-4 minutes total)
3. Reaches app's main screen with guidance

### Direct app access (skip onboarding):
- Open `../index.html` directly from main prototype folder
- Users can return to onboarding anytime via the ℹ️ button in the header

## Onboarding Screens

### 1. **Welcome** (`welcome.html`)
- App intro with tagline: "Reduce Food Waste. Save Money. Organize Your Kitchen."
- Single CTA: "Let's Get Started"
- Option to skip directly to app

### 2. **The Problem** (`problem.html`) 
- ~30% of groceries wasted statistic
- Relatable scenarios: forgotten fridge items, duplicate purchases
- Establishes WHY the app exists

### 3. **The Solution** (`solution.html`)
- Three core benefits: Track all food, plan shopping smarter, reduce waste proactively
- Emphasizes result: save money, reduce waste, better organized kitchen

### 4. **Meet Zesto** (`mascot.html`) 🆕
- Introduces Zesto the Avocado mascot
- Explains his role: celebrates wins, offers tips, tracks progress
- Fun fact: Why an avocado (most wasted food)
- Animated mascot with speech bubble

### 5. **Inventory Basics** (`inventory.html`)
- Step 1: Add items with expiry date (tap +)
- Step 2: Check "Expiring Soon" tab to prioritize consumption
- Visual emoji flow: 📦 → 🥛 → ⏰

### 6. **Shopping List Workflow** (`shopping.html`) ⭐ **KEY SCREEN**
**This screen directly addresses user confusion about shopping list → inventory conversion.**

Two-phase walkthrough:
- **Before you shop:** Check inventory first, add what you need to shopping list
- **After you shop:** Mark items as purchased, add to inventory with expiry date, items move to Inventory tab

Explicitly shows the conversion path with visual steps and result.

### 6. **Reduce Waste** (`waste.html`)
- Mark items as consumed when used
- Mark items as wasted (with reason + percentage)
- Shows progress tracking (% waste improvement over time)

### 7. **Permissions** (`permissions.html`)
- Camera access request (for expiry date OCR)
- Privacy assurance: only scans expiry dates, no server data
- Can skip and enable later

### 8. **Get Started** (`get-started.html`)
- Celebration screen with encouragement
- CTA: "Add First Item" (opens add-item flow)
- Pro tip: Take fridge photo and add items as you see them (~2 min)

## Technical Details

### File Structure
```
prototype/onboarding/
├── welcome.html           # Splash screen
├── problem.html           # Problem statement
├── solution.html          # Solution benefits
├── inventory.html         # Inventory workflow
├── shopping.html          # Shopping → Inventory conversion (KEY)
├── waste.html            # Waste reduction workflow
├── permissions.html      # Camera permissions
├── get-started.html      # Final CTA + first-action guidance
├── onboarding.css        # Shared styles for all screens
└── README.md             # This file
```

### Navigation
- **Next button**: Advance to next screen
- **Back button**: Return to previous screen
- **Skip button** (top-right): Jump to main app anytime
- All screens maintain consistent styling and progress indicator (X/6)

### Styling Features
- Mobile-first responsive design (390×844px iPhone frame)
- Green primary color (#2f9e44) for CTAs
- Progress indicators (1/6, 2/6, etc.)
- Emoji-based visual storytelling
- Encouraging, non-judgmental tone
- Accessibility: high contrast, clear labels, screen reader compatible

## Analytics Events (For Production)

The prototype includes placeholders for these analytics events:
```
onboarding_started
onboarding_screen_viewed (screen_id: 'welcome' | 'problem' | ...)
onboarding_skipped (from_screen_id, action)
onboarding_completed (duration_seconds, permissions_granted)
```

## User Testing Integration (Issue #060)

The onboarding flow is designed for moderated user testing:

1. **Pre-test:** Participant watches onboarding (4 min)
2. **Comprehension check:** Ask "What happens when you buy something and check it off the shopping list?" 
3. **Task scenarios:** Participant completes 7 core tasks
4. **Post-test survey:** Includes questions on shopping list clarity, whether onboarding helped, UX friction points

The **shopping list screen (Screen 5)** directly addresses user feedback on confusion about the shopping → inventory conversion workflow.

## Accessibility Checklist

- ✓ High contrast (white bg, dark text, green CTA)
- ✓ Touch targets ≥44pt
- ✓ Clear labels on all buttons
- ✓ Screen reader friendly (semantic HTML)
- ✓ No paywalls or content locked behind permissions
- ✓ Can skip and return anytime
- ✓ No auto-playing audio/video

## Key Design Principles

1. **Answer WHY first** (Screens 2-3) before teaching HOW (Screens 4-6)
   - Users need context before learning mechanics
   
2. **Shopping list clarity is explicit** (Screen 5)
   - Step-by-step breakdown of checkout → conversion process
   - Visual arrows and flow language ("→ moves to")
   
3. **Progressive disclosure** - One concept per screen
   - Don't overload with all features at once
   
4. **Respectful of time** - ~3-4 min total, can skip anytime
   - Mobile users have limited patience
   
5. **Encouragement throughout** - "You're getting better! 🎯"
   - Validates user effort and progress

## Testing Notes

### Manual Testing
1. Open `welcome.html`
2. Click through all 8 screens sequentially
3. Test back navigation
4. Test skip button at each screen
5. Verify links to main app work (e.g., "Add First Item" → add-item.html)
6. Test on mobile device (iOS Safari, Android Chrome) for touch targets

### User Testing (Issue #060)
- Show onboarding BEFORE asking participants to complete tasks
- Ask post-onboarding comprehension check on shopping flow
- Include survey question: "Was the shopping list → inventory process clear?"
- Measure: % participants who understood conversion without help

## Deployment

### GitHub Pages
1. Push `prototype/` folder to repo
2. Enable GitHub Pages in repo settings (main branch → /prototype)
3. URL: `https://username.github.io/zerospoils/onboarding/welcome.html`

### Netlify Drop (Instant)
1. Visit netlify.com/drop
2. Drag `prototype/` folder
3. Get instant shareable URL

### Local Testing
- Double-click `welcome.html` in file explorer
- Or: `cd prototype && python -m http.server 8000` then visit `http://localhost:8000/onboarding/welcome.html`

## Related Documentation

- **Issue #060** (User Testing): `planning/milestones/M1/060-clickable-prototype-walkthrough-capture-feedback-5-users.md`
- **Onboarding Wireframes**: `planning/docs/wireframes/onboarding-flow.md`
- **App Flows**: `planning/docs/app-flows.md`
- **UX Patterns**: `planning/docs/ux.md`

---

**Questions?** See the main [prototype README](../README.md) or issue #060 for user testing guidance.
