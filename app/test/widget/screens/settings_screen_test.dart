import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/screens/settings_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'expiry_lead_time_days': 3,
      'sound_enabled': true,
      'vibration_enabled': true,
      'date_format': 'MM/DD/YYYY',
    });
  });

  Widget buildTestHarness() {
    return MaterialApp(
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
      300,
      scrollable: find.byType(Scrollable),
    );
  }

  group('SettingsScreen - Notification Preferences & Telemetry', () {
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
      SharedPreferences.setMockInitialValues({
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
      });

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
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': true,
          'expiry_lead_time_days': 3,
          'sound_enabled': true,
          'vibration_enabled': true,
          'date_format': 'MM/DD/YYYY',
        });

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
  });
}
