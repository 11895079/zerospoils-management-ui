import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/reference/reference_pack_fetchers.dart';
import 'package:zerospoils/core/theme/app_colors.dart';
import 'package:zerospoils/presentation/di/localization_providers.dart';
import 'package:zerospoils/presentation/di/theme_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';
import 'package:zerospoils/presentation/di/repository_providers.dart';
import 'package:zerospoils/presentation/screens/settings_screen.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';
import 'package:zerospoils/presentation/widgets/feedback_drawer.dart';

void main() {
  Widget buildTestHarness() {
    return MaterialApp(
      home: ProviderScope(child: Scaffold(body: SettingsScreen())),
    );
  }

  Widget buildTestHarnessWithTelemetry(TelemetryClient client) {
    return MaterialApp(
      home: ProviderScope(
        overrides: [telemetryClientProvider.overrideWithValue(client)],
        child: Scaffold(body: SettingsScreen()),
      ),
    );
  }

  Widget buildThemeAwareHarnessWithTelemetry(TelemetryClient client) {
    return ProviderScope(
      overrides: [telemetryClientProvider.overrideWithValue(client)],
      child: Consumer(
        builder: (context, ref, _) {
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: Scaffold(body: SettingsScreen()),
          );
        },
      ),
    );
  }

  Widget buildDarkThemeHarness() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: ProviderScope(child: Scaffold(body: SettingsScreen())),
    );
  }

  Finder tileForIcon(IconData icon) {
    return find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(ListTile),
    );
  }

  Finder switchForIcon(IconData icon) {
    return find.descendant(
      of: tileForIcon(icon),
      matching: find.byType(Switch),
    );
  }

  Finder dropdownForIcon(IconData icon) {
    return find.descendant(
      of: tileForIcon(icon),
      matching: find.byType(DropdownButton<int>),
    );
  }

  Finder tileForKey(Key key) {
    return find.byKey(key);
  }

  Finder dropdownForKey(Key key) {
    return find.descendant(
      of: tileForKey(key),
      matching: find.byType(DropdownButton<String>),
    );
  }

  Finder switchForKey(Key key) {
    return find.descendant(of: tileForKey(key), matching: find.byType(Switch));
  }

  Finder sliderForKey(Key key) {
    return find.descendant(of: tileForKey(key), matching: find.byType(Slider));
  }

  Future<void> scrollToIcon(WidgetTester tester, IconData icon) async {
    await tester.scrollUntilVisible(
      find.byIcon(icon),
      500, // Increased from 300 to ensure dropdowns fit on screen
      scrollable: find.byType(Scrollable),
    );
    // Extra settle to ensure dropdown menus have space to render fully
    await tester.pumpAndSettle();
  }

  group('SettingsScreen - Notification Preferences & Telemetry', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
      });
    });

    testWidgets('Renders notification preference controls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.notifications_active);

      expect(switchForIcon(Icons.notifications_active), findsOneWidget);
      expect(dropdownForIcon(Icons.timer), findsOneWidget);
      expect(switchForIcon(Icons.music_note), findsOneWidget);
      expect(switchForIcon(Icons.vibration), findsOneWidget);
    });

    testWidgets('Toggling notifications persists to SharedPreferences', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.notifications_active);

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled') ?? true, true);

      await tester.tap(switchForIcon(Icons.notifications_active));
      await tester.pumpAndSettle();

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), false);
    });

    testWidgets('Changing expiry lead time persists preference', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.timer);

      await tester.tap(dropdownForIcon(Icons.timer));
      await tester.pumpAndSettle();

      final option7days = find.byWidgetPredicate(
        (widget) => widget is DropdownMenuItem<int> && widget.value == 7,
      );
      expect(option7days, findsWidgets);

      await tester.tap(option7days.last);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('expiry_lead_time_days'), 7);
    });

    testWidgets(
      'Sound and vibration toggles persist preferences independently',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestHarness());
        await tester.pumpAndSettle();

        await scrollToIcon(tester, Icons.music_note);

        var prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sound_enabled') ?? true, true);
        expect(prefs.getBool('vibration_enabled') ?? true, true);

        await tester.tap(switchForIcon(Icons.music_note));
        await tester.pumpAndSettle();

        prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sound_enabled'), false);
        expect(prefs.getBool('vibration_enabled'), true);
      },
    );

    testWidgets('Preferences are loaded from SharedPreferences on build', (
      WidgetTester tester,
    ) async {
      // Override defaults for this specific test
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': false,
        'expiry_lead_time_days': 7,
        'sound_enabled': false,
        'vibration_enabled': false,
        'date_format': 'DD/MM/YYYY',
      });

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.notifications_active);

      final notificationSwitch = tester.widget<Switch>(
        switchForIcon(Icons.notifications_active),
      );
      final soundSwitch = tester.widget<Switch>(
        switchForIcon(Icons.music_note),
      );
      final vibrationSwitch = tester.widget<Switch>(
        switchForIcon(Icons.vibration),
      );
      final dropdown = tester.widget<DropdownButton<int>>(
        dropdownForIcon(Icons.timer),
      );

      expect(notificationSwitch.value, false);
      expect(soundSwitch.value, false);
      expect(vibrationSwitch.value, false);
      expect(dropdown.value, 7);
    });

    testWidgets('Notification toggle emits telemetry event', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.notifications_active);

      await tester.tap(switchForIcon(Icons.notifications_active));
      await tester.pumpAndSettle();

      final event = telemetry.events.last;
      expect(event['name'], 'notification_toggle_changed');
      expect(event['properties']['notifications_enabled'], false);
    });

    testWidgets('Lead time change emits telemetry event', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.timer);

      await tester.tap(dropdownForIcon(Icons.timer));
      await tester.pumpAndSettle();

      final option7days = find.byWidgetPredicate(
        (widget) => widget is DropdownMenuItem<int> && widget.value == 7,
      );
      await tester.tap(option7days.last);
      await tester.pumpAndSettle();

      final event = telemetry.events.last;
      expect(event['name'], 'expiry_warning_changed');
      expect(event['properties']['lead_time_days'], 7);
    });

    testWidgets('Sound and vibration toggles emit telemetry events', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.music_note);

      await tester.tap(switchForIcon(Icons.music_note));
      await tester.pumpAndSettle();

      final soundEvent = telemetry.events.last;
      expect(soundEvent['name'], 'sound_toggle_changed');
      expect(soundEvent['properties']['sound_enabled'], false);

      await tester.tap(switchForIcon(Icons.vibration));
      await tester.pumpAndSettle();

      final vibrationEvent = telemetry.events.last;
      expect(vibrationEvent['name'], 'vibration_toggle_changed');
      expect(vibrationEvent['properties']['vibration_enabled'], false);
    });

    testWidgets('Dark mode toggle persists preference', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.dark_mode);

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode_enabled') ?? false, false);

      await tester.tap(switchForIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode_enabled'), true);
    });

    testWidgets('Dark mode toggle emits telemetry event', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.dark_mode);

      await tester.tap(switchForIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      final event = telemetry.events.last;
      expect(event['name'], 'theme_changed');
      expect(event['properties']['theme'], 'dark');
    });

    testWidgets('Camera-assisted add toggle is no longer shown', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(buildTestHarness());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.camera_alt), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Dark mode toggle updates app theme brightness live', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildThemeAwareHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.dark_mode);

      final materialAppBefore = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );
      expect(materialAppBefore.themeMode, ThemeMode.light);

      await tester.tap(switchForIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      final materialAppAfter = tester.widget<MaterialApp>(
        find.byType(MaterialApp).first,
      );
      expect(materialAppAfter.themeMode, ThemeMode.dark);
    });

    testWidgets('Settings tiles use dark theme colors in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDarkThemeHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.dark_mode);

      final tile = tileForIcon(Icons.dark_mode);
      final icon = tester.widget<Icon>(
        find.descendant(of: tile, matching: find.byIcon(Icons.dark_mode)),
      );
      final title = tester.widget<Text>(
        find.descendant(of: tile, matching: find.byType(Text)).first,
      );
      final theme = Theme.of(tester.element(find.byType(SettingsScreen)));

      expect(icon.color, isNot(AppColors.textPrimary));
      expect(icon.color, theme.colorScheme.onSurface);
      expect(title.style?.color, theme.textTheme.bodyMedium?.color);
    });

    testWidgets('Send Feedback opens feedback drawer', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.feedback_outlined);
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.feedback_outlined),
          matching: find.byType(ListTile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(feedbackDrawerKey), findsOneWidget);
      expect(
        telemetry.events.any((event) => event['name'] == 'feedback_opened'),
        isTrue,
      );
    });

    testWidgets('Feedback submit requires message', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.feedback_outlined);
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.feedback_outlined),
          matching: find.byType(ListTile),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Please enter feedback before submitting.'),
        findsOneWidget,
      );
      expect(
        telemetry.events.any((event) => event['name'] == 'feedback_submitted'),
        isFalse,
      );
    });

    testWidgets('Dark mode readability category emits telemetry event', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.feedback_outlined);
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.feedback_outlined),
          matching: find.byType(ListTile),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_category_field')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('feedback_category_option_dark_mode_readability')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_message_field')),
        'Dark mode text contrast is hard to read in settings tiles.',
      );
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      final readabilityEvent = telemetry.events
          .cast<Map<String, dynamic>?>()
          .whereType<Map<String, dynamic>>()
          .firstWhere(
            (event) => event['name'] == 'ui_dark_mode_readability_reported',
          );

      expect(readabilityEvent['properties'], isA<Map<String, dynamic>>());
      final properties = readabilityEvent['properties'] as Map<String, dynamic>;
      expect(properties['source'], 'settings');
      expect(properties['category'], 'dark_mode_readability');
      expect(properties['message_length'], greaterThan(0));
      expect(properties['has_contact_email'], isFalse);
    });

    testWidgets(
      'Dark mode readability telemetry not emitted on category select only',
      (WidgetTester tester) async {
        final telemetry = TelemetryClient();

        await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
        await tester.pumpAndSettle();

        await scrollToIcon(tester, Icons.feedback_outlined);
        await tester.tap(
          find.ancestor(
            of: find.byIcon(Icons.feedback_outlined),
            matching: find.byType(ListTile),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('feedback_category_field')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const Key('feedback_category_option_dark_mode_readability'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          telemetry.events.any(
            (event) => event['name'] == 'ui_dark_mode_readability_reported',
          ),
          isFalse,
        );
      },
    );

    testWidgets('Reference pack diagnostics render version, update, and source', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
        'refpack_barcode_active_version': 'v9',
        'refpack_barcode_updated_at': '2026-05-30T14:30:00Z',
        'refpack_barcode_records_json':
            '{"schema_version":1,"records":[{"barcode":"055000132152","product_name":"Coffee"}]}',
      });

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.dataset_linked),
        500,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reference Data Packs'), findsOneWidget);
      expect(
        find.textContaining('Active barcode pack: v9 (1 records)'),
        findsOneWidget,
      );
      expect(find.textContaining('Last update: 2026-05-30'), findsOneWidget);
      expect(
        find.textContaining(
          'Manifest source: Firebase Remote Config (${ReferencePackRemoteConfigKeys.manifestUrl})',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Language selection loads and persists preference', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
        'app_locale': 'fr_CA',
      });

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        tileForKey(const Key('language_dropdown_tile')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DropdownButton<String>>(
              dropdownForKey(const Key('language_dropdown_tile')),
            )
            .value,
        'fr_CA',
      );

      await tester.tap(dropdownForKey(const Key('language_dropdown_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(appLocalePreferenceKey), 'en');
      expect(
        tester
            .widget<DropdownButton<String>>(
              dropdownForKey(const Key('language_dropdown_tile')),
            )
            .value,
        'en',
      );
    });

    testWidgets('Reference data region and language persist preference', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
        referencePackRegionPreferenceKey: 'ca',
        referencePackLanguagePreferenceKey: 'fr-CA',
      });

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        tileForKey(const Key('reference_language_dropdown_tile')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DropdownButton<String>>(
              dropdownForKey(const Key('reference_region_dropdown_tile')),
            )
            .value,
        'ca',
      );
      expect(
        tester
            .widget<DropdownButton<String>>(
              dropdownForKey(const Key('reference_language_dropdown_tile')),
            )
            .value,
        'fr-CA',
      );

      await tester.ensureVisible(
        tileForKey(const Key('reference_region_dropdown_tile')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        dropdownForKey(const Key('reference_region_dropdown_tile')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('United States').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        tileForKey(const Key('reference_language_dropdown_tile')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        dropdownForKey(const Key('reference_language_dropdown_tile')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(referencePackRegionPreferenceKey), 'us');
      expect(prefs.getString(referencePackLanguagePreferenceKey), 'en');
    });

    testWidgets('Feedback settings controls render', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        tileForKey(const Key('feedback_haptic_toggle')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(tileForKey(const Key('feedback_haptic_toggle')), findsOneWidget);
      expect(tileForKey(const Key('feedback_audio_toggle')), findsOneWidget);
      expect(
        tileForKey(const Key('feedback_beep_volume_slider')),
        findsOneWidget,
      );
      expect(
        sliderForKey(const Key('feedback_beep_volume_slider')),
        findsOneWidget,
      );
      expect(
        tileForKey(const Key('feedback_haptic_intensity_dropdown')),
        findsOneWidget,
      );
      expect(
        tileForKey(const Key('feedback_scanner_barcode_toggle')),
        findsOneWidget,
      );
      expect(
        tileForKey(const Key('feedback_scanner_expiry_toggle')),
        findsOneWidget,
      );
      expect(
        tileForKey(const Key('feedback_scanner_receipt_toggle')),
        findsOneWidget,
      );
      expect(
        tileForKey(const Key('feedback_scanner_produce_toggle')),
        findsOneWidget,
      );
    });

    testWidgets('Feedback settings persist and emit telemetry', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        tileForKey(const Key('feedback_haptic_toggle')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(switchForKey(const Key('feedback_haptic_toggle')));
      await tester.pumpAndSettle();

      await tester.tap(switchForKey(const Key('feedback_audio_toggle')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('feedback_haptic_enabled'), false);
      expect(prefs.getBool('feedback_audio_enabled'), false);

      expect(
        telemetry.events.any(
          (event) => event['name'] == 'feedback_haptic_toggle_changed',
        ),
        isTrue,
      );
      expect(
        telemetry.events.any(
          (event) =>
              event['name'] == 'feedback_audio_toggle_changed' &&
              event['properties']['enabled'] == false,
        ),
        isTrue,
      );
    });

    testWidgets('Scanner toggle persists and emits telemetry', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(buildTestHarnessWithTelemetry(telemetry));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        tileForKey(const Key('feedback_scanner_barcode_toggle')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        switchForKey(const Key('feedback_scanner_barcode_toggle')),
      );
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('feedback_scanner_barcode_enabled'), false);

      expect(
        telemetry.events.any(
          (event) =>
              event['name'] == 'feedback_scanner_toggle_changed' &&
              event['properties']['scanner'] == 'barcodeSuccess' &&
              event['properties']['enabled'] == false,
        ),
        isTrue,
      );
    });

    testWidgets('Feedback settings are loaded from SharedPreferences on init', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'feedback_haptic_enabled': false,
        'feedback_audio_enabled': false,
        'feedback_scanner_barcode_enabled': false,
      });

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        tileForKey(const Key('feedback_haptic_toggle')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Switch>(switchForKey(const Key('feedback_haptic_toggle')))
            .value,
        false,
      );
      expect(
        tester
            .widget<Switch>(switchForKey(const Key('feedback_audio_toggle')))
            .value,
        false,
      );

      await tester.scrollUntilVisible(
        tileForKey(const Key('feedback_scanner_barcode_toggle')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Switch>(
              switchForKey(const Key('feedback_scanner_barcode_toggle')),
            )
            .value,
        false,
      );
    });
  });

  group('SettingsScreen - Demo Mode Telemetry & Accessibility', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
        'demo_mode_enabled': false,
      });
    });

    testWidgets('Demo mode toggle emits telemetry event with enabled=true', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryClientProvider.overrideWithValue(telemetry),
            demoModeProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to demo mode toggle
      await scrollToIcon(tester, Icons.bug_report);

      // Toggle demo mode on
      await tester.tap(switchForIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      // Verify telemetry event was emitted
      expect(
        telemetry.events.any(
          (event) =>
              event['name'] == 'demo_mode_toggled' &&
              event['properties']['enabled'] == true &&
              event['properties']['active_namespace'] == 'demo',
        ),
        isTrue,
      );
    });

    testWidgets('Demo mode toggle emits telemetry event with enabled=false', (
      WidgetTester tester,
    ) async {
      final telemetry = TelemetryClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryClientProvider.overrideWithValue(telemetry),
            demoModeProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to demo mode toggle
      await scrollToIcon(tester, Icons.bug_report);

      // Toggle demo mode off
      await tester.tap(switchForIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      // Verify telemetry event was emitted with correct properties
      expect(
        telemetry.events.any(
          (event) =>
              event['name'] == 'demo_mode_toggled' &&
              event['properties']['enabled'] == false &&
              event['properties']['active_namespace'] == 'live',
        ),
        isTrue,
      );
    });

    testWidgets('Demo mode toggle has accessibility semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [demoModeProvider.overrideWith((ref) => false)],
          child: MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to demo mode toggle
      await scrollToIcon(tester, Icons.bug_report);

      // Verify switch exists for demo mode
      expect(switchForIcon(Icons.bug_report), findsOneWidget);

      // Check that demo mode ListTile and its semantics are present
      final demoModeTile = tileForIcon(Icons.bug_report);
      expect(demoModeTile, findsOneWidget);

      // Verify Semantics widgets are present for accessibility
      final semanticsWidgets = find.descendant(
        of: demoModeTile,
        matching: find.byType(Semantics),
      );
      expect(semanticsWidgets, findsWidgets);
    });
  });
}
