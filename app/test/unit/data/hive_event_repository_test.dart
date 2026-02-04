import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:zerospoils/domain/models/event.dart';
import 'package:zerospoils/data/repositories/hive_event_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Box<Event> eventBox;
  late HiveEventRepository repo;

  setUpAll(() async {
    // Use a temp directory for Hive
    final testDir = Directory('./test/hive_test_tmp');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
    Hive.init(testDir.path);
    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(EventTypeAdapter());
    eventBox = await Hive.openBox<Event>('events');
    repo = HiveEventRepository(eventBox);
  });

  tearDown(() async {
    await eventBox.clear();
  });

  tearDownAll(() async {
    await eventBox.close();
    final testDir = Directory('./test/hive_test_tmp');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  group('HiveEventRepository', () {
    test('addEvent persists with correct metadata', () async {
      final event = Event(
        id: const Uuid().v4(),
        eventType: EventType.itemCreated,
        timestamp: DateTime.now(),
        metadataJson: '{"foo": "bar", "count": 1}',
        itemId: 'item-123',
      );
      await repo.addEvent(event);
      final stored = eventBox.get(event.id);
      expect(stored, isNotNull);
      expect(stored!.id, event.id);
      expect(stored.itemId, event.itemId);
      expect(stored.eventType, event.eventType);
      expect(
        stored.timestamp.millisecondsSinceEpoch,
        closeTo(event.timestamp.millisecondsSinceEpoch, 1000),
      );
      expect(stored.metadata['foo'], 'bar');
      expect(stored.metadata['count'], 1);
    });

    test('getByItemId returns all events for item', () async {
      final itemId = 'item-xyz';
      final events = [
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: DateTime.now(),
          metadataJson: '{}',
          itemId: itemId,
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemEdited,
          timestamp: DateTime.now(),
          metadataJson: '{}',
          itemId: itemId,
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemWasted,
          timestamp: DateTime.now(),
          metadataJson: '{}',
          itemId: 'other-item',
        ),
      ];
      for (final e in events) {
        await repo.addEvent(e);
      }
      final result = repo.getByItemId(itemId);
      expect(result.length, 2);
      expect(result.every((e) => e.itemId == itemId), isTrue);
    });

    test('getByType returns correct event type', () async {
      final events = [
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: DateTime.now(),
          metadataJson: '{}',
          itemId: 'item-1',
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemEdited,
          timestamp: DateTime.now(),
          metadataJson: '{}',
          itemId: 'item-2',
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: DateTime.now(),
          metadataJson: '{}',
          itemId: 'item-3',
        ),
      ];
      for (final e in events) {
        await repo.addEvent(e);
      }
      final result = repo.getByType(EventType.itemCreated);
      expect(result.length, 2);
      expect(result.every((e) => e.eventType == EventType.itemCreated), isTrue);
    });

    test('getByDateRange filters by timestamp window', () async {
      final now = DateTime.now();
      final events = [
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: now.subtract(const Duration(days: 2)),
          metadataJson: '{}',
          itemId: 'item-1',
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemEdited,
          timestamp: now,
          metadataJson: '{}',
          itemId: 'item-2',
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemWasted,
          timestamp: now.add(const Duration(days: 2)),
          metadataJson: '{}',
          itemId: 'item-3',
        ),
      ];
      for (final e in events) {
        await repo.addEvent(e);
      }
      final result = repo.getByDateRange(
        now.subtract(const Duration(days: 1)),
        now.add(const Duration(days: 1)),
      );
      expect(result.length, 1);
      expect(
        result.first.timestamp.difference(now).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('Metadata is preserved (JSON round-trip)', () async {
      final metadata = {
        'foo': 'bar',
        'num': 42,
        'list': [1, 2, 3],
      };
      final event = Event(
        id: const Uuid().v4(),
        eventType: EventType.itemEdited,
        timestamp: DateTime.now(),
        metadataJson: '{"foo": "bar", "num": 42, "list": [1,2,3]}',
        itemId: 'item-xyz',
      );
      await repo.addEvent(event);
      final stored = eventBox.get(event.id);
      expect(stored, isNotNull);
      expect(stored!.metadata['foo'], metadata['foo']);
      expect(stored.metadata['num'], metadata['num']);
      expect(stored.metadata['list'], metadata['list']);
    });

    test(
      'Event with null item_id (app-level events) handled correctly',
      () async {
        final event = Event(
          id: const Uuid().v4(),
          eventType: EventType.appInstalled,
          timestamp: DateTime.now(),
          metadataJson: '{"install": true}',
          itemId: null,
        );
        await repo.addEvent(event);
        final stored = eventBox.get(event.id);
        expect(stored, isNotNull);
        expect(stored!.itemId, isNull);
        expect(stored.eventType, EventType.appInstalled);
        expect(stored.metadata['install'], true);
      },
    );

    test('Timestamp ordering maintained', () async {
      final now = DateTime.now();
      final events = [
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: now.subtract(const Duration(hours: 2)),
          metadataJson: '{}',
          itemId: 'item-1',
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemEdited,
          timestamp: now,
          metadataJson: '{}',
          itemId: 'item-2',
        ),
        Event(
          id: const Uuid().v4(),
          eventType: EventType.itemWasted,
          timestamp: now.add(const Duration(hours: 2)),
          metadataJson: '{}',
          itemId: 'item-3',
        ),
      ];
      for (final e in events) {
        await repo.addEvent(e);
      }
      final all = repo.getAll();
      final sorted = List<Event>.from(all)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      expect(all.map((e) => e.id).toList(), sorted.map((e) => e.id).toList());
    });

    test('Large event volumes (1000+) queried efficiently (<200ms)', () async {
      final now = DateTime.now();
      final itemId = 'bulk-item';
      final events = List.generate(
        1200,
        (i) => Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: now.add(Duration(minutes: i)),
          metadataJson: '{}',
          itemId: itemId,
        ),
      );
      for (final e in events) {
        await repo.addEvent(e);
      }
      final sw = Stopwatch()..start();
      final result = repo.getByItemId(itemId);
      sw.stop();
      expect(result.length, 1200);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('Data persists across app restarts', () async {
      final event = Event(
        id: const Uuid().v4(),
        eventType: EventType.itemCreated,
        timestamp: DateTime.now(),
        metadataJson: '{"foo": "bar"}',
        itemId: 'persist-item',
      );
      await repo.addEvent(event);
      await eventBox.close();
      // Simulate app restart by reopening box and repo
      eventBox = await Hive.openBox<Event>('events');
      repo = HiveEventRepository(eventBox);
      final stored = eventBox.get(event.id);
      expect(stored, isNotNull);
      expect(stored!.id, event.id);
      expect(stored.metadata['foo'], 'bar');
    });

    test('Old events don\'t impact performance', () async {
      final now = DateTime.now();
      // Insert 5000 old events
      final oldEvents = List.generate(
        5000,
        (i) => Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: now.subtract(Duration(days: 365, minutes: i)),
          metadataJson: '{}',
          itemId: 'old-item',
        ),
      );
      // Insert 10 recent events
      final recentEvents = List.generate(
        10,
        (i) => Event(
          id: const Uuid().v4(),
          eventType: EventType.itemCreated,
          timestamp: now.subtract(Duration(minutes: i)),
          metadataJson: '{}',
          itemId: 'recent-item',
        ),
      );
      for (final e in oldEvents + recentEvents) {
        await repo.addEvent(e);
      }
      final sw = Stopwatch()..start();
      final result = repo.getByItemId('recent-item');
      sw.stop();
      expect(result.length, 10);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });
}
