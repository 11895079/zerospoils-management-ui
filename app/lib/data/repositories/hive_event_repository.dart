// HiveEventRepository for audit log persistence (M2/102)
import 'package:hive/hive.dart';
import 'package:zerospoils/domain/models/event.dart';

class HiveEventRepository {
  static const String boxName = 'events';
  final Box<Event> _box;

  HiveEventRepository(this._box);

  Future<void> addEvent(Event event) async {
    await _box.put(event.id, event);
  }

  List<Event> getByItemId(String itemId) {
    return _box.values.where((e) => e.itemId == itemId).toList();
  }

  List<Event> getByType(EventType type) {
    return _box.values.where((e) => e.eventType == type).toList();
  }

  List<Event> getByDateRange(DateTime start, DateTime end) {
    return _box.values
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  Future<void> clear() async {
    await _box.clear();
  }

  List<Event> getAll() {
    final events = _box.values.toList();
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }
}
