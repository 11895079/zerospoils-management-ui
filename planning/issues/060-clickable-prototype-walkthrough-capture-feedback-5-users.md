## Context
Validate whether the MVP flows are intuitive and low-friction by conducting moderated usability walkthroughs with 5 participants. This early-stage testing focuses on task completion rates, pain points, and overall intuitiveness of core workflows before investing heavily in polish.

## Goal
Run 5 quick walkthroughs (15-20 minutes each) with target users and capture actionable UX insights to inform M1/M2 design refinements.

## Expected behavior
- Participants can complete core tasks with minimal guidance
- Session facilitator follows a consistent script for reproducibility
- Feedback is captured systematically via task observations + post-test survey
- Low-friction deployment options (APK sideload, desktop build, or TestFlight) enable testing on user's own devices

## Acceptance criteria (Definition of Done)
- [ ] Create **task scenarios** (5-7 concrete workflows for users to attempt)
- [ ] Create **post-test survey** (Google Forms/Typeform with 8-10 questions)
- [ ] Create **facilitator script** (`docs/research/facilitator-script.md`) with instructions for conducting sessions
- [ ] Recruit 5 participants (ideally 2-3 who manage household shopping, 2 who rarely check expiration dates)
- [ ] Conduct 5 moderated sessions (record notes per session)
- [ ] Compile findings in `docs/research/round1.md`:
  - Task completion rates (e.g., "4/5 completed Add Item without help")
  - Top 3-5 UX issues with severity ratings (critical/major/minor)
  - Proposed fixes with priority recommendations
  - Verbatim quotes highlighting pain points
- [ ] Update wireframes or file follow-up issues for M2/M3 based on findings
- [ ] Telemetry added for task completion events (e.g., `user_test_task_completed`)
- [ ] Accessibility basics verified (screen reader labels, contrast, tap targets ≥44pt)

## Out of scope
- High-fidelity designs (wireframes are sufficient for this round)
- Automated usability metrics (A/B testing, heatmaps)
- Quantitative analytics (focus on qualitative insights)
- Remote unmoderated testing (moderated sessions only for context-rich feedback)
- Incentives/compensation (recruit from personal network or casual volunteers)

## Implementation notes

### Deployment Options (Choose Based on User's Setup & Timeline)

#### **Option A: HTML Clickable Prototype** (Fastest - No Flutter Build Required)
**Best for:** Quick validation before writing any Flutter code, remote testing, participants without device access.

Convert ASCII wireframes from `planning/docs/wireframes/` to interactive HTML:

**Steps:**
1. Create `prototype/` folder in repo root
2. Convert each wireframe to an HTML page with CSS styling
3. Add navigation links between pages (e.g., clicking FAB → add-item.html)
4. Host on GitHub Pages, Netlify, or Vercel (free, instant deployment)
5. Share URL with participants (works on any device with browser)

**Example structure:**
```
prototype/
  index.html              # Inventory list (default screen)
  add-item.html           # Add item modal/page
  item-detail.html        # Item detail view
  expiring-soon.html      # Expiring items filter
  shopping-list.html      # Shopping list tab
  styles.css              # Shared styles (green theme, card layouts)
  script.js               # Basic interactivity (form validation, nav)
```

**Pros:** 
- Zero build time, instant updates (edit HTML → refresh browser)
- Works on all devices (iOS/Android/Windows/Mac)
- No installation required (just open URL)
- Easy to share remotely (perfect for async feedback)

**Cons:** 
- Not a "real" app (limited to web interactions)
- No native mobile gestures (swipes, long-press)
- Requires manual HTML creation from wireframes

**Implementation time:** 2-4 hours to convert 5 wireframes to HTML

---

#### **Option B: Flutter App Build** (Most Realistic Experience)
**Best for:** Testing native mobile interactions, validating actual Flutter code before launch.

1. **Android APK (Easiest for Android users)**
   - Build debug APK: `flutter build apk --debug`
   - Share via Google Drive/Dropbox link
   - User installs by enabling "Install from Unknown Sources"
   - No Google Play setup required

2. **Windows Desktop (Easiest for laptop-based testing)**
   - Build Windows executable: `flutter build windows --debug`
   - Zip and share the `build/windows/runner/Debug/` folder
   - User extracts and runs `.exe` file
   - No installation required

3. **iOS TestFlight (For iOS users, requires Apple Developer account)**
   - Upload build to TestFlight via Xcode/Transporter
   - Share TestFlight invite link
   - User installs TestFlight app, redeems code
   - More setup but most polished experience

**Pros:** 
- Tests real app behavior (gestures, performance)
- Validates Flutter implementation quality
- Closest to production experience

**Cons:** 
- Requires Flutter app to be implemented first (depends on issue #090)
- Build/share friction (APK downloads, Windows Defender warnings)
- Harder to update between test sessions

**Implementation time:** 8-16 hours (requires functional Flutter app)

---

**Recommendation for M1:** Start with **Option A (HTML Prototype)** to validate UX flows quickly, then transition to **Option B (Flutter APK)** in M2 for implementation validation.

### Task Scenarios (Use These Verbatim)
Provide these scenarios to participants one at a time. Do not explain how to complete them—observe whether the UI is self-explanatory.

1. **Add a new food item to inventory**
   - "You just bought a carton of milk with an expiration date of [3 days from today]. Add it to your inventory."
   - Success criteria: Item appears in inventory with correct expiration date

2. **Find items expiring soon**
   - "Check what food is about to expire in the next 3 days."
   - Success criteria: User navigates to expiring items view and identifies milk

3. **Move an item to shopping list**
   - "You ran out of eggs. Add eggs to your shopping list."
   - Success criteria: Eggs appear in shopping list

4. **Mark an item as used/consumed**
   - "You used up the milk. Mark it as consumed."
   - Success criteria: Milk removed from inventory or marked as consumed

5. **Browse items by location**
   - "Show me everything stored in the refrigerator."
   - Success criteria: User filters or navigates to fridge items

6. **Edit an item's expiration date**
   - "You realized the bread expires tomorrow, not in 3 days. Update the date."
   - Success criteria: User edits bread's expiration date successfully

7. **Add an item without a barcode** (exploratory)
   - "Add an item that doesn't have a barcode (e.g., homemade leftovers)."
   - Success criteria: User manually enters item details

### Post-Test Survey Template
Create this as a Google Form or Typeform. Include link in facilitator script.

**Likert Scale Questions (1 = Strongly Disagree, 5 = Strongly Agree):**
1. The app was easy to navigate
2. I could complete tasks without help
3. I would use this app regularly to track my food
4. The language/labels were clear and understandable
5. I found the app visually appealing

**Open-Ended Questions:**
6. What was the most confusing or frustrating part of the experience?
7. What feature did you like the most?
8. If you could change one thing, what would it be?
9. Would you recommend this app to a friend who wants to reduce food waste? Why or why not?
10. Any other feedback or suggestions?

**Demographics (Optional):**
- Age range (18-25, 26-35, 36-45, 46+)
- How often do you currently check expiration dates? (Daily, Weekly, Rarely, Never)
- Device used for test (Android phone, iPhone, Windows PC, Mac)

### Facilitator Script Structure
Create `docs/research/facilitator-script.md` with:

```markdown
# Usability Test Facilitator Script

## Pre-Session (5 min)
- Thank participant for their time
- Explain purpose: "We're testing an early version of a food waste reduction app. Your honest feedback helps us improve it."
- Emphasize: "We're testing the app, not you. There are no wrong answers."
- Request permission to take notes (not recording video/audio)
- Have participant open the app on their device

## During Session (10-15 min)
- Read task scenarios verbatim (see Implementation Notes)
- Do not provide hints unless participant is stuck for >60 seconds
- Observe and note:
  - Hesitations, confused expressions, incorrect paths
  - Verbalize: "What are you looking for right now?" / "What do you expect to happen?"
- If stuck >60 sec, provide minimal hint: "Try looking at the [navigation bar/screen name]"

## Post-Session (5 min)
- Share survey link (Google Form)
- Ask participant to complete while experience is fresh
- Optional: "Is there anything else you want to mention that we didn't cover?"
- Thank participant and explain next steps (findings will inform app improvements)

## Notes Template (Copy per session)
- **Participant ID:** P1, P2, P3, P4, P5
- **Device:** [Android/iOS/Windows]
- **Date/Time:**
- **Task Completion:**
  - Task 1: ✅ Completed independently / ⚠️ Completed with help / ❌ Could not complete
  - Task 2: ...
- **Observations:**
  - [Timestamp] [Behavior/Quote]
- **Survey responses:** [Link to their submission or key takeaways]
```

### Findings Report Structure
`docs/research/round1.md` should include:

1. **Executive Summary** (3-5 bullets of top insights)
2. **Methodology** (5 participants, moderated sessions, 15-20 min each, tasks X-Y)
3. **Participant Demographics** (if collected)
4. **Task Completion Rates** (table showing X/5 completed independently, Y/5 needed help, Z/5 failed)
5. **Top UX Issues**:
   - Issue 1: [Description] — Severity: Critical/Major/Minor — Observed in X/5 sessions — Proposed fix: [Solution]
   - Issue 2: ...
6. **Verbatim Quotes** (highlight particularly insightful feedback)
7. **Recommendations** (prioritized list of changes for M2/M3)
8. **Appendix** (raw notes per participant)

### Telemetry for User Testing
Instrument these events to distinguish test sessions from production usage later:

```dart
// At start of test session (facilitator triggers or participant enters test mode)
telemetry.log('user_test_session_started', {
  'participant_id': 'P1', // Anonymized
  'device_type': 'android',
  'app_version': '0.1.0-m1'
});

// On task completion
telemetry.log('user_test_task_completed', {
  'task_id': 'add_item',
  'completion_status': 'success' | 'helped' | 'failed',
  'duration_seconds': 45
});
```

## Test plan
**Automated:**
- Widget test: Verify test mode toggle exists and can be enabled (to trigger telemetry for user tests)
- Unit test: Validate telemetry events are logged with correct properties
- Integration test: Verify all task scenarios are functional (add item, filter by expiration, add to shopping list, etc.)

**Manual:**
1. **Facilitator dry run**: Conduct 1 practice session internally to refine script and timing
2. **APK/Desktop build validation**: Share build with 1 internal tester to verify install process is smooth
3. **Survey link validation**: Test Google Form submission and response collection
4. **Pilot session**: Run 1 session with a friendly participant to identify logistical issues
5. **Data synthesis**: After all sessions, compile notes into `round1.md` and identify top 3-5 actionable insights
6. **Wireframe updates**: Revise wireframes based on findings or create follow-up issues for M2

## Dependencies
- **Issue #050** (UX wireframes) — wireframes define screens to implement in prototype
- **Issue #090** (Flutter app skeleton) — only required if using Flutter build option (Option B)
- Google Form or Typeform account for survey creation
- 5 willing participants (recruit from personal network, local community groups, or social media)

## Appendix: Converting ASCII Wireframes to HTML

### Quick HTML Template (Use for Each Screen)
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ZeroSpoils - Inventory</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="mobile-frame">
    <!-- Header -->
    <header class="app-header">
      <h1>Inventory</h1>
      <button class="filter-btn">Filter</button>
    </header>

    <!-- Search Bar -->
    <div class="search-bar">
      <input type="text" placeholder="🔍 Search items..." />
    </div>

    <!-- Category Chips -->
    <div class="category-chips">
      <button class="chip active">All</button>
      <button class="chip">Dairy</button>
      <button class="chip">Fruit</button>
      <button class="chip">Veg</button>
    </div>

    <!-- Item Cards -->
    <div class="item-list">
      <a href="item-detail.html" class="item-card">
        <div class="item-icon">🥛</div>
        <div class="item-info">
          <h3>Milk</h3>
          <p class="location">Fridge</p>
          <p class="expiry">Expires in 3 days</p>
        </div>
      </a>

      <a href="item-detail.html" class="item-card warning">
        <div class="item-icon">🍎</div>
        <div class="item-info">
          <h3>Apples</h3>
          <p class="location">Counter</p>
          <p class="expiry">Expires today ⚠️</p>
        </div>
      </a>

      <a href="item-detail.html" class="item-card expired">
        <div class="item-icon">🍞</div>
        <div class="item-info">
          <h3>Bread</h3>
          <p class="location">Pantry</p>
          <p class="expiry">Expired 2 days ago 🔴</p>
        </div>
      </a>
    </div>

    <!-- FAB -->
    <a href="add-item.html" class="fab">+</a>

    <!-- Bottom Nav (Optional) -->
    <nav class="bottom-nav">
      <a href="index.html" class="active">Inventory</a>
      <a href="expiring-soon.html">Expiring</a>
      <a href="shopping-list.html">Shopping</a>
    </nav>
  </div>
</body>
</html>
```

### Shared CSS (`styles.css`)
```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f5f5f5;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
}

/* Mobile Frame */
.mobile-frame {
  width: 100%;
  max-width: 390px;
  height: 844px;
  background: white;
  border-radius: 40px;
  overflow: hidden;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
  display: flex;
  flex-direction: column;
  position: relative;
}

/* Header */
.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: #2f9e44;
  color: white;
}

.app-header h1 {
  font-size: 20px;
  font-weight: 600;
}

.filter-btn {
  background: none;
  border: 1px solid white;
  color: white;
  padding: 6px 12px;
  border-radius: 16px;
  font-size: 14px;
}

/* Search Bar */
.search-bar {
  padding: 12px 20px;
  border-bottom: 1px solid #e0e0e0;
}

.search-bar input {
  width: 100%;
  padding: 10px 16px;
  border: 1px solid #ccc;
  border-radius: 20px;
  font-size: 15px;
}

/* Category Chips */
.category-chips {
  display: flex;
  gap: 8px;
  padding: 12px 20px;
  overflow-x: auto;
  border-bottom: 1px solid #e0e0e0;
}

.chip {
  padding: 8px 16px;
  border: 1px solid #2f9e44;
  background: white;
  color: #2f9e44;
  border-radius: 16px;
  font-size: 14px;
  white-space: nowrap;
  cursor: pointer;
}

.chip.active {
  background: #2f9e44;
  color: white;
}

/* Item List */
.item-list {
  flex: 1;
  overflow-y: auto;
  padding: 16px 20px;
}

.item-card {
  display: flex;
  gap: 12px;
  padding: 16px;
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  margin-bottom: 12px;
  text-decoration: none;
  color: inherit;
  transition: transform 0.2s;
}

.item-card:active {
  transform: scale(0.98);
}

.item-card.warning {
  border-left: 4px solid #ff9800;
}

.item-card.expired {
  border-left: 4px solid #f44336;
  opacity: 0.7;
}

.item-icon {
  font-size: 32px;
}

.item-info h3 {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.location {
  font-size: 13px;
  color: #666;
  margin-bottom: 4px;
}

.expiry {
  font-size: 13px;
  color: #999;
}

/* FAB */
.fab {
  position: absolute;
  bottom: 80px;
  right: 20px;
  width: 56px;
  height: 56px;
  background: #2f9e44;
  color: white;
  border-radius: 50%;
  font-size: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  box-shadow: 0 4px 12px rgba(47, 158, 68, 0.4);
}

/* Bottom Nav */
.bottom-nav {
  display: flex;
  justify-content: space-around;
  padding: 12px 0;
  border-top: 1px solid #e0e0e0;
  background: white;
}

.bottom-nav a {
  flex: 1;
  text-align: center;
  padding: 8px;
  color: #666;
  text-decoration: none;
  font-size: 13px;
}

.bottom-nav a.active {
  color: #2f9e44;
  font-weight: 600;
}
```

### Hosting Options
1. **GitHub Pages (Free):**
   ```bash
   # In repo root, create prototype/ folder
   # Add HTML files
   # Enable GitHub Pages in repo settings → Pages → Source: main branch → /prototype folder
   # URL: https://yourusername.github.io/zerospoils/
   ```

2. **Netlify Drop (Instant, no account required):**
   - Visit netlify.com/drop
   - Drag `prototype/` folder
   - Get instant shareable URL

3. **Vercel (Free, requires GitHub):**
   - Connect repo to Vercel
   - Deploy `prototype/` folder
   - Auto-updates on push

### Conversion Workflow (Per Screen)
1. Open wireframe markdown (e.g., `planning/docs/wireframes/inventory-list.md`)
2. Copy ASCII layout section
3. Map ASCII elements to HTML/CSS:
   - `┌─────┐` boxes → `<div class="card">`
   - `[Button]` → `<button>`
   - Emoji icons → keep as-is (🥛 → 🥛)
   - Navigation arrows → `<a href="next-screen.html">`
4. Add click targets for user tasks:
   - FAB button → links to `add-item.html`
   - Item cards → links to `item-detail.html`
   - Tab bar → links to respective screen
5. Test on phone browser (responsive view)

**Time estimate:** 30-45 min per screen × 5 screens = 2.5-4 hours total
