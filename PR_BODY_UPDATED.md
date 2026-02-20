## Summary
This PR implements the first batch of M2 MVP features alongside critical platform fixes and UI enhancements:
- Local storage infrastructure and migrations (M2/100)
- Expiry bucketing logic and classifier (M2/110)
- Shopping list repository with Hive persistence (M2/101)
- Onboarding and notification permissions flow (M2/120)
- **NEW:** Well-curated item icon library (200+ food/grocery items) for consistent UI display
- **NEW:** Fixed batch spinner visibility on Android (removed debug banner overlay)
- **NEW:** iOS Podfile path fix + Android ML Kit dependencies + iOS deployment targets
- Telemetry instrumentation for key actions
- Test and CI reliability improvements

## Details
### Core M2 Features
- Adds Hive-based repositories for inventory and shopping list
- Implements expiry bucketing and classifier utilities
- Integrates onboarding and permissions screens
- Refactors and fixes widget/unit tests for TDD compliance
- Excludes audit log (M2/102) pending further implementation

### Platform Fixes
- **iOS Podfile**: Fixed path in `ios/Podfile` to correctly reference Flutter framework location
- **Android ML Kit**: Added ML Kit Vision dependencies for future OCR receipt capture feature
- **iOS Targets**: Updated iOS deployment targets for compatibility

### Icon Library Enhancement
- **ItemIconLibrary**: Comprehensive static library mapping 200+ food/grocery items to Material Design icons
- **Categories Covered**: 
  - Produce (fruits, vegetables, international produce)
  - Dairy & Alternatives (milk variants, cheese, yogurt, eggs)
  - Meat & Seafood (chicken, beef, pork, fish, shellfish, tofu, tempeh)
  - Grains & Starches (rice, pasta, bread, lentils, beans)
  - Pantry (oils, spices, sauces, condiments, honey)
  - Beverages (juices, sodas, wine, beer, water, coffee, tea)
  - Frozen Foods (pizza, desserts, vegetables)
  - Prepared/Cooked Foods (curry, dhal, amala, fufu, stew, sushi)
  - Snacks & Desserts (chips, cookies, candy, granola, nuts)
  - Specialty/International (miso, kimchi, kombucha, wasabi, garam masala)
- **Intelligent Matching**: 
  - Exact match (case-insensitive, trimmed)
  - Substring fallback (e.g., "cherry tomatoes" → tomato icon)
  - Category fallback when no item match
  - Generic fallback for unknown items
- **Widgets**: 
  - `ItemIcon`: Flexible sizing, colors, background, border radius
  - `ItemIconWithLabel`: Horizontal/vertical layout with category labels
- **Offline-First**: Uses Material Design icons, no external dependencies
- **Test Coverage**: 25 unit + widget tests validating library logic and UI rendering

### Batch Spinner Fix
- Removed debug banner overlay that was blocking batch processing spinner visibility on Android
- Spinner now properly displays during batch operations

## Linked Issues
- Closes M2/100, M2/101, M2/110, M2/120
- Fixes critical Android visibility issue
- Adds foundation for 3x3 grid inventory layout (todo)

## Test Plan
✅ **Automated:**
- All 198 tests passing (unit, widget, integration)
- Item icon library: 14 unit tests + 11 widget tests validating:
  - Exact/substring/category/generic matching logic
  - International food items (amala, dhal, ramen, curry, etc.)
  - Case-insensitive and whitespace handling
  - Icon rendering with custom sizing, colors, background
  - ItemIconWithLabel horizontal/vertical layouts
- Pre-commit checks: formatting, analyzer, full test suite
- Platform builds: iOS/Android verification

✅ **Manual:**
1. Onboarding and permissions flow on iOS simulator
2. Onboarding and permissions flow on Android emulator
3. Batch processing spinner visible during file operations (Android)
4. Item icon rendering in inventory list screens
5. Verify theme tokens applied (spacing, colors, typography)

## Notes
- Icon library ready for integration into inventory list grid layout (next todo)
- Platform fixes enable reliable builds and UI consistency across devices
- Foundation established for 3x3 grid item display with icons
- All changes follow Flutter/Dart best practices and maintain test coverage ≥80%
