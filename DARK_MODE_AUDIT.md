# M4/296: Dark Mode Contrast & Readability Audit

## Audit Date
Started: May 18, 2026

## Audit Scope (10 Screens)

### Screen Audit Checklist

- [ ] **1. Onboarding** (app/lib/presentation/screens/onboarding_screen.dart)
  - Primary text contrast in dark
  - Button contrast
  - Background/surface pairing
  - Issues found: 
  - Fixes needed:

- [ ] **2. Inventory** (app/lib/presentation/screens/inventory_screen.dart)
  - Item list text color
  - Secondary labels (location, expiry date)
  - Empty state text
  - Issues found:
  - Fixes needed:

- [ ] **3. Add/Edit Item** (app/lib/presentation/screens/item_form_screen.dart)
  - Form labels (primary)
  - Helper text/hints (secondary)
  - Validation error messages
  - Issues found:
  - Fixes needed:

- [ ] **4. Item Detail** (app/lib/presentation/screens/item_detail_screen.dart)
  - Title/body text contrast
  - Badge backgrounds + text
  - Metadata labels (category, location, cost)
  - Action button text
  - Issues found:
  - Fixes needed:

- [ ] **5. Expiring Soon** (app/lib/presentation/screens/expiring_soon_screen.dart)
  - Item list secondary text
  - Days remaining badges
  - Empty state
  - Issues found:
  - Fixes needed:

- [ ] **6. Shopping List** (app/lib/presentation/screens/shopping_list_screen.dart)
  - Checked item text (strikethrough)
  - Quantity/unit labels
  - Card backgrounds
  - Issues found:
  - Fixes needed:

- [ ] **7. Settings** (app/lib/presentation/screens/settings_screen.dart)
  - Toggle labels
  - Divider visibility
  - Description/hint text
  - Issues found:
  - Fixes needed:

- [ ] **8. Progress** (app/lib/presentation/screens/progress_screen.dart)
  - Stats numbers/labels
  - Chart labels
  - Time period toggles
  - Issues found:
  - Fixes needed:

- [ ] **9. Feedback Drawer** (app/lib/presentation/widgets/feedback_drawer.dart)
  - Text input placeholder
  - Label text
  - Submit button
  - Issues found:
  - Fixes needed:

- [ ] **10. Receipt Capture/Review** (app/lib/presentation/screens/receipt_capture_screen.dart, receipt_review_screen.dart)
  - OCR text overlay
  - Detection status text
  - Date selection text
  - Issues found:
  - Fixes needed:

## Theme Token Analysis

### Current Dark Theme Colors (app_theme.dart)
- App bar background: `Color(0xFF101513)` (very dark)
- App bar foreground: `Color(0xFFF2F6F2)` (very light)
- Card color: `Color(0xFF1A201D)` (dark)
- Divider: `Color(0xFF2C3631)` (dark gray)

### Design Token Defaults (design_tokens.dart)
**Light Mode:**
- textPrimary: `#212121` (almost black)
- textSecondary: `#757575` (medium gray)
- textHint: `#BDBDBD` (light gray)

**Dark Mode:** (needs verification - may not exist)
- Issue: No dark-mode color overrides defined in AppColors
- Risk: Using light-mode colors directly in dark theme causes contrast failures

## Remediation Strategy

1. **Phase 1: Audit & Document**
   - [ ] Manually toggle dark mode on all 10 screens
   - [ ] Screenshot problematic text areas
   - [ ] Identify hardcoded colors vs theme colors
   - [ ] Document contrast ratios (use online checker if needed)

2. **Phase 2: Theme Token Updates**
   - [ ] Add dark-mode text color constants to AppColors
   - [ ] Update textSecondary/textHint for dark mode visibility
   - [ ] Create semantic color pairs (onSurface, onSurfaceVariant, outline)
   - [ ] Test ColorScheme.fromSeed brightness impact

3. **Phase 3: Widget Updates**
   - [ ] Replace hardcoded colors with theme colors
   - [ ] Update shared components (_buildToggleTile, _buildItemCard, etc.)
   - [ ] Fix badge/chip foreground/background pairs
   - [ ] Test all components in light + dark

4. **Phase 4: Testing**
   - [ ] Widget tests for color resolution in both themes
   - [ ] Manual QA on iOS simulator (light + dark)
   - [ ] Manual QA on Android emulator (light + dark)
   - [ ] Screenshot before/after for remediated areas

## Issues Found & Fixes (To Be Updated)

### Issue Category: Hardcoded Colors
- Status: TBD (audit in progress)

### Issue Category: Low Contrast Text
- Status: TBD (audit in progress)

### Issue Category: Surface Contrast Pairs
- Status: TBD (audit in progress)

## Test Coverage Plan

**Automated Tests:**
- [ ] Widget test: TextStyle resolution in dark mode (4+ test groups)
- [ ] Widget test: Card/chip background + text pair contrast
- [ ] Widget test: Error state visibility in dark
- [ ] Unit test: Theme color brightness validation

**Manual QA:**
- [ ] iOS: Navigate all 10 screens, light → dark toggle
- [ ] Android: Navigate all 10 screens, light → dark toggle
- [ ] Screenshot before/after for each remediated screen
- [ ] Verify no regression in light mode

## Telemetry Addition

- [ ] Add `ui_dark_mode_readability_reported` event handler
- [ ] Wire feedback drawer to enqueue event with { screen, issue_description }
- [ ] Test telemetry in demo + live modes

---

**Next Step:** Start manual audit of all 10 screens
