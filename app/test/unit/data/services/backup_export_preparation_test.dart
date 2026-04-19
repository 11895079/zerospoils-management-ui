import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/data/adapters/item_adapter.dart';
import 'package:zerospoils/data/services/backup_restore_service.dart';
import 'package:zerospoils/domain/models/item_model.dart';

void main() {
  late Directory tempDir;
  late HiveInterface hive;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zerospoils_export_test_');
    hive = Hive;
    Hive.init(tempDir.path);
    SharedPreferences.setMockInitialValues({});

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

  tearDown(() async {
    await hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('prepareCsvExport returns bytes and metadata without writing file', () async {
    final itemsBox = await hive.openBox<Item>('items');
    await itemsBox.put(
      'item-1',
      Item(
        id: 'item-1',
        name: 'Milk',
        category: ItemCategory.dairy,
        location: StorageLocation.fridge,
        quantity: 1,
        unit: Unit.liter,
        status: ItemStatus.available,
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      ),
    );

    final service = BackupRestoreService(hive: hive);
    final export = await service.prepareCsvExport();

    expect(export.metadata.itemCount, 1);
    expect(export.suggestedFileName, endsWith('.csv'));
    expect(utf8.decode(export.bytes), contains('Milk'));
  });
}