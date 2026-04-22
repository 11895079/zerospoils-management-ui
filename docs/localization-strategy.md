# ZeroSpoils Localization & Internationalization (i18n) Strategy

## Overview
ZeroSpoils supports multi-language and multi-region deployment with a focus on Canada launch (English + French-Canadian). The app uses Flutter's built-in `intl` package and ARB (Application Resource Bundle) format for string extraction and locale support.

## Architecture

### Directory Structure
```
app/
├── lib/
│   ├── l10n/                    # Localization source files
│   │   ├── app_en.arb           # English (base template)
│   │   ├── app_fr.arb           # French (base/fallback)
│   │   ├── app_fr_CA.arb        # French-Canadian (region-specific)
│   │   ├── app_es.arb           # Spanish (complete translation)
│   │   ├── app_de.arb           # German (complete translation)
│   │   ├── app_pt.arb           # Portuguese (complete translation)
│   │   └── ...                  # Future locales (it.arb, nl.arb, etc.)
│   ├── generated_l10n/          # Auto-generated code (do not edit)
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_de.dart
│   │   ├── app_localizations_en.dart
│   │   ├── app_localizations_es.dart
│   │   ├── app_localizations_fr.dart
│   │   └── app_localizations_pt.dart
│   └── main.dart                # Localization config in MaterialApp
├── l10n.yaml                    # Flutter gen-l10n configuration
└── pubspec.yaml                 # flutter: generate: true
```

### Key Files
1. **app_en.arb** — Base English string templates + placeholders (source of truth)
2. **app_fr.arb** — French fallback (supports `Locale('fr')`)
3. **app_fr_CA.arb** — French-Canadian variant (supports `Locale('fr', 'CA')`)
4. **app_es.arb** — Spanish complete translation (supports `Locale('es')`)
5. **app_de.arb** — German complete translation (supports `Locale('de')`)
6. **app_pt.arb** — Portuguese complete translation (supports `Locale('pt')`)
7. **l10n.yaml** — gen-l10n config (template file, supported locales, output settings)
8. **generated_l10n/app_localizations.dart** — Main generated class (never edit)

## Workflow

### Adding New Strings

1. **Edit app_en.arb** (English base file):
   ```json
   {
     "buttonAdd": "Add",
     "dialogTitleDelete": "Delete Item",
     "itemCountFormat": "Showing {count} items",
     "@itemCountFormat": {
       "placeholders": {
         "count": {
           "type": "int"
         }
       }
     }
   }
   ```

2. **Add translations to all locale files** (app_fr.arb, app_fr_CA.arb, app_es.arb, app_de.arb, app_pt.arb, etc.):
   
   **French (app_fr.arb):**
   ```json
   {
     "buttonAdd": "Ajouter",
     "dialogTitleDelete": "Supprimer l'article",
     "itemCountFormat": "Affichage de {count} articles",
     "@itemCountFormat": {
       "placeholders": {
         "count": {
           "type": "int"
         }
       }
     }
   }
   ```
   
   **Spanish (app_es.arb):**
   ```json
   {
     "buttonAdd": "Agregar",
     "dialogTitleDelete": "Eliminar Artículo",
     "itemCountFormat": "Mostrando {count} artículos",
     "@itemCountFormat": {
       "placeholders": {
         "count": {
           "type": "int"
         }
       }
     }
   }
   ```

3. **Regenerate localization code**:
   ```bash
   cd app
   flutter gen-l10n
   ```

4. **Use strings in Dart code**:
   ```dart
   import 'generated_l10n/app_localizations.dart';
   
   // In build() method:
   Text(AppLocalizations.of(context)!.buttonAdd),
   Text(AppLocalizations.of(context)!.itemCountFormat(5)),
   ```

### String Naming Conventions
- **Button labels**: `button{Action}` (e.g., `buttonAdd`, `buttonDelete`, `buttonSave`)
- **Screen titles**: `screenTitle{Screen}` (e.g., `screenTitleInventory`, `screenTitleSettings`)
- **Labels**: `label{Field}` (e.g., `labelCategory`, `labelExpiry`)
- **Error messages**: `error{Type}` (e.g., `errorUnableToLoadItems`, `errorPermissionDenied`)
- **Feedback/UI text**: `feedback{Action}` (e.g., `feedbackOcrBarcodeSuccess`)

## Supported Locales

| Locale | Language | Region | Priority | Status | Completeness |
|--------|----------|--------|----------|--------|--------------|
| `en` | English | Any | P0 (Launch) | ✅ Complete | 100% (140+ strings) |
| `fr` | French | Any | P0 (Launch) | ✅ Complete | 100% (140+ strings) |
| `fr_CA` | French | Canada | P0 (Launch) | ✅ Complete | 100% (140+ strings) |
| `es` | Spanish | Any | P1 | ✅ Complete | 100% (140+ strings) |
| `de` | German | Any | P1 | ✅ Complete | 100% (140+ strings) |
| `pt` | Portuguese | Any | P1 | ✅ Complete | 100% (140+ strings) |

**Note:** Locale selection follows the device locale when supported, with fallback to English (`en`). For user preference override, implement a settings page (see M3/195 feedback settings).

## Date & Number Formatting

The app respects device locale for date and number formatting via Flutter's `intl` package:

```dart
import 'package:intl/intl.dart';

// Format dates per device locale
final dateFormatter = DateFormat.yMMMd(); // "Jan 15, 2026" (en) / "15 janv. 2026" (fr)
final dateString = dateFormatter.format(DateTime.now());

// Format numbers per device locale
final numberFormatter = NumberFormat.currency(locale: Locale('fr_CA').toString());
final priceString = numberFormatter.format(9.99); // "9,99 $" (fr-CA) vs "$ 9.99" (en)

// Preference-based formatting utility in the app (see core/utils/date_formatter.dart)
final expiryDate = AppDateFormatter.formatDate(item.expiryDate, 'MM/DD/YYYY');
```

### Locale-Specific Handling
- **French-Canadian (fr_CA)**: Currency symbol **right-aligned** (e.g., "9,99 $"), comma as decimal separator
- **French (fr)**: Currency symbol varies by context
- **English (en)**: Currency symbol **left-aligned** (e.g., "$9.99"), period as decimal separator

## Platform Implementation

### Flutter Configuration (pubspec.yaml)
```yaml
flutter:
  generate: true
```

### MaterialApp Configuration (main.dart)
```dart
MaterialApp.router(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  localeResolutionCallback: (deviceLocale, supportedLocales) {
    // Return exact or language-only match; fallback to English.
  },
  supportedLocales: const [
    Locale('en'),
    Locale('fr'),
    Locale('fr', 'CA'),
    Locale('es'),
    Locale('de'),
    Locale('pt'),
  ],
  // ...
)
```

### l10n.yaml Configuration
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/generated_l10n
preferred-supported-locales:
  - en
  - fr_CA
  - es
  - de
  - pt
```

## Feedback & Sound Settings Localization

**New in M3/195:** Haptic feedback and audio settings are localized:

| Key | English | French-Canadian |
|-----|---------|-----------------|
| `settingsFeedback` | "Feedback & Sounds" | "Rétroaction et sons" |
| `feedbackHapticFeedback` | "Haptic Feedback" | "Rétroaction haptique" |
| `feedbackOcrBarcodeSuccess` | "Barcode Scan Success" | "Succès de la lecture du code-barres" |
| `feedbackOcrExpirySuccess` | "Expiry Date Recognition" | "Reconnaissance de la date d'expiration" |
| `feedbackBeepVolume` | "Beep Volume" | "Volume du bip" |
| `feedbackHapticIntensity` | "Haptic Intensity" | "Intensité haptique" |

All strings are stored in ARB files and auto-generated into `AppLocalizations` (e.g., `AppLocalizations.of(context)!.feedbackHapticFeedback`).

## CI/CD & Validation

### Pre-Commit Checks
1. **ARB syntax validation**: `flutter gen-l10n` validates ARB JSON structure
2. **Hardcoded string detection** (future): Lint/CI rule to flag direct string literals in UI widgets
3. **Translation completeness**: Ensure all keys in `app_en.arb` are present in `app_fr.arb` and `app_fr_CA.arb`

### GitHub Actions Workflow
```yaml
- name: Validate localization files
  run: |
    cd app
    flutter gen-l10n

# Optional future step: hardcoded-string lint gate
```

### Manual QA
1. **French locale rendering**: Test UI with device locale set to `fr_CA`
   - Verify no text clipping (French text is ~20% longer than English)
   - Check date/currency formatting (commas vs periods)
   - Test RTL support if added (future)

2. **Emoji & special characters**: Ensure proper rendering across platforms
3. **Placeholder substitution**: Verify `{count}`, `{amount}` placeholders resolve correctly

## Best Practices

### DO ✅
- Use ARB files for **all** user-facing strings
- Group related strings by prefix (`button*`, `label*`, `error*`)
- Keep translations concise (target length = English + 20%)
- Use context keys (`@key`) for translator notes and placeholder definitions
- Test French UI for text overflow (French ≈ 120% English length)
- Run `flutter gen-l10n` after every ARB edit

### DON'T ❌
- Hardcode strings in Dart code (use `AppLocalizations.of(context)!.key`)
- Edit `generated_l10n/*.dart` files (auto-generated, changes will be overwritten)
- Use string interpolation in templates (use placeholders: `{count}`)
- Forget locale fallback chain: `fr_CA` → `fr` → `en` (ensure `app_fr.arb` exists)
- Leave incomplete translations (all keys in `app_en.arb` must exist in `app_fr.arb`)

## Testing

### Unit Tests
```dart
testWidgets('French locale renders without clipping', (tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr', 'CA'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.feedbackHapticFeedback,
          ),
        ),
      ),
    ),
  );

  expect(find.byType(Text), findsWidgets);
  // Verify no overflow or text clipping
});
```

### Manual Testing Checklist
- [ ] Switch device locale to French-Canadian in Settings
- [ ] App respects locale change without restart
- [ ] All screens render without text clipping
- [ ] Date formatting uses French convention (e.g., "15 avril 2026")
- [ ] Currency displays correctly (e.g., "9,99 $")
- [ ] Barcode OCR success message displays in French
- [ ] Feedback settings show French labels

## Future Enhancements

1. **User locale preference** (M4): Add Settings → Language picker to override device locale
2. **RTL support**: Add `Arabic (ar)` and `Hebrew (he)` with bidirectional text rendering
3. **Pluralization**: Implement ICU message format for languages with complex plural rules
4. **Context-aware formatting**: Use `.yMMMd()` vs `.yMd()` based on locale
5. **In-app language switching**: No app restart required
6. **Translation management**: Integrate with crowdsourcing platform (e.g., Crowdin) for community translations

## References

- [Flutter Internationalizing Flutter apps](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
- [ARB Application Resource Bundle Specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Dart intl package](https://pub.dev/packages/intl)
- [Flutter gen-l10n documentation](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-22 | ARB + gen-l10n | Industry standard for Flutter i18n; code generation reduces manual boilerplate |
| 2026-04-22 | Locale default: `en` | English-first MVP; user preference override deferred to M4 |
| 2026-04-22 | Feedback strings + haptic service | OCR events should be locale-aware; users control granular feedback per event type |
| 2026-04-22 | No RTL in M3 | Complexity tradeoff; staged rollout post-launch |
