import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zerospoils/data/repositories/hive_item_repository.dart';
import 'package:zerospoils/domain/models/item_model.dart';
import 'package:zerospoils/data/adapters/item_adapter.dart';

class TestTelemetryClient {
  final List<Map<String, dynamic>> events = [];
  void emit(String name, Map<String, dynamic> properties) {
    events.add({'name': name, 'properties': properties});
  }
}

void main() {
  group('HiveItemRepository Telemetry', () {
    late HiveItemRepository repository;
    late TestTelemetryClient telemetry;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('hive_test_telemetry_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ItemCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(StorageLocationAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ItemStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(WasteReasonAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ItemTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(UnitAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    setUp(() async {
      telemetry = TestTelemetryClient();
      repository = HiveItemRepository();
      // Wire up telemetry callback for test
      repository.setTelemetryCallback(telemetry.emit);
      await repository.init();
      await repository.clear();
    });

    test('emits item_created on saveItem', () async {
      final item = Item(
        id: 't1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 1,
        unit: Unit.liter,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.saveItem(item);
      expect(telemetry.events.any((e) => e['name'] == 'item_created'), isTrue);
    });

    test('emits item_updated on saveItem for update', () async {
      final item = Item(
        id: 't2',
        name: 'Cheese',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 1,
        unit: Unit.liter,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // repository.setTelemetryCallback(telemetry.emit);
      await repository.saveItem(item);
      final updated = item.copyWith(name: 'Cheddar');
      await repository.saveItem(updated);
      expect(telemetry.events.any((e) => e['name'] == 'item_updated'), isTrue);
    });

    test('emits item_deleted on deleteItem', () async {
      final item = Item(
        id: 't3',
        name: 'Yogurt',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 1,
        unit: Unit.liter,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // repository.setTelemetryCallback(telemetry.emit);
      await repository.saveItem(item);
      await repository.deleteItem(item.id);
      expect(telemetry.events.any((e) => e['name'] == 'item_deleted'), isTrue);
    });
  });
}
