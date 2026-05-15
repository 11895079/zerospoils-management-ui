import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/theme/app_colors.dart';
import 'package:zerospoils/presentation/di/theme_providers.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';
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

    testWidgets('Feedback submit requires message', (WidgetTester tester) async {
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

  });
}
