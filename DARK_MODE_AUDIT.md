# M4/296: Dark Mode Contrast & Readability Audit

## Audit Date
Started: May 18, 2026
Updated: May 18, 2026

## Latest Manual QA Snapshot
- Chrome device pass completed for core screens.
- Resolved during this pass:
  - Add/Edit Item title low contrast in dark mode.
  - Add/Edit Item category value text low contrast in dark mode.
- Follow-up pending:
  - Android device manual verification.
  - Additional iOS device verification.

## Audit Scope (10 Screens)

### Screen Audit Checklist

- [x] **1. Onboarding** (app/lib/presentation/screens/onboarding_screen.dart)
  - Primary text contrast in dark
  - Button contrast
  - Background/surface pairing
  - Issues found: Automated dark-theme coverage added; manual walkthrough deferred
  - Fixes needed: None in automated pass

- [x] **2. Inventory** (app/lib/presentation/screens/inventory_screen.dart)
  - Item list text color
  - Secondary labels (location, expiry date)
  - Empty state text
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **3. Add/Edit Item** (app/lib/presentation/screens/item_form_screen.dart)
  - Form labels (primary)
  - Helper text/hints (secondary)
  - Validation error messages
  - Issues found: Manual QA found low-contrast title and category value text in dark mode
  - Fixes needed: Resolved by switching preview title and category value text to theme-driven dark-safe colors

- [x] **4. Item Detail** (app/lib/presentation/screens/item_detail_screen.dart)
  - Title/body text contrast
  - Badge backgrounds + text
  - Metadata labels (category, location, cost)
  - Action button text
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **5. Expiring Soon** (app/lib/presentation/screens/expiring_soon_screen.dart)
  - Item list secondary text
  - Days remaining badges
  - Empty state
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **6. Shopping List** (app/lib/presentation/screens/shopping_list_screen.dart)
  - Checked item text (strikethrough)
  - Quantity/unit labels
  - Card backgrounds
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **7. Settings** (app/lib/presentation/screens/settings_screen.dart)
  - Toggle labels
  - Divider visibility
  - Description/hint text
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **8. Progress** (app/lib/presentation/screens/progress_screen.dart)
  - Stats numbers/labels
  - Chart labels
  - Time period toggles
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **9. Feedback Drawer** (app/lib/presentation/widgets/feedback_drawer.dart)
  - Text input placeholder
  - Label text
  - Submit button
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

- [x] **10. Receipt Capture/Review** (app/lib/presentation/screens/receipt_capture_screen.dart, receipt_review_screen.dart)
  - OCR text overlay
  - Detection status text
  - Date selection text
  - Issues found: No contrast regression in automated dark-mode tests
  - Fixes needed: None identified in current pass

## Theme Token Analysis

### Current Dark Theme Colors (app_theme.dart)
- App bar background: `AppColors.backgroundDark`
- App bar foreground: `AppColors.textPrimaryDark`
- Card color: `AppColors.cardBackgroundDark`
- Divider: `AppColors.borderDark`

### Design Token Defaults (design_tokens.dart)
**Light Mode:**
- textPrimary: `#212121` (almost black)
- textSecondary: `#757575` (medium gray)
- textHint: `#BDBDBD` (light gray)

**Dark Mode:**
- Implemented: Dedicated dark tokens in `app/lib/core/theme/app_colors.dart`
- Result: Shared dark palette now used by `app/lib/presentation/themes/app_theme.dart`

## Remediation Strategy

1. **Phase 1: Audit & Document**
  - [ ] Manually toggle dark mode on all 10 screens on Android + iOS devices (Chrome pass completed)
   - [ ] Screenshot problematic text areas
   - [ ] Identify hardcoded colors vs theme colors
   - [ ] Document contrast ratios (use online checker if needed)

2. **Phase 2: Theme Token Updates**
  - [x] Add dark-mode text color constants to AppColors
  - [x] Update textSecondary/textHint for dark mode visibility
  - [x] Create semantic color pairs (onSurface, onSurfaceVariant, outline)
  - [x] Test ColorScheme.fromSeed brightness impact

3. **Phase 3: Widget Updates**
  - [x] Replace hardcoded colors with theme colors
   - [ ] Update shared components (_buildToggleTile, _buildItemCard, etc.)
   - [ ] Fix badge/chip foreground/background pairs
  - [ ] Test all components in light + dark on Android + iOS manual pass

4. **Phase 4: Testing**
  - [x] Widget tests for color resolution in both themes
  - [x] Manual QA on iOS simulator launch/smoke verified
  - [ ] Manual QA on Android emulator (light + dark) - deferred
  - [ ] Screenshot before/after for remediated areas (optional supporting evidence only)

## Issues Found & Fixes (To Be Updated)

### Issue Category: Hardcoded Colors
- Status: Resolved for shared theme tokens (`app_theme.dart` now references `AppColors` dark tokens)

### Issue Category: Low Contrast Text
- Status: Mitigated via dark text token rollout and passing dark-theme widget suites

### Issue Category: Surface Contrast Pairs
- Status: Mitigated for scaffold/app bar/cards/inputs/bottom navigation in shared theme

## Test Coverage Plan

**Automated Tests:**
- [x] Widget test: TextStyle resolution in dark mode (4+ test groups)
- [x] Widget test: Card/chip background + text pair contrast
- [x] Widget test: Error state visibility in dark
- [x] Unit test: Theme color brightness validation

**Manual QA:**
- [x] iOS: App launch/smoke in simulator verified
- [x] Chrome device: manual dark-mode walkthrough completed for reported screens
- [ ] Android: Navigate all 10 screens, light -> dark toggle - deferred to follow-up verification pass
- [ ] Screenshot before/after for each remediated screen (optional supporting evidence only)
- [ ] Verify no regression in light mode

## Telemetry Addition

- [x] Add `ui_dark_mode_readability_reported` event handler
- [x] Wire feedback drawer to enqueue event with { screen, issue_description }
- [x] Test telemetry in demo + live modes

---

**Next Step:** Automated verification is complete; manual Android QA is deferred to a follow-up verification pass
