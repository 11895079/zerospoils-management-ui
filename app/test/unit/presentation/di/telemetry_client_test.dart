import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:zerospoils/core/telemetry/telemetry_event_store.dart';
import 'package:zerospoils/presentation/di/service_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelemetryClient', () {
    late TelemetryEventStore store;

    setUpAll(() async {
      await setUpTestHive();
    });

    setUp(() async {
      store = TelemetryEventStore();
      await store.clear();
    });

    tearDownAll(() async {
      if (Hive.isBoxOpen(TelemetryEventStore.boxName)) {
        await Hive.box(TelemetryEventStore.boxName).close();
      }
      await tearDownTestHive();
    });

    test('persists enqueued events to store', () async {
      final client = TelemetryClient(consentEnabled: true, eventStore: store);

      client.enqueue({
        'name': 'reminder_opened',
        'properties': {'lead_time_days': 3, 'time_of_day': 'morning'},
      });

      final events = await store.getAll();
      expect(events.length, 1);
      expect(events.first['name'], 'reminder_opened');
    });

    test('injects platform property for core events when missing', () async {
      final client = TelemetryClient(consentEnabled: true, eventStore: store);

      client.enqueue({
        'name': 'item_added',
        'properties': {'entry_method': 'manual'},
      });

      final events = await store.getAll();
      expect(events.length, 1);
      final properties = Map<String, dynamic>.from(
        events.first['properties'] as Map,
      );
      expect(properties['platform'], isNotNull);
      expect(properties['platform'], isNotEmpty);
      expect(properties['entry_method'], 'manual');
    });
  });
}
