# 530 — Prepared Food Presets & Storage Guidelines

**Epic:** Pro / UX Polish  
**Priority:** P2 (Nice-to-have for M4, enables faster data entry)  
**Size:** M (backend preset library + UI for onboarding/settings + recommendation logic)

---

## Context
Users who frequently cook and store prepared foods (e.g., jollof rice, pasta, soup, stews) currently have to manually enter expiry dates and storage locations every time. Many users don't know optimal storage durations, leading to conservative guesses or food waste.

**Problem:**
- Repetitive data entry for common prepared foods
- Users unsure how long items last in fridge vs. freezer
- No guidance on optimal storage locations
- Missed opportunity to educate users on food safety

**Opportunity:**
- Build a preset library of common prepared foods with storage guidelines
- Let users configure their own presets during onboarding
- Provide smart defaults when adding prepared items
- Surface storage recommendations in real-time

---

## Goal
Streamline prepared food entry by providing smart defaults and storage guidance based on user-configured presets and food safety best practices.

---

## Expected behavior

### During Onboarding (Optional Step)
After permissions screen, show:
```
📋 Set Up Your Meal Presets (Optional)

Do you cook these often? We'll remember storage times for you.

[ ] Jollof rice       [ ] Fried rice      [ ] Stew
[ ] Pasta dishes      [ ] Soup            [ ] Curry
[ ] Beans             [ ] Casseroles      [ ] Other: _____

[Skip for now]  [Save Presets →]
```

When user selects an item (e.g., "Jollof rice"), show modal:
```
🍚 Jollof Rice Storage

Fridge:    3-4 days
Freezer:   1 month
Pantry:    Not recommended (prepared food)

[Save]  [Cancel]
```

User can adjust durations before saving.

### When Adding Prepared Food
In `add-item.html`, when user:
1. Sets "Type" to "Prepared"
2. Starts typing item name (e.g., "Jol...")

**Autocomplete shows:**
```
🍚 Jollof rice (preset available)
```

**On selection:**
- If location already selected → auto-fill expiry based on preset
- If no location → show picker with recommendations:
  ```
  Location:
  • ❄️ Fridge (3-4 days) [Recommended]
  • 🧊 Freezer (1 month)
  ```

**Expiry field shows:**
```
Expiry Date: [Feb 3, 2026]  ℹ️
  └─ Preset: Jollof rice in Fridge lasts 3-4 days
```

### Settings Page — Manage Presets
Add new section:
```
⚙️ Settings

...

📋 Prepared Food Presets
Manage storage times for foods you cook often

[+ Add New Preset]

🍚 Jollof rice
  Fridge: 3-4 days · Freezer: 1 month
  [Edit]  [Delete]

🍝 Pasta dishes
  Fridge: 3-5 days · Freezer: 2 months
  [Edit]  [Delete]

...
```

---

## Acceptance criteria (Definition of Done)

### Functional
- [ ] User can configure prepared food presets during onboarding (optional step)
- [ ] Add item screen autocompletes prepared food names with "(preset available)" badge
- [ ] Selecting a preset auto-fills expiry date based on chosen location
- [ ] If no location selected, show storage recommendations inline
- [ ] User can add/edit/delete presets in Settings → Prepared Food Presets
- [ ] Presets stored locally (offline-first)
- [ ] Default preset library includes 10-15 common items (jollof rice, pasta, soup, stew, curry, beans, casseroles, fried rice, etc.)

### Data Model
- [ ] Preset schema: `{ name: string, fridge_days: number, freezer_days: number, recommended_location: 'fridge'|'freezer' }`
- [ ] User can override defaults per preset
- [ ] Presets sync to cloud (Pro tier) if enabled

### UX
- [ ] Storage recommendations display clear time units (days/weeks/months)
- [ ] Info icon next to auto-filled expiry explains where value came from
- [ ] Onboarding step is optional and skippable
- [ ] Settings page allows bulk import/export of presets (JSON)

### Telemetry
- [ ] Log `preset_created`, `preset_used`, `preset_edited`, `preset_deleted`
- [ ] Track which presets are most commonly used
- [ ] Log when users override auto-filled expiry (indicates preset may need adjustment)

### Offline-First
- [ ] Presets stored in local DB (Hive/sqflite)
- [ ] Works fully offline
- [ ] Syncs to cloud only if Pro user opts in

### Accessibility
- [ ] Preset autocomplete navigable via keyboard
- [ ] Storage recommendations readable by screen readers
- [ ] Info icons have accessible tooltips

---

## Out of scope
- Raw food expiry presets (use category defaults instead, issue #080)
- Community-shared presets (defer to M6+)
- Photo-based preset detection ("this looks like jollof rice")
- Recipe integration (linking presets to recipes)
- Nutritional info for prepared foods

---

## Implementation notes

### Default Preset Library (Examples)
```json
[
  { "name": "Jollof rice", "fridge_days": 4, "freezer_days": 30, "recommended": "fridge" },
  { "name": "Fried rice", "fridge_days": 4, "freezer_days": 30, "recommended": "fridge" },
  { "name": "Pasta dishes", "fridge_days": 4, "freezer_days": 60, "recommended": "fridge" },
  { "name": "Soup (cooked)", "fridge_days": 4, "freezer_days": 90, "recommended": "freezer" },
  { "name": "Stew (meat)", "fridge_days": 4, "freezer_days": 90, "recommended": "fridge" },
  { "name": "Curry", "fridge_days": 4, "freezer_days": 90, "recommended": "fridge" },
  { "name": "Beans (cooked)", "fridge_days": 5, "freezer_days": 180, "recommended": "freezer" },
  { "name": "Casserole", "fridge_days": 4, "freezer_days": 60, "recommended": "fridge" },
  { "name": "Chili", "fridge_days": 4, "freezer_days": 90, "recommended": "freezer" },
  { "name": "Lasagna", "fridge_days": 5, "freezer_days": 90, "recommended": "fridge" }
]
```

### Storage Duration Guidelines (Food Safety)
Based on USDA/FDA recommendations:
- **Cooked grains/rice:** 3-4 days (fridge), 1 month (freezer)
- **Cooked pasta:** 3-5 days (fridge), 2 months (freezer)
- **Soups/stews:** 3-4 days (fridge), 2-3 months (freezer)
- **Cooked meat dishes:** 3-4 days (fridge), 2-3 months (freezer)
- **Cooked beans:** 3-5 days (fridge), 6 months (freezer)

### UI Flow
1. **Onboarding:**
   - Show preset config as Step 7 (after permissions, before final "Get Started")
   - Grid of common items with checkboxes
   - Tapping item shows duration modal (editable)
   - Skip button → skip to final screen

2. **Add Item:**
   - Autocomplete from preset names when Type=Prepared
   - On selection → if location set, auto-fill expiry
   - Show info tooltip: "Based on your preset: [preset_name] in [location]"

3. **Settings:**
   - New section: "Prepared Food Presets"
   - List of presets with inline edit/delete
   - "+ Add New Preset" → form with name, fridge_days, freezer_days, recommended_location

### Edge Cases
- User edits auto-filled expiry → log as override (don't update preset)
- User deletes all presets → hide autocomplete badge, keep manual entry
- Preset has no freezer duration → hide freezer recommendation
- User has 50+ presets → paginate in Settings, cap autocomplete to top 10 matches

---

## Test plan

### Automated
- Unit test: preset storage/retrieval in local DB
- Unit test: autocomplete logic (fuzzy match, ranking)
- Unit test: expiry date calculation from preset + location
- Widget test: onboarding preset config screen (select, edit, skip)
- Widget test: add-item autocomplete and auto-fill
- Widget test: Settings preset CRUD (add, edit, delete)
- Integration test: preset sync (create locally, sync to cloud if Pro)

### Manual
1. **Onboarding:**
   - Complete onboarding → see preset config step
   - Select 3 presets → verify durations editable
   - Skip step → verify app continues to final screen
   - Go back from final screen → verify presets saved

2. **Add Item with Preset:**
   - Type "Jol" → see "Jollof rice (preset available)"
   - Select → choose Fridge → verify expiry auto-fills to +4 days
   - Edit expiry → verify no error
   - Submit → verify item saved with overridden expiry

3. **Storage Recommendations:**
   - Add prepared item with preset → don't select location
   - Verify location picker shows "Fridge (3-4 days) [Recommended]"
   - Select Freezer → verify expiry updates to +30 days

4. **Settings:**
   - Open Settings → Prepared Food Presets
   - Add new preset "Egusi soup" → Fridge: 3 days, Freezer: 60 days
   - Edit existing preset → change Jollof rice Fridge to 5 days
   - Delete preset → verify removed from list
   - Return to add-item → verify autocomplete reflects changes

5. **Offline:**
   - Disable network → configure presets
   - Add items using presets → verify works
   - Re-enable network (Pro user) → verify presets sync

---

## Dependencies
- **Blocked by:**
  - Issue #090 (Flutter skeleton + DI)
  - Issue #150 (Prepared food type definition)
  - Issue #180 (Settings page structure)

- **Blocks:**
  - Issue #520 (Personalized tips — can use preset data)
  - Issue #400 (Recipe suggestions — future integration)

---

## Related issues
- Issue #150: Define "prepared" food type vs. "raw"
- Issue #180: Settings page (add preset management section)
- Issue #520: Personalized tips (can suggest creating presets)
- Issue #080: Data model (category vs. preset-based expiry)
