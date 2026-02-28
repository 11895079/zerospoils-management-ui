import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:zerospoils/core/telemetry/telemetry_event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelemetryEventStore', () {
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

    test('persists events in order', () async {
      await store.addEvent({
        'name': 'reminder_opened',
        'properties': {'lead_time_days': 3, 'time_of_day': 'morning'},
      });
      await store.addEvent({
        'name': 'item_marked_used',
        'properties': {'item_id': '1'},
      });

      final events = await store.getAll();
      expect(events.length, 2);
      expect(events[0]['name'], 'reminder_opened');
      expect(events[1]['name'], 'item_marked_used');
    });
  });
}
