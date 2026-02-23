import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';
import 'package:zerospoils/presentation/screens/settings_screen.dart';

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

  Future<void> scrollToIcon(WidgetTester tester, IconData icon) async {
    await tester.scrollUntilVisible(
      find.byIcon(icon),
      300,
      scrollable: find.byType(Scrollable),
    );
  }

  group('SettingsScreen - Analytics Consent', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'analytics_consent': true,
        'notifications_enabled': true,
        'expiry_lead_time_days': 3,
        'sound_enabled': true,
        'vibration_enabled': true,
        'date_format': 'MM/DD/YYYY',
      });
    });

    testWidgets('Renders analytics consent toggle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.analytics_outlined);

      expect(switchForIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('Toggling analytics consent persists to SharedPreferences', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.analytics_outlined);

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('analytics_consent'), true);

      await tester.tap(switchForIcon(Icons.analytics_outlined));
      await tester.pumpAndSettle();

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('analytics_consent'), false);
    });

    testWidgets('Toggling analytics consent emits telemetry event', (
      WidgetTester tester,
    ) async {
      final client = TelemetryClient(consentEnabled: true);
      String? capturedEventName;
      Map<String, dynamic>? capturedProperties;

      client.setEmitCallback((name, properties) {
        capturedEventName = name;
        capturedProperties = properties;
      });

      await tester.pumpWidget(buildTestHarnessWithTelemetry(client));
      await tester.pumpAndSettle();

      await scrollToIcon(tester, Icons.analytics_outlined);

      await tester.tap(switchForIcon(Icons.analytics_outlined));
      await tester.pumpAndSettle();

      expect(capturedEventName, 'analytics_consent_changed');
      expect(capturedProperties?['consent_enabled'], false);
    });

    testWidgets('Analytics consent OFF prevents event queueing', (
      WidgetTester tester,
    ) async {
      // Start with consent disabled
      SharedPreferences.setMockInitialValues({'analytics_consent': false});

      final client = TelemetryClient(consentEnabled: false);

      await tester.pumpWidget(buildTestHarnessWithTelemetry(client));
      await tester.pumpAndSettle();

      // Client should be initialized with consent OFF
      expect(client.consentEnabled, false);

      // Attempt to enqueue an event
      client.enqueue({
        'name': 'test_event',
        'properties': {'key': 'value'},
      });

      // Event should NOT be queued
      expect(client.events.length, 0);
    });

    testWidgets('Analytics consent ON allows event queueing', (
      WidgetTester tester,
    ) async {
      // Start with consent enabled (default)
      final client = TelemetryClient(consentEnabled: true);

      await tester.pumpWidget(buildTestHarnessWithTelemetry(client));
      await tester.pumpAndSettle();

      expect(client.consentEnabled, true);

      client.enqueue({
        'name': 'test_event',
        'properties': {'key': 'value'},
      });

      expect(client.events.length, 1);
    });
  });
}
