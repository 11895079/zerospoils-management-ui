import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';

void main() {
  group('TelemetryClient - Consent Gating', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Events are enqueued when consent is enabled', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'test_event',
        'properties': {'key': 'value'},
      });

      expect(client.events.length, 1);
      expect(client.events.first['name'], 'test_event');
    });

    test('Events are NOT enqueued when consent is disabled', () {
      final client = TelemetryClient(consentEnabled: false);

      client.enqueue({
        'name': 'test_event',
        'properties': {'key': 'value'},
      });

      expect(client.events.length, 0);
    });

    test('Callback is NOT invoked when consent is disabled', () {
      final client = TelemetryClient(consentEnabled: false);
      var callbackInvoked = false;

      client.setEmitCallback((name, properties) {
        callbackInvoked = true;
      });

      client.enqueue({
        'name': 'test_event',
        'properties': {'key': 'value'},
      });

      expect(callbackInvoked, false);
    });

    test('Callback is invoked when consent is enabled', () {
      final client = TelemetryClient(consentEnabled: true);
      String? capturedName;
      Map<String, dynamic>? capturedProperties;

      client.setEmitCallback((name, properties) {
        capturedName = name;
        capturedProperties = properties;
      });

      client.enqueue({
        'name': 'test_event',
        'properties': {'key': 'value'},
      });

      expect(capturedName, 'test_event');
      expect(capturedProperties, {'key': 'value'});
    });
  });

  group('TelemetryClient - Schema Validation (Debug Mode)', () {
    test('Accepts events with empty properties map', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({'name': 'test_event', 'properties': {}});

      expect(client.events.length, 1);
      expect(client.events.first['properties'], isA<Map<String, dynamic>>());
      expect(client.events.first['properties'], isEmpty);
    });

    test('Rejects events with missing name field', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({
          'properties': {'key': 'value'},
        }),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Rejects events with missing properties field', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({'name': 'test_event'}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Rejects events containing PII keys (email)', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({
          'name': 'test_event',
          'properties': {'email': 'user@example.com'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects events containing PII keys (phone)', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({
          'name': 'test_event',
          'properties': {'phone': '+1234567890'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects events containing PII keys (device_id)', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({
          'name': 'test_event',
          'properties': {'device_id': 'ABC123'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects events containing PII keys (ip_address)', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({
          'name': 'test_event',
          'properties': {'ip_address': '192.168.1.1'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Rejects events containing PII keys (full_name)', () {
      final client = TelemetryClient(consentEnabled: true);

      expect(
        () => client.enqueue({
          'name': 'test_event',
          'properties': {'full_name': 'John Doe'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Accepts events without PII keys', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'test_event',
        'properties': {
          'category': 'vegetables',
          'location': 'fridge',
          'lead_time_days': 3,
        },
      });

      expect(client.events.length, 1);
    });
  });

  group('TelemetryClient - Core Funnel Events', () {
    test('app_installed event is allowed', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'app_installed',
        'properties': {'is_first_install': true},
      });

      expect(client.events.length, 1);
    });

    test('onboarding_completed event is allowed', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'onboarding_completed',
        'properties': {'variant': 'short'},
      });

      expect(client.events.length, 1);
    });

    test('item_added event is allowed', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'item_added',
        'properties': {
          'category': 'vegetables',
          'location': 'fridge',
          'entry_method': 'manual',
        },
      });

      expect(client.events.length, 1);
    });

    test('inventory_viewed event is allowed', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'inventory_viewed',
        'properties': {'screen_name': 'inventory'},
      });

      expect(client.events.length, 1);
    });

    test('expiring_viewed event is allowed', () {
      final client = TelemetryClient(consentEnabled: true);

      client.enqueue({
        'name': 'expiring_viewed',
        'properties': {'screen_name': 'expiring_soon'},
      });

      expect(client.events.length, 1);
    });
  });
}
