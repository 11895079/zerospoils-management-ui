import 'package:hive/hive.dart';

/// Hive-based persistent storage for telemetry events.
/// Events are stored in order for later batch export.
class TelemetryEventStore {
  static const String boxName = 'telemetry_events';

  /// Add an event to the persistent store.
  Future<void> addEvent(Map<String, dynamic> event) async {
    final box = await Hive.openBox(boxName);
    await box.add(event);
  }

  /// Get all events from the store in order.
  Future<List<Map<String, dynamic>>> getAll() async {
    final box = await Hive.openBox(boxName);
    return box.values.cast<Map<String, dynamic>>().toList();
  }

  /// Clear all events from the store.
  Future<void> clear() async {
    final box = await Hive.openBox(boxName);
    await box.clear();
  }
}
