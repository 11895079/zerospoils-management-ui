# ZeroSpoils HTML Prototype

Interactive clickable prototype for user testing, converted from ASCII wireframes.

## Quick Start

### Option 1: Open Locally
1. Open `index.html` in any web browser
2. Navigate between screens using the bottom nav or interactive elements

### Option 2: Deploy to GitHub Pages
1. Push this folder to your repo
2. Go to repo **Settings** → **Pages**
3. Set source to `main` branch → `/prototype` folder
4. Access at: `https://yourusername.github.io/zerospoils/`

### Option 3: Netlify Drop (Instant)
1. Visit [netlify.com/drop](https://app.netlify.com/drop)
2. Drag the `prototype/` folder
3. Get instant shareable URL (no account needed)

## Screens Included

| Screen | File | Description |
|--------|------|-------------|
| **Inventory List** | `index.html` | Main screen with search, filters, item cards |
| **Add Item** | `add-item.html` | Form to add new food items with OCR simulation |
| **Item Detail** | `item-detail.html` | View item details, mark consumed/wasted |
| **Expiring Soon** | `expiring-soon.html` | Items grouped by urgency (Today/This Week/Expired) |
| **Shopping List** | `shopping-list.html` | Checkable shopping list with **convert-to-inventory modal** |
| **Progress Dashboard** | `progress.html` | Local analytics: waste %, savings, impact metrics |
| **Interactive Tutorial** | `tutorial.html` | Guided walkthrough with spotlight overlays (demo) |
| **Onboarding Flow** | `onboarding/welcome.html` | 8-screen educational onboarding (see onboarding/README.md) |

## Features

✅ **Fully clickable navigation** between screens  
✅ **Interactive elements**: checkboxes, buttons, modals  
✅ **Shopping → Inventory conversion**: Modal with expiry date + location picker  
✅ **Progress dashboard**: Waste %, savings, environmental impact visualization  
✅ **Interactive tutorial**: Spotlight overlays guide users through app  
✅ **Toast notifications** for user feedback  
✅ **Mobile-first design** (390×844px iPhone frame)  
✅ **Responsive** (adapts to real phone screens)  
✅ **Simulated interactions**: OCR camera, waste reason picker, item conversion  

## User Testing Instructions

**Share this URL with participants and ask them to complete these tasks:**

1. Add a new food item (milk, expires in 3 days)
2. Find items expiring today
3. Mark an item as consumed
4. Add eggs to shopping list
5. Mark eggs as purchased and convert to inventory

See [`planning/issues/060-clickable-prototype-walkthrough-capture-feedback-5-users.md`](../planning/issues/060-clickable-prototype-walkthrough-capture-feedback-5-users.md) for full facilitator script and survey template.

## Tech Stack

- **Pure HTML/CSS/JavaScript** (no frameworks)
- **No build step** (edit and refresh)
- **Mobile-first** responsive design
- **Emoji icons** (no image assets needed)

## Making Changes

1. Edit HTML files for content/structure
2. Edit `styles.css` for styling
3. Refresh browser to see changes
4. Re-deploy if using hosted version

## File Structure

```
prototype/
├── index.html              # Inventory list (default screen)
├── add-item.html           # Add item form
├── item-detail.html        # Item detail view
├── expiring-soon.html      # Expiring items grouped by urgency
├── shopping-list.html      # Shopping list with convert flow
├── styles.css              # Shared styles
└── README.md               # This file
```

## Browser Compatibility

✅ Chrome/Edge (recommended)  
✅ Safari (iOS/macOS)  
✅ Firefox  
⚠️ Requires modern browser with ES6+ support

## Next Steps

After user testing:
1. Compile findings in `planning/docs/research/round1.md`
2. Identify top 3-5 UX issues
3. Update wireframes or create follow-up issues for M2
4. Transition to Flutter implementation (issue #090)

---

**Questions?** See main repo [`planning/AGENTS.md`](../planning/AGENTS.md) or issue [`#060`](../planning/issues/060-clickable-prototype-walkthrough-capture-feedback-5-users.md).
